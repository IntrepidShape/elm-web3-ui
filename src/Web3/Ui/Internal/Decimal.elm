module Web3.Ui.Internal.Decimal exposing
    ( splitDecimal
    , siSuffix
    , significantFrac
    , trimTrailingZeros
    , leadingZeros
    , isAllZeros
    , maxScaled
    , scaledRatio
    , ratioBps
    , fixedPoint
    , bigFromDecimalString
    , log10
    , log10Units
    , powScaled
    , powerOfTenScaled
    )

{-| Internal string-space decimal helpers -- NOT part of the public API.

Token amounts routinely span 30+ orders of magnitude (a USDC-pair LP unit is
~1e12 smaller than a DAI-pair one because USDC has 6 decimals). A `Float` holds
only ~15-17 significant digits, so round-tripping an amount through `Float` both
corrupts large values and rounds tiny ones to zero -- a real balance vanishing to
"0.00" bit a live app. These helpers keep every formatter in integer/string
space so precision is never lost.

The same rule binds the ratio helpers below. A uint256 is never handed to
`Float` (nor to `String.toInt`, which yields a non-integral `Int` above 2^53 and
then silently corrupts `//`, which truncates to int32). Every ratio divides in
`BigInt` space first and only then narrows to a bounded `Int` on a fixed scale.
The single sanctioned `Float` step -- raising an already-bounded ratio to a
caller-supplied fractional exponent, and its `log10` companion -- lives here,
documented, rather than being re-derived at each chart module.

-}

import Web3.BigInt as BigInt exposing (BigInt)


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



-- RATIOS --------------------------------------------------------------------


{-| Upper bound for every scaled ratio produced here: 2^31 - 1.

Elm's `//` compiles to a JS `| 0`, so an `Int` above 2^31 - 1 wraps the moment
it is divided. Clamping at the boundary keeps every downstream `//`, `modBy`
and `String.fromInt` exact instead of quietly wrong.

-}
maxScaled : Int
maxScaled =
    2147483647


{-| `floor (num * scale / den)` computed entirely in `BigInt` space, then
narrowed to an `Int` clamped to `[0, maxScaled]`.

`scale` picks the resolution: 10000 gives basis points, 1000000 gives
millionths. Returns 0 when `den` is zero or `scale` is not positive, and clamps
a negative result to 0 (these render as "no progress" rather than as garbage
geometry).

The division happens before the narrowing, so a 2^200 numerator is exact:
nothing is ever converted from a uint256 to a machine number.

-}
scaledRatio : Int -> BigInt -> BigInt -> Int
scaledRatio scale num den =
    if scale <= 0 || BigInt.isZero den then
        0

    else
        BigInt.div (BigInt.mul num (BigInt.fromInt scale)) den
            |> Maybe.map clampBigToInt
            |> Maybe.withDefault 0


{-| `scaledRatio 10000` -- the ratio of `num` to `den` in basis points. -}
ratioBps : BigInt -> BigInt -> Int
ratioBps =
    scaledRatio 10000


{-| Narrow a `BigInt` to an `Int`, clamping to `[0, maxScaled]`. Only the
clamped range is ever parsed, so the `String.toInt` here is always exact --
unlike parsing a raw wei value, which returns a non-integral `Int` above 2^53.
-}
clampBigToInt : BigInt -> Int
clampBigToInt q =
    if BigInt.lt q BigInt.zero then
        0

    else if BigInt.gt q (BigInt.fromInt maxScaled) then
        maxScaled

    else
        String.toInt (BigInt.toString q) |> Maybe.withDefault 0


{-| Render a scaled integer as a fixed-point decimal string.

    fixedPoint 2 1234 --> "12.34"

    fixedPoint 2 5 --> "0.05"

    fixedPoint 0 42 --> "42"

-}
fixedPoint : Int -> Int -> String
fixedPoint places n =
    if places <= 0 then
        String.fromInt n

    else
        let
            sign =
                if n < 0 then
                    "-"

                else
                    ""

            padded =
                String.padLeft (places + 1) '0' (String.fromInt (abs n))

            cut =
                String.length padded - places
        in
        sign ++ String.left cut padded ++ "." ++ String.dropLeft cut padded


{-| Parse a plain decimal string into a `BigInt` scaled by `10 ^ places`,
truncating any digits past `places`. Pure string space -- the value never
touches `Float`, so "123456789012345678.9" survives intact.

`bigFromDecimalString 2 "14.75"` is the `BigInt` 1475.

Returns `Nothing` for anything that is not an optionally signed run of digits
with at most one decimal point and at least one digit.

-}
bigFromDecimalString : Int -> String -> Maybe BigInt
bigFromDecimalString places s =
    let
        ( sign, rest ) =
            if String.startsWith "-" s then
                ( "-", String.dropLeft 1 s )

            else if String.startsWith "+" s then
                ( "", String.dropLeft 1 s )

            else
                ( "", s )

        parts =
            case String.split "." rest of
                [ whole ] ->
                    Just ( whole, "" )

                [ whole, frac ] ->
                    Just ( whole, frac )

                _ ->
                    Nothing
    in
    case parts of
        Nothing ->
            Nothing

        Just ( whole, frac ) ->
            if
                String.isEmpty (whole ++ frac)
                    || not (String.all Char.isDigit (whole ++ frac))
                    || places < 0
            then
                Nothing

            else
                BigInt.fromString
                    (sign
                        ++ (if String.isEmpty whole then
                                "0"

                            else
                                whole
                           )
                        ++ String.left places (frac ++ String.repeat places "0")
                    )



-- THE BOUNDED-FLOAT SEAM ----------------------------------------------------


{-| Base-10 logarithm of a positive `BigInt`.

Built from the decimal digit count plus a mantissa in `[1, 10)` taken from the
leading 16 digits, so the exponent stays exact no matter how large the value is
-- there is no arbitrary-size integer handed to the `Float` parser. `Nothing`
for zero or negative input.

Chart geometry only: the result is a `Float` and must never flow back into a
displayed amount.

-}
log10 : BigInt -> Maybe Float
log10 b =
    let
        s =
            BigInt.toString b
    in
    if String.startsWith "-" s || s == "0" then
        Nothing

    else
        let
            digits =
                String.left 16 s

            frac =
                String.dropLeft 1 digits

            mantissaStr =
                if String.isEmpty frac then
                    String.left 1 digits

                else
                    String.left 1 digits ++ "." ++ frac
        in
        String.toFloat mantissaStr
            |> Maybe.map (\m -> logBase 10 m + toFloat (String.length s - 1))


{-| [`log10`](#log10) of the whole-unit number a `10 ^ decimals`-scaled value
represents: `log10Units 18 oneEtherInWei` is 0.
-}
log10Units : Int -> BigInt -> Maybe Float
log10Units decimals b =
    log10 b |> Maybe.map (\l -> l - toFloat decimals)


{-| Raise a scaled ratio to a fractional exponent, staying on the same scale.

    powScaled 1000000 2 500000 --> 250000 -- 0.5 ^ 2 == 0.25

The `Float` here is a ratio already bounded by `scaledRatio`, never a token
amount, which is the only shape of `Float` this library permits. Result clamps
to `[0, maxScaled]`.

-}
powScaled : Int -> Float -> Int -> Int
powScaled scale exponent x =
    if scale <= 0 || x <= 0 then
        0

    else
        clamp 0 maxScaled (round ((toFloat x / toFloat scale) ^ exponent * toFloat scale))


{-| `10 ^ x` on the given scale, clamped to `[0, maxScaled]`. The companion to
[`log10`](#log10): a magnitude computed in log space comes back as a bounded
scaled integer, so the caller stays in integer arithmetic.
-}
powerOfTenScaled : Int -> Float -> Int
powerOfTenScaled scale x =
    if scale <= 0 then
        0

    else
        clamp 0 maxScaled (round (10 ^ x * toFloat scale))
