// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {OnchainFarmMarketplace} from "../src/OnchainFarmMarketplace.sol";
import {OnchainFarmNFT} from "../src/OnchainFarmNFT.sol";

contract OnchainFarmNFTTest is Test {
    OnchainFarmMarketplace marketplace;
    OnchainFarmNFT nft;
    ERC1967Proxy marketplaceProxy;
    ERC1967Proxy nftProxy;

    address owner = makeAddr("owner");
    address marketplaceAddr;
    address user = makeAddr("user");

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
            owner, // fee recipient
            250 // platform fee
        );
        marketplaceProxy = new ERC1967Proxy(address(marketplaceImpl), marketplaceInitData);
        marketplace = OnchainFarmMarketplace(address(marketplaceProxy));
        marketplaceAddr = address(marketplaceProxy);

        // Set marketplace address in NFT
        nft.setMarketplaceContract(marketplaceAddr);

        vm.stopPrank();
    }

    function test_Initialization() public {
        assertEq(nft.name(), "OnchainFarm Certificate");
        assertEq(nft.symbol(), "OFC");
        assertEq(nft.tokenCount(), 0);
    }

    function test_MintCertificate() public {
        vm.prank(marketplaceAddr);
        uint256 tokenId = nft.mintCertificate(
            1, // productId
            "Organic Tomatoes",
            true, // isOrganic
            user // recipient
        );

        assertEq(tokenId, 1);
        assertEq(nft.tokenCount(), 1);
        assertEq(nft.ownerOf(1), user);

        (
            uint256 certProductId,
            string memory productName,
            bool isOrganic,
            bool isSustainable,
            address recipient,
            address issuer,
            uint256 issuedAt,
            string memory metadataURI
        ) = nft.certificates(1);

        assertEq(certProductId, 1);
        assertEq(productName, "Organic Tomatoes");
        assertTrue(isOrganic);
        assertFalse(isSustainable); // Default value
        assertEq(recipient, user);
        assertEq(issuer, marketplaceAddr);
        assertGt(issuedAt, 0);
        assertEq(metadataURI, "");
    }

    function test_MintCertificate_RevertIfNotMarketplace() public {
        vm.prank(user);
        vm.expectRevert();
        nft.mintCertificate(
            1,
            "Organic Tomatoes",
            true,
            user
        );
    }

    function test_SetMetadataURI() public {
        // Mint certificate first
        vm.prank(marketplaceAddr);
        uint256 tokenId = nft.mintCertificate(
            1,
            "Organic Tomatoes",
            true,
            user
        );

        // Set metadata URI
        vm.prank(user);
        nft.setMetadataURI(tokenId, "https://example.com/metadata/1");

        (, , , , , , , string memory metadataURI) = nft.certificates(tokenId);
        assertEq(metadataURI, "https://example.com/metadata/1");
    }

    function test_SetMetadataURI_RevertIfNotOwner() public {
        // Mint certificate first
        vm.prank(marketplaceAddr);
        uint256 tokenId = nft.mintCertificate(
            1,
            "Organic Tomatoes",
            true,
            user
        );

        // Try to set metadata as different user
        address otherUser = makeAddr("otherUser");
        vm.prank(otherUser);
        vm.expectRevert();
        nft.setMetadataURI(tokenId, "https://example.com/metadata/1");
    }

    function test_SetMetadataURI_MarketplaceCanSet() public {
        // Mint certificate first
        vm.prank(marketplaceAddr);
        uint256 tokenId = nft.mintCertificate(
            1,
            "Organic Tomatoes",
            true,
            user
        );

        // Marketplace can set metadata even if not owner
        vm.prank(marketplaceAddr);
        nft.setMetadataURI(tokenId, "https://example.com/metadata/1");

        (, , , , , , , string memory metadataURI) = nft.certificates(tokenId);
        assertEq(metadataURI, "https://example.com/metadata/1");
    }

    function test_TokenURI() public {
        // Mint certificate first
        vm.prank(marketplaceAddr);
        uint256 tokenId = nft.mintCertificate(
            1,
            "Organic Tomatoes",
            true,
            user
        );

        // Set metadata URI
        vm.prank(user);
        nft.setMetadataURI(tokenId, "https://example.com/metadata/1");

        // Check tokenURI
        assertEq(nft.tokenURI(tokenId), "https://example.com/metadata/1");
    }

    function test_GetCertificate() public {
        // Mint certificate first
        vm.prank(marketplaceAddr);
        uint256 tokenId = nft.mintCertificate(
            1,
            "Organic Tomatoes",
            true,
            user
        );

        // Get certificate details
        OnchainFarmNFT.Certificate memory cert = nft.getCertificate(tokenId);

        assertEq(cert.productId, 1);
        assertEq(cert.productName, "Organic Tomatoes");
        assertTrue(cert.isOrganic);
        assertFalse(cert.isSustainable);
        assertEq(cert.recipient, user);
        assertEq(cert.issuer, marketplaceAddr);
        assertGt(cert.issuedAt, 0);
        assertEq(cert.metadataURI, "");
    }

    function test_GetCertificate_RevertIfTokenNotFound() public {
        vm.expectRevert();
        nft.getCertificate(999);
    }

    function test_TokenURI_RevertIfTokenNotFound() public {
        vm.expectRevert();
        nft.tokenURI(999);
    }

    function test_SetMetadataURI_RevertIfTokenNotFound() public {
        vm.prank(user);
        vm.expectRevert();
        nft.setMetadataURI(999, "https://example.com/metadata/1");
    }

    function test_TransferCertificate() public {
        // Mint certificate first
        vm.prank(marketplaceAddr);
        uint256 tokenId = nft.mintCertificate(
            1,
            "Organic Tomatoes",
            true,
            user
        );

        // Transfer to another user
        address recipient = makeAddr("recipient");
        vm.prank(user);
        nft.transferFrom(user, recipient, tokenId);

        assertEq(nft.ownerOf(tokenId), recipient);
    }

    function test_BurnCertificate() public {
        // This test would require implementing burn functionality in the NFT contract
        // For now, ERC721 doesn't have burn by default, so we'll skip this test
    }

    function test_MultipleCertificates() public {
        // Mint multiple certificates
        vm.startPrank(marketplaceAddr);
        uint256 tokenId1 = nft.mintCertificate(1, "Tomatoes", true, user);
        uint256 tokenId2 = nft.mintCertificate(2, "Apples", false, user);
        vm.stopPrank();

        assertEq(tokenId1, 1);
        assertEq(tokenId2, 2);
        assertEq(nft.tokenCount(), 2);
        assertEq(nft.ownerOf(1), user);
        assertEq(nft.ownerOf(2), user);

        // Check different certificate data
        OnchainFarmNFT.Certificate memory cert1 = nft.getCertificate(1);
        OnchainFarmNFT.Certificate memory cert2 = nft.getCertificate(2);

        assertEq(cert1.productId, 1);
        assertEq(cert1.productName, "Tomatoes");
        assertTrue(cert1.isOrganic);

        assertEq(cert2.productId, 2);
        assertEq(cert2.productName, "Apples");
        assertFalse(cert2.isOrganic);
    }
}