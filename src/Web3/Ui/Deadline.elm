module Web3.Ui.Deadline exposing (view, Config, toUnixDeadline)

{-| Transaction deadline picker — preset chips plus a custom minutes input,
the sibling of `Web3.Ui.SlippageInput`.

    Web3.Ui.Deadline.view
        { valueMinutes = model.deadlineMinutes
        , onChange = DeadlineChanged
        , presetsMinutes = [ 10, 20, 30 ]
        }

    -- At send time, turn minutes into the unix deadline the contract wants:
    deadline =
        Deadline.toUnixDeadline model.deadlineMinutes nowMillis

CSS classes: `web3-deadline`, `web3-deadline__chip`,
`web3-deadline__chip--active`, `web3-deadline__custom`.

@docs view, Config, toUnixDeadline

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events


{-| -}
type alias Config msg =
    { valueMinutes : Int
    , onChange : Int -> msg
    , presetsMinutes : List Int
    }


{-| Unix timestamp (seconds) `minutes` from a `Time.posixToMillis` now. -}
toUnixDeadline : Int -> Int -> Int
toUnixDeadline minutes nowMillis =
    nowMillis // 1000 + minutes * 60


{-| Render the picker. -}
view : Config msg -> Html msg
view cfg =
    Html.div [ Attr.class "web3-deadline" ]
        (List.map (chip cfg) cfg.presetsMinutes
            ++ [ customInput cfg ]
        )


chip : Config msg -> Int -> Html msg
chip cfg minutes =
    Html.button
        [ Attr.class "web3-deadline__chip"
        , Attr.classList [ ( "web3-deadline__chip--active", cfg.valueMinutes == minutes ) ]
        , Events.onClick (cfg.onChange minutes)
        ]
        [ Html.text (String.fromInt minutes ++ "m") ]


customInput : Config msg -> Html msg
customInput cfg =
    Html.input
        [ Attr.class "web3-deadline__custom"
        , Attr.type_ "number"
        , Attr.min "1"
        , Attr.value (String.fromInt cfg.valueMinutes)
        , Attr.attribute "aria-label" "Deadline in minutes"
        , Events.onInput
            (\raw ->
                cfg.onChange
                    (String.toInt raw
                        |> Maybe.map (max 1)
                        |> Maybe.withDefault cfg.valueMinutes
                    )
            )
        ]
        []
