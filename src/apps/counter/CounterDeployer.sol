// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./Counter.sol";
import "socket-protocol/contracts/base/AppDeployerBase.sol";
import "socket-protocol/contracts/utils/OwnableTwoStep.sol";

contract CounterDeployer is AppDeployerBase, OwnableTwoStep {
    bytes32 public counter = _createContractId("counter");

    constructor(address addressResolver_, address auctionManager_, bytes32 sbType_, FeesData memory feesData_)
        AppDeployerBase(addressResolver_, auctionManager_, sbType_)
    {
        creationCodeWithArgs[counter] = abi.encodePacked(type(Counter).creationCode);
        _setFeesData(feesData_);
        _claimOwner(msg.sender);
    }

    function deployContracts(uint32 chainSlug_) external async {
        _deploy(counter, chainSlug_);
    }

    function initialize(uint32) public pure override {
        return;
    }

    function setFees(FeesData memory feesData_) public {
        feesData = feesData_;
    }
}
