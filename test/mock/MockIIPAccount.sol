// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IIPAccount} from "protocol-core-v1/contracts/interfaces/IIPAccount.sol";

contract MockIIPAccount is IIPAccount {
    address public override owner;
    bytes32 private _state;

    constructor() {
        owner = msg.sender;
        _state = bytes32(0);
    }

    receive() external payable {}

    function execute(
        address to,
        uint256,
        bytes calldata data
    ) external payable override returns (bytes memory) {
        (bool success, bytes memory result) = to.call{value: msg.value}(data);
        require(success, "MockIIPAccount: execution failed");
        return result;
    }

    function executeWithSig(
        address to,
        uint256,
        bytes calldata data,
        address,
        uint256,
        bytes calldata
    ) external payable override returns (bytes memory) {
        // Mock: just call execute
        (bool success, bytes memory result) = to.call{value: msg.value}(data);
        require(success, "MockIIPAccount: execution failed");
        return result;
    }

    function isValidSigner(address, bytes calldata) external pure override returns (bytes4) {
        return 0x00000000;
    }

    function state() external view override returns (bytes32) {
        return _state;
    }

    function token() external pure override returns (uint256, address, uint256) {
        return (0, address(0), 0);
    }

    function updateStateForValidSigner(address, address, bytes calldata) external override {
        // Mock: just increment state
        _state = bytes32(uint256(_state) + 1);
    }
}