# The complete web3 UI primitive set

An exhaustive taxonomy of every primitive and generic a web3 UI package needs,
graded against what `intrepidshape/elm-web3-ui` ships today. This is the
package's map and roadmap — the UI-layer companion to elm-web3's
`proofs/EVM_API_COVERAGE.md`. Audited 2026-07-02 against the exposed
modules; regraded same day after the 2.1.0 primitive build (46 modules).
Every generic primitive is demonstrated live in `examples/gallery/`.

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
| Identicon / blockie | deterministic avatar from address | ✅ `Identicon` — canonical blockies algorithm, pure Elm (SVG); raw `cells` exposed for canvas renderers |
| Token logo/symbol | logo url + symbol fallback | ✅ `TokenLogo` — img with lazy loading, deterministic letter-tile fallback (hue from symbol, class-based, zero inline styles) |
| QR code | address receive flow | ❌ **skip** — belongs to a general QR package, not web3-ui |
| Skeleton / shimmer | loading placeholder shaped like the atoms above | ✅ `Skeleton.line/block/circle/pill/address/amount` — aria-hidden bones, shimmer is pure CSS |
| Empty state | "no positions yet" | ❌ **skip** — not web3-specific |
| Revert reason display | decoded `Error(string)` → human banner | ✅ `Revert.banner/toast/reason` — decodes via elm-web3, honest labelled fallback for custom errors |

## Layer 1 — Input atoms (validated, typed)

| Primitive | What | Status |
|---|---|---|
| Amount input | decimals-aware, BigInt-backed, paste-sanitizing | ✅ `Amount.amountInput`, `Input.bigInt`, `Amount.presetRow` (25/50/75/MAX chips) |
| Address input | validation + visual confirm | ✅ `Address.input`, `Input.address` |
| Typed ABI inputs | every solidity type incl. arrays/tuples | ✅ `AbiInput` (uint*/int*/bool/string/bytes/bytesN/T[]/T[N]) |
| Slippage control | presets + custom bps | ✅ `SlippageInput` |
| Lock period | slider snapped to contract-valid periods | ✅ `LockPeriod` |
| Token selector | search + pick from a list | ✅ `TokenSearch` |
| Tab switcher | buy/sell, stake/unstake | ✅ `TradeTabs` |
| Deadline control | tx deadline minutes | ✅ `Deadline` — presets + custom, `toUnixDeadline` helper |
| Chain selector | pick from configured chains, triggers switch flow | ✅ `ChainSelector` — radiogroup semantics; renders truth from `Wallet.State`, never optimistic |
| Token-amount pair | token selector + amount input + balance + max, as one unit | ❌ **build** — the swap/deposit workhorse; compose from existing atoms |

## Layer 2 — State-machine-bound components (the elm-web3 glue)

| Primitive | What | Status |
|---|---|---|
| Connect button | full `Wallet.State` render, per-state labels | ✅ `Wallet.connectButton/viewState` |
| Wallet picker | EIP-6963 provider list modal | ✅ `Wallet.walletPicker/viewWalletOption` |
| Chain gate | blocks children until on expected chain, switch CTA | ✅ `ChainGate` |
| Tx action button | `Tx.Status`-driven: disabled/pending/label states | ✅ `Transaction.actionButton/statusBadge` |
| Tx status + hash | badge, link, confirmation display | ✅ incl. `Transaction.confirmationProgress` (n/N dots — monotonicity guaranteed upstream) |
| Pending overlay | modal scrim during signature/pending | ✅ `PendingOverlay` |
| Receipt view | success/fail, gas, block, logs link | ✅ `Transaction.receiptView` |
| Sign flow | `SignState`-driven button + signature display | ✅ `Sign.stateView/signButton/signatureView` |
| Gas estimate flow | estimate → display → proceed | ✅ `GasEstimate` + `ContractWrite` |
| Generic read form | any fn: AbiInputs → call → decoded result | ✅ `ContractRead` |
| Generic write form | any fn: AbiInputs → estimate → send → track | ✅ `ContractWrite` |
| Account pill | address + balance + chain + disconnect menu, one compound | ✅ `AccountPill` — all six wallet states, identicon included |
| Approval flow | allowance read → approve tx → action tx, as ONE component | ✅ `ApprovalFlow` — guarded machine, fuzz-tested AND TLC-model-checked (`proofs/tla/ApprovalSpec.tla`) |
| Event feed | live log subscription → prepend-rendered rows | 🟡 `ActivityRow` renders; no binder to `Web3.Subscription` (**build**: `EventFeed` = subscription plumbing + `ActivityRow`) |
| Balance watcher | re-fetch balances on new block | ❌ **build** (thin: `watchBlockNumber` → refetch policy) |
| Tx toast / queue | multiple in-flight txs, corner toasts | ✅ `TxQueue.toastStack` — id-routed, aria-live |
| Revert toast | failed tx → decoded reason, retry affordance | ✅ `Revert.toast` |

## Layer 3 — Flow generics (type-level machinery)

The highest-leverage layer: generic types that make every dapp's `Model`
smaller. These are what "generics" means for a web3 UI package.

| Generic | Type sketch | Status |
|---|---|---|
| Remote call | `RemoteCall a` — RemoteData specialised to correlation-id port round-trips | ✅ `RemoteCall` — id-guarded `resolve` (stale answers dropped; the SignSpec no-cross-confusion rule applied to reads) |
| Two-step tx | the approve-then-act machine behind `ApprovalFlow` | ✅ `ApprovalFlow.Step/update` — TLA+-specced and TLC-verified, elm-web3 style |
| Tx queue | many in-flight txs without Model gymnastics | ✅ `TxQueue` — opaque, id-routed, no ghost entries |
| Simulate-first write | run `readCall withFrom` preview, show result, then send — wraps `ContractWrite` | ❌ **build** (elm-web3 already has the simulate capability) |
| Block-refresh policy | `Refresh = EveryBlock \| EveryNBlocks Int \| Manual` driving re-fetch of a `RemoteCall` | ❌ **build** |
| Validated form | combine typed inputs into `Result (List FieldError) args` | ✅ `Form` — accumulating applicative (`succeed`/`andMap`), no short-circuit |
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

## The roadmap, ranked (what remains after 2.1.0)

The 2.1.0 build shipped the previous top of this list: `RemoteCall`,
`ApprovalFlow` (+ TLC-checked `ApprovalSpec.tla`), `Revert`, `AccountPill`,
`ChainSelector`, `Deadline`, `TxQueue`, `Form`, `Skeleton`, `Identicon`,
`Amount.presetRow`, `Transaction.confirmationProgress`. Still open:

1. **Token-amount pair** — token selector + amount + balance + max as one
   unit (compose from shipped atoms)
2. **`EventFeed`** — bind `Web3.Subscription` log streams to `ActivityRow`
3. **Block-refresh policy** + balance watcher (re-fetch `RemoteCall`s on
   new blocks)
4. **Simulate-first write** (elm-web3 already has the capability)
5. Token logo/symbol atom; `Address.copyable`; dust convention in `Amount`
6. Paginated logs loader
7. a11y sweep (`aria-busy`/`aria-live` audit across the older modules —
   the 2.1.0 modules ship with it)

Done ⇒ this package covers every layer of the taxonomy that is web3's to own.
