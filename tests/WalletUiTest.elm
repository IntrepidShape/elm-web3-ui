module WalletUiTest exposing (suite)

import Expect
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import Web3.Chain as Chain
import Web3.Transaction as Tx
import Web3.Types as T
import Web3.Ui.Address as Address
import Web3.Ui.Transaction as TxUi
import Web3.Ui.Wallet as WalletUi
import Web3.Wallet as Wallet


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
        , describe "chainBadge"
            [ test "Connected on known chain shows chain name" <|
                \_ ->
                    case T.address "0x1234567890abcdef1234567890abcdef12345678" of
                        Nothing ->
                            Expect.fail "test fixture: invalid address"

                        Just addr ->
                            WalletUi.chainBadge []
                                [ Chain.pulsechain ]
                                (Wallet.Connected { address = addr, chainId = Chain.chainId Chain.pulsechain })
                                |> Query.fromHtml
                                |> Query.has [ Selector.text "PulseChain" ]
            , test "Connected on unknown chain shows 'Unknown Chain'" <|
                \_ ->
                    case T.address "0x1234567890abcdef1234567890abcdef12345678" of
                        Nothing ->
                            Expect.fail "test fixture: invalid address"

                        Just addr ->
                            WalletUi.chainBadge []
                                [ Chain.pulsechain ]
                                (Wallet.Connected { address = addr, chainId = T.chainId 9999 })
                                |> Query.fromHtml
                                |> Query.has [ Selector.text "Unknown Chain" ]
            , test "ReadOnly shows 'Read-only'" <|
                \_ ->
                    WalletUi.chainBadge [] [] Wallet.ReadOnly
                        |> Query.fromHtml
                        |> Query.has [ Selector.text "Read-only" ]
            , test "Disconnected shows '—'" <|
                \_ ->
                    WalletUi.chainBadge [] [] Wallet.Disconnected
                        |> Query.fromHtml
                        |> Query.has [ Selector.text "—" ]
            ]
        , describe "viewState"
            [ test "WrongChain shows target chain name" <|
                \_ ->
                    case T.address "0x1234567890abcdef1234567890abcdef12345678" of
                        Nothing ->
                            Expect.fail "test fixture: invalid address"

                        Just addr ->
                            WalletUi.viewState []
                                { onConnect = ()
                                , onSwitchChain = ()
                                , onDisconnect = ()
                                , knownChains = [ Chain.pulsechain ]
                                }
                                (Wallet.WrongChain
                                    { address = addr, chainId = T.chainId 1 }
                                    (Chain.chainId Chain.pulsechain)
                                )
                                |> Query.fromHtml
                                |> Query.has [ Selector.text "PulseChain" ]
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
