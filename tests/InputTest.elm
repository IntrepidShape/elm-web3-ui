module InputTest exposing (suite)

import Expect
import Html.Attributes as Attr
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import Web3.Ui.Address as Address
import Web3.Ui.Input as Input


suite : Test
suite =
    describe "Web3.Ui.Input"
        [ describe "address input"
            [ test "has web3-input-address class" <|
                \_ ->
                    Input.address [] { value = "", onInput = identity, valid = True }
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "web3-input-address" ]
            , test "extra attrs are applied" <|
                \_ ->
                    Input.address [ Attr.id "my-input" ] { value = "", onInput = identity, valid = True }
                        |> Query.fromHtml
                        |> Query.has [ Selector.id "my-input" ]
            , test "value is reflected" <|
                \_ ->
                    Input.address [] { value = "0xabc", onInput = identity, valid = True }
                        |> Query.fromHtml
                        |> Query.has [ Selector.attribute (Attr.value "0xabc") ]
            , test "no invalid class when valid=True" <|
                \_ ->
                    Input.address [] { value = "", onInput = identity, valid = True }
                        |> Query.fromHtml
                        |> Query.hasNot [ Selector.class "web3-input-address--invalid" ]
            , test "adds invalid class when valid=False" <|
                \_ ->
                    Input.address [] { value = "", onInput = identity, valid = False }
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "web3-input-address--invalid" ]
            ]
        , describe "bigInt input"
            [ test "has web3-input-bigint class" <|
                \_ ->
                    Input.bigInt [] { value = "", onInput = identity, valid = True }
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "web3-input-bigint" ]
            , test "no invalid class when valid=True" <|
                \_ ->
                    Input.bigInt [] { value = "", onInput = identity, valid = True }
                        |> Query.fromHtml
                        |> Query.hasNot [ Selector.class "web3-input-bigint--invalid" ]
            , test "adds invalid class when valid=False" <|
                \_ ->
                    Input.bigInt [] { value = "", onInput = identity, valid = False }
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "web3-input-bigint--invalid" ]
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
                    Input.bytes [] { value = "", onInput = identity, valid = True }
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "web3-input-bytes" ]
            , test "no invalid class when valid=True" <|
                \_ ->
                    Input.bytes [] { value = "", onInput = identity, valid = True }
                        |> Query.fromHtml
                        |> Query.hasNot [ Selector.class "web3-input-bytes--invalid" ]
            , test "adds invalid class when valid=False" <|
                \_ ->
                    Input.bytes [] { value = "", onInput = identity, valid = False }
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "web3-input-bytes--invalid" ]
            ]
        , describe "Address.input valid/invalid class"
            [ test "no invalid class when valid=True" <|
                \_ ->
                    Address.input [] { value = "", onInput = identity, valid = True }
                        |> Query.fromHtml
                        |> Query.hasNot [ Selector.class "web3-input-address--invalid" ]
            , test "adds invalid class when valid=False" <|
                \_ ->
                    Address.input [] { value = "", onInput = identity, valid = False }
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "web3-input-address--invalid" ]
            ]
        ]
