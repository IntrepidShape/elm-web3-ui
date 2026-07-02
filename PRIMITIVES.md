# The complete web3 UI primitive set

An exhaustive taxonomy of every primitive and generic a web3 UI package needs,
graded against what `intrepidshape/elm-web3-ui` ships today. This is the
package's map and roadmap — the UI-layer companion to elm-web3's
`proofs/EVM_API_COVERAGE.md`. Audited 2026-07-02 against the 36 exposed
modules.

Grading: ✅ shipped · 🟡 partial (exists but missing listed capability) ·
❌ missing (verdict: **build** = roadmap, **skip** = deliberately out of scope).

The taxonomy has five layers plus cross-cutting concerns. A primitive belongs
in this package iff it is (a) web3-specific (an `Address` renderer, not a
button), or (b) a generic whose type parameters do web3 work (a `RemoteCall`
wrapper for port round-trips, not a spinner).

---

## Layer 0 — Display atoms (pure, stateless)

| Primitive | What | Status |
|---|---|---|
| Address display | truncated, full, explorer-linked (`Maybe` url), copyable | ✅ `Address.view/short/shortWith` — 🟡 no copy-to-clipboard affordance (**build**: `Address.copyable`) |
| Tx-hash display | truncated, explorer-linked, plain fallback | ✅ `Transaction.txHashLink/hashDisplay` |
| Token amount | BigInt+decimals → human string; SI notation; rounding | ✅ `Amount.formatWei/siFormat/round2` — 🟡 no dust convention (`<0.0001`) or locale grouping (**build**) |
| Fiat equivalent | amount × price feed → `$1,234.56` | ✅ `PriceDisplay` |
| Balance | live balance for an address, with loading/absent states | ✅ `Balance.view/viewEther/viewMaybe` |
| Chain badge | chain name/logo pill from chainId | ✅ `Wallet.chainBadge/lookupChainName` |
| Gas display | estimate in native units + fiat | ✅ `GasEstimate.view` — 🟡 no gwei price ticker (**build**: pairs with elm-web3's `Fee`) |
| Relative time | "3 min ago" from block timestamps | ✅ `RelativeTime` |
| Stat cell | labelled KPI ("TVL", "24h volume") | ✅ `StatCell` |
| Trend indicator | up/down/flat with delta | ✅ `TrendIndicator` |
| Progress ring / bar | vesting, caps, graduation | ✅ `ProgressRing`, `SupplyBar` |
| Percentage / bps | basis-point rendering, fee slices | ✅ `FeeBreakdown`, `FeeFlowDiagram` |
| Identicon / blockie | deterministic avatar from address | ❌ **build** — pure-Elm blockies is a contained fun problem; big UX win for address recognition |
| Token logo/symbol | logo url + symbol fallback | ❌ **build** (list-driven; `TokenSearch` already has the data shape) |
| QR code | address receive flow | ❌ **skip** — belongs to a general QR package, not web3-ui |
| Skeleton / shimmer | loading placeholder shaped like the atoms above | ❌ **build** — every read-heavy dapp needs it; ship as variants (`Address.skeleton`, `Amount.skeleton`, …) |
| Empty state | "no positions yet" | ❌ **skip** — not web3-specific |
| Revert reason display | decoded `Error(string)` → human banner | ❌ **build** — elm-web3 already decodes it; the UI never renders it. Highest-value missing atom |

## Layer 1 — Input atoms (validated, typed)

| Primitive | What | Status |
|---|---|---|
| Amount input | decimals-aware, BigInt-backed, paste-sanitizing | ✅ `Amount.amountInput`, `Input.bigInt` — 🟡 no Max button / balance-% presets (25/50/75/MAX) (**build**) |
| Address input | validation + visual confirm | ✅ `Address.input`, `Input.address` |
| Typed ABI inputs | every solidity type incl. arrays/tuples | ✅ `AbiInput` (uint*/int*/bool/string/bytes/bytesN/T[]/T[N]) |
| Slippage control | presets + custom bps | ✅ `SlippageInput` |
| Lock period | slider snapped to contract-valid periods | ✅ `LockPeriod` |
| Token selector | search + pick from a list | ✅ `TokenSearch` |
| Tab switcher | buy/sell, stake/unstake | ✅ `TradeTabs` |
| Deadline control | tx deadline minutes | ❌ **build** (small; sibling of `SlippageInput`) |
| Chain selector | pick from configured chains, triggers switch flow | ❌ **build** — `chainBadge` exists but there's no picker bound to `Wallet.switchChain`/`addChain` |
| Token-amount pair | token selector + amount input + balance + max, as one unit | ❌ **build** — the swap/deposit workhorse; compose from existing atoms |

## Layer 2 — State-machine-bound components (the elm-web3 glue)

| Primitive | What | Status |
|---|---|---|
| Connect button | full `Wallet.State` render, per-state labels | ✅ `Wallet.connectButton/viewState` |
| Wallet picker | EIP-6963 provider list modal | ✅ `Wallet.walletPicker/viewWalletOption` |
| Chain gate | blocks children until on expected chain, switch CTA | ✅ `ChainGate` |
| Tx action button | `Tx.Status`-driven: disabled/pending/label states | ✅ `Transaction.actionButton/statusBadge` |
| Tx status + hash | badge, link, confirmation display | ✅ — 🟡 no n/N confirmation progress binding (`transactionConfirmations` exists in elm-web3; wire it to `ProgressRing`) (**build**) |
| Pending overlay | modal scrim during signature/pending | ✅ `PendingOverlay` |
| Receipt view | success/fail, gas, block, logs link | ✅ `Transaction.receiptView` |
| Sign flow | `SignState`-driven button + signature display | ✅ `Sign.stateView/signButton/signatureView` |
| Gas estimate flow | estimate → display → proceed | ✅ `GasEstimate` + `ContractWrite` |
| Generic read form | any fn: AbiInputs → call → decoded result | ✅ `ContractRead` |
| Generic write form | any fn: AbiInputs → estimate → send → track | ✅ `ContractWrite` |
| Account pill | address + balance + chain + disconnect menu, one compound | ❌ **build** — the standard dapp header unit (RainbowKit's core loop); compose from shipped atoms |
| Approval flow | allowance read → approve tx → action tx, as ONE component | ❌ **build** — the single most-repeated flow in all of web3; every ERC-20 interaction needs it |
| Event feed | live log subscription → prepend-rendered rows | 🟡 `ActivityRow` renders; no binder to `Web3.Subscription` (**build**: `EventFeed` = subscription plumbing + `ActivityRow`) |
| Balance watcher | re-fetch balances on new block | ❌ **build** (thin: `watchBlockNumber` → refetch policy) |
| Tx toast / queue | multiple in-flight txs, corner toasts | ❌ **build** (needs the `TxQueue` generic below) |
| Revert toast | failed tx → decoded reason, retry affordance | ❌ **build** (pairs with the L0 revert atom) |

## Layer 3 — Flow generics (type-level machinery)

The highest-leverage layer: generic types that make every dapp's `Model`
smaller. These are what "generics" means for a web3 UI package.

| Generic | Type sketch | Status |
|---|---|---|
| Remote call | `RemoteCall a = NotAsked \| Loading CorrelationId \| Success a \| Failure Web3Error` — RemoteData specialised to correlation-id port round-trips, with `update`/`view` helpers | ❌ **build first** — every module above reinvents this shape ad hoc; it is the package's missing foundation |
| Two-step tx | `TwoStep = CheckingAllowance \| NeedsApproval Tx.Status \| Acting Tx.Status \| Done` — the approve-then-act machine behind `ApprovalFlow` | ❌ **build** (with a TLA+ spec in elm-web3 style — it IS a state machine) |
| Tx queue | `TxQueue = Dict CorrelationId Tx.Status` + fold-into-view — many in-flight txs without Model gymnastics | ❌ **build** |
| Simulate-first write | run `readCall withFrom` preview, show result, then send — wraps `ContractWrite` | ❌ **build** (elm-web3 already has the simulate capability) |
| Block-refresh policy | `Refresh = EveryBlock \| EveryNBlocks Int \| Manual` driving re-fetch of a `RemoteCall` | ❌ **build** |
| Validated form | combine typed inputs into `Result (List FieldError) args` | 🟡 per-input validation exists; no combinator (**build**: small applicative) |
| Paginated logs | block-range windowed `getLogs` loader with "load more" | ❌ **build** (nice-to-have) |
| Optimistic update | show expected post-state, reconcile on receipt | ❌ **skip for now** — high complexity, easy to get dishonest UX; revisit with demand |

## Layer 4 — Domain compounds (batteries included)

Shipped because a production dapp needed them; kept because they're broadly
reusable.
Not part of the "complete primitive set" contract — a dapp could build all of
these from Layers 0–3.

✅ Shipped: `StakeCard`, `NFTStakeCard`, `BondCard`, `BondingCurve`, `VeLock`,
`VeBalanceChart`, `GaugeRow`, `FundingPool`, `SecurityCard`, `HoldClock`,
`ActivityRow`, `SupplyBar`, `FeeBreakdown`, `FeeFlowDiagram`.

❌ Not shipped, commonly wanted: swap widget, LP position card,
proposal/vote row, claim/airdrop checker, mint widget. **Verdict:** build
only when a real project needs one — Layer 0–3 completeness is what makes
them cheap to assemble.

## Cross-cutting concerns

| Concern | Status |
|---|---|
| Theming | ✅ every component uses stable `web3-*` CSS classes, zero inline styles — themes are pure CSS. Keep this contract |
| Accessibility | 🟡 buttons/tabs are semantic; async states need `aria-busy`/`aria-live` sweep (**build**: one audit pass) |
| Locale number formatting | ❌ **skip** — Elm-side locale formatting is a separate concern (`cuducos/elm-format-number` exists); document the seam |
| Responsive | ✅ CSS-side by design (classes, no fixed widths) |

---

## The roadmap, ranked (what 2.x should build)

1. **`RemoteCall` generic** — the foundation everything else binds to
2. **`ApprovalFlow`** (+ `TwoStep` machine, TLA+-specced) — web3's most repeated flow
3. **Revert reason atom + toast** — elm-web3 decodes it; users never see it
4. **`AccountPill`** — the standard header compound
5. **Chain selector** bound to switch/add flows
6. **Confirmation progress** (`transactionConfirmations` × `ProgressRing`)
7. **Max/percent presets** on amount input; **token-amount pair** compound
8. **`EventFeed`** subscription binder
9. **Skeleton variants** for the read-heavy atoms
10. **Blockies/identicon** (pure Elm)

Done ⇒ this package covers every layer of the taxonomy that is web3's to own.
