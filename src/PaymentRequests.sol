// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";

contract PaymentRequests is  Initializable,OwnableUpgradeable,ERC1155Upgradeable,ERC1155URIStorageUpgradeable,ERC20Upgradeable, ERC20BurnableUpgradeable,ERC20PermitUpgradeable, UUPSUpgradeable  {
    
     /// @custom:storage-location erc7201:coinbase.storage.PointsUpgradeable 
    struct PointsUpgradeableStorage {
       uint rewardRateBps_;
       uint256[] lootBoxRarity_;
       mapping(uint256 productId => uint256 redeem) rewardRedemption;
    }

    // keccak256(abi.encode(uint256(keccak256("coinbase.storage.PointsUpgradeable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant PointsUpgradeableStorageLocation = 0x102ca4916efc5d30e5730936056d8c2fd2e983f4ec49165e465c9b7ff32d4800;
    //To use:  SlicerPurchasableHookStorage storage $ = _getSlicerPurchasableHookStorage(); $.x = 1;
    function _getPointsUpgradeableStorage() private pure returns (PointsUpgradeableStorage storage $) {
        assembly {
            $.slot := PointsUpgradeableStorageLocation
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        OwnableUpgradeable.__Ownable_init(initialOwner);
        ERC20Upgradeable.__ERC20_init("Points", "PTS");
        //we dont want to call the initializer of ERC20Upgradeable again
        ERC20BurnableUpgradeable.__ERC20Burnable_init();
        ERC20PermitUpgradeable.__ERC20Permit_init("Points");
        UUPSUpgradeable.__UUPSUpgradeable_init();
        // PointsUpgradeableStorage storage $ = _getPointsUpgradeableStorage();
        ERC1155Upgradeable.__ERC1155_init("uri");
        ERC1155URIStorageUpgradeable.__ERC1155URIStorage_init();
        //Now we dont want to call ERC1155 intializer again so we used unchained for extensions
        
        // $.rewardRateBps_ = rewardRate;
        // //1%,2%,3%,5% of users point balance
        // $.lootBoxRarity_ = lootBoxRarity;        
    }

     // Required override
    function uri(uint256 tokenId) 
        public
        view
        virtual
        override(ERC1155Upgradeable, ERC1155URIStorageUpgradeable)
        returns (string memory)
    {
        return super.uri(tokenId);
    }

    
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        //same decimals as USDC token
        return 6;
    }
    
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
