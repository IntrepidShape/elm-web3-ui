module DecimalsAndPrecisionTest exposing (suite)

{-| Regressions for the two boundary defects in the display layer:

  - E6: a card that formats a second token's amount with the first token's
    `decimals`. A 6-decimal reward beside an 18-decimal stake rendered 1e12 too
    small, which is the same bug class the 2.4.0 changelog records against a
    live app.

  - E7: uint256 values routed through `Float`. Every property below is chosen
    so the old `String.toFloat (BigInt.toString ...)` path gives a different --
    and wrong -- answer; each case notes what it used to produce.

-}

import Expect
import Fuzz
import Html
import Html.Attributes as Attr
import Test exposing (Test, describe, fuzz2, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import Web3.BigInt as BigInt exposing (BigInt)
import Web3.Ui.BondCard as BondCard
import Web3.Ui.BondingCurve as BondingCurve
import Web3.Ui.FundingPool as FundingPool
import Web3.Ui.GaugeRow as GaugeRow
import Web3.Ui.Internal.Decimal as Decimal
import Web3.Ui.NFTStakeCard as NFTStakeCard
import Web3.Ui.ProgressRing as ProgressRing
import Web3.Ui.StakeCard as StakeCard
import Web3.Ui.SupplyBar as SupplyBar
import Web3.Ui.TrendIndicator as TrendIndicator
import Web3.Ui.VeBalanceChart as VeBalanceChart


type Msg
    = NoOp


{-| A BigInt from its decimal digits. Never `BigInt.fromInt`: that corrupts
values above 2^53, which is precisely the range under test here.
-}
big : String -> BigInt
big s =
    BigInt.fromString s |> Maybe.withDefault BigInt.zero


pow10 : Int -> String
pow10 n =
    "1" ++ String.repeat n "0"


nines : Int -> String
nines n =
    String.repeat n "9"


countMatching : List Selector.Selector -> Query.Single msg -> Expect.Expectation
countMatching selectors =
    Query.findAll selectors >> Query.count (Expect.equal 0)


suite : Test
suite =
    describe "decimals correctness + integer-space ratios"
        [ secondTokenDecimals
        , ratioHelpers
        , floatRoundTripRegressions
        ]



-- E6 ------------------------------------------------------------------------


secondTokenDecimals : Test
secondTokenDecimals =
    describe "E6 -- the second token carries its own decimals"
        [ test "StakeCard renders a 6-decimal yield beside an 18-decimal stake" <|
            \_ ->
                StakeCard.view
                    { amount = big (pow10 18)
                    , symbol = "TKN"
                    , decimals = 18
                    , startTimeSec = 0
                    , lockDays = 30
                    , nowSec = 0
                    , yieldAccrued = big "2500000"
                    , yieldSymbol = "USDC"
                    , yieldDecimals = 6
                    , badges = []
                    , onClaimYield = Just NoOp
                    , onUnstake = Just NoOp
                    , unstakeLabel = "Unstake"
                    }
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.find [ Selector.class "web3-stakecard__amount" ]
                            >> Query.has [ Selector.exactText "1" ]
                        , Query.find [ Selector.class "web3-stakecard__yield" ]
                            >> Query.has [ Selector.exactText "2.5" ]

                        -- What the shared `decimals` field used to render.
                        , countMatching [ Selector.text "0.0000000000025" ]
                        ]
        , test "NFTStakeCard renders a 6-decimal pending yield" <|
            \_ ->
                NFTStakeCard.view
                    { tokenId = 7
                    , amount = big (pow10 18)
                    , symbol = "TKN"
                    , decimals = 18
                    , startTimeSec = 0
                    , unlockTimeSec = 100
                    , floorEligibleAt = 50
                    , pendingYield = big "2500000"
                    , yieldSymbol = "USDC"
                    , yieldDecimals = 6
                    , nowSec = 10
                    , onClaimYield = Just NoOp
                    , onUnstake = Just NoOp
                    , onRedeemAtFloor = Just NoOp
                    , onTransfer = Just NoOp
                    }
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.find [ Selector.class "web3-nftstakecard__amount" ]
                            >> Query.has [ Selector.exactText "1" ]
                        , Query.find [ Selector.class "web3-nftstakecard__yield" ]
                            >> Query.has [ Selector.exactText "2.5" ]
                        , countMatching [ Selector.text "0.0000000000025" ]
                        ]
        , test "BondCard renders a 6-decimal coupon on an 18-decimal principal" <|
            \_ ->
                BondCard.view
                    { bondId = 3
                    , principal = big (pow10 18)
                    , principalSymbol = "TKN"
                    , decimals = 18
                    , maturitySec = 200
                    , nowSec = 100
                    , pendingYield = big "2500000"
                    , yieldSymbol = "USDC"
                    , yieldDecimals = 6
                    , onClaimYield = Just NoOp
                    , onRedeem = Just NoOp
                    , onRoll = Just NoOp
                    }
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.find [ Selector.class "web3-bondcard__principal" ]
                            >> Query.has [ Selector.exactText "1" ]
                        , Query.find [ Selector.class "web3-bondcard__yield" ]
                            >> Query.has [ Selector.exactText "2.5" ]
                        , countMatching [ Selector.text "0.0000000000025" ]
                        ]
        , test "SupplyBar labels a 6-decimal token at its own scale" <|
            \_ ->
                SupplyBar.view
                    { current = big "1500000"
                    , max = big "3000000"
                    , decimals = 6
                    , label = Just "supply"
                    }
                    |> Query.fromHtml
                    |> Query.find [ Selector.class "web3-supplybar__label" ]
                    |> Expect.all
                        [ Query.has [ Selector.exactText "1.5" ]
                        , Query.has [ Selector.exactText "3" ]
                        ]
        , test "TrendIndicator pills a 6-decimal volume at its own scale" <|
            \_ ->
                TrendIndicator.view
                    { trend = TrendIndicator.Up
                    , buyVolume = big "1500000"
                    , sellVolume = big "3000000"
                    , decimals = 6
                    }
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.find [ Selector.class "web3-trend__pill--buy" ]
                            >> Query.has [ Selector.exactText "1.5" ]
                        , Query.find [ Selector.class "web3-trend__pill--sell" ]
                            >> Query.has [ Selector.exactText "3" ]
                        ]
        ]



-- E7 -- THE HELPERS ---------------------------------------------------------


ratioHelpers : Test
ratioHelpers =
    describe "E7 -- Internal.Decimal divides in BigInt space"
        [ fuzz2 (Fuzz.intRange 0 9999) (Fuzz.intRange 18 60) "ratioBps is exact for any k * 10^e over 10^(e+4)" <|
            \k e ->
                let
                    num =
                        if k == 0 then
                            "0"

                        else
                            String.fromInt k ++ String.repeat e "0"
                in
                Decimal.ratioBps (big num) (big (pow10 (e + 4)))
                    |> Expect.equal k
        , test "ratioBps of equal 27-digit values is exactly 10000" <|
            \_ ->
                -- `String.toInt "1000000000000000000000000000"` yields the
                -- non-integral 9.999999999999999e26, which then corrupts `//`.
                Decimal.ratioBps (big (pow10 27)) (big (pow10 27))
                    |> Expect.equal 10000
        , test "ratioBps is exact at 2^53 + 1, where Float stops counting" <|
            \_ ->
                Decimal.ratioBps (big "9007199254740993") (big "9007199254740993")
                    |> Expect.equal 10000
        , test "ratioBps sees a difference Float cannot: 1e27 vs 1e27 + 1e12" <|
            \_ ->
                -- Float rounds both operands to 1e27 and answers 10000.
                Decimal.ratioBps (big (pow10 27)) (big "1000000000001000000000000000")
                    |> Expect.equal 9999
        , test "ratioBps clamps instead of wrapping int32" <|
            \_ ->
                -- The old `String.toInt (BigInt.toString b)` handed 1e34 to
                -- `//`, which is `| 0` in JS and returns garbage.
                Decimal.ratioBps (big (pow10 30)) (big "1")
                    |> Expect.equal Decimal.maxScaled
        , test "ratioBps of anything over zero is zero, not a crash" <|
            \_ ->
                Decimal.ratioBps (big (pow10 30)) BigInt.zero
                    |> Expect.equal 0
        , test "scaledRatio resolves one part in a million" <|
            \_ ->
                Decimal.scaledRatio 1000000 (big (pow10 24)) (big (pow10 30))
                    |> Expect.equal 1
        , test "fixedPoint renders hundredths" <|
            \_ ->
                [ Decimal.fixedPoint 2 1234
                , Decimal.fixedPoint 2 5
                , Decimal.fixedPoint 2 0
                , Decimal.fixedPoint 2 -5
                , Decimal.fixedPoint 0 42
                ]
                    |> Expect.equal [ "12.34", "0.05", "0.00", "-0.05", "42" ]
        , test "bigFromDecimalString scales and truncates in string space" <|
            \_ ->
                [ Decimal.bigFromDecimalString 2 "14.75"
                , Decimal.bigFromDecimalString 2 "1.239"
                , Decimal.bigFromDecimalString 2 "25"
                , Decimal.bigFromDecimalString 0 "7"
                ]
                    |> List.map (Maybe.map BigInt.toString)
                    |> Expect.equal [ Just "1475", Just "123", Just "2500", Just "7" ]
        , test "bigFromDecimalString keeps every digit of a wei-sized string" <|
            \_ ->
                Decimal.bigFromDecimalString 0 (nines 30)
                    |> Maybe.map BigInt.toString
                    |> Expect.equal (Just (nines 30))
        , test "bigFromDecimalString rejects junk" <|
            \_ ->
                [ Decimal.bigFromDecimalString 2 "1.2.3"
                , Decimal.bigFromDecimalString 2 "abc"
                , Decimal.bigFromDecimalString 2 ""
                , Decimal.bigFromDecimalString 2 "1e18"
                ]
                    |> Expect.equal [ Nothing, Nothing, Nothing, Nothing ]
        , test "log10 stays exact in the exponent far above 2^53" <|
            \_ ->
                Decimal.log10 (big (pow10 77))
                    |> Maybe.map (\l -> abs (l - 77) < 1.0e-9)
                    |> Expect.equal (Just True)
        , test "log10 rejects zero" <|
            \_ ->
                Decimal.log10 BigInt.zero |> Expect.equal Nothing
        , test "powScaled raises a bounded ratio on its own scale" <|
            \_ ->
                Decimal.powScaled 1000000 2 500000 |> Expect.equal 250000
        , test "the constants the helpers lift into BigInt are exact" <|
            \_ ->
                -- `BigInt.fromInt` corrupts above 2^53; every constant these
                -- helpers lift stays far below it, and the clamp boundary in
                -- particular has to be exact or the clamp moves.
                [ BigInt.toString (BigInt.fromInt Decimal.maxScaled)
                , BigInt.toString (BigInt.fromInt 1000000)
                , BigInt.toString (BigInt.fromInt 10000)
                ]
                    |> Expect.equal [ "2147483647", "1000000", "10000" ]
        ]



-- E7 -- THE CALL SITES ------------------------------------------------------


floatRoundTripRegressions : Test
floatRoundTripRegressions =
    describe "E7 -- no uint256 reaches a Float at any call site"
        [ test "GaugeRow: one wei short of the whole gauge is not 100%" <|
            \_ ->
                gaugeRow (big (nines 27)) (big (pow10 27))
                    |> Query.fromHtml
                    |> Query.find [ Selector.class "web3-gaugerow__share" ]
                    |> Expect.all
                        [ Query.has [ Selector.exactText "99.99%" ]

                        -- The Float path rounded the two operands together.
                        , countMatching [ Selector.text "100%" ]
                        ]
        , test "GaugeRow: an exact quarter share reads 25%" <|
            \_ ->
                gaugeRow (big (pow10 27)) (big "4000000000000000000000000000")
                    |> Query.fromHtml
                    |> Query.find [ Selector.class "web3-gaugerow__share" ]
                    |> Query.has [ Selector.exactText "25%" ]
        , test "GaugeRow: an absurd share clamps instead of wrapping to garbage" <|
            \_ ->
                -- `String.toInt` of the 10^34 bps figure was non-integral, and
                -- `bps // 100` then truncated it to int32.
                gaugeRow (big (pow10 30)) (big "1")
                    |> Query.fromHtml
                    |> Query.find [ Selector.class "web3-gaugerow__share" ]
                    |> Query.has [ Selector.exactText "21474836.47%" ]
        , test "SupplyBar: one wei short of the cap is 99.99%, not full" <|
            \_ ->
                SupplyBar.view
                    { current = big (nines 30)
                    , max = big (pow10 30)
                    , decimals = 18
                    , label = Nothing
                    }
                    |> Query.fromHtml
                    |> Query.find [ Selector.class "web3-supplybar__fill" ]
                    |> Query.has [ Selector.style "width" "99.99%" ]
        , test "SupplyBar: an empty bar is 0.00%" <|
            \_ ->
                supplyBarFill BigInt.zero (big (pow10 30))
                    |> Query.has [ Selector.style "width" "0.00%" ]
        , test "SupplyBar: a full bar is 100.00%" <|
            \_ ->
                supplyBarFill (big (pow10 30)) (big (pow10 30))
                    |> Query.has [ Selector.style "width" "100.00%" ]
        , test "SupplyBar: a milestone sits where BigInt division puts it" <|
            \_ ->
                SupplyBar.withMilestone
                    { current = big (pow10 27)
                    , max = big (pow10 30)
                    , decimals = 18
                    , milestone = Just { at = big "250000000000000000000000000000", label = "graduation" }
                    , label = Nothing
                    }
                    |> Query.fromHtml
                    |> Query.find [ Selector.class "web3-supplybar__milestone" ]
                    |> Query.has [ Selector.style "left" "25.00%" ]
        , test "TrendIndicator: the smaller side no longer wins the threshold" <|
            \_ ->
                -- buy is strictly less than sell, by a margin Float cannot see
                -- (1e40 is below the ulp of 1e60). The Float path scored both
                -- at exactly 5000 bps, hit the buy branch first, and reported
                -- Up on a selling market.
                TrendIndicator.fromVolumes
                    { buyVolume = big (nines 20 ++ String.repeat 40 "0")
                    , sellVolume = big (pow10 60)
                    , thresholdBps = 4999
                    }
                    |> Expect.equal TrendIndicator.Down
        , test "TrendIndicator: zero volume is Neutral" <|
            \_ ->
                TrendIndicator.fromVolumes
                    { buyVolume = BigInt.zero
                    , sellVolume = BigInt.zero
                    , thresholdBps = 5800
                    }
                    |> Expect.equal TrendIndicator.Neutral
        , test "TrendIndicator: a dominant side above 2^53 still trips" <|
            \_ ->
                TrendIndicator.fromVolumes
                    { buyVolume = big (pow10 30)
                    , sellVolume = big (pow10 28)
                    , thresholdBps = 9000
                    }
                    |> Expect.equal TrendIndicator.Up
        , test "VeBalanceChart: a balance past Float's range still plots" <|
            \_ ->
                -- `String.toFloat` of a 401-digit amount is Infinity, and
                -- Infinity / Infinity painted every coordinate "NaN".
                VeBalanceChart.view
                    { amount = big (pow10 400)
                    , unlockTime = 200000
                    , maxLockSec = 126144000
                    , nowSec = 100000
                    , width = 320
                    , height = 80
                    }
                    |> Query.fromHtml
                    |> Query.find [ Selector.class "web3-vebalancechart__current" ]
                    |> Expect.all
                        [ Query.has [ Selector.attribute (Attr.attribute "cx" "0.00") ]
                        , Query.has [ Selector.attribute (Attr.attribute "cy" "0.00") ]
                        ]
        , test "VeBalanceChart: an expired lock sits flat on the axis" <|
            \_ ->
                VeBalanceChart.view
                    { amount = big (pow10 27)
                    , unlockTime = 100
                    , maxLockSec = 126144000
                    , nowSec = 100000
                    , width = 320
                    , height = 80
                    }
                    |> Query.fromHtml
                    |> Query.find [ Selector.class "web3-vebalancechart__current" ]
                    |> Query.has [ Selector.attribute (Attr.attribute "cy" "80.00") ]
        , test "ProgressRing: geometry is integer-derived and finite" <|
            \_ ->
                ProgressRing.view
                    { current = big (pow10 30)
                    , target = big (pow10 30)
                    , size = 64
                    , label = Just "graduation"
                    }
                    |> Query.fromHtml
                    |> Query.find [ Selector.class "web3-progressring__fill" ]
                    |> Expect.all
                        [ Query.has [ Selector.attribute (Attr.attribute "stroke-dasharray" "175.92") ]
                        , Query.has [ Selector.attribute (Attr.attribute "stroke-dashoffset" "0.00") ]
                        ]
        , test "ProgressRing: an empty ring is fully offset" <|
            \_ ->
                ProgressRing.view
                    { current = BigInt.zero
                    , target = big (pow10 30)
                    , size = 64
                    , label = Nothing
                    }
                    |> Query.fromHtml
                    |> Query.find [ Selector.class "web3-progressring__fill" ]
                    |> Query.has [ Selector.attribute (Attr.attribute "stroke-dashoffset" "175.92") ]
        , test "BondingCurve: the spot marker comes from a BigInt-space ratio" <|
            \_ ->
                -- Half the supply on an x^2 curve is a quarter of the price,
                -- so the marker sits at (50%, 75%) of a 100x100 box.
                bondingCurve 18 (big (pow10 18)) (big "500000000000000000000000000") (big (pow10 27)) Nothing
                    |> Query.fromHtml
                    |> Query.find [ Selector.class "web3-bondingcurve__spot" ]
                    |> Expect.all
                        [ Query.has [ Selector.attribute (Attr.attribute "cx" "50.00") ]
                        , Query.has [ Selector.attribute (Attr.attribute "cy" "75.00") ]
                        ]
        , test "BondingCurve: the floor line honours a 6-decimal unit scale" <|
            \_ ->
                -- coeffA = 1.0 and maxSupply = 1e9 tokens, both at 6 decimals,
                -- put the top of the curve at price 1e18; a floor of 2.5e17 is
                -- a quarter of it. The hardcoded 1e18 unit scale drew this line
                -- 1e12 out of place, far off the canvas.
                bondingCurve 6 (big (pow10 6)) (big (pow10 15)) (big (pow10 15)) (Just (big "250000000000000000000000"))
                    |> Query.fromHtml
                    |> Query.find [ Selector.class "web3-bondingcurve__floor" ]
                    |> Query.has [ Selector.attribute (Attr.attribute "y1" "75.00") ]
        , test "FundingPool: a wei-sized pool one short of target is not funded" <|
            \_ ->
                fundingPool (nines 30) (pow10 30)
                    |> Query.fromHtml
                    |> Query.find [ Selector.attribute (Attr.attribute "role" "progressbar") ]
                    |> Query.has [ Selector.attribute (Attr.attribute "aria-valuenow" "99") ]
        , test "FundingPool: ordinary decimal strings still work" <|
            \_ ->
                fundingPool "14.75" "25"
                    |> Query.fromHtml
                    |> Query.find [ Selector.attribute (Attr.attribute "role" "progressbar") ]
                    |> Query.has [ Selector.attribute (Attr.attribute "aria-valuenow" "59") ]
        , test "FundingPool: unparseable input reads as zero progress" <|
            \_ ->
                fundingPool "1e18" "25"
                    |> Query.fromHtml
                    |> Query.find [ Selector.attribute (Attr.attribute "role" "progressbar") ]
                    |> Query.has [ Selector.attribute (Attr.attribute "aria-valuenow" "0") ]
        ]



-- FIXTURES ------------------------------------------------------------------


gaugeRow : BigInt -> BigInt -> Html.Html Msg
gaugeRow yourVote totalVotes =
    GaugeRow.view
        { gaugeLabel = "PAIR"
        , epoch = 12
        , currentEpoch = 12
        , totalVotes = totalVotes
        , totalBribes = big (pow10 18)
        , bribeSymbol = "USDC"
        , bribeDecimals = 6
        , veSymbol = "veToken"
        , veDecimals = 18
        , yourVote = yourVote
        , aprBps = Just 1500
        , onVote = Just NoOp
        , onBribe = Just NoOp
        , onClaim = Nothing
        }


bondingCurve : Int -> BigInt -> BigInt -> BigInt -> Maybe BigInt -> Html.Html Msg
bondingCurve decimals coeffA supply maxSupply floorPrice =
    BondingCurve.sparkline
        { coeffA = coeffA
        , exponent = 2
        , supply = supply
        , maxSupply = maxSupply
        , floorPrice = floorPrice
        , decimals = decimals
        , width = 100
        , height = 100
        }


supplyBarFill : BigInt -> BigInt -> Query.Single Msg
supplyBarFill current max =
    SupplyBar.view { current = current, max = max, decimals = 18, label = Nothing }
        |> Query.fromHtml
        |> Query.find [ Selector.class "web3-supplybar__fill" ]


fundingPool : String -> String -> Html.Html Msg
fundingPool balance target =
    FundingPool.view []
        { pool =
            FundingPool.pool
                { target = target
                , balance = balance
                , unit = "PLS"
                , deadline = "6 days"
                , pledgerCount = 47
                , topPledgers = []
                , status = FundingPool.Open
                , reportUrl = Nothing
                }
        , labels = FundingPool.defaultLabels
        , onPledge = Just NoOp
        , onPledgeCustom = Nothing
        , onRefund = Nothing
        , onViewReport = Nothing
        }
