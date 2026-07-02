module Web3.Ui.PendingOverlay exposing
    ( view
    , conditionalView
    , viewMultiStep
    , Step
    , StepState(..)
    )

{-| Overlay shown while waiting for wallet signature.

Every dapp needs a "check your wallet" prompt when a transaction is
`AwaitingSignature`. This module provides a consistent overlay so each
project does not hand-roll the same spinner and copy.

    -- Always rendered (you control visibility via CSS or parent logic):
    Web3.Ui.PendingOverlay.view []
        { message = "Check your wallet" }

    -- Only renders during AwaitingSignature, empty otherwise:
    Web3.Ui.PendingOverlay.conditionalView []
        { message = "Check your wallet" }
        model.tx

    -- Multi-step approve → call sequence:
    Web3.Ui.PendingOverlay.viewMultiStep []
        { steps =
            [ { label = "Approve $TOKEN", state = StepDone }
            , { label = "Stake $TOKEN", state = StepActive }
            , { label = "Confirm on-chain", state = StepPending }
            ]
        , currentStatus = model.txStatus
        }


# Single-step

@docs view, conditionalView


# Multi-step

@docs viewMultiStep, Step, StepState

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Web3.Transaction as Tx


{-| Render the overlay unconditionally.

CSS classes: `web3-pending-overlay` (root), `web3-pending-overlay-inner`,
`web3-pending-spinner`, `web3-pending-message`

-}
view :
    List (Html.Attribute msg)
    -> { message : String }
    -> Html msg
view attrs opts =
    Html.div
        (Attr.class "web3-pending-overlay" :: Attr.attribute "role" "status" :: Attr.attribute "aria-busy" "true" :: attrs)
        [ Html.div
            [ Attr.class "web3-pending-overlay-inner" ]
            [ Html.div [ Attr.class "web3-pending-spinner" ] []
            , Html.p [ Attr.class "web3-pending-message" ] [ Html.text opts.message ]
            ]
        ]


{-| Render the overlay only when `status` is `Tx.AwaitingSignature`.

Returns `Html.text ""` for all other states — safe to always include in your
view tree.

-}
conditionalView :
    List (Html.Attribute msg)
    -> { message : String }
    -> Tx.Status
    -> Html msg
conditionalView attrs opts status =
    case status of
        Tx.AwaitingSignature ->
            view attrs opts

        _ ->
            Html.text ""



-- ── Multi-step approve → call ────────────────────────────────────────


{-| One row in a multi-step pending overlay.

  - `label` — human title for the step (e.g. "Approve $TOKEN").
  - `state` — `StepPending` (not started), `StepActive` (in flight),
    `StepDone` (confirmed), `StepFailed reason` (last revert reason).

-}
type alias Step =
    { label : String
    , state : StepState
    }


{-| Lifecycle of a single step in a multi-step sequence.

`StepFailed` carries the revert / wallet reason so the user sees a
specific message — useful for the post-approve, mid-call failure mode
(approve confirms, then the call reverts and the approve toast already
faded). The multi-step overlay keeps the full sequence visible until
the user dismisses it or starts a new tx.

-}
type StepState
    = StepPending
    | StepActive
    | StepDone
    | StepFailed String


{-| Render a vertical stack of steps with the active one spinning.
Renders an empty node if every step is `StepPending` AND the overall
`currentStatus` is `Tx.Idle` (nothing is happening yet — caller can
keep the overlay inert without a per-page conditional).

CSS classes: `web3-pending-overlay`, `web3-pending-overlay-multi`,
`web3-pending-step`, `web3-pending-step--pending` /
`--active` / `--done` / `--failed`, `web3-pending-step-glyph`,
`web3-pending-step-label`, `web3-pending-step-reason`.

-}
viewMultiStep :
    List (Html.Attribute msg)
    -> { steps : List Step, currentStatus : Tx.Status }
    -> Html msg
viewMultiStep attrs opts =
    let
        everyPending =
            List.all (\s -> s.state == StepPending) opts.steps

        idleAndPending =
            everyPending && opts.currentStatus == Tx.Idle
    in
    if idleAndPending then
        Html.text ""

    else
        Html.div
            (Attr.class "web3-pending-overlay web3-pending-overlay-multi" :: attrs)
            [ Html.div
                [ Attr.class "web3-pending-overlay-inner" ]
                (List.map renderStep opts.steps)
            ]


renderStep : Step -> Html msg
renderStep step =
    let
        ( modifier, glyph ) =
            case step.state of
                StepPending ->
                    ( "pending", "·" )

                StepActive ->
                    ( "active", "" )

                StepDone ->
                    ( "done", "\u{2713}" )

                StepFailed _ ->
                    ( "failed", "\u{2715}" )

        glyphNode =
            case step.state of
                StepActive ->
                    Html.div [ Attr.class "web3-pending-spinner" ] []

                _ ->
                    Html.span [ Attr.class "web3-pending-step-glyph" ] [ Html.text glyph ]

        reasonNode =
            case step.state of
                StepFailed reason ->
                    Html.p [ Attr.class "web3-pending-step-reason" ] [ Html.text reason ]

                _ ->
                    Html.text ""
    in
    Html.div
        [ Attr.class ("web3-pending-step web3-pending-step--" ++ modifier) ]
        [ glyphNode
        , Html.p [ Attr.class "web3-pending-step-label" ] [ Html.text step.label ]
        , reasonNode
        ]
