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
        , width = 320
        , height = 80
        }

The component is generic for any curve of shape `price = A * supply^N`,
which covers `x^1.1`, classic `x^2`, and any sub-/super-linear
issuance model. Math runs on `Float` because the chart is purely visual --
do not consume the rendered points for on-chain calculation.

CSS classes: `web3-bondingcurve`, `web3-bondingcurve__path`,
`web3-bondingcurve__spot`, `web3-bondingcurve__floor`. Stroke colors come
from CSS.

@docs sparkline

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Svg
import Svg.Attributes as SAttr
import Web3.BigInt as BigInt exposing (BigInt)


{-| Render the sparkline. -}
sparkline :
    { coeffA : BigInt
    , exponent : Float
    , supply : BigInt
    , maxSupply : BigInt
    , floorPrice : Maybe BigInt
    , width : Int
    , height : Int
    }
    -> Html msg
sparkline opts =
    let
        sampleCount =
            64

        maxSupplyF =
            bigToFloat opts.maxSupply

        coeffAF =
            bigToFloat opts.coeffA / 1.0e18

        priceAt s =
            coeffAF * (s / 1.0e18) ^ opts.exponent

        samples =
            List.range 0 (sampleCount - 1)
                |> List.map
                    (\i ->
                        let
                            x =
                                toFloat i / toFloat (sampleCount - 1) * maxSupplyF
                        in
                        ( x, priceAt x )
                    )

        maxPrice =
            samples
                |> List.map Tuple.second
                |> List.maximum
                |> Maybe.withDefault 1

        toX x =
            x / maxSupplyF * toFloat opts.width

        toY p =
            toFloat opts.height - (p / maxPrice * toFloat opts.height)

        pathD =
            samples
                |> List.indexedMap
                    (\i ( x, p ) ->
                        let
                            cmd =
                                if i == 0 then
                                    "M"

                                else
                                    "L"
                        in
                        cmd ++ String.fromFloat (toX x) ++ " " ++ String.fromFloat (toY p)
                    )
                |> String.join " "

        spotX =
            toX (bigToFloat opts.supply)

        spotY =
            toY (priceAt (bigToFloat opts.supply))

        floorMarker =
            case opts.floorPrice of
                Nothing ->
                    Svg.text ""

                Just fp ->
                    let
                        fy =
                            toY (bigToFloat fp / 1.0e18)
                    in
                    Svg.line
                        [ SAttr.class "web3-bondingcurve__floor"
                        , SAttr.x1 "0"
                        , SAttr.y1 (String.fromFloat fy)
                        , SAttr.x2 (String.fromInt opts.width)
                        , SAttr.y2 (String.fromFloat fy)
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
                , SAttr.cx (String.fromFloat spotX)
                , SAttr.cy (String.fromFloat spotY)
                , SAttr.r "3"
                ]
                []
            ]
        ]


bigToFloat : BigInt -> Float
bigToFloat bi =
    String.toFloat (BigInt.toString bi) |> Maybe.withDefault 0
