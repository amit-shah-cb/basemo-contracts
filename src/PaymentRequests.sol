// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
    event PaymentRequestCancelled(uint256 tokenId);

     /// @custom:storage-location erc7201:payment.requests.storage
    struct PaymentRequestStorage {
        mapping(uint256 => PaymentData) paymentDetails;
        uint256 nextTokenId;
        mapping(address creator => mapping(uint256 index => uint256)) _createdTokens;
        mapping(uint256 tokenId => uint256) _createdTokensIndex;
        mapping(address owner => uint256) _createdBalances;
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
        address token,
        address payee,
        uint256 amount,
        string calldata description
    ) external returns (uint256) {
        PaymentRequestStorage storage $ = _getPaymentStorage();
        uint256 tokenId = $.nextTokenId++;
        
        $.paymentDetails[tokenId] = PaymentData({
            receiver: msg.sender,
            payee: payee,
            token: token,
            amount: amount,
            paid: false,
            publicMemo: description
        });
        $._createdBalances[msg.sender]+=1;
        _addTokenToCreatorEnumeration(msg.sender, tokenId);
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
        
        //We dont check msg.sender is the payee because anyone can settle the payment
        require(paymentData.payee != address(0), "Payment request not found");        
        require(!paymentData.paid, "Payment already made");        
        
        $.paymentDetails[tokenId].paid = true;
        IERC20 token = IERC20(paymentData.token);
        bool success = token.transferFrom(msg.sender, paymentData.receiver, paymentData.amount);
        if(!success){
            revert("Transfer failed");
        }
        emit PaymentRequestPaid(tokenId);
        return tokenId;
    }

    function cancelPaymentRequest(uint256 tokenId) external returns (uint256) {
        PaymentRequestStorage storage $ = _getPaymentStorage(); 
        PaymentData memory paymentData = $.paymentDetails[tokenId];
        require(msg.sender == paymentData.receiver, "Only the creator can cancel the payment request");
        $.paymentDetails[tokenId].receiver = address(0);
        $._createdBalances[msg.sender]-=1;        
        _removeTokenFromCreatorEnumeration(msg.sender, tokenId);
        //send to 0 address
        super._burn(tokenId);
        emit PaymentRequestCancelled(tokenId);
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

    function createdBalanceOf(address owner) public view virtual returns (uint256) {
        PaymentRequestStorage storage $ = _getPaymentStorage();
        if (owner == address(0)) {
            revert ERC721InvalidOwner(address(0));
        }
        return $._createdBalances[owner];
    }

    function _addTokenToCreatorEnumeration(address creator, uint256 tokenId) private {
        PaymentRequestStorage storage $ = _getPaymentStorage();
        uint256 length = createdBalanceOf(creator)-1;
        $._createdTokens[creator][length] = tokenId;
        $._createdTokensIndex[tokenId] = length;
    }

     function _removeTokenFromCreatorEnumeration(address creator, uint256 tokenId) private {
        PaymentRequestStorage storage $ = _getPaymentStorage();
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = createdBalanceOf(creator)+1;
        uint256 tokenIndex = $._createdTokensIndex[tokenId];

        mapping(uint256 index => uint256) storage _createdTokensByOwner = $._createdTokens[creator];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _createdTokensByOwner[lastTokenIndex];
            _createdTokensByOwner[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            $._createdTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete $._createdTokensIndex[tokenId];
        delete _createdTokensByOwner[lastTokenIndex];
    }

    function tokenOfCreatorByIndex(address creator, uint256 index) public view virtual returns (uint256) {
        PaymentRequestStorage storage $ = _getPaymentStorage();
        if (index >= createdBalanceOf(creator)) {
            revert ERC721OutOfBoundsIndex(creator, index);
        }
        return $._createdTokens[creator][index];
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
