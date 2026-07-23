module Web3.Ui.Identicon exposing (view, cells, Cells)

{-| Deterministic address identicons -- the classic 8x8 "blockies" every
wallet renders, in pure Elm.

Faithful port of the canonical `ethereum/blockies` algorithm (xorshift PRNG
seeded from the lowercased address, three HSL colors, 8-wide vertically
mirrored grid), so the identicon for an address here matches the one users
already recognise from MetaMask et al. Recognition is the whole point of an
identicon -- a pretty-but-different avatar would be worse than none.

    Identicon.view [] { size = 24 } holderAddress

Rendered as an inline SVG (`viewBox 0 0 8 8`, crisp edges) so it scales
losslessly to any `size`. The three colors are data -- derived from the
address -- so they are set as SVG `fill` attributes; everything else
(border-radius for circular crops, borders, drop shadows) belongs to your
CSS via the `web3-identicon` class.

    .web3-identicon { border-radius: 50%; }   /* circular crop */

CSS class: `web3-identicon`.

@docs view, cells, Cells

-}

import Bitwise
import Html.Attributes as Attr
import Html exposing (Html)
import Svg exposing (Svg)
import Svg.Attributes as SA
import Web3.Types as T


{-| The raw material of an identicon, for custom renderers (canvas, PNG
export): three CSS color strings and the 64-cell grid in row-major order.
Cell values: `0` background, `1` color, `2` spot color.
-}
type alias Cells =
    { color : String
    , bgColor : String
    , spotColor : String
    , grid : List Int
    }


{-| Render the identicon for an address at a given pixel size.

The `attrs` land on an `Html.span` wrapper (class `web3-identicon`), not on
the SVG itself -- `Html.Attributes.class` sets the `className` *property*,
which is read-only on SVG nodes and would crash at runtime. The wrapper
makes any `Html.Attribute` safe to pass.

-}
view : List (Html.Attribute msg) -> { size : Int } -> T.Address -> Html msg
view attrs opts addr =
    let
        c =
            cells (T.addressToString addr)

        px =
            String.fromInt opts.size
    in
    Html.span
        (Attr.class "web3-identicon" :: attrs)
        [ Svg.svg
            [ SA.viewBox "0 0 8 8"
            , SA.width px
            , SA.height px
            , SA.shapeRendering "crispEdges"
            ]
            (Svg.rect
                [ SA.x "0", SA.y "0", SA.width "8", SA.height "8", SA.fill c.bgColor ]
                []
                :: List.filterMap identity (List.indexedMap (cell c) c.grid)
            )
        ]


cell : Cells -> Int -> Int -> Maybe (Svg msg)
cell c index value =
    let
        fill =
            case value of
                1 ->
                    Just c.color

                2 ->
                    Just c.spotColor

                _ ->
                    Nothing
    in
    Maybe.map
        (\f ->
            Svg.rect
                [ SA.x (String.fromInt (modBy 8 index))
                , SA.y (String.fromInt (index // 8))
                , SA.width "1"
                , SA.height "1"
                , SA.fill f
                ]
                []
        )
        fill


{-| Compute the colors and grid for any seed string (normally the lowercase
`0x...` address -- [`view`](#view) handles that for you). Deterministic: the
same seed always yields the same `Cells`.
-}
cells : String -> Cells
cells seedString =
    let
        seed0 =
            seedFromString seedString

        -- Canonical consumption order: color, bgcolor, spotcolor, then grid.
        ( color, seed1 ) =
            nextColor seed0

        ( bgColor, seed2 ) =
            nextColor seed1

        ( spotColor, seed3 ) =
            nextColor seed2

        ( grid, _ ) =
            buildGrid seed3
    in
    { color = color, bgColor = bgColor, spotColor = spotColor, grid = grid }



-- PRNG — canonical blockies xorshift over four int32 lanes.
--
-- Elm Ints are JS numbers and Bitwise ops coerce to int32 exactly like the
-- JS operators, so this is semantics-identical to the reference
-- implementation — including its quirks (rand() ranges over [0, 2): CSS
-- clamps the out-of-range hues/percentages the same way browsers do for
-- the original).


type alias Seed =
    { a : Int, b : Int, c : Int, d : Int }


seedFromString : String -> Seed
seedFromString s =
    List.foldl mix { a = 0, b = 0, c = 0, d = 0 }
        (List.indexedMap Tuple.pair (String.toList s))


mix : ( Int, Char ) -> Seed -> Seed
mix ( i, char ) seed =
    let
        stir lane =
            Bitwise.shiftLeftBy 5 lane - lane + Char.toCode char
    in
    case modBy 4 i of
        0 ->
            { seed | a = stir seed.a }

        1 ->
            { seed | b = stir seed.b }

        2 ->
            { seed | c = stir seed.c }

        _ ->
            { seed | d = stir seed.d }


rand : Seed -> ( Float, Seed )
rand seed =
    let
        t =
            Bitwise.xor seed.a (Bitwise.shiftLeftBy 11 seed.a)

        d =
            seed.d
                |> Bitwise.xor (Bitwise.shiftRightBy 19 seed.d)
                |> Bitwise.xor t
                |> Bitwise.xor (Bitwise.shiftRightBy 8 t)

        unsigned =
            toFloat (Bitwise.shiftRightZfBy 0 d)
    in
    ( unsigned / 2147483648
    , { a = seed.b, b = seed.c, c = seed.d, d = d }
    )


nextColor : Seed -> ( String, Seed )
nextColor seed0 =
    let
        ( hr, seed1 ) =
            rand seed0

        ( sr, seed2 ) =
            rand seed1

        ( l1, seed3 ) =
            rand seed2

        ( l2, seed4 ) =
            rand seed3

        ( l3, seed5 ) =
            rand seed4

        ( l4, seed6 ) =
            rand seed5

        hue =
            String.fromInt (floor (hr * 360))

        saturation =
            String.fromFloat (sr * 60 + 40)

        lightness =
            String.fromFloat ((l1 + l2 + l3 + l4) * 25)
    in
    ( "hsl(" ++ hue ++ "," ++ saturation ++ "%," ++ lightness ++ "%)"
    , seed6
    )


{-| 8 rows; each row draws 4 values and mirrors them, so the icon is
symmetric about its vertical axis -- the trait that makes blockies read as
"faces".
-}
buildGrid : Seed -> ( List Int, Seed )
buildGrid seed0 =
    List.foldl
        (\_ ( rows, seed ) ->
            let
                ( half, seed_ ) =
                    randList 4 seed
            in
            ( rows ++ half ++ List.reverse half, seed_ )
        )
        ( [], seed0 )
        (List.range 0 7)


randList : Int -> Seed -> ( List Int, Seed )
randList n seed0 =
    List.foldl
        (\_ ( acc, seed ) ->
            let
                ( r, seed_ ) =
                    rand seed
            in
            ( acc ++ [ floor (r * 2.3) ], seed_ )
        )
        ( [], seed0 )
        (List.range 1 n)
