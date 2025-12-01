// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {OnchainFarmMarketplace} from "../src/OnchainFarmMarketplace.sol";
import {OnchainFarmNFT} from "../src/OnchainFarmNFT.sol";

contract OnchainFarmMarketplaceTest is Test {
    OnchainFarmMarketplace marketplace;
    OnchainFarmNFT nft;
    ERC1967Proxy marketplaceProxy;
    ERC1967Proxy nftProxy;

    address owner = makeAddr("owner");
    address farmer = makeAddr("farmer");
    address buyer = makeAddr("buyer");
    address feeRecipient = makeAddr("feeRecipient");

    uint256 constant PLATFORM_FEE = 250; // 2.5%
    uint256 constant PRODUCT_PRICE = 1 ether;
    uint256 constant QUANTITY = 10;

    function setUp() public {
        vm.startPrank(owner);

        // Deploy NFT implementation
        OnchainFarmNFT nftImpl = new OnchainFarmNFT();

        // Deploy NFT proxy
        bytes memory nftInitData = abi.encodeWithSelector(
            OnchainFarmNFT.initialize.selector,
            "OnchainFarm Certificate",
            "OFC",
            address(0) // marketplace address will be set later
        );
        nftProxy = new ERC1967Proxy(address(nftImpl), nftInitData);
        nft = OnchainFarmNFT(address(nftProxy));

        // Deploy Marketplace implementation
        OnchainFarmMarketplace marketplaceImpl = new OnchainFarmMarketplace();

        // Deploy Marketplace proxy
        bytes memory marketplaceInitData = abi.encodeWithSelector(
            OnchainFarmMarketplace.initialize.selector,
            address(nftProxy), // nft contract
            feeRecipient, // fee recipient
            PLATFORM_FEE // platform fee
        );
        marketplaceProxy = new ERC1967Proxy(address(marketplaceImpl), marketplaceInitData);
        marketplace = OnchainFarmMarketplace(address(marketplaceProxy));

        // Set marketplace address in NFT
        nft.setMarketplaceContract(address(marketplaceProxy));

        vm.stopPrank();
    }

    function test_Initialization() public {
        assertEq(marketplace.platformFee(), PLATFORM_FEE);
        assertEq(marketplace.feeRecipient(), feeRecipient);
        assertEq(address(marketplace.nftContract()), address(nftProxy));
        assertEq(marketplace.productCount(), 0);
        assertEq(marketplace.orderCount(), 0);
    }

    function test_ListProduct() public {
        vm.prank(farmer);
        uint256 productId = marketplace.listProduct(
            "Organic Tomatoes",
            "Fresh organic tomatoes from local farm",
            "https://example.com/tomatoes.jpg",
            PRODUCT_PRICE,
            QUANTITY,
            "Vegetables",
            "California"
        );

        assertEq(productId, 1);
        assertEq(marketplace.productCount(), 1);

        (
            uint256 id,
            address productFarmer,
            string memory name,
            ,
            ,
            uint256 price,
            uint256 quantity,
            uint256 remainingQuantity,
            string memory category,
            string memory location,
            bool isActive,
            ,
        ) = marketplace.products(1);

        assertEq(id, 1);
        assertEq(productFarmer, farmer);
        assertEq(name, "Organic Tomatoes");
        assertEq(price, PRODUCT_PRICE);
        assertEq(quantity, QUANTITY);
        assertEq(remainingQuantity, QUANTITY);
        assertEq(category, "Vegetables");
        assertEq(location, "California");
        assertTrue(isActive);
    }

    function test_ListProduct_RevertOnInvalidPrice() public {
        vm.prank(farmer);
        vm.expectRevert(abi.encodeWithSignature("OnchainFarmMarketplace__InvalidInput(string)", "Invalid price or quantity"));
        marketplace.listProduct(
            "Organic Tomatoes",
            "Fresh organic tomatoes",
            "https://example.com/tomatoes.jpg",
            0, // invalid price
            QUANTITY,
            "Vegetables",
            "California"
        );
    }

    function test_UpdateProduct() public {
        // List product first
        vm.prank(farmer);
        uint256 productId = marketplace.listProduct(
            "Organic Tomatoes",
            "Fresh organic tomatoes",
            "https://example.com/tomatoes.jpg",
            PRODUCT_PRICE,
            QUANTITY,
            "Vegetables",
            "California"
        );

        // Update product
        vm.prank(farmer);
        marketplace.updateProduct(
            productId,
            "Premium Organic Tomatoes",
            "Updated description",
            "https://example.com/tomatoes-updated.jpg",
            PRODUCT_PRICE * 2,
            QUANTITY * 2,
            "Premium Vegetables",
            "California Premium"
        );

        (
            uint256 id,
            address productFarmer,
            string memory name,
            string memory description,
            string memory imageUrl,
            uint256 price,
            uint256 quantity,
            uint256 remainingQuantity,
            string memory category,
            string memory location,
            ,
            ,
        ) = marketplace.products(productId);

        assertEq(name, "Premium Organic Tomatoes");
        assertEq(description, "Updated description");
        assertEq(imageUrl, "https://example.com/tomatoes-updated.jpg");
        assertEq(price, PRODUCT_PRICE * 2);
        assertEq(quantity, QUANTITY * 2);
        assertEq(remainingQuantity, QUANTITY * 2); // Reset to new quantity
        assertEq(category, "Premium Vegetables");
        assertEq(location, "California Premium");
    }

    function test_UpdateProduct_RevertIfNotFarmer() public {
        // List product as farmer
        vm.prank(farmer);
        uint256 productId = marketplace.listProduct(
            "Organic Tomatoes",
            "Fresh organic tomatoes",
            "https://example.com/tomatoes.jpg",
            PRODUCT_PRICE,
            QUANTITY,
            "Vegetables",
            "California"
        );

        // Try to update as buyer
        vm.prank(buyer);
        vm.expectRevert();
        marketplace.updateProduct(
            productId,
            "Hacked Tomatoes",
            "Hacked description",
            "https://example.com/hacked.jpg",
            PRODUCT_PRICE,
            QUANTITY,
            "Hacked",
            "Hacked"
        );
    }

    function test_DeactivateProduct() public {
        // List product
        vm.prank(farmer);
        uint256 productId = marketplace.listProduct(
            "Organic Tomatoes",
            "Fresh organic tomatoes",
            "https://example.com/tomatoes.jpg",
            PRODUCT_PRICE,
            QUANTITY,
            "Vegetables",
            "California"
        );

        // Deactivate
        vm.prank(farmer);
        marketplace.deactivateProduct(productId);

        OnchainFarmMarketplace.Product memory product = marketplace.getProduct(productId);
        assertFalse(product.isActive);
    }

    function test_CreateOrder() public {
        // List product
        vm.prank(farmer);
        uint256 productId = marketplace.listProduct(
            "Organic Tomatoes",
            "Fresh organic tomatoes",
            "https://example.com/tomatoes.jpg",
            PRODUCT_PRICE,
            QUANTITY,
            "Vegetables",
            "California"
        );

        // Create order
        uint256 orderQuantity = 2;
        uint256 totalPrice = PRODUCT_PRICE * orderQuantity;
        uint256 fee = (totalPrice * PLATFORM_FEE) / 10000;
        uint256 totalPayment = totalPrice + fee;

        vm.deal(buyer, totalPayment + 0.1 ether); // Extra for excess refund
        vm.prank(buyer);
        uint256 orderId = marketplace.createOrder{value: totalPayment + 0.1 ether}(
            productId,
            orderQuantity,
            "123 Main St, Anytown"
        );

        assertEq(orderId, 1);
        assertEq(marketplace.orderCount(), 1);

        (
            uint256 id,
            uint256 orderProductId,
            address orderBuyer,
            address orderSeller,
            uint256 orderQty,
            uint256 orderTotalPrice,
            ,
            string memory deliveryAddress,
            ,
            ,
        ) = marketplace.orders(1);

        assertEq(id, 1);
        assertEq(orderProductId, productId);
        assertEq(orderBuyer, buyer);
        assertEq(orderSeller, farmer);
        assertEq(orderQty, orderQuantity);
        assertEq(orderTotalPrice, totalPrice);
        assertEq(deliveryAddress, "123 Main St, Anytown");

        // Check remaining quantity
        OnchainFarmMarketplace.Product memory productAfter = marketplace.getProduct(productId);
        assertEq(productAfter.remainingQuantity, QUANTITY - orderQuantity);
    }

    function test_CreateOrder_RevertOnInsufficientFunds() public {
        // List product
        vm.prank(farmer);
        uint256 productId = marketplace.listProduct(
            "Organic Tomatoes",
            "Fresh organic tomatoes",
            "https://example.com/tomatoes.jpg",
            PRODUCT_PRICE,
            QUANTITY,
            "Vegetables",
            "California"
        );

        // Try to create order with insufficient funds
        vm.deal(buyer, 0.5 ether);
        vm.prank(buyer);
        vm.expectRevert();
        marketplace.createOrder{value: 0.5 ether}(
            productId,
            2,
            "123 Main St, Anytown"
        );
    }

    function test_ConfirmOrder() public {
        // Setup order
        _setupOrder();

        // Confirm order as seller
        vm.prank(farmer);
        marketplace.confirmOrder(1);

        OnchainFarmMarketplace.Order memory order = marketplace.getOrder(1);
        assertEq(uint8(order.status), uint8(OnchainFarmMarketplace.OrderStatus.Confirmed));
    }

    function test_ShipOrder() public {
        // Setup and confirm order
        _setupOrder();
        vm.prank(farmer);
        marketplace.confirmOrder(1);

        // Ship order
        vm.prank(farmer);
        marketplace.shipOrder(1, "TRK123456");

        OnchainFarmMarketplace.Order memory orderShipped = marketplace.getOrder(1);
        assertEq(uint8(orderShipped.status), uint8(OnchainFarmMarketplace.OrderStatus.Shipped));
        assertEq(orderShipped.trackingInfo, "TRK123456");
    }

    function test_ConfirmDelivery() public {
        // Setup and ship order
        _setupOrder();
        vm.prank(farmer);
        marketplace.confirmOrder(1);
        vm.prank(farmer);
        marketplace.shipOrder(1, "TRK123456");

        uint256 initialBuyerBalance = buyer.balance;
        uint256 initialFarmerBalance = farmer.balance;
        uint256 initialFeeRecipientBalance = feeRecipient.balance;

        // Confirm delivery
        vm.prank(buyer);
        marketplace.confirmDelivery(1);

        OnchainFarmMarketplace.Order memory orderDelivered = marketplace.getOrder(1);
        assertEq(uint8(orderDelivered.status), uint8(OnchainFarmMarketplace.OrderStatus.Delivered));
        assertGt(orderDelivered.deliveredAt, 0);

        // Check balances
        uint256 fee = (orderDelivered.totalPrice * PLATFORM_FEE) / 10000;
        assertEq(farmer.balance, initialFarmerBalance + orderDelivered.totalPrice);
        assertEq(feeRecipient.balance, initialFeeRecipientBalance + fee);
    }

    function test_CancelOrder() public {
        // Setup order
        _setupOrder();

        uint256 initialBuyerBalance = buyer.balance;

        // Cancel order
        vm.prank(buyer);
        marketplace.cancelOrder(1);

        OnchainFarmMarketplace.Order memory orderCancelled = marketplace.getOrder(1);
        assertEq(uint8(orderCancelled.status), uint8(OnchainFarmMarketplace.OrderStatus.Cancelled));

        // Check refund
        uint256 fee = (orderCancelled.totalPrice * PLATFORM_FEE) / 10000;
        uint256 refundAmount = orderCancelled.totalPrice + fee;
        assertEq(buyer.balance, initialBuyerBalance + refundAmount);

        // Check quantity restored
        OnchainFarmMarketplace.Product memory productRestored = marketplace.getProduct(1);
        assertEq(productRestored.remainingQuantity, QUANTITY);
    }

    function test_DisputeOrder() public {
        // Setup and ship order
        _setupOrder();
        vm.prank(farmer);
        marketplace.confirmOrder(1);
        vm.prank(farmer);
        marketplace.shipOrder(1, "TRK123456");

        // Raise dispute
        vm.prank(buyer);
        marketplace.disputeOrder(1, "Product damaged");

        OnchainFarmMarketplace.Order memory orderDisputed = marketplace.getOrder(1);
        assertEq(uint8(orderDisputed.status), uint8(OnchainFarmMarketplace.OrderStatus.Disputed));
    }

    function test_ResolveDispute_FavorBuyer() public {
        // Setup disputed order
        _setupOrder();
        vm.prank(farmer);
        marketplace.confirmOrder(1);
        vm.prank(farmer);
        marketplace.shipOrder(1, "TRK123456");
        vm.prank(buyer);
        marketplace.disputeOrder(1, "Product damaged");

        uint256 initialBuyerBalance = buyer.balance;

        // Resolve dispute favoring buyer
        vm.prank(owner);
        marketplace.resolveDispute(1, true); // favor buyer

        OnchainFarmMarketplace.Order memory orderResolved = marketplace.getOrder(1);
        assertEq(uint8(orderResolved.status), uint8(OnchainFarmMarketplace.OrderStatus.Delivered));

        // Check refund
        uint256 fee = (orderResolved.totalPrice * PLATFORM_FEE) / 10000;
        uint256 refundAmount = orderResolved.totalPrice + fee;
        assertEq(buyer.balance, initialBuyerBalance + refundAmount);

        // Check quantity restored
        OnchainFarmMarketplace.Product memory productRestored2 = marketplace.getProduct(1);
        assertEq(productRestored2.remainingQuantity, QUANTITY);
    }

    // Helper function to setup a basic order
    function _setupOrder() internal {
        // List product
        vm.prank(farmer);
        marketplace.listProduct(
            "Organic Tomatoes",
            "Fresh organic tomatoes",
            "https://example.com/tomatoes.jpg",
            PRODUCT_PRICE,
            QUANTITY,
            "Vegetables",
            "California"
        );

        // Create order
        uint256 orderQuantity = 2;
        uint256 totalPrice = PRODUCT_PRICE * orderQuantity;
        uint256 fee = (totalPrice * PLATFORM_FEE) / 10000;
        uint256 totalPayment = totalPrice + fee;

        vm.deal(buyer, totalPayment);
        vm.prank(buyer);
        marketplace.createOrder{value: totalPayment}(
            1,
            orderQuantity,
            "123 Main St, Anytown"
        );
    }
}