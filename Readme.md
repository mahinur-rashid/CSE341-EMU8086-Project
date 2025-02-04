# 8086 Assembly Banking System

A simple banking system implemented in 8086 assembly language, featuring user authentication, basic banking operations, and a foreign exchange calculator.

## Features

- **User Authentication**
  - Signup with username and password (max 5 users).
  - Login with credentials.
  
- **Banking Menu**
  - Display balance.
  - Cash deposit.
  - Cash withdrawal.
  - Print transaction receipt.
  - Foreign exchange calculator (USD ↔ BDT).
  - Logout functionality.

- **Foreign Exchange Calculator**
  - Convert USD to Bangladeshi Taka (BDT) at a fixed rate (1 USD = 110 BDT).
  - Convert BDT to USD (supports decimal results).
  - Error handling for large inputs/overflows.

- **Transaction History**
  - Stores up to 5 transactions.
  - Displays deposit/withdrawal history in receipts.

## How to Run

1. **Prerequisites**:
   - An 8086 emulator (e.g., [DOSBox](https://www.dosbox.com/) + [TASM](https://github.com/hsaliak/dosbox-tasm) or [EMU8086](https://emu8086.com/)).

2. **Steps**:
   ```bash
   https://github.com/mahinur-rashid/CSE341-EMU8086-Project.git
   # Assemble and run in your emulator (e.g., EMU8086)
