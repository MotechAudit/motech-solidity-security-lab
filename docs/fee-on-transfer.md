# Fee-on-transfer ERC-20 accounting

Some ERC-20 tokens deliver less than the requested transfer amount. A token may deduct a transfer fee, burn part of the amount, or route part of it elsewhere.

## The accounting mistake

A vault that calls `transferFrom(user, vault, requestedAmount)` and then credits `requestedAmount` assumes the full amount arrived. For a fee-on-transfer token, that assumption is false:

- Alice requests a deposit of 100 tokens.
- The token charges a 10% transfer fee, so the vault receives 90.
- If the vault credits Alice with 100, its liabilities exceed its token balance by 10.
- Repeating the deposit can make the vault insolvent, leaving later depositors unable to withdraw their recorded balances.

The vulnerable example demonstrates two users depositing 100 each: the vault records 200 credits while holding only 180 tokens. The first withdrawal leaves only 80 tokens to back the second user's 100-token credit.

## The mitigation demonstrated here

The fixed example reads the vault's token balance before and after `transferFrom`, then credits the difference:

```solidity
uint256 beforeBalance = token.balanceOf(address(this));
require(token.transferFrom(msg.sender, address(this), requestedAmount));
uint256 received = token.balanceOf(address(this)) - beforeBalance;

credits[msg.sender] += received;
totalCredits += received;
```

This makes the recorded deposit match the amount actually delivered for the fee-on-transfer behavior modeled by the test token.

## Important limitations

This example is educational, not a production-ready vault. Balance-delta accounting is not a universal compatibility guarantee for every unusual token. Rebasing, reflection, callback-capable, malicious, or otherwise non-standard tokens may require token-specific handling or explicit exclusion. The example also does not replace reentrancy protection, access control, withdrawal design, or a full token compatibility review.

The mock token charges a 10% fee on both incoming and outgoing transfers. The fixed vault credits the amount received on deposit; the fee on withdrawal is borne by the recipient, so the recipient receives less than the gross credited amount.
