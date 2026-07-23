module Web3.Ui.RemoteCall exposing
    ( RemoteCall(..)
    , notAsked, request, resolve, reset
    , map, withDefault, toMaybe, isLoading, correlationId
    , view, Slots
    )

{-| The remote-data type for correlation-id port round-trips -- the missing
foundation under every read in a dapp.

Every elm-web3 read (balance, contract call, fee, block...) is fire-and-forget
through a port, matched back by a correlation id. Modelling each one by hand
means every dapp reinvents `Maybe (Result String a)` plus an in-flight flag
plus id bookkeeping. `RemoteCall` is that shape, once, with the id
bookkeeping built in:

    type alias Model =
        { reserves : RemoteCall Reserves }

    -- fire
    ( { model | reserves = RemoteCall.request "reserves-1" model.reserves }
    , web3Cmd (Call.encode reservesCall)
    )

    -- resolve (ONLY applies if the id matches the one in flight --
    -- a stale response for an earlier request cannot clobber a newer one)
    { model | reserves = RemoteCall.resolve incomingId result model.reserves }

    -- render
    RemoteCall.view
        { skeleton = Skeleton.line []
        , failed = \\err -> Html.text err
        }
        viewReserves
        model.reserves

The id guard follows the same rule the `Web3.Sign` machine proves in
elm-web3's `SignSpec.tla`: a response for a different correlation id never
completes the pending call.

@docs RemoteCall
@docs notAsked, request, resolve, reset
@docs map, withDefault, toMaybe, isLoading, correlationId
@docs view, Slots

-}

import Html exposing (Html)
import Html.Attributes as Attr


{-| The four honest states of a port round-trip. `Loading` carries the
correlation id of the request in flight.
-}
type RemoteCall a
    = NotAsked
    | Loading String
    | Ready a
    | Failed String


{-| The initial state. -}
notAsked : RemoteCall a
notAsked =
    NotAsked


{-| Mark a request in flight under the given correlation id. Always
transitions -- firing a new request supersedes whatever came before, and its
id becomes the only one `resolve` will accept.
-}
request : String -> RemoteCall a -> RemoteCall a
request id _ =
    Loading id


{-| Apply a response -- but only if its correlation id matches the request in
flight. A stale or misrouted response (an earlier request answered late,
another component's id) is dropped on the floor, never shown as fresh data.
-}
resolve : String -> Result String a -> RemoteCall a -> RemoteCall a
resolve id result call =
    case call of
        Loading pendingId ->
            if pendingId == id then
                case result of
                    Ok a ->
                        Ready a

                    Err err ->
                        Failed err

            else
                call

        _ ->
            call


{-| Back to `NotAsked` (e.g. on wallet disconnect or chain switch, when the
data no longer describes anything).
-}
reset : RemoteCall a -> RemoteCall a
reset _ =
    NotAsked


{-| Transform the value inside `Ready`. -}
map : (a -> b) -> RemoteCall a -> RemoteCall b
map fn call =
    case call of
        Ready a ->
            Ready (fn a)

        NotAsked ->
            NotAsked

        Loading id ->
            Loading id

        Failed err ->
            Failed err


{-| The value, or a fallback. -}
withDefault : a -> RemoteCall a -> a
withDefault fallback call =
    case call of
        Ready a ->
            a

        _ ->
            fallback


{-| `Just` the value when `Ready`. -}
toMaybe : RemoteCall a -> Maybe a
toMaybe call =
    case call of
        Ready a ->
            Just a

        _ ->
            Nothing


{-| True while a request is in flight. -}
isLoading : RemoteCall a -> Bool
isLoading call =
    case call of
        Loading _ ->
            True

        _ ->
            False


{-| The correlation id in flight, if any. -}
correlationId : RemoteCall a -> Maybe String
correlationId call =
    case call of
        Loading id ->
            Just id

        _ ->
            Nothing


{-| What to render for the non-`Ready` states. `NotAsked` renders the
skeleton too -- from the user's point of view "not fetched yet" and
"fetching" look the same.
-}
type alias Slots msg =
    { skeleton : Html msg
    , failed : String -> Html msg
    }


{-| Render a `RemoteCall`, wrapped in a `<div class="web3-remote">` whose
modifier tracks the state -- `--loading` carries `aria-busy="true"` so
assistive tech knows the region is settling.

CSS classes: `web3-remote`, `web3-remote--loading`, `web3-remote--ready`,
`web3-remote--failed`.

-}
view : Slots msg -> (a -> Html msg) -> RemoteCall a -> Html msg
view slots ready call =
    case call of
        Ready a ->
            Html.div [ Attr.class "web3-remote web3-remote--ready" ]
                [ ready a ]

        Failed err ->
            Html.div [ Attr.class "web3-remote web3-remote--failed" ]
                [ slots.failed err ]

        _ ->
            Html.div
                [ Attr.class "web3-remote web3-remote--loading"
                , Attr.attribute "aria-busy" "true"
                ]
                [ slots.skeleton ]
