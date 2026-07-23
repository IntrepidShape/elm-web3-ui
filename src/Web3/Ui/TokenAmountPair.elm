module Web3.Ui.TokenAmountPair exposing (view, Config)

{-| The swap/deposit workhorse: token identity, decimals-aware amount input,
live balance line, and percent presets -- one compound, one Config.

    TokenAmountPair.view []
        { symbol = "FOO"
        , logoUrl = Just "https://tokens.example/foo.png"
        , balance = Just "420.69 FOO"
        , value = model.amountStr
        , onInput = AmountChanged
        , onPercent = FillPercent      -- 25/50/75/100; app computes from balance
        , onOpenSelector = Just OpenTokenPicker
        , valid = model.amountValid
        }

The percent chips emit intent (`onPercent 100` = MAX); the app computes the
actual amount from its live balance so the chips can never show a stale
number. `onOpenSelector = Nothing` renders the token as a static label
(fixed-token forms).

CSS classes: `web3-tokenamount`, `web3-tokenamount__token`,
`web3-tokenamount__symbol`, `web3-tokenamount__input`,
`web3-tokenamount__input--invalid`, `web3-tokenamount__balance`,
`web3-tokenamount__presets`, `web3-tokenamount__chip`,
`web3-tokenamount__chip--max`.

@docs view, Config

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Web3.Ui.TokenLogo as TokenLogo


{-| -}
type alias Config msg =
    { symbol : String
    , logoUrl : Maybe String
    , balance : Maybe String
    , value : String
    , onInput : String -> msg
    , onPercent : Int -> msg
    , onOpenSelector : Maybe msg
    , valid : Bool
    }


{-| Render the pair. -}
view : List (Html.Attribute msg) -> Config msg -> Html msg
view attrs cfg =
    Html.div
        (Attr.class "web3-tokenamount" :: attrs)
        [ token cfg
        , Html.input
            [ Attr.class "web3-tokenamount__input"
            , Attr.classList [ ( "web3-tokenamount__input--invalid", not cfg.valid ) ]
            , Attr.type_ "text"
            , Attr.attribute "inputmode" "decimal"
            , Attr.placeholder "0.0"
            , Attr.value cfg.value
            , Attr.attribute "aria-label" ("Amount in " ++ cfg.symbol)
            , Attr.attribute "aria-invalid"
                (if cfg.valid then
                    "false"

                 else
                    "true"
                )
            , Events.onInput cfg.onInput
            ]
            []
        , balanceLine cfg
        , presets cfg
        ]



-- INTERNAL


token : Config msg -> Html msg
token cfg =
    let
        body =
            [ TokenLogo.view { logoUrl = cfg.logoUrl, symbol = cfg.symbol, size = 20 }
            , Html.span [ Attr.class "web3-tokenamount__symbol" ] [ Html.text cfg.symbol ]
            ]
    in
    case cfg.onOpenSelector of
        Just msg ->
            Html.button
                [ Attr.class "web3-tokenamount__token"
                , Attr.attribute "aria-label" ("Change token, currently " ++ cfg.symbol)
                , Events.onClick msg
                ]
                (body ++ [ Html.text " ▾" ])

        Nothing ->
            Html.span [ Attr.class "web3-tokenamount__token" ] body


balanceLine : Config msg -> Html msg
balanceLine cfg =
    case cfg.balance of
        Just b ->
            Html.span [ Attr.class "web3-tokenamount__balance" ]
                [ Html.text ("Balance: " ++ b) ]

        Nothing ->
            Html.text ""


presets : Config msg -> Html msg
presets cfg =
    Html.div [ Attr.class "web3-tokenamount__presets" ]
        (List.map
            (\pct ->
                Html.button
                    [ Attr.class "web3-tokenamount__chip"
                    , Attr.classList [ ( "web3-tokenamount__chip--max", pct == 100 ) ]
                    , Events.onClick (cfg.onPercent pct)
                    ]
                    [ Html.text
                        (if pct == 100 then
                            "MAX"

                         else
                            String.fromInt pct ++ "%"
                        )
                    ]
            )
            [ 25, 50, 75, 100 ]
        )
