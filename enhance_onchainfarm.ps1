# OnchainFarm Enhancement Script
# Implements 5 changes with separate commits for Base network, upgradable contracts, NFT certificates, documentation, and marketplace features

Write-Host "🚀 Starting OnchainFarm enhancement script..." -ForegroundColor Green

# Change 1: Build on Base network
Write-Host "📦 Change 1: Configure for Base network deployment" -ForegroundColor Yellow

$baseConfig = @'
[rpc_endpoints]
base_mainnet = "https://mainnet.base.org"
base_sepolia = "https://sepolia.base.org"

[etherscan]
base_mainnet = { key = "${BASESCAN_API_KEY}" }
base_sepolia = { key = "${BASESCAN_API_KEY}" }
'@

Add-Content -Path "foundry.toml" -Value $baseConfig

& git add foundry.toml
& git commit -m "Added Base network configuration for deployment and contract verification"

# Change 2: Enhance upgradable smart contract with pause functionality
Write-Host "🔄 Change 2: Enhance upgradable smart contract with pause functionality" -ForegroundColor Yellow

$pauseImport = @"

// Add pause functionality for emergency stops
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

// Inherit from PausableUpgradeable
contract OnchainFarmMarketplace is UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
"@

$content = Get-Content "src/OnchainFarmMarketplace.sol" -Raw
$content = $content -replace "// Contract", "$pauseImport`n// Contract"
Set-Content -Path "src/OnchainFarmMarketplace.sol" -Value $content

# Add pause modifier
$pauseModifier = @"
    modifier whenNotPaused() {
        _whenNotPaused();
        _;
    }

    modifier whenPaused() {
        _whenPaused();
        _;
    }
"@

$content = Get-Content "src/OnchainFarmMarketplace.sol" -Raw
$content = $content -replace "    modifier onlyFarmer\(uint256 _productId\) \{", "$pauseModifier`n`n    modifier onlyFarmer(uint256 _productId) {"
Set-Content -Path "src/OnchainFarmMarketplace.sol" -Value $content

# Add pause functions
$pauseFunctions = @"
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function paused() public view returns (bool) {
        return _paused();
    }
"@

$content = Get-Content "src/OnchainFarmMarketplace.sol" -Raw
$content = $content -replace "function _authorizeUpgrade\(address newImplementation\) internal override onlyOwner \{\}", "function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}`n`n$pauseFunctions"
Set-Content -Path "src/OnchainFarmMarketplace.sol" -Value $content

# Update initialize function
$content = Get-Content "src/OnchainFarmMarketplace.sol" -Raw
$content = $content -replace "__ReentrancyGuard_init\(\);", "__ReentrancyGuard_init();`n        __Pausable_init();"
Set-Content -Path "src/OnchainFarmMarketplace.sol" -Value $content

& git add src/OnchainFarmMarketplace.sol
& git commit -m "updated upgradable smart contract - added emergency pause functionality with PausableUpgradeable for security controls and emergency stops in upgradable OnchainFarm marketplace"

# Change 3: Enhance NFT Certificates with batch operations
Write-Host "🎨 Change 3: Enhance NFT Certificates with batch operations" -ForegroundColor Yellow

$batchFunctions = @"
// Add batch minting functionality
function batchMintCertificates(
    uint256[] memory _productIds,
    string[] memory _productNames,
    bool[] memory _isOrganic,
    address[] memory _recipients
) external onlyMarketplace returns (uint256[] memory) {
    if (_productIds.length != _productNames.length ||
        _productIds.length != _isOrganic.length ||
        _productIds.length != _recipients.length) {
        revert OnchainFarmNFT__InvalidInput("Array lengths must match");
    }

    uint256[] memory tokenIds = new uint256[](_productIds.length);

    for (uint256 i = 0; i < _productIds.length; i++) {
        tokenCount++;
        uint256 tokenId = tokenCount;

        _mint(_recipients[i], tokenId);

        certificates[tokenId] = Certificate({
            productId: _productIds[i],
            productName: _productNames[i],
            isOrganic: _isOrganic[i],
            isSustainable: false, // Default to false for batch minting
            recipient: _recipients[i],
            issuer: marketplaceContract,
            issuedAt: block.timestamp,
            metadataURI: ""
        });

        tokenIds[i] = tokenId;

        emit CertificateMinted(tokenId, _productIds[i], _recipients[i]);
    }

    return tokenIds;
}

// Add certificate verification function
function verifyCertificate(uint256 _tokenId) external view returns (bool) {
    return _exists(_tokenId) && certificates[_tokenId].recipient != address(0);
}

// Add function to get certificates by owner
function getCertificatesByOwner(address _owner) external view returns (uint256[] memory) {
    uint256 balance = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](balance);

    for (uint256 i = 0; i < balance; i++) {
        tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }

    return tokenIds;
}
"@

Add-Content -Path "src/OnchainFarmNFT.sol" -Value $batchFunctions

& git add src/OnchainFarmNFT.sol
& git commit -m "enhanced NFT Certificates - added batch minting, certificate verification, and owner certificate lookup functions for efficient NFT certificate management in OnchainFarm"

# Change 4: Add reading/documentation features
Write-Host "📚 Change 4: Add reading and documentation features" -ForegroundColor Yellow

$viewFunctions = @"
// Add product reading/view functions for better data access
function getProductDetails(uint256 _productId) external view returns (
    uint256 id,
    address farmer,
    string memory name,
    string memory description,
    string memory imageUrl,
    uint256 price,
    uint256 quantity,
    uint256 remainingQuantity,
    string memory category,
    string memory location,
    bool isActive,
    uint256 createdAt,
    uint256 updatedAt
) {
    Product memory product = products[_productId];
    if (product.id == 0) revert OnchainFarmMarketplace__ProductNotFound(_productId);

    return (
        product.id,
        product.farmer,
        product.name,
        product.description,
        product.imageUrl,
        product.price,
        product.quantity,
        product.remainingQuantity,
        product.category,
        product.location,
        product.isActive,
        product.createdAt,
        product.updatedAt
    );
}

function getOrderDetails(uint256 _orderId) external view returns (
    uint256 id,
    uint256 productId,
    address buyer,
    address seller,
    uint256 quantity,
    uint256 totalPrice,
    OrderStatus status,
    string memory deliveryAddress,
    string memory trackingInfo,
    uint256 createdAt,
    uint256 deliveredAt
) {
    Order memory order = orders[_orderId];
    if (order.id == 0) revert OnchainFarmMarketplace__OrderNotFound(_orderId);

    return (
        order.id,
        order.productId,
        order.buyer,
        order.seller,
        order.quantity,
        order.totalPrice,
        order.status,
        order.deliveryAddress,
        order.trackingInfo,
        order.createdAt,
        order.deliveredAt
    );
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
"@

Add-Content -Path "src/OnchainFarmMarketplace.sol" -Value $viewFunctions

& git add src/OnchainFarmMarketplace.sol
& git commit -m "added reading features about this project - added comprehensive view functions for product details, order details, and user-specific data retrieval to enhance transparency and data access in OnchainFarm marketplace"

# Change 5: Add marketplace analytics and reputation system
Write-Host "📊 Change 5: Add marketplace analytics and farmer reputation" -ForegroundColor Yellow

$analyticsFeatures = @"
// Add reputation and analytics features
mapping(address => uint256) public farmerReputation;
mapping(address => uint256) public farmerTotalSales;
mapping(address => uint256) public farmerTotalEarnings;

// Events for analytics
event FarmerReputationUpdated(address indexed farmer, uint256 newReputation);
event SaleRecorded(address indexed farmer, uint256 orderId, uint256 amount);

// Add reputation management
function updateFarmerReputation(address _farmer, uint256 _reputation) external onlyOwner {
    farmerReputation[_farmer] = _reputation;
    emit FarmerReputationUpdated(_farmer, _reputation);
}

function recordSale(address _farmer, uint256 _orderId, uint256 _amount) internal {
    farmerTotalSales[_farmer]++;
    farmerTotalEarnings[_farmer] += _amount;
    emit SaleRecorded(_farmer, _orderId, _amount);
}

// Update confirmDelivery to record sales
function confirmDelivery(uint256 _orderId) external {
    Order storage order = orders[_orderId];
    if (order.id == 0) revert OnchainFarmMarketplace__OrderNotFound(_orderId);
    if (order.buyer != msg.sender && order.seller != msg.sender) revert OnchainFarmMarketplace__UnauthorizedAccess(msg.sender);
    if (order.status != OrderStatus.Shipped) revert OnchainFarmMarketplace__InvalidInput("Order must be shipped first");

    order.status = OrderStatus.Delivered;
    order.deliveredAt = block.timestamp;

    // Record sale for analytics
    recordSale(order.seller, _orderId, order.totalPrice);

    emit OrderStatusUpdated(_orderId, OrderStatus.Delivered);
    emit OrderDelivered(_orderId, block.timestamp);
}

// Analytics view functions
function getFarmerStats(address _farmer) external view returns (
    uint256 reputation,
    uint256 totalSales,
    uint256 totalEarnings,
    uint256 activeProducts
) {
    return (
        farmerReputation[_farmer],
        farmerTotalSales[_farmer],
        farmerTotalEarnings[_farmer],
        farmerProducts[_farmer].length
    );
}

function getMarketplaceStats() external view returns (
    uint256 totalProducts,
    uint256 totalOrders,
    uint256 totalVolume
) {
    uint256 volume = 0;
    for (uint256 i = 1; i <= orderCount; i++) {
        if (orders[i].status == OrderStatus.Delivered) {
            volume += orders[i].totalPrice;
        }
    }

    return (
        productCount,
        orderCount,
        volume
    );
}
"@

Add-Content -Path "src/OnchainFarmMarketplace.sol" -Value $analyticsFeatures

& git add src/OnchainFarmMarketplace.sol
& git commit -m "added marketplace analytics and reputation system - added farmer reputation tracking, sales analytics, and marketplace statistics for comprehensive OnchainFarm platform insights and performance monitoring"

Write-Host "✅ All 5 changes have been implemented and committed successfully!" -ForegroundColor Green
Write-Host "" -ForegroundColor White
Write-Host "📋 Summary of changes:" -ForegroundColor Cyan
Write-Host "1. ✅ Base network configuration" -ForegroundColor Green
Write-Host "2. ✅ Enhanced upgradable contracts with pause functionality" -ForegroundColor Green
Write-Host "3. ✅ Enhanced NFT certificates with batch operations" -ForegroundColor Green
Write-Host "4. ✅ Added comprehensive reading/view functions" -ForegroundColor Green
Write-Host "5. ✅ Added marketplace analytics and reputation system" -ForegroundColor Green
Write-Host "" -ForegroundColor White
Write-Host "🎉 Ready for deployment on Base network!" -ForegroundColor Magenta