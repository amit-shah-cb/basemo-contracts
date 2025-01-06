// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "../src/PaymentRequests.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {PaymentRequestsV2} from "../src/test/PaymentRequestsV2.sol";

contract UpgradePaymentRequestsScript is Script {
    PaymentRequestsV2 public pr;
    address proxyAddress;
    address owner;
    address usdc;
    function run() external {
          
       uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        owner = vm.envAddress("OWNER");
        usdc = vm.envAddress("USDC_ADDRESS");
        proxyAddress = vm.envAddress("PROXY_ADDRESS");


        Upgrades.upgradeProxy(
            proxyAddress,
            "PaymentRequestsV2.sol:PaymentRequestsV2",
             abi.encodeCall(PaymentRequestsV2.initializeV2, ("2.0.0")),
             owner
        );        
        vm.stopBroadcast();    
       
    }
}