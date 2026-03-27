module Web3.Ui.Transaction exposing
    ( statusBadge
    , actionButton
    , txHashLink
    , statusHashLink
    , receiptView
    )

{-| Transaction lifecycle UI components.

Pattern-match on `Tx.Status` to render appropriate UI without missing any state.

    -- Status badge with modifier class:
    Web3.Ui.Transaction.statusBadge [] tx.status

    -- Action button disabled while in-flight:
    Web3.Ui.Transaction.actionButton []
        { label = "Buy", pendingLabel = "Buying…", onPress = SubmitBuy }
        tx.status

    -- Clickable tx hash link:
    Web3.Ui.Transaction.txHashLink []
        { explorerUrl = "https://etherscan.io/tx/" }
        hash

    -- Hash link extracted from status (Nothing when no hash available):
    Web3.Ui.Transaction.statusHashLink []
        { explorerUrl = "https://etherscan.io/tx/" }
        tx.status

    -- Confirmed receipt display:
    Web3.Ui.Transaction.receiptView []
        { explorerUrl = "https://etherscan.io/tx/" }
        receipt

@docs statusBadge, actionButton, txHashLink, statusHashLink, receiptView

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Web3.Transaction as Tx
import Web3.Types as T


{-| A status badge for the current transaction state.

Labels: "Idle" / "Awaiting Signature" / "Pending" / "Confirming" / "Confirmed" / "Failed" / "Rejected"

CSS classes: `web3-tx-badge` plus one of:
`web3-tx-badge--idle`, `web3-tx-badge--pending`, `web3-tx-badge--confirmed`,
`web3-tx-badge--failed`, `web3-tx-badge--rejected`

-}
statusBadge :
    List (Html.Attribute msg)
    -> Tx.Status
    -> Html msg
statusBadge attrs status =
    let
        ( label, modifier ) =
            case status of
                Tx.Idle ->
                    ( "Idle", "web3-tx-badge--idle" )

                Tx.AwaitingSignature ->
                    ( "Awaiting Signature", "web3-tx-badge--pending" )

                Tx.Submitted _ ->
                    ( "Pending", "web3-tx-badge--pending" )

                Tx.Confirming _ n ->
                    ( "Confirming (" ++ String.fromInt n ++ ")", "web3-tx-badge--pending" )

                Tx.Confirmed _ ->
                    ( "Confirmed", "web3-tx-badge--confirmed" )

                Tx.Failed _ ->
                    ( "Failed", "web3-tx-badge--failed" )

                Tx.Rejected ->
                    ( "Rejected", "web3-tx-badge--rejected" )
    in
    Html.span
        (Attr.class "web3-tx-badge" :: Attr.class modifier :: attrs)
        [ Html.text label ]


{-| An action button that is active in `Idle` and terminal states, and disabled
while in-flight (`AwaitingSignature`, `Submitted`, `Confirming`).

Shows `pendingLabel` while the transaction is in-flight.

CSS classes: `web3-action-btn`, `web3-action-btn--pending` (added when disabled)

-}
actionButton :
    List (Html.Attribute msg)
    -> { label : String, pendingLabel : String, onPress : msg }
    -> Tx.Status
    -> Html msg
actionButton attrs opts status =
    let
        inFlight =
            Tx.isPending status

        label =
            if inFlight then
                opts.pendingLabel

            else
                opts.label

        baseAttrs =
            [ Attr.class "web3-action-btn"
            , Attr.disabled inFlight
            ]

        pendingAttr =
            if inFlight then
                [ Attr.class "web3-action-btn--pending" ]

            else
                [ Events.onClick opts.onPress ]
    in
    Html.button
        (baseAttrs ++ pendingAttr ++ attrs)
        [ Html.text label ]


{-| A clickable link displaying a truncated tx hash.

The `explorerUrl` is prepended to the full hash to build the href.
Example: `{ explorerUrl = "https://etherscan.io/tx/" }`

CSS class: `web3-tx-link`

-}
txHashLink :
    List (Html.Attribute msg)
    -> { explorerUrl : String }
    -> T.TxHash
    -> Html msg
txHashLink attrs opts hash =
    let
        full =
            T.txHashToString hash

        short =
            String.left 6 full ++ "…" ++ String.right 4 full
    in
    Html.a
        (Attr.class "web3-tx-link"
            :: Attr.href (opts.explorerUrl ++ full)
            :: Attr.target "_blank"
            :: Attr.rel "noopener noreferrer"
            :: attrs
        )
        [ Html.text short ]


{-| Extract a hash link from a `Tx.Status`. Returns `Nothing` when there is no
hash (Idle, AwaitingSignature, Failed, Rejected).

Delegates to `txHashLink` so truncation, `rel`, and `target` stay in one place.

-}
statusHashLink :
    List (Html.Attribute msg)
    -> { explorerUrl : String }
    -> Tx.Status
    -> Maybe (Html msg)
statusHashLink attrs opts status =
    case status of
        Tx.Submitted hash ->
            Just (txHashLink attrs opts hash)

        Tx.Confirming hash _ ->
            Just (txHashLink attrs opts hash)

        Tx.Confirmed receipt ->
            Just (txHashLink attrs opts receipt.txHash)

        _ ->
            Nothing


{-| Display a confirmed transaction receipt.

Root element: `<div class="web3-receipt web3-receipt--success|failed">`

Each field is wrapped in `<div class="web3-receipt-field">`.

CSS classes: `web3-receipt`, `web3-receipt--success`, `web3-receipt--failed`, `web3-receipt-field`

-}
receiptView :
    List (Html.Attribute msg)
    -> { explorerUrl : String }
    -> Tx.Receipt
    -> Html msg
receiptView attrs opts receipt =
    let
        modifier =
            if receipt.status then
                "web3-receipt--success"

            else
                "web3-receipt--failed"
    in
    Html.div
        (Attr.class "web3-receipt" :: Attr.class modifier :: attrs)
        [ Html.div [ Attr.class "web3-receipt-field" ]
            [ Html.text ("Block: " ++ String.fromInt receipt.blockNumber) ]
        , Html.div [ Attr.class "web3-receipt-field" ]
            [ Html.text ("Gas used: " ++ receipt.gasUsed) ]
        , Html.div [ Attr.class "web3-receipt-field" ]
            [ txHashLink [] opts receipt.txHash ]
        ]
