# Changelog

## 2.0.0 — 2026-03-27

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
