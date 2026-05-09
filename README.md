# elm-web3-ui

HTML view primitives for [elm-web3](https://package.elm-lang.org/packages/intrepidshape/elm-web3/latest/) — wallet connection, transaction status, address display, balance, typed inputs, and signing.

All components return plain `Html msg`. There are no internal messages, no subscriptions, and no state of their own. They render what you pass in and call back with whatever `msg` you provide.

## Install

```sh
elm install intrepidshape/elm-web3-ui
```

Requires `intrepidshape/elm-web3` 2.0.0 or later.

## Design

- **No default styles.** Every element has a semantic `class` attribute. Write your own CSS, or use one of the included stylesheets in `styles/` as a starting point.
- **Attribute passthrough.** Every function takes `List (Html.Attribute msg)` as its first argument, merged onto the root element. Pass `[]` if you have nothing to add.
- **No internal Msg.** All callbacks are plain `msg` values from your application. The components do not own any update logic.
- **Validation feedback.** `Input.address`, `Input.bigInt`, and `Input.bytes` accept a `valid : Bool` field. Pass `False` to apply the `--invalid` modifier class after a failed parse.

## Modules

| Module | Contents |
|---|---|
| `Web3.Ui.Wallet` | Connect button, wallet picker, full wallet state view, chain badge |
| `Web3.Ui.Transaction` | Status badge, action button, tx hash link, receipt view |
| `Web3.Ui.Address` | Address display (with optional explorer link), `short` helper, address input |
| `Web3.Ui.Balance` | Balance display with `formatUnits` / `formatEther`, loading-state variants |
| `Web3.Ui.Input` | Typed inputs: `address`, `bigInt`, `bool`, `text`, `bytes` |
| `Web3.Ui.Sign` | Sign state display, sign button, signature display |

## Quick start

```elm
import Web3.Chain as Chain
import Web3.Ui.Wallet as WalletUi
import Web3.Ui.Transaction as TxUi
import Web3.Ui.Address as AddressUi

view : Model -> Html Msg
view model =
    div []
        [ WalletUi.viewState []
            { onConnect    = ConnectWallet
            , onSwitchChain = SwitchChain
            , onDisconnect = DisconnectWallet
            , knownChains  = [ Chain.pulsechain, Chain.ethereum ]
            }
            model.wallet
        , TxUi.statusBadge [] model.tx
        , TxUi.actionButton []
            { label = "Submit", pendingLabel = "Submitting…", onPress = Submit }
            model.tx
        ]
```

## `Web3.Ui.Wallet`

```elm
connectButton :
    List (Html.Attribute msg)
    -> { onConnect : msg, onDisconnect : msg }
    -> Wallet.State
    -> Html msg
```

Shows "Connect" in disconnected/error/read-only states. Shows "Disconnect" when connected or on the wrong chain. Disabled with "Connecting…" while `Connecting`.

```elm
walletPicker :
    List (Html.Attribute msg)
    -> (String -> msg)         -- called with the RDNS of the chosen wallet
    -> List Wallet.WalletProvider
    -> Html msg
```

Renders a list of EIP-6963 discovered wallets as buttons with icon and name.

```elm
viewState :
    List (Html.Attribute msg)
    -> { onConnect : msg, onSwitchChain : msg, onDisconnect : msg
       , knownChains : List Chain }
    -> Wallet.State
    -> Html msg
```

Covers all six `Wallet.State` variants. Pass `knownChains` so the `WrongChain` branch can display the target network name.

```elm
chainBadge :
    List (Html.Attribute msg)
    -> List Chain
    -> Wallet.State
    -> Html msg
```

Labels: connected chain name · `"Wrong Chain"` · `"Read-only"` · `"—"` (connecting / disconnected / error).

## `Web3.Ui.Transaction`

```elm
statusBadge :
    List (Html.Attribute msg)
    -> Tx.Status
    -> Html msg
```

Renders a `<span>` with `web3-tx-badge` plus one modifier class. Labels: `"Idle"` / `"Awaiting Signature"` / `"Pending"` / `"Confirming (N)"` / `"Confirmed"` / `"Failed"` / `"Rejected"`.

```elm
actionButton :
    List (Html.Attribute msg)
    -> { label : String, pendingLabel : String, onPress : msg }
    -> Tx.Status
    -> Html msg
```

Active in `Idle` and terminal states. Disabled (with `pendingLabel`) while in-flight.

```elm
txHashLink :
    List (Html.Attribute msg)
    -> { explorerUrl : String }
    -> T.TxHash
    -> Html msg

statusHashLink :
    List (Html.Attribute msg)
    -> { explorerUrl : String }
    -> Tx.Status
    -> Maybe (Html msg)

receiptView :
    List (Html.Attribute msg)
    -> { explorerUrl : String }
    -> Tx.Receipt
    -> Html msg
```

`statusHashLink` returns `Nothing` when there is no hash in the current state. `receiptView` shows block number, gas used, and a tx hash link.

## `Web3.Ui.Address`

```elm
view :
    List (Html.Attribute msg)
    -> { explorerUrl : Maybe String }
    -> T.Address
    -> Html msg
```

Renders `"0x1234…abcd"`. Wraps in `<a>` when `explorerUrl` is `Just url`, otherwise a `<span>`.

```elm
short : T.Address -> String
```

Pure function — no Html. Returns `"0x" ++ first4 ++ "…" ++ last4`.

```elm
input :
    List (Html.Attribute msg)
    -> { value : String, onInput : String -> msg, valid : Bool }
    -> Html msg
```

Text input for address entry. Adds `web3-input-address--invalid` when `valid` is `False`.

## `Web3.Ui.Balance`

```elm
view      : List (Html.Attribute msg) -> { decimals : Int, symbol : String } -> BigInt -> Html msg
viewEther : List (Html.Attribute msg) -> { symbol : String } -> BigInt -> Html msg

viewMaybe      : List (Html.Attribute msg) -> { decimals : Int, symbol : String, loading : String } -> Maybe BigInt -> Html msg
viewEtherMaybe : List (Html.Attribute msg) -> { symbol : String, loading : String } -> Maybe BigInt -> Html msg
```

`viewMaybe` / `viewEtherMaybe` render `opts.loading` with class `web3-balance--loading` while `Nothing`, and the formatted balance once it arrives.

## `Web3.Ui.Input`

```elm
address : List (Html.Attribute msg) -> { value : String, onInput : String -> msg, valid : Bool } -> Html msg
bigInt  : List (Html.Attribute msg) -> { value : String, onInput : String -> msg, valid : Bool } -> Html msg
bytes   : List (Html.Attribute msg) -> { value : String, onInput : String -> msg, valid : Bool } -> Html msg
bool    : List (Html.Attribute msg) -> { value : Bool,   onToggle : Bool -> msg } -> Html msg
text    : List (Html.Attribute msg) -> { value : String, onInput : String -> msg } -> Html msg
```

No validation is performed inside the components. Call `T.address`, `BigInt.fromString`, etc. in your `update` and pass the result back as `valid`.

`Web3.Ui.Input.address` delegates to `Web3.Ui.Address.input` — they are the same component.

## `Web3.Ui.Sign`

```elm
stateView :
    List (Html.Attribute msg)
    -> Sign.SignState
    -> Html msg
```

Labels: `"Idle"` / `"Waiting for signature…"` / `"Signed"` / `"Failed: <err>"` / `"Rejected"`.

```elm
signButton :
    List (Html.Attribute msg)
    -> { label : String, onSign : msg }
    -> Sign.SignState
    -> Html msg
```

Disabled while `SignPending`, active otherwise.

```elm
signatureView :
    List (Html.Attribute msg)
    -> Sign.SignState
    -> Html msg
```

Renders the signature in a `<code>` element when in `Signed` state. Returns an empty text node for all other states — safe to always include.

## CSS class reference

| Class | Element |
|---|---|
| `web3-connect-btn` | Connect button |
| `web3-disconnect-btn` | Disconnect button |
| `web3-wallet-picker` | Wallet picker container |
| `web3-wallet-option` | Individual wallet option button |
| `web3-chain-badge` | Chain badge span |
| `web3-wallet-state` | Full wallet state wrapper div |
| `web3-tx-badge` | Transaction status badge |
| `web3-tx-badge--idle` | Idle state |
| `web3-tx-badge--pending` | Pending / in-flight state |
| `web3-tx-badge--confirmed` | Confirmed state |
| `web3-tx-badge--failed` | Failed state |
| `web3-tx-badge--rejected` | Rejected state |
| `web3-action-btn` | Action button |
| `web3-action-btn--pending` | Action button while disabled |
| `web3-tx-link` | Transaction hash link |
| `web3-receipt` | Receipt view root div |
| `web3-receipt--success` | Receipt — EVM status true |
| `web3-receipt--failed` | Receipt — EVM status false |
| `web3-receipt-field` | Receipt field row div |
| `web3-address` | Address display |
| `web3-balance` | Balance display span |
| `web3-balance--loading` | Balance loading state |
| `web3-input-address` | Address text input |
| `web3-input-address--invalid` | Address input — invalid |
| `web3-input-bigint` | BigInt text input |
| `web3-input-bigint--invalid` | BigInt input — invalid |
| `web3-input-bool` | Bool checkbox input |
| `web3-input-text` | Plain text input |
| `web3-input-bytes` | Bytes hex input |
| `web3-input-bytes--invalid` | Bytes input — invalid |
| `web3-sign-state` | Sign state span |
| `web3-sign-btn` | Sign button |
| `web3-signature` | Signature display wrapper div |
| `web3-signature-value` | Signature value code element |

## Included stylesheets

The `styles/` directory contains a few optional CSS files if you want something to start from:

- `vanilla.css` — minimal, unstyled
- `dark.css` — dark theme
- `shadcn.css` — shadcn/ui-inspired
- `brutalist.css` — high contrast, no-frills
- `tailwind.plugin.cjs` — Tailwind plugin that maps the class names above to utility classes

None of these are loaded automatically. Copy or import whichever suits your project.

## Made by

Built and maintained by [Intrepid Development](https://intrepiddev.com.au) — a
Solidity studio in Perth, AU. Pairs with
[`intrepidshape/elm-web3`](https://github.com/IntrepidShape/elm-web3); both
ship together.

If your team is using these in production and wants help wiring up dApp UX,
hardening contracts, or auditing a deployment, reach out at
[Jake@intrepiddev.com.au](mailto:Jake@intrepiddev.com.au).

## License

MIT © Intrepid Development
