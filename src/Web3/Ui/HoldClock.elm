module Web3.Ui.HoldClock exposing
    ( view
    , Config
    )

{-| Visual countdown of a graduated-fee tier. Common pattern: an early-exit fee
that decays linearly from a base rate to a floor over N days. Shows current
fee % and a progress ring/line until the floor is reached.

    Web3.Ui.HoldClock.view
        { holdSeconds = nowSec - weightedBuyTime
        , decayDays = 40
        , baseFeeBps = 500   -- 5%
        , minFeeBps  = 100   -- 1%
        }

Style classes: `web3-holdclock`, `web3-holdclock__current`, `web3-holdclock__bar`,
`web3-holdclock__fill`, `web3-holdclock__remaining`.

@docs view, Config

-}

import Html exposing (Html)
import Html.Attributes as Attr


{-| -}
type alias Config =
    { holdSeconds : Int
    , decayDays : Int
    , baseFeeBps : Int
    , minFeeBps : Int
    }


{-| Render the hold-clock widget. -}
view : Config -> Html msg
view cfg =
    let
        dayFloat : Float
        dayFloat =
            toFloat cfg.holdSeconds / 86400

        progress : Float
        progress =
            if cfg.decayDays <= 0 then
                1

            else
                clamp 0 1 (dayFloat / toFloat cfg.decayDays)

        currentBps : Int
        currentBps =
            cfg.baseFeeBps - round (progress * toFloat (cfg.baseFeeBps - cfg.minFeeBps))

        remainingDays : Int
        remainingDays =
            max 0 (cfg.decayDays - floor dayFloat)

        bpsFmt : Int -> String
        bpsFmt b =
            let
                pct =
                    toFloat b / 100
            in
            String.fromFloat pct ++ "%"
    in
    Html.div [ Attr.class "web3-holdclock" ]
        [ Html.div
            [ Attr.class "web3-holdclock__current"
            , Attr.title "Current sell-fee tier given current hold time"
            ]
            [ Html.text (bpsFmt currentBps) ]
        , Html.div [ Attr.class "web3-holdclock__bar" ]
            [ Html.div
                [ Attr.class "web3-holdclock__fill"
                , Attr.style "width" (String.fromFloat (progress * 100) ++ "%")
                ]
                []
            ]
        , Html.div
            [ Attr.class "web3-holdclock__remaining" ]
            [ Html.text
                (if remainingDays <= 0 then
                    "at floor"

                 else
                    String.fromInt remainingDays
                        ++ " day"
                        ++ (if remainingDays == 1 then
                                ""

                            else
                                "s"
                           )
                        ++ " until "
                        ++ bpsFmt cfg.minFeeBps
                )
            ]
        ]
