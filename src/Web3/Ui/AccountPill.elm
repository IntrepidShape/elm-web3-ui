module Web3.Ui.AccountPill exposing (view, Config)

{-| The standard dapp header unit: one pill that is the whole wallet story.

Renders per `Wallet.State`:

  - `Disconnected` / `Error` — a connect button
  - `Connecting` — the connect button, busy
  - `ReadOnly` — a "read-only" chip (no wallet, reads work)
  - `Connected` — identicon · truncated address · chain chip · optional
    balance · disconnect
  - `WrongChain` — the same pill flagged, chain chip shows the mismatch

<!---->

    AccountPill.view
        { onConnect = ConnectClicked
        , onDisconnect = DisconnectClicked
        , chainLabel = Chain.nameOf     -- T.ChainId -> String
        , balance = model.plsBalance    -- Maybe String, pre-formatted
        }
        model.wallet

CSS classes: `web3-pill`, `web3-pill--connect`, `--connecting`,
`--readonly`, `--connected`, `--wrong-chain`; `web3-pill__identicon`,
`web3-pill__address`, `web3-pill__chain`, `web3-pill__balance`,
`web3-pill__disconnect`.

@docs view, Config

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Web3.Types as T
import Web3.Ui.Identicon as Identicon
import Web3.Wallet as Wallet


{-| Handlers plus how to name a chain and what balance to show (already
formatted — pair with `Web3.Ui.Amount`).
-}
type alias Config msg =
    { onConnect : msg
    , onDisconnect : msg
    , chainLabel : T.ChainId -> String
    , balance : Maybe String
    }


{-| Render the pill for any wallet state. -}
view : Config msg -> Wallet.State -> Html msg
view cfg state =
    case state of
        Wallet.Disconnected ->
            connectButton cfg "connect" False "Connect wallet"

        Wallet.Error _ ->
            connectButton cfg "connect" False "Reconnect"

        Wallet.Connecting _ ->
            connectButton cfg "connecting" True "Connecting…"

        Wallet.ReadOnly ->
            Html.div
                [ Attr.class "web3-pill web3-pill--readonly" ]
                [ Html.span [ Attr.class "web3-pill__chain" ] [ Html.text "read-only" ] ]

        Wallet.Connected info ->
            accountPill cfg "connected" info.address (cfg.chainLabel info.chainId)

        Wallet.WrongChain info expected ->
            accountPill cfg
                "wrong-chain"
                info.address
                (cfg.chainLabel info.chainId ++ " → " ++ cfg.chainLabel expected)



-- INTERNAL


connectButton : Config msg -> String -> Bool -> String -> Html msg
connectButton cfg modifier busy label =
    Html.button
        [ Attr.class "web3-pill"
        , Attr.class ("web3-pill--" ++ modifier)
        , Attr.disabled busy
        , Attr.attribute "aria-busy"
            (if busy then
                "true"

             else
                "false"
            )
        , Events.onClick cfg.onConnect
        ]
        [ Html.text label ]


accountPill : Config msg -> String -> T.Address -> String -> Html msg
accountPill cfg modifier addr chainText =
    let
        full =
            T.addressToString addr

        short =
            String.left 6 full ++ "…" ++ String.right 4 full

        balance =
            case cfg.balance of
                Just b ->
                    [ Html.span [ Attr.class "web3-pill__balance" ] [ Html.text b ] ]

                Nothing ->
                    []
    in
    Html.div
        [ Attr.class "web3-pill"
        , Attr.class ("web3-pill--" ++ modifier)
        ]
        (Identicon.view [ Attr.class "web3-pill__identicon" ] { size = 20 } addr
            :: Html.span [ Attr.class "web3-pill__address", Attr.title full ]
                [ Html.text short ]
            :: Html.span [ Attr.class "web3-pill__chain" ] [ Html.text chainText ]
            :: balance
            ++ [ Html.button
                    [ Attr.class "web3-pill__disconnect"
                    , Attr.attribute "aria-label" "Disconnect wallet"
                    , Events.onClick cfg.onDisconnect
                    ]
                    [ Html.text "⏻" ]
               ]
        )
