module Web3.Ui.ContractRead exposing
    ( view, Config
    , Status(..)
    , isIdle, isPending, isTerminal
    )

{-| Render a Solidity `view` / `pure` function call as a typed form: function
name header, one [`AbiInput`](Web3-Ui-AbiInput) per argument, a "Read"
button, and a result panel that pattern-matches on the current `Status`.

Like every primitive in this lib, the component is **stateless** — the
caller owns the `args` (one `AbiInput.Config` per argument) and the
`status` and passes them in on every render. The lib renders, the caller
wires the result back through `update`.

Pair with [`Web3.Contract.Call`](https://package.elm-lang.org/packages/intrepidshape/elm-web3/latest/Web3-Contract-Call)
to actually fire the read:

    -- in update
    Read fn ->
        ( { model | reads = Dict.insert fn Pending model.reads }
        , web3Cmd
            (Call.encode
                (Call.readCall
                    { contract = tokenAddress
                    , method = "balanceOf(address)"
                    , args = [ resolvedArg ]
                    , decoder = Decode.uint256
                    , id = fn
                    }
                )
            )
        )

    -- in view
    Web3.Ui.ContractRead.view []
        { name = "balanceOf"
        , solType = "uint256"
        , args = [ holderArgConfig ]
        , status = Maybe.withDefault Idle (Dict.get "balanceOf" model.reads)
        , onRead = Read "balanceOf"
        , readLabel = "Read"
        }

CSS classes: `web3-contract-read`, `web3-contract-read__header`,
`web3-contract-read__name`, `web3-contract-read__return-type`,
`web3-contract-read__args`, `web3-contract-read__button`,
`web3-contract-read__pending`, `web3-contract-read__result`,
`web3-contract-read__result--success`, `web3-contract-read__result--failed`.

@docs view, Config
@docs Status
@docs isIdle, isPending, isTerminal

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Web3.Ui.AbiInput as AbiInput



-- STATUS --------------------------------------------------------------------


{-| Lifecycle of a single read.

`Success String` carries the rendered result — the caller stringifies the
typed value (using whatever `Web3.Abi.Decode`-produced value they decoded).
This keeps `ContractRead` agnostic to the result type.
-}
type Status
    = Idle
    | Pending
    | Success String
    | Failed String


{-| `True` for `Idle`. -}
isIdle : Status -> Bool
isIdle s =
    case s of
        Idle ->
            True

        _ ->
            False


{-| `True` for `Pending`. -}
isPending : Status -> Bool
isPending s =
    case s of
        Pending ->
            True

        _ ->
            False


{-| `True` for `Success _` and `Failed _`. -}
isTerminal : Status -> Bool
isTerminal s =
    case s of
        Success _ ->
            True

        Failed _ ->
            True

        _ ->
            False



-- VIEW ----------------------------------------------------------------------


{-| Configuration for `view`.

  - `name` — the function name to display (e.g. `"balanceOf"`).
  - `solType` — the return type string for display (e.g. `"uint256"`).
  - `args` — one [`AbiInput`](Web3-Ui-AbiInput) config per ABI argument.
  - `status` — current lifecycle state.
  - `onRead` — message dispatched when the user clicks the read button.
  - `readLabel` — button label when idle / terminal (e.g. `"Read"` or `"Refresh"`).

-}
type alias Config msg =
    { name : String
    , solType : String
    , args : List (AbiInput.Config msg)
    , status : Status
    , onRead : msg
    , readLabel : String
    }


{-| Render the read form. -}
view : List (Html.Attribute msg) -> Config msg -> Html msg
view attrs opts =
    Html.div
        ([ Attr.class "web3-contract-read"
         , Attr.classList [ ( "web3-contract-read--pending", isPending opts.status ) ]
         ]
            ++ attrs
        )
        [ headerView opts
        , argsView opts
        , buttonView opts
        , resultView opts.status
        ]


headerView : Config msg -> Html msg
headerView opts =
    Html.div [ Attr.class "web3-contract-read__header" ]
        [ Html.span [ Attr.class "web3-contract-read__name" ]
            [ Html.text opts.name ]
        , Html.span [ Attr.class "web3-contract-read__return-type" ]
            [ Html.text ("returns " ++ opts.solType) ]
        ]


argsView : Config msg -> Html msg
argsView opts =
    if List.isEmpty opts.args then
        Html.text ""

    else
        Html.div [ Attr.class "web3-contract-read__args" ]
            (List.map (AbiInput.view []) opts.args)


buttonView : Config msg -> Html msg
buttonView opts =
    let
        label =
            if isPending opts.status then
                "Reading…"

            else
                opts.readLabel
    in
    Html.button
        [ Attr.class "web3-contract-read__button"
        , Attr.type_ "button"
        , Attr.disabled (isPending opts.status)
        , Events.onClick opts.onRead
        ]
        [ Html.text label ]


resultView : Status -> Html msg
resultView status =
    case status of
        Idle ->
            Html.text ""

        Pending ->
            Html.div [ Attr.class "web3-contract-read__pending" ]
                [ Html.text "Reading…" ]

        Success rendered ->
            Html.div
                [ Attr.class "web3-contract-read__result"
                , Attr.class "web3-contract-read__result--success"
                ]
                [ Html.text rendered ]

        Failed err ->
            Html.div
                [ Attr.class "web3-contract-read__result"
                , Attr.class "web3-contract-read__result--failed"
                ]
                [ Html.text err ]
