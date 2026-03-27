module Web3.Ui.PriceDisplay exposing
    ( view
    , format
    )

{-| Token price display with automatic notation selection.

Bonding curve prices span many orders of magnitude. This module picks the most
readable notation automatically so each project does not reimplement the same
range-checking logic.

    Web3.Ui.PriceDisplay.view []
        { decimals = 18, symbol = "PLS" }
        priceWei

    Web3.Ui.PriceDisplay.format 18 priceWei
    --> "0.00042"   (fixed for normal range)
    --> "1.23M"     (SI suffix for large)
    --> "4.56e-10"  (scientific for tiny)

@docs view, format

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Web3.BigInt exposing (BigInt)
import Web3.Units as Units


{-| Display a token price, automatically selecting notation.

Notation rules:

- ≥ 1 000: SI suffix (`1.23M`, `45.6K`)
- 0.001 – 999.99: fixed decimal (`1.23`, `0.456`, `0.00123`)
- < 0.001: scientific (`4.56e-10`)

CSS class: `web3-price`

-}
view :
    List (Html.Attribute msg)
    -> { decimals : Int, symbol : String }
    -> BigInt
    -> Html msg
view attrs opts amount =
    Html.span
        (Attr.class "web3-price" :: attrs)
        [ Html.text (format opts.decimals amount ++ " " ++ opts.symbol) ]


{-| Format a price BigInt as a human-readable string. No symbol appended.

See `view` for notation selection rules.

-}
format : Int -> BigInt -> String
format decimals amount =
    case String.toFloat (Units.formatUnits decimals amount) of
        Nothing ->
            "0"

        Just f ->
            let
                a =
                    abs f
            in
            if a == 0 then
                "0"

            else if a >= 1.0e3 then
                siFormat f

            else if a >= 0.001 then
                fixedFormat f

            else
                sciFormat f


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

    else
        fmt (a / 1.0e3) "K"


fixedFormat : Float -> String
fixedFormat f =
    let
        sign =
            if f < 0 then
                "-"

            else
                ""

        a =
            abs f

        dp =
            if a >= 100 then
                0

            else if a >= 10 then
                1

            else if a >= 1 then
                2

            else if a >= 0.1 then
                3

            else
                4

        factor =
            toFloat (10 ^ dp)

        rounded =
            toFloat (round (a * factor)) / factor
    in
    sign ++ String.fromFloat rounded


sciFormat : Float -> String
sciFormat f =
    let
        sign =
            if f < 0 then
                "-"

            else
                ""

        a =
            abs f

        exp =
            floor (logBase 10 a)

        mantissa =
            a / (10.0 ^ toFloat exp)

        mantissaStr =
            round2 mantissa
    in
    sign ++ mantissaStr ++ "e" ++ String.fromInt exp


round2 : Float -> String
round2 f =
    String.fromFloat (toFloat (round (f * 100)) / 100)
