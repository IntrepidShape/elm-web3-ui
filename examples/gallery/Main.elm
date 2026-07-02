module Main exposing (main)

{-| The elm-web3-ui gallery — every generic primitive, every state, one page.

Everything here is driven by SIMULATED port messages: the library's state
machines (`Tx.Status`, `SignState`, `ApprovalFlow.Step`, `RemoteCall`,
`TxQueue`) are pure, so the whole dapp surface can be demonstrated — and
clicked through — without a wallet, a node, or JavaScript. That purity is
the point of the library; this page is the proof you can see.

Build:  cd examples/gallery && elm make Main.elm --output=elm.js
Open:   index.html

-}

import Browser
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Web3.BigInt as B
import Web3.Sign as Sign
import Web3.Transaction as Tx
import Web3.Types as T
import Web3.Ui.AccountPill as AccountPill
import Web3.Ui.Address as Address
import Web3.Ui.Amount as Amount
import Web3.Ui.ApprovalFlow as Flow
import Web3.Ui.ChainSelector as ChainSelector
import Web3.Ui.Deadline as Deadline
import Web3.Ui.FeeBreakdown as FeeBreakdown
import Web3.Ui.Form as Form
import Web3.Ui.GasEstimate as GasEstimate
import Web3.Ui.Identicon as Identicon
import Web3.Ui.PendingOverlay as PendingOverlay
import Web3.Ui.PriceDisplay as PriceDisplay
import Web3.Ui.ProgressRing as ProgressRing
import Web3.Ui.RelativeTime as RelativeTime
import Web3.Ui.RemoteCall as RemoteCall exposing (RemoteCall)
import Web3.Ui.Revert as Revert
import Web3.Ui.Sign as SignUi
import Web3.Ui.Skeleton as Skeleton
import Web3.Ui.SlippageInput as SlippageInput
import Web3.Ui.StatCell as StatCell
import Web3.Ui.SupplyBar as SupplyBar
import Web3.Ui.TokenSearch as TokenSearch
import Web3.Ui.TradeTabs as TradeTabs
import Web3.Ui.Transaction as TxUi
import Web3.Ui.TxQueue as TxQueue
import Web3.Wallet as Wallet


main : Program () Model Msg
main =
    Browser.sandbox { init = init, update = update, view = view }



-- FIXTURES


demoAddress : T.Address
demoAddress =
    unsafeAddress "0xbeefcafe1234deadbeefcafe1234deadbeefcafe"


demoAddress2 : T.Address
demoAddress2 =
    unsafeAddress "0x1234567890abcdef1234567890abcdef12345678"


unsafeAddress : String -> T.Address
unsafeAddress s =
    case T.address s of
        Just a ->
            a

        Nothing ->
            unsafeAddress "0xbeefcafe1234deadbeefcafe1234deadbeefcafe"


demoHashStr : String
demoHashStr =
    "0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd"


explorer : { explorerUrl : Maybe String }
explorer =
    { explorerUrl = Just "https://scan.pulsechain.com/tx/" }


wei : String -> B.BigInt
wei s =
    Maybe.withDefault B.zero (B.fromString s)


chainId : Int -> String
chainId id =
    case id of
        369 ->
            "PulseChain"

        1 ->
            "Ethereum"

        8453 ->
            "Base"

        _ ->
            "Chain " ++ String.fromInt id



-- MODEL


type alias Model =
    { amount : String
    , slippageBps : Int
    , deadlineMinutes : Int
    , tab : Side
    , search : String
    , chain : Maybe Int
    , walletScene : Int
    , tx : Tx.Status
    , sign : Sign.SignState
    , flow : Flow.Step
    , remote : RemoteCall String
    , queue : TxQueue.TxQueue
    , revertDismissed : Bool
    }


type Side
    = BuySide
    | SellSide


init : Model
init =
    { amount = "1.5"
    , slippageBps = 50
    , deadlineMinutes = 20
    , tab = BuySide
    , search = ""
    , chain = Just 369
    , walletScene = 3
    , tx = Tx.Idle
    , sign = Sign.SignIdle
    , flow = Flow.start
    , remote = RemoteCall.notAsked
    , queue =
        TxQueue.empty
            |> TxQueue.begin "q1" "Approve FOO"
            |> TxQueue.update "q1" (Tx.TxSubmitted demoHashStr)
            |> TxQueue.begin "q2" "Stake 50k FOO"
    , revertDismissed = False
    }



-- UPDATE (all simulated — no ports anywhere on this page)


type Msg
    = SetAmount String
    | PickPercent Int
    | SetSlippage Int
    | SetDeadline Int
    | SetTab Side
    | SetSearch String
    | PickChain Int
    | CycleWallet
    | AdvanceTx
    | AdvanceSign
    | FlowMsg Flow.Msg
    | FlowStartApprove
    | FlowStartAction
    | FlowReset
    | RemoteFire
    | RemoteSucceed
    | RemoteFail
    | RemoteStale
    | QueueAdvance String
    | QueueDismiss String
    | DismissRevert
    | Noop


update : Msg -> Model -> Model
update msg model =
    case msg of
        SetAmount v ->
            { model | amount = v }

        PickPercent pct ->
            { model
                | amount =
                    if pct == 100 then
                        "420.69"

                    else
                        String.fromFloat (420.69 * toFloat pct / 100)
            }

        SetSlippage bps ->
            { model | slippageBps = bps }

        SetDeadline m ->
            { model | deadlineMinutes = m }

        SetTab side ->
            { model | tab = side }

        SetSearch s ->
            { model | search = s }

        PickChain id ->
            { model | chain = Just id }

        CycleWallet ->
            { model | walletScene = modBy 6 (model.walletScene + 1) }

        AdvanceTx ->
            { model | tx = advanceTx model.tx }

        AdvanceSign ->
            { model | sign = advanceSign model.sign }

        FlowMsg m ->
            { model | flow = Flow.update flowReq m model.flow }

        FlowStartApprove ->
            { model | flow = Flow.startApprove model.flow }

        FlowStartAction ->
            { model | flow = Flow.startAction model.flow }

        FlowReset ->
            { model | flow = Flow.reset model.flow }

        RemoteFire ->
            { model | remote = RemoteCall.request "req-7" model.remote }

        RemoteSucceed ->
            { model | remote = RemoteCall.resolve "req-7" (Ok "1,204,776 FOO") model.remote }

        RemoteFail ->
            { model | remote = RemoteCall.resolve "req-7" (Err "execution reverted") model.remote }

        RemoteStale ->
            -- a late answer for an OLD request id — dropped by the id guard
            { model | remote = RemoteCall.resolve "req-3" (Ok "STALE DATA") model.remote }

        QueueAdvance id ->
            { model
                | queue =
                    TxQueue.update id
                        (nextQueueMsg id model.queue)
                        model.queue
            }

        QueueDismiss id ->
            { model | queue = TxQueue.dismiss id model.queue }

        DismissRevert ->
            { model | revertDismissed = True }

        Noop ->
            model


flowReq : { required : B.BigInt }
flowReq =
    { required = wei "1000000000000000000" }


advanceTx : Tx.Status -> Tx.Status
advanceTx status =
    case status of
        Tx.Idle ->
            Tx.AwaitingSignature

        Tx.AwaitingSignature ->
            Tx.update (Tx.TxSubmitted demoHashStr) status

        Tx.Submitted _ ->
            Tx.update (Tx.TxConfirmation demoHashStr 1) status

        Tx.Confirming _ n ->
            if n < 3 then
                Tx.update (Tx.TxConfirmation demoHashStr (n + 1)) status

            else
                Tx.update
                    (Tx.TxConfirmed
                        { txHash = demoHashStr
                        , blockNumber = 21688204
                        , gasUsed = "48213"
                        , status = True
                        , logs = []
                        }
                    )
                    status

        _ ->
            Tx.update Tx.TxReset status


advanceSign : Sign.SignState -> Sign.SignState
advanceSign state =
    case state of
        Sign.SignIdle ->
            Sign.startSign "sig-1" state

        Sign.SignPending id ->
            Sign.signUpdate (Sign.SignResponse id "0xdeadbeef5161…") state

        _ ->
            Sign.SignIdle



-- VIEW


view : Model -> Html Msg
view model =
    Html.div [ Attr.class "gallery" ]
        [ Html.header [ Attr.class "gallery__header" ]
            [ Html.h1 [] [ Html.text "elm-web3-ui" ]
            , Html.p []
                [ Html.text "Every generic primitive, every state — driven entirely by simulated messages. No wallet, no node, no JS: the state machines are pure, and that is the product." ]
            ]
        , layer "Layer 0 — display atoms"
            [ demo "Identicon"
                "Canonical blockies, pure Elm — same faces users know from their wallet."
                (Html.div [ Attr.class "row" ]
                    [ Identicon.view [] { size = 48 } demoAddress
                    , Identicon.view [] { size = 32 } demoAddress2
                    , Identicon.view [ Attr.class "round" ] { size = 32 } demoAddress
                    ]
                )
            , demo "Address"
                "Truncated, explorer-linked; Nothing renders a plain span (local dev)."
                (Html.div [ Attr.class "row" ]
                    [ Address.view [] { explorerUrl = Just "https://scan.pulsechain.com/address/" } demoAddress
                    , Address.view [] { explorerUrl = Nothing } demoAddress2
                    ]
                )
            , demo "PriceDisplay / StatCell / TrendIndicator"
                "The analytics row every dapp reaches for."
                (Html.div [ Attr.class "row" ]
                    [ PriceDisplay.view [] { decimals = 18, symbol = "PLS" } (wei "1204776000000000000000000")
                    , StatCell.view { label = "TVL", value = "$1.2M", delta = Just "+4.2%", sentiment = StatCell.Positive }
                    , StatCell.view { label = "24h", value = "$88k", delta = Just "-1.9%", sentiment = StatCell.Negative }
                    ]
                )
            , demo "ProgressRing / SupplyBar / RelativeTime"
                "Progress toward caps and thresholds; block-time phrasing."
                (Html.div [ Attr.class "row" ]
                    [ ProgressRing.view { current = wei "68", target = wei "100", size = 56, label = Just "68%" }
                    , SupplyBar.view { current = wei "6800", max = wei "10000", label = Just "graduation" }
                    , RelativeTime.view { nowSec = 1000000, atSec = 999160 }
                    ]
                )
            , demo "Skeleton"
                "Placeholders shaped like the atoms they stand in for — shimmer is pure CSS."
                (Html.div [ Attr.class "row" ]
                    [ Skeleton.circle [], Skeleton.address [], Skeleton.amount [], Skeleton.pill [], Skeleton.line [] ]
                )
            , demo "Revert"
                "elm-web3 decodes Error(string) revert data; this finally shows it to the user."
                (Html.div [ Attr.class "col" ]
                    [ Revert.banner [] { onDismiss = Nothing } errorStringRevert
                    , Revert.banner []
                        { onDismiss =
                            if model.revertDismissed then
                                Nothing

                            else
                                Just DismissRevert
                        }
                        "0x4e487b710000000000000000000000000000000000000000000000000000000000000011"
                    ]
                )
            ]
        , layer "Layer 1 — input atoms"
            [ demo "Amount + presets"
                "Decimals-aware input; percentage chips emit intent, app computes from live balance."
                (Html.div [ Attr.class "col" ]
                    [ Amount.amountInput []
                        { value = model.amount, onInput = SetAmount, decimals = 18, symbol = "PLS", valid = True }
                    , Amount.presetRow [] { onPick = PickPercent }
                    ]
                )
            , demo "SlippageInput / Deadline"
                "The trade-settings pair, in basis points and minutes."
                (Html.div [ Attr.class "col" ]
                    [ SlippageInput.view { valueBps = model.slippageBps, onChange = SetSlippage, presetsBps = [ 10, 50, 100 ] }
                    , Deadline.view { valueMinutes = model.deadlineMinutes, onChange = SetDeadline, presetsMinutes = [ 10, 20, 30 ] }
                    ]
                )
            , demo "ChainSelector"
                "A switch *request* — real dapps re-render from Wallet.State truth, never optimistically."
                (ChainSelector.view []
                    { entries =
                        [ { chainId = 369, label = "PulseChain" }
                        , { chainId = 1, label = "Ethereum" }
                        , { chainId = 8453, label = "Base" }
                        ]
                    , current = model.chain
                    , onSelect = PickChain
                    }
                )
            , demo "TokenSearch / TradeTabs"
                "List-filtering and side-switching."
                (Html.div [ Attr.class "col" ]
                    [ TokenSearch.view { value = model.search, onInput = SetSearch, placeholder = "Search tokens…" }
                    , TradeTabs.view
                        { current = model.tab
                        , onSelect = SetTab
                        , tabs = [ { id = BuySide, label = "Buy" }, { id = SellSide, label = "Sell" } ]
                        }
                    ]
                )
            , demo "Form"
                "Accumulating validation — a three-field form reports all three problems at once."
                (Form.errorList []
                    (Form.succeed (\a b c -> ( a, b, c ))
                        |> Form.andMap (Form.fromMaybe "Recipient is not a valid address" (T.address "nope"))
                        |> Form.andMap (Form.fromMaybe "Amount is not a valid number" (B.fromString "1.5.0"))
                        |> Form.andMap (Form.fromMaybe "Deadline must be at least 1 minute" (validDeadline 0))
                    )
                )
            ]
        , layer "Layer 2 — state-machine bound"
            [ demoWith "AccountPill"
                "The whole wallet story in one pill. Cycle through all six states."
                [ button CycleWallet "cycle state" ]
                (AccountPill.view
                    { onConnect = Noop
                    , onDisconnect = Noop
                    , chainLabel = \c -> chainId (T.chainIdToInt c)
                    , balance = Just "420.69 PLS"
                    }
                    (walletScene model.walletScene)
                )
            , demoWith "Transaction lifecycle"
                "Badge, hash link, confirmation dots, receipt — one Tx.Status drives them all."
                [ button AdvanceTx "advance" ]
                (Html.div [ Attr.class "col" ]
                    [ Html.div [ Attr.class "row" ]
                        [ TxUi.statusBadge [] model.tx
                        , Maybe.withDefault (Html.text "") (TxUi.statusHashLink [] explorer model.tx)
                        , TxUi.confirmationProgress [] { required = 3 } model.tx
                        ]
                    , TxUi.actionButton [] { label = "Buy 1.2M FOO", pendingLabel = "Buying…", onPress = AdvanceTx } model.tx
                    , case model.tx of
                        Tx.Confirmed receipt ->
                            TxUi.receiptView [] explorer receipt

                        _ ->
                            Html.text ""
                    ]
                )
            , demoWith "Sign"
                "EIP-191/712 signing lifecycle."
                [ button AdvanceSign "advance" ]
                (Html.div [ Attr.class "row" ]
                    [ SignUi.signButton [] { label = "Sign in", onSign = AdvanceSign } model.sign
                    , SignUi.stateView [] model.sign
                    ]
                )
            , demoWith "RemoteCall"
                "The correlation-id read wrapper. 'stale answer' proves the id guard: a late response for an old request cannot clobber the screen."
                [ button RemoteFire "fire"
                , button RemoteSucceed "answer"
                , button RemoteFail "fail"
                , button RemoteStale "stale answer"
                ]
                (RemoteCall.view
                    { skeleton = Skeleton.amount []
                    , failed = \err -> Revert.banner [] { onDismiss = Nothing } err
                    }
                    (\balance -> Html.strong [] [ Html.text balance ])
                    model.remote
                )
            , demoWith "TxQueue"
                "Many transactions in flight; messages route by id, one tx can never touch another."
                [ button (QueueAdvance "q1") "advance q1"
                , button (QueueAdvance "q2") "advance q2"
                ]
                (TxQueue.toastStack
                    { onDismiss = QueueDismiss, explorerUrl = explorer.explorerUrl }
                    model.queue
                )
            , demo "GasEstimate / PendingOverlay"
                "Estimate display and the in-flight scrim (rendered inline here)."
                (Html.div [ Attr.class "row" ]
                    [ GasEstimate.view [] { gasUnits = Just (wei "48213"), gasPrice = Just (wei "2100000000"), decimals = 18, symbol = "PLS" }
                    , Html.div [ Attr.class "overlay-box" ]
                        [ PendingOverlay.view [] { message = "Waiting for signature…" } ]
                    ]
                )
            , demo "FeeBreakdown"
                "Where every basis point goes."
                (FeeBreakdown.view
                    { totalBps = 300
                    , symbol = "PLS"
                    , decimals = 18
                    , gross = Just (wei "1000000000000000000")
                    , slices =
                        [ { label = "Protocol", bps = 100, recipient = Nothing }
                        , { label = "LP", bps = 150, recipient = Nothing }
                        , { label = "Referrer", bps = 50, recipient = Just demoAddress2 }
                        ]
                    }
                )
            ]
        , layer "Layer 3 — flow generics"
            [ demoWith "ApprovalFlow"
                "Approve-then-act, structurally safe: Acting is unreachable without a verified allowance (fuzz-tested AND model-checked — proofs/tla/ApprovalSpec.tla)."
                [ button (FlowMsg (Flow.AllowanceLoaded (wei "0"))) "allowance: 0"
                , button (FlowMsg (Flow.AllowanceLoaded (wei "2000000000000000000"))) "allowance: plenty"
                , button FlowStartApprove "approve"
                , button (FlowMsg (Flow.ApproveTx (Tx.TxSubmitted demoHashStr))) "approve submitted"
                , button (FlowMsg (Flow.ApproveTx (Tx.TxConfirmed demoReceiptJson))) "approve confirmed"
                , button FlowStartAction "act"
                , button (FlowMsg (Flow.ActionTx (Tx.TxSubmitted demoHashStr))) "act submitted"
                , button (FlowMsg (Flow.ActionTx (Tx.TxConfirmed demoReceiptJson))) "act confirmed"
                , button FlowReset "reset"
                ]
                (Flow.view
                    { approveLabel = "Approve FOO"
                    , actionLabel = "Stake 50k"
                    , onApprove = FlowStartApprove
                    , onAction = FlowStartAction
                    , onRetry = FlowMsg Flow.Retry
                    }
                    model.flow
                )
            ]
        , Html.footer [ Attr.class "gallery__footer" ]
            [ Html.text "Domain compounds (StakeCard, BondCard, VeLock, GaugeRow, FundingPool, SecurityCard, …) and the generic contract forms (ContractRead/Write, AbiInput) live in the "
            , Html.a [ Attr.href "https://package.elm-lang.org/packages/intrepidshape/elm-web3-ui/latest/" ] [ Html.text "package docs" ]
            , Html.text ". Taxonomy and roadmap: PRIMITIVES.md."
            ]
        ]


{-| ABI-encoded Error("Insufficient balance for this purchase") -}
errorStringRevert : String
errorStringRevert =
    "0x08c379a0"
        ++ "0000000000000000000000000000000000000000000000000000000000000020"
        ++ "0000000000000000000000000000000000000000000000000000000000000026"
        ++ "496e73756666696369656e742062616c616e636520666f722074686973207075"
        ++ "7263686173650000000000000000000000000000000000000000000000000000"


demoReceiptJson : { txHash : String, blockNumber : Int, gasUsed : String, status : Bool, logs : List { address : String, topics : List String, data : String, blockNumber : Int, logIndex : Int } }
demoReceiptJson =
    { txHash = demoHashStr, blockNumber = 21688204, gasUsed = "48213", status = True, logs = [] }


{-| Walk a queued tx one step along its lifecycle. -}
nextQueueMsg : String -> TxQueue.TxQueue -> Tx.Msg
nextQueueMsg id queue =
    case List.head (List.filter (\( i, _ ) -> i == id) (TxQueue.entries queue)) of
        Just ( _, e ) ->
            case e.status of
                Tx.AwaitingSignature ->
                    Tx.TxSubmitted demoHashStr

                Tx.Submitted _ ->
                    Tx.TxConfirmation demoHashStr 1

                Tx.Confirming _ n ->
                    if n < 2 then
                        Tx.TxConfirmation demoHashStr (n + 1)

                    else
                        Tx.TxConfirmed demoReceiptJson

                _ ->
                    Tx.TxReset

        Nothing ->
            Tx.TxReset


validDeadline : Int -> Maybe Int
validDeadline m =
    if m >= 1 then
        Just m

    else
        Nothing


walletScene : Int -> Wallet.State
walletScene index =
    case index of
        0 ->
            Wallet.Disconnected

        1 ->
            Wallet.Connecting

        2 ->
            Wallet.ReadOnly

        3 ->
            Wallet.update (T.chainId 369) (Wallet.WalletConnected (T.addressToString demoAddress) 369) Wallet.Disconnected

        4 ->
            Wallet.update (T.chainId 369) (Wallet.WalletConnected (T.addressToString demoAddress) 1) Wallet.Disconnected

        _ ->
            Wallet.Error "user closed the wallet"



-- CHROME


layer : String -> List (Html Msg) -> Html Msg
layer title demos =
    Html.section [ Attr.class "layer" ]
        (Html.h2 [ Attr.class "layer__title" ] [ Html.text title ] :: demos)


demo : String -> String -> Html Msg -> Html Msg
demo title blurb content =
    demoWith title blurb [] content


demoWith : String -> String -> List (Html Msg) -> Html Msg -> Html Msg
demoWith title blurb controls content =
    Html.article [ Attr.class "demo" ]
        [ Html.div [ Attr.class "demo__head" ]
            (Html.h3 [] [ Html.text title ]
                :: Html.p [ Attr.class "demo__blurb" ] [ Html.text blurb ]
                :: (if List.isEmpty controls then
                        []

                    else
                        [ Html.div [ Attr.class "demo__controls" ] controls ]
                   )
            )
        , Html.div [ Attr.class "demo__stage" ] [ content ]
        ]


button : Msg -> String -> Html Msg
button msg label =
    Html.button [ Attr.class "demo__button", Events.onClick msg ] [ Html.text label ]
