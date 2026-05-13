module V13PrimitivesCompileTest exposing (suite)

{-| Smoke test that all six v1.3.0 primitives compile and emit their
expected outermost CSS class. Not a behavioral test — its job is to gate
the build so a refactor in the lib can't ship a broken module.
-}

import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import Web3.BigInt as BigInt
import Web3.Ui.BondCard as BondCard
import Web3.Ui.FeeFlowDiagram as FeeFlowDiagram
import Web3.Ui.GaugeRow as GaugeRow
import Web3.Ui.NFTStakeCard as NFTStakeCard
import Web3.Ui.VeBalanceChart as VeBalanceChart
import Web3.Ui.VeLock as VeLock


type Msg
    = NoOp
    | StringMsg String
    | IntMsg Int


suite : Test
suite =
    describe "v1.3.0 primitives compile + emit base class"
        [ test "VeLock" <|
            \_ ->
                VeLock.view
                    { amount = BigInt.fromInt 1000
                    , amountInput = "1000"
                    , decimals = 18
                    , symbol = "TKN"
                    , veSymbol = "veToken"
                    , lockSec = 604800
                    , minLockSec = 604800
                    , maxLockSec = 126144000
                    , stepSec = 604800
                    , onAmountInput = StringMsg
                    , onLockChange = IntMsg
                    }
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "web3-velock" ]
        , test "VeBalanceChart" <|
            \_ ->
                VeBalanceChart.view
                    { amount = BigInt.fromInt 1000
                    , unlockTime = 200000
                    , maxLockSec = 126144000
                    , nowSec = 100000
                    , width = 320
                    , height = 80
                    }
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "web3-vebalancechart" ]
        , test "NFTStakeCard" <|
            \_ ->
                NFTStakeCard.view
                    { tokenId = 7
                    , amount = BigInt.fromInt 1000
                    , symbol = "PULSE"
                    , decimals = 18
                    , startTimeSec = 100
                    , unlockTimeSec = 200
                    , floorEligibleAt = 150
                    , pendingYield = BigInt.fromInt 5
                    , yieldSymbol = "PLS"
                    , nowSec = 120
                    , onClaimYield = Just NoOp
                    , onUnstake = Just NoOp
                    , onRedeemAtFloor = Just NoOp
                    , onTransfer = Just NoOp
                    }
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "web3-nftstakecard" ]
        , test "BondCard" <|
            \_ ->
                BondCard.view
                    { bondId = 3
                    , principal = BigInt.fromInt 100
                    , principalSymbol = "PLS"
                    , decimals = 18
                    , maturitySec = 200
                    , nowSec = 100
                    , pendingYield = BigInt.fromInt 1
                    , yieldSymbol = "PLS"
                    , onClaimYield = Just NoOp
                    , onRedeem = Just NoOp
                    , onRoll = Just NoOp
                    }
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "web3-bondcard" ]
        , test "GaugeRow" <|
            \_ ->
                GaugeRow.view
                    { gaugeLabel = "PULSE/PLS"
                    , epoch = 12
                    , currentEpoch = 12
                    , totalVotes = BigInt.fromInt 1000
                    , totalBribes = BigInt.fromInt 50
                    , bribeSymbol = "PLS"
                    , bribeDecimals = 18
                    , veSymbol = "veToken"
                    , veDecimals = 18
                    , yourVote = BigInt.fromInt 100
                    , aprBps = Just 1500
                    , onVote = Just NoOp
                    , onBribe = Just NoOp
                    , onClaim = Nothing
                    }
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "web3-gaugerow" ]
        , test "FeeFlowDiagram" <|
            \_ ->
                FeeFlowDiagram.view
                    { gross = BigInt.fromInt 1000
                    , symbol = "PLS"
                    , decimals = 18
                    , width = 480
                    , height = 24
                    , slices =
                        [ { label = "veToken", bps = 3000, kind = Just "ve" }
                        , { label = "stakers", bps = 3000, kind = Just "stakers" }
                        , { label = "floor", bps = 2000, kind = Just "floor" }
                        , { label = "burn", bps = 1000, kind = Just "burn" }
                        , { label = "treasury", bps = 1000, kind = Just "treasury" }
                        ]
                    }
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "web3-feeflow" ]
        ]
