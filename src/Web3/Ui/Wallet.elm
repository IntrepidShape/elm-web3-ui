module Web3.Ui.Wallet exposing
    ( connectButton
    , walletPicker
    , viewState
    , chainBadge
    )

{-| Wallet connection UI components.

All functions accept `List (Html.Attribute msg)` as the first argument — merged
onto the root element. Pass `[]` for no extra attributes.

No default styles — every element has a semantic class name. Supply your own CSS.

    -- Basic connect/disconnect button:
    Web3.Ui.Wallet.connectButton []
        { onConnect = ConnectWallet, onDisconnect = DisconnectWallet }
        model.wallet

    -- Full wallet UI handling all states:
    Web3.Ui.Wallet.viewState []
        { onConnect = ConnectWallet
        , onSwitchChain = SwitchChain
        , onDisconnect = DisconnectWallet
        , knownChains = [ Chain.pulsechain, Chain.ethereum ]
        }
        model.wallet

@docs connectButton, walletPicker, viewState, chainBadge

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Web3.Chain as Chain exposing (Chain)
import Web3.Types as T
import Web3.Ui.Address as Address
import Web3.Wallet as Wallet


{-| A connect/disconnect button. Shows "Connect" in disconnected/error states
and "Disconnect" in connected states.

CSS classes: `web3-connect-btn`, `web3-disconnect-btn`

-}
connectButton :
    List (Html.Attribute msg)
    -> { onConnect : msg, onDisconnect : msg }
    -> Wallet.State
    -> Html msg
connectButton attrs callbacks state =
    case state of
        Wallet.Connected _ ->
            Html.button
                (Attr.class "web3-disconnect-btn" :: Events.onClick callbacks.onDisconnect :: attrs)
                [ Html.text "Disconnect" ]

        Wallet.WrongChain _ _ ->
            Html.button
                (Attr.class "web3-disconnect-btn" :: Events.onClick callbacks.onDisconnect :: attrs)
                [ Html.text "Disconnect" ]

        Wallet.ReadOnly ->
            Html.button
                (Attr.class "web3-connect-btn" :: Events.onClick callbacks.onConnect :: attrs)
                [ Html.text "Connect" ]

        Wallet.Connecting ->
            Html.button
                (Attr.class "web3-connect-btn" :: Attr.disabled True :: attrs)
                [ Html.text "Connecting…" ]

        Wallet.Disconnected ->
            Html.button
                (Attr.class "web3-connect-btn" :: Events.onClick callbacks.onConnect :: attrs)
                [ Html.text "Connect" ]

        Wallet.Error _ ->
            Html.button
                (Attr.class "web3-connect-btn" :: Events.onClick callbacks.onConnect :: attrs)
                [ Html.text "Connect" ]


{-| A list of EIP-6963 discovered wallets for the user to pick from.

Each wallet renders as a button with the wallet icon and name. Pass the RDNS of
the currently active wallet as `selected` to highlight it.

CSS classes: `web3-wallet-picker` (container), `web3-wallet-option` (each item),
`web3-wallet-option--selected` (active wallet)

-}
walletPicker :
    List (Html.Attribute msg)
    -> { onSelect : String -> msg, selected : Maybe String }
    -> List Wallet.WalletProvider
    -> Html msg
walletPicker attrs opts providers =
    Html.div
        (Attr.class "web3-wallet-picker" :: attrs)
        (List.map (viewWalletOption opts) providers)


viewWalletOption : { onSelect : String -> msg, selected : Maybe String } -> Wallet.WalletProvider -> Html msg
viewWalletOption opts provider =
    let
        selectedClass =
            if opts.selected == Just provider.rdns then
                [ Attr.class "web3-wallet-option--selected" ]

            else
                []
    in
    Html.button
        ([ Attr.class "web3-wallet-option"
         , Events.onClick (opts.onSelect provider.rdns)
         ]
            ++ selectedClass
        )
        [ Html.img [ Attr.src provider.icon, Attr.alt provider.name ] []
        , Html.span [] [ Html.text provider.name ]
        ]


{-| Full wallet UI — handles all `Wallet.State` variants with appropriate labels
and actions.

Pass `knownChains` so the `WrongChain` branch can display the target network name.

CSS class: `web3-wallet-state`

-}
viewState :
    List (Html.Attribute msg)
    -> { onConnect : msg, onSwitchChain : msg, onDisconnect : msg, knownChains : List Chain }
    -> Wallet.State
    -> Html msg
viewState attrs callbacks state =
    Html.div
        (Attr.class "web3-wallet-state" :: attrs)
        (case state of
            Wallet.Disconnected ->
                [ connectButton [] { onConnect = callbacks.onConnect, onDisconnect = callbacks.onDisconnect } state
                ]

            Wallet.ReadOnly ->
                [ Html.span [] [ Html.text "Read-only mode" ]
                , connectButton [] { onConnect = callbacks.onConnect, onDisconnect = callbacks.onDisconnect } state
                ]

            Wallet.Connecting ->
                [ Html.span [] [ Html.text "Connecting…" ] ]

            Wallet.Connected info ->
                [ Html.span [] [ Html.text (Address.short info.address) ]
                , connectButton [] { onConnect = callbacks.onConnect, onDisconnect = callbacks.onDisconnect } state
                ]

            Wallet.WrongChain _ expectedChainId ->
                let
                    targetName =
                        lookupChainName callbacks.knownChains expectedChainId
                in
                [ Html.span [] [ Html.text ("Wrong network — switch to " ++ targetName) ]
                , Html.button
                    [ Attr.class "web3-action-btn", Events.onClick callbacks.onSwitchChain ]
                    [ Html.text ("Switch to " ++ targetName) ]
                ]

            Wallet.Error err ->
                [ Html.span [] [ Html.text ("Error: " ++ err) ]
                , connectButton [] { onConnect = callbacks.onConnect, onDisconnect = callbacks.onDisconnect } state
                ]
        )


{-| Displays the connected chain name, looked up from the supplied chain list.
Falls back to "Unknown Chain" if not found.

Shows "Wrong Chain" when in `WrongChain` state.
Shows "Read-only" when in `ReadOnly` state.
Shows "—" when connecting, disconnected, or in error state.

CSS class: `web3-chain-badge`

-}
chainBadge :
    List (Html.Attribute msg)
    -> List Chain
    -> Wallet.State
    -> Html msg
chainBadge attrs knownChains state =
    let
        label =
            case state of
                Wallet.Connected info ->
                    lookupChainName knownChains info.chainId

                Wallet.WrongChain _ _ ->
                    "Wrong Chain"

                Wallet.ReadOnly ->
                    "Read-only"

                Wallet.Connecting ->
                    "—"

                Wallet.Disconnected ->
                    "—"

                Wallet.Error _ ->
                    "—"
    in
    Html.span
        (Attr.class "web3-chain-badge" :: attrs)
        [ Html.text label ]


lookupChainName : List Chain -> T.ChainId -> String
lookupChainName chains cid =
    chains
        |> List.filter (\c -> T.chainIdToInt (Chain.chainId c) == T.chainIdToInt cid)
        |> List.head
        |> Maybe.map Chain.name
        |> Maybe.withDefault "Unknown Chain"
