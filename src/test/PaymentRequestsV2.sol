// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "../PaymentRequests.sol";

/// @custom:oz-upgrades-from PaymentRequests
contract PaymentRequestsV2 is PaymentRequests {
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initializeV2(string calldata version) public reinitializer(4) {
        /* NOTE: 
        When used with inheritance, manual care must be taken to not invoke a parent initializer twice, 
        or to ensure that all initializers are idempotent. This is not verified automatically as 
        constructors are by Solidity. */
        super._getPaymentStorage().version = version;
    }

    function getVersion() public view returns (string memory) {
        return super._getPaymentStorage().version;
    }
}
