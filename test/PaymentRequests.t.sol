// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;


import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import { PaymentRequests } from "../src/PaymentRequests.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PaymentRequestsTest is Test {
    PaymentRequests pr;
    ERC1967Proxy proxy;
    address owner;
    address newOwner;
    address productModuleAddress;
    address maliciousAddress;
    address usdcAddress;
    uint rewardRate;
    address entropyAddress;
    address entropyProvider;
    address receiver;
    address payee;

    function setUp() public {
        PaymentRequests implementation = new PaymentRequests();
        usdcAddress = address(0x83358384D0c96f5027154e075B6B38F35e916523);
        receiver = makeAddr("receiver");
        payee = makeAddr("payee");
        // usdc = IERC20(usdcAddress);
        owner = makeAddr("owner");
        newOwner = makeAddr("newOwner");
        proxy = new ERC1967Proxy(address(implementation), abi.encodeCall(implementation.initialize, (owner)));
        pr = PaymentRequests(address(proxy));
        assert(pr.owner() == owner);
    }
    
    function testCreatePaymentRequest() public {
        vm.startPrank(receiver);
        pr.createPaymentRequest(usdcAddress, payee, 1000, "Test payment request");
        pr.createPaymentRequest(usdcAddress, payee, 2000, "Test payment request 2");
        pr.createPaymentRequest(usdcAddress, payee, 3000, "Test payment request 3");
        vm.stopPrank();
        PaymentRequests.PaymentData memory paymentData = pr.getPaymentDetails(0);

        assert(paymentData.receiver == receiver);
        assert(paymentData.payee == payee);
        assert(paymentData.token == usdcAddress);
        assert(paymentData.amount == 1000);
        assert(keccak256(abi.encode(paymentData.publicMemo)) == keccak256(abi.encode("Test payment request")));

        string memory uri = pr.tokenURI(0);
        assert(keccak256(abi.encode(uri)) == keccak256(abi.encode("data:application/json;base64,eyJuYW1lIjogIlBheW1lbnQgUmVxdWVzdCAjMCIsImRlc2NyaXB0aW9uIjogIlBheW1lbnQgUmVxdWVzdCBmcm9tIDB4YjZkNDgwNWJmNjk0M2M1ODc1YzBjN2I2N2VkYTI0YjJiZGFjYmY2ZSBmb3IgMTAwMCAweDgzMzU4Mzg0ZDBjOTZmNTAyNzE1NGUwNzViNmIzOGYzNWU5MTY1MjMiLCJpbWFnZSI6ICI8c3ZnIHdpZHRoPSczNTBweCcgaGVpZ2h0PSczNTBweCcgdmlld0JveD0nMCAwIDM1MCAzNTAnIHhtbG5zPSdodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2Zyc+PHRleHQgeD0nNTAlJyB5PSc1MCUnIGRvbWluYW50LWJhc2VsaW5lPSdtaWRkbGUnIHRleHQtYW5jaG9yPSdtaWRkbGUnIGZpbGw9J3doaXRlJz5UZXN0IHBheW1lbnQgcmVxdWVzdDwvdGV4dD48L3N2Zz4iLCJhdHRyaWJ1dGVzIjogW119")));        
        uint256 tokenIndex = pr.tokenOfOwnerByIndex(payee, 1);
        assert(tokenIndex == 1);
        paymentData = pr.getPaymentDetails(1);
        assert(paymentData.receiver == receiver);
        assert(paymentData.payee == payee);
        assert(paymentData.token == usdcAddress);
        assert(paymentData.amount == 2000);
        assert(keccak256(abi.encode(paymentData.publicMemo)) == keccak256(abi.encode("Test payment request 2")));

        assert(pr.createdBalanceOf(receiver) == 3);
        assert(pr.createdBalanceOf(payee) == 0);
        assert(pr.balanceOf(receiver) == 0);
        assert(pr.balanceOf(payee) == 3);
       
        vm.startPrank(payee);
        vm.expectRevert(bytes("Only the creator can cancel the payment request"));
        pr.cancelPaymentRequest(1);
        vm.stopPrank();
    

        vm.startPrank(receiver);
        pr.cancelPaymentRequest(1);
        vm.stopPrank();

        assert(pr.createdBalanceOf(receiver) == 2);
        assert(pr.createdBalanceOf(payee) == 0);
        assert(pr.balanceOf(receiver) == 0);
        assert(pr.balanceOf(payee) == 2);

        paymentData = pr.getPaymentDetails(1);
        assert(paymentData.receiver == address(0));
        assert(paymentData.payee == payee);
        assert(paymentData.token == usdcAddress);
        assert(paymentData.amount == 2000);
        assert(keccak256(abi.encode(paymentData.publicMemo)) == keccak256(abi.encode("Test payment request 2")));

         
    }

    function testPayPaymentRequest() public {
        bytes32 storageLocation = keccak256(abi.encode(uint256(keccak256("coinbase.storage.PaymentRequests")) - 1)) & ~bytes32(uint256(0xff));
        assert(storageLocation == 0x9fe4f3caa6e7bcc6a7c922cbcf4c12b3cca2fd8b3e555039c554d4efe351b300);
    }

    function testSettlePaymentRequest() public {

        vm.prank(receiver);
        pr.createPaymentRequest(usdcAddress, payee, 1000, "Test");
        vm.stopPrank();

        PaymentRequests.PaymentData memory paymentData = pr.getPaymentDetails(0);
        assert(paymentData.receiver == receiver);
        assert(paymentData.payee == payee);
        assert(paymentData.token == usdcAddress);
        assert(paymentData.amount == 1000);
        assert(keccak256(abi.encode(paymentData.publicMemo)) == keccak256(abi.encode("Test")));
        assert(paymentData.paid == false);


        vm.mockCall(
            usdcAddress,
            abi.encodeWithSelector(IERC20.transferFrom.selector, payee, receiver, 1000),
            abi.encode(true)
        );

        vm.prank(payee);
        pr.settlePaymentRequest(0);
        vm.stopPrank();               

        paymentData = pr.getPaymentDetails(0);
        assert(paymentData.receiver == receiver);
        assert(paymentData.payee == payee);
        assert(paymentData.token == usdcAddress);
        assert(paymentData.amount == 1000);
        assert(keccak256(abi.encode(paymentData.publicMemo)) == keccak256(abi.encode("Test")));
        assert(paymentData.paid == true);
    }

    function testFailedTransferSettlePaymentRequest() public {

        vm.prank(receiver);
        pr.createPaymentRequest(usdcAddress, payee, 1000, "Test");
        vm.stopPrank();

        PaymentRequests.PaymentData memory paymentData = pr.getPaymentDetails(0);
        assert(paymentData.receiver == receiver);
        assert(paymentData.payee == payee);
        assert(paymentData.token == usdcAddress);
        assert(paymentData.amount == 1000);
        assert(keccak256(abi.encode(paymentData.publicMemo)) == keccak256(abi.encode("Test")));
        assert(paymentData.paid == false);


        vm.mockCall(
            usdcAddress,
            abi.encodeWithSelector(IERC20.transferFrom.selector, payee, receiver, 1000),
            abi.encode(false)
        );

        vm.prank(payee);
        pr.settlePaymentRequest(0);
        vm.stopPrank();               

        vm.expectRevert("Transfer failed");
        paymentData = pr.getPaymentDetails(0);
        assert(paymentData.receiver == receiver);
        assert(paymentData.payee == payee);
        assert(paymentData.token == usdcAddress);
        assert(paymentData.amount == 1000);
        assert(keccak256(abi.encode(paymentData.publicMemo)) == keccak256(abi.encode("Test")));
        assert(paymentData.paid == false);
    }


}