module Web3.Ui.VeBalanceChart exposing (view)

{-| SVG line chart of vote-escrow balance decaying linearly from `nowSec` to
`unlockTime`. Educational primitive -- shows the user how their vote weight
will fade as the lock matures.

Linear-decay model (Curve / Aerodrome standard):

    veBalance(t) = amount * max(0, unlockTime - t) / maxLockSec

At `t = nowSec` the line starts at the current ve-balance; at
`t = unlockTime` it hits zero and stays there. The chart samples
`sampleCount` points across that span and connects them with a polyline.

The `amount` cancels out of the normalised curve -- every plotted height is
`remaining(t) / remaining(nowSec)`, a ratio of two second counts -- so the
geometry is computed entirely in integer space and the uint256 `amount` is
never converted to a `Float`. It is only tested for zero (a zero balance draws
a flat line on the axis). Coordinates are emitted in hundredths of a pixel.

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
import Web3.BigInt exposing (BigInt)
import Web3.Ui.Internal.Decimal as Decimal


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

        spanSec =
            max 1 (opts.unlockTime - opts.nowSec)

        remainingAt t =
            max 0 (opts.unlockTime - t)

        peakRemaining =
            remainingAt opts.nowSec

        -- Height of the curve at `t` as a fraction of the current balance, in
        -- millionths. `amount` and `maxLockSec` are common factors of both
        -- sides of the ratio and cancel exactly, so this is the whole curve.
        heightMillionths t =
            if peakRemaining <= 0 || Web3.BigInt.isZero opts.amount then
                0

            else
                remainingAt t * scale // peakRemaining

        -- Hundredths of a pixel: SVG takes decimals, integers keep them exact.
        toX100 t =
            (t - opts.nowSec) * opts.width * 100 // spanSec

        toY100 h =
            opts.height * 100 - (h * opts.height * 100 // scale)

        samples =
            List.range 0 (sampleCount - 1)
                |> List.map
                    (\i ->
                        let
                            t =
                                opts.nowSec
                                    + (spanSec * i // (sampleCount - 1))
                        in
                        ( t, heightMillionths t )
                    )

        pathD =
            samples
                |> List.indexedMap
                    (\i ( t, h ) ->
                        let
                            cmd =
                                if i == 0 then
                                    "M"

                                else
                                    "L"
                        in
                        cmd
                            ++ px (toX100 t)
                            ++ " "
                            ++ px (toY100 h)
                    )
                |> String.join " "

        currentX =
            px (toX100 opts.nowSec)

        currentY =
            px (toY100 (heightMillionths opts.nowSec))
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
                , SAttr.cx currentX
                , SAttr.cy currentY
                , SAttr.r "3"
                ]
                []
            ]
        ]


{-| Fixed-point resolution for the normalised curve height. -}
scale : Int
scale =
    1000000


{-| Hundredths of a pixel as an SVG coordinate. -}
px : Int -> String
px hundredths =
    Decimal.fixedPoint 2 hundredths
