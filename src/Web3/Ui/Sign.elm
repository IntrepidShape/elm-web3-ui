module Web3.Ui.Sign exposing
    ( stateView
    , signButton
    , signatureView
    )

{-| Signing lifecycle UI components.

Pattern-match on `Sign.SignState` to render sign request status without missing
any state.

    -- Display current sign state:
    Web3.Ui.Sign.stateView [] model.signState

    -- Sign button disabled while pending:
    Web3.Ui.Sign.signButton []
        { label = "Sign Permit", onSign = RequestSign }
        model.signState

    -- Display the signature once signed:
    Web3.Ui.Sign.signatureView [] model.signState

@docs stateView, signButton, signatureView

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Web3.Sign as Sign


{-| Displays the sign lifecycle state as a labelled span.

Labels: "Idle" / "Waiting for signature…" / "Signed" / "Failed: <err>" / "Rejected"

CSS class: `web3-sign-state`

-}
stateView :
    List (Html.Attribute msg)
    -> Sign.SignState
    -> Html msg
stateView attrs state =
    let
        label =
            case state of
                Sign.SignIdle ->
                    "Idle"

                Sign.SignPending _ ->
                    "Waiting for signature…"

                Sign.Signed _ _ ->
                    "Signed"

                Sign.SignFailed _ err ->
                    "Failed: " ++ err

                Sign.SignRejected _ ->
                    "Rejected"
    in
    Html.span
        (Attr.class "web3-sign-state" :: attrs)
        [ Html.text label ]


{-| A sign button that is active in `SignIdle` and terminal states, and disabled
while `SignPending`.

CSS class: `web3-sign-btn`

-}
signButton :
    List (Html.Attribute msg)
    -> { label : String, onSign : msg }
    -> Sign.SignState
    -> Html msg
signButton attrs opts state =
    let
        isPending =
            case state of
                Sign.SignPending _ ->
                    True

                _ ->
                    False
    in
    Html.button
        ([ Attr.class "web3-sign-btn"
         , Attr.disabled isPending
         , Events.onClick opts.onSign
         ]
            ++ attrs
        )
        [ Html.text opts.label ]


{-| Displays the signature value when in the `Signed` state.

Returns an empty text node for all other states — safe to always render.

CSS classes: `web3-signature` (wrapper div), `web3-signature-value` (code element)

-}
signatureView :
    List (Html.Attribute msg)
    -> Sign.SignState
    -> Html msg
signatureView attrs state =
    case state of
        Sign.Signed _ sig ->
            Html.div
                (Attr.class "web3-signature" :: attrs)
                [ Html.code [ Attr.class "web3-signature-value" ]
                    [ Html.text sig ]
                ]

        _ ->
            Html.text ""
