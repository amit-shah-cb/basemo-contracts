// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

import {PaymentRequests} from "../src/PaymentRequests.sol";

contract DeployBasedmo is Script {
    PaymentRequests public pr;
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

        pr = PaymentRequests(proxyAddress);  
        pr.createPaymentRequest(usdc, owner, 100, "Test payment request");     
        vm.stopBroadcast();
    }
}
