# elm-web3-ui

UI primitives for [elm-web3](https://package.elm-lang.org/packages/intrepidshape/elm-web3/latest/) — wallet, transaction, address, and input components.

## Install

```sh
elm install intrepidshape/elm-web3-ui
```

Requires `intrepidshape/elm-web3` 2.0.0+.

## Design

- **No default styles** — every element gets a semantic `class` attribute. Supply your own CSS.
- **Attribute passthrough** — every function takes `List (Html.Attribute msg)` as its first argument, merged onto the root element.
- **No internal Msg** — all functions return `Html msg` with callbacks as plain `msg` values.
- **No validation** — input components are thin wrappers; call `T.address`, `BigInt.fromString`, etc. in your app.

## Modules

| Module | Contents |
|---|---|
| `Web3.Ui.Wallet` | Connect button, wallet picker, full wallet state view, chain badge |
| `Web3.Ui.Transaction` | Status badge, action button, tx hash link |
| `Web3.Ui.Address` | Address display (with optional explorer link), `short` truncation, address input |
| `Web3.Ui.Balance` | Balance display with `formatUnits` / `formatEther` |
| `Web3.Ui.Input` | Typed inputs: `address`, `bigInt`, `bool`, `text`, `bytes` |
| `Web3.Ui.Sign` | Sign state display, sign button |

## Quick start

```elm
import Web3.Ui.Wallet as WalletUi
import Web3.Ui.Transaction as TxUi
import Web3.Ui.Address as AddressUi

-- In your view:
view model =
    div []
        [ WalletUi.connectButton []
            { onConnect = ConnectWallet, onDisconnect = DisconnectWallet }
            model.wallet
        , TxUi.statusBadge [] model.tx
        , TxUi.actionButton []
            { label = "Buy", pendingLabel = "Buying…", onPress = SubmitBuy }
            model.tx
        ]
```

## CSS class reference

| Element | Class |
|---|---|
| Connect button | `web3-connect-btn` |
| Disconnect button | `web3-disconnect-btn` |
| Wallet picker container | `web3-wallet-picker` |
| Individual wallet option | `web3-wallet-option` |
| Chain badge | `web3-chain-badge` |
| Full wallet state wrapper | `web3-wallet-state` |
| Tx status badge | `web3-tx-badge` |
| Tx badge state modifiers | `web3-tx-badge--idle`, `--pending`, `--confirmed`, `--failed`, `--rejected` |
| Action button | `web3-action-btn` |
| Action button (disabled) | `web3-action-btn--pending` |
| Tx hash link | `web3-tx-link` |
| Address display | `web3-address` |
| Balance display | `web3-balance` |
| Address input | `web3-input-address` |
| Address input (invalid) | `web3-input-address--invalid` |
| BigInt input | `web3-input-bigint` |
| Bool input | `web3-input-bool` |
| Text input | `web3-input-text` |
| Bytes input | `web3-input-bytes` |
| Sign state display | `web3-sign-state` |
| Sign button | `web3-sign-btn` |

## License

MIT
