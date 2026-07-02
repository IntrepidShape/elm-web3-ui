module FlowGenericsTest exposing (suite)

{-| Structural invariants of the four flow generics. -}

import Expect
import Fuzz exposing (Fuzzer)
import Test exposing (..)
import Web3.Transaction as Tx
import Web3.Ui.BlockRefresh as BR
import Web3.Ui.EventFeed as EF
import Web3.Ui.PaginatedLogs as PL
import Web3.Ui.SimulateFirst as SF


suite : Test
suite =
    describe "flow generics"
        [ eventFeedTests, blockRefreshTests, simulateFirstTests, pagedLogsTests ]


eventFeedTests : Test
eventFeedTests =
    describe "EventFeed"
        [ fuzz2 (Fuzz.intRange 1 20) (Fuzz.list Fuzz.int) "cap is never exceeded; newest first" <|
            \cap xs ->
                let
                    feed =
                        List.foldl EF.push (EF.init { cap = cap }) xs

                    kept =
                        EF.items feed
                in
                ( List.length kept <= cap
                , kept == List.take cap (List.reverse xs)
                )
                    |> Expect.equal ( True, True )
        , test "subscribed open->Live, failed->Fallback, closed->Closed" <|
            \_ ->
                let
                    f0 =
                        EF.init { cap = 5 }
                in
                [ EF.status (EF.onSubscribed { open = True } f0)
                , EF.status (EF.onSubscribed { open = False } f0)
                , EF.status (EF.closed f0)
                ]
                    |> Expect.equal [ EF.Live, EF.Fallback, EF.Closed ]
        ]


blockRefreshTests : Test
blockRefreshTests =
    describe "BlockRefresh"
        [ fuzz (Fuzz.intRange 0 1000000) "Manual never fires" <|
            \n ->
                BR.onBlock n (BR.init BR.Manual)
                    |> Tuple.second
                    |> Expect.equal False
        , fuzz (Fuzz.intRange 0 1000000) "first observed block fires (non-Manual)" <|
            \n ->
                BR.onBlock n (BR.init BR.EveryBlock)
                    |> Tuple.second
                    |> Expect.equal True
        , fuzz2 (Fuzz.intRange 1 50) (Fuzz.intRange 0 200) "EveryNBlocks fires exactly when the gap reaches N" <|
            \n gap ->
                let
                    ticker =
                        BR.init (BR.EveryNBlocks n) |> BR.markRefreshed 1000
                in
                BR.onBlock (1000 + gap) ticker
                    |> Tuple.second
                    |> Expect.equal (gap >= n)
        ]


simMsgFuzzer : Fuzzer (SF.Step -> SF.Step)
simMsgFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant SF.start
        , Fuzz.map SF.onSimResult
            (Fuzz.oneOf [ Fuzz.map Ok Fuzz.string, Fuzz.map Err Fuzz.string ])
        , Fuzz.map SF.onTx
            (Fuzz.oneOf
                [ Fuzz.constant (Tx.TxSubmitted "0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd")
                , Fuzz.constant Tx.TxRejected
                , Fuzz.map Tx.TxFailed Fuzz.string
                ]
            )
        , Fuzz.constant SF.reset
        ]


simulateFirstTests : Test
simulateFirstTests =
    describe "SimulateFirst"
        [ fuzz (Fuzz.list simMsgFuzzer) "never Sending/Done without confirm" <|
            \fns ->
                let
                    final =
                        List.foldl (\fn s -> fn s) SF.Idle fns

                    sentOrDone st =
                        case st of
                            SF.Sending _ _ ->
                                True

                            SF.Done _ ->
                                True

                            _ ->
                                False
                in
                sentOrDone final |> Expect.equal False
        , fuzz Fuzz.string "wallet rejection returns to Previewing with the same preview" <|
            \preview ->
                SF.Previewing preview
                    |> SF.confirm
                    |> SF.onTx Tx.TxRejected
                    |> Expect.equal (SF.Previewing preview)
        , test "confirm only opens from Previewing" <|
            \_ ->
                [ SF.Idle, SF.Simulating, SF.Refused "x" ]
                    |> List.map SF.confirm
                    |> Expect.equal [ SF.Idle, SF.Simulating, SF.Refused "x" ]
        ]


pagedLogsTests : Test
pagedLogsTests =
    describe "PaginatedLogs"
        [ fuzz2 (Fuzz.intRange 0 100000) (Fuzz.intRange 1 9999) "windows tile [0..latest] exactly, no overlap, no gap" <|
            \latest window ->
                let
                    walk range pager acc =
                        case PL.next pager of
                            Just ( p2, r2 ) ->
                                walk r2 p2 (range :: acc)

                            Nothing ->
                                range :: acc

                    ( p0, r0 ) =
                        PL.init { latest = latest, window = window }

                    ranges =
                        walk r0 p0 []

                    -- oldest-first after the walk accumulation
                    covered =
                        List.foldl (\r n -> n + (r.toBlock - r.fromBlock + 1)) 0 ranges

                    contiguous =
                        List.all identity
                            (List.map2 (\older newer -> older.toBlock + 1 == newer.fromBlock)
                                ranges
                                (List.drop 1 ranges)
                            )
                in
                ( covered, contiguous, List.head ranges |> Maybe.map .fromBlock )
                    |> Expect.equal ( latest + 1, True, Just 0 )
        , test "next at genesis is Nothing" <|
            \_ ->
                PL.init { latest = 10, window = 100 }
                    |> Tuple.first
                    |> PL.next
                    |> Expect.equal Nothing
        ]
