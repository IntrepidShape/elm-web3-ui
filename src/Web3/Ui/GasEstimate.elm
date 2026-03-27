module Web3.Ui.GasEstimate exposing (view)

{-| Gas cost estimate display.

Pair with `Web3.Contract.Send.estimateGas` and `Web3.Fee.getGasPrice` to show
the expected cost of a transaction before the user confirms.

    Web3.Ui.GasEstimate.view []
        { gasUnits = model.gasEstimate
        , gasPrice = model.gasPrice
        , decimals = 18
        , symbol = "PLS"
        }

@docs view

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Web3.BigInt as BigInt exposing (BigInt)
import Web3.Units as Units


{-| Display an estimated transaction cost in the native token.

`gasUnits` — gas limit returned by `estimateGas` (decoded from port)
`gasPrice` — current gas price in wei, from `Web3.Fee.getGasPrice`

Shows `"Estimating…"` while either value is `Nothing`.

Cost = gasUnits × gasPrice (in wei), displayed via `formatUnits`.

CSS class: `web3-gas-estimate`

-}
view :
    List (Html.Attribute msg)
    -> { gasUnits : Maybe BigInt, gasPrice : Maybe BigInt, decimals : Int, symbol : String }
    -> Html msg
view attrs opts =
    let
        content =
            case ( opts.gasUnits, opts.gasPrice ) of
                ( Just units, Just price ) ->
                    let
                        cost =
                            BigInt.mul units price
                    in
                    "~" ++ Units.formatUnits opts.decimals cost ++ " " ++ opts.symbol

                _ ->
                    "Estimating…"
    in
    Html.span
        (Attr.class "web3-gas-estimate" :: attrs)
        [ Html.text content ]
