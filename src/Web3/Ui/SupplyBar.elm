module Web3.Ui.SupplyBar exposing
    ( view
    , withMilestone
    , Config
    )

{-| Progress bar for any "how full is X" metric — token supply against a cap,
graduation reserves toward a threshold, vault deposits toward an issuance limit.

    -- Bare usage:
    Web3.Ui.SupplyBar.view
        { current = curve.supply
        , max = maxSupply
        , label = Just "supply"
        }

    -- With a milestone marker (e.g., the bonding-curve graduation threshold
    -- sitting partway along a max-reserve bar):
    Web3.Ui.SupplyBar.withMilestone
        { current = curve.curvePls
        , max = totalCapacity
        , milestone = Just { at = graduationThreshold, label = "graduation" }
        , label = Just "reserves"
        }

The bar is rendered as a styled `div` with CSS classes `web3-supplybar`,
`web3-supplybar__fill`, `web3-supplybar__milestone`, `web3-supplybar__label`.
Width is controlled by `width: <pct>%` inline; everything else is style-via-CSS.

@docs view, withMilestone, Config

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Web3.BigInt as BigInt exposing (BigInt)
import Web3.Ui.Amount as Amount


{-| Minimal config for a plain progress bar. -}
type alias Config =
    { current : BigInt
    , max : BigInt
    , label : Maybe String
    }


{-| Render a progress bar without a milestone marker. -}
view : Config -> Html msg
view cfg =
    withMilestone
        { current = cfg.current
        , max = cfg.max
        , milestone = Nothing
        , label = cfg.label
        }


{-| Render a progress bar, optionally annotated with a milestone marker
positioned at `milestone.at` along the `[0, max]` range. -}
withMilestone :
    { current : BigInt
    , max : BigInt
    , milestone : Maybe { at : BigInt, label : String }
    , label : Maybe String
    }
    -> Html msg
withMilestone opts =
    let
        pct =
            percent opts.current opts.max

        milestoneEl =
            case opts.milestone of
                Nothing ->
                    Html.text ""

                Just m ->
                    Html.div
                        [ Attr.class "web3-supplybar__milestone"
                        , Attr.style "left" (String.fromFloat (percent m.at opts.max) ++ "%")
                        , Attr.title m.label
                        ]
                        []

        labelEl =
            case opts.label of
                Nothing ->
                    Html.text ""

                Just l ->
                    Html.div
                        [ Attr.class "web3-supplybar__label" ]
                        [ Html.text l
                        , Html.text " · "
                        , Html.text (Amount.formatWei 18 opts.current)
                        , Html.text " / "
                        , Html.text (Amount.formatWei 18 opts.max)
                        ]
    in
    Html.div [ Attr.class "web3-supplybar" ]
        [ Html.div
            [ Attr.class "web3-supplybar__fill"
            , Attr.style "width" (String.fromFloat (clamp 0 100 pct) ++ "%")
            ]
            []
        , milestoneEl
        , labelEl
        ]


{-| Compute `(current / max) * 100` as a Float, returning `0` when `max == 0`. -}
percent : BigInt -> BigInt -> Float
percent current max =
    if BigInt.isZero max then
        0

    else
        case ( String.toFloat (BigInt.toString current), String.toFloat (BigInt.toString max) ) of
            ( Just c, Just m ) ->
                if m == 0 then
                    0

                else
                    100 * c / m

            _ ->
                0
