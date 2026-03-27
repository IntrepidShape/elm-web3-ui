module Web3.Ui.Balance exposing
    ( view
    , viewEther
    )

{-| Balance display components.

Uses `Web3.Units.formatUnits` / `Web3.Units.formatEther` internally.

    -- ERC-20 token with 6 decimals:
    Web3.Ui.Balance.view []
        { decimals = 6, symbol = "USDC" }
        amount

    -- Native ETH/PLS balance:
    Web3.Ui.Balance.viewEther []
        { symbol = "ETH" }
        weiAmount

@docs view, viewEther

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Web3.BigInt exposing (BigInt)
import Web3.Units as Units


{-| Display a token balance formatted with the given decimal count and symbol.

    view [] { decimals = 6, symbol = "USDC" } amount
    --> <span class="web3-balance">1.5 USDC</span>

CSS class: `web3-balance`

-}
view :
    List (Html.Attribute msg)
    -> { decimals : Int, symbol : String }
    -> BigInt
    -> Html msg
view attrs opts amount =
    Html.span
        (Attr.class "web3-balance" :: attrs)
        [ Html.text (Units.formatUnits opts.decimals amount ++ " " ++ opts.symbol) ]


{-| Display a Wei amount as ether (18 decimals) with the given symbol.

    viewEther [] { symbol = "ETH" } weiAmount
    --> <span class="web3-balance">1.5 ETH</span>

CSS class: `web3-balance`

-}
viewEther :
    List (Html.Attribute msg)
    -> { symbol : String }
    -> BigInt
    -> Html msg
viewEther attrs opts amount =
    Html.span
        (Attr.class "web3-balance" :: attrs)
        [ Html.text (Units.formatEther amount ++ " " ++ opts.symbol) ]
