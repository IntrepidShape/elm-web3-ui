# Security Policy

This package renders the screens on which a user decides whether to sign a
transaction. It does not hold keys and it does not talk to a wallet -- but a
component that displays the wrong amount, the wrong address, or the wrong
token is a security bug, not a cosmetic one. Report it as such.

## Reporting a vulnerability

Email **[Jake@intrepiddev.com.au](mailto:Jake@intrepiddev.com.au)** with
`elm-web3-ui security` in the subject line.

Include the affected version, the shortest reproduction you have (a `Model`
value and the component call is usually enough -- every view here is a pure
function), and what a user would be misled into doing.

Do **not** open a public GitHub issue for anything that causes a component to
misrepresent an amount, an address, a token, a chain, or a transaction's
outcome.

What to expect:

| | |
|---|---|
| Acknowledgement | within 3 working days (Perth, AWST / UTC+8) |
| Initial assessment | within 10 working days |
| Fix or documented mitigation | as fast as the severity warrants; see [Publishing a security patch](#publishing-a-security-patch) |
| Credit | offered by default, declined on request |

This is a small team. There is no bug bounty, and pretending otherwise would
be dishonest.

## Scope

In scope:

- `src/**` -- every UI primitive.
- `styles/**` -- only where a stylesheet could hide or obscure a value the
  component intended to show.
- The underlying package `intrepidshape/elm-web3`, which has its own
  `SECURITY.md` pointing at the same address. Anything involving signing,
  broadcasting, the JS bridge, or RPC transport belongs there.

Out of scope:

- Your own CSS. This package ships class names, not styles; a theme that
  renders text invisible is your theme's bug.
- Wallet extensions, RPC providers, and chains themselves.
- The example RPC endpoints referenced in `examples/**`.

### The bug class that matters most here

The highest-severity bug this package can have is a **display/reality
mismatch**: a number formatted with the wrong `decimals`, an amount rounded
through a `Float`, a truncated address whose ellipsis hides the bytes that
differ, a status badge that renders a mined-and-reverted transaction as
success. None of these throw. All of them can cost a user money. They are
treated as security reports, not as bugs.

If you find one, the reproduction we want is the exact input value and the
exact rendered string.

## What is verified, and what is not

**No external security audit has been performed on this package.**

What *is* machine-checked, on every push, with an exit code:

| Mechanism | What it covers | Where |
|---|---|---|
| TLA+ model checking (TLC) | The approval-flow state machine's invariants and liveness | `proofs/tla/`, CI job `tlc` |
| Unit and property tests | Component rendering across every state of every state machine they consume, plus formatting and input-validation behaviour | `tests/`, CI job `elm` |
| Compiler | Elm's totality and exhaustiveness checks. Every view is a pure function of its arguments; there is no internal `Msg`, no subscription, and no state of its own, so there is nothing to get out of sync | CI job `elm` |
| ASCII doc guard | Rejects non-ASCII in `docs.json`, which permanently bricks published docs for every consumer | CI job `elm` |
| Example builds | Every example -- including the gallery, which exercises every generic primitive in every state -- is compiled | CI job `elm` |

What is **not** verified:

1. **There are no Lean proofs in this package.** The formal corpus lives in
   `intrepidshape/elm-web3`; see its `proofs/COVERAGE.md`. Claims made there
   are about that package's internals, not about rendering.
2. **TLA+ here is finite-model checked, not proof-verified,** and covers the
   approval flow only.
3. **"Renders correctly" is tested, not proved.** The tests assert on the
   produced `Html` for chosen inputs. They are not an exhaustive statement
   that every input renders faithfully -- and the display/reality mismatch
   class above is precisely the class that survives that gap. Read a green
   suite as evidence, not as a guarantee.
4. **Themes are unverified by construction.** The package emits semantic class
   names and no inline styles. What a class ends up looking like is entirely
   your stylesheet's business.

## Supply chain

**Zero runtime dependencies outside the Elm package ecosystem, and zero
JavaScript of any kind.** This package is pure Elm: `elm/core`, `elm/html`,
`elm/json`, `elm/svg`, and `intrepidshape/elm-web3`. Elm packages are pure Elm
by construction, so nothing in the dependency tree can execute at install
time.

There is no bundler plugin, no CSS-in-JS runtime, no icon package pulling
network assets, and no `dangerouslySetInnerHTML` equivalent -- Elm has no such
primitive.

The one JS artifact in this stack is the port shim, and it lives in
`intrepidshape/elm-web3`. Verifying its bytes is documented in that package's
`SECURITY.md`.

## Publishing a security patch

**The Elm package registry is append-only. Nothing can ever be unpublished or
overwritten.** Published bytes are immutable, forever. There is no "yank the
bad version" step available to us, or to any Elm package author.

The procedure is deprecate-and-supersede:

1. **Fix and publish forward, immediately.** A new version is the only
   mechanism that exists; the vulnerable version stays installable regardless.
2. **Mark the affected versions in `CHANGELOG.md`** under an explicit
   `SECURITY` heading, naming every affected range and the minimum fixed
   version. The changelog is the deprecation notice -- the registry has no
   other one.
3. **Publish a GitHub Security Advisory** on the repository. That is what
   dependency scanners read.
4. **Note it at the top of `README.md`** while a meaningful number of
   consumers remain on an affected version; the README is what the registry
   page renders.
5. **Say whether the fix also requires an `intrepidshape/elm-web3` upgrade.**
   The two packages ship together and this one pins a MAJOR range of the
   other, so a coordinated pair is common. Name both versions explicitly.
6. **If the fix requires a breaking API change, ship the MAJOR.** `elm bump`
   is the arbiter. A contorted API that dodges the version bump is a worse
   outcome than the bump.

Consumers: pin an exact lower bound you have reviewed, and watch this
repository's advisories.

## Hardening notes for consumers

- **Pass the right `decimals`.** Components format what you give them. When a
  card shows two different tokens, check that each amount is paired with its
  own token's decimals -- that mismatch is silent and it is the most common
  real-world defect in this class of component.
- **A truncated address is a display, not an identity.** Never make a
  comparison or a routing decision on `Address.short`; compare the full
  `T.Address` values.
- **`valid : Bool` is yours to compute.** Input components do not parse. If
  you never call `T.address` / `BigInt.fromString`, nothing validates.
- **Terminal is not the same as successful.** A confirmed receipt can carry an
  EVM status of false. Check the receipt, not just the state machine's
  terminality.

## License

Reports and fixes are handled under the same MIT license as the rest of the
project.
