module Web3.Ui.BlockRefresh exposing
    ( Policy(..), Ticker
    , init, withPolicy, onBlock, markRefreshed
    )

{-| A refresh policy for chain-derived data — the missing piece between
`Block.watchBlockNumber` and your `RemoteCall`s.

Chain data goes stale exactly once per block, so refetch cadence should be
expressed in blocks, not milliseconds:

    type alias Model =
        { ticker : BlockRefresh.Ticker
        , balance : RemoteCall String
        }

    -- init
    { ticker = BlockRefresh.init (EveryNBlocks 5), ... }

    -- on each { tag = "blockNumber" } port message:
    let
        ( ticker, refetch ) =
            BlockRefresh.onBlock number model.ticker
    in
    if refetch then
        ( { model | ticker = BlockRefresh.markRefreshed number ticker
          , balance = RemoteCall.request "bal-..." model.balance }
        , web3Cmd (Balance.encode ...)
        )
    else
        ( { model | ticker = ticker }, Cmd.none )

That worked example IS the balance watcher: balances re-read on-cadence,
driven by chain time. Any `RemoteCall` slots in the same way.

@docs Policy, Ticker
@docs init, withPolicy, onBlock, markRefreshed

-}


{-| `EveryBlock` — refetch on every new block. `EveryNBlocks n` — refetch
when at least `n` blocks have passed since the last refresh. `Manual` —
never fire from block signals (the app refetches explicitly).
-}
type Policy
    = EveryBlock
    | EveryNBlocks Int
    | Manual


{-| Tracks the policy and the block height of the last refresh. Opaque. -}
type Ticker
    = Ticker
        { policy : Policy
        , lastRefreshedAt : Maybe Int
        }


{-| -}
init : Policy -> Ticker
init policy =
    Ticker { policy = policy, lastRefreshedAt = Nothing }


{-| Change cadence, keeping the last-refreshed watermark. -}
withPolicy : Policy -> Ticker -> Ticker
withPolicy policy (Ticker t) =
    Ticker { t | policy = policy }


{-| Feed a new block number in; the `Bool` says "fire your refetch now".
The first observed block always fires (except under `Manual`) — data that
has never been fetched is infinitely stale.
-}
onBlock : Int -> Ticker -> ( Ticker, Bool )
onBlock number ((Ticker t) as ticker) =
    let
        due =
            case ( t.policy, t.lastRefreshedAt ) of
                ( Manual, _ ) ->
                    False

                ( _, Nothing ) ->
                    True

                ( EveryBlock, Just last ) ->
                    number > last

                ( EveryNBlocks n, Just last ) ->
                    number - last >= max 1 n
    in
    ( ticker, due )


{-| Record that the refetch was actually fired at this height. Separate from
[`onBlock`](#onBlock) so a refetch you decided to skip (e.g. one already in
flight) doesn't advance the watermark.
-}
markRefreshed : Int -> Ticker -> Ticker
markRefreshed number (Ticker t) =
    Ticker { t | lastRefreshedAt = Just number }
