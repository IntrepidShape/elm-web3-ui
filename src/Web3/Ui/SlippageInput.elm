module Web3.Ui.SlippageInput exposing
    ( view
    , Config
    , minOutFromBps
    )

{-| Slippage tolerance picker for trade UIs. Renders a row of preset chips
(0.1% / 0.5% / 1%) plus a custom input. Returns the chosen value as basis
points so the caller can compute `minTokensOut` / `minPlsOut`.

    Web3.Ui.SlippageInput.view
        { valueBps = model.slippageBps
        , onChange = SlippageChanged
        , presetsBps = [ 10, 50, 100 ]   -- 0.1%, 0.5%, 1%
        }

    -- Helper: derive the minOut value given an expected amount and slippage.
    let
        minOut =
            Web3.Ui.SlippageInput.minOutFromBps model.slippageBps expectedAmount
    in
    contractCall { ..., minOut = minOut }

Style classes: `web3-slippage`, `web3-slippage__chip`, `web3-slippage__chip--active`,
`web3-slippage__custom`.

@docs view, Config, minOutFromBps

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode as Decode
import Web3.BigInt as BigInt exposing (BigInt)


{-| -}
type alias Config msg =
    { valueBps : Int
    , onChange : Int -> msg
    , presetsBps : List Int
    }


{-| Compute `expected * (10000 - slippageBps) / 10000` in BigInt arithmetic.
Returns `BigInt.zero` if the slippage exceeds 100%.
-}
minOutFromBps : Int -> BigInt -> BigInt
minOutFromBps slippageBps expected =
    if slippageBps >= 10000 then
        BigInt.zero

    else
        let
            multiplier =
                BigInt.fromInt (10000 - slippageBps)

            denom =
                BigInt.fromInt 10000
        in
        case BigInt.div (BigInt.mul expected multiplier) denom of
            Just v ->
                v

            Nothing ->
                BigInt.zero


{-| Render the picker. -}
view : Config msg -> Html msg
view cfg =
    Html.div [ Attr.class "web3-slippage" ]
        (List.map (chip cfg) cfg.presetsBps
            ++ [ customInput cfg ]
        )


chip : Config msg -> Int -> Html msg
chip cfg bps =
    let
        active =
            bps == cfg.valueBps

        cls =
            if active then
                "web3-slippage__chip web3-slippage__chip--active"

            else
                "web3-slippage__chip"
    in
    Html.button
        [ Attr.class cls
        , Attr.type_ "button"
        , Events.onClick (cfg.onChange bps)
        ]
        [ Html.text (formatBps bps) ]


customInput : Config msg -> Html msg
customInput cfg =
    let
        isPreset =
            List.member cfg.valueBps cfg.presetsBps

        displayed =
            if isPreset then
                ""

            else
                formatBps cfg.valueBps
    in
    Html.div [ Attr.class "web3-slippage__custom" ]
        [ Html.input
            [ Attr.type_ "text"
            , Attr.attribute "inputmode" "decimal"
            , Attr.placeholder "Custom %"
            , Attr.value displayed
            , Events.on "input" (Decode.map (parsePercent >> cfg.onChange) targetValueDecoder)
            ]
            []
        ]


targetValueDecoder : Decode.Decoder String
targetValueDecoder =
    Decode.at [ "target", "value" ] Decode.string


parsePercent : String -> Int
parsePercent s =
    let
        cleaned =
            String.filter (\c -> Char.isDigit c || c == '.') s
    in
    case String.toFloat cleaned of
        Just f ->
            round (f * 100)

        Nothing ->
            0


formatBps : Int -> String
formatBps bps =
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
