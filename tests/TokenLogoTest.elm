module TokenLogoTest exposing (suite)

{-| TokenLogo: branch selection and deterministic tile hue. -}

import Expect
import Test exposing (..)
import Web3.Ui.TokenLogo as TokenLogo


suite : Test
suite =
    describe "Web3.Ui.TokenLogo"
        [ test "same symbol renders identically (deterministic tile)" <|
            \_ ->
                TokenLogo.view { logoUrl = Nothing, symbol = "USDC", size = 24 }
                    |> Expect.equal
                        (TokenLogo.view { logoUrl = Nothing, symbol = "USDC", size = 24 })
        , test "img branch differs from tile branch" <|
            \_ ->
                TokenLogo.view { logoUrl = Just "https://x/y.png", symbol = "USDC", size = 24 }
                    |> Expect.notEqual
                        (TokenLogo.view { logoUrl = Nothing, symbol = "USDC", size = 24 })
        ]
