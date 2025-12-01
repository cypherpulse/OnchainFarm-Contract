// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {OnchainFarmMarketplace} from "../src/OnchainFarmMarketplace.sol";
import {OnchainFarmNFT} from "../src/OnchainFarmNFT.sol";

contract DeployOnchainFarm is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy NFT implementation
        OnchainFarmNFT nftImpl = new OnchainFarmNFT();

        // Deploy NFT proxy
        bytes memory nftInitData = abi.encodeWithSelector(
            OnchainFarmNFT.initialize.selector,
            "OnchainFarm Certificate",
            "OFC",
            address(0) // marketplace address will be set later
        );
        ERC1967Proxy nftProxy = new ERC1967Proxy(address(nftImpl), nftInitData);

        // Deploy Marketplace implementation
        OnchainFarmMarketplace marketplaceImpl = new OnchainFarmMarketplace();

        // Deploy Marketplace proxy
        bytes memory marketplaceInitData = abi.encodeWithSelector(
            OnchainFarmMarketplace.initialize.selector,
            address(nftProxy), // nft contract
            msg.sender, // fee recipient
            250 // platform fee 2.5%
        );
        ERC1967Proxy marketplaceProxy = new ERC1967Proxy(address(marketplaceImpl), marketplaceInitData);

        // Set marketplace address in NFT
        OnchainFarmNFT(address(nftProxy)).setMarketplaceContract(address(marketplaceProxy));

        vm.stopBroadcast();

        console.log("NFT Proxy deployed at:", address(nftProxy));
        console.log("Marketplace Proxy deployed at:", address(marketplaceProxy));
    }
}