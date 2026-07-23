module Web3.Ui.ApprovalFlow exposing
    ( Step(..), Msg(..)
    , start, update, startApprove, startAction, reset
    , isTerminal, needsApproval
    , view, Config
    )

{-| The approve-then-act state machine -- the most repeated flow in all of
web3. Every ERC-20 interaction (deposit, stake, swap, lock...) is really two
transactions gated by an allowance read, and every dapp hand-rolls the same
fragile ladder. This is that ladder, once, with the guards proven by fuzz
tests (`ApprovalFlowTest`) and modeled in `proofs/tla/ApprovalSpec.tla`.

    +------------------+  insufficient   +----------------+
    | CheckingAllowance+---------------->| ApprovalNeeded |
    +-------+----------+                 +-------+--------+
            | sufficient                 startApprove
            v                                    v
    +--------------+   approve confirmed +------------+
    |  ReadyToAct  |<---(via re-check)---|  Approving |
    +-------+------+                     +------------+
       startAction
            v
    +--------------+    tx confirmed     +------------+
    |    Acting    +-------------------->|  Completed |
    +--------------+                     +------------+

Design choices, deliberately:

  - **A confirmed approval re-checks the allowance** instead of optimistically
    assuming it. Non-standard tokens (USDT's approve-to-zero-first rule,
    fee-on-transfer tokens) make optimism a lie; the chain is the truth.
  - **Wallet rejection is not failure.** Rejecting the approve returns to
    `ApprovalNeeded`; rejecting the action returns to `ReadyToAct` -- the user
    changed their mind, nothing is broken.
  - **The two transactions cannot cross.** `ApproveTx` messages are ignored
    while `Acting`, `ActionTx` messages while `Approving` -- a late
    confirmation from one leg can never corrupt the other (the same
    no-cross-confusion rule elm-web3's SignSpec proves).

Wire-up sketch:

    -- fire the allowance read, then:
    ApprovalFlow.update { required = amountWei } (AllowanceLoaded current) step

    -- user clicks approve:
    ( { model | step = ApprovalFlow.startApprove model.step }
    , web3Cmd approveCall
    )

    -- port messages for the approve tx:
    ApprovalFlow.update req (ApproveTx txMsg) step

@docs Step, Msg
@docs start, update, startApprove, startAction, reset
@docs isTerminal, needsApproval
@docs view, Config

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Web3.BigInt as BigInt exposing (BigInt)
import Web3.Transaction as Tx


{-| Where the flow is. `Approving`/`Acting` carry the inner transaction
lifecycle; `Blocked` carries the error that stopped the flow.
-}
type Step
    = CheckingAllowance
    | ApprovalNeeded
    | Approving Tx.Status
    | ReadyToAct
    | Acting Tx.Status
    | Completed Tx.Receipt
    | Blocked String


{-| Inputs to the machine. `ApproveTx`/`ActionTx` wrap the port's
`Tx.Msg` for whichever leg it belongs to -- route by your correlation id.
-}
type Msg
    = AllowanceLoaded BigInt
    | AllowanceFailed String
    | ApproveTx Tx.Msg
    | ActionTx Tx.Msg
    | Retry


{-| The flow begins by asking the chain what is already approved. -}
start : Step
start =
    CheckingAllowance


{-| True in `Completed` -- the flow finished; only [`reset`](#reset) leaves. -}
isTerminal : Step -> Bool
isTerminal step =
    case step of
        Completed _ ->
            True

        _ ->
            False


{-| True when the user's next click should be Approve. -}
needsApproval : Step -> Bool
needsApproval step =
    case step of
        ApprovalNeeded ->
            True

        Approving _ ->
            True

        _ ->
            False


{-| User clicked Approve: `ApprovalNeeded -> Approving AwaitingSignature`.
No-op from every other step -- this is the only door into `Approving`.
-}
startApprove : Step -> Step
startApprove step =
    case step of
        ApprovalNeeded ->
            Approving Tx.AwaitingSignature

        _ ->
            step


{-| User clicked the action: `ReadyToAct -> Acting AwaitingSignature`.
No-op from every other step -- the only door into `Acting`, which is what
makes "never act on an unverified allowance" a structural guarantee rather
than a convention.
-}
startAction : Step -> Step
startAction step =
    case step of
        ReadyToAct ->
            Acting Tx.AwaitingSignature

        _ ->
            step


{-| Leave a finished or blocked flow: `Completed`/`Blocked ->
CheckingAllowance` (a fresh flow re-reads the chain). No-op elsewhere.
-}
reset : Step -> Step
reset step =
    case step of
        Completed _ ->
            CheckingAllowance

        Blocked _ ->
            CheckingAllowance

        _ ->
            step


{-| Advance the machine. `required` is the amount the action needs approved.
-}
update : { required : BigInt } -> Msg -> Step -> Step
update req msg step =
    case ( msg, step ) of
        ( AllowanceLoaded current, CheckingAllowance ) ->
            if BigInt.gte current req.required then
                ReadyToAct

            else
                ApprovalNeeded

        ( AllowanceFailed err, CheckingAllowance ) ->
            Blocked err

        ( ApproveTx txMsg, Approving status ) ->
            case Tx.update txMsg status of
                Tx.Confirmed _ ->
                    -- Approval mined: re-read the allowance rather than
                    -- trust it. The chain is the truth; tokens lie.
                    CheckingAllowance

                Tx.Failed err ->
                    Blocked err

                Tx.Rejected ->
                    -- The user declined in the wallet; nothing is broken.
                    ApprovalNeeded

                inFlight ->
                    Approving inFlight

        ( ActionTx txMsg, Acting status ) ->
            case Tx.update txMsg status of
                Tx.Confirmed receipt ->
                    Completed receipt

                Tx.Failed err ->
                    Blocked err

                Tx.Rejected ->
                    ReadyToAct

                inFlight ->
                    Acting inFlight

        ( Retry, Blocked _ ) ->
            CheckingAllowance

        -- Everything else — including ApproveTx while Acting and ActionTx
        -- while Approving — is dropped. The legs cannot cross.
        _ ->
            step



-- VIEW


{-| Labels and handlers for the two-step control. -}
type alias Config msg =
    { approveLabel : String
    , actionLabel : String
    , onApprove : msg
    , onAction : msg
    , onRetry : msg
    }


{-| A two-step control: numbered step indicator plus the one button that is
valid right now. The root carries a state modifier so every step is
independently styleable.

CSS classes: `web3-approval`, `web3-approval--checking`, `--approve`,
`--approving`, `--ready`, `--acting`, `--done`, `--blocked`;
`web3-approval__steps`, `web3-approval__step`, `web3-approval__step--active`,
`web3-approval__step--done`, `web3-approval__button`, `web3-approval__error`.

-}
view : Config msg -> Step -> Html msg
view cfg step =
    let
        ( modifier, stepIndex, control ) =
            case step of
                CheckingAllowance ->
                    ( "checking", 1, button [ Attr.disabled True ] "…" )

                ApprovalNeeded ->
                    ( "approve", 1, button [ Events.onClick cfg.onApprove ] cfg.approveLabel )

                Approving _ ->
                    ( "approving", 1, button [ Attr.disabled True, Attr.attribute "aria-busy" "true" ] cfg.approveLabel )

                ReadyToAct ->
                    ( "ready", 2, button [ Events.onClick cfg.onAction ] cfg.actionLabel )

                Acting _ ->
                    ( "acting", 2, button [ Attr.disabled True, Attr.attribute "aria-busy" "true" ] cfg.actionLabel )

                Completed _ ->
                    ( "done", 3, Html.text "" )

                Blocked err ->
                    ( "blocked"
                    , 1
                    , Html.div []
                        [ Html.p [ Attr.class "web3-approval__error" ] [ Html.text err ]
                        , button [ Events.onClick cfg.onRetry ] "Retry"
                        ]
                    )
    in
    Html.div
        [ Attr.class "web3-approval"
        , Attr.class ("web3-approval--" ++ modifier)
        ]
        [ Html.ol [ Attr.class "web3-approval__steps" ]
            [ stepDot stepIndex 1 cfg.approveLabel
            , stepDot stepIndex 2 cfg.actionLabel
            ]
        , control
        ]


stepDot : Int -> Int -> String -> Html msg
stepDot activeIndex index label =
    Html.li
        [ Attr.class "web3-approval__step"
        , Attr.classList
            [ ( "web3-approval__step--active", activeIndex == index )
            , ( "web3-approval__step--done", activeIndex > index )
            ]
        ]
        [ Html.text label ]


button : List (Html.Attribute msg) -> String -> Html msg
button extra label =
    Html.button
        (Attr.class "web3-approval__button" :: extra)
        [ Html.text label ]
