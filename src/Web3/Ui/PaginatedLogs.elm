module Web3.Ui.PaginatedLogs exposing
    ( Pager, Range
    , init, next, onLoaded, exhausted, loadedCount
    , loadMoreButton, Config
    )

{-| Block-range windowed `eth_getLogs` paging -- newest window first, walking
back toward genesis without overlaps or gaps.

    -- start: latest window
    ( pager, range ) =
        PaginatedLogs.init { latest = 21688204, window = 5000 }
    -- fire getLogs for range.fromBlock..range.toBlock, then:
    pager2 = PaginatedLogs.onLoaded (List.length logs) pager

    -- "Load older" click:
    case PaginatedLogs.next pager2 of
        Just ( pager3, olderRange ) -> fire the next query
        Nothing -> at genesis; nothing older exists

Ranges tile exactly: `[latest-window+1 .. latest]`, then
`[latest-2w+1 .. latest-w]`, ... clamped at 0.

CSS classes: `web3-pagedlogs__more`.

@docs Pager, Range
@docs init, next, onLoaded, exhausted, loadedCount
@docs loadMoreButton, Config

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events


{-| An inclusive block range for one `getLogs` query. -}
type alias Range =
    { fromBlock : Int, toBlock : Int }


{-| Opaque paging state. -}
type Pager
    = Pager
        { nextTo : Maybe Int -- toBlock of the NEXT (older) window; Nothing = exhausted
        , window : Int
        , loaded : Int
        }


{-| The newest window. `window` is clamped to >= 1. -}
init : { latest : Int, window : Int } -> ( Pager, Range )
init opts =
    let
        w =
            max 1 opts.window

        from =
            max 0 (opts.latest - w + 1)
    in
    ( Pager
        { nextTo =
            if from == 0 then
                Nothing

            else
                Just (from - 1)
        , window = w
        , loaded = 0
        }
    , { fromBlock = from, toBlock = opts.latest }
    )


{-| The next older window, or `Nothing` at genesis. -}
next : Pager -> Maybe ( Pager, Range )
next (Pager p) =
    p.nextTo
        |> Maybe.map
            (\to ->
                let
                    from =
                        max 0 (to - p.window + 1)
                in
                ( Pager
                    { p
                        | nextTo =
                            if from == 0 then
                                Nothing

                            else
                                Just (from - 1)
                    }
                , { fromBlock = from, toBlock = to }
                )
            )


{-| Record how many logs a window returned (display/telemetry). -}
onLoaded : Int -> Pager -> Pager
onLoaded count (Pager p) =
    Pager { p | loaded = p.loaded + max 0 count }


{-| True once the walk reached genesis. -}
exhausted : Pager -> Bool
exhausted (Pager p) =
    p.nextTo == Nothing


{-| Total logs recorded via [`onLoaded`](#onLoaded). -}
loadedCount : Pager -> Int
loadedCount (Pager p) =
    p.loaded


{-| What the load-more button says and what it fires. -}
type alias Config msg =
    { onLoadMore : msg
    , label : String
    }


{-| A load-more button that disappears at genesis.

At genesis the whole button is gone, so there is no element left to carry
`attrs` -- the same convention as
[`Web3.Ui.PendingOverlay.conditionalView`](Web3-Ui-PendingOverlay#conditionalView).
Style the surrounding slot, not this node, if you need a stable box.

-}
loadMoreButton : List (Html.Attribute msg) -> Config msg -> Pager -> Html msg
loadMoreButton attrs cfg pager =
    if exhausted pager then
        Html.text ""

    else
        Html.button
            (Attr.class "web3-pagedlogs__more"
                :: Events.onClick cfg.onLoadMore
                :: attrs
            )
            [ Html.text cfg.label ]
