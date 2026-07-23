module Web3.Ui.BondCard exposing
    ( view
    , Config
    )

{-| Card for a fixed-term bond receipt: principal locked for a maturity
period, accruing some pro-rata yield from a shared pool, redeemable at
maturity (or rolled for another term). Generic for any term-deposit
primitive (OHM-style bonds, fixed-term deposits, treasury bills, ...).

```elm
Web3.Ui.BondCard.view
    { bondId = receipt.id
    , principal = receipt.principal
    , principalSymbol = "PLS"
    , decimals = 18
    , maturitySec = receipt.maturity
    , nowSec = model.nowSec
    , pendingYield = receipt.pendingYield
    , yieldSymbol = "PLS"
    , onClaimYield = Just (ClaimYield receipt.id)
    , onRedeem = Just (Redeem receipt.id)
    , onRoll = Just (Roll receipt.id)
    }
```

CSS classes: `web3-bondcard`, `web3-bondcard__id`, `web3-bondcard__principal`,
`web3-bondcard__maturity`, `web3-bondcard__yield`, `web3-bondcard__actions`,
`web3-bondcard__action`. Maturity gets a `--matured` modifier once
`nowSec >= maturitySec`.

@docs view, Config

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Web3.BigInt exposing (BigInt)
import Web3.Ui.Amount as Amount


{-| -}
type alias Config msg =
    { bondId : Int
    , principal : BigInt
    , principalSymbol : String
    , decimals : Int
    , maturitySec : Int
    , nowSec : Int
    , pendingYield : BigInt
    , yieldSymbol : String
    , onClaimYield : Maybe msg
    , onRedeem : Maybe msg
    , onRoll : Maybe msg
    }


{-| Render the bond-receipt card. -}
view : Config msg -> Html msg
view cfg =
    let
        remaining =
            max 0 (cfg.maturitySec - cfg.nowSec)

        matured =
            cfg.nowSec >= cfg.maturitySec

        maturityText =
            if matured then
                "matured"

            else
                "matures in " ++ humanDuration remaining

        maturityClass =
            if matured then
                "web3-bondcard__maturity web3-bondcard__maturity--matured"

            else
                "web3-bondcard__maturity"

        actionButton label maybeMsg =
            case maybeMsg of
                Nothing ->
                    Html.text ""

                Just msg ->
                    Html.button
                        [ Attr.class "web3-bondcard__action"
                        , Attr.type_ "button"
                        , Events.onClick msg
                        ]
                        [ Html.text label ]
    in
    Html.div [ Attr.class "web3-bondcard" ]
        [ Html.div [ Attr.class "web3-bondcard__id" ]
            [ Html.text ("#" ++ String.fromInt cfg.bondId) ]
        , Html.div [ Attr.class "web3-bondcard__principal" ]
            [ Html.text (Amount.formatWei cfg.decimals cfg.principal)
            , Html.text " "
            , Html.text cfg.principalSymbol
            ]
        , Html.div [ Attr.class maturityClass ] [ Html.text maturityText ]
        , Html.div [ Attr.class "web3-bondcard__yield" ]
            [ Html.text "Accrued: "
            , Html.text (Amount.formatWei cfg.decimals cfg.pendingYield)
            , Html.text " "
            , Html.text cfg.yieldSymbol
            ]
        , Html.div [ Attr.class "web3-bondcard__actions" ]
            [ actionButton "Claim yield" cfg.onClaimYield
            , actionButton "Redeem" cfg.onRedeem
            , actionButton "Roll" cfg.onRoll
            ]
        ]


humanDuration : Int -> String
humanDuration sec =
    if sec >= 86400 then
        String.fromInt (sec // 86400) ++ "d"

    else if sec >= 3600 then
        String.fromInt (sec // 3600) ++ "h"

    else if sec >= 60 then
        String.fromInt (sec // 60) ++ "m"

    else
        String.fromInt sec ++ "s"
