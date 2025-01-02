// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;


import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import { PaymentRequests } from "../src/PaymentRequests.sol";
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

    function setUp() public {
        PaymentRequests implementation = new PaymentRequests();
        // address usdcAddress = 0x83358384d0c96f5027154e075b6b38f35e916523;
        // usdc = IERC20(usdcAddress);
        owner = makeAddr("owner");
        newOwner = makeAddr("newOwner");
        proxy = new ERC1967Proxy(address(implementation), abi.encodeCall(implementation.initialize, (owner)));
        pr = PaymentRequests(address(proxy));
        assert(pr.owner() == owner);
    }
    
    function testCreatePaymentRequest() public {
        pr.createPaymentRequest(msg.sender, address(2), address(3), 1000, "Test payment request");
        PaymentRequests.PaymentData memory paymentData = pr.getPaymentDetails(0);
        console.log("paymentData.receiver", paymentData.publicMemo);
        assert(paymentData.receiver == msg.sender);
        assert(paymentData.payee == address(2));
        assert(paymentData.token == address(3));
        assert(paymentData.amount == 1000);
        assert(keccak256(abi.encode(paymentData.publicMemo)) == keccak256(abi.encode("Test payment request")));

        string memory uri = pr.tokenURI(0);
        console.log("uri", uri);
    }

    function testPayPaymentRequest() public {
    }

    function testPayPaymentRequestWithPermit() public {
        //TODO: test with permit
        //First get eip712 approve tx
        // then run multicall with approve + payPaymentRequest tx
    }


}