module Web3.Ui.Balance exposing
    ( view
    , viewEther
    , viewMaybe
    , viewEtherMaybe
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

    -- Balance that may not have loaded yet:
    Web3.Ui.Balance.viewMaybe []
        { decimals = 6, symbol = "USDC", loading = "…" }
        model.balance

    -- Ether balance that may not have loaded yet:
    Web3.Ui.Balance.viewEtherMaybe []
        { symbol = "ETH", loading = "…" }
        model.ethBalance

@docs view, viewEther, viewMaybe, viewEtherMaybe

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


{-| Display a token balance that may not have loaded yet.

Shows `opts.loading` with class `web3-balance--loading` while `Nothing`.
Renders the same as `view` once the balance arrives.

CSS classes: `web3-balance`, `web3-balance--loading` (loading state only)

-}
viewMaybe :
    List (Html.Attribute msg)
    -> { decimals : Int, symbol : String, loading : String }
    -> Maybe BigInt
    -> Html msg
viewMaybe attrs opts amount =
    case amount of
        Nothing ->
            Html.span
                (Attr.class "web3-balance" :: Attr.class "web3-balance--loading" :: attrs)
                [ Html.text opts.loading ]

        Just a ->
            Html.span
                (Attr.class "web3-balance" :: attrs)
                [ Html.text (Units.formatUnits opts.decimals a ++ " " ++ opts.symbol) ]


{-| Display a Wei balance that may not have loaded yet (18 decimals).

Delegates to `viewMaybe` with `decimals = 18`.

CSS classes: `web3-balance`, `web3-balance--loading` (loading state only)

-}
viewEtherMaybe :
    List (Html.Attribute msg)
    -> { symbol : String, loading : String }
    -> Maybe BigInt
    -> Html msg
viewEtherMaybe attrs opts amount =
    viewMaybe attrs { decimals = 18, symbol = opts.symbol, loading = opts.loading } amount
