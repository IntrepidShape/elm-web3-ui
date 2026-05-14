module Web3.Ui.AbiInput exposing
    ( view, Config
    , Field, field, fieldName, fieldSolType, fieldChildren
    , Value, valueString, valueList, valueTuple
    , stringValue, listValues, tupleValues
    , initFor, parse, parseSlot
    )

{-| Render a typed input for any Solidity argument shape — `address`,
`uint*`, `int*`, `bool`, `string`, `bytes`, `bytesN`, `T[]`, `T[N]`, and
`tuple` (recursively).

The component is **stateless**, like every other primitive in this library.
The caller owns a `Value` per ABI argument and passes it back in on every
render. Validation feedback is wired the same way (`error : Maybe String`).

A complete write flow looks like this:

    -- in your Model
    type alias Model =
        { fooArg : Web3.Ui.AbiInput.Value
        , fooError : Maybe String
        , …
        }

    -- in init
    init =
        { fooArg = Web3.Ui.AbiInput.initFor fooField, … }

    -- in your view
    Web3.Ui.AbiInput.view []
        { field = fooField
        , value = model.fooArg
        , onChange = FooArgChanged
        , error = model.fooError
        }

    -- when the user clicks Send, parse to JSON
    case Web3.Ui.AbiInput.parse fooField model.fooArg of
        Ok jsonValue -> -- pass to Web3.Contract.Send
        Err msg      -> ( { model | fooError = Just msg }, Cmd.none )

@docs view, Config
@docs Field, field, fieldName, fieldSolType, fieldChildren
@docs Value, valueString, valueList, valueTuple
@docs stringValue, listValues, tupleValues
@docs initFor, parse, parseSlot

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Encode as E
import Web3.Abi.Calldata as Calldata
import Web3.Abi.Encode as AbiEncode
import Web3.BigInt as BigInt
import Web3.Types as T
import Web3.Ui.Input as Input



-- FIELD ---------------------------------------------------------------------


{-| Description of one ABI argument: name, Solidity type string, and (for
tuples) the recursive list of child fields.
-}
type Field
    = Field
        { name : String
        , solType : String
        , children : List Field
        }


{-| Construct a `Field`. -}
field : { name : String, solType : String, children : List Field } -> Field
field r =
    Field r


{-| Extract the field's display name. -}
fieldName : Field -> String
fieldName (Field f) =
    f.name


{-| Extract the field's Solidity type string (e.g. `"uint256"`, `"address[]"`). -}
fieldSolType : Field -> String
fieldSolType (Field f) =
    f.solType


{-| Extract a field's recursive children (tuple fields), empty otherwise. -}
fieldChildren : Field -> List Field
fieldChildren (Field f) =
    f.children



-- VALUE ---------------------------------------------------------------------


{-| Opaque user-input value for an ABI argument of any shape.

Scalars carry their raw input buffer (a `String`); arrays carry a list of
inner values; tuples carry an ordered list of field values matching their
`Field.children`.
-}
type Value
    = VString String
    | VList (List Value)
    | VTuple (List Value)


{-| Construct a scalar value from a raw input buffer. -}
valueString : String -> Value
valueString =
    VString


{-| Construct a list value (for `T[]` / `T[N]` arguments). -}
valueList : List Value -> Value
valueList =
    VList


{-| Construct a tuple value. -}
valueTuple : List Value -> Value
valueTuple =
    VTuple


{-| Extract the raw input buffer from a scalar value, if it is one. -}
stringValue : Value -> Maybe String
stringValue v =
    case v of
        VString s ->
            Just s

        _ ->
            Nothing


{-| Extract array elements, if this is a list value. -}
listValues : Value -> Maybe (List Value)
listValues v =
    case v of
        VList xs ->
            Just xs

        _ ->
            Nothing


{-| Extract tuple field values, if this is a tuple value. -}
tupleValues : Value -> Maybe (List Value)
tupleValues v =
    case v of
        VTuple xs ->
            Just xs

        _ ->
            Nothing



-- INIT ----------------------------------------------------------------------


{-| Build the empty `Value` matching a `Field`'s shape.

For scalars, returns `valueString ""`. For dynamic arrays, an empty list.
For fixed arrays, a list of N empty inner values. For tuples, a tuple of
empty values matching the field's children.
-}
initFor : Field -> Value
initFor (Field f) =
    case classify f.solType of
        Scalar _ ->
            VString ""

        DynArray _ ->
            VList []

        FixedArray inner n ->
            VList (List.repeat n (initFor (innerField inner f.children)))

        Tuple_ ->
            VTuple (List.map initFor f.children)



-- PARSE ---------------------------------------------------------------------


{-| Parse a `Value` against its `Field` into a `Json.Encode.Value` ready for
the JS port. Returns `Err message` on the first validation failure.
-}
parse : Field -> Value -> Result String E.Value
parse (Field f) value =
    case classify f.solType of
        Scalar kind ->
            case value of
                VString raw ->
                    parseScalar kind raw

                _ ->
                    Err ("Expected scalar for " ++ f.solType)

        DynArray inner ->
            case value of
                VList xs ->
                    parseList (innerField inner f.children) xs

                _ ->
                    Err ("Expected list for " ++ f.solType)

        FixedArray inner n ->
            case value of
                VList xs ->
                    if List.length xs == n then
                        parseList (innerField inner f.children) xs

                    else
                        Err
                            ("Expected "
                                ++ String.fromInt n
                                ++ " elements for "
                                ++ f.solType
                                ++ ", got "
                                ++ String.fromInt (List.length xs)
                            )

                _ ->
                    Err ("Expected list for " ++ f.solType)

        Tuple_ ->
            case value of
                VTuple xs ->
                    parseTuple f.children xs

                _ ->
                    Err "Expected tuple"


parseScalar : ScalarKind -> String -> Result String E.Value
parseScalar kind raw =
    let
        trimmed =
            String.trim raw
    in
    case kind of
        AddressK ->
            case T.address trimmed of
                Just a ->
                    Ok (AbiEncode.address a)

                Nothing ->
                    Err ("Invalid address: " ++ trimmed)

        UintK ->
            case BigInt.fromString trimmed of
                Just b ->
                    Ok (AbiEncode.uint256 b)

                Nothing ->
                    Err ("Invalid uint: " ++ trimmed)

        IntK ->
            case BigInt.fromString trimmed of
                Just b ->
                    Ok (AbiEncode.int256 b)

                Nothing ->
                    Err ("Invalid int: " ++ trimmed)

        BoolK ->
            case String.toLower trimmed of
                "true" ->
                    Ok (AbiEncode.bool True)

                "false" ->
                    Ok (AbiEncode.bool False)

                "" ->
                    Ok (AbiEncode.bool False)

                _ ->
                    Err ("Expected true/false, got: " ++ trimmed)

        StringK ->
            Ok (AbiEncode.string raw)

        BytesK ->
            if isHex trimmed then
                Ok (AbiEncode.bytes trimmed)

            else
                Err ("Expected 0x… hex, got: " ++ trimmed)

        FixedBytesK n ->
            -- 0x + 2n hex chars
            if isHex trimmed && String.length trimmed == 2 + 2 * n then
                Ok (AbiEncode.bytesN trimmed)

            else
                Err
                    ("Expected 0x followed by "
                        ++ String.fromInt (2 * n)
                        ++ " hex chars for bytes"
                        ++ String.fromInt n
                    )


parseList : Field -> List Value -> Result String E.Value
parseList innerF xs =
    let
        step v acc =
            case acc of
                Err e ->
                    Err e

                Ok jvs ->
                    case parse innerF v of
                        Err e ->
                            Err e

                        Ok jv ->
                            Ok (jv :: jvs)
    in
    List.foldr step (Ok []) xs
        |> Result.map (\jvs -> E.list identity jvs)


parseTuple : List Field -> List Value -> Result String E.Value
parseTuple fields values =
    let
        zipped =
            List.map2 Tuple.pair fields values

        step ( f, v ) acc =
            case acc of
                Err e ->
                    Err e

                Ok jvs ->
                    case parse f v of
                        Err e ->
                            Err e

                        Ok jv ->
                            Ok (jv :: jvs)
    in
    if List.length fields /= List.length values then
        Err
            ("Tuple field count mismatch: expected "
                ++ String.fromInt (List.length fields)
                ++ ", got "
                ++ String.fromInt (List.length values)
            )

    else
        List.foldr step (Ok []) zipped
            |> Result.map (\jvs -> E.list identity jvs)



-- PARSE → CALLDATA SLOT -----------------------------------------------------


{-| Parse a `Value` against its `Field` into a [`Calldata.Slot`](Web3-Abi-Calldata#Slot).

This is the canonical parser for the pure-Elm calldata path — codegen tools
emit `parseSlot` calls and feed the resulting slots to
[`Web3.Abi.Calldata.calldata`](Web3-Abi-Calldata#calldata) plus a baked
selector, producing complete `"0x…"` calldata with zero JavaScript
involvement.

Use `parseSlot` when building `readCallRaw` / `writeCallRaw`; use the
existing [`parse`](#parse) when you need the legacy method+args port shape.
-}
parseSlot : Field -> Value -> Result String Calldata.Slot
parseSlot (Field f) value =
    case classify f.solType of
        Scalar kind ->
            case value of
                VString raw ->
                    parseSlotScalar kind raw

                _ ->
                    Err ("Expected scalar for " ++ f.solType)

        DynArray inner ->
            case value of
                VList xs ->
                    parseSlotList (innerField inner f.children) xs

                _ ->
                    Err ("Expected list for " ++ f.solType)

        FixedArray inner n ->
            case value of
                VList xs ->
                    if List.length xs == n then
                        parseSlotList (innerField inner f.children) xs

                    else
                        Err
                            ("Expected "
                                ++ String.fromInt n
                                ++ " elements for "
                                ++ f.solType
                                ++ ", got "
                                ++ String.fromInt (List.length xs)
                            )

                _ ->
                    Err ("Expected list for " ++ f.solType)

        Tuple_ ->
            case value of
                VTuple xs ->
                    parseSlotTuple f.children xs

                _ ->
                    Err "Expected tuple"


parseSlotScalar : ScalarKind -> String -> Result String Calldata.Slot
parseSlotScalar kind raw =
    let
        trimmed =
            String.trim raw
    in
    case kind of
        AddressK ->
            if String.isEmpty trimmed then
                Err "address required"

            else
                case T.address trimmed of
                    Just a ->
                        Ok (Calldata.address a)

                    Nothing ->
                        Err ("not a 20-byte hex address: " ++ trimmed)

        UintK ->
            if String.isEmpty trimmed then
                Err "uint required"

            else
                case BigInt.fromString trimmed of
                    Just b ->
                        Ok (Calldata.uint256 b)

                    Nothing ->
                        Err ("not an integer: " ++ trimmed)

        IntK ->
            if String.isEmpty trimmed then
                Err "int required"

            else
                case BigInt.fromString trimmed of
                    Just b ->
                        Ok (Calldata.int256 b)

                    Nothing ->
                        Err ("not an integer: " ++ trimmed)

        BoolK ->
            case String.toLower trimmed of
                "true" ->
                    Ok (Calldata.bool True)

                "false" ->
                    Ok (Calldata.bool False)

                "" ->
                    Ok (Calldata.bool False)

                _ ->
                    Err ("expected true/false, got: " ++ trimmed)

        StringK ->
            Ok (Calldata.string raw)

        BytesK ->
            if String.isEmpty trimmed then
                Err "hex bytes required"

            else if isHex trimmed then
                Ok (Calldata.bytes trimmed)

            else
                Err ("not 0x-prefixed hex: " ++ trimmed)

        FixedBytesK n ->
            if String.isEmpty trimmed then
                Err ("bytes" ++ String.fromInt n ++ " required")

            else if isHex trimmed && String.length trimmed == 2 + 2 * n then
                Ok (Calldata.bytesN n trimmed)

            else
                Err
                    ("Expected 0x followed by "
                        ++ String.fromInt (2 * n)
                        ++ " hex chars for bytes"
                        ++ String.fromInt n
                    )


parseSlotList : Field -> List Value -> Result String Calldata.Slot
parseSlotList innerF xs =
    let
        innerEncoder v =
            parseSlot innerF v

        step v acc =
            case acc of
                Err e ->
                    Err e

                Ok slots ->
                    case innerEncoder v of
                        Err e ->
                            Err e

                        Ok s ->
                            Ok (s :: slots)
    in
    List.foldr step (Ok []) xs
        |> Result.map (Calldata.list identity)


parseSlotTuple : List Field -> List Value -> Result String Calldata.Slot
parseSlotTuple fields values =
    if List.length fields /= List.length values then
        Err
            ("Tuple field count mismatch: expected "
                ++ String.fromInt (List.length fields)
                ++ ", got "
                ++ String.fromInt (List.length values)
            )

    else
        let
            zipped =
                List.map2 Tuple.pair fields values

            step ( f, v ) acc =
                case acc of
                    Err e ->
                        Err e

                    Ok slots ->
                        case parseSlot f v of
                            Err e ->
                                Err e

                            Ok s ->
                                Ok (s :: slots)
        in
        List.foldr step (Ok []) zipped
            |> Result.map Calldata.tuple



-- VIEW ----------------------------------------------------------------------


{-| Configuration for `view`.
-}
type alias Config msg =
    { field : Field
    , value : Value
    , onChange : Value -> msg
    , error : Maybe String
    }


{-| Render the input(s) for one ABI argument.

Composes the existing `Web3.Ui.Input.*` primitives, recursing into arrays
and tuples. Class names follow the BEM convention `web3-abi-input` /
`web3-abi-input__label` / `web3-abi-input__error` / `web3-abi-input__list`
/ `web3-abi-input__tuple`.
-}
view : List (Html.Attribute msg) -> Config msg -> Html msg
view attrs opts =
    let
        (Field f) =
            opts.field

        invalidClass =
            case opts.error of
                Just _ ->
                    [ Attr.class "web3-abi-input--invalid" ]

                Nothing ->
                    []

        labelHtml =
            if String.isEmpty f.name then
                Html.text ""

            else
                Html.label [ Attr.class "web3-abi-input__label" ]
                    [ Html.text f.name
                    , Html.span [ Attr.class "web3-abi-input__type" ]
                        [ Html.text (" : " ++ f.solType) ]
                    ]

        errorHtml =
            case opts.error of
                Just msg ->
                    Html.div [ Attr.class "web3-abi-input__error" ]
                        [ Html.text msg ]

                Nothing ->
                    Html.text ""
    in
    Html.div
        ([ Attr.class "web3-abi-input" ] ++ invalidClass ++ attrs)
        [ labelHtml
        , renderBody opts
        , errorHtml
        ]


renderBody : Config msg -> Html msg
renderBody opts =
    let
        (Field f) =
            opts.field
    in
    case classify f.solType of
        Scalar kind ->
            renderScalar kind opts

        DynArray inner ->
            renderArray (innerField inner f.children) True opts

        FixedArray inner _ ->
            renderArray (innerField inner f.children) False opts

        Tuple_ ->
            renderTuple f.children opts


renderScalar : ScalarKind -> Config msg -> Html msg
renderScalar kind opts =
    let
        raw =
            stringValue opts.value |> Maybe.withDefault ""

        valid =
            opts.error == Nothing

        toMsg s =
            opts.onChange (VString s)
    in
    case kind of
        AddressK ->
            Input.address [] { value = raw, onInput = toMsg, valid = valid }

        UintK ->
            Input.bigInt [] { value = raw, onInput = toMsg, valid = valid }

        IntK ->
            Input.bigInt [] { value = raw, onInput = toMsg, valid = valid }

        BoolK ->
            Html.div [ Attr.class "web3-abi-input__bool" ]
                [ Input.bool []
                    { value = raw == "true"
                    , onToggle =
                        \b ->
                            opts.onChange
                                (VString
                                    (if b then
                                        "true"

                                     else
                                        "false"
                                    )
                                )
                    }
                , Html.span [ Attr.class "web3-abi-input__bool-label" ]
                    [ Html.text
                        (if raw == "true" then
                            "true"

                         else
                            "false"
                        )
                    ]
                ]

        StringK ->
            Input.text [] { value = raw, onInput = toMsg }

        BytesK ->
            Input.bytes [] { value = raw, onInput = toMsg, valid = valid }

        FixedBytesK _ ->
            Input.bytes [] { value = raw, onInput = toMsg, valid = valid }


renderArray : Field -> Bool -> Config msg -> Html msg
renderArray innerF dynamic opts =
    let
        xs =
            listValues opts.value |> Maybe.withDefault []

        update i newInner =
            opts.onChange
                (VList
                    (List.indexedMap
                        (\j v ->
                            if i == j then
                                newInner

                             else
                                v
                        )
                        xs
                    )
                )

        remove i =
            opts.onChange
                (VList
                    (List.indexedMap Tuple.pair xs
                        |> List.filter (\( j, _ ) -> j /= i)
                        |> List.map Tuple.second
                    )
                )

        add =
            opts.onChange (VList (xs ++ [ initFor innerF ]))

        rowFor i innerValue =
            Html.div [ Attr.class "web3-abi-input__list-row" ]
                [ view []
                    { field = innerF
                    , value = innerValue
                    , onChange = update i
                    , error = Nothing
                    }
                , if dynamic then
                    Html.button
                        [ Attr.class "web3-abi-input__list-remove"
                        , Attr.type_ "button"
                        , Events.onClick (remove i)
                        ]
                        [ Html.text "×" ]

                  else
                    Html.text ""
                ]

        addButton =
            if dynamic then
                Html.button
                    [ Attr.class "web3-abi-input__list-add"
                    , Attr.type_ "button"
                    , Events.onClick add
                    ]
                    [ Html.text "+ add" ]

            else
                Html.text ""
    in
    Html.div [ Attr.class "web3-abi-input__list" ]
        (List.indexedMap rowFor xs ++ [ addButton ])


renderTuple : List Field -> Config msg -> Html msg
renderTuple fields opts =
    let
        values =
            tupleValues opts.value |> Maybe.withDefault (List.map initFor fields)

        update i newInner =
            opts.onChange
                (VTuple
                    (List.indexedMap
                        (\j v ->
                            if i == j then
                                newInner

                             else
                                v
                        )
                        values
                    )
                )

        rowFor i ( f, v ) =
            view []
                { field = f
                , value = v
                , onChange = update i
                , error = Nothing
                }
    in
    Html.div [ Attr.class "web3-abi-input__tuple" ]
        (List.indexedMap rowFor (List.map2 Tuple.pair fields values))



-- INTERNAL : CLASSIFICATION ------------------------------------------------


type SolKind
    = Scalar ScalarKind
    | DynArray String
    | FixedArray String Int
    | Tuple_


type ScalarKind
    = AddressK
    | UintK
    | IntK
    | BoolK
    | StringK
    | BytesK
    | FixedBytesK Int


classify : String -> SolKind
classify raw =
    let
        s =
            String.trim raw
    in
    if String.endsWith "]" s then
        case String.indexes "[" s |> List.reverse |> List.head of
            Just i ->
                let
                    inner =
                        String.left i s

                    bracket =
                        String.dropLeft i s
                in
                if bracket == "[]" then
                    DynArray inner

                else
                    case
                        bracket
                            |> String.dropLeft 1
                            |> String.dropRight 1
                            |> String.toInt
                    of
                        Just n ->
                            FixedArray inner n

                        Nothing ->
                            DynArray inner

            Nothing ->
                Scalar StringK

    else if s == "address" then
        Scalar AddressK

    else if s == "bool" then
        Scalar BoolK

    else if s == "string" then
        Scalar StringK

    else if s == "bytes" then
        Scalar BytesK

    else if String.startsWith "uint" s then
        Scalar UintK

    else if String.startsWith "int" s then
        Scalar IntK

    else if String.startsWith "bytes" s then
        case String.dropLeft 5 s |> String.toInt of
            Just n ->
                Scalar (FixedBytesK n)

            Nothing ->
                Scalar BytesK

    else if String.startsWith "tuple" s then
        Tuple_

    else
        -- Unknown — render as string for safety; user sees `solType` label and
        -- knows what to type.
        Scalar StringK


innerField : String -> List Field -> Field
innerField inner children =
    Field { name = "", solType = inner, children = children }


isHex : String -> Bool
isHex s =
    String.startsWith "0x" s
        && (String.dropLeft 2 s
                |> String.toList
                |> List.all isHexChar
           )


isHexChar : Char -> Bool
isHexChar c =
    Char.isDigit c
        || (c >= 'a' && c <= 'f')
        || (c >= 'A' && c <= 'F')
