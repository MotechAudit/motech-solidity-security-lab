# ERC-20 compatibility: return values and approvals

ERC-20 integrations cannot assume every deployed token behaves identically at the ABI boundary.

## Optional return data

Some older or non-standard tokens complete `transfer` and `transferFrom` without returning a boolean value. A contract that calls those methods through a typed interface expecting a boolean can fail while decoding the empty return data.

Other tokens return `false` to signal failure. A caller must not treat a non-reverting call as proof that the transfer succeeded.

The compatibility vault uses OpenZeppelin's `SafeERC20` library:

- A successful call with no return data is accepted when the token call itself succeeds.
- An explicit `false` return is rejected.
- Reverting token calls are bubbled or wrapped by the library.

The example also measures the vault's token balance before and after `safeTransferFrom`, so deposit credits reflect the amount actually received for the transfer behavior modeled in the lab.

## Zero-first approvals

Some tokens require an existing non-zero allowance to be reset to zero before it can be changed to another non-zero value. OpenZeppelin's `forceApprove` handles this compatibility pattern by attempting the requested approval and falling back to a zero approval followed by the requested value when needed.

This is a token-compatibility behavior, not a general solution to every allowance race or approval UX risk. Applications should still consider the token's approval semantics, spender trust, and transaction ordering.

## Tests in this lab

- A no-return token can be deposited into and withdrawn from through the SafeERC20-based example.
- A token that explicitly returns `false` is rejected and does not create user credit.
- A zero-first approval token can have its allowance safely updated through `forceApprove`.
- An unauthorized caller cannot alter the managed spender allowance.

## Limitations

These examples are educational. SafeERC20 handles common return-value irregularities, but it does not make arbitrary malicious, rebasing, reflection, callback-capable, fee-on-transfer, or otherwise non-standard token behavior safe by itself. Review token behavior and the protocol's accounting and external-call assumptions separately.
