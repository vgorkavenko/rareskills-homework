## Why does the SafeERC20 program exist and when should it be used?
We can't be sure that some ERC20 tokens could not return boolean value from transfers.
SafeERC20 introduces wrappers around ERC20 operations that throw on failure (when the token contract returns false). Tokens that return no value (and instead revert or throw on failure) are also supported, non-reverting calls are assumed to be successful.
It also provides a safe way to increase or decrease the allowance of a spender, that helps to avoid the double-spend attack.