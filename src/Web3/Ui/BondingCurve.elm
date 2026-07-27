module Web3.Ui.BondingCurve exposing (sparkline)

{-| SVG sparkline of an `A * x^N` bonding-curve price function. Renders the
price-vs-supply curve from supply 0 to a chosen max, with optional markers
for the current spot price and floor price.

    Web3.Ui.BondingCurve.sparkline
        { coeffA = curve.coeffA
        , exponent = 1.1
        , supply = curve.supply
        , maxSupply = maxSupply
        , floorPrice = Just curve.floorPrice
        , decimals = 18
        , width = 320
        , height = 80
        }

The component is generic for any curve of shape `price = A * supply^N`,
which covers `x^1.1`, classic `x^2`, and any sub-/super-linear
issuance model. `coeffA`, `floorPrice` and `supply` are all scaled by
`10 ^ decimals`, which used to be hardcoded to 18 -- on a 6-decimal token the
floor line was drawn 1e12 out of place.

`supply / maxSupply` is divided in `BigInt` space and the curve is plotted from
that bounded ratio, so no uint256 is converted to a `Float`; the floor line is
placed from `Decimal.log10` magnitudes, which stay exact in the exponent
however large the inputs are. The remaining `Float` work is the caller's
fractional `exponent`, which has no integer equivalent. The chart is purely
visual -- do not consume the rendered points for on-chain calculation.

CSS classes: `web3-bondingcurve`, `web3-bondingcurve__path`,
`web3-bondingcurve__spot`, `web3-bondingcurve__floor`. Stroke colors come
from CSS.

@docs sparkline

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Svg
import Svg.Attributes as SAttr
import Web3.BigInt exposing (BigInt)
import Web3.Ui.Internal.Decimal as Decimal


{-| Render the sparkline. -}
sparkline :
    { coeffA : BigInt
    , exponent : Float
    , supply : BigInt
    , maxSupply : BigInt
    , floorPrice : Maybe BigInt
    , decimals : Int
    , width : Int
    , height : Int
    }
    -> Html msg
sparkline opts =
    let
        sampleCount =
            64

        -- Every plotted height is `price(x) / price(maxSupply)`, and both
        -- `coeffA` and the unit scale cancel out of that ratio, leaving
        -- `(x / maxSupply) ^ exponent`. So the curve needs only the bounded
        -- supply ratio, never the raw uint256 amounts.
        priceRatio supplyRatio =
            Decimal.powScaled scale opts.exponent supplyRatio

        toX100 supplyRatio =
            supplyRatio * opts.width * 100 // scale

        toY100 pRatio =
            opts.height * 100 - (clamp 0 scale pRatio * opts.height * 100 // scale)

        samples =
            List.range 0 (sampleCount - 1)
                |> List.map (\i -> i * scale // (sampleCount - 1))

        pathD =
            samples
                |> List.indexedMap
                    (\i supplyRatio ->
                        let
                            cmd =
                                if i == 0 then
                                    "M"

                                else
                                    "L"
                        in
                        cmd ++ px (toX100 supplyRatio) ++ " " ++ px (toY100 (priceRatio supplyRatio))
                    )
                |> String.join " "

        spotRatio =
            Decimal.scaledRatio scale opts.supply opts.maxSupply

        spotX =
            px (toX100 (min scale spotRatio))

        spotY =
            px (toY100 (priceRatio spotRatio))

        floorMarker =
            case opts.floorPrice of
                Nothing ->
                    Svg.text ""

                Just fp ->
                    let
                        fy =
                            px (toY100 (floorRatio opts.decimals opts.exponent opts.coeffA opts.maxSupply fp))
                    in
                    Svg.line
                        [ SAttr.class "web3-bondingcurve__floor"
                        , SAttr.x1 "0"
                        , SAttr.y1 fy
                        , SAttr.x2 (String.fromInt opts.width)
                        , SAttr.y2 fy
                        , SAttr.strokeDasharray "3,3"
                        ]
                        []
    in
    Html.div [ Attr.class "web3-bondingcurve" ]
        [ Svg.svg
            [ SAttr.width (String.fromInt opts.width)
            , SAttr.height (String.fromInt opts.height)
            , SAttr.viewBox
                ("0 0 "
                    ++ String.fromInt opts.width
                    ++ " "
                    ++ String.fromInt opts.height
                )
            ]
            [ Svg.path
                [ SAttr.class "web3-bondingcurve__path"
                , SAttr.d pathD
                , SAttr.fill "none"
                ]
                []
            , floorMarker
            , Svg.circle
                [ SAttr.class "web3-bondingcurve__spot"
                , SAttr.cx spotX
                , SAttr.cy spotY
                , SAttr.r "3"
                ]
                []
            ]
        ]


{-| Fixed-point resolution for every normalised ratio here. -}
scale : Int
scale =
    1000000


{-| Hundredths of a pixel as an SVG coordinate. -}
px : Int -> String
px hundredths =
    Decimal.fixedPoint 2 hundredths


{-| Where the floor price sits on the normalised price axis, in millionths of
the curve's price at `maxSupply`.

`floor / price(maxSupply)` is `(floorPrice / coeffA) / (maxSupply / 10 ^ d) ^ N`.
That mixes a fractional power with values far above 2^53, so it is evaluated in
log space: `Decimal.log10` reads each magnitude off the decimal digit count plus
a bounded mantissa, which never hands an arbitrary-size integer to `Float`.

-}
floorRatio : Int -> Float -> BigInt -> BigInt -> BigInt -> Int
floorRatio decimals exponent coeffA maxSupply floorPrice =
    case ( Decimal.log10 floorPrice, Decimal.log10 coeffA, Decimal.log10Units decimals maxSupply ) of
        ( Just logFloor, Just logCoeff, Just logMaxUnits ) ->
            Decimal.powerOfTenScaled scale
                (logFloor - logCoeff - exponent * logMaxUnits)

        _ ->
            0
