// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

import {PaymentRequestsV2} from "../src/test/PaymentRequestsV2.sol";

contract CreatePaymentRequests is Script {
    PaymentRequestsV2 public pr;
    ERC1967Proxy proxy;
    address owner;
    address usdc;
    address proxyAddress;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        owner = vm.envAddress("OWNER");
        usdc = vm.envAddress("USDC_ADDRESS");
        proxyAddress = vm.envAddress("PROXY_ADDRESS");

        pr = PaymentRequestsV2(proxyAddress);  

        console.log("Version:", pr.getVersion());   
        console.log("Created balance of owner:", pr.createdBalanceOf(owner));
        console.log("Balance of owner:", pr.balanceOf(owner));
        console.log("Token uri:", pr.tokenURI(0));
        vm.stopBroadcast();
    }
}
