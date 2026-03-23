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
        for (uint256 i = 0; i < 100; i++) {
            vm.prank(address(this));
            sw.buyTicket{value: 0.01 ether}();
        }
        assertTrue(sw.currentWinner() != address(0));
    }

    function testClaimPrizeResetsRound() public {
        address alice = vm.addr(0x1000);
        vm.deal(alice, 3 ether); // fund alice with enough ETH for tickets and gas

        for (uint256 i = 0; i < 100; i++) {
            vm.prank(alice);
            sw.buyTicket{value: 0.01 ether}();
        }

        assertEq(sw.currentWinner(), alice);

        // Winner claims
        vm.prank(alice);
        sw.claimPrize();

        // After claim, round should reset
        assertEq(sw.totalTickets(), 0);
        assertEq(sw.currentWinner(), address(0));
        assertEq(sw.prizeClaimed(), false);
    }
}
