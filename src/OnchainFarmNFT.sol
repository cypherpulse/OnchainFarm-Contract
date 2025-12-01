// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// Custom errors
error OnchainFarmNFT__UnauthorizedAccess(address caller);
error OnchainFarmNFT__TokenNotFound(uint256 tokenId);
error OnchainFarmNFT__InvalidInput(string reason);

// Contract
contract OnchainFarmNFT is ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    // Type declarations
    struct Certificate {
        uint256 productId;
        string productName;
        bool isOrganic;
        bool isSustainable;
        address recipient;
        address issuer;
        uint256 issuedAt;
        string metadataURI;
    }

    // State variables
    uint256 public tokenCount;
    mapping(uint256 => Certificate) public certificates;
    address public marketplaceContract;

    // Events
    event CertificateMinted(uint256 indexed tokenId, uint256 indexed productId, address indexed recipient);
    event MetadataUpdated(uint256 indexed tokenId, string metadataURI);

    // Modifiers
    modifier onlyMarketplace() {
        _onlyMarketplace();
        _;
    }

    modifier tokenExists(uint256 _tokenId) {
        _tokenExists(_tokenId);
        _;
    }

    // Internal functions for modifiers
    function _onlyMarketplace() internal view {
        if (msg.sender != marketplaceContract) {
            revert OnchainFarmNFT__UnauthorizedAccess(msg.sender);
        }
    }

    function _tokenExists(uint256 _tokenId) internal view {
        if (_tokenId == 0 || _tokenId > tokenCount) {
            revert OnchainFarmNFT__TokenNotFound(_tokenId);
        }
    }

    // Functions

    // Initialize
    function initialize(string memory _name, string memory _symbol, address _marketplaceContract) external initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init(msg.sender);
        marketplaceContract = _marketplaceContract;
    }

    // External functions
    function mintCertificate(
        uint256 _productId,
        string memory _productName,
        bool _isOrganic,
        address _recipient
    ) external onlyMarketplace returns (uint256) {
        tokenCount++;
        _mint(_recipient, tokenCount);
        certificates[tokenCount] = Certificate({
            productId: _productId,
            productName: _productName,
            isOrganic: _isOrganic,
            isSustainable: false, // or add param
            recipient: _recipient,
            issuer: msg.sender,
            issuedAt: block.timestamp,
            metadataURI: ""
        });
        emit CertificateMinted(tokenCount, _productId, _recipient);
        return tokenCount;
    }

    function setMetadataURI(uint256 _tokenId, string memory _metadataUri) external tokenExists(_tokenId) {
        if (ownerOf(_tokenId) != msg.sender && msg.sender != marketplaceContract) {
            revert OnchainFarmNFT__UnauthorizedAccess(msg.sender);
        }
        certificates[_tokenId].metadataURI = _metadataUri;
        emit MetadataUpdated(_tokenId, _metadataUri);
    }

    function setMarketplaceContract(address _marketplace) external onlyOwner {
        marketplaceContract = _marketplace;
    }

    // View functions
    function getCertificate(uint256 _tokenId) external view tokenExists(_tokenId) returns (Certificate memory) {
        return certificates[_tokenId];
    }

    function tokenURI(uint256 _tokenId) public view override tokenExists(_tokenId) returns (string memory) {
        return certificates[_tokenId].metadataURI;
    }

    // Internal functions
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}