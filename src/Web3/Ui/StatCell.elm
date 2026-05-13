module Web3.Ui.StatCell exposing (view, Sentiment(..))

{-| Single label/value cell with optional delta and sentiment color. The
unit-of-display analytics row that every dapp reaches for: "TVL", "24h
volume", "stakers", "floor".

    Web3.Ui.StatCell.view
        { label = "Floor price"
        , value = "0.024 PLS"
        , delta = Just "+1.4%"
        , sentiment = Web3.Ui.StatCell.Positive
        }

CSS classes: `web3-statcell`, `web3-statcell__label`, `web3-statcell__value`,
`web3-statcell__delta`, `web3-statcell--positive` / `--negative` / `--neutral`.

@docs view, Sentiment

-}

import Html exposing (Html)
import Html.Attributes as Attr


{-| -}
type Sentiment
    = Positive
    | Negative
    | Neutral


{-| Render the stat cell. -}
view :
    { label : String
    , value : String
    , delta : Maybe String
    , sentiment : Sentiment
    }
    -> Html msg
view opts =
    let
        modifier =
            case opts.sentiment of
                Positive ->
                    "web3-statcell--positive"

                Negative ->
                    "web3-statcell--negative"

                Neutral ->
                    "web3-statcell--neutral"

        deltaEl =
            case opts.delta of
                Nothing ->
                    Html.text ""

                Just d ->
                    Html.span [ Attr.class "web3-statcell__delta" ] [ Html.text d ]
    in
    Html.div [ Attr.class ("web3-statcell " ++ modifier) ]
        [ Html.div [ Attr.class "web3-statcell__label" ] [ Html.text opts.label ]
        , Html.div [ Attr.class "web3-statcell__value" ] [ Html.text opts.value ]
        , deltaEl
        ]
