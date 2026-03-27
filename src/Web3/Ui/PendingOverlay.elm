module Web3.Ui.PendingOverlay exposing
    ( view
    , conditionalView
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

@docs view, conditionalView

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
        (Attr.class "web3-pending-overlay" :: attrs)
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
