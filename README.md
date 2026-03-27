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
- **Validation feedback** — `Input.address`, `Input.bigInt`, and `Input.bytes` accept `valid : Bool` and add an `--invalid` modifier class when `False`.

## Modules

| Module | Contents |
|---|---|
| `Web3.Ui.Wallet` | Connect button, wallet picker, full wallet state view, chain badge |
| `Web3.Ui.Transaction` | Status badge, action button, tx hash link, status hash link, receipt view |
| `Web3.Ui.Address` | Address display (with optional explorer link), `short` truncation, address input |
| `Web3.Ui.Balance` | Balance display with `formatUnits` / `formatEther`, loading-state variants |
| `Web3.Ui.Input` | Typed inputs: `address`, `bigInt`, `bool`, `text`, `bytes` |
| `Web3.Ui.Sign` | Sign state display, sign button, signature display |

## Quick start

```elm
import Web3.Chain as Chain
import Web3.Ui.Wallet as WalletUi
import Web3.Ui.Transaction as TxUi
import Web3.Ui.Address as AddressUi

-- In your view:
view model =
    div []
        [ WalletUi.viewState []
            { onConnect = ConnectWallet
            , onSwitchChain = SwitchChain
            , onDisconnect = DisconnectWallet
            , knownChains = [ Chain.pulsechain, Chain.ethereum ]
            }
            model.wallet
        , TxUi.statusBadge [] model.tx
        , TxUi.actionButton []
            { label = "Buy", pendingLabel = "Buying…", onPress = SubmitBuy }
            model.tx
        ]
```

## CSS class reference

| Class | Element |
|---|---|
| `web3-connect-btn` | Connect button |
| `web3-disconnect-btn` | Disconnect button |
| `web3-wallet-picker` | Wallet picker container |
| `web3-wallet-option` | Individual wallet option |
| `web3-chain-badge` | Chain badge |
| `web3-wallet-state` | Full wallet state wrapper |
| `web3-tx-badge` | Tx status badge |
| `web3-tx-badge--idle` | Tx badge — idle state |
| `web3-tx-badge--pending` | Tx badge — pending state |
| `web3-tx-badge--confirmed` | Tx badge — confirmed state |
| `web3-tx-badge--failed` | Tx badge — failed state |
| `web3-tx-badge--rejected` | Tx badge — rejected state |
| `web3-action-btn` | Action button |
| `web3-action-btn--pending` | Action button (disabled/in-flight) |
| `web3-tx-link` | Tx hash link |
| `web3-receipt` | Receipt view root |
| `web3-receipt--success` | Receipt — EVM status true |
| `web3-receipt--failed` | Receipt — EVM status false |
| `web3-receipt-field` | Receipt field row |
| `web3-address` | Address display |
| `web3-balance` | Balance display |
| `web3-balance--loading` | Balance loading state |
| `web3-input-address` | Address input |
| `web3-input-address--invalid` | Address input (invalid) |
| `web3-input-bigint` | BigInt input |
| `web3-input-bigint--invalid` | BigInt input (invalid) |
| `web3-input-bool` | Bool input |
| `web3-input-text` | Text input |
| `web3-input-bytes` | Bytes input |
| `web3-input-bytes--invalid` | Bytes input (invalid) |
| `web3-sign-state` | Sign state display |
| `web3-sign-btn` | Sign button |
| `web3-signature` | Signature display wrapper |
| `web3-signature-value` | Signature `<code>` element |

## License

MIT
