module Web3.Ui.TrendIndicator exposing
    ( view
    , Trend(..)
    , fromVolumes
    )

{-| Compact Up/Neutral/Down arrow with paired volume pills. Useful for any
trend-aware contract -- trend-detector outputs, lending-rate sentiment,
DAO vote pressure indicators, etc.

    -- From explicit trend:
    Web3.Ui.TrendIndicator.view
        { trend = Web3.Ui.TrendIndicator.Down
        , buyVolume = buyVol
        , sellVolume = sellVol
        , decimals = 18
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
    Web3.Ui.TrendIndicator.view
        { trend = trend
        , buyVolume = buyVol
        , sellVolume = sellVol
        , decimals = 6
        }

`decimals` scales the two volume pills. It used to be hardcoded to 18, so a
USDC-denominated volume rendered 1e12 too small.

Style classes: `web3-trend`, `web3-trend--up`, `web3-trend--neutral`,
`web3-trend--down`, `web3-trend__arrow`, `web3-trend__pill`.

@docs view, Trend, fromVolumes

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Web3.BigInt as BigInt exposing (BigInt)
import Web3.Ui.Amount as Amount
import Web3.Ui.Internal.Decimal as Decimal


{-| -}
type Trend
    = Up
    | Neutral
    | Down


{-| Derive a Trend from buy/sell volumes plus a threshold in basis points. The
side that exceeds the threshold determines the direction; otherwise Neutral.

Each side's share is divided in `BigInt` space and compared as an integer
number of basis points (floored), so volumes far above 2^53 are compared
exactly. Zero total volume is Neutral.

-}
fromVolumes : { buyVolume : BigInt, sellVolume : BigInt, thresholdBps : Int } -> Trend
fromVolumes opts =
    let
        total =
            BigInt.add opts.buyVolume opts.sellVolume

        bpsOf side =
            Decimal.ratioBps side total
    in
    if bpsOf opts.buyVolume > opts.thresholdBps then
        Up

    else if bpsOf opts.sellVolume > opts.thresholdBps then
        Down

    else
        Neutral


{-| Render the indicator. `decimals` scales both volume pills. -}
view : { trend : Trend, buyVolume : BigInt, sellVolume : BigInt, decimals : Int } -> Html msg
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
            [ Html.text (Amount.formatWei opts.decimals opts.buyVolume) ]
        , Html.span [ Attr.class "web3-trend__sep" ] [ Html.text " / " ]
        , Html.span [ Attr.class "web3-trend__pill web3-trend__pill--sell", Attr.title "Sell volume" ]
            [ Html.text (Amount.formatWei opts.decimals opts.sellVolume) ]
        ]
