module Web3.Ui.VeBalanceChart exposing (view)

{-| SVG line chart of vote-escrow balance decaying linearly from `nowSec` to
`unlockTime`. Educational primitive -- shows the user how their vote weight
will fade as the lock matures.

Linear-decay model (Curve / Aerodrome standard):

    veBalance(t) = amount * max(0, unlockTime - t) / maxLockSec

At `t = nowSec` the line starts at the current ve-balance; at
`t = unlockTime` it hits zero and stays there. The chart samples
`sampleCount` points across that span and connects them with a polyline.
Math runs on `Float` because the chart is purely visual -- do not consume
rendered points for on-chain calculation.

    Web3.Ui.VeBalanceChart.view
        { amount = lock.amount
        , unlockTime = lock.unlockTime
        , maxLockSec = fourYears
        , nowSec = model.nowSec
        , width = 320
        , height = 80
        }

CSS classes: `web3-vebalancechart`, `web3-vebalancechart__path`,
`web3-vebalancechart__current`, `web3-vebalancechart__axis`. Stroke and
fill colors come from the consumer stylesheet.

@docs view

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Svg
import Svg.Attributes as SAttr
import Web3.BigInt as BigInt exposing (BigInt)


{-| Render the decay chart. -}
view :
    { amount : BigInt
    , unlockTime : Int
    , maxLockSec : Int
    , nowSec : Int
    , width : Int
    , height : Int
    }
    -> Html msg
view opts =
    let
        sampleCount =
            48

        amountF =
            bigToFloat opts.amount

        maxLockF =
            toFloat (max 1 opts.maxLockSec)

        veAt t =
            let
                remaining =
                    toFloat (max 0 (opts.unlockTime - t))
            in
            amountF * remaining / maxLockF

        spanSec =
            max 1 (opts.unlockTime - opts.nowSec)

        currentVe =
            veAt opts.nowSec

        peakVe =
            max currentVe 1

        toX t =
            toFloat (t - opts.nowSec) / toFloat spanSec * toFloat opts.width

        toY v =
            toFloat opts.height - (v / peakVe * toFloat opts.height)

        samples =
            List.range 0 (sampleCount - 1)
                |> List.map
                    (\i ->
                        let
                            t =
                                opts.nowSec
                                    + (spanSec * i // (sampleCount - 1))
                        in
                        ( t, veAt t )
                    )

        pathD =
            samples
                |> List.indexedMap
                    (\i ( t, v ) ->
                        let
                            cmd =
                                if i == 0 then
                                    "M"

                                else
                                    "L"
                        in
                        cmd
                            ++ String.fromFloat (toX t)
                            ++ " "
                            ++ String.fromFloat (toY v)
                    )
                |> String.join " "

        currentX =
            toX opts.nowSec

        currentY =
            toY currentVe
    in
    Html.div [ Attr.class "web3-vebalancechart" ]
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
            [ Svg.line
                [ SAttr.class "web3-vebalancechart__axis"
                , SAttr.x1 "0"
                , SAttr.y1 (String.fromInt opts.height)
                , SAttr.x2 (String.fromInt opts.width)
                , SAttr.y2 (String.fromInt opts.height)
                ]
                []
            , Svg.path
                [ SAttr.class "web3-vebalancechart__path"
                , SAttr.d pathD
                , SAttr.fill "none"
                ]
                []
            , Svg.circle
                [ SAttr.class "web3-vebalancechart__current"
                , SAttr.cx (String.fromFloat currentX)
                , SAttr.cy (String.fromFloat currentY)
                , SAttr.r "3"
                ]
                []
            ]
        ]


bigToFloat : BigInt -> Float
bigToFloat bi =
    String.toFloat (BigInt.toString bi) |> Maybe.withDefault 0
