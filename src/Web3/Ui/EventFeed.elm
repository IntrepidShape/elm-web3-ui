module Web3.Ui.EventFeed exposing
    ( Feed, Status(..)
    , init, onSubscribed, push, items, status, closed
    , view, Config
    )

{-| A live on-chain event feed — the binder between `Web3.Subscription` log
streams and rendered rows.

The port layer answers a subscription request with
`{ tag = "subscribed", status = "open" | "failed" }` — `failed` meaning the
WebSocket was unavailable and the bridge fell back to polling, so events
still flow, just with more latency. The `Feed` tracks that honestly (a
`Fallback` chip, not a lie of liveness), keeps items newest-first, and
enforces a cap so a hot contract can't grow your model without bound.

    -- MODEL
    { feed : EventFeed.Feed TokenCreated }

    -- port `subscribed` for our correlation id:
    { model | feed = EventFeed.onSubscribed { open = ok } model.feed }

    -- each decoded LogEvent:
    { model | feed = EventFeed.push tokenCreated model.feed }

    -- VIEW
    EventFeed.view
        { onLoadMore = Just LoadOlder }   -- app fires a getLogs range query
        viewTokenCreated
        model.feed

Generic over the item type — the app decodes its own events; this module
never guesses at your ABI.

CSS classes: `web3-eventfeed`, `web3-eventfeed__status`,
`web3-eventfeed__status--connecting/--live/--fallback/--closed`,
`web3-eventfeed__list`, `web3-eventfeed__more`.

@docs Feed, Status
@docs init, onSubscribed, push, items, status, closed
@docs view, Config

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events


{-| Where the stream stands. `Fallback` = events arrive by polling. -}
type Status
    = Connecting
    | Live
    | Fallback
    | Closed


{-| The feed. Opaque — the cap and ordering are invariants, not suggestions. -}
type Feed item
    = Feed
        { status : Status
        , entries : List item
        , cap : Int
        }


{-| A feed awaiting its subscription confirmation. Caps below 1 are lifted
to 1 — a feed that can hold nothing is not a feed.
-}
init : { cap : Int } -> Feed item
init opts =
    Feed { status = Connecting, entries = [], cap = max 1 opts.cap }


{-| Apply the port's `subscribed` answer: `open = True` → `Live`,
`open = False` → `Fallback` (the bridge is polling; events still flow).
-}
onSubscribed : { open : Bool } -> Feed item -> Feed item
onSubscribed { open } (Feed f) =
    Feed
        { f
            | status =
                if open then
                    Live

                else
                    Fallback
        }


{-| Mark the stream closed (unwatch / teardown). -}
closed : Feed item -> Feed item
closed (Feed f) =
    Feed { f | status = Closed }


{-| Prepend an event. The oldest entries fall off past the cap. -}
push : item -> Feed item -> Feed item
push item (Feed f) =
    Feed { f | entries = List.take f.cap (item :: f.entries) }


{-| Newest first. -}
items : Feed item -> List item
items (Feed f) =
    f.entries


{-| -}
status : Feed item -> Status
status (Feed f) =
    f.status


{-| -}
type alias Config msg =
    { onLoadMore : Maybe msg
    }


{-| Render the feed: status chip, `aria-live` list, optional load-more.
-}
view : Config msg -> (item -> Html msg) -> Feed item -> Html msg
view cfg viewItem (Feed f) =
    let
        ( modifier, label ) =
            case f.status of
                Connecting ->
                    ( "connecting", "connecting…" )

                Live ->
                    ( "live", "live" )

                Fallback ->
                    ( "fallback", "polling" )

                Closed ->
                    ( "closed", "closed" )

        more =
            case cfg.onLoadMore of
                Just msg ->
                    [ Html.button
                        [ Attr.class "web3-eventfeed__more", Events.onClick msg ]
                        [ Html.text "Load older" ]
                    ]

                Nothing ->
                    []
    in
    Html.div [ Attr.class "web3-eventfeed" ]
        (Html.span
            [ Attr.class "web3-eventfeed__status"
            , Attr.class ("web3-eventfeed__status--" ++ modifier)
            , Attr.attribute "role" "status"
            ]
            [ Html.text label ]
            :: Html.ol
                [ Attr.class "web3-eventfeed__list"
                , Attr.attribute "aria-live" "polite"
                ]
                (List.map (\i -> Html.li [] [ viewItem i ]) f.entries)
            :: more
        )
