## What problems ERC777 and ERC1363 solves
### ERC777
It defines advanced features to interact with tokens. Namely, operators to send tokens on behalf of another address — contract or regular account (attempt to replace "approve & pull" flow). And send/receive `hooks` to offer token holders more control over their tokens. This standard allows the implementation of ERC-20 functions `transfer`, `transferFrom`, `approve` and `allowance` alongside to make a token fully compatible with ERC-20.

### ERC1363

Defines a token interface for ERC-20 tokens that supports executing recipient code after `transfer` or `transferFrom`, or spender code after `approve`.

## Why was ERC1363 introduced?

There is no way to execute code after a ERC-20 transfer or approval (i.e. making a payment), so to make an action it is required to send another transaction and pay GAS twice.

This ERC wants to make token payments easier and working without the use of any other listener. It allows to make a callback after a transfer or approval in a single transaction. It can be used for specific utilities or for any other purposes who require the execution of a callback after a transfer or approval received.

## What issues are there with ERC777?

- Complexity: ERC777 is a complex standard and over-engineered for most use-cases which makes it hard to understand and use (according to the community)
- Reentrancy: The standard is vulnerable to reentrancy attacks because of hooks.
- Spam-tokens: The standard doesn't prevent spam-tokens from being sent to a contract as as it was intended because of sophisticated spam-token sending logic.