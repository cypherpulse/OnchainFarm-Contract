@echo off
echo Starting individual file commits for OnchainFarm project...
echo Total files to commit: 14
echo.

REM Set git author
git config user.name "cypherpulse"
git config user.email "johnbradill67@gmail.com"

REM Base commit message
set "BASE_MSG=Implemented OnchainFarm decentralized marketplace with NFT certificates on Base

- Deployed on Base Network: Complete marketplace and NFT system optimized for Base L2
- Built Decentralized Marketplace: UUPS upgradeable marketplace with escrow payments, order management, and dispute resolution
- Created NFT Certification System: ERC-721 certificates for verified agricultural products with metadata management
- Implemented Security First: Reentrancy protection, access control, and Cyfrin Updraft security patterns
- Added Comprehensive Testing: Full test suite covering marketplace, NFT, and integration functionality
- Created Professional Documentation: Enterprise-grade README with architecture, deployment, and usage guides
- Enabled Gas Optimization: ViaIR compilation enabled for optimal performance on Base network

Key Features Implemented:
• Product listing with escrow-based payments
• Order lifecycle management (create → confirm → ship → deliver)
• NFT certificates for product authenticity verification
• Dispute resolution system with buyer/seller arbitration
• Platform fee collection and revenue model
• Upgradeable contracts via UUPS proxy pattern

Tech Stack: Solidity ^0.8.19, OpenZeppelin Contracts v5, Foundry, Base Network"

echo [1/14] Adding and committing: .gitignore
git add .gitignore
git commit -m "Add .gitignore%n%n%BASE_MSG%" --author="cypherpulse <johnbradill67@gmail.com>"
echo Committed: .gitignore
echo.

echo [2/14] Adding and committing: .gitmodules
git add .gitmodules
git commit -m "Add .gitmodules%n%n%BASE_MSG%" --author="cypherpulse <johnbradill67@gmail.com>"
echo Committed: .gitmodules
echo.

echo [3/14] Adding and committing: foundry.toml
git add foundry.toml
git commit -m "Add foundry.toml%n%n%BASE_MSG%" --author="cypherpulse <johnbradill67@gmail.com>"
echo Committed: foundry.toml
echo.

echo [4/14] Adding and committing: foundry.lock
git add foundry.lock
git commit -m "Add foundry.lock%n%n%BASE_MSG%" --author="cypherpulse <johnbradill67@gmail.com>"
echo Committed: foundry.lock
echo.

echo [5/14] Adding and committing: lib/forge-std/
git add lib/forge-std/
git commit -m "Add forge-std library%n%n%BASE_MSG%" --author="cypherpulse <johnbradill67@gmail.com>"
echo Committed: lib/forge-std/
echo.

echo [6/14] Adding and committing: lib/openzeppelin-contracts/
git add lib/openzeppelin-contracts/
git commit -m "Add OpenZeppelin contracts library%n%n%BASE_MSG%" --author="cypherpulse <johnbradill67@gmail.com>"
echo Committed: lib/openzeppelin-contracts/
echo.

echo [7/14] Adding and committing: lib/openzeppelin-contracts-upgradeable/
git add lib/openzeppelin-contracts-upgradeable/
git commit -m "Add OpenZeppelin upgradeable contracts library%n%n%BASE_MSG%" --author="cypherpulse <johnbradill67@gmail.com>"
echo Committed: lib/openzeppelin-contracts-upgradeable/
echo.

echo [8/14] Adding and committing: script/DeployOnchainFarm.s.sol
git add script/DeployOnchainFarm.s.sol
git commit -m "Add deployment script%n%n%BASE_MSG%" --author="cypherpulse <johnbradill67@gmail.com>"
echo Committed: script/DeployOnchainFarm.s.sol
echo.

echo [9/14] Adding and committing: src/OnchainFarmMarketplace.sol
git add src/OnchainFarmMarketplace.sol
git commit -m "Add OnchainFarm marketplace contract%n%n%BASE_MSG%" --author="cypherpulse <johnbradill67@gmail.com>"
echo Committed: src/OnchainFarmMarketplace.sol
echo.

echo [10/14] Adding and committing: src/OnchainFarmNFT.sol
git add src/OnchainFarmNFT.sol
git commit -m "Add OnchainFarm NFT certificate contract%n%n%BASE_MSG%" --author="cypherpulse <johnbradill67@gmail.com>"
echo Committed: src/OnchainFarmNFT.sol
echo.

echo [11/14] Adding and committing: test/OnchainFarmMarketplace.t.sol
git add test/OnchainFarmMarketplace.t.sol
git commit -m "Add marketplace contract tests%n%n%BASE_MSG%" --author="cypherpulse <johnbradill67@gmail.com>"
echo Committed: test/OnchainFarmMarketplace.t.sol
echo.

echo [12/14] Adding and committing: test/OnchainFarmNFT.t.sol
git add test/OnchainFarmNFT.t.sol
git commit -m "Add NFT contract tests%n%n%BASE_MSG%" --author="cypherpulse <johnbradill67@gmail.com>"
echo Committed: test/OnchainFarmNFT.t.sol
echo.

echo [13/14] Adding and committing: README.md
git add README.md
git commit -m "Add project documentation%n%n%BASE_MSG%" --author="cypherpulse <johnbradill67@gmail.com>"
echo Committed: README.md
echo.

echo [14/14] Adding and committing: enhance scripts
git add enhance_onchainfarm.ps1 enhance_onchainfarm.sh
git commit -m "Add enhancement scripts%n%n%BASE_MSG%" --author="cypherpulse <johnbradill67@gmail.com>"
echo Committed: enhancement scripts
echo.

echo All files have been individually committed!
echo.
echo Next steps:
echo 1. Review commits: git log --oneline
echo 2. Push to remote: git push -u origin master
echo.
echo Repository: https://github.com/cypherpulse/OnchainFarm-Contract
pause