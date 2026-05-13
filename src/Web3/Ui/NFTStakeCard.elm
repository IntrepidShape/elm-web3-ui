module Web3.Ui.NFTStakeCard exposing
    ( view
    , Config
    )

{-| Card for an ERC-721 stake position. Like `Web3.Ui.StakeCard`, but the
position is a transferable NFT — so the card surfaces the `tokenId`, an
optional transfer action, and a separate "redeem at floor" action for
designs where floor-redemption is a distinct primitive
from full unstake.

Two countdowns are tracked independently:

  - `unlockTimeSec`: when principal can be withdrawn without penalty.
  - `floorEligibleAt`: when the position becomes eligible for floor-price
    redemption. Anchored to mint time so transfers do not reset it
    (the wash-trade-immunity property).

```elm
Web3.Ui.NFTStakeCard.view
    { tokenId = position.id
    , amount = position.amount
    , symbol = "PULSE"
    , decimals = 18
    , startTimeSec = position.startTime
    , unlockTimeSec = position.unlockTime
    , floorEligibleAt = position.floorEligibleAt
    , pendingYield = position.pendingYield
    , yieldSymbol = "PLS"
    , nowSec = model.nowSec
    , onClaimYield = Just (ClaimYield position.id)
    , onUnstake = Just (Unstake position.id)
    , onRedeemAtFloor = Just (RedeemFloor position.id)
    , onTransfer = Just (OpenTransfer position.id)
    }
```

CSS classes: `web3-nftstakecard`, `web3-nftstakecard__id`,
`web3-nftstakecard__amount`, `web3-nftstakecard__lock`,
`web3-nftstakecard__floor`, `web3-nftstakecard__yield`,
`web3-nftstakecard__actions`, `web3-nftstakecard__action`. The floor
countdown gets a `--eligible` modifier when `nowSec >= floorEligibleAt`.

@docs view, Config

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Web3.BigInt exposing (BigInt)
import Web3.Ui.Amount as Amount


{-| -}
type alias Config msg =
    { tokenId : Int
    , amount : BigInt
    , symbol : String
    , decimals : Int
    , startTimeSec : Int
    , unlockTimeSec : Int
    , floorEligibleAt : Int
    , pendingYield : BigInt
    , yieldSymbol : String
    , nowSec : Int
    , onClaimYield : Maybe msg
    , onUnstake : Maybe msg
    , onRedeemAtFloor : Maybe msg
    , onTransfer : Maybe msg
    }


{-| Render the NFT stake-position card. -}
view : Config msg -> Html msg
view cfg =
    let
        unlockRemaining =
            max 0 (cfg.unlockTimeSec - cfg.nowSec)

        floorRemaining =
            max 0 (cfg.floorEligibleAt - cfg.nowSec)

        floorEligible =
            cfg.nowSec >= cfg.floorEligibleAt

        lockText =
            if unlockRemaining == 0 then
                "principal unlocked"

            else
                "unlocks in " ++ humanDuration unlockRemaining

        floorText =
            if floorEligible then
                "floor redemption eligible"

            else
                "floor eligible in " ++ humanDuration floorRemaining

        floorClass =
            if floorEligible then
                "web3-nftstakecard__floor web3-nftstakecard__floor--eligible"

            else
                "web3-nftstakecard__floor"

        actionButton label maybeMsg =
            case maybeMsg of
                Nothing ->
                    Html.text ""

                Just msg ->
                    Html.button
                        [ Attr.class "web3-nftstakecard__action"
                        , Attr.type_ "button"
                        , Events.onClick msg
                        ]
                        [ Html.text label ]
    in
    Html.div [ Attr.class "web3-nftstakecard" ]
        [ Html.div [ Attr.class "web3-nftstakecard__id" ]
            [ Html.text ("#" ++ String.fromInt cfg.tokenId) ]
        , Html.div [ Attr.class "web3-nftstakecard__amount" ]
            [ Html.text (Amount.formatWei cfg.decimals cfg.amount)
            , Html.text " "
            , Html.text cfg.symbol
            ]
        , Html.div [ Attr.class "web3-nftstakecard__lock" ] [ Html.text lockText ]
        , Html.div [ Attr.class floorClass ] [ Html.text floorText ]
        , Html.div [ Attr.class "web3-nftstakecard__yield" ]
            [ Html.text "Accrued: "
            , Html.text (Amount.formatWei cfg.decimals cfg.pendingYield)
            , Html.text " "
            , Html.text cfg.yieldSymbol
            ]
        , Html.div [ Attr.class "web3-nftstakecard__actions" ]
            [ actionButton "Claim yield" cfg.onClaimYield
            , actionButton "Redeem at floor" cfg.onRedeemAtFloor
            , actionButton "Unstake" cfg.onUnstake
            , actionButton "Transfer" cfg.onTransfer
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
