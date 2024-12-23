// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract PaymentRequests is Initializable {
    function initialize() public initializer {
        __EIP712_init("PaymentRequests", "1");
    }
}
