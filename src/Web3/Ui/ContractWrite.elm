module Web3.Ui.ContractWrite exposing (view, Config)

{-| Render a Solidity write function (non-payable or payable) as a typed
form: function name header, one [`AbiInput`](Web3-Ui-AbiInput) per
argument, an optional `msg.value` input for `payable` functions, a "Send"
button wired through the [`Tx.Status`](https://package.elm-lang.org/packages/intrepidshape/elm-web3/latest/Web3-Transaction#Status)
state machine, and a status badge plus tx-hash link below.

Like every primitive in this lib, the component is **stateless** — the
caller owns the `args`, the `msgValue` input buffer, and the `txStatus`
and passes them in on every render.

A complete write flow looks like this:

    -- in update
    Send fn ->
        case resolveArgs model fn of
            Ok args ->
                ( { model | tx = Tx.update Tx.TxSent model.tx }
                , web3Cmd
                    (Send.encode
                        (Send.writeCall
                            { contract = tokenAddress
                            , method = "approve"
                            , args = args
                            }
                        )
                    )
                )

            Err _ ->
                ( model, Cmd.none )

    -- in view
    Web3.Ui.ContractWrite.view []
        { name = "approve"
        , args = [ spenderArg, amountArg ]
        , payable = Nothing
        , txStatus = model.tx
        , onSend = Send "approve"
        , sendLabel = "Approve"
        , pendingLabel = "Approving…"
        , explorerUrl = Just "https://scan.pulsechain.com/tx/"
        }

CSS classes: `web3-contract-write`, `web3-contract-write__header`,
`web3-contract-write__name`, `web3-contract-write__mutability`,
`web3-contract-write__args`, `web3-contract-write__value`,
`web3-contract-write__value-label`, `web3-contract-write__footer`,
`web3-contract-write__error`.

@docs view, Config

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Web3.Transaction as Tx
import Web3.Ui.AbiInput as AbiInput
import Web3.Ui.Input as Input
import Web3.Ui.Transaction as TxUi



-- VIEW ----------------------------------------------------------------------


{-| Configuration for `view`.

  - `name` — the function name to display (e.g. `"approve"`).
  - `args` — one [`AbiInput`](Web3-Ui-AbiInput) config per ABI argument.
  - `payable` — for `payable` functions, the `msg.value` input state and
    callback; `Nothing` for non-payable.
  - `txStatus` — current transaction lifecycle state.
  - `onSend` — message dispatched when the user clicks the send button.
  - `sendLabel` — button label when the tx is idle (e.g. `"Approve"`).
  - `pendingLabel` — button label while the tx is in-flight (e.g. `"Approving…"`).
  - `explorerUrl` — optional explorer URL prefix for the tx-hash link;
    `Nothing` renders the hash as plain text (useful in local dev).

-}
type alias Config msg =
    { name : String
    , args : List (AbiInput.Config msg)
    , payable :
        Maybe
            { value : String
            , onValueChange : String -> msg
            , valid : Bool
            }
    , txStatus : Tx.Status
    , onSend : msg
    , sendLabel : String
    , pendingLabel : String
    , explorerUrl : Maybe String
    }


{-| Render the write form. -}
view : List (Html.Attribute msg) -> Config msg -> Html msg
view attrs opts =
    Html.div
        ([ Attr.class "web3-contract-write"
         , Attr.classList
            [ ( "web3-contract-write--pending", Tx.isPending opts.txStatus )
            , ( "web3-contract-write--terminal", Tx.isTerminal opts.txStatus )
            ]
         ]
            ++ attrs
        )
        [ headerView opts
        , argsView opts
        , valueView opts
        , buttonRow opts
        , footerView opts
        ]


headerView : Config msg -> Html msg
headerView opts =
    let
        mutability =
            case opts.payable of
                Just _ ->
                    "payable"

                Nothing ->
                    "nonpayable"
    in
    Html.div [ Attr.class "web3-contract-write__header" ]
        [ Html.span [ Attr.class "web3-contract-write__name" ]
            [ Html.text opts.name ]
        , Html.span [ Attr.class "web3-contract-write__mutability" ]
            [ Html.text mutability ]
        ]


argsView : Config msg -> Html msg
argsView opts =
    if List.isEmpty opts.args then
        Html.text ""

    else
        Html.div [ Attr.class "web3-contract-write__args" ]
            (List.map (AbiInput.view []) opts.args)


valueView : Config msg -> Html msg
valueView opts =
    case opts.payable of
        Nothing ->
            Html.text ""

        Just pay ->
            Html.div [ Attr.class "web3-contract-write__value" ]
                [ Html.label
                    [ Attr.class "web3-contract-write__value-label" ]
                    [ Html.text "msg.value"
                    , Html.span [ Attr.class "web3-contract-write__value-unit" ]
                        [ Html.text " (wei)" ]
                    ]
                , Input.bigInt []
                    { value = pay.value
                    , onInput = pay.onValueChange
                    , valid = pay.valid
                    }
                ]


buttonRow : Config msg -> Html msg
buttonRow opts =
    Html.div [ Attr.class "web3-contract-write__button-row" ]
        [ TxUi.actionButton []
            { label = opts.sendLabel
            , pendingLabel = opts.pendingLabel
            , onPress = opts.onSend
            }
            opts.txStatus
        , TxUi.statusBadge [] opts.txStatus
        ]


footerView : Config msg -> Html msg
footerView opts =
    let
        maybeHashLink =
            TxUi.statusHashLink [] { explorerUrl = opts.explorerUrl } opts.txStatus

        maybeErrorLine =
            case opts.txStatus of
                Tx.Failed err ->
                    Just
                        (Html.div [ Attr.class "web3-contract-write__error" ]
                            [ Html.text err ]
                        )

                _ ->
                    Nothing
    in
    Html.div [ Attr.class "web3-contract-write__footer" ]
        (List.filterMap identity [ maybeHashLink, maybeErrorLine ])
