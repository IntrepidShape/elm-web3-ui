module Web3.Ui.SupplyBar exposing
    ( view
    , withMilestone
    , Config
    , MilestoneConfig
    )

{-| Progress bar for any "how full is X" metric -- token supply against a cap,
graduation reserves toward a threshold, vault deposits toward an issuance limit.

    -- Bare usage:
    Web3.Ui.SupplyBar.view []
        { current = curve.supply
        , max = maxSupply
        , decimals = 18
        , label = Just "supply"
        }

    -- With a milestone marker (e.g., the bonding-curve graduation threshold
    -- sitting partway along a max-reserve bar):
    Web3.Ui.SupplyBar.withMilestone []
        { current = curve.curvePls
        , max = totalCapacity
        , decimals = 18
        , milestone = Just { at = graduationThreshold, label = "graduation" }
        , label = Just "reserves"
        }

`decimals` scales the amounts printed in the label. It used to be hardcoded to
18, which rendered a 6-decimal token's supply 1e12 times too small.

The bar is rendered as a styled `div` with CSS classes `web3-supplybar`,
`web3-supplybar__fill`, `web3-supplybar__milestone`, `web3-supplybar__label`.
Width is controlled by `width: <pct>%` inline; everything else is style-via-CSS.

The fill percentage is computed by dividing in `BigInt` space and is emitted
with two decimal places, so a bar at 1 part in 10000 of a 2^255 cap is still
positioned correctly. No amount is routed through `Float`.

@docs view, withMilestone, Config, MilestoneConfig

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Web3.BigInt exposing (BigInt)
import Web3.Ui.Amount as Amount
import Web3.Ui.Internal.Decimal as Decimal


{-| Minimal config for a plain progress bar. -}
type alias Config =
    { current : BigInt
    , max : BigInt
    , decimals : Int
    , label : Maybe String
    }


{-| [`Config`](#Config) plus an optional marker positioned at `milestone.at`
along the `[0, max]` range.
-}
type alias MilestoneConfig =
    { current : BigInt
    , max : BigInt
    , decimals : Int
    , milestone : Maybe { at : BigInt, label : String }
    , label : Maybe String
    }


{-| Render a progress bar without a milestone marker. -}
view : List (Html.Attribute msg) -> Config -> Html msg
view attrs cfg =
    withMilestone attrs
        { current = cfg.current
        , max = cfg.max
        , decimals = cfg.decimals
        , milestone = Nothing
        , label = cfg.label
        }


{-| Render a progress bar, optionally annotated with a milestone marker
positioned at `milestone.at` along the `[0, max]` range. -}
withMilestone : List (Html.Attribute msg) -> MilestoneConfig -> Html msg
withMilestone attrs opts =
    let
        pct =
            percentHundredths opts.current opts.max

        milestoneEl =
            case opts.milestone of
                Nothing ->
                    Html.text ""

                Just m ->
                    Html.div
                        [ Attr.class "web3-supplybar__milestone"
                        , Attr.style "left" (pctStyle (percentHundredths m.at opts.max))
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
                        , Html.text (Amount.formatWei opts.decimals opts.current)
                        , Html.text " / "
                        , Html.text (Amount.formatWei opts.decimals opts.max)
                        ]
    in
    Html.div (Attr.class "web3-supplybar" :: attrs)
        [ Html.div
            [ Attr.class "web3-supplybar__fill"
            , Attr.style "width" (pctStyle pct)
            ]
            []
        , milestoneEl
        , labelEl
        ]


{-| `(current / max) * 100` in hundredths of a percent, divided in `BigInt`
space so no uint256 is ever narrowed to a machine number. `0` when `max` is
zero.
-}
percentHundredths : BigInt -> BigInt -> Int
percentHundredths current max =
    Decimal.ratioBps current max


{-| Hundredths of a percent as a CSS length, clamped to `[0%, 100%]`. -}
pctStyle : Int -> String
pctStyle hundredths =
    Decimal.fixedPoint 2 (clamp 0 10000 hundredths) ++ "%"
