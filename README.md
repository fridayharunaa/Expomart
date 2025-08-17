# 🌍 Expomart - Export Bidding Market

> **Global buyers bid on export orders in a decentralized marketplace** 🚀

## 📋 Overview

Expomart is a Clarity smart contract that creates a decentralized marketplace where exporters can list their products and global buyers can place competitive bids. Built on the Stacks blockchain, it enables transparent, secure, and efficient international trade.

## ✨ Features

- 📦 **Create Export Orders**: Exporters can list products with descriptions, quantities, and minimum prices
- 💰 **Competitive Bidding**: Global buyers can place bids on export orders
- ⏰ **Time-bound Auctions**: Orders have deadlines for bidding
- 🏆 **Bid Acceptance**: Exporters can accept the best bids
- 💳 **Secure Payments**: Built-in escrow system with platform fees
- 📊 **Order Management**: Cancel orders, track bids, and view order status

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity smart contracts

### Installation

1. Clone or create a new Clarinet project:
```bash
clarinet new expomart-project
```

2. Replace the contract file with the Expomart contract
3. Test the contract:
```bash
clarinet test
```

## 📖 Usage Guide

### For Exporters 🏭

#### 1. Create an Export Order
```clarity
(contract-call? .Expomart create-export-order 
  "Premium Coffee Beans" 
  "High-quality Arabica coffee beans from Colombia" 
  u1000 
  u50000 
  u144)
```

#### 2. Accept a Bid
```clarity
(contract-call? .Expomart accept-bid u1 u1)
```

#### 3. Cancel an Order
```clarity
(contract-call? .Expomart cancel-order u1)
```

### For Buyers 🛒

#### 1. Deposit Funds
```clarity
(contract-call? .Expomart deposit-funds u100000)
```

#### 2. Place a Bid
```clarity
(contract-call? .Expomart place-bid 
  u1 
  u60000 
  "Interested in long-term partnership")
```

#### 3. Withdraw Funds
```clarity
(contract-call? .Expomart withdraw-funds u50000)
```

### Read-Only Functions 📊

#### Get Order Details
```clarity
(contract-call? .Expomart get-export-order u1)
```

#### Check User Balance
```clarity
(contract-call? .Expomart get-user-balance 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

#### Get Highest Bid
```clarity
(contract-call? .Expomart get-highest-bid u1)
```

## 💡 Key Concepts

### Order Status
- **active**: Order is open for bidding
- **completed**: Order has been fulfilled
- **cancelled**: Order was cancelled by exporter

### Bid Status
- **active**: Bid is valid and active
- **accepted**: Bid was accepted by exporter

### Platform Fee
- 2% fee charged on successful transactions
- Automatically deducted and sent to platform treasury

## 🔧 Contract Functions

| Function | Type | Description |
|----------|------|-------------|
| `create-export-order` | Public | Create a new export order |
| `place-bid` | Public | Place a bid on an order |
| `accept-bid` | Public | Accept a specific bid |
| `cancel-order` | Public | Cancel an active order |
| `deposit-funds` | Public | Deposit STX for bidding |
| `withdraw-funds` | Public | Withdraw available STX |
| `get-export-order` | Read-only | Get order details |
| `get-bid` | Read-only | Get bid information |
| `get-user-balance` | Read-only | Check user balance |
| `get-highest-bid` | Read-only | Get current highest bid |

## 🛡️ Security Features

- ✅ Authorization checks for order management
- ✅ Deadline validation for bids
- ✅ Balance verification before bidding
- ✅ Self-bidding prevention
- ✅ Minimum price enforcement

## 🧪 Testing

Run the test suite:
```bash
clarinet test
```

Check contract syntax:
```bash
clarinet check
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is open source and available under the MIT License.

## 🌟 Support

If you find this project helpful, please give it a star! ⭐


