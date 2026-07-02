module Web3.Ui.SimulateFirst exposing
    ( Step(..)
    , start, onSimResult, confirm, onTx, reset
    , view, Config
    )

{-| Simulate-then-send: preview a write's outcome before asking for a
signature. The structural guarantee, in the family of
[`ApprovalFlow`](Web3-Ui-ApprovalFlow): **a transaction cannot be sent
without a completed simulation** — `confirm` is the only door into
`Sending`, and it only opens from `Previewing`.

elm-web3 already has the capability: `Contract.Call.withFrom` runs the
write's calldata as an `eth_call` from the user's address, returning what
the transaction *would* do (or its revert) for free.

    -- user clicks the primary button:
    ( { model | sim = SimulateFirst.start model.sim }
    , web3Cmd (Call.encode simulatedCall)      -- readCall withFrom
    )

    -- simulation answer (callResult or failed for our id):
    { model | sim = SimulateFirst.onSimResult (Ok decodedPreview) model.sim }

    -- user confirms the previewed outcome:
    ( { model | sim = SimulateFirst.confirm model.sim }
    , web3Cmd (Send.encode theRealWrite)
    )

    -- tx lifecycle:
    { model | sim = SimulateFirst.onTx txMsg model.sim }

Wallet rejection is not failure: rejecting the signature returns to
`Previewing` — the preview is still true; the user just declined.

CSS classes: `web3-simulate`, `web3-simulate--idle/--simulating/--preview/
--sending/--done/--refused`, `web3-simulate__preview`,
`web3-simulate__button`, `web3-simulate__error`.

@docs Step
@docs start, onSimResult, confirm, onTx, reset
@docs view, Config

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Web3.Transaction as Tx


{-| `Previewing` carries the simulated outcome (already decoded/rendered to
a string by the app); `Refused` carries the reason (simulation revert, tx
failure).
-}
type Step
    = Idle
    | Simulating
    | Previewing String
    | Sending String Tx.Status
    | Done Tx.Receipt
    | Refused String


{-| `Idle -> Simulating` (fire the simulation). No-op elsewhere. -}
start : Step -> Step
start step =
    case step of
        Idle ->
            Simulating

        _ ->
            step


{-| Apply the simulation's answer. Only meaningful in `Simulating`. -}
onSimResult : Result String String -> Step -> Step
onSimResult result step =
    case step of
        Simulating ->
            case result of
                Ok preview ->
                    Previewing preview

                Err err ->
                    Refused err

        _ ->
            step


{-| `Previewing -> Sending AwaitingSignature` — the only door into
`Sending`; unreachable without a completed simulation.
-}
confirm : Step -> Step
confirm step =
    case step of
        Previewing preview ->
            Sending preview Tx.AwaitingSignature

        _ ->
            step


{-| Drive the inner transaction. Only meaningful in `Sending`:
confirmed → `Done`, failed → `Refused`, wallet-rejected → back to
`Previewing` (the preview is still valid).
-}
onTx : Tx.Msg -> Step -> Step
onTx txMsg step =
    case step of
        Sending preview status ->
            case Tx.update txMsg status of
                Tx.Confirmed receipt ->
                    Done receipt

                Tx.Failed err ->
                    Refused err

                Tx.Rejected ->
                    -- The preview is still true; the user just declined.
                    Previewing preview

                inFlight ->
                    Sending preview inFlight

        _ ->
            step


{-| `Done`/`Refused` -> `Idle`. No-op elsewhere. -}
reset : Step -> Step
reset step =
    case step of
        Done _ ->
            Idle

        Refused _ ->
            Idle

        _ ->
            step


{-| -}
type alias Config msg =
    { simulateLabel : String
    , confirmLabel : String
    , onStart : msg
    , onConfirm : msg
    , onReset : msg
    }


{-| The one valid control per step, plus the preview/receipt/error surface. -}
view : Config msg -> Step -> Html msg
view cfg step =
    let
        ( modifier, body ) =
            case step of
                Idle ->
                    ( "idle", [ button [ Events.onClick cfg.onStart ] cfg.simulateLabel ] )

                Simulating ->
                    ( "simulating"
                    , [ button [ Attr.disabled True, Attr.attribute "aria-busy" "true" ] cfg.simulateLabel ]
                    )

                Previewing preview ->
                    ( "preview"
                    , [ Html.p [ Attr.class "web3-simulate__preview" ] [ Html.text preview ]
                      , button [ Events.onClick cfg.onConfirm ] cfg.confirmLabel
                      ]
                    )

                Sending _ _ ->
                    ( "sending"
                    , [ button [ Attr.disabled True, Attr.attribute "aria-busy" "true" ] cfg.confirmLabel ]
                    )

                Done _ ->
                    ( "done", [ button [ Events.onClick cfg.onReset ] "Done" ] )

                Refused err ->
                    ( "refused"
                    , [ Html.p [ Attr.class "web3-simulate__error" ] [ Html.text err ]
                      , button [ Events.onClick cfg.onReset ] "Start over"
                      ]
                    )
    in
    Html.div
        [ Attr.class "web3-simulate"
        , Attr.class ("web3-simulate--" ++ modifier)
        ]
        body


button : List (Html.Attribute msg) -> String -> Html msg
button extra label =
    Html.button (Attr.class "web3-simulate__button" :: extra) [ Html.text label ]
