// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract StakeAndWin is Ownable, Pausable {
    uint256 public constant TICKET_PRICE = 0.01 ether;
    uint256 public constant THRESHOLD = 100;
    uint256 public ticketCounter;
    uint256 public totalTickets;
    uint256 public prizePool;
    uint256 public houseCutBps = 1000; // 10%
    uint256 public roundStartBlock;
    uint256 public lastAdminTimestamp; // cooldown tracking

    address payable public currentWinner;
    bool public prizeClaimed;
    uint256 public pendingPrize;
    uint256 public salt;

    mapping(uint256 => address payable) public ticketOwner;

    event TicketPurchased(address indexed buyer, uint256 ticketId, uint256 amount);
    event ThresholdReached(uint256 totalTickets, uint256 prizePool);
    event WinnerSelected(uint256 ticketId, address indexed winner, uint256 prize);
    event PrizeClaimed(uint256 ticketId, address indexed winner, uint256 amount);
    event RoundReset(uint256 newTotalTickets);
    event BatchPurchased(address indexed buyer, uint256 firstTicketId, uint256 count, uint256 totalPaid);
    event SaltUpdated(uint256 newSalt);
    event AdminActionCooldown(uint256 timestamp);

    constructor() Ownable(msg.sender) {
        _status = _NOT_ENTERED;
        roundStartBlock = block.number;
        lastAdminTimestamp = block.timestamp;
    }

    receive() external payable {}

    // NonReentrant
    uint256 private _status;
    uint256 constant _NOT_ENTERED = 1;
    uint256 constant _ENTERED = 2;

    modifier nonReentrant() {
        _requireNotEntered();
        _enter();
        _;
        _exit();
    }

    modifier whenNotPaused() {
        require(!paused(), "Paused");
        _;
    }

    modifier onlyOwnerWithCooldown() {
        require(msg.sender == owner(), "Not owner");
        require(block.timestamp >= lastAdminTimestamp + 1 days, "Admin cooldown");
        lastAdminTimestamp = block.timestamp;
        emit AdminActionCooldown(block.timestamp);
        _;
    }

    function _requireNotEntered() private view {
        require(_status == _NOT_ENTERED, "Reentrant");
    }

    function _enter() private {
        _status = _ENTERED;
    }

    function _exit() private {
        _status = _NOT_ENTERED;
    }

    function buyTicket() external payable whenNotPaused {
        require(msg.value == TICKET_PRICE, "Incorrect price");
        _recordPurchase(msg.sender, 1);
    }

    function buyMultiple(uint256 count) external payable whenNotPaused {
        require(count > 0 && count <= 100, "Invalid count");
        require(msg.value == TICKET_PRICE * count, "Incorrect total");
        _recordPurchase(msg.sender, count);
    }

    function _recordPurchase(address buyer, uint256 count) internal {
        for (uint256 i = 0; i < count; i++) {
            ticketCounter++;
            totalTickets++;
            ticketOwner[ticketCounter] = payable(buyer);
        }
        prizePool += msg.value;
        emit TicketPurchased(buyer, ticketCounter - count + 1, msg.value);
        if (count > 1) {
            emit BatchPurchased(buyer, ticketCounter - count + 1, count, msg.value);
        }
        if (totalTickets >= THRESHOLD && currentWinner == address(0)) {
            _selectWinner();
        }
    }

    function _selectWinner() private {
        require(currentWinner == address(0), "Winner already selected");
        salt = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), salt, block.timestamp, ticketCounter)));
        uint256 winningTicketId = (salt % ticketCounter) + 1;
        address payable winner = ticketOwner[winningTicketId];
        require(winner != address(0), "Invalid winner");

        currentWinner = winner;
        pendingPrize = (prizePool * (10000 - houseCutBps)) / 10000;
        prizePool -= pendingPrize;
        emit ThresholdReached(totalTickets, prizePool + pendingPrize);
        emit WinnerSelected(winningTicketId, winner, pendingPrize);
        emit SaltUpdated(salt);
    }

    function claimPrize() external nonReentrant whenNotPaused {
        require(msg.sender == currentWinner, "Not winner");
        require(!prizeClaimed, "Already claimed");
        prizeClaimed = true;
        uint256 amount = pendingPrize;
        pendingPrize = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        emit PrizeClaimed(ticketCounter, msg.sender, amount);
        _resetRound();
    }

    function _resetRound() internal {
        totalTickets = 0;
        currentWinner = payable(address(0));
        prizeClaimed = false;
        pendingPrize = 0;
        roundStartBlock = block.number;
        emit RoundReset(totalTickets);
    }

    // Owner utilities with cooldown
    function setHouseCut(uint256 bps) external onlyOwnerWithCooldown {
        require(bps <= 2500, "Max 25%");
        houseCutBps = bps;
    }

    function pause() external onlyOwnerWithCooldown {
        _pause();
    }

    function unpause() external onlyOwnerWithCooldown {
        _unpause();
    }

    function emergencyWithdraw() external nonReentrant onlyOwnerWithCooldown {
        (bool ok, ) = owner().call{value: address(this).balance}("");
        require(ok, "Withdraw failed");
    }

    // Force reset if prize unclaimed for many blocks (owner call, no cooldown)
    function forceResetRound() external onlyOwner {
        require(prizeClaimed || block.number >= roundStartBlock + 1000, "Too soon");
        if (!prizeClaimed && pendingPrize > 0) {
            prizePool += pendingPrize;
            pendingPrize = 0;
        }
        _resetRound();
    }

    // Views
    function ticketsRemaining() external view returns (uint256) {
        if (totalTickets >= THRESHOLD) return 0;
        return THRESHOLD - totalTickets;
    }

    function blocksUntilDraw() external view returns (uint256) {
        if (totalTickets >= THRESHOLD) return 0;
        return THRESHOLD - totalTickets;
    }
}
