module Web3.Ui.Form exposing
    ( Validated, succeed, fail, fromMaybe
    , andMap, map, map2
    , errors, isValid, errorList
    )

{-| Accumulating form validation — combine per-field results into one
`Validated args` where **every** problem is collected, not just the first.
The applicative sibling of the per-field validation the input atoms
(`Web3.Ui.Input`, `Web3.Ui.Amount`) already do.

    type alias SendForm =
        { to : T.Address, amount : BigInt }

    validated : Model -> Validated SendForm
    validated model =
        succeed SendForm
            |> andMap (fromMaybe "Recipient is not a valid address" model.parsedTo)
            |> andMap (fromMaybe "Amount is not a valid number" model.parsedAmount)

    -- in view: disable the button and show ALL the problems
    button [ disabled (not (Form.isValid v)) ] …
    Form.errorList [] v

`Result` short-circuits on the first `Err`; forms shouldn't — a user fixing
a three-field form one error at a time is the classic papercut this type
removes.

CSS classes: `web3-form-errors`, `web3-form-errors__item`.

@docs Validated, succeed, fail, fromMaybe
@docs andMap, map, map2
@docs errors, isValid, errorList

-}

import Html exposing (Html)
import Html.Attributes as Attr


{-| A value that is either fully valid or carries every accumulated
problem.
-}
type alias Validated a =
    Result (List String) a


{-| Start a pipeline with the record constructor. -}
succeed : a -> Validated a
succeed =
    Ok


{-| A single failure. -}
fail : String -> Validated a
fail message =
    Err [ message ]


{-| Lift a parsed field: `Nothing` becomes the given error. The natural
bridge from `T.address` / `BigInt.fromString` / `Units.parseUnits`.
-}
fromMaybe : String -> Maybe a -> Validated a
fromMaybe message maybe =
    Result.fromMaybe [ message ] maybe


{-| Apply the next field, **accumulating** errors from both sides. -}
andMap : Validated a -> Validated (a -> b) -> Validated b
andMap fieldV fnV =
    case ( fnV, fieldV ) of
        ( Ok fn, Ok a ) ->
            Ok (fn a)

        ( Err es1, Err es2 ) ->
            Err (es1 ++ es2)

        ( Err es, Ok _ ) ->
            Err es

        ( Ok _, Err es ) ->
            Err es


{-| -}
map : (a -> b) -> Validated a -> Validated b
map =
    Result.map


{-| -}
map2 : (a -> b -> c) -> Validated a -> Validated b -> Validated c
map2 fn a b =
    succeed fn
        |> andMap a
        |> andMap b


{-| All accumulated problems (empty when valid). -}
errors : Validated a -> List String
errors v =
    case v of
        Ok _ ->
            []

        Err es ->
            es


{-| -}
isValid : Validated a -> Bool
isValid v =
    case v of
        Ok _ ->
            True

        Err _ ->
            False


{-| Render the problems as a list (`role="alert"`), or nothing when valid. -}
errorList : List (Html.Attribute msg) -> Validated a -> Html msg
errorList attrs v =
    case errors v of
        [] ->
            Html.text ""

        es ->
            Html.ul
                (Attr.class "web3-form-errors"
                    :: Attr.attribute "role" "alert"
                    :: attrs
                )
                (List.map
                    (\e -> Html.li [ Attr.class "web3-form-errors__item" ] [ Html.text e ])
                    es
                )
