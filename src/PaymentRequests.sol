// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract PaymentRequests is  Initializable,OwnableUpgradeable,ERC721EnumerableUpgradeable, UUPSUpgradeable  {
     struct PaymentData {
        address receiver;
        address payee;
        address token;
        uint256 amount;
        bool paid;
        string publicMemo;
    }

    event PaymentRequestCreated(uint256 tokenId, address payee, uint256 amount, string description);
    event PaymentRequestPaid(uint256 tokenId);

     /// @custom:storage-location erc7201:payment.requests.storage
    struct PaymentRequestStorage {
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
        UUPSUpgradeable.__UUPSUpgradeable_init();
        ERC721Upgradeable.__ERC721_init("Payment Requests", "PR");
        ERC721EnumerableUpgradeable.__ERC721Enumerable_init();
    }

   
    function createPaymentRequest(
        address receiver,
        address payee,
        address token,
        uint256 amount,
        string calldata description
    ) external returns (uint256) {
        PaymentRequestStorage storage $ = _getPaymentStorage();
        uint256 tokenId = $.nextTokenId++;
        
        $.paymentDetails[tokenId] = PaymentData({
            receiver: receiver,
            payee: payee,
            token: token,
            amount: amount,
            paid: false,
            publicMemo: description
        });
        _safeMint(payee, tokenId);        
        emit PaymentRequestCreated(tokenId, payee, amount, description);
        return tokenId;
    }

    function getPaymentDetails(uint256 tokenId) external view returns (PaymentData memory) {
        return _getPaymentStorage().paymentDetails[tokenId];
    }

    function settlePaymentRequest(
        uint256 tokenId      
    ) external returns (uint256) {
        PaymentRequestStorage storage $ = _getPaymentStorage(); 
        PaymentData memory paymentData = $.paymentDetails[tokenId];
        require(paymentData.payee != address(0), "Payment request not found");
        require(!paymentData.paid, "Payment already made");        
        paymentData.paid = true;

        $.paymentDetails[tokenId]= paymentData;
        //TODO: transfer the amount to the payee

        // IERC20(paymentData.token).transerFrom(paymentData.payee, paymentData.receiver, paymentData.amount);
        emit PaymentRequestPaid(tokenId);
        return tokenId;
    }

    
    function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721Upgradeable, IERC721) {
        revert("Not allowed");
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        PaymentData memory paymentData = _getPaymentStorage().paymentDetails[tokenId];
        string memory publicMemo = paymentData.publicMemo;
        string memory json = Base64.encode(
                bytes(string(
                    abi.encodePacked(
                        '{"name": "Payment Request",',
                        '"image_data": "', getSvg(publicMemo), '",',
                        '"attributes": []}'
                    )
                ))
            );
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function getSvg(string memory description) private pure returns (string memory) {
        string memory svg;
        svg = string.concat("<svg width='350px' height='350px' viewBox='0 0 350 350' fill='none' xmlns='http://www.w3.org/2000/svg'><text x='10' y='175' fill='blue'>",description,"</text></svg>");
        return svg;
    }    

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
