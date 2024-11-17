# Executor

Smart contract for executing transactions and managing assets through a proxy pattern.

## Overview

The Executor smart contract allows an owner to:
- Execute single transactions with ETH support
- Bundle multiple transactions in a single call
- Manage ETH and ERC20 token balances
- Control access through ownership

## Installation

```bash
forge install
```

## Usage

### Building

```bash
forge build
```

### Testing

```bash
forge test
```

For verbose output:
```bash
forge test -vvv
```

### Deployment

Deploy with your preferred network:

```bash
forge script script/Deploy.s.sol --rpc-url <your_rpc_url> --private-key <your_private_key>
```
