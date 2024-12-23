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
        owner = makeAddr("owner");
        newOwner = makeAddr("newOwner");
        proxy = new ERC1967Proxy(address(implementation), abi.encodeCall(implementation.initialize, (owner)));
        pr = PaymentRequests(address(proxy));
        
       
               
    }
    
    function testCreatePaymentRequest() public {
        pr.createPaymentRequest(address(2), 1000, "Test payment request");
    }


}