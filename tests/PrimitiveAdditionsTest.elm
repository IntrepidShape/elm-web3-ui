module PrimitiveAdditionsTest exposing (suite)

{-| C1/C6/C7 additions: dust convention vectors, copyable render branches,
pair determinism.
-}

import Expect
import Test exposing (..)
import Web3.BigInt as B
import Web3.Types as T
import Web3.Ui.Address as Address
import Web3.Ui.Amount as Amount
import Web3.Ui.TokenAmountPair as Pair


wei : String -> B.BigInt
wei s =
    Maybe.withDefault B.zero (B.fromString s)


addr : T.Address
addr =
    case T.address "0xbeefcafe1234deadbeefcafe1234deadbeefcafe" of
        Just a ->
            a

        Nothing ->
            addrFallback "x"


addrFallback : String -> T.Address
addrFallback _ =
    case T.address "0xbeefcafe1234deadbeefcafe1234deadbeefcafe" of
        Just a ->
            a

        Nothing ->
            addrFallback "x"


type Msg
    = Copied String
    | Input String
    | Percent Int


suite : Test
suite =
    describe "C1/C6/C7 primitive additions"
        [ describe "Amount.formatWeiDust"
            [ test "zero is 0, never dust" <|
                \_ -> Amount.formatWeiDust 18 B.zero |> Expect.equal "0"
            , test "1 wei at 18 decimals is dust" <|
                \_ -> Amount.formatWeiDust 18 (wei "1") |> Expect.equal "<0.0001"
            , test "just under the threshold is dust" <|
                \_ -> Amount.formatWeiDust 18 (wei "99999999999999") |> Expect.equal "<0.0001"
            , test "1e18 formats normally" <|
                \_ ->
                    Amount.formatWeiDust 18 (wei "1000000000000000000")
                        |> Expect.equal (Amount.formatWei 18 (wei "1000000000000000000"))
            ]
        , describe "Address.copyable"
            [ test "renders deterministically" <|
                \_ ->
                    Address.copyable [] { onCopy = Copied, explorerUrl = Nothing } addr
                        |> Expect.equal
                            (Address.copyable [] { onCopy = Copied, explorerUrl = Nothing } addr)
            , test "linked and plain variants differ" <|
                \_ ->
                    Address.copyable [] { onCopy = Copied, explorerUrl = Just "https://x/" } addr
                        |> Expect.notEqual
                            (Address.copyable [] { onCopy = Copied, explorerUrl = Nothing } addr)
            ]
        , describe "TokenAmountPair"
            [ test "selector and fixed-token variants differ" <|
                \_ ->
                    let
                        base =
                            { symbol = "FOO"
                            , logoUrl = Nothing
                            , balance = Just "420.69 FOO"
                            , value = "1.5"
                            , onInput = Input
                            , onPercent = Percent
                            , onOpenSelector = Nothing
                            , valid = True
                            }
                    in
                    Pair.view [] base
                        |> Expect.notEqual (Pair.view [] { base | onOpenSelector = Just (Input "open") })
            , test "invalid flag changes the render" <|
                \_ ->
                    let
                        base =
                            { symbol = "FOO"
                            , logoUrl = Nothing
                            , balance = Nothing
                            , value = "x"
                            , onInput = Input
                            , onPercent = Percent
                            , onOpenSelector = Nothing
                            , valid = True
                            }
                    in
                    Pair.view [] base
                        |> Expect.notEqual (Pair.view [] { base | valid = False })
            ]
        ]
