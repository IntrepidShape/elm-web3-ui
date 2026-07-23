module Web3.Ui.RelativeTime exposing (view, format)

{-| Compact relative-time string for transaction ages, position open dates,
graduation timestamps -- anywhere a dapp shows "how long ago".

    Web3.Ui.RelativeTime.view { nowSec = model.nowSec, atSec = tx.timestamp }
    --> "2m ago" / "3h ago" / "1d ago" / "Apr 12"

For non-Html callers (e.g., row labels):

    Web3.Ui.RelativeTime.format { nowSec = model.nowSec, atSec = tx.timestamp }
    --> "2m ago"

CSS class on the rendered span: `web3-relativetime`. The full RFC-style
timestamp (ISO-like seconds) is set as a `title` attribute for hover.

@docs view, format

-}

import Html exposing (Html)
import Html.Attributes as Attr


{-| Render the relative time string inside a span with a `title` showing the
absolute Unix seconds for accessibility / hover. -}
view : { nowSec : Int, atSec : Int } -> Html msg
view opts =
    Html.span
        [ Attr.class "web3-relativetime"
        , Attr.title (String.fromInt opts.atSec ++ "s")
        ]
        [ Html.text (format opts) ]


{-| Pure helper: convert a Unix-seconds delta into a human string.

Buckets:

  - < 60s  -> "Ns ago"
  - < 60m  -> "Nm ago"
  - < 24h  -> "Nh ago"
  - < 30d  -> "Nd ago"
  - else   -> "Nw ago" (weeks; coarse beyond a month)

Negative deltas (future) render as "in Ns" / "in Nm" / etc.
-}
format : { nowSec : Int, atSec : Int } -> String
format { nowSec, atSec } =
    let
        delta =
            nowSec - atSec

        absDelta =
            abs delta

        prefix =
            if delta >= 0 then
                ""

            else
                "in "

        suffix =
            if delta >= 0 then
                " ago"

            else
                ""

        unit n u =
            prefix ++ String.fromInt n ++ u ++ suffix
    in
    if absDelta < 60 then
        unit absDelta "s"

    else if absDelta < 3600 then
        unit (absDelta // 60) "m"

    else if absDelta < 86400 then
        unit (absDelta // 3600) "h"

    else if absDelta < 86400 * 30 then
        unit (absDelta // 86400) "d"

    else
        unit (absDelta // (86400 * 7)) "w"
