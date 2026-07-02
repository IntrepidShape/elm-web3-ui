module TxQueueFormTest exposing (suite)

{-| TxQueue routing-by-id + Form error accumulation. -}

import Expect
import Test exposing (..)
import Web3.Transaction as Tx
import Web3.Ui.Form as Form
import Web3.Ui.TxQueue as Q


validHash : String
validHash =
    "0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd"


suite : Test
suite =
    describe "TxQueue + Form"
        [ describe "Web3.Ui.TxQueue"
            [ test "messages route by id; other entries untouched" <|
                \_ ->
                    Q.empty
                        |> Q.begin "a" "Approve"
                        |> Q.begin "b" "Stake"
                        |> Q.update "a" (Tx.TxSubmitted validHash)
                        |> Q.entries
                        |> List.map (\( id, e ) -> ( id, Tx.isPending e.status ))
                        |> Expect.equal [ ( "a", True ), ( "b", True ) ]
            , test "unknown id is ignored — no ghost entries" <|
                \_ ->
                    Q.empty
                        |> Q.update "ghost" (Tx.TxSubmitted validHash)
                        |> Q.entries
                        |> Expect.equal []
            , test "pendingCount counts only in-flight" <|
                \_ ->
                    Q.empty
                        |> Q.begin "a" "Approve"
                        |> Q.begin "b" "Stake"
                        |> Q.update "b" Tx.TxRejected
                        |> Q.pendingCount
                        |> Expect.equal 1
            , test "dismiss removes the entry" <|
                \_ ->
                    Q.empty
                        |> Q.begin "a" "Approve"
                        |> Q.dismiss "a"
                        |> Q.entries
                        |> Expect.equal []
            ]
        , describe "Web3.Ui.Form"
            [ test "errors accumulate across fields (no short-circuit)" <|
                \_ ->
                    Form.succeed Tuple.pair
                        |> Form.andMap (Form.fromMaybe "bad address" (Nothing |> Maybe.map identity))
                        |> Form.andMap (Form.fromMaybe "bad amount" (Nothing |> Maybe.map String.trim))
                        |> Form.errors
                        |> Expect.equal [ "bad address", "bad amount" ]
            , test "all-valid pipeline yields the record" <|
                \_ ->
                    Form.succeed Tuple.pair
                        |> Form.andMap (Form.fromMaybe "x" (Just 1))
                        |> Form.andMap (Form.fromMaybe "y" (Just "one"))
                        |> Expect.equal (Ok ( 1, "one" ))
            ]
        ]
