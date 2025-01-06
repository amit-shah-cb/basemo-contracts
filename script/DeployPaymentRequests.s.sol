// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;


import {Script} from "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

import {PaymentRequests} from "../src/PaymentRequests.sol";

contract DeployPaymentRequests is Script {
    PaymentRequests public pr;
    ERC1967Proxy proxy;
    address owner;
    address usdc;
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        owner = vm.envAddress("OWNER");
        usdc = vm.envAddress("USDC_ADDRESS");
        PaymentRequests implementation = new PaymentRequests();
        // Deploy the proxy and initialize the contract through the proxy
       
        proxy = new ERC1967Proxy(address(implementation), abi.encodeCall(implementation.initialize,        
            (owner)));
        pr = PaymentRequests(address(proxy));  
        vm.stopBroadcast();
    }
}
