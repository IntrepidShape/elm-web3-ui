module Web3.Ui.VeLock exposing
    ( view
    , Config
    , veBalance
    )

{-| Lock-duration picker for vote-escrow tokens (Curve veCRV, GMX esGMX,
veToken, ...). Renders an amount input, a lock-period slider snapped
to a configurable step (typically 1 week, the Curve standard), and a live
projection of the resulting ve-balance.

Linear-decay vote-escrow standard:

    veBalance = amount * lockSec / maxLockSec

So a maximum-length lock yields ve-balance equal to the principal; a quarter
of max-length yields a quarter of the principal.

    Web3.Ui.VeLock.view
        { amount = model.lockAmount
        , amountInput = model.lockAmountInput
        , decimals = 18
        , symbol = "TKN"
        , veSymbol = "veToken"
        , lockSec = model.lockSec
        , minLockSec = oneWeek
        , maxLockSec = fourYears
        , stepSec = oneWeek
        , onAmountInput = LockAmountInput
        , onLockChange = LockSecChanged
        }

CSS classes: `web3-velock`, `web3-velock__amount`, `web3-velock__slider`,
`web3-velock__readout`, `web3-velock__preview`, `web3-velock__preview-label`,
`web3-velock__preview-value`. Caller provides colors via stylesheet.

@docs view, Config, veBalance

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode as Decode
import Web3.BigInt as BigInt exposing (BigInt)
import Web3.Ui.Amount as Amount


{-| All configuration. `amount` is the principal as `BigInt` (used for the
ve-balance projection). `amountInput` is the live string in the input box
(separate so the consumer owns parse/validation state). `lockSec` is the
chosen lock duration in seconds. `stepSec` is the slider granularity --
pass `604800` (1 week) to match Curve's snap-to-week semantics.
-}
type alias Config msg =
    { amount : BigInt
    , amountInput : String
    , decimals : Int
    , symbol : String
    , veSymbol : String
    , lockSec : Int
    , minLockSec : Int
    , maxLockSec : Int
    , stepSec : Int
    , onAmountInput : String -> msg
    , onLockChange : Int -> msg
    }


{-| Pure helper: project ve-balance from principal + chosen lock + max lock.
Mirrors the on-chain formula `amount * lockSec / maxLockSec`. Returns
`BigInt.fromInt 0` if `maxLockSec` is non-positive.
-}
veBalance : { amount : BigInt, lockSec : Int, maxLockSec : Int } -> BigInt
veBalance opts =
    if opts.maxLockSec <= 0 then
        BigInt.fromInt 0

    else
        case BigInt.fromInt opts.lockSec of
            lockB ->
                case BigInt.fromInt opts.maxLockSec of
                    maxB ->
                        case BigInt.div (BigInt.mul opts.amount lockB) maxB of
                            Just v ->
                                v

                            Nothing ->
                                BigInt.fromInt 0


{-| Render the picker. -}
view : Config msg -> Html msg
view cfg =
    let
        previewWei =
            veBalance
                { amount = cfg.amount
                , lockSec = cfg.lockSec
                , maxLockSec = cfg.maxLockSec
                }

        previewText =
            Amount.formatWei cfg.decimals previewWei
    in
    Html.div [ Attr.class "web3-velock" ]
        [ Html.div [ Attr.class "web3-velock__amount" ]
            [ Amount.amountInput []
                { value = cfg.amountInput
                , onInput = cfg.onAmountInput
                , decimals = cfg.decimals
                , symbol = cfg.symbol
                , valid = True
                }
            ]
        , Html.input
            [ Attr.class "web3-velock__slider"
            , Attr.type_ "range"
            , Attr.min (String.fromInt cfg.minLockSec)
            , Attr.max (String.fromInt cfg.maxLockSec)
            , Attr.step (String.fromInt cfg.stepSec)
            , Attr.value (String.fromInt cfg.lockSec)
            -- Use the `change` event (fires once on pointer release)
            -- rather than `input` (fires every drag frame). A dapp
            -- debug trace captured 223 LockSecChange msgs from a
            -- single user drag — each ran the Elm view; ten msgs
            -- per drag is plenty for an Elm update loop.
            , Events.on "change" (Decode.map cfg.onLockChange targetValueAsInt)
            ]
            []
        , Html.output
            [ Attr.class "web3-velock__readout"
            , Attr.title (String.fromInt cfg.lockSec ++ " seconds")
            ]
            [ Html.text (humanDuration cfg.lockSec) ]
        , Html.div [ Attr.class "web3-velock__preview" ]
            [ Html.span
                [ Attr.class "web3-velock__preview-label" ]
                [ Html.text "you receive" ]
            , Html.span
                [ Attr.class "web3-velock__preview-value" ]
                [ Html.text previewText
                , Html.text " "
                , Html.text cfg.veSymbol
                ]
            ]
        ]


targetValueAsInt : Decode.Decoder Int
targetValueAsInt =
    Decode.at [ "target", "value" ] Decode.string
        |> Decode.andThen
            (\s ->
                case String.toInt s of
                    Just n ->
                        Decode.succeed n

                    Nothing ->
                        Decode.fail ("not an int: " ++ s)
            )


humanDuration : Int -> String
humanDuration sec =
    let
        week =
            604800

        year =
            31536000

        month =
            2592000
    in
    if sec >= year then
        let
            years =
                sec // year

            remMonths =
                modBy year sec // month
        in
        String.fromInt years
            ++ plural years "y"
            ++ (if remMonths == 0 then
                    ""

                else
                    " " ++ String.fromInt remMonths ++ "mo"
               )

    else if sec >= month then
        let
            months =
                sec // month

            remWeeks =
                modBy month sec // week
        in
        String.fromInt months
            ++ "mo"
            ++ (if remWeeks == 0 then
                    ""

                else
                    " " ++ String.fromInt remWeeks ++ "w"
               )

    else if sec >= week then
        let
            weeks =
                sec // week
        in
        String.fromInt weeks ++ plural weeks "w"

    else
        let
            days =
                sec // 86400
        in
        String.fromInt (max 1 days) ++ "d"


plural : Int -> String -> String
plural _ unit =
    unit
