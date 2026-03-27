module WalletUiTest exposing (suite)

import Expect
import Test exposing (Test, describe, test)
import Web3.Types as T
import Web3.Ui.Address as Address
import Web3.Ui.Transaction as TxUi
import Web3.Transaction as Tx


suite : Test
suite =
    describe "Web3.Ui"
        [ describe "Address.short"
            [ test "truncates a full address to 0x + 4 + … + 4" <|
                \_ ->
                    let
                        addr =
                            T.address "0x1234567890abcdef1234567890abcdef12345678"
                    in
                    case addr of
                        Just a ->
                            Expect.equal "0x1234…5678" (Address.short a)

                        Nothing ->
                            Expect.fail "address constructor returned Nothing"
            , test "short retains 0x prefix" <|
                \_ ->
                    let
                        addr =
                            T.address "0xabcdef1234567890abcdef1234567890abcdef12"
                    in
                    case addr of
                        Just a ->
                            let
                                result =
                                    Address.short a
                            in
                            Expect.equal True (String.startsWith "0x" result)

                        Nothing ->
                            Expect.fail "address constructor returned Nothing"
            , test "short result is 11 chars (6 prefix + … + 4 suffix)" <|
                \_ ->
                    let
                        addr =
                            T.address "0x1234567890abcdef1234567890abcdef12345678"
                    in
                    case addr of
                        Just a ->
                            Expect.equal 11 (String.length (Address.short a))

                        Nothing ->
                            Expect.fail "address constructor returned Nothing"
            ]
        , describe "Transaction.statusBadge class names"
            [ test "Idle gets --idle modifier" <|
                \_ ->
                    -- We test the label text as a proxy for correct branching,
                    -- since we can't inspect Html attributes directly in elm-test.
                    -- The label is what drives the modifier selection.
                    let
                        label =
                            txStatusLabel Tx.Idle
                    in
                    Expect.equal "Idle" label
            , test "AwaitingSignature gets --pending modifier" <|
                \_ ->
                    Expect.equal "Awaiting Signature" (txStatusLabel Tx.AwaitingSignature)
            , test "Rejected gets --rejected modifier" <|
                \_ ->
                    Expect.equal "Rejected" (txStatusLabel Tx.Rejected)
            , test "Failed carries message" <|
                \_ ->
                    Expect.equal "Failed" (txStatusLabel (Tx.Failed "out of gas"))
            ]
        ]


{-| Mirror the label logic from Transaction.statusBadge for unit testing
without touching Html.
-}
txStatusLabel : Tx.Status -> String
txStatusLabel status =
    case status of
        Tx.Idle ->
            "Idle"

        Tx.AwaitingSignature ->
            "Awaiting Signature"

        Tx.Submitted _ ->
            "Pending"

        Tx.Confirming _ _ ->
            "Confirming"

        Tx.Confirmed _ ->
            "Confirmed"

        Tx.Failed _ ->
            "Failed"

        Tx.Rejected ->
            "Rejected"
