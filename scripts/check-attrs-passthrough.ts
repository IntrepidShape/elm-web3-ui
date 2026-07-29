#!/usr/bin/env bun
/**
 * check-attrs-passthrough.ts -- the lib <-> consumer boundary detector.
 *
 * The README makes one promise about composability:
 *
 *   "Attribute passthrough. Every function takes `List (Html.Attribute msg)`
 *    as its first argument, merged onto the root element."
 *
 * Nothing enforced it, and it drifted to false for most of the library: a
 * consumer could not attach an `id`, a `data-testid`, an `aria-describedby`,
 * a layout class, or a hover handler to the root of a component, so wanting
 * 5% different behaviour meant forking the module. Two production dapps did
 * exactly that.
 *
 * This script makes the promise checkable. Nothing else in this repo can:
 * `elm make` is perfectly happy with a component that ignores its caller,
 * and a doc comment is not a gate.
 *
 * What is checked, per exposed module, for every EXPOSED top-level function
 * whose return type is `Html`/`Svg`:
 *
 *   ATTR-1  the first argument is not `List (Html.Attribute msg)`
 *           (including the no-argument case -- a bare `Html msg` constant
 *           cannot be addressed by a caller at all)
 *   ATTR-2  a `List (Html.Attribute msg)` argument exists but is not first
 *           -- the caller cannot partially apply the component, and the
 *           convention the other modules follow is broken
 *   ATTR-3  the first argument is accepted and then DROPPED: bound to `_`,
 *           or bound to a name the body never mentions. This is the failure
 *           the type checker cannot see -- the signature satisfies the
 *           README while the attributes go nowhere.
 *
 * Non-exposed helpers are ignored on purpose: they are free to take whatever
 * shape suits the module's internals. The promise is about the surface.
 *
 * Exit code: 0 when every exposed view-producer honours the contract, 1
 * otherwise.
 *
 * Usage:
 *   bun run scripts/check-attrs-passthrough.ts             # check the working tree
 *   bun run scripts/check-attrs-passthrough.ts --verbose   # + the full inventory
 *   bun run scripts/check-attrs-passthrough.ts --self-test # prove the checker fails
 *
 * `--self-test` is not decoration. A checker that has never been observed to
 * fire is not evidence that the tree is clean -- it is evidence of nothing.
 * The self-test runs the analyser over hermetic synthetic sources: once clean
 * (must report nothing), then once per failure class with a violation
 * injected (must report exactly that class), then once over a REAL module
 * with its attrs argument surgically removed (must notice). It exits 0 only
 * if every injected violation was caught and the clean baseline was silent.
 */

import { readFileSync, existsSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

// ---------------------------------------------------------------------------
// Source model
// ---------------------------------------------------------------------------

export interface ElmModule {
  /** Repo-relative path, for reporting. */
  readonly path: string
  /** Module name as written in the `module` line. */
  readonly name: string
  readonly text: string
}

export type FailureCode = 'ATTR-1' | 'ATTR-2' | 'ATTR-3'

export interface Finding {
  readonly code: FailureCode
  /** `Module.function`, the thing a maintainer greps for. */
  readonly ref: string
  readonly detail: string
}

export interface ViewFn {
  readonly module: string
  readonly name: string
  readonly signature: string
  readonly args: readonly string[]
  readonly returns: string
}

export interface Report {
  readonly findings: readonly Finding[]
  readonly views: readonly ViewFn[]
  readonly stats: {
    readonly modules: number
    readonly views: number
    readonly compliant: number
  }
}

// ---------------------------------------------------------------------------
// Comment stripping. Preserves byte offsets and line breaks so line numbers
// and column-zero detection stay honest.
// ---------------------------------------------------------------------------

function blank(ch: string): string {
  return ch === '\n' ? '\n' : ' '
}

/** Strip Elm `--` line comments and nested `{- -}` block comments. */
export function stripElmComments(src: string): string {
  let out = ''
  let i = 0
  let depth = 0
  let inString = false
  let inChar = false

  while (i < src.length) {
    const ch = src[i] as string
    const next = src[i + 1] ?? ''

    if (depth > 0) {
      if (ch === '{' && next === '-') { depth++; out += '  '; i += 2; continue }
      if (ch === '-' && next === '}') { depth--; out += '  '; i += 2; continue }
      out += blank(ch); i++; continue
    }
    if (inString) {
      if (ch === '\\') { out += ch + (next || ''); i += 2; continue }
      if (ch === '"') inString = false
      out += ch; i++; continue
    }
    if (inChar) {
      if (ch === '\\') { out += ch + (next || ''); i += 2; continue }
      if (ch === "'") inChar = false
      out += ch; i++; continue
    }
    if (ch === '"') { inString = true; out += ch; i++; continue }
    if (ch === "'") { inChar = true; out += ch; i++; continue }
    if (ch === '{' && next === '-') { depth = 1; out += '  '; i += 2; continue }
    if (ch === '-' && next === '-') {
      while (i < src.length && src[i] !== '\n') { out += ' '; i++ }
      continue
    }
    out += ch
    i++
  }
  return out
}

// ---------------------------------------------------------------------------
// Extractors
// ---------------------------------------------------------------------------

/**
 * The names a module exposes. `null` means `exposing (..)` -- everything
 * top-level is public, so nothing can be skipped as internal.
 */
export function exposedNames(stripped: string): Set<string> | null {
  const m = /(^|\n)module\s+[\w.]+\s+exposing\s*\(/.exec(stripped)
  if (!m) return new Set()
  let i = (m.index === 0 ? 0 : m.index + m[1].length) + m[0].length - (m.index === 0 ? 0 : m[1].length)
  // Re-find the opening paren precisely: scan forward from the match start.
  i = stripped.indexOf('(', m.index)
  let depth = 0
  let body = ''
  for (; i < stripped.length; i++) {
    const ch = stripped[i] as string
    if (ch === '(') { depth++; if (depth === 1) continue }
    if (ch === ')') { depth--; if (depth === 0) break }
    body += ch
  }
  if (body.trim() === '..') return null
  const names = new Set<string>()
  // Drop `Type(..)` payloads so `(..)` inside a type export is not mistaken
  // for a whole-module export.
  for (const raw of body.replace(/\([^()]*\)/g, '').split(',')) {
    const n = raw.trim()
    if (n) names.add(n)
  }
  return names
}

interface Annotation {
  readonly name: string
  readonly type: string
  /** Everything from the definition's `=` to the next top-level declaration. */
  readonly body: string
  /** Parameter tokens between the definition name and its `=`. */
  readonly params: readonly string[]
}

/** Column-zero `name :` declarations plus the definition that follows. */
export function topLevelAnnotations(stripped: string): Annotation[] {
  const lines = stripped.split('\n')
  const starts: { name: string; line: number }[] = []
  for (let i = 0; i < lines.length; i++) {
    const m = /^([a-z][A-Za-z0-9_']*)\s*:(?!:)/.exec(lines[i] as string)
    if (m) starts.push({ name: m[1] as string, line: i })
  }

  const isTopLevelStart = (line: string): boolean =>
    line.length > 0 && !/^\s/.test(line) && !/^[)\]}]/.test(line)

  const out: Annotation[] = []
  for (const s of starts) {
    // The type runs until the definition line, which starts at column zero
    // with the same name.
    const defRe = new RegExp(`^${s.name}(\\s|=)`)
    let defLine = -1
    for (let i = s.line + 1; i < lines.length; i++) {
      const line = lines[i] as string
      if (!isTopLevelStart(line)) continue
      if (defRe.test(line)) { defLine = i; break }
      break // some other top-level declaration intervened; annotation is orphaned
    }
    if (defLine === -1) continue

    const typeText = [
      (lines[s.line] as string).replace(/^[a-z][A-Za-z0-9_']*\s*:/, ''),
      ...lines.slice(s.line + 1, defLine),
    ].join(' ')

    let endLine = lines.length
    for (let i = defLine + 1; i < lines.length; i++) {
      if (isTopLevelStart(lines[i] as string)) { endLine = i; break }
    }
    const defBlock = lines.slice(defLine, endLine).join('\n')
    const eq = defBlock.indexOf('=')
    const head = eq === -1 ? defBlock : defBlock.slice(0, eq)
    const body = eq === -1 ? '' : defBlock.slice(eq + 1)
    const params = head
      .replace(new RegExp(`^${s.name}`), '')
      .trim()
      .split(/\s+/)
      .filter((p) => p.length > 0)

    out.push({ name: s.name, type: normalise(typeText), body, params })
  }
  return out
}

function normalise(t: string): string {
  return t.replace(/\s+/g, ' ').trim()
}

/** Split a type on its top-level `->`, ignoring arrows inside brackets. */
export function arrowSegments(type: string): string[] {
  const segs: string[] = []
  let depth = 0
  let cur = ''
  for (let i = 0; i < type.length; i++) {
    const ch = type[i] as string
    if (ch === '(' || ch === '[' || ch === '{') depth++
    if (ch === ')' || ch === ']' || ch === '}') depth--
    if (depth === 0 && ch === '-' && type[i + 1] === '>') {
      segs.push(normalise(cur))
      cur = ''
      i++
      continue
    }
    cur += ch
  }
  segs.push(normalise(cur))
  return segs.filter((s) => s.length > 0)
}

const ATTR_ARG = /^List\s*\(\s*(?:Html\.)?Attribute\s+[a-z][A-Za-z0-9_']*\s*\)$/

export function isAttrsArg(seg: string): boolean {
  return ATTR_ARG.test(normalise(seg))
}

/** A return type of `Html msg`, `Svg msg`, `Maybe (Html msg)`, `List (Html msg)`... */
export function isViewReturn(seg: string): boolean {
  return /(^|[\s([{])(Html|Svg)\.?(Html|Svg)?\s/.test(normalise(seg) + ' ')
}

// ---------------------------------------------------------------------------
// Analysis
// ---------------------------------------------------------------------------

export function analyse(modules: readonly ElmModule[]): Report {
  const findings: Finding[] = []
  const views: ViewFn[] = []
  let compliant = 0

  for (const mod of modules) {
    const stripped = stripElmComments(mod.text)
    const exposed = exposedNames(stripped)

    for (const ann of topLevelAnnotations(stripped)) {
      if (exposed !== null && !exposed.has(ann.name)) continue

      const segs = arrowSegments(ann.type)
      const returns = segs[segs.length - 1] as string
      if (!isViewReturn(returns)) continue

      const args = segs.slice(0, -1)
      const ref = `${mod.name}.${ann.name}`
      views.push({ module: mod.name, name: ann.name, signature: ann.type, args, returns })

      if (args.length === 0) {
        findings.push({
          code: 'ATTR-1',
          ref,
          detail: `${ref} : ${ann.type} -- takes no arguments, so a caller can attach nothing to its root`,
        })
        continue
      }

      if (!isAttrsArg(args[0] as string)) {
        const at = args.findIndex((a) => isAttrsArg(a))
        if (at > 0) {
          findings.push({
            code: 'ATTR-2',
            ref,
            detail: `${ref} : ${ann.type} -- takes List (Html.Attribute msg) at position ${at + 1}, not first`,
          })
        } else {
          findings.push({
            code: 'ATTR-1',
            ref,
            detail: `${ref} : ${ann.type} -- first argument is \`${args[0]}\`, expected List (Html.Attribute msg)`,
          })
        }
        continue
      }

      // Signature is right. Are the attributes actually used?
      const param = ann.params[0]
      if (param === undefined) {
        // Point-free definition (`address = Address.input`): the attrs are
        // forwarded by construction, nothing to check.
        compliant++
        continue
      }
      if (param === '_') {
        findings.push({
          code: 'ATTR-3',
          ref,
          detail: `${ref} discards its attrs argument (bound to \`_\`)`,
        })
        continue
      }
      const used = new RegExp(`(^|[^A-Za-z0-9_'.])${param}([^A-Za-z0-9_']|$)`).test(ann.body)
      if (!used) {
        findings.push({
          code: 'ATTR-3',
          ref,
          detail: `${ref} accepts \`${param}\` and never mentions it again -- the attributes are dropped`,
        })
        continue
      }

      compliant++
    }
  }

  return {
    findings,
    views,
    stats: { modules: modules.length, views: views.length, compliant },
  }
}

// ---------------------------------------------------------------------------
// Loading the real tree
// ---------------------------------------------------------------------------

const HERE = dirname(fileURLToPath(import.meta.url))
const ROOT = join(HERE, '..')

export function loadModules(): ElmModule[] {
  const manifest = JSON.parse(readFileSync(join(ROOT, 'elm.json'), 'utf8')) as {
    'exposed-modules': string[]
  }
  const out: ElmModule[] = []
  for (const name of manifest['exposed-modules']) {
    const rel = join('src', ...name.split('.')) + '.elm'
    const abs = join(ROOT, rel)
    if (!existsSync(abs)) {
      throw new Error(`elm.json exposes ${name} but ${rel} does not exist`)
    }
    out.push({ path: rel, name, text: readFileSync(abs, 'utf8') })
  }
  return out
}

// ---------------------------------------------------------------------------
// Self-test
// ---------------------------------------------------------------------------

const FIXTURE_CLEAN = `module Web3.Ui.Widget exposing (view, Config, label)

{-| A fixture module. -}

import Html exposing (Html)
import Html.Attributes as Attr


{-| -}
type alias Config msg =
    { onPress : msg
    , text : String
    }


{-| Not a view: must never be flagged. -}
label : Config msg -> String
label cfg =
    cfg.text


{-| -}
view : List (Html.Attribute msg) -> Config msg -> Html msg
view attrs cfg =
    Html.div
        (Attr.class "web3-widget" :: attrs)
        [ Html.text (label cfg) ]


internalRow : Config msg -> Html msg
internalRow cfg =
    Html.div [ Attr.class "web3-widget__row" ] [ Html.text cfg.text ]
`

interface SelfTestCase {
  readonly name: string
  readonly modules: readonly ElmModule[]
  readonly expect: FailureCode
  readonly expectRef: string
}

function fixture(text: string): ElmModule[] {
  return [{ path: 'src/Web3/Ui/Widget.elm', name: 'Web3.Ui.Widget', text }]
}

function selfTestCases(real: readonly ElmModule[]): SelfTestCase[] {
  const cases: SelfTestCase[] = [
    {
      name: 'exposed view with no attrs argument',
      modules: fixture(
        FIXTURE_CLEAN.replace(
          'view : List (Html.Attribute msg) -> Config msg -> Html msg\nview attrs cfg =',
          'view : Config msg -> Html msg\nview cfg =',
        ).replace('(Attr.class "web3-widget" :: attrs)', '[ Attr.class "web3-widget" ]'),
      ),
      expect: 'ATTR-1',
      expectRef: 'Web3.Ui.Widget.view',
    },
    {
      name: 'exposed view taking no arguments at all',
      modules: fixture(
        FIXTURE_CLEAN.replace(
          'view : List (Html.Attribute msg) -> Config msg -> Html msg\nview attrs cfg =',
          'view : Html msg\nview =',
        )
          .replace('(Attr.class "web3-widget" :: attrs)', '[ Attr.class "web3-widget" ]')
          .replace('[ Html.text (label cfg) ]', '[ Html.text "static" ]'),
      ),
      expect: 'ATTR-1',
      expectRef: 'Web3.Ui.Widget.view',
    },
    {
      name: 'attrs argument present but in second position',
      modules: fixture(
        FIXTURE_CLEAN.replace(
          'view : List (Html.Attribute msg) -> Config msg -> Html msg\nview attrs cfg =',
          'view : Config msg -> List (Html.Attribute msg) -> Html msg\nview cfg attrs =',
        ),
      ),
      expect: 'ATTR-2',
      expectRef: 'Web3.Ui.Widget.view',
    },
    {
      name: 'right signature, attrs bound to _ and dropped',
      modules: fixture(
        FIXTURE_CLEAN.replace('view attrs cfg =', 'view _ cfg =').replace(
          '(Attr.class "web3-widget" :: attrs)',
          '[ Attr.class "web3-widget" ]',
        ),
      ),
      expect: 'ATTR-3',
      expectRef: 'Web3.Ui.Widget.view',
    },
    {
      name: 'right signature, attrs named and silently ignored',
      modules: fixture(
        FIXTURE_CLEAN.replace('(Attr.class "web3-widget" :: attrs)', '[ Attr.class "web3-widget" ]'),
      ),
      expect: 'ATTR-3',
      expectRef: 'Web3.Ui.Widget.view',
    },
  ]

  // Same injection against a REAL module: proves the extractors work on the
  // actual sources and not only on a fixture shaped to suit them.
  const victim = real.find((m) => m.name === 'Web3.Ui.StatCell')
  if (victim && victim.text.includes('view : List (Html.Attribute msg) -> Config -> Html msg')) {
    cases.push({
      name: 'REAL Web3.Ui.StatCell with its attrs argument removed',
      modules: [
        {
          ...victim,
          text: victim.text
            .replace(
              'view : List (Html.Attribute msg) -> Config -> Html msg',
              'view : Config -> Html msg',
            )
            .replace('view attrs opts =', 'view opts ='),
        },
      ],
      expect: 'ATTR-1',
      expectRef: 'Web3.Ui.StatCell.view',
    })
  }

  return cases
}

function runSelfTest(): number {
  let failures = 0

  // 1. The clean fixture must be silent. A checker that always fires is as
  //    useless as one that never does. Note it also contains a non-view
  //    function and an unexposed view helper: both must be ignored.
  const clean = analyse(fixture(FIXTURE_CLEAN))
  if (clean.findings.length === 0 && clean.stats.views === 1) {
    console.log('  ok   clean fixture reports nothing (and sees exactly 1 exposed view)')
  } else {
    failures++
    console.log(`  FAIL clean fixture: ${clean.findings.length} finding(s), ${clean.stats.views} view(s) seen`)
    for (const f of clean.findings) console.log(`         [${f.code}] ${f.detail}`)
  }

  // 2. Every injected violation must be caught, with the right code and ref.
  let real: readonly ElmModule[] = []
  try {
    real = loadModules()
  } catch {
    console.log('  note real sources unavailable; running fixture cases only')
  }

  for (const c of selfTestCases(real)) {
    const report = analyse(c.modules)
    const hit = report.findings.find((f) => f.code === c.expect && f.ref === c.expectRef)
    if (hit) {
      console.log(`  ok   ${c.name} -> ${c.expect} ${c.expectRef}`)
    } else {
      failures++
      console.log(`  FAIL ${c.name}: expected ${c.expect} for '${c.expectRef}', got:`)
      if (report.findings.length === 0) console.log('         (nothing)')
      for (const f of report.findings) console.log(`         [${f.code}] ${f.ref}`)
    }
  }

  console.log('')
  if (failures === 0) {
    console.log('SELF-TEST PASS -- the checker detects every injected violation and stays quiet on clean input.')
    return 0
  }
  console.log(`SELF-TEST FAIL -- ${failures} case(s) not detected. The checker is not trustworthy.`)
  return 1
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

function main(): number {
  const args = new Set(process.argv.slice(2))

  if (args.has('--self-test')) {
    console.log('attribute passthrough self-test (injected violation must be detected)')
    console.log('')
    return runSelfTest()
  }

  const report = analyse(loadModules())
  const s = report.stats
  console.log(
    `attribute passthrough: ${s.views} exposed view-producing function(s) across ` +
      `${s.modules} exposed module(s); ${s.compliant} honour the contract`,
  )

  if (args.has('--verbose') || args.has('-v')) {
    console.log('')
    for (const v of report.views) console.log(`  ${v.module}.${v.name} : ${v.signature}`)
  }

  if (report.findings.length === 0) {
    console.log('OK -- every exposed view takes List (Html.Attribute msg) first and uses it.')
    return 0
  }

  console.log('')
  for (const f of report.findings) console.log(`  [${f.code}] ${f.detail}`)
  console.log('')
  console.log(`FAIL -- ${report.findings.length} function(s) break the attribute-passthrough promise.`)
  return 1
}

// Guarded so the extractors above can be imported by other scripts (and by
// the self-test) without running the check.
if (import.meta.main) process.exit(main())
