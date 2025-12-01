# OnchainFarm 🧑‍🌾

[![Solidity](https://img.shields.io/badge/Solidity-^0.8.19-blue.svg)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-orange.svg)](https://getfoundry.sh/)
[![Base Network](https://img.shields.io/badge/Network-Base-blue.svg)](https://base.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> A decentralized marketplace and certification system for farm products built on Base, enabling transparent, secure, and efficient agricultural commerce with NFT-backed product verification.

## 🌟 Overview

OnchainFarm revolutionizes agricultural commerce by providing a decentralized marketplace where farmers can list products and buyers can purchase with confidence. The platform features NFT certificates for product verification, escrow-based payments, and dispute resolution mechanisms - all built with upgradeable smart contracts following industry best practices.

**Key Innovation**: Combines marketplace functionality with NFT certification to create verifiable, transparent supply chain tracking for agricultural products.

## ✨ Features

### 🏪 Decentralized Marketplace
- **Product Listing**: Farmers can list agricultural products with detailed specifications
- **Escrow Payments**: Secure payment holding until delivery confirmation
- **Order Management**: Complete order lifecycle from creation to delivery
- **Dispute Resolution**: Built-in arbitration system for transaction disputes

### 🎨 NFT Certification System
- **Product Certificates**: ERC-721 NFTs verifying product authenticity and quality
- **Metadata Management**: Rich metadata storage for product information
- **Transferable Certificates**: Certificates can be transferred with product ownership
- **Burn Functionality**: Certificates can be burned when products are consumed

### 🔒 Security & Trust
- **UUPS Upgradeable**: Contracts can be upgraded without losing state
- **Access Control**: Role-based permissions for different user types
- **Reentrancy Protection**: Comprehensive security against reentrancy attacks
- **Input Validation**: Extensive validation of all user inputs

### 💰 Economic Model
- **Platform Fees**: Configurable fee structure for sustainable operation
- **Farmer Rewards**: Direct payments to farmers without intermediaries
- **Buyer Protection**: Funds held in escrow until successful delivery

## 🏗️ Architecture

### Core Contracts

#### OnchainFarmMarketplace
```solidity
contract OnchainFarmMarketplace is
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
```
**Responsibilities:**
- Product listing and management
- Order creation and lifecycle management
- Payment processing and escrow
- Dispute resolution
- Platform fee collection

**Key Functions:**
- `listProduct()` - List agricultural products for sale
- `createOrder()` - Create purchase orders with escrow
- `confirmDelivery()` - Release funds upon successful delivery
- `disputeOrder()` - Initiate dispute resolution process

#### OnchainFarmNFT
```solidity
contract OnchainFarmNFT is
    ERC721Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
```
**Responsibilities:**
- Minting product certificates
- Managing certificate metadata
- Certificate transfer and burning
- Integration with marketplace

**Key Functions:**
- `mintCertificate()` - Mint NFT certificates for verified products
- `setMetadataURI()` - Update certificate metadata
- `burn()` - Burn certificates when products are consumed

### Contract Relationships
```
┌─────────────────┐    ┌─────────────────┐
│   Marketplace   │◄──►│      NFT        │
│                 │    │   Certificates │
│ • Product Mgmt  │    │ • Verification │
│ • Order Mgmt    │    │ • Metadata     │
│ • Escrow        │    │ • Transfer     │
│ • Disputes      │    │                 │
└─────────────────┘    └─────────────────┘
         ▲
         │
    ┌─────────────────┐
    │   ERC1967Proxy  │
    │   (UUPS Proxy)  │
    └─────────────────┘
```

## 🚀 Getting Started

### Prerequisites

- [Foundry](https://getfoundry.sh/) - Ethereum development toolkit
- [Node.js](https://nodejs.org/) >= 18.0.0
- [Git](https://git-scm.com/)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd onchain-harvest-contract
   ```

2. **Install dependencies**
   ```bash
   forge install
   ```

3. **Build contracts**
   ```bash
   forge build
   ```

4. **Run tests**
   ```bash
   forge test
   ```

## 📖 Usage

### Local Development

1. **Start local blockchain**
   ```bash
   anvil
   ```

2. **Deploy contracts**
   ```bash
   forge script script/DeployOnchainFarm.s.sol --rpc-url http://localhost:8545 --broadcast --private-key <your-private-key>
   ```

### Contract Interaction Examples

#### Listing a Product
```solidity
// As a farmer
marketplace.listProduct(
    "Organic Tomatoes",           // name
    "Premium organic tomatoes",   // description
    "https://example.com/img.jpg", // image URL
    1 ether,                      // price per unit
    100,                          // quantity
    "Vegetables",                 // category
    "California"                  // location
);
```

#### Creating an Order
```solidity
// As a buyer
marketplace.createOrder{value: 2 ether}(
    productId,           // product to purchase
    2,                   // quantity
    "123 Main St, NY"    // delivery address
);
```

#### Minting a Certificate
```solidity
// Marketplace mints certificate for verified product
nft.mintCertificate(
    productId,           // associated product
    "Organic Tomatoes",  // product name
    true,                // is organic
    buyerAddress         // certificate recipient
);
```

## 🧪 Testing

The project includes comprehensive test suites covering all functionality:

```bash
# Run all tests
forge test

# Run with gas reporting
forge test --gas-report

# Run specific test file
forge test --match-path test/OnchainFarmMarketplace.t.sol

# Run with verbosity
forge test -vv
```

### Test Coverage

- ✅ **Marketplace Tests**: Product listing, order management, escrow, disputes
- ✅ **NFT Tests**: Certificate minting, metadata, transfers, burning
- ✅ **Security Tests**: Access control, reentrancy protection, input validation
- ✅ **Integration Tests**: Cross-contract functionality

## 🚢 Deployment

### Base Network Deployment

1. **Set environment variables**
   ```bash
   export PRIVATE_KEY=<your-private-key>
   export BASE_RPC_URL=<base-rpc-url>
   ```

2. **Deploy to Base**
   ```bash
   forge script script/DeployOnchainFarm.s.sol \
     --rpc-url $BASE_RPC_URL \
     --broadcast \
     --verify \
     --etherscan-api-key <etherscan-api-key>
   ```

### Contract Verification

Contracts are verified on Basescan for transparency:

```bash
forge verify-contract <contract-address> src/OnchainFarmMarketplace.sol:OnchainFarmMarketplace \
  --chain-id 8453 \
  --etherscan-api-key <api-key>
```

## 🔒 Security

### Security Measures

- **Upgradeable Contracts**: UUPS proxy pattern for secure upgrades
- **Access Control**: OpenZeppelin Ownable and custom modifiers
- **Reentrancy Protection**: Comprehensive guards against reentrancy attacks
- **Input Validation**: Extensive validation of all parameters
- **Emergency Pause**: Circuit breaker functionality for critical situations

### Audit Status

The contracts follow Cyfrin Updraft security patterns and best practices. For production deployment, we recommend:

- Third-party security audit
- Bug bounty program
- Ongoing security monitoring

### Known Limitations

- Single token payment (ETH only)
- No partial order fulfillment
- Centralized dispute resolution

## 🤝 Contributing

We welcome contributions from the community! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Workflow

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and add tests
4. Ensure all tests pass: `forge test`
5. Format code: `forge fmt`
6. Submit a pull request

### Code Standards

- Follow Solidity style guide
- Comprehensive test coverage (>90%)
- Gas optimization considerations
- Clear documentation and comments

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

- **Documentation**: [docs.onchainfarm.com](https://docs.onchainfarm.com)
- **Discord**: [Join our community](https://discord.gg/onchainfarm)
- **Twitter**: [@OnchainFarm](https://twitter.com/OnchainFarm)
- **Email**: support@onchainfarm.com

## 🙏 Acknowledgments

- [OpenZeppelin](https://openzeppelin.com/) - For secure, audited smart contract libraries
- [Foundry](https://getfoundry.sh/) - For the excellent Ethereum development toolkit
- [Base](https://base.org/) - For providing a robust Layer 2 infrastructure
- [Cyfrin](https://cyfrin.io/) - For security patterns and best practices

---

**Built with ❤️ for transparent agricultural commerce**
