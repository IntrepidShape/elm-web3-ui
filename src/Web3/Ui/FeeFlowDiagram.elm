module Web3.Ui.FeeFlowDiagram exposing
    ( view
    , Slice
    )

{-| Educational visualization of a fee split — a horizontal stacked bar with
proportional segments, plus a label and Wei amount under each. Pairs with
`Web3.Ui.FeeBreakdown` (which is the equivalent table view); use this one
when you want a hero-tier "where does my fee go?" graphic on a marketing
page or trade modal.

The bar segments are sized by basis points; total `bps` does not need to
sum to 10000 (the bar is normalized to its own total).

Each `Slice` accepts an optional `kind` string — emitted as a CSS class
suffix (`web3-feeflow__seg--<kind>`) so the consumer can color the
segments by recipient type without inline styles.

```elm
Web3.Ui.FeeFlowDiagram.view
    { gross = tradeFee
    , symbol = "PLS"
    , decimals = 18
    , width = 480
    , height = 24
    , slices =
        [ { label = "veToken holders", bps = 3000, kind = Just "ve" }
        , { label = "stakers",        bps = 3000, kind = Just "stakers" }
        , { label = "floor pool",     bps = 2000, kind = Just "floor" }
        , { label = "buy & burn",     bps = 1000, kind = Just "burn" }
        , { label = "treasury",       bps = 1000, kind = Just "treasury" }
        ]
    }
```

CSS classes: `web3-feeflow`, `web3-feeflow__bar`, `web3-feeflow__seg`,
`web3-feeflow__seg--<kind>`, `web3-feeflow__legend`,
`web3-feeflow__legend-item`, `web3-feeflow__legend-swatch`,
`web3-feeflow__legend-label`, `web3-feeflow__legend-amount`.

@docs view, Slice

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Svg
import Svg.Attributes as SAttr
import Web3.BigInt as BigInt exposing (BigInt)
import Web3.Ui.Amount as Amount


{-| One fee segment. `kind` becomes the CSS modifier suffix; pass
`Nothing` for a default-colored segment. -}
type alias Slice =
    { label : String
    , bps : Int
    , kind : Maybe String
    }


{-| Render the diagram (bar + legend). -}
view :
    { gross : BigInt
    , symbol : String
    , decimals : Int
    , width : Int
    , height : Int
    , slices : List Slice
    }
    -> Html msg
view opts =
    let
        totalBps =
            List.sum (List.map .bps opts.slices)

        denom =
            max 1 totalBps

        widthFor bps =
            toFloat opts.width * toFloat bps / toFloat denom

        ( _, segs ) =
            List.foldl
                (\slice ( x, acc ) ->
                    let
                        w =
                            widthFor slice.bps

                        seg =
                            Svg.rect
                                [ SAttr.class (segClass slice.kind)
                                , SAttr.x (String.fromFloat x)
                                , SAttr.y "0"
                                , SAttr.width (String.fromFloat w)
                                , SAttr.height (String.fromInt opts.height)
                                ]
                                []
                    in
                    ( x + w, seg :: acc )
                )
                ( 0, [] )
                opts.slices

        legendItems =
            List.map (legendItem opts) opts.slices
    in
    Html.div [ Attr.class "web3-feeflow" ]
        [ Svg.svg
            [ SAttr.class "web3-feeflow__bar"
            , SAttr.width (String.fromInt opts.width)
            , SAttr.height (String.fromInt opts.height)
            , SAttr.viewBox
                ("0 0 "
                    ++ String.fromInt opts.width
                    ++ " "
                    ++ String.fromInt opts.height
                )
            ]
            (List.reverse segs)
        , Html.div [ Attr.class "web3-feeflow__legend" ] legendItems
        ]


segClass : Maybe String -> String
segClass kind =
    case kind of
        Nothing ->
            "web3-feeflow__seg"

        Just k ->
            "web3-feeflow__seg web3-feeflow__seg--" ++ k


legendItem : { a | gross : BigInt, symbol : String, decimals : Int } -> Slice -> Html msg
legendItem opts slice =
    Html.div [ Attr.class "web3-feeflow__legend-item" ]
        [ Html.span [ Attr.class (swatchClass slice.kind) ] []
        , Html.span [ Attr.class "web3-feeflow__legend-label" ]
            [ Html.text slice.label
            , Html.text " "
            , Html.span [ Attr.class "web3-feeflow__legend-bps" ]
                [ Html.text (bpsToPct slice.bps) ]
            ]
        , Html.span [ Attr.class "web3-feeflow__legend-amount" ]
            [ Html.text (sliceAmount opts slice.bps) ]
        ]


swatchClass : Maybe String -> String
swatchClass kind =
    case kind of
        Nothing ->
            "web3-feeflow__legend-swatch"

        Just k ->
            "web3-feeflow__legend-swatch web3-feeflow__legend-swatch--" ++ k


sliceAmount : { a | gross : BigInt, symbol : String, decimals : Int } -> Int -> String
sliceAmount opts bps =
    case BigInt.fromInt bps of
        bpsB ->
            case BigInt.fromInt 10000 of
                denomB ->
                    case BigInt.div (BigInt.mul opts.gross bpsB) denomB of
                        Just slice ->
                            Amount.formatWei opts.decimals slice ++ " " ++ opts.symbol

                        Nothing ->
                            "—"


bpsToPct : Int -> String
bpsToPct bps =
    let
        whole =
            bps // 100

        rem =
            modBy 100 bps
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
