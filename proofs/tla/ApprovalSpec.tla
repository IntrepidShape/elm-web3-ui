--------------------------- MODULE ApprovalSpec ---------------------------
(*
 * TLA+ specification of the Web3.Ui.ApprovalFlow state machine —
 * the approve-then-act flow behind every ERC-20 interaction.
 *
 * Models src/Web3/Ui/ApprovalFlow.elm: `update`, `startApprove`,
 * `startAction`, `reset`. The inner Tx.Status lifecycles are abstracted to
 * their outcomes (confirmed / failed / rejected) — the inner machine has
 * its own spec in elm-web3's TransactionSpec.tla.
 *
 * The invariant that matters: Acting (and therefore Completed) is
 * unreachable without passing ReadyToAct, which is only entered by a
 * sufficient allowance check or an action rejection — "never act on an
 * unverified allowance" is structural.
 *
 * Conformance: each action maps 1:1 to a case arm of ApprovalFlow.update /
 * a start* helper; the same invariants are fuzz-tested in
 * tests/ApprovalFlowTest.elm.
 *
 * Verify:  java -jar tla2tools.jar -config ApprovalSpec.cfg ApprovalSpec.tla
 * (full deadlock check: Completed/Blocked have Reset/Retry exits, no sinks)
 *)

EXTENDS Naturals

VARIABLES
    step,        \* Current step tag
    prevStep     \* Previous step tag (for transition invariants)

vars == <<step, prevStep>>

StepSet == {"CheckingAllowance", "ApprovalNeeded", "Approving",
            "ReadyToAct", "Acting", "Completed", "Blocked"}

--------------------------------------------------------------------------
(* Invariants *)

TypeOK ==
    /\ step \in StepSet
    /\ prevStep \in StepSet

(* The only door into Acting is startAction from ReadyToAct. *)
ActingNeedsVerifiedAllowance ==
    step = "Acting" => prevStep \in {"ReadyToAct", "Acting"}

(* ReadyToAct is only entered by a sufficient allowance check or an action
   rejection (the user changed their mind; the allowance is still good). *)
ReadyRequiresCheck ==
    step = "ReadyToAct" => prevStep \in {"CheckingAllowance", "Acting", "ReadyToAct"}

(* Completed only comes from a confirmed action. *)
CompletedFromActing ==
    step = "Completed" => prevStep \in {"Acting", "Completed"}

(* Completed is absorbing except for the explicit reset to a fresh check. *)
CompletedAbsorbing ==
    prevStep = "Completed" => step \in {"Completed", "CheckingAllowance"}

--------------------------------------------------------------------------
Init ==
    /\ step = "CheckingAllowance"
    /\ prevStep = "CheckingAllowance"

Go(from, to) ==
    /\ step = from
    /\ step' = to
    /\ prevStep' = from

(* Allowance read resolves: sufficient / insufficient / errored.
   (AllowanceLoaded >=, AllowanceLoaded <, AllowanceFailed in the Elm.) *)
AllowanceOk   == Go("CheckingAllowance", "ReadyToAct")
AllowanceLow  == Go("CheckingAllowance", "ApprovalNeeded")
AllowanceFail == Go("CheckingAllowance", "Blocked")

(* startApprove — the only door into Approving. *)
StartApprove == Go("ApprovalNeeded", "Approving")

(* The approve leg resolves. A confirmed approval RE-CHECKS the allowance
   (the chain is the truth); rejection returns to ApprovalNeeded. *)
ApproveConfirmed == Go("Approving", "CheckingAllowance")
ApproveFailed    == Go("Approving", "Blocked")
ApproveRejected  == Go("Approving", "ApprovalNeeded")

(* startAction — the only door into Acting. *)
StartAction == Go("ReadyToAct", "Acting")

(* The action leg resolves. *)
ActionConfirmed == Go("Acting", "Completed")
ActionFailed    == Go("Acting", "Blocked")
ActionRejected  == Go("Acting", "ReadyToAct")

(* Retry / reset back to a fresh on-chain check. *)
Retry == Go("Blocked", "CheckingAllowance")
Reset == Go("Completed", "CheckingAllowance")

Next ==
    \/ AllowanceOk \/ AllowanceLow \/ AllowanceFail
    \/ StartApprove
    \/ ApproveConfirmed \/ ApproveFailed \/ ApproveRejected
    \/ StartAction
    \/ ActionConfirmed \/ ActionFailed \/ ActionRejected
    \/ Retry \/ Reset

--------------------------------------------------------------------------
(* Liveness: an in-flight leg always settles — the port either confirms,
   fails, or reports rejection (elm-web3's port layer guarantees a typed
   response on every path; see its JS_PORT_PROOF.md). User actions are NOT
   assumed: a flow can honestly rest in ApprovalNeeded/ReadyToAct forever
   if the user walks away. *)

LegFairness ==
    /\ WF_vars(ApproveConfirmed \/ ApproveFailed \/ ApproveRejected)
    /\ WF_vars(ActionConfirmed \/ ActionFailed \/ ActionRejected)
    /\ WF_vars(AllowanceOk \/ AllowanceLow \/ AllowanceFail)

InFlightSettles ==
    [](step \in {"Approving", "Acting", "CheckingAllowance"} =>
        <>(step \notin {"Approving", "Acting", "CheckingAllowance"}))

--------------------------------------------------------------------------
Spec == Init /\ [][Next]_vars /\ LegFairness

==========================================================================
