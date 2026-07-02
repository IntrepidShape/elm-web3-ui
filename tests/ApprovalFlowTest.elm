module ApprovalFlowTest exposing (suite)

{-| Fuzz tests for the ApprovalFlow state machine — the invariants that make
approve-then-act structurally safe (mirrored by proofs/tla/ApprovalSpec.tla):

1.  Acting/Completed are unreachable from any message stream alone — only
    `startAction` (which only fires from `ReadyToAct`) opens that door.
    "Never act on an unverified allowance" is structural, not conventional.
2.  `Completed` is absorbing under every message.
3.  The legs cannot cross: `ApproveTx` never moves an `Acting` state,
    `ActionTx` never moves an `Approving` state.
4.  Wallet rejection is not failure: rejecting approve → `ApprovalNeeded`,
    rejecting the action → `ReadyToAct`.

-}

import Expect
import Fuzz exposing (Fuzzer)
import Test exposing (..)
import Web3.BigInt as B
import Web3.Transaction as Tx
import Web3.Types as T
import Web3.Ui.ApprovalFlow as Flow exposing (Msg(..), Step(..))


req : { required : B.BigInt }
req =
    { required = B.fromInt 1000 }


validHash : String
validHash =
    "0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd"


receipt : { txHash : String, blockNumber : Int, gasUsed : String, status : Bool, logs : List { address : String, topics : List String, data : String, blockNumber : Int, logIndex : Int } }
receipt =
    { txHash = validHash, blockNumber = 1, gasUsed = "21000", status = True, logs = [] }


txMsgFuzzer : Fuzzer Tx.Msg
txMsgFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant (Tx.TxSubmitted validHash)
        , Fuzz.map (Tx.TxConfirmation validHash) (Fuzz.intRange 1 5)
        , Fuzz.constant (Tx.TxConfirmed receipt)
        , Fuzz.map Tx.TxFailed Fuzz.string
        , Fuzz.constant Tx.TxRejected
        , Fuzz.constant Tx.TxReset
        ]


msgFuzzer : Fuzzer Msg
msgFuzzer =
    Fuzz.oneOf
        [ Fuzz.map (AllowanceLoaded << B.fromInt) (Fuzz.intRange 0 5000)
        , Fuzz.map AllowanceFailed Fuzz.string
        , Fuzz.map ApproveTx txMsgFuzzer
        , Fuzz.map ActionTx txMsgFuzzer
        , Fuzz.constant Retry
        ]


isActingOrDone : Step -> Bool
isActingOrDone step =
    case step of
        Acting _ ->
            True

        Completed _ ->
            True

        _ ->
            False


suite : Test
suite =
    describe "Web3.Ui.ApprovalFlow"
        [ fuzz (Fuzz.list msgFuzzer) "Acting/Completed unreachable without startAction" <|
            \msgs ->
                List.foldl (Flow.update req) Flow.start msgs
                    |> isActingOrDone
                    |> Expect.equal False
        , fuzz (Fuzz.list msgFuzzer) "Completed is absorbing under any message stream" <|
            \msgs ->
                List.foldl (Flow.update req) (Completed anyReceipt) msgs
                    |> Expect.equal (Completed anyReceipt)
        , fuzz txMsgFuzzer "ApproveTx never moves an Acting state (legs cannot cross)" <|
            \txMsg ->
                Flow.update req (ApproveTx txMsg) (Acting Tx.AwaitingSignature)
                    |> Expect.equal (Acting Tx.AwaitingSignature)
        , fuzz txMsgFuzzer "ActionTx never moves an Approving state (legs cannot cross)" <|
            \txMsg ->
                Flow.update req (ActionTx txMsg) (Approving Tx.AwaitingSignature)
                    |> Expect.equal (Approving Tx.AwaitingSignature)
        , test "startAction only opens from ReadyToAct" <|
            \_ ->
                [ Flow.start, ApprovalNeeded, Approving Tx.AwaitingSignature, Blocked "x" ]
                    |> List.map Flow.startAction
                    |> List.filter isActingOrDone
                    |> Expect.equal []
        , test "sufficient allowance -> ReadyToAct; insufficient -> ApprovalNeeded" <|
            \_ ->
                ( Flow.update req (AllowanceLoaded (B.fromInt 1000)) Flow.start
                , Flow.update req (AllowanceLoaded (B.fromInt 999)) Flow.start
                )
                    |> Expect.equal ( ReadyToAct, ApprovalNeeded )
        , test "rejecting the approve returns to ApprovalNeeded (not Blocked)" <|
            \_ ->
                Flow.update req (ApproveTx Tx.TxRejected) (Approving Tx.AwaitingSignature)
                    |> Expect.equal ApprovalNeeded
        , test "rejecting the action returns to ReadyToAct (not Blocked)" <|
            \_ ->
                Flow.update req (ActionTx Tx.TxRejected) (Acting Tx.AwaitingSignature)
                    |> Expect.equal ReadyToAct
        , test "confirmed approval re-checks the allowance (chain is the truth)" <|
            \_ ->
                submittedApprove
                    |> Flow.update req (ApproveTx (Tx.TxConfirmed receipt))
                    |> Expect.equal CheckingAllowance
        , test "confirmed action completes the flow" <|
            \_ ->
                submittedAction
                    |> Flow.update req (ActionTx (Tx.TxConfirmed receipt))
                    |> expectCompleted
        ]


{-| An Approving step whose inner tx is Submitted (so TxConfirmed is accepted
by the guarded Tx machine).
-}
submittedApprove : Step
submittedApprove =
    Flow.update req (ApproveTx (Tx.TxSubmitted validHash)) (Approving Tx.AwaitingSignature)


submittedAction : Step
submittedAction =
    Flow.update req (ActionTx (Tx.TxSubmitted validHash)) (Acting Tx.AwaitingSignature)


anyReceipt : Tx.Receipt
anyReceipt =
    { txHash = unsafeHash validHash
    , blockNumber = 1
    , gasUsed = "21000"
    , status = True
    , logs = []
    }


{-| Parse a known-valid hash; a function (not a cyclic value) so the
unreachable fallback is legal.
-}
unsafeHash : String -> T.TxHash
unsafeHash s =
    case T.txHash s of
        Just h ->
            h

        Nothing ->
            unsafeHash validHash


expectCompleted : Step -> Expect.Expectation
expectCompleted step =
    case step of
        Completed _ ->
            Expect.pass

        _ ->
            Expect.fail "expected Completed"
