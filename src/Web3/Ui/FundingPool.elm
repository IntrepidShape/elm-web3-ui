module Web3.Ui.FundingPool exposing
    ( view, Config, Pool, Pledger, Status(..)
    , Labels, defaultLabels
    , pool
    )

{-| Render a **crowd-funded pool** panel -- generic shape for any
"escrowed funding with a target, deadline, and refund fallback"
mechanism.

Use cases:

  - Community-funded audits (pledgers crowdfund a security review ->
    auditor delivers report -> escrow releases).
  - Bug-bounty / vulnerability-fix pools.
  - Open-source-feature crowdfunding (pledgers fund a feature ->
    maintainer ships -> escrow releases).
  - Refundable kickstarter-style commitments where the deliverable
    is on-chain verifiable.

The structural pattern is universal:

  1. Someone commits to deliver against a target.
  2. Anyone pledges native value while the deadline is in the future.
  3. Once the target is met, the proposer releases by publishing a
     deliverable URI.
  4. If the deadline passes without release, every pledger pulls back
     their own deposit.

Three lifecycle states swap the primary CTA:

  - `Open` -- collecting pledges, deadline ahead.
  - `Funded` -- target reached, awaiting release.
  - `Closed` -- released (with deliverable URL) or expired (refunds).

The panel title, status pill copy, CTA verbs, and disclaimer are all
configurable via [`Labels`](#Labels) so the panel can speak in the
voice of whichever mechanism the caller is exposing.

    Web3.Ui.FundingPool.view []
        { pool =
            Web3.Ui.FundingPool.pool
                { target = "25.0"
                , balance = "14.75"
                , unit = "PLS"
                , deadline = "6 days"
                , pledgerCount = 47
                , topPledgers = [ { label = "alice.eth", amount = "2.5" } ]
                , status = Open
                , reportUrl = Nothing
                }
        , labels = Web3.Ui.FundingPool.defaultLabels
        , onPledge = Just PledgeStandard
        , onPledgeCustom = Just PledgeCustom
        , onRefund = Nothing
        , onViewReport = Nothing
        }

Stateless -- caller owns the `Pool` and emits the appropriate `msg`.

CSS classes follow BEM: `web3-funding-pool`,
`web3-funding-pool__head`, `web3-funding-pool__title`,
`web3-funding-pool__subtitle`, `web3-funding-pool__stats`,
`web3-funding-pool__stat`, `web3-funding-pool__stat-label`,
`web3-funding-pool__stat-value`, `web3-funding-pool__progress`,
`web3-funding-pool__progress-fill`, `web3-funding-pool__pledgers`,
`web3-funding-pool__pledger`, `web3-funding-pool__actions`,
`web3-funding-pool__cta`,
`web3-funding-pool__cta--primary / --secondary`,
`web3-funding-pool__report`, `web3-funding-pool__disclaimer`.

@docs view, Config, Pool, Pledger, Status
@docs Labels, defaultLabels
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
strings because amount/unit/precision is the caller's concern -- this
primitive is rendering, not arithmetic.
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


{-| Construct a `Pool`. Progress is derived from target+balance via
best-effort string parsing; the result clamps to [0, 100].
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
                clamp 0 100 (floor ((b / t) * 100))

        _ ->
            0



-- LABELS --------------------------------------------------------------------


{-| Configurable strings rendered inside the panel. Override per pool
mechanism: an audit pool reads "Community-funded audit" / "Pledge" /
"View audit report"; a feature-funding pool reads "Community-funded
feature" / "Back" / "View deliverable".

`statusLabels` maps each [`Status`](#Status) to its status-pill text.
-}
type alias Labels =
    { title : String
    , pledgeCta : String
    , pledgeCustomCta : String
    , refundCta : String
    , viewReportCta : String
    , fundedMessage : String
    , disclaimer : String
    , targetLabel : String
    , poolLabel : String
    , deadlineLabel : String
    , pledgerCountLabel : String
    , topPledgersTitle : String
    , statusLabels :
        { open : String
        , funded : String
        , closed : String
        }
    }


{-| Generic defaults. Caller overrides any field with mechanism-specific
copy (e.g. forge.intrepiddev uses audit-pool framing on top of this). -}
defaultLabels : Labels
defaultLabels =
    { title = "Community-funded pool"
    , pledgeCta = "Pledge"
    , pledgeCustomCta = "Pledge custom"
    , refundCta = "Claim refund"
    , viewReportCta = "View deliverable"
    , fundedMessage = "Target met — awaiting release"
    , disclaimer =
        "Pledges are service prepayments for a deliverable. Refunds are available if the target is not met by the deadline."
    , targetLabel = "Target"
    , poolLabel = "Pool"
    , deadlineLabel = "Deadline"
    , pledgerCountLabel = "Pledgers"
    , topPledgersTitle = "Top pledgers"
    , statusLabels =
        { open = "open"
        , funded = "funded"
        , closed = "closed"
        }
    }



-- VIEW ----------------------------------------------------------------------


{-| Configuration for `view`. Each `onXxx` is optional -- pass `Nothing`
to disable that affordance.
-}
type alias Config msg =
    { pool : Pool
    , labels : Labels
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
        ([ Attr.class "web3-funding-pool"
         , Attr.class ("web3-funding-pool--" ++ statusSlug p.status)
         ]
            ++ attrs
        )
        [ headView cfg.labels p
        , statsView cfg.labels p
        , progressView p
        , pledgersView cfg.labels p
        , actionsView cfg
        , disclaimerView cfg.labels
        ]


headView : Labels -> { a | status : Status } -> Html msg
headView labels p =
    Html.div [ Attr.class "web3-funding-pool__head" ]
        [ Html.span [ Attr.class "web3-funding-pool__title" ]
            [ Html.text labels.title ]
        , Html.span
            [ Attr.class "web3-funding-pool__subtitle"
            , Attr.class ("web3-funding-pool__subtitle--" ++ statusSlug p.status)
            ]
            [ Html.text (statusLabel labels p.status) ]
        ]


statsView :
    Labels
    -> { a | target : String, balance : String, unit : String, deadline : String, pledgerCount : Int }
    -> Html msg
statsView labels p =
    Html.div [ Attr.class "web3-funding-pool__stats" ]
        [ statCell labels.targetLabel (p.target ++ " " ++ p.unit)
        , statCell labels.poolLabel (p.balance ++ " " ++ p.unit)
        , statCell labels.deadlineLabel p.deadline
        , statCell labels.pledgerCountLabel (String.fromInt p.pledgerCount)
        ]


statCell : String -> String -> Html msg
statCell label value =
    Html.div [ Attr.class "web3-funding-pool__stat" ]
        [ Html.span [ Attr.class "web3-funding-pool__stat-label" ]
            [ Html.text label ]
        , Html.span [ Attr.class "web3-funding-pool__stat-value" ]
            [ Html.text value ]
        ]


progressView : { a | progressPct : Int } -> Html msg
progressView p =
    Html.div
        [ Attr.class "web3-funding-pool__progress"
        , Attr.attribute "role" "progressbar"
        , Attr.attribute "aria-valuemin" "0"
        , Attr.attribute "aria-valuemax" "100"
        , Attr.attribute "aria-valuenow" (String.fromInt p.progressPct)
        ]
        [ Html.div
            [ Attr.class "web3-funding-pool__progress-fill"
            , Attr.style "width" (String.fromInt p.progressPct ++ "%")
            ]
            []
        ]


pledgersView : Labels -> { a | topPledgers : List Pledger, unit : String } -> Html msg
pledgersView labels p =
    if List.isEmpty p.topPledgers then
        Html.text ""

    else
        Html.div [ Attr.class "web3-funding-pool__pledgers" ]
            [ Html.div [ Attr.class "web3-funding-pool__pledgers-title" ]
                [ Html.text labels.topPledgersTitle ]
            , Html.ul [ Attr.class "web3-funding-pool__pledgers-list" ]
                (List.map (pledgerRow p.unit) p.topPledgers)
            ]


pledgerRow : String -> Pledger -> Html msg
pledgerRow unit pl =
    Html.li [ Attr.class "web3-funding-pool__pledger" ]
        [ Html.span [ Attr.class "web3-funding-pool__pledger-label" ]
            [ Html.text pl.label ]
        , Html.span [ Attr.class "web3-funding-pool__pledger-amount" ]
            [ Html.text (pl.amount ++ " " ++ unit) ]
        ]


actionsView : Config msg -> Html msg
actionsView cfg =
    let
        (Pool p) =
            cfg.pool
    in
    Html.div [ Attr.class "web3-funding-pool__actions" ]
        (case p.status of
            Open ->
                [ pledgeCta cfg.onPledge cfg.labels.pledgeCta
                , pledgeCustomCta cfg.onPledgeCustom cfg.labels.pledgeCustomCta
                ]

            Funded ->
                [ Html.span [ Attr.class "web3-funding-pool__awaiting" ]
                    [ Html.text cfg.labels.fundedMessage ]
                ]

            Closed ->
                List.filterMap identity
                    [ Maybe.map (reportCta cfg.labels.viewReportCta) cfg.onViewReport
                    , Maybe.map (refundCta cfg.labels.refundCta) cfg.onRefund
                    ]
        )


pledgeCta : Maybe msg -> String -> Html msg
pledgeCta maybeMsg label =
    case maybeMsg of
        Just msg ->
            Html.button
                [ Attr.class "web3-funding-pool__cta"
                , Attr.class "web3-funding-pool__cta--primary"
                , Events.onClick msg
                ]
                [ Html.text label ]

        Nothing ->
            Html.button
                [ Attr.class "web3-funding-pool__cta"
                , Attr.class "web3-funding-pool__cta--primary"
                , Attr.disabled True
                ]
                [ Html.text label ]


pledgeCustomCta : Maybe msg -> String -> Html msg
pledgeCustomCta maybeMsg label =
    case maybeMsg of
        Just msg ->
            Html.button
                [ Attr.class "web3-funding-pool__cta"
                , Attr.class "web3-funding-pool__cta--secondary"
                , Events.onClick msg
                ]
                [ Html.text label ]

        Nothing ->
            Html.text ""


refundCta : String -> msg -> Html msg
refundCta label msg =
    Html.button
        [ Attr.class "web3-funding-pool__cta"
        , Attr.class "web3-funding-pool__cta--secondary"
        , Events.onClick msg
        ]
        [ Html.text label ]


reportCta : String -> msg -> Html msg
reportCta label msg =
    Html.button
        [ Attr.class "web3-funding-pool__cta"
        , Attr.class "web3-funding-pool__cta--primary"
        , Events.onClick msg
        ]
        [ Html.text label ]


disclaimerView : Labels -> Html msg
disclaimerView labels =
    Html.p [ Attr.class "web3-funding-pool__disclaimer" ]
        [ Html.text labels.disclaimer ]



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


statusLabel : Labels -> Status -> String
statusLabel labels s =
    case s of
        Open ->
            labels.statusLabels.open

        Funded ->
            labels.statusLabels.funded

        Closed ->
            labels.statusLabels.closed
