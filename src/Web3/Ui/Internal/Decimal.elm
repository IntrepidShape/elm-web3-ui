module Web3.Ui.Internal.Decimal exposing
    ( splitDecimal
    , siSuffix
    , significantFrac
    , trimTrailingZeros
    , leadingZeros
    , isAllZeros
    )

{-| Internal string-space decimal helpers -- NOT part of the public API.

Token amounts routinely span 30+ orders of magnitude (a USDC-pair LP unit is
~1e12 smaller than a DAI-pair one because USDC has 6 decimals). A `Float` holds
only ~15-17 significant digits, so round-tripping an amount through `Float` both
corrupts large values and rounds tiny ones to zero -- a real balance vanishing to
"0.00" bit a live app. These helpers keep every formatter in integer/string
space so precision is never lost.

-}


{-| Split a `Web3.Units.formatUnits`-style decimal string into
`( sign, integerPart, fractionPart )`. Sign is `"-"` or `""`. The integer part
carries no leading zeros (except the literal `"0"`); the fraction part is
returned verbatim (no trailing-zero trimming here).
-}
splitDecimal : String -> ( String, String, String )
splitDecimal s =
    let
        ( sign, rest ) =
            if String.startsWith "-" s then
                ( "-", String.dropLeft 1 s )

            else
                ( "", s )
    in
    case String.split "." rest of
        [ whole ] ->
            ( sign, whole, "" )

        [ whole, frac ] ->
            ( sign, whole, frac )

        _ ->
            ( sign, rest, "" )


{-| Number of leading `'0'` characters in a string. -}
leadingZeros : String -> Int
leadingZeros s =
    String.length s - String.length (dropLeadingZeros s)


dropLeadingZeros : String -> String
dropLeadingZeros s =
    if String.startsWith "0" s then
        dropLeadingZeros (String.dropLeft 1 s)

    else
        s


{-| True when the string is empty or consists only of `'0'`. -}
isAllZeros : String -> Bool
isAllZeros =
    String.all ((==) '0')


{-| Drop trailing `'0'` characters. `"1200" -> "12"`, `"0" -> ""`. -}
trimTrailingZeros : String -> String
trimTrailingZeros s =
    if String.endsWith "0" s then
        trimTrailingZeros (String.left (String.length s - 1) s)

    else
        s


{-| The leading zeros of a fraction plus its first two significant digits:
`"0000019..." -> "0000019"`. This is the "sub-0.01 balance stays visible"
fallback -- instead of a flat `"0.00"`, the caller renders `"0." ++ significantFrac`.
Assumes at least one nonzero digit; returns the (all-zero) string otherwise.
-}
significantFrac : String -> String
significantFrac frac =
    String.left (leadingZeros frac + 2) frac


{-| SI divisor exponent and suffix for an integer part of the given digit
length. Returns `( exponent, suffix )` with exponent in `{3, 6, 9, 12}` for
`K` / `M` / `B` / `T`. Anything >= 1e12 stays on `T`.
-}
siSuffix : Int -> ( Int, String )
siSuffix intLen =
    if intLen >= 13 then
        ( 12, "T" )

    else if intLen >= 10 then
        ( 9, "B" )

    else if intLen >= 7 then
        ( 6, "M" )

    else
        ( 3, "K" )
