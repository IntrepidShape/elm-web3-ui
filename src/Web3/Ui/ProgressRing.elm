module Web3.Ui.ProgressRing exposing (view)

{-| Circular progress ring (SVG) for "X% toward Y" displays — graduation
progress, vesting unlock, vault deposit cap. The circular variant of
`Web3.Ui.SupplyBar`.

    Web3.Ui.ProgressRing.view
        { current = curve.curvePls
        , target = graduationThreshold
        , size = 64
        , label = Just "graduation"
        }

CSS classes: `web3-progressring`, `web3-progressring__track`,
`web3-progressring__fill`, `web3-progressring__label`. Stroke width and color
come from CSS — set `stroke` and `stroke-width` on the `__track` and `__fill`
elements; geometry is inline for SVG.

@docs view

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Svg
import Svg.Attributes as SAttr
import Web3.BigInt as BigInt exposing (BigInt)


{-| Render the ring. -}
view :
    { current : BigInt
    , target : BigInt
    , size : Int
    , label : Maybe String
    }
    -> Html msg
view opts =
    let
        sizeStr =
            String.fromInt opts.size

        radius =
            toFloat opts.size / 2 - 4

        circumference =
            2 * pi * radius

        pct =
            percent opts.current opts.target

        offset =
            circumference * (1 - clamp 0 1 (pct / 100))

        center =
            String.fromFloat (toFloat opts.size / 2)

        rStr =
            String.fromFloat radius

        labelEl =
            case opts.label of
                Nothing ->
                    Html.text ""

                Just l ->
                    Html.div [ Attr.class "web3-progressring__label" ]
                        [ Html.text l ]
    in
    Html.div
        [ Attr.class "web3-progressring"
        , Attr.attribute "role" "img"
        , Attr.attribute "aria-label"
            ((opts.label |> Maybe.withDefault "progress")
                ++ ": "
                ++ String.fromInt (round pct)
                ++ "%"
            )
        ]
        [ Svg.svg
            [ SAttr.width sizeStr
            , SAttr.height sizeStr
            , SAttr.viewBox ("0 0 " ++ sizeStr ++ " " ++ sizeStr)
            ]
            [ Svg.circle
                [ SAttr.class "web3-progressring__track"
                , SAttr.cx center
                , SAttr.cy center
                , SAttr.r rStr
                , SAttr.fill "none"
                ]
                []
            , Svg.circle
                [ SAttr.class "web3-progressring__fill"
                , SAttr.cx center
                , SAttr.cy center
                , SAttr.r rStr
                , SAttr.fill "none"
                , SAttr.strokeDasharray (String.fromFloat circumference)
                , SAttr.strokeDashoffset (String.fromFloat offset)
                , SAttr.transform ("rotate(-90 " ++ center ++ " " ++ center ++ ")")
                , SAttr.strokeLinecap "round"
                ]
                []
            ]
        , labelEl
        ]


percent : BigInt -> BigInt -> Float
percent current target =
    if BigInt.isZero target then
        0

    else
        case ( String.toFloat (BigInt.toString current), String.toFloat (BigInt.toString target) ) of
            ( Just c, Just t ) ->
                if t == 0 then
                    0

                else
                    100 * c / t

            _ ->
                0
