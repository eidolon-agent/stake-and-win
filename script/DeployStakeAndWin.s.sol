// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { StakeAndWin } from "../src/StakeAndWin.sol";

contract DeployStakeAndWin {
    StakeAndWin public stakeAndWin;

    function run() external returns (StakeAndWin) {
        stakeAndWin = new StakeAndWin();
        return stakeAndWin;
    }
}
