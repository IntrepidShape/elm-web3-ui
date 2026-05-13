module Web3.Ui.TrendIndicator exposing
    ( view
    , Trend(..)
    , fromVolumes
    )

{-| Compact Up/Neutral/Down arrow with paired volume pills. Useful for any
trend-aware contract — trend-detector outputs, lending-rate sentiment,
DAO vote pressure indicators, etc.

    -- From explicit trend:
    Web3.Ui.TrendIndicator.view
        { trend = Web3.Ui.TrendIndicator.Down
        , buyVolume = buyVol
        , sellVolume = sellVol
        }

    -- Or derive trend from volumes given a threshold (in basis points,
    -- e.g., 5800 = 58% one side):
    let
        trend =
            Web3.Ui.TrendIndicator.fromVolumes
                { buyVolume = buyVol
                , sellVolume = sellVol
                , thresholdBps = 5800
                }
    in
    Web3.Ui.TrendIndicator.view { trend = trend, buyVolume = buyVol, sellVolume = sellVol }

Style classes: `web3-trend`, `web3-trend--up`, `web3-trend--neutral`,
`web3-trend--down`, `web3-trend__arrow`, `web3-trend__pill`.

@docs view, Trend, fromVolumes

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Web3.BigInt as BigInt exposing (BigInt)
import Web3.Ui.Amount as Amount


{-| -}
type Trend
    = Up
    | Neutral
    | Down


{-| Derive a Trend from buy/sell volumes plus a threshold in basis points. The
side that exceeds the threshold determines the direction; otherwise Neutral.
-}
fromVolumes : { buyVolume : BigInt, sellVolume : BigInt, thresholdBps : Int } -> Trend
fromVolumes opts =
    let
        total =
            BigInt.add opts.buyVolume opts.sellVolume

        bpsOf side =
            if BigInt.isZero total then
                0

            else
                case ( String.toFloat (BigInt.toString side), String.toFloat (BigInt.toString total) ) of
                    ( Just s, Just t ) ->
                        if t == 0 then
                            0

                        else
                            10000 * s / t

                    _ ->
                        0

        threshold =
            toFloat opts.thresholdBps
    in
    if bpsOf opts.buyVolume > threshold then
        Up

    else if bpsOf opts.sellVolume > threshold then
        Down

    else
        Neutral


{-| Render the indicator. -}
view : { trend : Trend, buyVolume : BigInt, sellVolume : BigInt } -> Html msg
view opts =
    let
        ( arrow, modifier ) =
            case opts.trend of
                Up ->
                    ( "↑", "up" )

                Neutral ->
                    ( "→", "neutral" )

                Down ->
                    ( "↓", "down" )
    in
    Html.div
        [ Attr.class ("web3-trend web3-trend--" ++ modifier) ]
        [ Html.span [ Attr.class "web3-trend__arrow", Attr.attribute "aria-hidden" "true" ]
            [ Html.text arrow ]
        , Html.span [ Attr.class "web3-trend__pill web3-trend__pill--buy", Attr.title "Buy volume" ]
            [ Html.text (Amount.formatWei 18 opts.buyVolume) ]
        , Html.span [ Attr.class "web3-trend__sep" ] [ Html.text " / " ]
        , Html.span [ Attr.class "web3-trend__pill web3-trend__pill--sell", Attr.title "Sell volume" ]
            [ Html.text (Amount.formatWei 18 opts.sellVolume) ]
        ]
