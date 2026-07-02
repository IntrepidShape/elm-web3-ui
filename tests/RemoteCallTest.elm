module RemoteCallTest exposing (suite)

{-| The RemoteCall id-guard — the same no-cross-request-confusion rule
elm-web3 proves for its Sign machine, applied to reads.
-}

import Expect
import Fuzz
import Test exposing (..)
import Web3.Ui.RemoteCall as RC exposing (RemoteCall(..))


suite : Test
suite =
    describe "Web3.Ui.RemoteCall"
        [ fuzz2 Fuzz.string Fuzz.string "resolve with a non-matching id is a no-op" <|
            \pendingId otherId ->
                if pendingId == otherId then
                    Expect.pass

                else
                    Loading pendingId
                        |> RC.resolve otherId (Ok 42)
                        |> Expect.equal (Loading pendingId)
        , fuzz Fuzz.string "resolve with the matching id lands the value" <|
            \id ->
                Loading id
                    |> RC.resolve id (Ok 42)
                    |> Expect.equal (Ready 42)
        , fuzz Fuzz.string "resolve with the matching id lands the failure" <|
            \id ->
                Loading id
                    |> RC.resolve id (Err "revert")
                    |> Expect.equal (Failed "revert")
        , fuzz Fuzz.string "resolve never touches non-Loading states" <|
            \anyId ->
                [ NotAsked, Ready 1, Failed "x" ]
                    |> List.map (RC.resolve anyId (Ok 2))
                    |> Expect.equal [ NotAsked, Ready 1, Failed "x" ]
        , fuzz2 Fuzz.string Fuzz.string "a new request supersedes: only the NEW id can resolve" <|
            \oldId newId ->
                if oldId == newId then
                    Expect.pass

                else
                    Loading oldId
                        |> RC.request newId
                        |> RC.resolve oldId (Ok 1)
                        |> Expect.equal (Loading newId)
        , test "map only transforms Ready" <|
            \_ ->
                [ RC.map ((+) 1) (Ready 1), RC.map ((+) 1) (Failed "x") ]
                    |> Expect.equal [ Ready 2, Failed "x" ]
        ]
