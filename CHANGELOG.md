# Changelog

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
