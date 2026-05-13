module Web3.Ui.FeeBreakdown exposing
    ( view
    , Slice
    )

{-| Render a fee-split table. Each row is one slice of the fee — the caller
provides labels, basis points, and (optionally) the Wei amount that slice will
receive at the current trade size.

    Web3.Ui.FeeBreakdown.view
        { totalBps = 150
        , symbol = "PLS"
        , decimals = 18
        , gross = Just tradeGrossWei
        , slices =
            [ { label = "Creator", bps = 50, recipient = Just creatorAddr }
            , { label = "Protocol", bps = 10, recipient = Nothing }
            , { label = "Platform", bps = 20, recipient = Nothing }
            , { label = "Token pool", bps = 70, recipient = Nothing }
            ]
        }

Style classes: `web3-feebreakdown`, `web3-feebreakdown__row`, `web3-feebreakdown__label`,
`web3-feebreakdown__bps`, `web3-feebreakdown__amount`, `web3-feebreakdown__total`.

@docs view, Slice

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Web3.BigInt as BigInt exposing (BigInt)
import Web3.Types as T
import Web3.Ui.Address as Address
import Web3.Ui.Amount as Amount


{-| One row of the fee table. -}
type alias Slice =
    { label : String
    , bps : Int
    , recipient : Maybe T.Address
    }


{-| Render the breakdown table. -}
view :
    { totalBps : Int
    , symbol : String
    , decimals : Int
    , gross : Maybe BigInt
    , slices : List Slice
    }
    -> Html msg
view opts =
    let
        rows =
            List.map (sliceRow opts) opts.slices

        totalRow =
            Html.div [ Attr.class "web3-feebreakdown__row web3-feebreakdown__total" ]
                [ Html.span [ Attr.class "web3-feebreakdown__label" ] [ Html.text "Total fee" ]
                , Html.span [ Attr.class "web3-feebreakdown__bps" ]
                    [ Html.text (bpsString opts.totalBps) ]
                , Html.span [ Attr.class "web3-feebreakdown__amount" ]
                    [ Html.text (sliceAmount opts opts.totalBps) ]
                ]
    in
    Html.div [ Attr.class "web3-feebreakdown" ] (rows ++ [ totalRow ])


sliceRow : { a | symbol : String, decimals : Int, gross : Maybe BigInt } -> Slice -> Html msg
sliceRow opts slice =
    Html.div [ Attr.class "web3-feebreakdown__row" ]
        [ Html.span [ Attr.class "web3-feebreakdown__label" ]
            [ Html.text slice.label
            , case slice.recipient of
                Nothing ->
                    Html.text ""

                Just addr ->
                    Html.span
                        [ Attr.class "web3-feebreakdown__recipient" ]
                        [ Html.text " → "
                        , Html.text (Address.short addr)
                        ]
            ]
        , Html.span [ Attr.class "web3-feebreakdown__bps" ]
            [ Html.text (bpsString slice.bps) ]
        , Html.span [ Attr.class "web3-feebreakdown__amount" ]
            [ Html.text (sliceAmount opts slice.bps) ]
        ]


sliceAmount : { a | symbol : String, decimals : Int, gross : Maybe BigInt } -> Int -> String
sliceAmount opts bps =
    case opts.gross of
        Nothing ->
            "—"

        Just gross ->
            case BigInt.fromInt bps of
                bpsB ->
                    case BigInt.fromInt 10000 of
                        denomB ->
                            case BigInt.div (BigInt.mul gross bpsB) denomB of
                                Just slice ->
                                    Amount.formatWei opts.decimals slice ++ " " ++ opts.symbol

                                Nothing ->
                                    "—"


bpsString : Int -> String
bpsString bps =
    let
        whole =
            bps // 100

        rem =
            bps |> modBy 100
    in
    if rem == 0 then
        String.fromInt whole ++ "%"

    else
        String.fromInt whole
            ++ "."
            ++ (if rem < 10 then
                    "0"

                else
                    ""
               )
            ++ String.fromInt rem
            ++ "%"
