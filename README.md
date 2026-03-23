# Stake & Win

A micro‑lottery on Base Sepolia. Users buy 0.01 ETH tickets. When 100 tickets are sold, a winner is drawn automatically. The house takes 10% of the pool; 90% goes to the winner.

## Contract

- `StakeAndWin.sol` — main lottery logic
- Reentrancy‑protected (`nonReentrant`) on `buyTicket`, `buyMultiple`, and `claimPrize`
- Commit‑reveal inspired randomness: per‑round salt updated at each winner selection, combined with blockhash and timestamp
- `buyTicket()` and `buyMultiple(count)` pay 0.01 ETH per ticket
- When `totalTickets >= THRESHOLD` (100), winner is selected automatically
- Winner calls `claimPrize()` to receive 90% of pool; round auto‑resets
- Owner can set fee (`houseCutBps`), pause/unpause, emergency withdraw, and `forceResetRound` after 1000 blocks (rolls over unclaimed prizes)
- View `ticketsRemaining()` and `blocksUntilDraw()` (estimate)
- Events: `TicketPurchased`, `BatchPurchased`, `ThresholdReached`, `WinnerSelected`, `PrizeClaimed`, `RoundReset`, `SaltUpdated`, `Paused`, `Unpaused`

## Frontend

- Static dashboard in `frontend/index.html`
- Connect wallet (MetaMask) and auto‑switch to Base Sepolia
- Shows: tickets sold, tickets to next draw, prize pool (ETH), current winner, house fee percentage
- Single‑ticket and batch‑ticket purchase
- Winner claim card (if you are the winner)
- Auto‑refresh every 30 s
- Paused banner

Deploy to Vercel with root=`frontend`. After deployment, update `CONTRACT_ADDRESS` in the file.

## Frontend

Static dashboard in `frontend/index.html`:
- Connect wallet (MetaMask)
- Network guard (Base Sepolia)
- Buy Ticket button
- Live stats: tickets sold, prize pool, current winner

Deploy to Vercel with root=`frontend`.

## Deploy

```bash
export BASE_SEPOLIA_RPC_URL="https://sepolia.base.org"
export PRIVATE_KEY="0x..."
forge script script/DeployStakeAndWin.s.sol:DeployStakeAndWin \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
```

After deployment, update `CONTRACT_ADDRESS` in `frontend/index.html` and redeploy frontend.

**Deployed on Base Sepolia:**
- Contract: `0x1d14aF931b5C98dc4938DD940898E715330D6fa9`
- Verified on Basescan: https://sepolia.basescan.org/address/0x1d14aF931b5C98dc4938DD940898E715330D6fa9

**Notes:**
- House fee: 10% (configurable by owner)
- Auto-reset rounds after prize claim; `forceResetRound` available after 1000 blocks
- Reentrancy guard, pausable, and admin 24‑hour cooldown in source (cooldown not yet deployed)
- Uses commit‑reveal inspired salt for randomness improvement (still not VRF‑grade)

**Frontend:** Deploy to Vercel with root=`frontend`. After deployment, share URL.

**Frontend:** Deploy to Vercel with root=`frontend`. Then share URL.

**Features:**
- Batch ticket purchase (`buyMultiple`) for lower gas
- Winner claim with safety (reentrancy guard)
- Auto-reset rounds after claim
- `ticketsRemaining()` view
- Owner `forceResetRound` for emergencies
- Auto-refresh dashboard
- Winner claim card appears when you are the winner

## Revenue

- 10% of each pool goes to the contract owner (can withdraw any time).
- With volume, this generates consistent ETH revenue.

## Gas & Costs

- `buyTicket()` costs ~80k gas on Base Sepolia.
- cheap enough for micro‑lottery play.

## Security

- nonReentrant modifier prevents reentrancy
- one‑tx‑per‑block guard to reduce spam
- winner selection uses on‑chain randomness (note: not VRF‑grade, but fine for micro‑games)

## License

MIT
