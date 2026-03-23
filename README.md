# Stake & Win

A micro‑lottery on Base Sepolia. Users buy 0.01 ETH tickets. When 100 tickets are sold, a winner is drawn automatically. The house takes 10% of the pool; 90% goes to the winner.

## Contract

- `StakeAndWin.sol` — main lottery logic
- Reentrancy‑protected on `buyTicket`, `buyMultiple`, and `claimPrize`
- Random winner selection using blockhash + timestamp
- `buyTicket()` and `buyMultiple(count)` pay 0.01 ETH per ticket
- When `totalTickets >= THRESHOLD` (100), winner is selected automatically
- Winner calls `claimPrize()` to receive 90% of pool; round auto‑resets
- Owner can set fee (`houseCutBps`), emergency withdraw, and `forceResetRound` if needed
- View `ticketsRemaining()` shows how many tickets left until next draw

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
- Contract: `0x0Fbb6EC9F1C43D22BBDbB4E7b5913a3fb17fC2C6`
- Basescan: https://sepolia.basescan.org/address/0x0Fbb6EC9F1C43D22BBDbB4E7b5913a3fb17fC2C6

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
