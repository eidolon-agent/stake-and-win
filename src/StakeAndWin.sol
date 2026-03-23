// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

contract StakeAndWin is Ownable {
    uint256 public constant TICKET_PRICE = 0.01 ether;
    uint256 public constant THRESHOLD = 100;
    uint256 public ticketCounter;
    uint256 public totalTickets;
    uint256 public prizePool;
    uint256 public houseCutBps = 1000; // 10%
    uint256 public lastBlock;

    address payable public currentWinner;
    bool public prizeClaimed;

    // ticketId -> buyer
    mapping(uint256 => address payable) public ticketOwner;

    event TicketPurchased(address indexed buyer, uint256 ticketId, uint256 amount);
    event ThresholdReached(uint256 totalTickets, uint256 prizePool);
    event WinnerSelected(uint256 ticketId, address indexed winner, uint256 prize);
    event PrizeClaimed(uint256 ticketId, address indexed winner, uint256 amount);

    constructor() Ownable(msg.sender) {}

    receive() external payable {}

    function buyTicket() external payable nonReentrant {
        require(msg.value == TICKET_PRICE, "Incorrect price");
        require(block.number != lastBlock, "One tx per block");
        lastBlock = block.number;

        ticketCounter++;
        totalTickets++;
        prizePool += msg.value;
        ticketOwner[ticketCounter] = payable(msg.sender);

        emit TicketPurchased(msg.sender, ticketCounter, msg.value);

        if (totalTickets >= THRESHOLD && currentWinner == address(0)) {
            _selectWinner();
        }
    }

    function _selectWinner() private {
        require(currentWinner == address(0), "Winner already selected");
        // PRNG: keccak256(blockhash(block.number-1), block.timestamp, ticketCounter)
        uint256 seed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, ticketCounter)));
        uint256 winningTicketId = (seed % ticketCounter) + 1;
        address payable winner = ticketOwner[winningTicketId];
        require(winner != address(0), "Invalid winner");

        currentWinner = winner;
        uint256 prize = (prizePool * (10000 - houseCutBps)) / 10000;
        prizePool -= prize;
        emit WinnerSelected(winningTicketId, winner, prize);
    }

    function claimPrize() external {
        require(msg.sender == currentWinner, "Not winner");
        require(!prizeClaimed, "Already claimed");
        prizeClaimed = true;
        uint256 amount = prizePool;
        prizePool = 0;
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "Transfer failed");
        emit PrizeClaimed(ticketCounter, msg.sender, amount);
    }

    function setHouseCut(uint256 bps) external onlyOwner {
        require(bps <= 2500, "Max 25%");
        houseCutBps = bps;
    }

    function emergencyWithdraw() external onlyOwner {
        (bool ok, ) = owner().call{value: address(this).balance}("");
        require(ok, "Withdraw failed");
    }

    // NonReentrant modifiers (simple)
    uint256 private _status;
    uint256 constant _NOT_ENTERED = 1;
    uint256 constant _ENTERED = 2;

    modifier nonReentrant() {
        _requireNotEntered();
        _enter();
        _;
        _exit();
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
}
