module SignUiTest exposing (suite)

import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import Web3.Sign as Sign
import Web3.Ui.Sign as SignUi


suite : Test
suite =
    describe "Web3.Ui.Sign"
        [ describe "stateView"
            [ test "SignIdle shows 'Idle'" <|
                \_ ->
                    SignUi.stateView [] Sign.SignIdle
                        |> Query.fromHtml
                        |> Query.has [ Selector.text "Idle" ]
            , test "SignPending shows 'Waiting for signature…'" <|
                \_ ->
                    SignUi.stateView [] (Sign.SignPending "req-1")
                        |> Query.fromHtml
                        |> Query.has [ Selector.text "Waiting for signature…" ]
            , test "Signed shows 'Signed'" <|
                \_ ->
                    SignUi.stateView [] (Sign.Signed "req-1" "0xsig")
                        |> Query.fromHtml
                        |> Query.has [ Selector.text "Signed" ]
            , test "SignFailed shows 'Failed: <err>'" <|
                \_ ->
                    SignUi.stateView [] (Sign.SignFailed "req-1" "user rejected")
                        |> Query.fromHtml
                        |> Query.has [ Selector.text "Failed: user rejected" ]
            , test "SignRejected shows 'Rejected'" <|
                \_ ->
                    SignUi.stateView [] (Sign.SignRejected "req-1")
                        |> Query.fromHtml
                        |> Query.has [ Selector.text "Rejected" ]
            ]
        , describe "signatureView"
            [ test "Signed: has web3-signature class" <|
                \_ ->
                    SignUi.signatureView [] (Sign.Signed "req-1" "0xdeadbeef")
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "web3-signature" ]
            , test "Signed: has web3-signature-value class on code element" <|
                \_ ->
                    SignUi.signatureView [] (Sign.Signed "req-1" "0xdeadbeef")
                        |> Query.fromHtml
                        |> Query.find [ Selector.tag "code" ]
                        |> Query.has [ Selector.class "web3-signature-value" ]
            , test "Signed: shows the signature text" <|
                \_ ->
                    SignUi.signatureView [] (Sign.Signed "req-1" "0xdeadbeef")
                        |> Query.fromHtml
                        |> Query.has [ Selector.text "0xdeadbeef" ]
            , test "SignIdle: does NOT have web3-signature class" <|
                \_ ->
                    SignUi.signatureView [] Sign.SignIdle
                        |> Query.fromHtml
                        |> Query.hasNot [ Selector.class "web3-signature" ]
            ]
        ]
