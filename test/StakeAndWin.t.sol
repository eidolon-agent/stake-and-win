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

    function testBuyMultiple() public {
        vm.prank(address(this));
        sw.buyMultiple{value: 0.05 ether}(5);
        assertEq(sw.totalTickets(), 5);
        assertEq(sw.prizePool(), 0.05 ether);
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
        vm.deal(alice, 3 ether);

        for (uint256 i = 0; i < 100; i++) {
            vm.prank(alice);
            sw.buyTicket{value: 0.01 ether}();
        }

        assertEq(sw.currentWinner(), alice);

        vm.prank(alice);
        sw.claimPrize();

        assertEq(sw.totalTickets(), 0);
        assertEq(sw.currentWinner(), address(0));
        assertEq(sw.prizeClaimed(), false);
    }

    function testForceResetRoundAfterTimeout() public {
        address alice = vm.addr(0x1000);
        vm.deal(alice, 3 ether);
        for (uint256 i = 0; i < 100; i++) {
            vm.prank(alice);
            sw.buyTicket{value: 0.01 ether}();
        }
        assertTrue(sw.currentWinner() != address(0));
        assertFalse(sw.prizeClaimed());

        // Fast forward 1000 blocks
        vm.warp(block.number + 1000);
        vm.prank(owner());
        sw.forceResetRound();

        assertEq(sw.currentWinner(), address(0));
        assertEq(sw.totalTickets(), 0);
    }

    function testPausable() public {
        vm.prank(owner());
        sw.pause();
        vm.prank(address(this));
        vm.expectRevert("Paused");
        sw.buyTicket{value: 0.01 ether}();
        vm.prank(owner());
        sw.unpause();
        vm.prank(address(this));
        sw.buyTicket{value: 0.01 ether}();
    }

    function testBlocksUntilDraw() public {
        for (uint256 i = 0; i < 50; i++) {
            vm.prank(address(this));
            sw.buyTicket{value: 0.01 ether}();
        }
        assertEq(sw.blocksUntilDraw(), 50);
    }

    function testSaltUpdatedOnWinnerSelect() public {
        for (uint256 i = 0; i < 100; i++) {
            vm.prank(address(this));
            sw.buyTicket{value: 0.01 ether}();
        }
        uint256 salt1 = sw.salt();
        // Reset round and draw again
        vm.prank(owner());
        sw.forceResetRound();
        for (uint256 i = 0; i < 100; i++) {
            vm.prank(address(this));
            sw.buyTicket{value: 0.01 ether}();
        }
        uint256 salt2 = sw.salt();
        assertNe(salt1, salt2);
    }
}
