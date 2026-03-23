// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/StakeAndWin.sol";

contract StakeAndWinTest is Test {
    StakeAndWin sw;

    function setUp() public {
        sw = new StakeAndWin();
    }

    function testBuyTicket() public {
        vm.prank(address(this));
        sw.buyTicket{value: 0.01 ether}();
        assertEq(sw.totalTickets(), 1);
        assertEq(sw.prizePool(), 0.01 ether);
    }

    function testThresholdTriggersWinner() public {
        // Buy THRESHOLD tickets
        for (uint256 i = 0; i < 100; i++) {
            vm.prank(address(this));
            sw.buyTicket{value: 0.01 ether}();
        }
        assertNe(sw.currentWinner(), address(0));
    }
}
