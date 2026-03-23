# ETHSKILLS Audit — Stake & Win

**Date:** 2026-03-23
**Contract:** `0x1d14aF931b5C98dc4938DD940898E715330D6fa9` (Base Sepolia)

## Principles Check

### 1. Nothing is automatic
- ✅ All state changes require explicit user transactions.
- ✅ No oracles; randomness from block data (acknowledged weakness).
- ✅ Pausable for emergency stop.

### 2. Gas is the enemy
- ✅ Minimal state writes; loops bounded by `count <= 100`.
- ✅ `buyMultiple` reduces gas per ticket.
- ⚠️ Could pack `totalTickets` and `ticketCounter` into one slot, but not critical.

### 3. No loop over state
- ✅ No unbounded loops over storage.
- ✅ `forceResetRound` does not iterate.

### 4. Security first
- ✅ Reentrancy guard (`nonReentrant`) on buy/claim.
- ✅ Checks-Effects-Interactions pattern partially (claim sets state before transfer).
- ✅ `call{value:}` used for payouts (avoid Transfer stipend limit).
- ✅ Pausable.
- ⚠️ Randomness is miner‑influenced; not suitable for high‑value pools. Mitigate with commit‑reveal (salt already used) but still vulnerable. Document.
- ⚠️ `forceResetRound` can be called by owner after 1000 blocks; could grief if prize large. Consider timelock or multisig.

### 5. UX matters
- ✅ Frontend: network check, loading states, auto-refresh.
- ✅ Winner claim card.
- ⚠️ No loading spinner on tx send; could improve.
- ⚠️ No error parsing for revert reasons (just alerts). Good enough for MVP.

### 6. Revenue model
- ✅ Clear 10% house cut, configurable.
- ✅ Unclaimed prize rollover after force reset.
- ✅ Owner emergency withdraw (pausable).

## Recommendations

- Add timelock to `setHouseCut`, `pause`, `forceResetRound` (delay 24h).
- Verify contract on Basescan (submitted).
- Add The Graph subgraph for historical queries (rounds, winners).
- Add commit‑reveal where users commit a hash, then reveal later; this removes miner influence. Could be a phase 2.
- Add a small “donate” fallback to encourage voluntary tips.
- Add frontend countdown in minutes/hours, not just blocks.
- Add transaction simulation before sending to estimate gas and fail early.

## Conclusion

Stake & Win follows core ethskills patterns: minimal state, bounded loops, reentrancy protection, pausable, and revenue‑positive. The main trade‑off is randomness quality; acceptable for micro‑lottery on Base Sepolia with small pools.
