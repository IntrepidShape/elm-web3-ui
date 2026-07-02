module Web3.Ui.Revert exposing (banner, toast, reason, bannerWith, toastWith)

{-| Human-readable revert reasons. elm-web3 can decode `Error(string)`
revert data (`Web3.Abi.Decode.decodeRevertReason`) — this module is the
missing last mile that actually shows it to the user instead of a raw
`0x08c379a0…` blob.

    case model.txError of
        Just raw ->
            Revert.banner [] { onDismiss = Just DismissError } raw

        Nothing ->
            Html.text ""

Decoding is best-effort and honest about it: a decodable `Error(string)`
payload renders its message; anything else (custom solc errors, empty
reverts, out-of-gas) renders a labelled fallback with the truncated selector
so the information is preserved, never invented.

CSS classes: `web3-revert`, `web3-revert--decoded`, `web3-revert--raw`,
`web3-revert__reason`, `web3-revert__dismiss`, `web3-revert-toast`.

@docs banner, toast, reason
@docs bannerWith, toastWith

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Web3.Abi.Decode as Decode


{-| Extract the best human-readable string from raw revert data.
`Ok message` when it decoded as `Error(string)`; `Err shortForm` (a
truncated hex selector, or the raw input for non-hex strings) when it
did not.
-}
reason : String -> Result String String
reason raw =
    case Decode.decodeRevertReason raw of
        Just message ->
            Ok message

        Nothing ->
            Err (shorten raw)


{-| An inline error banner (`role="alert"` — screen readers announce it).
Pass `onDismiss = Just msg` to get a dismiss button.
-}
banner : List (Html.Attribute msg) -> { onDismiss : Maybe msg } -> String -> Html msg
banner attrs opts raw =
    body "web3-revert" attrs opts raw


{-| The same content shaped for a toast/notification stack. -}
toast : List (Html.Attribute msg) -> { onDismiss : Maybe msg } -> String -> Html msg
toast attrs opts raw =
    body "web3-revert-toast" attrs opts raw



-- INTERNAL


body : String -> List (Html.Attribute msg) -> { onDismiss : Maybe msg } -> String -> Html msg
body baseClass attrs opts raw =
    let
        ( modifier, text ) =
            case reason raw of
                Ok message ->
                    ( "decoded", message )

                Err short ->
                    ( "raw", "Transaction reverted (" ++ short ++ ")" )

        dismiss =
            case opts.onDismiss of
                Just msg ->
                    [ Html.button
                        [ Attr.class "web3-revert__dismiss"
                        , Attr.attribute "aria-label" "Dismiss"
                        , Events.onClick msg
                        ]
                        [ Html.text "×" ]
                    ]

                Nothing ->
                    []
    in
    Html.div
        (Attr.class baseClass
            :: Attr.class (baseClass ++ "--" ++ modifier)
            :: Attr.attribute "role" "alert"
            :: attrs
        )
        (Html.span [ Attr.class "web3-revert__reason" ] [ Html.text text ]
            :: dismiss
        )


shorten : String -> String
shorten raw =
    if String.startsWith "0x" raw && String.length raw > 12 then
        String.left 10 raw ++ "…"

    else if String.isEmpty raw then
        "no revert data"

    else
        String.left 40 raw


{-| Like [`banner`](#banner), but tries a typed custom-error decoder first —
pass elm-web3's `Abi.Decode.decodeCustomError yourFragments` (>= 1.4.0). A
decoded custom error renders its name and args
(`web3-revert--custom`, name in `web3-revert__name`); anything else falls
through to the standard `Error(string)` path.
-}
bannerWith :
    List (Html.Attribute msg)
    -> { onDismiss : Maybe msg
       , decode : String -> Maybe { name : String, args : List String }
       }
    -> String
    -> Html msg
bannerWith =
    withCustom "web3-revert"


{-| Toast-shaped sibling of [`bannerWith`](#bannerWith). -}
toastWith :
    List (Html.Attribute msg)
    -> { onDismiss : Maybe msg
       , decode : String -> Maybe { name : String, args : List String }
       }
    -> String
    -> Html msg
toastWith =
    withCustom "web3-revert-toast"


withCustom :
    String
    -> List (Html.Attribute msg)
    -> { onDismiss : Maybe msg
       , decode : String -> Maybe { name : String, args : List String }
       }
    -> String
    -> Html msg
withCustom baseClass attrs opts raw =
    case opts.decode raw of
        Just err ->
            Html.div
                (Attr.class baseClass
                    :: Attr.class (baseClass ++ "--custom")
                    :: Attr.attribute "role" "alert"
                    :: attrs
                )
                (Html.span [ Attr.class "web3-revert__name" ] [ Html.text err.name ]
                    :: Html.span [ Attr.class "web3-revert__reason" ]
                        [ Html.text (String.join ", " err.args) ]
                    :: (case opts.onDismiss of
                            Just msg ->
                                [ Html.button
                                    [ Attr.class "web3-revert__dismiss"
                                    , Attr.attribute "aria-label" "Dismiss"
                                    , Events.onClick msg
                                    ]
                                    [ Html.text "×" ]
                                ]

                            Nothing ->
                                []
                       )
                )

        Nothing ->
            body baseClass attrs { onDismiss = opts.onDismiss } raw
