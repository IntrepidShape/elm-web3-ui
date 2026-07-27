module Web3.Ui.ProgressRing exposing (view)

{-| Circular progress ring (SVG) for "X% toward Y" displays -- graduation
progress, vesting unlock, vault deposit cap. The circular variant of
`Web3.Ui.SupplyBar`.

    Web3.Ui.ProgressRing.view
        { current = curve.curvePls
        , target = graduationThreshold
        , size = 64
        , label = Just "graduation"
        }

`current / target` is divided in `BigInt` space and the arc geometry is carried
as hundredths of a pixel, so nothing is routed through `Float`.

CSS classes: `web3-progressring`, `web3-progressring__track`,
`web3-progressring__fill`, `web3-progressring__label`. Stroke width and color
come from CSS -- set `stroke` and `stroke-width` on the `__track` and `__fill`
elements; geometry is inline for SVG.

@docs view

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Svg
import Svg.Attributes as SAttr
import Web3.BigInt exposing (BigInt)
import Web3.Ui.Internal.Decimal as Decimal


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

        -- Hundredths of a pixel throughout: SVG accepts decimals, and integers
        -- keep the arc exact without a Float anywhere in the path.
        radius100 =
            max 0 (opts.size * 50 - 400)

        circumference100 =
            radius100 * tauScaled // tauScale

        filled =
            clamp 0 scale (Decimal.scaledRatio scale opts.current opts.target)

        offset100 =
            circumference100 * (scale - filled) // scale

        center =
            Decimal.fixedPoint 2 (opts.size * 50)

        rStr =
            Decimal.fixedPoint 2 radius100

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
                ++ String.fromInt ((Decimal.ratioBps opts.current opts.target + 50) // 100)
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
                , SAttr.strokeDasharray (Decimal.fixedPoint 2 circumference100)
                , SAttr.strokeDashoffset (Decimal.fixedPoint 2 offset100)
                , SAttr.transform ("rotate(-90 " ++ center ++ " " ++ center ++ ")")
                , SAttr.strokeLinecap "round"
                ]
                []
            ]
        , labelEl
        ]


{-| Fixed-point resolution for the filled fraction. -}
scale : Int
scale =
    1000000


{-| `2 * pi` on `tauScale`, so the circumference stays integer arithmetic. -}
tauScaled : Int
tauScaled =
    628319


tauScale : Int
tauScale =
    100000
