# Multi-Party Escrow Smart Contract

## 📌 Overview

The **MultiPartyEscrow** contract is a Solidity-based implementation of a **2-of-3 multi-signature escrow system**.  
It enables safe transactions between a **buyer** and a **seller**, with the help of a **mediator** in case of disputes.
 
Funds are locked in the contract until **any 2 of the 3 parties** agree on the outcome:

- If **buyer + seller** approve → funds are released to the seller. 
- If **buyer + mediator** approve → funds are released to the seller.
- If **seller + mediator** approve → funds are released to the seller. 
- If the deadline passes without agreement → the buyer can refund. 
 
---

## ❓ Why Use This Contract?

### 🔒 Trustless Transactions

- In traditional transactions, either the buyer or the seller must trust the other.
- With escrow, funds are held securely until terms are met.

### 🧑‍⚖️ Built-In Dispute Resolution

- If buyer and seller disagree, the mediator can step in to provide a fair resolution.
- This avoids the need for centralized arbitration services.

### ⏰ Automatic Refunds

- Deadlines prevent funds from being stuck indefinitely.
- If no consensus is reached, the buyer can reclaim their funds.

### 🛡️ Security

- Uses OpenZeppelin’s **ReentrancyGuard** to protect against reentrancy attacks.
- Ensures funds are only released once and cannot be drained.

---

## ⚙️ How It Works

1. **Deployment**

   - Contract is deployed with:
     - `buyer`
     - `seller`
     - `mediator`
     - `deadline` (a future UNIX timestamp)

2. **Deposit**

   - Buyer calls `deposit()` and sends funds to the contract.
   - Contract moves from `AWAITING_DEPOSIT` → `AWAITING_APPROVALS`.

3. **Approval Phase**

   - Any of the 3 parties can call `approveRelease()`.
   - Once 2 parties approve, funds are automatically released to the seller.

4. **Refund**
   - If the deadline passes and no consensus is reached,  
     the buyer can call `refundIfDeadlinePassed()` to get funds back.

---

## 📜 Contract States

The contract has 4 states:

- `AWAITING_DEPOSIT` → before buyer deposits
- `AWAITING_APPROVALS` → funds are locked, waiting for approvals
- `RELEASED` → funds sent to seller
- `REFUNDED` → funds returned to buyer

---

## 📄 License

MIT License
