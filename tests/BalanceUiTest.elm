module BalanceUiTest exposing (suite)

import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import Web3.BigInt as BigInt
import Web3.Ui.Balance as Balance


suite : Test
suite =
    describe "Web3.Ui.Balance"
        [ describe "view"
            [ test "has web3-balance class" <|
                \_ ->
                    Balance.view [] { decimals = 0, symbol = "TEST" } (BigInt.fromInt 1)
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "web3-balance" ]
            , test "formats amount with symbol" <|
                \_ ->
                    Balance.view [] { decimals = 0, symbol = "TEST" } (BigInt.fromInt 42)
                        |> Query.fromHtml
                        |> Query.has [ Selector.text "TEST" ]
            ]
        , describe "viewMaybe"
            [ test "Nothing: has web3-balance--loading class" <|
                \_ ->
                    Balance.viewMaybe [] { decimals = 6, symbol = "USDC", loading = "…" } Nothing
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "web3-balance--loading" ]
            , test "Nothing: shows loading text" <|
                \_ ->
                    Balance.viewMaybe [] { decimals = 6, symbol = "USDC", loading = "Loading…" } Nothing
                        |> Query.fromHtml
                        |> Query.has [ Selector.text "Loading…" ]
            , test "Just: does NOT have web3-balance--loading class" <|
                \_ ->
                    Balance.viewMaybe [] { decimals = 0, symbol = "TEST", loading = "…" } (Just (BigInt.fromInt 1))
                        |> Query.fromHtml
                        |> Query.hasNot [ Selector.class "web3-balance--loading" ]
            , test "Just: has web3-balance class" <|
                \_ ->
                    Balance.viewMaybe [] { decimals = 0, symbol = "TEST", loading = "…" } (Just (BigInt.fromInt 1))
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "web3-balance" ]
            ]
        , describe "viewEtherMaybe"
            [ test "Nothing: shows loading text" <|
                \_ ->
                    Balance.viewEtherMaybe [] { symbol = "ETH", loading = "Loading…" } Nothing
                        |> Query.fromHtml
                        |> Query.has [ Selector.text "Loading…" ]
            , test "Nothing: has web3-balance--loading class" <|
                \_ ->
                    Balance.viewEtherMaybe [] { symbol = "ETH", loading = "…" } Nothing
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "web3-balance--loading" ]
            ]
        ]
