module Web3.Ui.LockPeriod exposing
    ( view
    , Config
    )

{-| Slider for picking a lock-period (in days) with an optional penalty-curve
hint underneath. Designed for stake-and-lock contracts where users choose
how long to commit (any min/max range; pass what your contract enforces).

    Web3.Ui.LockPeriod.view []
        { value = model.lockDays
        , onChange = LockDaysChanged
        , min = 1
        , max = 365
        , penaltyAtMax = Just 35  -- 35% penalty at full early-exit
        , inputAttrs = []
        }

The slider renders a native `<input type="range">` for accessibility, with the
penalty hint as a side-by-side `<output>`. Style via `web3-lockperiod`,
`web3-lockperiod__slider`, `web3-lockperiod__readout`, `web3-lockperiod__penalty`.

@docs view, Config

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode as Decode


{-| Slider configuration. `penaltyAtMax` is the maximum early-exit penalty in
percent (e.g., `Just 35` for 35%). When `Nothing`, no penalty hint is shown.

`inputAttrs` reach the `<input type="range">` itself. The root is the wrapper
that also holds the readout and the penalty hint, so `id`, `disabled` and
`aria-describedby` -- which belong on the control -- go here instead.

-}
type alias Config msg =
    { value : Int
    , onChange : Int -> msg
    , min : Int
    , max : Int
    , penaltyAtMax : Maybe Int
    , inputAttrs : List (Html.Attribute msg)
    }


{-| Render the slider. -}
view : List (Html.Attribute msg) -> Config msg -> Html msg
view attrs cfg =
    let
        penaltyHint =
            case cfg.penaltyAtMax of
                Nothing ->
                    Html.text ""

                Just maxPenalty ->
                    let
                        -- linear interpolation: longer locks ⇒ higher max penalty.
                        -- Caller can override with their own logic by ignoring this.
                        rough =
                            (toFloat cfg.value / toFloat (max cfg.max 1))
                                * toFloat maxPenalty
                    in
                    Html.span
                        [ Attr.class "web3-lockperiod__penalty"
                        , Attr.title "Maximum early-exit penalty proportional to lock length"
                        ]
                        [ Html.text ("≤ " ++ String.fromInt (round rough) ++ "% early-exit") ]
    in
    Html.div (Attr.class "web3-lockperiod" :: attrs)
        [ Html.input
            ([ Attr.class "web3-lockperiod__slider"
             , Attr.type_ "range"
             , Attr.min (String.fromInt cfg.min)
             , Attr.max (String.fromInt cfg.max)
             , Attr.value (String.fromInt cfg.value)
             , Events.on "input" (Decode.map cfg.onChange targetValueAsInt)
             ]
                ++ cfg.inputAttrs
            )
            []
        , Html.output
            [ Attr.class "web3-lockperiod__readout" ]
            [ Html.text (String.fromInt cfg.value)
            , Html.text " day"
            , Html.text
                (if cfg.value == 1 then
                    ""

                 else
                    "s"
                )
            ]
        , penaltyHint
        ]


targetValueAsInt : Decode.Decoder Int
targetValueAsInt =
    Decode.at [ "target", "value" ] Decode.string
        |> Decode.andThen
            (\s ->
                case String.toInt s of
                    Just n ->
                        Decode.succeed n

                    Nothing ->
                        Decode.fail ("not an int: " ++ s)
            )
