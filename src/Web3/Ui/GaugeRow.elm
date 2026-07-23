module Web3.Ui.GaugeRow exposing
    ( view
    , Config
    )

{-| One row of a vote-escrow gauge list: gauge label, current epoch, total
votes on the gauge, total bribes pooled for voters, your vote share, and
optional vote / bribe / claim actions. Generic for any Curve-style gauge
voting design (Curve, Aerodrome, Velodrome, bribe markets generally).

The available actions depend on epoch state:

  - `epoch == currentEpoch`: vote and bribe both make sense; claim does not.
  - `epoch < currentEpoch`: epoch is closed; voters can claim, bribers can
    forfeit, no new votes/bribes possible.

The component does not enforce these -- caller passes `Nothing` for actions
that should be hidden in the current state.

```elm
Web3.Ui.GaugeRow.view
    { gaugeLabel = gauge.label
    , epoch = gauge.epoch
    , currentEpoch = market.currentEpoch
    , totalVotes = gauge.totalVotes
    , totalBribes = gauge.totalBribes
    , bribeSymbol = "PLS"
    , bribeDecimals = 18
    , veSymbol = "veToken"
    , veDecimals = 18
    , yourVote = gauge.yourVote
    , aprBps = Just gauge.aprBps
    , onVote = Just (Vote gauge.id)
    , onBribe = Just (Bribe gauge.id)
    , onClaim = Nothing
    }
```

CSS classes: `web3-gaugerow`, `web3-gaugerow__label`, `web3-gaugerow__epoch`,
`web3-gaugerow__votes`, `web3-gaugerow__bribes`, `web3-gaugerow__share`,
`web3-gaugerow__apr`, `web3-gaugerow__actions`, `web3-gaugerow__action`.
Epoch gets a `--closed` modifier when `epoch < currentEpoch`.

@docs view, Config

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Web3.BigInt as BigInt exposing (BigInt)
import Web3.Ui.Amount as Amount


{-| -}
type alias Config msg =
    { gaugeLabel : String
    , epoch : Int
    , currentEpoch : Int
    , totalVotes : BigInt
    , totalBribes : BigInt
    , bribeSymbol : String
    , bribeDecimals : Int
    , veSymbol : String
    , veDecimals : Int
    , yourVote : BigInt
    , aprBps : Maybe Int
    , onVote : Maybe msg
    , onBribe : Maybe msg
    , onClaim : Maybe msg
    }


{-| Render the row. -}
view : Config msg -> Html msg
view cfg =
    let
        closed =
            cfg.epoch < cfg.currentEpoch

        epochClass =
            if closed then
                "web3-gaugerow__epoch web3-gaugerow__epoch--closed"

            else
                "web3-gaugerow__epoch"

        sharePct =
            if BigInt.isZero cfg.totalVotes then
                "0%"

            else
                case BigInt.fromInt 10000 of
                    bps ->
                        case BigInt.div (BigInt.mul cfg.yourVote bps) cfg.totalVotes of
                            Just shareBps ->
                                bpsToPct (bigToInt shareBps)

                            Nothing ->
                                "0%"

        aprText =
            case cfg.aprBps of
                Nothing ->
                    "—"

                Just b ->
                    bpsToPct b ++ " APR"

        actionButton label maybeMsg =
            case maybeMsg of
                Nothing ->
                    Html.text ""

                Just msg ->
                    Html.button
                        [ Attr.class "web3-gaugerow__action"
                        , Attr.type_ "button"
                        , Events.onClick msg
                        ]
                        [ Html.text label ]
    in
    Html.div [ Attr.class "web3-gaugerow" ]
        [ Html.div [ Attr.class "web3-gaugerow__label" ]
            [ Html.text cfg.gaugeLabel ]
        , Html.div [ Attr.class epochClass ]
            [ Html.text ("epoch " ++ String.fromInt cfg.epoch) ]
        , Html.div [ Attr.class "web3-gaugerow__votes" ]
            [ Html.text (Amount.formatWei cfg.veDecimals cfg.totalVotes)
            , Html.text " "
            , Html.text cfg.veSymbol
            ]
        , Html.div [ Attr.class "web3-gaugerow__bribes" ]
            [ Html.text (Amount.formatWei cfg.bribeDecimals cfg.totalBribes)
            , Html.text " "
            , Html.text cfg.bribeSymbol
            ]
        , Html.div [ Attr.class "web3-gaugerow__share" ]
            [ Html.text "your share "
            , Html.text sharePct
            ]
        , Html.div [ Attr.class "web3-gaugerow__apr" ]
            [ Html.text aprText ]
        , Html.div [ Attr.class "web3-gaugerow__actions" ]
            [ actionButton "Vote" cfg.onVote
            , actionButton "Bribe" cfg.onBribe
            , actionButton "Claim" cfg.onClaim
            ]
        ]


bigToInt : BigInt -> Int
bigToInt b =
    String.toInt (BigInt.toString b) |> Maybe.withDefault 0


bpsToPct : Int -> String
bpsToPct bps =
    let
        whole =
            bps // 100

        rem =
            modBy 100 bps
    in
    if rem == 0 then
        String.fromInt whole ++ "%"

    else
        String.fromInt whole
            ++ "."
            ++ (if rem < 10 then
                    "0"

                else
                    ""
               )
            ++ String.fromInt rem
            ++ "%"
