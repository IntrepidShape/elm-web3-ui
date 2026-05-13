module Web3.Ui.StakeCard exposing
    ( view
    , Config
    )

{-| Generic stake-position card: amount staked, lock-days remaining, accrued
yield, eligibility badge (e.g., floor-protection eligibility), plus claim and
unstake action buttons. Intended for any lock-and-yield staking contract.

    Web3.Ui.StakeCard.view
        { amount = position.amount
        , symbol = "TKN"
        , decimals = 18
        , startTimeSec = position.startTime
        , lockDays = position.lockDays
        , nowSec = nowSec
        , yieldAccrued = position.yieldAccrued
        , yieldSymbol = "PLS"
        , badges = [ { active = position.floorEligible, label = "floor protected" } ]
        , onClaimYield = Just (ClaimYield idx)
        , onUnstake = Just (Unstake idx)
        , unstakeLabel = "Unstake"
        }

Style: `web3-stakecard`, `web3-stakecard__amount`, `web3-stakecard__lock`,
`web3-stakecard__yield`, `web3-stakecard__badge`, `web3-stakecard__actions`,
`web3-stakecard__action`.

@docs view, Config

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Web3.BigInt exposing (BigInt)
import Web3.Ui.Amount as Amount


{-| -}
type alias Config msg =
    { amount : BigInt
    , symbol : String
    , decimals : Int
    , startTimeSec : Int
    , lockDays : Int
    , nowSec : Int
    , yieldAccrued : BigInt
    , yieldSymbol : String
    , badges : List { active : Bool, label : String }
    , onClaimYield : Maybe msg
    , onUnstake : Maybe msg
    , unstakeLabel : String
    }


{-| Render a stake-position card. -}
view : Config msg -> Html msg
view cfg =
    let
        elapsedSec =
            max 0 (cfg.nowSec - cfg.startTimeSec)

        elapsedDays =
            elapsedSec // 86400

        remainingDays =
            max 0 (cfg.lockDays - elapsedDays)

        lockText =
            if remainingDays == 0 then
                "lock complete"

            else
                String.fromInt remainingDays
                    ++ "d"
                    ++ " of "
                    ++ String.fromInt cfg.lockDays
                    ++ "d remaining"

        badge b =
            if b.active then
                Html.span
                    [ Attr.class "web3-stakecard__badge web3-stakecard__badge--active" ]
                    [ Html.text b.label ]

            else
                Html.text ""

        actionButton label maybeMsg =
            case maybeMsg of
                Nothing ->
                    Html.text ""

                Just msg ->
                    Html.button
                        [ Attr.class "web3-stakecard__action"
                        , Attr.type_ "button"
                        , Events.onClick msg
                        ]
                        [ Html.text label ]
    in
    Html.div [ Attr.class "web3-stakecard" ]
        [ Html.div [ Attr.class "web3-stakecard__amount" ]
            [ Html.text (Amount.formatWei cfg.decimals cfg.amount)
            , Html.text " "
            , Html.text cfg.symbol
            ]
        , Html.div [ Attr.class "web3-stakecard__lock" ] [ Html.text lockText ]
        , Html.div [ Attr.class "web3-stakecard__yield" ]
            [ Html.text "Accrued: "
            , Html.text (Amount.formatWei cfg.decimals cfg.yieldAccrued)
            , Html.text " "
            , Html.text cfg.yieldSymbol
            ]
        , Html.div [ Attr.class "web3-stakecard__badges" ]
            (List.map badge cfg.badges)
        , Html.div [ Attr.class "web3-stakecard__actions" ]
            [ actionButton "Claim yield" cfg.onClaimYield
            , actionButton cfg.unstakeLabel cfg.onUnstake
            ]
        ]
