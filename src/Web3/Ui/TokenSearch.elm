module Web3.Ui.TokenSearch exposing (view)

{-| Search input for filtering a token list by name/symbol/address. Generic
across any dapp that lists tokens (launchpad, DEX, vault aggregator, NFT
collection picker).

    Web3.Ui.TokenSearch.view
        { value = model.query
        , onInput = QueryChanged
        , placeholder = "Search tokens..."
        }

The component does not perform filtering — it just renders the input and
emits change events. Filter logic is the consumer's responsibility (an
`on*Match` predicate that compares against `name`, `symbol`, `address`).

CSS classes: `web3-tokensearch`, `web3-tokensearch__input`, `web3-tokensearch__icon`.

@docs view

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events


{-| Render the search input. -}
view :
    { value : String
    , onInput : String -> msg
    , placeholder : String
    }
    -> Html msg
view opts =
    Html.div [ Attr.class "web3-tokensearch" ]
        [ Html.span
            [ Attr.class "web3-tokensearch__icon"
            , Attr.attribute "aria-hidden" "true"
            ]
            [ Html.text "⌕" ]
        , Html.input
            [ Attr.class "web3-tokensearch__input"
            , Attr.type_ "search"
            , Attr.value opts.value
            , Attr.placeholder opts.placeholder
            , Attr.attribute "autocomplete" "off"
            , Attr.attribute "spellcheck" "false"
            , Events.onInput opts.onInput
            ]
            []
        ]
