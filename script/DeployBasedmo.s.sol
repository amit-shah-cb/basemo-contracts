// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

import {PaymentRequests} from "../src/PaymentRequests.sol";

contract DeployBasedmo is Script {
    PaymentRequests public points;
    ERC1967Proxy proxy;
    address owner;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        owner = vm.envAddress("OWNER");

        PaymentRequests implementation = new PaymentRequests();
        uint[] memory rarity = new uint[](4);
        rarity[0] = 100;
        rarity[1] = 200;
        rarity[2] = 300;
        rarity[3] = 500;
        // Deploy the proxy and initialize the contract through the proxy
       
        proxy = new ERC1967Proxy(address(implementation), abi.encodeCall(implementation.initialize,        
            (owner)));
        points = PaymentRequests(address(proxy));       
        vm.stopBroadcast();
    }
}
