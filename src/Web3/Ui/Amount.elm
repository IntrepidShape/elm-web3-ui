module Web3.Ui.Amount exposing
    ( amountInput
    , formatWei
    )

{-| Token amount input and display with SI suffix formatting.

    -- Amount input with inline symbol label:
    Web3.Ui.Amount.amountInput []
        { value = model.amountStr
        , onInput = AmountChanged
        , decimals = 18
        , symbol = "PLS"
        , valid = True
        }

    -- Format a Wei value as human-readable (caller appends symbol):
    Web3.Ui.Amount.formatWei 18 weiAmount ++ " PLS"
    --> "1.23M PLS"

@docs amountInput, formatWei

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Web3.BigInt exposing (BigInt)
import Web3.Units as Units


{-| Numeric text input for a token amount. `value` is a plain decimal string
(e.g. `"1000.5"`). No parsing is done here — call `Web3.Units.parseUnits` in
your `update` to convert to Wei.

Adds `web3-amount-input--invalid` when `valid` is `False`.

CSS classes: `web3-amount-wrapper` (outer div), `web3-amount-input` (input),
`web3-amount-symbol` (symbol label)

-}
amountInput :
    List (Html.Attribute msg)
    -> { value : String, onInput : String -> msg, decimals : Int, symbol : String, valid : Bool }
    -> Html msg
amountInput attrs opts =
    let
        invalidClass =
            if opts.valid then
                []

            else
                [ Attr.class "web3-amount-input--invalid" ]
    in
    Html.div
        (Attr.class "web3-amount-wrapper" :: attrs)
        [ Html.input
            ([ Attr.class "web3-amount-input"
             , Attr.type_ "text"
             , Attr.attribute "inputmode" "decimal"
             , Attr.value opts.value
             , Events.onInput opts.onInput
             ]
                ++ invalidClass
            )
            []
        , Html.span
            [ Attr.class "web3-amount-symbol" ]
            [ Html.text opts.symbol ]
        ]


{-| Format a Wei BigInt as a human-readable string with SI suffix.

The symbol is not appended — concatenate it yourself so the caller controls
spacing and placement.

    formatWei 18 onePls   --> "1"
    formatWei 18 largePls --> "1.23M"
    formatWei 6  oneUsdc  --> "1"

SI suffixes: K (10³), M (10⁶), B (10⁹), T (10¹²).
Values below 1000 are shown with up to 2 decimal places, trailing zeros trimmed.

-}
formatWei : Int -> BigInt -> String
formatWei decimals amount =
    case String.toFloat (Units.formatUnits decimals amount) of
        Nothing ->
            Units.formatUnits decimals amount

        Just f ->
            siFormat f


siFormat : Float -> String
siFormat f =
    let
        a =
            abs f

        sign =
            if f < 0 then
                "-"

            else
                ""

        fmt n suffix =
            sign ++ round2 n ++ suffix
    in
    if a >= 1.0e12 then
        fmt (a / 1.0e12) "T"

    else if a >= 1.0e9 then
        fmt (a / 1.0e9) "B"

    else if a >= 1.0e6 then
        fmt (a / 1.0e6) "M"

    else if a >= 1.0e3 then
        fmt (a / 1.0e3) "K"

    else
        sign ++ round2 a


{-| Round to 2 decimal places, trimming trailing zeros. -}
round2 : Float -> String
round2 f =
    String.fromFloat (toFloat (round (f * 100)) / 100)
