module Web3.Ui.TxQueue exposing
    ( TxQueue, empty
    , begin, update, dismiss
    , pendingCount, entries
    , toastStack, Config
    )

{-| Many transactions in flight, without Model gymnastics.

A `TxQueue` is a labelled collection of `Tx.Status` machines keyed by
correlation id. `begin` when the user acts, route each port `Tx.Msg` to its
id with `update`, render the whole thing as a toast stack:

    type alias Model =
        { txs : TxQueue }

    -- user clicks buy:
    { model | txs = TxQueue.begin "buy-42" "Buy 1.2M FOO" model.txs }

    -- port message for a tx:
    { model | txs = TxQueue.update incomingId txMsg model.txs }

    -- in view:
    TxQueue.toastStack
        { onDismiss = DismissTx
        , explorerUrl = Just "https://scan.pulsechain.com/tx/"
        }
        model.txs

Every entry is a full `Web3.Transaction` state machine, so all its
guarantees hold per-transaction (terminal absorbing, monotonic
confirmations) -- and because messages are routed by id, one transaction's
late confirmation can never touch another's state.

CSS classes: `web3-txq`, `web3-txq__toast`, `web3-txq__toast--pending`,
`--confirmed`, `--failed`, `web3-txq__label`, `web3-txq__status`,
`web3-txq__dismiss`.

@docs TxQueue, empty
@docs begin, update, dismiss
@docs pendingCount, entries
@docs toastStack, Config

-}

import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Web3.Transaction as Tx
import Web3.Ui.Transaction as TxUi


{-| The queue. Opaque; read it through [`entries`](#entries) /
[`pendingCount`](#pendingCount).
-}
type TxQueue
    = TxQueue (Dict String { label : String, status : Tx.Status })


{-| No transactions. -}
empty : TxQueue
empty =
    TxQueue Dict.empty


{-| Start tracking a transaction under a correlation id, with a
human-readable label ("Approve FOO", "Stake 50k"). Starts in
`AwaitingSignature` -- call it when you fire the write.
-}
begin : String -> String -> TxQueue -> TxQueue
begin id label (TxQueue d) =
    TxQueue (Dict.insert id { label = label, status = Tx.AwaitingSignature } d)


{-| Route a port `Tx.Msg` to the transaction it belongs to. Unknown ids are
ignored -- a message for a transaction you never began (or already dismissed)
cannot create ghost entries.
-}
update : String -> Tx.Msg -> TxQueue -> TxQueue
update id msg (TxQueue d) =
    TxQueue
        (Dict.update id
            (Maybe.map (\e -> { e | status = Tx.update msg e.status }))
            d
        )


{-| Remove an entry (the toast's x button). -}
dismiss : String -> TxQueue -> TxQueue
dismiss id (TxQueue d) =
    TxQueue (Dict.remove id d)


{-| How many transactions are still in flight. -}
pendingCount : TxQueue -> Int
pendingCount (TxQueue d) =
    Dict.foldl
        (\_ e n ->
            if Tx.isPending e.status then
                n + 1

            else
                n
        )
        0
        d


{-| Every entry, id-ordered -- for custom renderings. -}
entries : TxQueue -> List ( String, { label : String, status : Tx.Status } )
entries (TxQueue d) =
    Dict.toList d


{-| -}
type alias Config msg =
    { onDismiss : String -> msg
    , explorerUrl : Maybe String
    }


{-| Render the queue as a stack of toasts (`aria-live="polite"` -- status
changes are announced without stealing focus). Empty queue renders an empty
container, so the stack can be styled `position: fixed` unconditionally.
-}
toastStack : Config msg -> TxQueue -> Html msg
toastStack cfg queue =
    Html.div
        [ Attr.class "web3-txq"
        , Attr.attribute "aria-live" "polite"
        ]
        (List.map (toast cfg) (entries queue))


toast : Config msg -> ( String, { label : String, status : Tx.Status } ) -> Html msg
toast cfg ( id, e ) =
    let
        modifier =
            case e.status of
                Tx.Confirmed _ ->
                    "confirmed"

                Tx.Failed _ ->
                    "failed"

                Tx.Rejected ->
                    "failed"

                _ ->
                    "pending"
    in
    Html.div
        [ Attr.class "web3-txq__toast"
        , Attr.class ("web3-txq__toast--" ++ modifier)
        ]
        [ Html.span [ Attr.class "web3-txq__label" ] [ Html.text e.label ]
        , Html.span [ Attr.class "web3-txq__status" ]
            [ TxUi.statusBadge [] e.status ]
        , Maybe.withDefault (Html.text "")
            (TxUi.statusHashLink [] { explorerUrl = cfg.explorerUrl } e.status)
        , Html.button
            [ Attr.class "web3-txq__dismiss"
            , Attr.attribute "aria-label" ("Dismiss " ++ e.label)
            , Events.onClick (cfg.onDismiss id)
            ]
            [ Html.text "×" ]
        ]
