# foundry-invariant-starter

A minimal, complete, heavily commented example of **invariant testing in Foundry**. Copy it, read the
comments, and start writing invariants for your own contracts in an hour instead of a week.

Invariant testing is the most powerful thing in Foundry and has the worst on-ramp. The official docs
show fragments; a real setup needs a handler, bounded actors, ghost variables, and the right config,
and none of that is obvious from the fragments. Most people give up before their first invariant runs.
This repository is one tiny contract with a full, working setup that explains every moving part.

## What invariant testing actually is

A unit test checks one path you thought of. An **invariant** is a property that must hold after *any*
sequence of actions. Foundry calls random sequences of your functions, thousands of them, and after
each sequence checks that your invariants still hold. It finds the broken states you never thought to
write a test for, which is exactly where real exploits live.

## The example

`src/Bank.sol` is a trivial ETH bank: users deposit and withdraw their own ETH. Two things must always
be true, no matter the order or who acts:

1. **Solvency** — the bank physically holds exactly the ETH it accounts for.
2. **Accounting** — its running total equals every deposit minus every withdrawal.

The suite proves both across thousands of random deposit and withdrawal sequences.

## The four pieces people get stuck on

- **The handler** (`test/invariant/Handler.sol`). If you point the fuzzer at your contract directly, it
  throws random garbage at your functions and almost everything reverts, so it explores nothing. The
  handler is a thin wrapper exposing only safe, bounded actions. This is the piece that makes invariant
  testing work, and the piece the docs barely mention.
- **`bound(x, lo, hi)`**. Squeeze each fuzzed argument into a sane range so every call is valid instead
  of reverting noise. See both handler functions.
- **Ghost variables** (`ghost_sumDeposits`). An independent tally of what the state *should* be,
  computed in the test, separately from the contract. The invariants check the contract against this,
  so drift gets caught.
- **`targetContract(...)`** and **`fail_on_revert = true`**. Point the fuzzer at the handler, and treat
  a reverting call as a bug in your handler, not a silent pass. Both are set here.

## Run it

```
forge install foundry-rs/forge-std
forge test
```

You should see both invariants pass over 256 runs.

## Now watch it catch a bug

Break the accounting in `src/Bank.sol`. In `withdraw`, comment out this line:

```solidity
totalDeposited -= amount;
```

Run `forge test` again. The `invariant_bankIsSolvent` check fails, and Foundry hands you the shortest
sequence of calls that breaks it, shrunk down for you. That is the whole point: it finds the bad state
and shows you how to reach it. Put the line back and it passes again.

## Layout

    src/Bank.sol                          the contract under test
    test/invariant/Handler.sol            the bounded actions the fuzzer drives
    test/invariant/Bank.invariant.t.sol   the invariants themselves
    foundry.toml                          the invariant config most people forget to set

## Where to go next

Swap `Bank` for your own contract. Keep the shape: a handler of bounded actions, ghost variables for an
independent tally, and one invariant per property that must always hold. The hard part was never the
invariants. It was the scaffolding, and now you have it.

## License

MIT.
