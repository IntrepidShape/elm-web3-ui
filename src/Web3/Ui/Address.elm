module Web3.Ui.Address exposing
    ( view
    , short
    , input
    )

{-| Address display and input components.

    -- Display with optional explorer link:
    Web3.Ui.Address.view []
        { explorerUrl = Just "https://etherscan.io/address/" }
        addr

    -- Truncated address string (pure, no Html):
    Web3.Ui.Address.short addr  --> "0x1234…abcd"

    -- Address text input:
    Web3.Ui.Address.input []
        { value = model.addressInput
        , onInput = AddressInputChanged
        , valid = True
        }

@docs view, short, input

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Web3.Types as T


{-| Display an address as "0x1234…abcd". Optionally wraps in an `<a>` tag
when `explorerUrl` is `Just url`.

CSS class: `web3-address`

-}
view :
    List (Html.Attribute msg)
    -> { explorerUrl : Maybe String }
    -> T.Address
    -> Html msg
view attrs opts addr =
    let
        label =
            short addr
    in
    case opts.explorerUrl of
        Just url ->
            Html.a
                (Attr.class "web3-address"
                    :: Attr.href (url ++ T.addressToString addr)
                    :: Attr.target "_blank"
                    :: Attr.rel "noopener noreferrer"
                    :: attrs
                )
                [ Html.text label ]

        Nothing ->
            Html.span
                (Attr.class "web3-address" :: attrs)
                [ Html.text label ]


{-| Truncate an address to "0x" + first 4 hex chars + "…" + last 4 hex chars.

    short addr  --> "0x1234…abcd"

-}
short : T.Address -> String
short addr =
    let
        s =
            T.addressToString addr
    in
    String.left 6 s ++ "…" ++ String.right 4 s


{-| A text input for address entry. Adds `web3-input-address--invalid` class
when `valid` is `False`.

The host app is responsible for validating with `T.address`.

CSS class: `web3-input-address` (plus `web3-input-address--invalid` when invalid)

-}
input :
    List (Html.Attribute msg)
    -> { value : String, onInput : String -> msg, valid : Bool }
    -> Html msg
input attrs opts =
    let
        invalidClass =
            if opts.valid then
                []

            else
                [ Attr.class "web3-input-address--invalid" ]
    in
    Html.input
        ([ Attr.class "web3-input-address"
         , Attr.type_ "text"
         , Attr.attribute "inputmode" "text"
         , Attr.placeholder "0x…"
         , Attr.value opts.value
         , Events.onInput opts.onInput
         ]
            ++ invalidClass
            ++ attrs
        )
        []
