module TransactionUiTest exposing (suite)

import Expect
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import Web3.Transaction as Tx
import Web3.Types as T
import Web3.Ui.Transaction as TxUi


suite : Test
suite =
    describe "Web3.Ui.Transaction"
        [ describe "statusBadge"
            [ test "Idle has web3-tx-badge--idle class" <|
                \_ ->
                    TxUi.statusBadge [] Tx.Idle
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "web3-tx-badge--idle" ]
            , test "AwaitingSignature has web3-tx-badge--pending class" <|
                \_ ->
                    TxUi.statusBadge [] Tx.AwaitingSignature
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "web3-tx-badge--pending" ]
            , test "Confirmed has web3-tx-badge--confirmed class" <|
                \_ ->
                    case T.txHash "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef" of
                        Nothing ->
                            Expect.fail "test fixture: invalid tx hash"

                        Just hash ->
                            TxUi.statusBadge []
                                (Tx.Confirmed
                                    { txHash = hash
                                    , blockNumber = 1
                                    , gasUsed = "21000"
                                    , status = True
                                    , logs = []
                                    }
                                )
                                |> Query.fromHtml
                                |> Query.has [ Selector.class "web3-tx-badge--confirmed" ]
            , test "Failed has web3-tx-badge--failed class" <|
                \_ ->
                    TxUi.statusBadge [] (Tx.Failed "revert")
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "web3-tx-badge--failed" ]
            , test "Rejected has web3-tx-badge--rejected class" <|
                \_ ->
                    TxUi.statusBadge [] Tx.Rejected
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "web3-tx-badge--rejected" ]
            , test "all badges have web3-tx-badge base class" <|
                \_ ->
                    TxUi.statusBadge [] Tx.Idle
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "web3-tx-badge" ]
            ]
        , describe "statusHashLink"
            [ test "Idle returns Nothing" <|
                \_ ->
                    Expect.equal Nothing
                        (TxUi.statusHashLink [] { explorerUrl = "https://etherscan.io/tx/" } Tx.Idle)
            , test "AwaitingSignature returns Nothing" <|
                \_ ->
                    Expect.equal Nothing
                        (TxUi.statusHashLink [] { explorerUrl = "https://etherscan.io/tx/" } Tx.AwaitingSignature)
            , test "Failed returns Nothing" <|
                \_ ->
                    Expect.equal Nothing
                        (TxUi.statusHashLink [] { explorerUrl = "https://etherscan.io/tx/" } (Tx.Failed "err"))
            , test "Rejected returns Nothing" <|
                \_ ->
                    Expect.equal Nothing
                        (TxUi.statusHashLink [] { explorerUrl = "https://etherscan.io/tx/" } Tx.Rejected)
            , test "Submitted returns Just" <|
                \_ ->
                    case T.txHash "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef" of
                        Nothing ->
                            Expect.fail "test fixture: invalid tx hash"

                        Just hash ->
                            TxUi.statusHashLink [] { explorerUrl = "https://etherscan.io/tx/" } (Tx.Submitted hash)
                                |> Expect.notEqual Nothing
            , test "Confirmed returns Just" <|
                \_ ->
                    case T.txHash "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef" of
                        Nothing ->
                            Expect.fail "test fixture: invalid tx hash"

                        Just hash ->
                            TxUi.statusHashLink []
                                { explorerUrl = "https://etherscan.io/tx/" }
                                (Tx.Confirmed
                                    { txHash = hash
                                    , blockNumber = 1
                                    , gasUsed = "21000"
                                    , status = True
                                    , logs = []
                                    }
                                )
                                |> Expect.notEqual Nothing
            ]
        , describe "receiptView"
            [ test "has web3-receipt base class" <|
                \_ ->
                    case T.txHash "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef" of
                        Nothing ->
                            Expect.fail "test fixture: invalid tx hash"

                        Just hash ->
                            TxUi.receiptView []
                                { explorerUrl = "https://etherscan.io/tx/" }
                                { txHash = hash
                                , blockNumber = 100
                                , gasUsed = "21000"
                                , status = True
                                , logs = []
                                }
                                |> Query.fromHtml
                                |> Query.has [ Selector.class "web3-receipt" ]
            , test "success receipt has web3-receipt--success class" <|
                \_ ->
                    case T.txHash "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef" of
                        Nothing ->
                            Expect.fail "test fixture: invalid tx hash"

                        Just hash ->
                            TxUi.receiptView []
                                { explorerUrl = "https://etherscan.io/tx/" }
                                { txHash = hash
                                , blockNumber = 100
                                , gasUsed = "21000"
                                , status = True
                                , logs = []
                                }
                                |> Query.fromHtml
                                |> Query.has [ Selector.class "web3-receipt--success" ]
            , test "failed receipt has web3-receipt--failed class" <|
                \_ ->
                    case T.txHash "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef" of
                        Nothing ->
                            Expect.fail "test fixture: invalid tx hash"

                        Just hash ->
                            TxUi.receiptView []
                                { explorerUrl = "https://etherscan.io/tx/" }
                                { txHash = hash
                                , blockNumber = 100
                                , gasUsed = "21000"
                                , status = False
                                , logs = []
                                }
                                |> Query.fromHtml
                                |> Query.has [ Selector.class "web3-receipt--failed" ]
            ]
        ]
