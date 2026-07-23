module Web3.Ui.Skeleton exposing (line, block, circle, pill, address, amount)

{-| Loading placeholders shaped like the things they stand in for.

Every read-heavy dapp needs these; pairing each atom with a skeleton of the
same silhouette keeps layouts from jumping when data lands. All shimmer and
color comes from your CSS -- the classes are the whole API:

    .web3-skeleton {
        background: linear-gradient(90deg, #222 25%, #333 50%, #222 75%);
        background-size: 200% 100%;
        animation: web3-shimmer 1.4s infinite;
        border-radius: 4px;
    }
    @keyframes web3-shimmer {
        to { background-position: -200% 0; }
    }

Each helper renders a `<span>` (or `<div>` for `block`) that is
`aria-hidden` -- the loading announcement belongs on the container (see
`Web3.Ui.RemoteCall.view`, which sets `aria-busy`), not on each bone.

CSS classes: `web3-skeleton`, plus a shape modifier --
`web3-skeleton--line`, `--block`, `--circle`, `--pill`, `--address`,
`--amount`.

@docs line, block, circle, pill, address, amount

-}

import Html exposing (Html)
import Html.Attributes as Attr


{-| A one-line text placeholder. -}
line : List (Html.Attribute msg) -> Html msg
line =
    bone Html.span "line"


{-| A rectangular area placeholder (cards, charts). -}
block : List (Html.Attribute msg) -> Html msg
block =
    bone Html.div "block"


{-| A circular placeholder (identicons, token logos). -}
circle : List (Html.Attribute msg) -> Html msg
circle =
    bone Html.span "circle"


{-| A rounded chip placeholder (badges, buttons). -}
pill : List (Html.Attribute msg) -> Html msg
pill =
    bone Html.span "pill"


{-| Sized like a truncated address (`0x1234...abcd`). -}
address : List (Html.Attribute msg) -> Html msg
address =
    bone Html.span "address"


{-| Sized like a token amount. -}
amount : List (Html.Attribute msg) -> Html msg
amount =
    bone Html.span "amount"



-- INTERNAL


bone :
    (List (Html.Attribute msg) -> List (Html msg) -> Html msg)
    -> String
    -> List (Html.Attribute msg)
    -> Html msg
bone el shape attrs =
    el
        (Attr.class "web3-skeleton"
            :: Attr.class ("web3-skeleton--" ++ shape)
            :: Attr.attribute "aria-hidden" "true"
            :: attrs
        )
        []
