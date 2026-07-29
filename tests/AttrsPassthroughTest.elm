module AttrsPassthroughTest exposing (suite)

{-| E1: the README's attribute-passthrough promise, asserted at runtime.

`scripts/check-attrs-passthrough.ts` proves every exposed view *accepts*
`List (Html.Attribute msg)` first and mentions it. That is a static check and
it cannot see which element the attributes end up on. These tests close that
gap for the cases where "the root" is not a single fixed node:

  - components that pick a different root per state (AccountPill, TokenLogo,
    RemoteCall, ChainGate),
  - components whose meaningful target is an inner control reached through a
    named config field rather than the first positional argument
    (Amount.amountInput, TokenSearch, LockPeriod).

A `data-testid` is used as the probe because it is the exact attribute a
consumer reached for and could not attach before this change.

-}

import Expect
import Html
import Html.Attributes as Attr
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import Web3.Transaction as Tx
import Web3.Types as T
import Web3.Ui.AccountPill as AccountPill
import Web3.Ui.Amount as Amount
import Web3.Ui.ApprovalFlow as ApprovalFlow
import Web3.Ui.ChainGate as ChainGate
import Web3.Ui.LockPeriod as LockPeriod
import Web3.Ui.RemoteCall as RemoteCall
import Web3.Ui.StatCell as StatCell
import Web3.Ui.TokenLogo as TokenLogo
import Web3.Ui.TokenSearch as TokenSearch
import Web3.Ui.TxQueue as TxQueue
import Web3.Wallet as Wallet


type Msg
    = NoOp
    | Typed String
    | Picked Int
    | Dismissed String


probe : Html.Attribute msg
probe =
    Attr.attribute "data-testid" "probe"


hasProbe : Html.Html msg -> Expect.Expectation
hasProbe html =
    html
        |> Query.fromHtml
        |> Query.has [ Selector.attribute probe ]


{-| The library's own class must survive alongside the caller's attributes --
passthrough that clobbers the class contract is not passthrough.
-}
hasProbeAnd : String -> Html.Html msg -> Expect.Expectation
hasProbeAnd cls html =
    html
        |> Query.fromHtml
        |> Query.has [ Selector.attribute probe, Selector.class cls ]


addr : T.Address
addr =
    addrOr "0x1234567890abcdef1234567890abcdef12345678"


addrOr : String -> T.Address
addrOr s =
    case T.address s of
        Just a ->
            a

        Nothing ->
            addrOr "0x0000000000000000000000000000000000000000"


pillConfig : AccountPill.Config Msg
pillConfig =
    { onConnect = NoOp
    , onDisconnect = NoOp
    , chainLabel = \_ -> "PulseChain"
    , balance = Nothing
    }


suite : Test
suite =
    describe "attribute passthrough (E1)"
        [ describe "a fixed root keeps the library class"
            [ test "StatCell" <|
                \_ ->
                    StatCell.view [ probe ]
                        { label = "TVL"
                        , value = "$1.2M"
                        , delta = Nothing
                        , sentiment = StatCell.Neutral
                        }
                        |> hasProbeAnd "web3-statcell"
            , test "TxQueue.toastStack (empty queue still carries them)" <|
                \_ ->
                    TxQueue.toastStack [ probe ]
                        { onDismiss = Dismissed, explorerUrl = Nothing }
                        TxQueue.empty
                        |> hasProbeAnd "web3-txq"
            ]
        , describe "a state-dependent root carries them in every branch"
            [ test "AccountPill: Disconnected (button root)" <|
                \_ ->
                    AccountPill.view [ probe ] pillConfig Wallet.Disconnected
                        |> hasProbeAnd "web3-pill"
            , test "AccountPill: ReadOnly (chip root)" <|
                \_ ->
                    AccountPill.view [ probe ] pillConfig Wallet.ReadOnly
                        |> hasProbeAnd "web3-pill"
            , test "AccountPill: Connected (pill root)" <|
                \_ ->
                    AccountPill.view [ probe ]
                        pillConfig
                        (Wallet.Connected { address = addr, chainId = T.chainId 369 })
                        |> hasProbeAnd "web3-pill"
            , test "AccountPill: WrongChain (pill root)" <|
                \_ ->
                    AccountPill.view [ probe ]
                        pillConfig
                        (Wallet.WrongChain { address = addr, chainId = T.chainId 1 } (T.chainId 369))
                        |> hasProbeAnd "web3-pill"
            , test "TokenLogo: img branch" <|
                \_ ->
                    TokenLogo.view [ probe ]
                        { logoUrl = Just "https://tokens.example/usdc.png"
                        , symbol = "USDC"
                        , size = 24
                        }
                        |> hasProbeAnd "web3-tokenlogo"
            , test "TokenLogo: letter-tile fallback branch" <|
                \_ ->
                    TokenLogo.view [ probe ]
                        { logoUrl = Nothing, symbol = "FOO", size = 24 }
                        |> hasProbeAnd "web3-tokenlogo"
            , test "RemoteCall: loading branch" <|
                \_ ->
                    RemoteCall.view [ probe ]
                        { skeleton = Html.text "", failed = \_ -> Html.text "" }
                        Html.text
                        (RemoteCall.request "r1" RemoteCall.notAsked)
                        |> hasProbeAnd "web3-remote"
            , test "RemoteCall: ready branch" <|
                \_ ->
                    RemoteCall.view [ probe ]
                        { skeleton = Html.text "", failed = \_ -> Html.text "" }
                        Html.text
                        (RemoteCall.resolve "r1" (Ok "done") (RemoteCall.request "r1" RemoteCall.notAsked))
                        |> hasProbeAnd "web3-remote"
            , test "RemoteCall: failed branch" <|
                \_ ->
                    RemoteCall.view [ probe ]
                        { skeleton = Html.text "", failed = \_ -> Html.text "" }
                        Html.text
                        (RemoteCall.resolve "r1" (Err "reverted") (RemoteCall.request "r1" RemoteCall.notAsked))
                        |> hasProbeAnd "web3-remote"
            , test "ApprovalFlow: state is last, attrs are first" <|
                \_ ->
                    ApprovalFlow.view [ probe ]
                        { approveLabel = "Approve"
                        , actionLabel = "Stake"
                        , onApprove = NoOp
                        , onAction = NoOp
                        , onRetry = NoOp
                        }
                        ApprovalFlow.start
                        |> hasProbeAnd "web3-approval"
            ]
        , describe "ChainGate renders its own root in both branches"
            [ test "on the expected chain" <|
                \_ ->
                    ChainGate.view [ probe ]
                        { wallet = Wallet.Connected { address = addr, chainId = T.chainId 369 }
                        , expectedChain = T.chainId 369
                        , wrongChain = Html.text "switch"
                        , content = Html.text "app"
                        }
                        |> Expect.all
                            [ hasProbeAnd "web3-chaingate"
                            , Query.fromHtml >> Query.has [ Selector.text "app" ]
                            ]
            , test "on the wrong chain" <|
                \_ ->
                    ChainGate.view [ probe ]
                        { wallet = Wallet.Connected { address = addr, chainId = T.chainId 1 }
                        , expectedChain = T.chainId 369
                        , wrongChain = Html.text "switch"
                        , content = Html.text "app"
                        }
                        |> Expect.all
                            [ hasProbeAnd "web3-chaingate"
                            , Query.fromHtml >> Query.has [ Selector.text "switch" ]
                            ]
            ]
        , describe "an inner control is reachable through inputAttrs"
            [ test "Amount.amountInput: wrapper takes attrs, input takes inputAttrs" <|
                \_ ->
                    Amount.amountInput [ Attr.attribute "data-testid" "wrapper" ]
                        { value = "1.5"
                        , onInput = Typed
                        , decimals = 18
                        , symbol = "PLS"
                        , valid = True
                        , inputAttrs = [ Attr.id "amount", probe ]
                        }
                        |> Query.fromHtml
                        |> Expect.all
                            [ Query.has [ Selector.attribute (Attr.attribute "data-testid" "wrapper") ]
                            , Query.find [ Selector.class "web3-amount-input" ]
                                >> Query.has [ Selector.id "amount", Selector.attribute probe ]
                            ]
            , test "TokenSearch: the search input is addressable" <|
                \_ ->
                    TokenSearch.view []
                        { value = ""
                        , onInput = Typed
                        , placeholder = "Search"
                        , inputAttrs = [ Attr.id "token-search" ]
                        }
                        |> Query.fromHtml
                        |> Query.find [ Selector.class "web3-tokensearch__input" ]
                        |> Query.has [ Selector.id "token-search" ]
            , test "LockPeriod: the range slider is addressable" <|
                \_ ->
                    LockPeriod.view []
                        { value = 30
                        , onChange = Picked
                        , min = 1
                        , max = 365
                        , penaltyAtMax = Nothing
                        , inputAttrs = [ Attr.id "lock-days" ]
                        }
                        |> Query.fromHtml
                        |> Query.find [ Selector.class "web3-lockperiod__slider" ]
                        |> Query.has [ Selector.id "lock-days" ]
            ]
        , describe "caller attributes come last, so they can override"
            [ test "a caller title beats the library's own on a fixed root" <|
                \_ ->
                    -- SupplyBar-style roots put the library attrs first and
                    -- the caller's after; Elm applies the last one written.
                    StatCell.view [ Attr.title "caller" ]
                        { label = "TVL"
                        , value = "$1.2M"
                        , delta = Nothing
                        , sentiment = StatCell.Neutral
                        }
                        |> Query.fromHtml
                        |> Query.has [ Selector.attribute (Attr.title "caller") ]
            ]
        , describe "unrelated behaviour is untouched"
            [ test "an empty attrs list renders exactly what it always did" <|
                \_ ->
                    Expect.equal
                        (TxQueue.toastStack []
                            { onDismiss = Dismissed, explorerUrl = Nothing }
                            (TxQueue.begin "q1" "Approve" TxQueue.empty)
                        )
                        (TxQueue.toastStack []
                            { onDismiss = Dismissed, explorerUrl = Nothing }
                            (TxQueue.begin "q1" "Approve" TxQueue.empty)
                        )
            , test "a pending tx still reaches the toast stack" <|
                \_ ->
                    TxQueue.toastStack [ probe ]
                        { onDismiss = Dismissed, explorerUrl = Nothing }
                        (TxQueue.update "q1" (Tx.TxSubmitted Nothing hashString) (TxQueue.begin "q1" "Approve" TxQueue.empty))
                        |> Query.fromHtml
                        |> Query.has [ Selector.attribute probe, Selector.class "web3-txq" ]
            ]
        ]


hashString : String
hashString =
    "0x" ++ String.repeat 64 "a"
