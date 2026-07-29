module Web3.Ui.ChainGate exposing (view, Config)

{-| Render content only when the wallet is on the expected chain.

A common pattern in every dapp: show the actual UI when connected to the right
network, show a prompt to switch otherwise. This wraps that pattern so it does
not have to be repeated in every view.

    Web3.Ui.ChainGate.view []
        { wallet = model.wallet
        , expectedChain = Chain.chainId Chain.pulsechain
        , wrongChain = Html.text "Please switch to PulseChain"
        , content = actualContent
        }

The two branches are named record fields rather than adjacent positional
arguments of the same type: the previous `chainGate state chain wrong content`
form let a caller swap the last two and get a gate that showed the app to the
wrong network and the switch prompt to the right one, with no type error.

The gate renders its own root element (`web3-chaingate`) carrying an
`--ok` / `--wrong-chain` modifier, so the caller's attributes have somewhere
to land and the gate itself is styleable and addressable.

@docs view, Config

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Web3.Types as T
import Web3.Wallet as Wallet


{-| The wallet state to inspect, the chain the content requires, and the two
branches -- `content` when the wallet is `Connected` on `expectedChain`,
`wrongChain` for every other state (disconnected, wrong chain, read-only,
connecting, error).
-}
type alias Config msg =
    { wallet : Wallet.State
    , expectedChain : T.ChainId
    , wrongChain : Html msg
    , content : Html msg
    }


{-| Render whichever branch the wallet state selects.

CSS classes: `web3-chaingate`, `web3-chaingate--ok`,
`web3-chaingate--wrong-chain`.

-}
view : List (Html.Attribute msg) -> Config msg -> Html msg
view attrs cfg =
    let
        onExpectedChain =
            case cfg.wallet of
                Wallet.Connected info ->
                    T.chainIdToInt info.chainId == T.chainIdToInt cfg.expectedChain

                _ ->
                    False

        ( modifier, branch ) =
            if onExpectedChain then
                ( "web3-chaingate--ok", cfg.content )

            else
                ( "web3-chaingate--wrong-chain", cfg.wrongChain )
    in
    Html.div
        (Attr.class "web3-chaingate" :: Attr.class modifier :: attrs)
        [ branch ]
