module Web3.Ui.SecurityCard exposing
    ( view, Config
    , Findings, findings
    , Finding, Severity(..)
    , Stubbed(..)
    )

{-| Render a Trustpilot-style **security pre-flight card** for a smart
contract, summarising static-analysis findings (Slither, Aderyn, Mythril,
…).

Design intent (informed by the dapp-gen UX research brief):

  - **Never** a single Pass/Fail verdict. Always a *breakdown* of finding
    counts by severity. Static analyzers have known false-positive
    rates; presenting a single pass/fail invites misinterpretation.
  - Top-3 most-severe findings surface inline so a user has *actionable*
    information without clicking into a long report.
  - The "request human audit" CTA is always available — the card is a
    funnel, not a substitute, and that framing protects everyone (the
    auditor, the user, and the contract author).

The component is **stateless** like every primitive in this lib — the
caller owns the [`Findings`](#Findings) record and the `Stubbed` flag
(set to `Yes` when no analysis has run, e.g. an Etherscan-only fetch
where no NatSpec or sources are available).

    Web3.Ui.SecurityCard.view []
        { findings =
            Web3.Ui.SecurityCard.findings
                { critical = 0
                , high = 2
                , medium = 5
                , low = 11
                , info = 8
                }
        , topFindings =
            [ { severity = High
              , title = "Centralization risk — onlyOwner can mint"
              , tool = "slither"
              }
            , { severity = High
              , title = "Reentrancy in withdraw()"
              , tool = "slither"
              }
            , { severity = Medium
              , title = "Missing zero-address check in setOracle"
              , tool = "aderyn"
              }
            ]
        , toolVersions = [ ( "slither", "0.10.4" ), ( "aderyn", "0.5.1" ) ]
        , stubbed = NotStubbed
        , reportUrl = Just "/dapp/1/0x.../report"
        , onRequestAudit = Just RequestAudit
        }

CSS classes follow BEM: `web3-security-card`, `web3-security-card__head`,
`web3-security-card__counts`, `web3-security-card__count`,
`web3-security-card__count--critical / --high / --medium / --low / --info`,
`web3-security-card__findings`, `web3-security-card__finding`,
`web3-security-card__finding-severity`, `web3-security-card__finding-title`,
`web3-security-card__finding-tool`, `web3-security-card__tools`,
`web3-security-card__actions`, `web3-security-card__disclaimer`.

@docs view, Config
@docs Findings, findings
@docs Finding, Severity
@docs Stubbed

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events



-- FINDING COUNTS ------------------------------------------------------------


{-| Per-severity counts. -}
type Findings
    = Findings
        { critical : Int
        , high : Int
        , medium : Int
        , low : Int
        , info : Int
        }


{-| Construct a `Findings` value. -}
findings :
    { critical : Int
    , high : Int
    , medium : Int
    , low : Int
    , info : Int
    }
    -> Findings
findings r =
    Findings r


totalFindings : Findings -> Int
totalFindings (Findings f) =
    f.critical + f.high + f.medium + f.low + f.info



-- INDIVIDUAL FINDINGS -------------------------------------------------------


{-| One specific finding from a tool. -}
type alias Finding =
    { severity : Severity
    , title : String
    , tool : String
    }


{-| Severity stops. -}
type Severity
    = Critical
    | High
    | Medium
    | Low
    | Info



-- STUBBED FLAG --------------------------------------------------------------


{-| Whether real analysis ran or the card is rendering the "not-available"
state. Etherscan-only fetches don't carry the metadata needed for
analysis, and during early development the analyser may be stubbed.
-}
type Stubbed
    = NotStubbed
    | Yes String  -- reason (e.g. "etherscan source", "analysis disabled")



-- VIEW ----------------------------------------------------------------------


{-| Configuration for `view`. -}
type alias Config msg =
    { findings : Findings
    , topFindings : List Finding
    , toolVersions : List ( String, String )
    , stubbed : Stubbed
    , reportUrl : Maybe String
    , onRequestAudit : Maybe msg
    }


{-| Render the card. -}
view : List (Html.Attribute msg) -> Config msg -> Html msg
view attrs opts =
    Html.div
        ([ Attr.class "web3-security-card" ] ++ attrs)
        [ headView opts
        , bodyView opts
        , disclaimerView opts
        ]


headView : Config msg -> Html msg
headView opts =
    Html.div [ Attr.class "web3-security-card__head" ]
        [ Html.span [ Attr.class "web3-security-card__title" ]
            [ Html.text "Security pre-flight" ]
        , Html.span [ Attr.class "web3-security-card__subtitle" ]
            [ Html.text "static analysis" ]
        ]


bodyView : Config msg -> Html msg
bodyView opts =
    case opts.stubbed of
        Yes reason ->
            Html.div [ Attr.class "web3-security-card__body" ]
                [ Html.p [ Attr.class "web3-security-card__stubbed" ]
                    [ Html.text ("Analysis not available: " ++ reason) ]
                , actionsView opts
                ]

        NotStubbed ->
            Html.div [ Attr.class "web3-security-card__body" ]
                [ countsView opts.findings
                , topFindingsView opts.topFindings
                , toolsView opts.toolVersions
                , actionsView opts
                ]


countsView : Findings -> Html msg
countsView (Findings f) =
    Html.div [ Attr.class "web3-security-card__counts" ]
        [ countCell "critical" f.critical "critical"
        , countCell "high" f.high "high"
        , countCell "medium" f.medium "medium"
        , countCell "low" f.low "low"
        , countCell "info" f.info "info"
        ]


countCell : String -> Int -> String -> Html msg
countCell modifier n label =
    Html.div
        [ Attr.class "web3-security-card__count"
        , Attr.class ("web3-security-card__count--" ++ modifier)
        , Attr.classList [ ( "web3-security-card__count--zero", n == 0 ) ]
        ]
        [ Html.span [ Attr.class "web3-security-card__count-n" ]
            [ Html.text (String.fromInt n) ]
        , Html.span [ Attr.class "web3-security-card__count-label" ]
            [ Html.text label ]
        ]


topFindingsView : List Finding -> Html msg
topFindingsView fs =
    let
        top =
            List.take 3 fs
    in
    if List.isEmpty top then
        Html.text ""

    else
        Html.div [ Attr.class "web3-security-card__findings" ]
            [ Html.div [ Attr.class "web3-security-card__findings-title" ]
                [ Html.text "Top findings" ]
            , Html.ul [ Attr.class "web3-security-card__findings-list" ]
                (List.map findingRow top)
            ]


findingRow : Finding -> Html msg
findingRow f =
    Html.li [ Attr.class "web3-security-card__finding" ]
        [ Html.span
            [ Attr.class "web3-security-card__finding-severity"
            , Attr.class
                ("web3-security-card__finding-severity--"
                    ++ severitySlug f.severity
                )
            ]
            [ Html.text (severityLabel f.severity) ]
        , Html.span [ Attr.class "web3-security-card__finding-title" ]
            [ Html.text f.title ]
        , Html.span [ Attr.class "web3-security-card__finding-tool" ]
            [ Html.text f.tool ]
        ]


severitySlug : Severity -> String
severitySlug s =
    case s of
        Critical ->
            "critical"

        High ->
            "high"

        Medium ->
            "medium"

        Low ->
            "low"

        Info ->
            "info"


severityLabel : Severity -> String
severityLabel s =
    case s of
        Critical ->
            "CRITICAL"

        High ->
            "HIGH"

        Medium ->
            "MEDIUM"

        Low ->
            "LOW"

        Info ->
            "INFO"


toolsView : List ( String, String ) -> Html msg
toolsView pairs =
    if List.isEmpty pairs then
        Html.text ""

    else
        Html.div [ Attr.class "web3-security-card__tools" ]
            [ Html.span [ Attr.class "web3-security-card__tools-label" ]
                [ Html.text "Run by" ]
            , Html.span [ Attr.class "web3-security-card__tools-list" ]
                (List.intersperse
                    (Html.span [ Attr.class "web3-security-card__tools-sep" ] [ Html.text " · " ])
                    (List.map toolBadge pairs)
                )
            ]


toolBadge : ( String, String ) -> Html msg
toolBadge ( name, version ) =
    Html.span [ Attr.class "web3-security-card__tool" ]
        [ Html.text (name ++ " " ++ version) ]


actionsView : Config msg -> Html msg
actionsView opts =
    Html.div [ Attr.class "web3-security-card__actions" ]
        [ case opts.reportUrl of
            Just url ->
                Html.a
                    [ Attr.href url
                    , Attr.class "web3-security-card__report-link"
                    ]
                    [ Html.text "See full report" ]

            Nothing ->
                Html.text ""
        , case opts.onRequestAudit of
            Just msg ->
                Html.button
                    [ Attr.class "web3-security-card__audit-btn"
                    , Attr.type_ "button"
                    , Events.onClick msg
                    , Attr.classList
                        [ ( "web3-security-card__audit-btn--urgent"
                          , shouldUrgeAudit opts
                          )
                        ]
                    ]
                    [ Html.text "Request human audit" ]

            Nothing ->
                Html.text ""
        ]


shouldUrgeAudit : Config msg -> Bool
shouldUrgeAudit opts =
    let
        (Findings f) =
            opts.findings
    in
    f.critical > 0 || f.high > 0 || f.medium >= 3


disclaimerView : Config msg -> Html msg
disclaimerView opts =
    let
        text_ =
            case opts.stubbed of
                Yes _ ->
                    "Verified source code or NatSpec metadata required to run static analysis. Human audit is always recommended before significant on-chain interactions."

                NotStubbed ->
                    if totalFindings opts.findings == 0 then
                        "Static analysis is a starting point — a clean run does not guarantee safety. A human audit is recommended before significant on-chain interactions."

                    else
                        "Static analysis produces signals, not verdicts. Findings may be false positives; severity is heuristic. Always read the contract before approving."
    in
    Html.p [ Attr.class "web3-security-card__disclaimer" ]
        [ Html.text text_ ]
