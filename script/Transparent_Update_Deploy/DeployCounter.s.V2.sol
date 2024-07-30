// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployCounterV2 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = 0x51DE36eeA69e0bB922110532B806a27Af3580fff;
        vm.startBroadcast(deployerPrivateKey);

        Options memory opts;

        opts.unsafeSkipAllChecks = true;
        opts.referenceContract = "CounterUpgradeable.sol";

        Upgrades.upgradeProxy(proxyAddress, "CounterUpgradeableV2.sol", "", opts);

        vm.stopBroadcast();
    }
}
