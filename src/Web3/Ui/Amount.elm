module Web3.Ui.Amount exposing
    ( amountInput
    , formatWei
    , presetRow
    , formatWeiDust
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

@docs amountInput, formatWei, presetRow, formatWeiDust

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Web3.BigInt exposing (BigInt)
import Web3.BigInt
import Web3.Ui.Internal.Decimal as Decimal
import Web3.Units as Units


{-| Numeric text input for a token amount. `value` is a plain decimal string
(e.g. `"1000.5"`). No parsing is done here -- call `Web3.Units.parseUnits` in
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

The symbol is not appended -- concatenate it yourself so the caller controls
spacing and placement.

    formatWei 18 onePls   --> "1"
    formatWei 18 largePls --> "1.23M"
    formatWei 6  oneUsdc  --> "1"

SI suffixes: K (10^3), M (10^6), B (10^9), T (10^12).
Values below 1000 are shown with up to 2 decimal places, trailing zeros trimmed.
A nonzero value under 0.01 (which a flat 2dp would render as `"0.00"`) instead
shows its first two significant fractional digits (e.g. `"0.0000019"`) so real
sub-cent balances never vanish.

All formatting stays in integer/string space -- the amount is never routed
through `Float`, so neither very small nor very large values lose precision.

-}
formatWei : Int -> BigInt -> String
formatWei decimals amount =
    formatDecimalString (Units.formatUnits decimals amount)


{-| Format a lossless `formatUnits` decimal string: SI suffix at/above 1000, and
a significant-figures fallback below 0.01 so tiny balances stay visible. -}
formatDecimalString : String -> String
formatDecimalString s =
    let
        ( sign, intPart, fracPart ) =
            Decimal.splitDecimal s

        intLen =
            String.length intPart
    in
    if intLen > 3 then
        siFormat sign intPart

    else
        let
            twoDp =
                Decimal.trimTrailingZeros (String.left 2 (fracPart ++ "00"))

            intNonEmpty =
                if String.isEmpty intPart then
                    "0"

                else
                    intPart
        in
        if intNonEmpty == "0" && twoDp == "" && not (Decimal.isAllZeros fracPart) then
            -- Nonzero but under 0.01: a flat 2dp renders a real balance as
            -- "0.00" (bit us live — USDC-pair LP units are ~1e12 smaller than
            -- DAI-pair's). Show leading zeros + first 2 significant digits.
            sign ++ "0." ++ Decimal.significantFrac fracPart

        else if String.isEmpty twoDp then
            sign ++ intNonEmpty

        else
            sign ++ intNonEmpty ++ "." ++ twoDp


{-| SI-suffix an integer-part string (no sign, no leading zeros), truncating the
scaled value to 2 decimal places with trailing zeros trimmed. Pure string math. -}
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


{-| A row of balance-percentage chips -- 25% / 50% / 75% / MAX -- the
companion every [`amountInput`](#amountInput) deserves. Emits the chosen
percentage (100 = MAX); the app computes the actual amount from the live
balance, so the chips never display a stale number.

    Web3.Ui.Amount.presetRow [] { onPick = FillPercent }

    -- FillPercent 100 -> set input to formatUnits decimals balance

CSS classes: `web3-amount-presets`, `web3-amount-presets__chip`,
`web3-amount-presets__chip--max`.

-}
presetRow : List (Html.Attribute msg) -> { onPick : Int -> msg } -> Html msg
presetRow attrs opts =
    Html.div
        (Attr.class "web3-amount-presets" :: attrs)
        (List.map
            (\pct ->
                Html.button
                    [ Attr.class "web3-amount-presets__chip"
                    , Attr.classList [ ( "web3-amount-presets__chip--max", pct == 100 ) ]
                    , Events.onClick (opts.onPick pct)
                    ]
                    [ Html.text
                        (if pct == 100 then
                            "MAX"

                         else
                            String.fromInt pct ++ "%"
                        )
                    ]
            )
            [ 25, 50, 75, 100 ]
        )


{-| Like [`formatWei`](#formatWei), with the dust convention: a nonzero
amount that would display as zero (below 0.0001 of the unit) renders as
`"<0.0001"` instead -- "0" must mean zero, never "too small to show".
-}
formatWeiDust : Int -> BigInt -> String
formatWeiDust decimals amount =
    if Web3.BigInt.isZero amount then
        "0"

    else
        let
            ( _, intPart, fracPart ) =
                Decimal.splitDecimal (Units.formatUnits decimals amount)

            intIsZero =
                String.isEmpty intPart || intPart == "0"
        in
        -- "below 0.0001" in pure string space: integer part zero and the first
        -- four fractional digits all zero (0.00009999 < 0.0001 ≤ 0.0001).
        if intIsZero && String.left 4 (fracPart ++ "0000") == "0000" then
            "<0.0001"

        else
            formatWei decimals amount
