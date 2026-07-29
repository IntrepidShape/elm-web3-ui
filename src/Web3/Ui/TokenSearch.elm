module Web3.Ui.TokenSearch exposing (view, Config)

{-| Search input for filtering a token list by name/symbol/address. Generic
across any dapp that lists tokens (launchpad, DEX, vault aggregator, NFT
collection picker).

    Web3.Ui.TokenSearch.view []
        { value = model.query
        , onInput = QueryChanged
        , placeholder = "Search tokens..."
        , inputAttrs = []
        }

The component does not perform filtering -- it just renders the input and
emits change events. Filter logic is the consumer's responsibility (an
`on*Match` predicate that compares against `name`, `symbol`, `address`).

CSS classes: `web3-tokensearch`, `web3-tokensearch__input`, `web3-tokensearch__icon`.

@docs view, Config

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events


{-| The query string, where edits go, the placeholder, and `inputAttrs` for
the inner `<input type="search">`.

The root is the wrapper that also carries the magnifier glyph, so the first
positional argument cannot address the control -- `id`, `autofocus` and
`aria-controls` (pointing at the list this input filters) belong on the
control, and that is what `inputAttrs` is for.

-}
type alias Config msg =
    { value : String
    , onInput : String -> msg
    , placeholder : String
    , inputAttrs : List (Html.Attribute msg)
    }


{-| Render the search input. -}
view : List (Html.Attribute msg) -> Config msg -> Html msg
view attrs opts =
    Html.div (Attr.class "web3-tokensearch" :: attrs)
        [ Html.span
            [ Attr.class "web3-tokensearch__icon"
            , Attr.attribute "aria-hidden" "true"
            ]
            [ Html.text "⌕" ]
        , Html.input
            ([ Attr.class "web3-tokensearch__input"
             , Attr.type_ "search"
             , Attr.value opts.value
             , Attr.placeholder opts.placeholder
             , Attr.attribute "autocomplete" "off"
             , Attr.attribute "spellcheck" "false"
             , Events.onInput opts.onInput
             ]
                ++ opts.inputAttrs
            )
            []
        ]
