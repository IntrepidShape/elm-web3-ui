module Web3.Ui.ChainGate exposing (chainGate)

{-| Render content only when the wallet is on the expected chain.

A common pattern in every dapp: show the actual UI when connected to the right
network, show a prompt to switch otherwise. This wraps that pattern so it does
not have to be repeated in every view.

    Web3.Ui.ChainGate.chainGate model.wallet
        (Chain.chainId Chain.pulsechain)
        (Html.text "Please switch to PulseChain")
        actualContent

@docs chainGate

-}

import Html exposing (Html)
import Web3.Types as T
import Web3.Wallet as Wallet


{-| Render `contentView` when the wallet is `Connected` on `expectedChain`.
Render `wrongChainView` for every other state (disconnected, wrong chain,
read-only, connecting, error).

-}
chainGate :
    Wallet.State
    -> T.ChainId
    -> Html msg
    -> Html msg
    -> Html msg
chainGate state expectedChain wrongChainView contentView =
    case state of
        Wallet.Connected info ->
            if T.chainIdToInt info.chainId == T.chainIdToInt expectedChain then
                contentView

            else
                wrongChainView

        _ ->
            wrongChainView
