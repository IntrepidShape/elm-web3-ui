# Changelog

## 2.3.1 — 2026-07-02

- Docs-only: README refresh (module count, gallery/theme/proofs links) so
  the registry page carries the current front door. No code changes.


## 2.3.0 — 2026-07-02

### Added — the flow-generic completion

- **`TokenAmountPair`** — the swap/deposit workhorse compound.
- **`EventFeed`** — Subscription→rows binder: honest live/fallback status
  chip, capped newest-first list (fuzz: cap never exceeded), aria-live.
- **`BlockRefresh`** — block-cadence refetch policies (EveryBlock /
  EveryNBlocks / Manual); the balance watcher is its documented example.
  Fuzz: fires exactly on gap ≥ N, Manual never fires.
- **`SimulateFirst`** — preview-before-sign machine: `confirm` is the only
  door into Sending (fuzz: unreachable without it); wallet rejection
  returns to the still-true preview.
- **`PaginatedLogs`** — windowed getLogs walker; fuzz-proved exact tiling
  to genesis (no overlap, no gap).
- **`Address.copyable`** — copy affordance emitting intent (app owns the
  clipboard; zero JS here, one-line port documented).
- **`Amount.formatWeiDust`** — `"<0.0001"` dust convention ("0" must mean
  zero).
- **`Revert.bannerWith`/`toastWith`** — typed custom-error rendering; pass
  elm-web3 ≥ 1.4.0's `decodeCustomError fragments`.

### Accessibility

- TradeTabs: proper `role="tab"` + `aria-selected`; PendingOverlay:
  `role="status"` + `aria-busy`.

113+ tests green (structural fuzz for every new machine).


## 2.2.0 — 2026-07-02

### Added

- **`TokenLogo`** — token logo atom: lazy-loaded `<img>` when a url is
  known, deterministic letter-tile fallback when not (tile hue derived from
  the symbol via class buckets — zero inline styles, riceable like
  everything else). Closes the PRIMITIVES.md token-logo gap.


## 2.1.2 — 2026-07-02

- README: prominent links to the [live gallery](https://intrepidshape.github.io/elm-web3-ui/),
  the reference theme, `PRIMITIVES.md`, and elm-web3's
  [proofs page](https://intrepidshape.github.io/elm-web3/) — so all of it
  surfaces on the package registry too. Docs-only release.


## 2.1.1 — 2026-07-02

### Fixed

- **`Identicon.view` crashed at runtime when passed `Html.Attributes.class`**
  (which every caller does — including our own `AccountPill`): the
  `className` property is read-only on SVG elements. The user attrs now land
  on an `Html.span` wrapper (class `web3-identicon`), making any
  `Html.Attribute` safe. Found by opening the gallery — the page died on
  first render in 2.1.0.
- **Require `intrepidshape/elm-web3 ≥ 1.2.2`** — 1.2.2 fixes the
  `Error(string)` selector typo (`08c379a2` → `08c379a0`) that meant NO real
  on-chain revert reason ever decoded; `Revert` is only useful with it. Also
  found via the gallery: a canonical solc payload refused to decode on
  screen.
- Gallery: reference CSS now covers the real class names of `ProgressRing`,
  `SupplyBar`, `Sign`, `FeeBreakdown`, and `SlippageInput`'s custom-input
  wrapper; SupplyBar demo data at 18-decimal scale; interactions click-tested
  end-to-end headlessly (stale-answer drop, full ApprovalFlow, tx lifecycle
  through receipt).

### Added

- GitHub Pages deploy for the gallery (`.github/workflows/pages.yml`) — the
  demo is its own public page, rebuilt on every push to master.


## 2.1.0 — 2026-07-02

### Added — the generic primitive build (10 new modules + gallery)

Twelve items off the top of the PRIMITIVES.md roadmap, all
protocol-agnostic, all CSS-class themeable, aria-annotated:

- **`RemoteCall`** — the correlation-id remote-data foundation. Id-guarded
  `resolve`: a stale response for a superseded request is dropped, never
  rendered (the SignSpec no-cross-confusion rule applied to reads).
- **`ApprovalFlow`** — the approve-then-act machine behind every ERC-20
  interaction. Structurally safe (Acting is unreachable without a verified
  allowance), rejection ≠ failure, confirmed approvals re-check the chain.
  Fuzz-tested (10 properties) **and TLC-model-checked** — this repo now has
  its own `proofs/tla/ApprovalSpec.tla` + `check-tla.sh`, wired into CI.
- **`AccountPill`** — the wallet header compound, all six states, identicon
  included.
- **`Identicon`** — canonical Ethereum blockies in pure Elm (faithful
  xorshift port, SVG, `cells` exposed for canvas renderers).
- **`TxQueue`** — many in-flight transactions, id-routed, toast stack view.
- **`Revert`** — decoded `Error(string)` revert reasons as banner/toast,
  honest fallback for custom errors.
- **`ChainSelector`** — radiogroup chain picker for the switch flow.
- **`Skeleton`** — six loading bones shaped like the atoms they replace.
- **`Deadline`** — tx deadline picker, sibling of `SlippageInput`.
- **`Form`** — accumulating validation applicative (all errors, not the
  first).
- `Transaction.confirmationProgress` — n/N confirmation dots (additive).
- `Amount.presetRow` — 25/50/75/MAX chips (additive).

### Added — the gallery

`examples/gallery/` — every generic primitive in every state on one page,
driven entirely by simulated messages (the state machines are pure, so the
whole dapp surface demos without a wallet, a node, or JS). `gallery.css` is
the reference theme: every `web3-*` class styled from a handful of tokens —
copy it and re-color to rice the entire kit.

27 new tests (93 total). Pure additive — compiler-verified MINOR.


## 2.0.0 — 2026-07-02

> Registry note: versions 1.6.0–1.10.1 were tagged in git but never
> `elm publish`ed, and the Elm registry only accepts exactly-next versions —
> so those tags are permanently unpublishable (registry had only 1.0.0).
> This release publishes everything since 1.0.0, under the MAJOR bump the
> accumulated API changes require anyway. Git history and the entries below
> preserve the 1.x story.

### Breaking — explorer links unified on `Maybe String`

- **`Transaction.txHashLink` and `Transaction.receiptView`** now take
  `{ explorerUrl : Maybe String }`, matching `statusHashLink`,
  `hashDisplay`, `Web3.Ui.Address`, and `ContractWrite`. `Nothing` renders a
  plain `<span class="web3-tx-hash">` instead of a dead link (local
  Anvil/Hardhat dev). Migration: wrap your url in `Just`.
  `txHashLink` is now literally `hashDisplay` — one rendering path.

### Changed

- **Require `intrepidshape/elm-web3 ≥ 1.2.1`** — 1.2.1 fixes three wallet /
  transaction state-machine bugs this UI's flows rely on (WrongChain recovery
  via `chainChanged`, `readOnly` no longer tearing down a live session,
  monotonic confirmation counts). The constraint encodes that assumption.

### Added

- **`PRIMITIVES.md`** — exhaustive taxonomy of every primitive and generic a
  web3 UI package needs, graded against the 36 shipped modules, with the
  ranked 2.x roadmap (headline gaps: `RemoteCall` generic, `ApprovalFlow`,
  revert-reason surfacing, `AccountPill`, chain selector).

### Fixed

- `TransactionUiTest` had been failing to compile since the
  `statusHashLink` API change (stale non-`Maybe` call sites). All 66 tests
  green.

## 1.10.1 — 2026-05-14 (git tag only — never published)

### Changed — generalised the audit-pool primitive

- **`Web3.Ui.AuditPool` → `Web3.Ui.FundingPool`** — the structural
  shape (target + balance + deadline + pledger count + refund-by-
  deadline fallback) is universal across any crowd-funded escrow
  mechanism, not just audits. Renamed and parameterised every
  user-facing string via a [`Labels`](Web3-Ui-FundingPool#Labels)
  record. `defaultLabels` give generic copy; callers (forge.intrepiddev,
  bug-bounty pools, feature-funding kickstarters) override per
  mechanism.

  Migration: replace `import Web3.Ui.AuditPool as Pool` with
  `import Web3.Ui.FundingPool as Pool` and pass a `labels` field on
  the `Config`. All type names are identical; only the module name
  and the new `labels` field change.

## 1.10.0 — 2026-05-14

### Added — Trustpilot-style security pre-flight card

- **`Web3.Ui.SecurityCard`** — renders static-analysis findings (from
  Slither / Aderyn / Mythril, or any tool that produces severity-bucketed
  findings) as a breakdown card. Five-stop severity counter (critical /
  high / medium / low / info), top-3 findings inline, tool-versions
  badges, prominent disclaimer.
  
  Design intent: **never a Pass/Fail verdict**. Static analyzers have
  false-positive rates; the card surfaces signal, not judgement.

### Added — Community-funded audit panel

- **`Web3.Ui.AuditPool`** — render the on-chain audit-pool state
  (target / balance / deadline / pledger count) with pledge / refund /
  view-report CTAs that vary by status (`Open` / `Funded` / `Closed`).
  Status pill, top-pledger list, progress bar, service-prepayment
  disclaimer. Stateless — caller owns the `Pool` value and supplies
  `msg`s for each action.

Used by the hosted forge above every generated dapp page, paired with
`Web3.Ui.SecurityCard` to give the static-analysis signal plus the
community-funding pathway in one surface.

---

## 1.9.0 — 2026-05-14

### Added — typed-slot parser for the pure-Elm calldata path

- **`Web3.Ui.AbiInput.parseSlot : Field -> Value -> Result String Calldata.Slot`** —
  produces a [`Web3.Abi.Calldata.Slot`](https://package.elm-lang.org/packages/intrepidshape/elm-web3/1.2.0/Web3-Abi-Calldata#Slot)
  ready to feed into the pure-Elm calldata path. The existing `parse`
  (returns `Json.Encode.Value` for the legacy method+args port shape) is
  unchanged.

Generated dapps from `@intrepidshape/dapp-gen` 0.2+ use `parseSlot`,
which keeps the entire calldata-encoding path inside Elm and drops the JS
side to a pure pass-through.

### Requires

Bumps the `intrepidshape/elm-web3` dep floor to **1.2.0** (introduced
`Web3.Abi.Calldata`).

---

## 1.8.0 — 2026-05-14

### Added — Tier-1 primitives (any-contract dapp surface)

Three generic primitives that let a dapp render *any* Solidity contract
from its ABI alone, without bespoke per-function code. These are the
target API for the upcoming `dapp-gen` CLI.

- **`Web3.Ui.AbiInput`** — Typed input for any Solidity arg shape:
  `address`, `uint*`, `int*`, `bool`, `string`, `bytes`, `bytesN`, `T[]`,
  `T[N]`, and `tuple` (recursive). Returns a `Value` the caller stores
  and a `parse` function that produces a `Json.Encode.Value` ready for
  the port. Recursive tuple / array rendering composes the existing
  `Web3.Ui.Input.*` primitives.
- **`Web3.Ui.ContractRead`** — Renders a `view`/`pure` call as a typed
  form: name header, one `AbiInput` per argument, "Read" button, result
  panel with explicit `Idle / Pending / Success / Failed` lifecycle.
- **`Web3.Ui.ContractWrite`** — Renders a state-changing call:
  same arg-input shape, optional `msg.value` for `payable`, "Send" button
  wired through `Web3.Transaction.Status`, status badge, hash link, and
  failure-reason readout.

All three follow the existing design contract: plain `Html msg`, attribute
passthrough, no internal `Msg`, no subscriptions, semantic class names
(`web3-abi-input`, `web3-contract-read`, `web3-contract-write` + BEM
modifiers).

### Changed

- `summary` updated to reflect the any-contract framing.

---

## 1.7.0 — 2026-05-13

### Added — DeFi UI surface expansion

Twenty new exposed modules covering the full DeFi frontend surface:

- `Web3.Ui.ActivityRow` — typed activity-feed row (swap / stake / claim / vote).
- `Web3.Ui.BondCard` — bond-buy card with vesting and discount display.
- `Web3.Ui.BondingCurve` — bonding-curve plot with current-price marker.
- `Web3.Ui.FeeBreakdown` — protocol-fee disclosure list (% of headline, never absolute decimals).
- `Web3.Ui.FeeFlowDiagram` — fee-routing Sankey diagram, SVG.
- `Web3.Ui.GaugeRow` — gauge-vote row with weight, emissions, voter count.
- `Web3.Ui.HoldClock` — countdown display for time-locked positions.
- `Web3.Ui.LockPeriod` — lock-period selector (range slider + presets).
- `Web3.Ui.NFTStakeCard` — NFT stake card with image, lock, reward APR.
- `Web3.Ui.ProgressRing` — SVG progress ring for time or completion.
- `Web3.Ui.RelativeTime` — humanised relative-time renderer ("3m ago", "in 2d").
- `Web3.Ui.SlippageInput` — slippage-tolerance input with preset chips.
- `Web3.Ui.StakeCard` — generic stake card: deposit / withdraw / claim / APR.
- `Web3.Ui.StatCell` — single-stat tile with label, value, unit, delta.
- `Web3.Ui.SupplyBar` — total-supply / circulating-supply bar with burn segment.
- `Web3.Ui.TokenSearch` — token search with logo, symbol, balance.
- `Web3.Ui.TradeTabs` — buy / sell / wrap / unwrap tab selector.
- `Web3.Ui.TrendIndicator` — typed trend arrow (Up / Flat / Down) with magnitude.
- `Web3.Ui.VeBalanceChart` — vote-escrow balance decay chart, SVG.
- `Web3.Ui.VeLock` — vote-escrow lock card with lock-up display.

All follow the existing design rules: plain `Html msg`, attribute passthrough, no internal `Msg`, no subscriptions, semantic class names.

### Changed

- Corrected `intrepidshape/elm-web3` dependency range to `1.0.0 <= v < 2.0.0` (registry-published version line under the `intrepidshape` namespace).
- README rewrite: leads with the frontend-security positioning, exhaustive benefit list (supply chain, type safety, state machines, auditability, sec-gap closure), tightened "Made by" section.
- `docs.json` now tracked in repo; regenerated against all 31 exposed modules.

---

## 1.6.0 — 2026-05-12

### Added — `Web3.Ui.PendingOverlay.viewMultiStep`

Multi-step approve→call overlay for two-stage write flows where the
approve toast otherwise fades before the call lands (revealed by the
 audit's "approve→call gap" finding). One overlay shows the
full sequence — pending · active · done · failed — so the user never
loses visibility into which stage just reverted.

```elm
Web3.Ui.PendingOverlay.viewMultiStep []
    { steps =
        [ { label = "Approve $TOKEN", state = StepDone }
        , { label = "Stake $TOKEN", state = StepActive }
        , { label = "Confirm on-chain", state = StepPending }
        ]
    , currentStatus = model.txStatus
    }
```

New exports: `viewMultiStep`, `Step`, `StepState(..)`.

Renders an empty node when every step is `StepPending` AND
`currentStatus = Tx.Idle`, so callers can leave it in the tree
without per-page guards.

CSS classes: `web3-pending-overlay-multi`, `web3-pending-step`,
`web3-pending-step--pending/--active/--done/--failed`,
`web3-pending-step-glyph`, `web3-pending-step-label`,
`web3-pending-step-reason`.

## 1.5.0 — 2026-05-11

### Added — `Web3.Ui.Transaction.toast`

The composite every dapp re-implements: a labeled transaction toast with
status-tone styling, hash pill, copy + explorer action buttons, and
dismiss. Renders all 7 `Tx.Status` cases — including the new structured
`Failed FailureDetail` shape — from a single call:

```elm
Web3.Ui.Transaction.toast []
    { label = "Approving TKN"
    , explorerTxUrl = Just (Web3.Chain.txUrl Web3.Chain.pulsechain)
    , onCopyHash = Just CopyAddress
    , onDismiss = Just DismissTx
    }
    model.txStatus
```

Pass `Nothing` for any optional callback to suppress that affordance —
useful for read-only environments (no clipboard) or local dev (no explorer).
The  consumer dropped ~210 LoC of hand-rolled toast plumbing
adopting it.

### Added — `Web3.Ui.Transaction.humanFailureLabel`

Maps a `Tx.FailureReason` to a one-line human label. Used internally by
`toast`; exposed so consumers can render the same labels in their own
custom layouts (badge, modal, banner, …) without re-implementing the
string-matching.

### Required upgrade — elm-web3 2.x

This release depends on `intrepidshape/elm-web3 2.x` for the new
`Tx.FailureReason` ADT and `Web3.Chain.txUrl` / `addressUrl` helpers.
Consumers upgrading from 1.x must bump both `elm-web3` and `elm-web3-ui`
together.

## 1.4.0 — 2026-05-11

### Added — `Web3.Ui.Wallet.walletMenu`

A composite dropdown for the connected-wallet case: renders the
`walletPicker` over the current `WalletProvider` list and tacks on a
"Disconnect" row below. Fixes the common dapp UX bug where clicking the
connected-address pill hard-wires to `disconnect`, leaving no path to
switch wallets without a full disconnect → reconnect cycle.

```elm
Web3.Ui.Wallet.walletMenu []
    { onSelect = SelectWallet         -- swap to a different injected wallet
    , onDisconnect = DisconnectWallet -- exit entirely
    , selected = Just currentRdns     -- optional highlight
    }
    model.walletProviders
```

Renders `.web3-wallet-menu` containing the existing `.web3-wallet-picker`
plus a `.web3-wallet-menu-disconnect` button — consumers style as desired.

## 1.3.0 — 2026-05-10

### Added — Vote-escrow, NFT-stake, bond, gauge, and fee-flow primitives

Six new generic primitives shipped together. Each one is protocol-agnostic
(passes the genericity test in `~/.claude/skills/intrepid-elm-web3-frontend/SKILL.md`)
and accepts `Web3.BigInt.BigInt` + plain numeric configs — no protocol-specific
naming.

- **`Web3.Ui.VeLock`** — Lock-duration picker for vote-escrow tokens (Curve
  veCRV, GMX esGMX, veToken, …). Composes `Amount.amountInput` with
  a step-snapped range slider; live ve-balance projection via the linear-decay
  formula `amount * lockSec / maxLockSec`.
- **`Web3.Ui.VeBalanceChart`** — SVG line chart of ve-balance decaying linearly
  from `nowSec` to `unlockTime`. Educational primitive, mirrors the
  `BondingCurve.sparkline` pattern.
- **`Web3.Ui.NFTStakeCard`** — Card for an ERC-721 stake position. Surfaces
  `tokenId`, two independent countdowns (principal unlock vs. floor-redemption
  eligibility), pending yield, and four actions (claim / redeem-at-floor /
  unstake / transfer).
- **`Web3.Ui.BondCard`** — Card for a fixed-term bond receipt: principal,
  maturity countdown, pending yield, claim / redeem / roll actions. Generic
  for any term-deposit primitive.
- **`Web3.Ui.GaugeRow`** — One row of a vote-escrow gauge list: gauge label,
  epoch, total votes, total bribes, your share %, APR estimate, plus
  vote / bribe / claim actions. Generic for Curve-style gauge voting.
- **`Web3.Ui.FeeFlowDiagram`** — Educational stacked-bar visualization of a
  fee split. Pairs with `FeeBreakdown` (the table view); use this one for
  hero-tier "where does my fee go?" graphics. Segments accept a `kind`
  string emitted as a CSS modifier suffix (`web3-feeflow__seg--ve`, etc.).

### Changed

- `summary` extended to mention vote-escrow, NFT-stake, bond, and gauge
  primitives.

## 1.2.0 — 2026-05-10

### Added — Generic DeFi UI primitives (modular by design)

Each module is intentionally protocol-agnostic. APIs accept `Web3.BigInt.BigInt`,
`Web3.Types.Address`, basis-points integers, or generic record configs — never
protocol-specific naming. Pass the genericity test from
`~/.claude/skills/intrepid-elm-web3-frontend/SKILL.md`.

- **`Web3.Ui.RelativeTime`** — "2m ago" / "3h ago" / "1d ago" timestamp
  rendering with absolute-time tooltip.
- **`Web3.Ui.StatCell`** — label + value + optional delta + sentiment.
  Use for any analytics row (TVL, APR, floor, volume, etc.).
- **`Web3.Ui.TradeTabs`** — single-select tab switcher parameterized by your
  app's tab `id` type. Buy/Sell/Stake on a launchpad, Long/Short on a perp,
  Mint/Redeem on a vault — same component.
- **`Web3.Ui.TokenSearch`** — search input emitting change events; consumer
  owns filter logic.
- **`Web3.Ui.ProgressRing`** — circular progress for "X% toward Y" KPIs.
  SVG; styling via CSS.
- **`Web3.Ui.BondingCurve`** — SVG sparkline of any `A * x^N` curve. Caller
  supplies `coeffA`, `exponent`, `supply`, `maxSupply`, optional `floorPrice`
  marker. Generic over any sub-/super-linear issuance model.
- **`Web3.Ui.ActivityRow`** — one row of an on-chain activity feed with a
  `Kind` enum (Buy / Sell / Stake / Unstake / Penalty / Create / Graduate /
  Claim / Other). The `Other String` escape-hatch covers any DeFi event.

### Changed

- `summary` rewritten to emphasize modular DeFi-generic positioning.
- `dependencies`: added `elm/svg` (used by `ProgressRing` and `BondingCurve`).

## 1.1.0 — 2026-05-10

### Added — DeFi-flavored UI primitives

- **`Web3.Ui.SupplyBar`** — progress bar for supply caps, graduation reserves,
  vault deposit limits. Optional milestone marker for thresholds.
- **`Web3.Ui.LockPeriod`** — native range slider for stake-lock-days picker
  with optional early-exit penalty hint.
- **`Web3.Ui.HoldClock`** — visual countdown of a graduated-fee tier
  (e.g., 5% → 1% over N days).
- **`Web3.Ui.TrendIndicator`** — Up/Neutral/Down arrow with paired buy/sell
  volume pills; `fromVolumes` derives Trend from a basis-point threshold.
- **`Web3.Ui.FeeBreakdown`** — multi-slice fee table showing bps + Wei amount
  per slice + optional recipient address.
- **`Web3.Ui.SlippageInput`** — preset chips + custom-percent input;
  `minOutFromBps` helper for slippage-protected `minTokensOut` / `minPlsOut`.
- **`Web3.Ui.StakeCard`** — generic stake-position card: amount, lock countdown,
  accrued yield, eligibility badges, claim/unstake actions.

All seven primitives ship with `web3-<module>-*` BEM-ish CSS classes (no inline
semantic colors), accept `Web3.BigInt.BigInt` and `Web3.Types.Address` directly,
and follow the existing `Web3.Ui.Amount`-style record-config API shape.

### Changed

- `elm.json` `dependencies`: added `elm/json` (used by `SlippageInput` for the
  custom-input change handler).

## 1.0.0 — 2026-05-09

First publish of `intrepidshape/elm-web3-ui` on the Elm package registry.
Published by [Intrepid Development](https://intrepiddev.com.au).

The Elm registry tracks per-namespace versions, so this package starts at
1.0.0 under the `intrepidshape` namespace. The internal evolution from
1.0.0 → 2.0.x continued under earlier namespaces (`intrepidshape`,
`bassradian`) and is preserved as historical CHANGELOG entries below for
context. The 2.0.1 source content is what shipped here as 1.0.0. Pairs
with `intrepidshape/elm-web3` ≥ 1.0.0.

The earlier namespaces are no longer maintained.

---

## 2.0.1 (legacy) — 2026-05-09

### Namespace move

Package and repository moved to the `intrepidshape` namespace, where it lives
alongside the rest of [Intrepid Development](https://intrepiddev.com.au)'s
open-source work. Dependency on `elm-web3` updated to the new namespace. No
source changes — `elm install intrepidshape/elm-web3-ui` is a drop-in
replacement for the prior namespace.

The `bassradian/elm-web3-ui` namespace is no longer maintained.

---

## 2.0.0 (legacy) — 2026-03-27

### New modules

- `Web3.Ui.Amount` — token amount input with inline symbol label; `formatWei` formats Wei BigInt with SI suffix (K/M/B/T)
- `Web3.Ui.PriceDisplay` — price display with automatic notation: SI suffix for large values, fixed decimal for normal range, scientific for sub-0.001 prices
- `Web3.Ui.GasEstimate` — estimated transaction cost display; pairs with `Send.estimateGas` and `Fee.getGasPrice`
- `Web3.Ui.PendingOverlay` — overlay for `AwaitingSignature` state; `conditionalView` renders only when needed
- `Web3.Ui.ChainGate` — renders content only on the expected chain; renders a fallback for all other wallet states

### New in existing modules

- `Web3.Ui.Address.shortWith` — configurable prefix/suffix lengths (`shortWith { prefixChars = 8, suffixChars = 6 }`)
- `Web3.Ui.Transaction.hashDisplay` — internal helper rendering either a link or a plain span
- `Web3.Ui.Wallet` — `web3-wallet-option--selected` class on the active wallet in `walletPicker`

### Breaking changes

- `Web3.Ui.Wallet.walletPicker` — second argument changed from `(String -> msg)` to `{ onSelect : String -> msg, selected : Maybe String }`
- `Web3.Ui.Transaction.statusHashLink` — `explorerUrl` field changed from `String` to `Maybe String`; `Nothing` renders a plain `<span class="web3-tx-hash">` instead of a link (for local dev / no explorer)

---

## 1.0.0 — 2026-03-27

Initial release.

### Modules

- `Web3.Ui.Wallet` — connect button, wallet picker, full state view, chain badge
- `Web3.Ui.Transaction` — status badge, action button, tx hash link
- `Web3.Ui.Address` — address display (with optional explorer link), `short` truncation, address text input
- `Web3.Ui.Balance` — balance display via `formatUnits` / `formatEther`
- `Web3.Ui.Input` — typed input primitives: `address`, `bigInt`, `bool`, `text`, `bytes`
- `Web3.Ui.Sign` — sign state display, sign button

### Additions in 1.0.0 final

- `Web3.Ui.Transaction.statusHashLink` — extract a hash link directly from `Tx.Status` (`Nothing` when no hash available)
- `Web3.Ui.Transaction.receiptView` — display a confirmed receipt with block number, gas used, and tx hash link
- `Web3.Ui.Balance.viewMaybe` — balance display with loading state (`Nothing` renders `web3-balance--loading`)
- `Web3.Ui.Balance.viewEtherMaybe` — ether variant of `viewMaybe`
- `Web3.Ui.Input.address` — gains `valid : Bool`; adds `web3-input-address--invalid` when `False`
- `Web3.Ui.Input.bigInt` — gains `valid : Bool`; adds `web3-input-bigint--invalid` when `False`
- `Web3.Ui.Input.bytes` — gains `valid : Bool`; adds `web3-input-bytes--invalid` when `False`
- `Web3.Ui.Sign.signatureView` — displays the signature value from a `Signed` state; empty otherwise
- `Web3.Ui.Wallet.viewState` — gains `knownChains : List Chain`; `WrongChain` branch now shows the target network name
- `Web3.Ui.Wallet.chainBadge` — exhaustive state labels: `"Read-only"` for `ReadOnly`, `"—"` for `Connecting`/`Disconnected`/`Error`
