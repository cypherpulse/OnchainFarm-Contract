// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Custom errors
error OnchainFarmMarketplace__ProductNotFound(uint256 productId);
error OnchainFarmMarketplace__OrderNotFound(uint256 orderId);
error OnchainFarmMarketplace__InsufficientFunds(uint256 required, uint256 provided);
error OnchainFarmMarketplace__UnauthorizedAccess(address caller);
error OnchainFarmMarketplace__InvalidInput(string reason);
error OnchainFarmMarketplace__OrderAlreadyProcessed(uint256 orderId);
error OnchainFarmMarketplace__DisputeWindowExpired(uint256 orderId);

// Interfaces
interface IOnchainFarmNFT {
    function mintCertificate(
        uint256 _productId,
        string memory _productName,
        bool _isOrganic,
        address _recipient
    ) external returns (uint256);
}

// Contract
contract OnchainFarmMarketplace is UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuard {
    // Type declarations
    enum OrderStatus {
        Pending,
        Confirmed,
        Shipped,
        Delivered,
        Cancelled,
        Disputed
    }

    struct Product {
        uint256 id;
        address farmer;
        string name;
        string description;
        string imageUrl;
        uint256 price; // in wei
        uint256 quantity;
        uint256 remainingQuantity;
        string category;
        string location;
        bool isActive;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Order {
        uint256 id;
        uint256 productId;
        address buyer;
        address seller;
        uint256 quantity;
        uint256 totalPrice;
        OrderStatus status;
        string deliveryAddress;
        string trackingInfo;
        uint256 createdAt;
        uint256 deliveredAt;
    }

    // State variables
    uint256 public productCount;
    mapping(uint256 => Product) public products;
    mapping(address => uint256[]) public farmerProducts;

    uint256 public orderCount;
    mapping(uint256 => Order) public orders;
    mapping(address => uint256[]) public buyerOrders;
    mapping(address => uint256[]) public sellerOrders;

    uint256 public platformFee; // in basis points
    address public feeRecipient;

    IOnchainFarmNFT public nftContract;

    // Events
    event ProductListed(uint256 indexed productId, address indexed farmer, string name, uint256 price);
    event ProductUpdated(uint256 indexed productId, address indexed farmer);
    event ProductDeactivated(uint256 indexed productId, address indexed farmer);

    event OrderCreated(uint256 indexed orderId, uint256 indexed productId, address indexed buyer, address seller, uint256 quantity, uint256 totalPrice);
    event OrderStatusUpdated(uint256 indexed orderId, OrderStatus status);
    event OrderDelivered(uint256 indexed orderId, uint256 timestamp);
    event OrderDisputed(uint256 indexed orderId, string reason);

    event DeliveryVerified(uint256 indexed orderId, address indexed verifier, string proof);

    // Modifiers
    modifier onlyFarmer(uint256 _productId) {
        _onlyFarmer(_productId);
        _;
    }

    modifier orderExists(uint256 _orderId) {
        _orderExists(_orderId);
        _;
    }

    modifier productExists(uint256 _productId) {
        _productExists(_productId);
        _;
    }

    // Internal functions for modifiers
    function _onlyFarmer(uint256 _productId) internal view {
        if (products[_productId].farmer != msg.sender) {
            revert OnchainFarmMarketplace__UnauthorizedAccess(msg.sender);
        }
    }

    function _orderExists(uint256 _orderId) internal view {
        if (_orderId == 0 || _orderId > orderCount) {
            revert OnchainFarmMarketplace__OrderNotFound(_orderId);
        }
    }

    function _productExists(uint256 _productId) internal view {
        if (_productId == 0 || _productId > productCount) {
            revert OnchainFarmMarketplace__ProductNotFound(_productId);
        }
    }

    // Functions

    // Initialize function (replaces constructor)
    function initialize(address _nftContract, address _feeRecipient, uint256 _platformFee) external initializer {
        __Ownable_init(msg.sender);

        nftContract = IOnchainFarmNFT(_nftContract);
        feeRecipient = _feeRecipient;
        platformFee = _platformFee;
    }

    // External functions
    function listProduct(
        string memory _name,
        string memory _description,
        string memory _imageUrl,
        uint256 _price,
        uint256 _quantity,
        string memory _category,
        string memory _location
    ) external returns (uint256) {
        if (_price == 0 || _quantity == 0) {
            revert OnchainFarmMarketplace__InvalidInput("Invalid price or quantity");
        }
        productCount++;
        products[productCount] = Product({
            id: productCount,
            farmer: msg.sender,
            name: _name,
            description: _description,
            imageUrl: _imageUrl,
            price: _price,
            quantity: _quantity,
            remainingQuantity: _quantity,
            category: _category,
            location: _location,
            isActive: true,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });
        farmerProducts[msg.sender].push(productCount);
        emit ProductListed(productCount, msg.sender, _name, _price);
        return productCount;
    }

    function updateProduct(
        uint256 _productId,
        string memory _name,
        string memory _description,
        string memory _imageUrl,
        uint256 _price,
        uint256 _quantity,
        string memory _category,
        string memory _location
    ) external productExists(_productId) onlyFarmer(_productId) {
        Product storage product = products[_productId];
        product.name = _name;
        product.description = _description;
        product.imageUrl = _imageUrl;
        product.price = _price;
        product.quantity = _quantity;
        product.remainingQuantity = _quantity; // Reset remaining
        product.category = _category;
        product.location = _location;
        product.updatedAt = block.timestamp;
        emit ProductUpdated(_productId, msg.sender);
    }

    function deactivateProduct(uint256 _productId) external productExists(_productId) onlyFarmer(_productId) {
        products[_productId].isActive = false;
        emit ProductDeactivated(_productId, msg.sender);
    }

    function createOrder(
        uint256 _productId,
        uint256 _quantity,
        string memory _deliveryAddress
    ) external payable productExists(_productId) nonReentrant returns (uint256) {
        Product storage product = products[_productId];
        if (!product.isActive || product.remainingQuantity < _quantity) {
            revert OnchainFarmMarketplace__InvalidInput("Product not available or insufficient quantity");
        }
        uint256 totalPrice = product.price * _quantity;
        uint256 fee = (totalPrice * platformFee) / 10000;
        uint256 requiredAmount = totalPrice + fee;
        if (msg.value < requiredAmount) {
            revert OnchainFarmMarketplace__InsufficientFunds(requiredAmount, msg.value);
        }
        // Refund excess immediately
        if (msg.value > requiredAmount) {
            payable(msg.sender).transfer(msg.value - requiredAmount);
        }
        orderCount++;
        orders[orderCount] = Order({
            id: orderCount,
            productId: _productId,
            buyer: msg.sender,
            seller: product.farmer,
            quantity: _quantity,
            totalPrice: totalPrice,
            status: OrderStatus.Pending,
            deliveryAddress: _deliveryAddress,
            trackingInfo: "",
            createdAt: block.timestamp,
            deliveredAt: 0
        });
        buyerOrders[msg.sender].push(orderCount);
        sellerOrders[product.farmer].push(orderCount);
        product.remainingQuantity -= _quantity;
        emit OrderCreated(orderCount, _productId, msg.sender, product.farmer, _quantity, totalPrice);
        return orderCount;
    }

    function confirmOrder(uint256 _orderId) external orderExists(_orderId) {
        Order storage order = orders[_orderId];
        if (order.seller != msg.sender || order.status != OrderStatus.Pending) {
            revert OnchainFarmMarketplace__UnauthorizedAccess(msg.sender);
        }
        order.status = OrderStatus.Confirmed;
        emit OrderStatusUpdated(_orderId, OrderStatus.Confirmed);
    }

    function shipOrder(uint256 _orderId, string memory _trackingInfo) external orderExists(_orderId) {
        Order storage order = orders[_orderId];
        if (order.seller != msg.sender || order.status != OrderStatus.Confirmed) {
            revert OnchainFarmMarketplace__UnauthorizedAccess(msg.sender);
        }
        order.status = OrderStatus.Shipped;
        order.trackingInfo = _trackingInfo;
        emit OrderStatusUpdated(_orderId, OrderStatus.Shipped);
    }

    function confirmDelivery(uint256 _orderId) external orderExists(_orderId) {
        Order storage order = orders[_orderId];
        if ((order.buyer != msg.sender && order.seller != msg.sender) || order.status != OrderStatus.Shipped) {
            revert OnchainFarmMarketplace__UnauthorizedAccess(msg.sender);
        }
        order.status = OrderStatus.Delivered;
        order.deliveredAt = block.timestamp;
        // Release payment
        uint256 fee = (order.totalPrice * platformFee) / 10000;
        payable(feeRecipient).transfer(fee);
        payable(order.seller).transfer(order.totalPrice);
        emit OrderDelivered(_orderId, block.timestamp);
    }

    function cancelOrder(uint256 _orderId) external orderExists(_orderId) {
        Order storage order = orders[_orderId];
        if (order.buyer != msg.sender || order.status != OrderStatus.Pending) {
            revert OnchainFarmMarketplace__UnauthorizedAccess(msg.sender);
        }
        order.status = OrderStatus.Cancelled;
        // Refund
        uint256 refundAmount = order.totalPrice + (order.totalPrice * platformFee) / 10000;
        payable(order.buyer).transfer(refundAmount);
        // Restore quantity
        products[order.productId].remainingQuantity += order.quantity;
        emit OrderStatusUpdated(_orderId, OrderStatus.Cancelled);
    }

    function updateTrackingInfo(uint256 _orderId, string memory _trackingInfo) external orderExists(_orderId) {
        Order storage order = orders[_orderId];
        if (order.seller != msg.sender) {
            revert OnchainFarmMarketplace__UnauthorizedAccess(msg.sender);
        }
        order.trackingInfo = _trackingInfo;
    }

    function disputeOrder(uint256 _orderId, string memory _reason) external orderExists(_orderId) {
        Order storage order = orders[_orderId];
        if ((order.buyer != msg.sender && order.seller != msg.sender) || order.status != OrderStatus.Shipped) {
            revert OnchainFarmMarketplace__UnauthorizedAccess(msg.sender);
        }
        order.status = OrderStatus.Disputed;
        emit OrderDisputed(_orderId, _reason);
    }

    function resolveDispute(uint256 _orderId, bool _favorBuyer) external onlyOwner orderExists(_orderId) {
        Order storage order = orders[_orderId];
        if (order.status != OrderStatus.Disputed) {
            revert OnchainFarmMarketplace__InvalidInput("Order not disputed");
        }
        if (_favorBuyer) {
            // Refund buyer
            uint256 refundAmount = order.totalPrice + (order.totalPrice * platformFee) / 10000;
            payable(order.buyer).transfer(refundAmount);
            // Restore quantity
            products[order.productId].remainingQuantity += order.quantity;
        } else {
            // Pay seller
            payable(order.seller).transfer(order.totalPrice);
            payable(feeRecipient).transfer((order.totalPrice * platformFee) / 10000);
        }
        order.status = OrderStatus.Delivered; // or something
    }

    // View functions
    function getProduct(uint256 _productId) external view productExists(_productId) returns (Product memory) {
        return products[_productId];
    }

    function getOrder(uint256 _orderId) external view orderExists(_orderId) returns (Order memory) {
        return orders[_orderId];
    }

    function getFarmerProducts(address _farmer) external view returns (uint256[] memory) {
        return farmerProducts[_farmer];
    }

    function getBuyerOrders(address _buyer) external view returns (uint256[] memory) {
        return buyerOrders[_buyer];
    }

    function getSellerOrders(address _seller) external view returns (uint256[] memory) {
        return sellerOrders[_seller];
    }

    // Internal functions
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}