module Web3.Ui.ChainSelector exposing (view, Config, Entry)

{-| Pick a chain from the set your dapp supports, wired to the
switch-chain flow.

    ChainSelector.view
        { entries =
            [ { chainId = 369, label = "PulseChain" }
            , { chainId = 1, label = "Ethereum" }
            ]
        , current = Wallet.getChainId model.wallet |> Maybe.map T.chainIdToInt
        , onSelect = SwitchChainTo   -- then: web3Cmd (Wallet.encode (Wallet.switchChain …))
        }

Selecting an entry is a *request* — render the truth from `Wallet.State`,
never optimistically: the pill only moves when `SwitchChainOk` /
`ChainChanged` actually arrives. Chains the wallet doesn't know yet are the
`Wallet.addChain` (EIP-3085) flow; fire it from your `onSelect` handler when
the switch errors.

Rendered as a `role="radiogroup"` of buttons — keyboard and screen-reader
native.

CSS classes: `web3-chains`, `web3-chains__option`,
`web3-chains__option--current`.

@docs view, Config, Entry

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events


{-| One selectable chain. -}
type alias Entry =
    { chainId : Int
    , label : String
    }


{-| The supported set, the currently-connected chain id (if any), and the
switch request handler.
-}
type alias Config msg =
    { entries : List Entry
    , current : Maybe Int
    , onSelect : Int -> msg
    }


{-| Render the selector. -}
view : List (Html.Attribute msg) -> Config msg -> Html msg
view attrs cfg =
    Html.div
        (Attr.class "web3-chains"
            :: Attr.attribute "role" "radiogroup"
            :: Attr.attribute "aria-label" "Network"
            :: attrs
        )
        (List.map (option cfg) cfg.entries)


option : Config msg -> Entry -> Html msg
option cfg entry =
    let
        isCurrent =
            cfg.current == Just entry.chainId
    in
    Html.button
        [ Attr.class "web3-chains__option"
        , Attr.classList [ ( "web3-chains__option--current", isCurrent ) ]
        , Attr.attribute "role" "radio"
        , Attr.attribute "aria-checked"
            (if isCurrent then
                "true"

             else
                "false"
            )
        , Events.onClick (cfg.onSelect entry.chainId)
        ]
        [ Html.text entry.label ]
