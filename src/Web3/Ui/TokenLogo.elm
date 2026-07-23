module Web3.Ui.TokenLogo exposing (view, Config)

{-| Token logo atom -- an `img` when a logo URL is known, a deterministic
letter tile when it is not.

Every token list, swap panel, and portfolio row needs the same thing: show
the logo if we have one, and degrade to something recognisable (not a broken
image icon) when we don't. The fallback tile shows the first 1-2 characters
of the symbol and picks one of eight hue classes from a character-code hash
of the symbol -- so `"USDC"` is always the same colour everywhere it appears,
with zero inline styles. Your stylesheet owns the actual palette.

    Web3.Ui.TokenLogo.view
        { logoUrl = Just "https://tokens.example/usdc.png"
        , symbol = "USDC"
        , size = 24
        }

    -- No logo known -- renders the "FO" letter tile:
    Web3.Ui.TokenLogo.view
        { logoUrl = Nothing, symbol = "FOO", size = 24 }

The image is `loading="lazy"` (token lists are long) with `alt` set to the
symbol. The tile carries `role="img"` and `aria-label` with the symbol so
screen readers announce the same thing either way. Sizing uses width/height
attributes (img) and SVG width/height (tile) -- the same convention as
`Web3.Ui.Identicon` -- never inline styles.

CSS classes: `web3-tokenlogo`, `web3-tokenlogo--img`, `web3-tokenlogo--tile`,
`web3-tokenlogo--hue-0` ... `web3-tokenlogo--hue-7`.

@docs view, Config

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Svg
import Svg.Attributes as SA


{-| What to render: the logo URL if known, the token symbol (alt text and
tile letters), and the pixel size.
-}
type alias Config =
    { logoUrl : Maybe String
    , symbol : String
    , size : Int
    }


{-| Render the logo image, or the letter-tile fallback when `logoUrl` is
`Nothing`.
-}
view : Config -> Html msg
view cfg =
    case cfg.logoUrl of
        Just url ->
            Html.img
                [ Attr.class "web3-tokenlogo web3-tokenlogo--img"
                , Attr.src url
                , Attr.alt cfg.symbol
                , Attr.attribute "loading" "lazy"
                , Attr.width cfg.size
                , Attr.height cfg.size
                ]
                []

        Nothing ->
            tile cfg



-- INTERNAL


tile : Config -> Html msg
tile cfg =
    let
        px =
            String.fromInt cfg.size
    in
    Html.span
        [ Attr.class "web3-tokenlogo web3-tokenlogo--tile"
        , Attr.class ("web3-tokenlogo--hue-" ++ String.fromInt (hue cfg.symbol))
        , Attr.attribute "role" "img"
        , Attr.attribute "aria-label" cfg.symbol
        ]
        [ Svg.svg
            [ SA.viewBox "0 0 24 24"
            , SA.width px
            , SA.height px
            ]
            [ Svg.text_
                [ SA.x "12"
                , SA.y "12"
                , SA.textAnchor "middle"
                , SA.dominantBaseline "central"
                ]
                [ Svg.text (letters cfg.symbol) ]
            ]
        ]


{-| First 1-2 characters of the symbol, uppercased. -}
letters : String -> String
letters symbol =
    String.toUpper (String.left 2 symbol)


{-| Deterministic hue bucket 0-7 from the symbol's character codes. -}
hue : String -> Int
hue symbol =
    symbol
        |> String.toList
        |> List.map Char.toCode
        |> List.sum
        |> modBy 8
