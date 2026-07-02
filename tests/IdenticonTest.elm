module IdenticonTest exposing (suite)

{-| Blockies algorithm properties: deterministic, 64 mirrored cells with
values in {0,1,2}, distinct across addresses, HSL color strings.
-}

import Expect
import Fuzz exposing (Fuzzer)
import Test exposing (..)
import Web3.Ui.Identicon as Identicon


hexCharFuzzer : Fuzzer Char
hexCharFuzzer =
    Fuzz.intRange 0 15
        |> Fuzz.map
            (\n ->
                if n < 10 then
                    Char.fromCode (Char.toCode '0' + n)

                else
                    Char.fromCode (Char.toCode 'a' + (n - 10))
            )


addressStringFuzzer : Fuzzer String
addressStringFuzzer =
    Fuzz.listOfLength 40 hexCharFuzzer
        |> Fuzz.map (\cs -> "0x" ++ String.fromList cs)


chunksOf : Int -> List a -> List (List a)
chunksOf n xs =
    case xs of
        [] ->
            []

        _ ->
            List.take n xs :: chunksOf n (List.drop n xs)


suite : Test
suite =
    describe "Web3.Ui.Identicon"
        [ fuzz addressStringFuzzer "deterministic: same seed, same cells" <|
            \seed ->
                Identicon.cells seed
                    |> Expect.equal (Identicon.cells seed)
        , fuzz addressStringFuzzer "grid is 64 cells with values in {0,1,2}" <|
            \seed ->
                let
                    grid =
                        (Identicon.cells seed).grid
                in
                Expect.all
                    [ \g -> List.length g |> Expect.equal 64
                    , \g -> List.all (\v -> v >= 0 && v <= 2) g |> Expect.equal True
                    ]
                    grid
        , fuzz addressStringFuzzer "every row is vertically mirrored" <|
            \seed ->
                (Identicon.cells seed).grid
                    |> chunksOf 8
                    |> List.all (\row -> row == List.reverse row)
                    |> Expect.equal True
        , fuzz addressStringFuzzer "colors are hsl(...) strings" <|
            \seed ->
                let
                    c =
                        Identicon.cells seed
                in
                [ c.color, c.bgColor, c.spotColor ]
                    |> List.all (String.startsWith "hsl(")
                    |> Expect.equal True
        , test "distinct addresses produce distinct icons (known vectors)" <|
            \_ ->
                Identicon.cells "0x0000000000000000000000000000000000000001"
                    |> Expect.notEqual
                        (Identicon.cells "0x0000000000000000000000000000000000000002")
        ]
