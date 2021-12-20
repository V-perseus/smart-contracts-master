// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./multisig.sol";

contract SigFactory {

    function createMultiSig(address[] memory _owners, uint _confirms) public returns(MultiSig) {
        MultiSig multisig = new MultiSig(_owners, _confirms);
        return multisig;
    }
}