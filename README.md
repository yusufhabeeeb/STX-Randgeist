
# STX-Randgeist - Secure Random Number Generator for Clarity

A composable and verifiable **Random Number Generator (RNG)** smart contract built with Clarity for the Stacks blockchain. It ensures unpredictable, tamper-resistant randomness using multiple on-chain entropy sources.

---

## 📦 Features

- ✅ **Secure entropy combination** using:
  - Current & previous Stacks block hashes
  - Burn block header hash
  - Transaction sender address
  - Nonce & entropy accumulator

- 🔄 **Stateless randomness** for external inputs (`user-seed`)
- 🛡️ **Mitigates same-block attacks**
- 📈 **Entropy accumulation** over time for enhanced unpredictability
- 🔍 **Verifiable random outputs**

---

## ⚙️ Functions

### 🎲 `get-random (user-seed (buff 32)) (max-value uint)`

Returns a random `uint` from `0` to `max-value` (inclusive).

```clarity
(get-random 0x1234567890abcdef... u100)
;; → (ok u42)
````

---

### 🎯 `get-random-in-range (user-seed (buff 32)) (min-value uint) (max-value uint)`

Returns a random number within a specific range (inclusive).

```clarity
(get-random-in-range 0x1234567890abcdef... u10 u20)
;; → (ok u13)
```

---

### 🔍 `get-entropy-state`

Returns the current entropy accumulator for audit/verification.

```clarity
(get-entropy-state)
;; → 0xdeadbeef...
```

---

## 🔒 Security Considerations

* Enforces **one call per block** to prevent block-time manipulation.
* Requires external `user-seed` input to minimize determinism.
* Internal state updated with every call to prevent reuse of entropy.
* Output randomness **cannot be predicted** without access to internal state and future block info.

---

## 🧪 Example Use Cases

* Lottery draws in decentralized games
* Random NFT attribute generation
* DAO voting with probabilistic triggers
* On-chain puzzles and treasure hunts

---

## 📥 Deployment

Add the contract to your Stacks project and deploy using the Clarity CLI or a tool like Clarinet:

```bash
clarinet contract publish random-generator
```

---

## 📄 License

MIT License. Use freely with attribution. Designed for public utility on the Stacks blockchain.

---
