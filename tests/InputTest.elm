module InputTest exposing (suite)

import Expect
import Html
import Html.Attributes as Attr
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import Web3.Ui.Input as Input


suite : Test
suite =
    describe "Web3.Ui.Input"
        [ describe "address input"
            [ test "has web3-input-address class" <|
                \_ ->
                    Input.address [] { value = "", onInput = identity }
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "web3-input-address" ]
            , test "extra attrs are applied" <|
                \_ ->
                    Input.address [ Attr.id "my-input" ] { value = "", onInput = identity }
                        |> Query.fromHtml
                        |> Query.has [ Selector.id "my-input" ]
            , test "value is reflected" <|
                \_ ->
                    Input.address [] { value = "0xabc", onInput = identity }
                        |> Query.fromHtml
                        |> Query.has [ Selector.attribute (Attr.value "0xabc") ]
            ]
        , describe "bigInt input"
            [ test "has web3-input-bigint class" <|
                \_ ->
                    Input.bigInt [] { value = "", onInput = identity }
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "web3-input-bigint" ]
            ]
        , describe "bool input"
            [ test "has web3-input-bool class" <|
                \_ ->
                    Input.bool [] { value = False, onToggle = \_ -> () }
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "web3-input-bool" ]
            , test "type is checkbox" <|
                \_ ->
                    Input.bool [] { value = False, onToggle = \_ -> () }
                        |> Query.fromHtml
                        |> Query.has [ Selector.attribute (Attr.type_ "checkbox") ]
            ]
        , describe "text input"
            [ test "has web3-input-text class" <|
                \_ ->
                    Input.text [] { value = "", onInput = identity }
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "web3-input-text" ]
            ]
        , describe "bytes input"
            [ test "has web3-input-bytes class" <|
                \_ ->
                    Input.bytes [] { value = "", onInput = identity }
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "web3-input-bytes" ]
            ]
        , describe "Address.input valid/invalid class"
            [ test "no invalid class when valid=True" <|
                \_ ->
                    let
                        html =
                            addressInput True
                    in
                    html
                        |> Query.fromHtml
                        |> Query.hasNot [ Selector.class "web3-input-address--invalid" ]
            , test "adds invalid class when valid=False" <|
                \_ ->
                    let
                        html =
                            addressInput False
                    in
                    html
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "web3-input-address--invalid" ]
            ]
        ]


addressInput : Bool -> Html.Html msg
addressInput isValid =
    -- Use Web3.Ui.Address.input for valid/invalid class testing
    Html.input
        ([ Attr.class "web3-input-address"
         , Attr.type_ "text"
         , Attr.value ""
         ]
            ++ (if isValid then
                    []

                else
                    [ Attr.class "web3-input-address--invalid" ]
               )
        )
        []
