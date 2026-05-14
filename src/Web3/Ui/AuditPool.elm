module Web3.Ui.AuditPool exposing
    ( view, Config, Pool, Status(..), Pledger
    , pool
    )

{-| Render a **community-funded audit pool** panel for a smart contract.

Companion to [`Web3.Ui.SecurityCard`](Web3-Ui-SecurityCard) — where the
security card shows what *automated* tooling found, the audit-pool panel
shows what the *community* is willing to pay to have a human auditor
review.

Design intent:

  - **Three states**, never ambiguous: `Open` (collecting pledges,
    deadline ahead), `Funded` (target reached, awaiting auditor release),
    `Closed` (released with report link, or expired with refunds open).
    Each state changes the primary CTA.
  - **Service-prepayment framing.** Pledgers receive a deliverable (the
    audit report URI on release), never equity. Refund is a non-
    discretionary backstop, surfaced as a secondary CTA only when
    relevant.
  - **Anchor sizes** for the pledge CTAs (e.g. 25 / 100 / custom) so the
    panel isn't an unbounded "enter number" form — that's where Web3 UX
    falls down.

The component is **stateless**: caller owns the `Pool` and emits the
appropriate `msg` on user action. Indexer translates on-chain events
into the `Pool` shape; the panel re-renders.

    Web3.Ui.AuditPool.view []
        { pool =
            Web3.Ui.AuditPool.pool
                { target = "25.0"
                , balance = "14.75"
                , unit = "PLS"
                , deadline = "6 days"
                , pledgerCount = 47
                , topPledgers =
                    [ { label = "alice.eth", amount = "2.5" }
                    , { label = "0xabc…cd2",  amount = "1.0" }
                    , { label = "bob.eth",   amount = "0.75" }
                    ]
                , status = Open
                , reportUrl = Nothing
                }
        , onPledge = Just (PledgeStandard "25")
        , onPledgeCustom = Just PledgeCustom
        , onRefund = Nothing
        , onViewReport = Nothing
        }

CSS classes follow BEM: `web3-audit-pool`, `web3-audit-pool__head`,
`web3-audit-pool__title`, `web3-audit-pool__subtitle`,
`web3-audit-pool__stats`, `web3-audit-pool__stat`,
`web3-audit-pool__stat-label`, `web3-audit-pool__stat-value`,
`web3-audit-pool__progress`, `web3-audit-pool__progress-fill`,
`web3-audit-pool__pledgers`, `web3-audit-pool__pledger`,
`web3-audit-pool__actions`, `web3-audit-pool__cta`,
`web3-audit-pool__cta--primary / --secondary`,
`web3-audit-pool__report`, `web3-audit-pool__disclaimer`.

@docs view, Config, Pool, Status, Pledger
@docs pool

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events



-- TYPES ---------------------------------------------------------------------


{-| A pool's lifecycle state. -}
type Status
    = Open
    | Funded
    | Closed


{-| One pledger row in the "top pledgers" list. -}
type alias Pledger =
    { label : String
    , amount : String
    }


{-| The pool's current observable state. Values are pre-formatted
strings (e.g. `"25.0"`) because amount/unit/precision is the caller's
concern — this primitive is rendering, not arithmetic.
-}
type Pool
    = Pool
        { target : String
        , balance : String
        , unit : String
        , deadline : String
        , pledgerCount : Int
        , topPledgers : List Pledger
        , status : Status
        , reportUrl : Maybe String
        , progressPct : Int
        }


{-| Construct a `Pool`. The progress percentage is derived from
target+balance via best-effort string parsing; callers can rely on it
clamping to [0, 100].
-}
pool :
    { target : String
    , balance : String
    , unit : String
    , deadline : String
    , pledgerCount : Int
    , topPledgers : List Pledger
    , status : Status
    , reportUrl : Maybe String
    }
    -> Pool
pool r =
    Pool
        { target = r.target
        , balance = r.balance
        , unit = r.unit
        , deadline = r.deadline
        , pledgerCount = r.pledgerCount
        , topPledgers = r.topPledgers
        , status = r.status
        , reportUrl = r.reportUrl
        , progressPct = computeProgress r.balance r.target
        }


computeProgress : String -> String -> Int
computeProgress balance target =
    case ( String.toFloat balance, String.toFloat target ) of
        ( Just b, Just t ) ->
            if t <= 0 then
                0

            else
                let
                    pct =
                        floor ((b / t) * 100)
                in
                clamp 0 100 pct

        _ ->
            0



-- VIEW ----------------------------------------------------------------------


{-| Configuration for `view`. Each `onXxx` is optional — pass `Nothing`
to disable that affordance (e.g. `onRefund = Nothing` when the pool
hasn't expired, `onViewReport` until release publishes a URI).
-}
type alias Config msg =
    { pool : Pool
    , onPledge : Maybe msg
    , onPledgeCustom : Maybe msg
    , onRefund : Maybe msg
    , onViewReport : Maybe msg
    }


{-| Render the panel. -}
view : List (Html.Attribute msg) -> Config msg -> Html msg
view attrs cfg =
    let
        (Pool p) =
            cfg.pool
    in
    Html.div
        ([ Attr.class "web3-audit-pool"
         , Attr.class ("web3-audit-pool--" ++ statusSlug p.status)
         ]
            ++ attrs
        )
        [ headView p
        , statsView p
        , progressView p
        , pledgersView p
        , actionsView cfg
        , disclaimerView
        ]


headView : { a | status : Status } -> Html msg
headView p =
    Html.div [ Attr.class "web3-audit-pool__head" ]
        [ Html.span [ Attr.class "web3-audit-pool__title" ]
            [ Html.text "Community-funded audit" ]
        , Html.span
            [ Attr.class "web3-audit-pool__subtitle"
            , Attr.class
                ("web3-audit-pool__subtitle--" ++ statusSlug p.status)
            ]
            [ Html.text (statusLabel p.status) ]
        ]


statsView :
    { a
        | target : String
        , balance : String
        , unit : String
        , deadline : String
        , pledgerCount : Int
    }
    -> Html msg
statsView p =
    Html.div [ Attr.class "web3-audit-pool__stats" ]
        [ statCell "Target" (p.target ++ " " ++ p.unit)
        , statCell "Pool" (p.balance ++ " " ++ p.unit)
        , statCell "Deadline" p.deadline
        , statCell "Pledgers" (String.fromInt p.pledgerCount)
        ]


statCell : String -> String -> Html msg
statCell label value =
    Html.div [ Attr.class "web3-audit-pool__stat" ]
        [ Html.span [ Attr.class "web3-audit-pool__stat-label" ]
            [ Html.text label ]
        , Html.span [ Attr.class "web3-audit-pool__stat-value" ]
            [ Html.text value ]
        ]


progressView : { a | progressPct : Int } -> Html msg
progressView p =
    Html.div
        [ Attr.class "web3-audit-pool__progress"
        , Attr.attribute "role" "progressbar"
        , Attr.attribute "aria-valuemin" "0"
        , Attr.attribute "aria-valuemax" "100"
        , Attr.attribute "aria-valuenow" (String.fromInt p.progressPct)
        ]
        [ Html.div
            [ Attr.class "web3-audit-pool__progress-fill"
            , Attr.style "width" (String.fromInt p.progressPct ++ "%")
            ]
            []
        ]


pledgersView : { a | topPledgers : List Pledger, unit : String } -> Html msg
pledgersView p =
    if List.isEmpty p.topPledgers then
        Html.text ""

    else
        Html.div [ Attr.class "web3-audit-pool__pledgers" ]
            [ Html.div [ Attr.class "web3-audit-pool__pledgers-title" ]
                [ Html.text "Top pledgers" ]
            , Html.ul [ Attr.class "web3-audit-pool__pledgers-list" ]
                (List.map (pledgerRow p.unit) p.topPledgers)
            ]


pledgerRow : String -> Pledger -> Html msg
pledgerRow unit pl =
    Html.li [ Attr.class "web3-audit-pool__pledger" ]
        [ Html.span [ Attr.class "web3-audit-pool__pledger-label" ]
            [ Html.text pl.label ]
        , Html.span [ Attr.class "web3-audit-pool__pledger-amount" ]
            [ Html.text (pl.amount ++ " " ++ unit) ]
        ]


actionsView : Config msg -> Html msg
actionsView cfg =
    let
        (Pool p) =
            cfg.pool
    in
    Html.div [ Attr.class "web3-audit-pool__actions" ]
        (case p.status of
            Open ->
                [ pledgeCta cfg.onPledge "Pledge"
                , pledgeCustomCta cfg.onPledgeCustom
                ]

            Funded ->
                [ Html.span [ Attr.class "web3-audit-pool__awaiting" ]
                    [ Html.text "Target met — awaiting auditor release" ]
                ]

            Closed ->
                List.filterMap identity
                    [ Maybe.map reportCta cfg.onViewReport
                    , Maybe.map refundCta cfg.onRefund
                    ]
        )


pledgeCta : Maybe msg -> String -> Html msg
pledgeCta maybeMsg label =
    case maybeMsg of
        Just msg ->
            Html.button
                [ Attr.class "web3-audit-pool__cta"
                , Attr.class "web3-audit-pool__cta--primary"
                , Events.onClick msg
                ]
                [ Html.text label ]

        Nothing ->
            Html.button
                [ Attr.class "web3-audit-pool__cta"
                , Attr.class "web3-audit-pool__cta--primary"
                , Attr.disabled True
                ]
                [ Html.text label ]


pledgeCustomCta : Maybe msg -> Html msg
pledgeCustomCta maybeMsg =
    case maybeMsg of
        Just msg ->
            Html.button
                [ Attr.class "web3-audit-pool__cta"
                , Attr.class "web3-audit-pool__cta--secondary"
                , Events.onClick msg
                ]
                [ Html.text "Pledge custom" ]

        Nothing ->
            Html.text ""


refundCta : msg -> Html msg
refundCta msg =
    Html.button
        [ Attr.class "web3-audit-pool__cta"
        , Attr.class "web3-audit-pool__cta--secondary"
        , Events.onClick msg
        ]
        [ Html.text "Claim refund" ]


reportCta : msg -> Html msg
reportCta msg =
    Html.button
        [ Attr.class "web3-audit-pool__cta"
        , Attr.class "web3-audit-pool__cta--primary"
        , Events.onClick msg
        ]
        [ Html.text "View audit report" ]


disclaimerView : Html msg
disclaimerView =
    Html.p [ Attr.class "web3-audit-pool__disclaimer" ]
        [ Html.text
            "Pledges are service prepayments for an audit deliverable. "
        , Html.text
            "Refunds are available if the target is not met by the deadline."
        ]



-- SLUGS ---------------------------------------------------------------------


statusSlug : Status -> String
statusSlug s =
    case s of
        Open ->
            "open"

        Funded ->
            "funded"

        Closed ->
            "closed"


statusLabel : Status -> String
statusLabel s =
    case s of
        Open ->
            "open"

        Funded ->
            "funded"

        Closed ->
            "closed"
