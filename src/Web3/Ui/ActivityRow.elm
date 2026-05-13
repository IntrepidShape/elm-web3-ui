module Web3.Ui.ActivityRow exposing
    ( view
    , Kind(..)
    , defaultLabel
    )

{-| One row of an on-chain activity feed. The dapp pattern is universal:
"Alice bought 1.2M FOO", "Bob staked 50k BAR for 90 days", "0xABC graduated".
This component renders one such row with a `Kind` enum that drives the
icon and color modifier classes.

    Web3.Ui.ActivityRow.view
        { kind = Web3.Ui.ActivityRow.Buy
        , primary = "1.2M FOO"
        , secondary = Just "by 0xABC...DEF"
        , atSec = activity.timestamp
        , nowSec = model.nowSec
        , onClick = Just (OpenTx activity.txHash)
        }

CSS classes: `web3-activityrow`, `web3-activityrow--buy/--sell/--stake/...`,
`web3-activityrow__icon`, `web3-activityrow__primary`, `web3-activityrow__secondary`,
`web3-activityrow__time`.

@docs view, Kind, defaultLabel

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Web3.Ui.RelativeTime as RelativeTime


{-| One of the standard on-chain activity kinds. Add more as the lib evolves. -}
type Kind
    = Buy
    | Sell
    | Stake
    | Unstake
    | Penalty
    | Create
    | Graduate
    | Claim
    | Other String


{-| Default short label per kind, suitable as the icon's accessibility name. -}
defaultLabel : Kind -> String
defaultLabel k =
    case k of
        Buy ->
            "Buy"

        Sell ->
            "Sell"

        Stake ->
            "Stake"

        Unstake ->
            "Unstake"

        Penalty ->
            "Penalty"

        Create ->
            "Create"

        Graduate ->
            "Graduate"

        Claim ->
            "Claim"

        Other s ->
            s


{-| Render an activity row. -}
view :
    { kind : Kind
    , primary : String
    , secondary : Maybe String
    , atSec : Int
    , nowSec : Int
    , onClick : Maybe msg
    }
    -> Html msg
view opts =
    let
        modifier =
            case opts.kind of
                Buy ->
                    "buy"

                Sell ->
                    "sell"

                Stake ->
                    "stake"

                Unstake ->
                    "unstake"

                Penalty ->
                    "penalty"

                Create ->
                    "create"

                Graduate ->
                    "graduate"

                Claim ->
                    "claim"

                Other _ ->
                    "other"

        clickAttrs =
            case opts.onClick of
                Just msg ->
                    [ Events.onClick msg
                    , Attr.attribute "role" "button"
                    , Attr.tabindex 0
                    ]

                Nothing ->
                    []

        secondaryEl =
            case opts.secondary of
                Nothing ->
                    Html.text ""

                Just s ->
                    Html.span [ Attr.class "web3-activityrow__secondary" ]
                        [ Html.text s ]
    in
    Html.div
        ([ Attr.class ("web3-activityrow web3-activityrow--" ++ modifier) ] ++ clickAttrs)
        [ Html.span
            [ Attr.class "web3-activityrow__icon"
            , Attr.attribute "aria-label" (defaultLabel opts.kind)
            ]
            [ Html.text (iconFor opts.kind) ]
        , Html.span [ Attr.class "web3-activityrow__primary" ] [ Html.text opts.primary ]
        , secondaryEl
        , Html.span [ Attr.class "web3-activityrow__time" ]
            [ RelativeTime.view { nowSec = opts.nowSec, atSec = opts.atSec } ]
        ]


iconFor : Kind -> String
iconFor k =
    case k of
        Buy ->
            "▲"

        Sell ->
            "▼"

        Stake ->
            "◆"

        Unstake ->
            "◇"

        Penalty ->
            "✕"

        Create ->
            "✦"

        Graduate ->
            "★"

        Claim ->
            "✓"

        Other _ ->
            "·"
