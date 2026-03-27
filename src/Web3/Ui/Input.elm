module Web3.Ui.Input exposing
    ( address
    , bigInt
    , bool
    , text
    , bytes
    )

{-| Typed input primitives for EVM data entry.

Thin wrappers around `Html.input` with semantic class names and appropriate
`type` / `inputmode` attributes. No validation — the host app calls
`T.address`, `BigInt.fromString`, etc. on the string value.

The `address`, `bigInt`, and `bytes` inputs accept a `valid : Bool` field.
Pass `False` to add the `--invalid` modifier class (e.g. after a failed parse).

    Web3.Ui.Input.address []
        { value = model.toAddress, onInput = ToAddressChanged, valid = True }

    Web3.Ui.Input.bigInt []
        { value = model.amount, onInput = AmountChanged, valid = True }

    Web3.Ui.Input.bool []
        { value = model.approve, onToggle = ApproveToggled }

@docs address, bigInt, bool, text, bytes

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events


{-| Text input for Ethereum address entry (`0x…`).

Adds `web3-input-address--invalid` when `valid` is `False`.

CSS class: `web3-input-address`

-}
address :
    List (Html.Attribute msg)
    -> { value : String, onInput : String -> msg, valid : Bool }
    -> Html msg
address attrs opts =
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


{-| Text input for a BigInt / uint256 value.

Uses `inputmode="numeric"` to show the numeric keyboard on mobile.
Adds `web3-input-bigint--invalid` when `valid` is `False`.

CSS class: `web3-input-bigint`

-}
bigInt :
    List (Html.Attribute msg)
    -> { value : String, onInput : String -> msg, valid : Bool }
    -> Html msg
bigInt attrs opts =
    let
        invalidClass =
            if opts.valid then
                []

            else
                [ Attr.class "web3-input-bigint--invalid" ]
    in
    Html.input
        ([ Attr.class "web3-input-bigint"
         , Attr.type_ "text"
         , Attr.attribute "inputmode" "numeric"
         , Attr.value opts.value
         , Events.onInput opts.onInput
         ]
            ++ invalidClass
            ++ attrs
        )
        []


{-| Checkbox input for a boolean value.

CSS class: `web3-input-bool`

-}
bool :
    List (Html.Attribute msg)
    -> { value : Bool, onToggle : Bool -> msg }
    -> Html msg
bool attrs opts =
    Html.input
        ([ Attr.class "web3-input-bool"
         , Attr.type_ "checkbox"
         , Attr.checked opts.value
         , Events.onCheck opts.onToggle
         ]
            ++ attrs
        )
        []


{-| Plain text input.

CSS class: `web3-input-text`

-}
text :
    List (Html.Attribute msg)
    -> { value : String, onInput : String -> msg }
    -> Html msg
text attrs opts =
    Html.input
        ([ Attr.class "web3-input-text"
         , Attr.type_ "text"
         , Attr.value opts.value
         , Events.onInput opts.onInput
         ]
            ++ attrs
        )
        []


{-| Text input for hex bytes (`0x…`).

Adds `web3-input-bytes--invalid` when `valid` is `False`.

CSS class: `web3-input-bytes`

-}
bytes :
    List (Html.Attribute msg)
    -> { value : String, onInput : String -> msg, valid : Bool }
    -> Html msg
bytes attrs opts =
    let
        invalidClass =
            if opts.valid then
                []

            else
                [ Attr.class "web3-input-bytes--invalid" ]
    in
    Html.input
        ([ Attr.class "web3-input-bytes"
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
