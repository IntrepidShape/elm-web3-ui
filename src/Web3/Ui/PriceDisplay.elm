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
    --> "0.0042"    (fixed for normal range)
    --> "1.23M"     (SI suffix for large)
    --> "4.56e-10"  (scientific for tiny)

@docs view, format

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Web3.BigInt exposing (BigInt)
import Web3.Ui.Internal.Decimal as Decimal
import Web3.Units as Units


{-| Display a token price, automatically selecting notation.

Notation rules:

- >= 1 000: SI suffix (`1.23M`, `45.6K`)
- 0.001 - 999.99: fixed decimal (`1.23`, `0.456`, `0.00123`)
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
    if Web3.BigInt.isZero amount then
        "0"

    else
        let
            ( sign, intPart, fracPart ) =
                Decimal.splitDecimal (Units.formatUnits decimals amount)

            intLen =
                String.length intPart

            intIsZero =
                String.isEmpty intPart || intPart == "0"
        in
        if intLen > 3 then
            -- ≥ 1000
            siFormat sign intPart

        else if not (intIsZero && String.left 3 (fracPart ++ "000") == "000") then
            -- 0.001 ≤ value < 1000
            fixedFormat sign intPart fracPart

        else
            -- 0 < value < 0.001
            sciFormat sign fracPart


{-| SI-suffix an integer-part string, truncating to 2 decimals. Pure string math. -}
siFormat : String -> String -> String
siFormat sign intPart =
    let
        intLen =
            String.length intPart

        ( exp, suffix ) =
            Decimal.siSuffix intLen

        wholeLen =
            intLen - exp

        wholePart =
            String.left wholeLen intPart

        frac =
            Decimal.trimTrailingZeros (String.slice wholeLen (wholeLen + 2) intPart)
    in
    if String.isEmpty frac then
        sign ++ wholePart ++ suffix

    else
        sign ++ wholePart ++ "." ++ frac ++ suffix


{-| Fixed-decimal notation with magnitude-adaptive precision (more decimals for
smaller magnitudes), trailing zeros trimmed. Pure string math -- no `Float`. -}
fixedFormat : String -> String -> String -> String
fixedFormat sign intPart fracPart =
    let
        intLen =
            String.length intPart

        intIsZero =
            String.isEmpty intPart || intPart == "0"

        dp =
            if intLen >= 3 then
                0

            else if intLen == 2 then
                1

            else if not intIsZero then
                2

            else if String.left 1 fracPart /= "0" then
                3

            else
                4

        intNonEmpty =
            if String.isEmpty intPart then
                "0"

            else
                intPart

        frac =
            Decimal.trimTrailingZeros (String.left dp fracPart)
    in
    if dp == 0 || String.isEmpty frac then
        sign ++ intNonEmpty

    else
        sign ++ intNonEmpty ++ "." ++ frac


{-| Scientific notation for values below 0.001, computed in string space so the
exponent and mantissa are exact for arbitrarily tiny amounts. -}
sciFormat : String -> String -> String
sciFormat sign fracPart =
    let
        zeros =
            Decimal.leadingZeros fracPart

        exp =
            -(zeros + 1)

        sig =
            String.dropLeft zeros fracPart

        d1 =
            String.left 1 sig

        rest =
            Decimal.trimTrailingZeros (String.left 2 (String.dropLeft 1 sig))
    in
    if String.isEmpty rest then
        sign ++ d1 ++ "e" ++ String.fromInt exp

    else
        sign ++ d1 ++ "." ++ rest ++ "e" ++ String.fromInt exp
