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

contract PaymentRequests is  Initializable,OwnableUpgradeable,ERC1155Upgradeable,ERC1155URIStorageUpgradeable, UUPSUpgradeable  {
     struct PaymentData {
        address payee;
        uint256 amount;
        bool paid;
        string description;
    }

     /// @custom:storage-location erc7201:payment.requests.storage
    struct PaymentRequestStorage {
        // tokenId => PaymentData
        mapping(uint256 => PaymentData) paymentDetails;
        uint256 nextTokenId;
    }

   
    bytes32 private constant PAYMENT_STORAGE_LOCATION = 0x0000000000000000000000000000000000000000000000000000000000000000; // Calculate this value

    function _getPaymentStorage() private pure returns (PaymentRequestStorage storage $) {
        assembly {
            $.slot := PAYMENT_STORAGE_LOCATION
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        OwnableUpgradeable.__Ownable_init(initialOwner);
        // ERC20Upgradeable.__ERC20_init("Points", "PTS");
        // //we dont want to call the initializer of ERC20Upgradeable again
        // ERC20BurnableUpgradeable.__ERC20Burnable_init();
        // ERC20PermitUpgradeable.__ERC20Permit_init("Points");
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

    function createPaymentRequest(
        address payee,
        uint256 amount,
        string calldata description
    ) external returns (uint256) {
        PaymentRequestStorage storage $ = _getPaymentStorage();
        uint256 tokenId = $.nextTokenId++;
        
        $.paymentDetails[tokenId] = PaymentData({
            payee: payee,
            amount: amount,
            paid: false,
            description: description
        });

        _mint(payee, tokenId, 1, "");
        
        // emit PaymentRequestCreated(tokenId, payee, amount, description);
        
        return tokenId;
    }

    function getPaymentDetails(uint256 tokenId) external view returns (PaymentData memory) {
        return _getPaymentStorage().paymentDetails[tokenId];
    }
    
    // function decimals() public view virtual override returns (uint8) {
    //     //same decimals as USDC token
    //     return 6;
    // }
    
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
