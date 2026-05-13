module Web3.Ui.TradeTabs exposing (view, Tab)

{-| Generic tab switcher for trade UIs (Buy / Sell / Stake, or any other
named tab set). Single-select, button-based, accessible.

    type TradeTab = BuyTab | SellTab | StakeTab

    Web3.Ui.TradeTabs.view
        { current = model.tradeTab
        , onSelect = ChangeTradeTab
        , tabs =
            [ { id = BuyTab,   label = "Buy" }
            , { id = SellTab,  label = "Sell" }
            , { id = StakeTab, label = "Stake" }
            ]
        }

CSS classes: `web3-tradetabs`, `web3-tradetabs__tab`, `web3-tradetabs__tab--active`.

@docs view, Tab

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events


{-| One tab definition. `id` is your app's tab type; `label` is what users see. -}
type alias Tab id =
    { id : id
    , label : String
    }


{-| Render the switcher. -}
view :
    { current : id
    , onSelect : id -> msg
    , tabs : List (Tab id)
    }
    -> Html msg
view opts =
    Html.div
        [ Attr.class "web3-tradetabs"
        , Attr.attribute "role" "tablist"
        ]
        (List.map (tabButton opts) opts.tabs)


tabButton : { a | current : id, onSelect : id -> msg } -> Tab id -> Html msg
tabButton opts tab =
    let
        active =
            tab.id == opts.current

        cls =
            if active then
                "web3-tradetabs__tab web3-tradetabs__tab--active"

            else
                "web3-tradetabs__tab"
    in
    Html.button
        [ Attr.class cls
        , Attr.type_ "button"
        , Attr.attribute "role" "tab"
        , Attr.attribute "aria-selected"
            (if active then
                "true"

             else
                "false"
            )
        , Events.onClick (opts.onSelect tab.id)
        ]
        [ Html.text tab.label ]
