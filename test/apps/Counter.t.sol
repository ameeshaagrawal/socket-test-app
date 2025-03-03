// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {CounterAppGateway} from "socket-protocol/contracts/apps/counter/CounterAppGateway.sol";
import {CounterDeployer} from "socket-protocol/contracts/apps/counter/CounterDeployer.sol";
import {Counter} from "socket-protocol/contracts/apps/counter/Counter.sol";
import "socket-protocol/test/DeliveryHelper.t.sol";

contract CounterTest is DeliveryHelperTest {
    uint256 feesAmount = 0.01 ether;

    bytes32 counterId;
    bytes32[] contractIds = new bytes32[](1);

    CounterAppGateway counterGateway;
    CounterDeployer counterDeployer;

    function deploySetup() internal {
        setUpDeliveryHelper();

        counterDeployer =
            new CounterDeployer(address(addressResolver), address(auctionManager), FAST, createFeesData(feesAmount));

        counterGateway = new CounterAppGateway(
            address(addressResolver), address(counterDeployer), address(auctionManager), createFeesData(feesAmount)
        );
        setLimit(address(counterGateway));

        counterId = counterDeployer.counter();
        contractIds[0] = counterId;
    }

    function deployCounterApp(uint32 chainSlug) internal returns (bytes32 asyncId) {
        asyncId = _deploy(contractIds, chainSlug, 1, IAppDeployer(counterDeployer), address(counterGateway));
    }

    function testCounterDeployment() external {
        deploySetup();
        deployCounterApp(arbChainSlug);

        (address onChain, address forwarder) = getOnChainAndForwarderAddresses(arbChainSlug, counterId, counterDeployer);

        assertEq(IForwarder(forwarder).getChainSlug(), arbChainSlug, "Forwarder chainSlug should be correct");
        assertEq(IForwarder(forwarder).getOnChainAddress(), onChain, "Forwarder onChainAddress should be correct");
    }

    function testCounterIncrement() external {
        deploySetup();
        deployCounterApp(arbChainSlug);

        (address arbCounter, address arbCounterForwarder) =
            getOnChainAndForwarderAddresses(arbChainSlug, counterId, counterDeployer);

        uint256 arbCounterBefore = Counter(arbCounter).counter();

        address[] memory instances = new address[](1);
        instances[0] = arbCounterForwarder;
        counterGateway.incrementCounters(instances);

        _executeWriteBatchSingleChain(arbChainSlug, 1);
        assertEq(Counter(arbCounter).counter(), arbCounterBefore + 1);
    }

    function testCounterIncrementMultipleChains() external {
        deploySetup();
        deployCounterApp(arbChainSlug);
        deployCounterApp(optChainSlug);

        (address arbCounter, address arbCounterForwarder) =
            getOnChainAndForwarderAddresses(arbChainSlug, counterId, counterDeployer);
        (address optCounter, address optCounterForwarder) =
            getOnChainAndForwarderAddresses(optChainSlug, counterId, counterDeployer);

        uint256 arbCounterBefore = Counter(arbCounter).counter();
        uint256 optCounterBefore = Counter(optCounter).counter();

        address[] memory instances = new address[](2);
        instances[0] = arbCounterForwarder;
        instances[1] = optCounterForwarder;
        counterGateway.incrementCounters(instances);

        uint32[] memory chains = new uint32[](2);
        chains[0] = arbChainSlug;
        chains[1] = optChainSlug;
        _executeWriteBatchMultiChain(chains);
        assertEq(Counter(arbCounter).counter(), arbCounterBefore + 1);
        assertEq(Counter(optCounter).counter(), optCounterBefore + 1);
    }
}
