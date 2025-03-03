// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "socket-protocol/contracts/utils/OwnableTwoStep.sol";
import "socket-protocol/contracts/base/PlugBase.sol";

contract Counter is OwnableTwoStep, PlugBase {
    uint256 public counter;

    constructor() PlugBase(msg.sender) {
        _claimOwner(msg.sender);
    }

    function increase() external onlySocket {
        counter++;
    }

    function connectSocket(address appGateway_, address socket_, address switchboard_) external onlyOwner {
        _claimOwner(socket_);
        _connectSocket(appGateway_, socket_, switchboard_);
    }
}
