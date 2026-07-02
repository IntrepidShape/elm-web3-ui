# Contributing to elm-web3-ui

Type-safe dapp UI primitives for
[elm-web3](https://github.com/IntrepidShape/elm-web3). The package's map is
[`PRIMITIVES.md`](PRIMITIVES.md) — an exhaustive, graded taxonomy of every
primitive a web3 UI package needs. Read it before proposing anything: the
ranked roadmap there is the wanted list, and the "skip" verdicts carry
reasoning a PR must rebut to overturn.

## Development setup

```bash
elm make --docs=/tmp/docs.json    # docs must build (publish gate)
npx --yes elm-test                # elm-test is a Node CLI
```

CI runs both on every PR.

## Design contract (what makes a PR mergeable)

1. **CSS classes, zero inline styles.** Every element gets a stable
   `web3-*` class; theming is pure CSS on the consumer side. A component
   that ships inline styles will be declined.
2. **Options records, `Maybe` for optionals.** Follow the house shape:
   `view : List (Html.Attribute msg) -> { opts } -> data -> Html msg`.
   Optional URLs/features are `Maybe` — render a graceful fallback on
   `Nothing` (see `Transaction.hashDisplay` for the convention).
3. **Bind to elm-web3's state machines, don't reinvent them.** Components
   render `Wallet.State` / `Tx.Status` / `SignState`; they never track
   parallel state of their own.
4. **Layer discipline.** Layer 0–1 atoms stay pure and dumb; Layer 2 binds
   state machines; Layer 3 generics carry the type-level machinery
   (see `PRIMITIVES.md`). Domain compounds (Layer 4) need a real consuming
   project, not speculation.
5. **Tests + docs.** Every exposed function gets doc comments (the docs
   build is a hard gate) and view tests for its state variants.
6. **Update `PRIMITIVES.md` and `CHANGELOG.md`** in the same PR — the
   taxonomy's grades must stay true, exactly like elm-web3's coverage doc.

## Good first contributions (from the ranked roadmap)

1. `RemoteCall` generic — RemoteData specialised to correlation-id port
   round-trips; the package's missing foundation
2. `ApprovalFlow` — allowance → approve → act, web3's most repeated flow
3. Revert-reason display — elm-web3 decodes it, users never see it
4. `AccountPill` — address + balance + chain + disconnect, one compound
5. Chain selector bound to switch/add flows

## Commit style

Imperative subject with an area prefix (`feat:`, `fix:`, `docs:`,
`release:`), body explains *why*. No AI attribution footers.
