# Release plan and issue dispositions

**For the agent working this repo.** Read this before touching the issue tracker or planning a
release. It records what has been decided, in what order, and what "done" looks like for each item.
Everything here is a decision or a measurement; where the two differ it says which.

- **Status:** decisions made 27 Nov 2026, nothing yet actioned.
- **Scope:** release train, issue closures, what to adopt from the community fork, and the
  `material_ui` migration.
- **Deep-dive evidence** lives in the local-only `docs/` directory of a working checkout (it is
  gitignored on purpose — it names internal tooling). This file is the action list and stands alone.

---

## 1. Release train

| Release | Contents | Gate |
| --- | --- | --- |
| **1.1.0** | Already in flight. The current open PRs (#150, #153, #147) plus the landed fixes since 1.0.12. | Spec A R36 merge freeze: **do not merge #145, #150, #153 until 1.1.0 stable is tagged.** Ship `1.1.0-dev.1`, soak, then stable. |
| **1.1.x** | Small fixes and the issue closures in §3. Anything that does not change the public API or raise the floor. | Patch-level: no API change, no floor change. |
| **1.2.0** | Additive features that change behaviour or add API — `forceStrutHeight` opt-out is the model. | Minor: additive API allowed. Floor unchanged. |
| **2.0.0 / next major** | The `material_ui` migration (§6). This is the only item that justifies a major. | Requires an explicit floor decision first. |

**Rule that governs all of them:** the example's `flutter:` floor must not exceed the declared
Compatibility Floor. A patch release must not raise the floor.

---

## 2. Recommended order of work

1. **Land 1.1.0.** It unblocks the merge freeze and the Material UI work.
2. **Three small fixes, all one-file changes with tests** (§3.1 and §5.2) — #82, #121, and the
   `test/image_test.dart` defects we already carry. The third is a two-line re-derivation of work
   that has already been done and verified elsewhere; take it first, it is the cheapest.
3. **Close the already-fixed issues** (§3.2) — no code, just disposition comments naming the version.
4. **Close the agreed won't-fix set** (§3.3).
5. **Leave the contested four open** (§4) and give them a label so they stop looking abandoned.
6. **Open a work item for the `material_ui` migration** (§6) — it is the only long-lead item and it
   should not be discovered late.

Steps 2–5 are cheap and make the tracker look maintained, which is the point.

---

## 3. Issue dispositions to action

### 3.1 Fix and close — two items, both small

**#82 — API documentation points at a non-existent GitHub issue.**
Two stale dartdoc links. `lib/src/widget.dart` around lines 169 and 183 point at
`github.com/flutter/flutter_markdown_plus/issues/311` and `issues/169`. Both 404: wrong organisation,
and our tracker has never held 311 issues. Fix by pointing both at
`https://github.com/foresightmobile/flutter_markdown_plus/issues`, or drop the issue numbers and
describe the constraint in prose (better — issue-number links rot).
*Acceptance:* no `github.com/flutter/` link remains anywhere in `lib/`; a test or an assert is not
needed, but run `dart doc` and check no 404 target remains.

**#121 — Dark theme support.**
Most colours already derive from `ThemeData`. The remaining gap is one hardcoded link colour:
`a: const TextStyle(color: Colors.blue)` in `lib/src/style_sheet.dart`, in both `fromTheme` and the
large variant. `test/style_sheet_test.dart` currently **pins** `Colors.blue`, so the test is asserting
the bug.
*Acceptance:* link colour derives from `theme.colorScheme.primary`; the dark-theme test asserts the
link colour changes between `ThemeData.light()` and `ThemeData.dark()`; the old `expect(..., Colors.blue)`
assertion is gone.

Both are honest "fixed in flutter_markdown_plus" moments with our own tests behind them.

### 3.2 Close as already fixed — seven items, no code

These were fixed in our code in the 1.0.x line and the issues were never closed. Before commenting,
confirm which release/PR landed the fix and name it. Do not say "fixed recently" — name the version.

| # | Issue | Evidence the fix is in |
| --- | --- | --- |
| #46 | Custom builder for `'hr'` not invoked | Fixed before the current HEAD; confirm PR |
| #48 | Allow aligning table cell content | `MarkdownStyleSheet` align fields + `builder.dart` `_textAlignForBlockTag`, tests in `test/text_alignment_test.dart` |
| #58 | Inline code blocks break selectable text | Fixed in 1.0.x; confirm PR |
| #62 | `onSelectionChanged` nullable, `!` without null check | Fixed in 1.0.x; confirm PR |
| #72 | Assertion for footnotes with latest `markdown` | Fixed and runtime-verified; confirm PR |
| #81 | `MarkdownBody.shrinkWrap` with single child | Fixed in 1.0.x; confirm PR |
| #99 | `MarkdownBody` ignores `textAligment` | Property is on `MarkdownStyleSheet` (`textAlign`, `h1Align`…`h6Align`, `tableHeadAlign`), consumed in `builder.dart`. **Caveat:** it is not a `MarkdownBody.textAlign` parameter. If the reporter wanted that spelling, say so explicitly rather than closing as fixed. |

### 3.3 Close as won't-fix — with our own reasoning

We agree with these calls. The reason written on each issue must be **ours**, phrased as a design
decision of this package — not a reference to anyone else's triage.

Won't fix, design:

| # | Issue | Reason to write |
| --- | --- | --- |
| #29 | SVGs not rendered | SVG support means an SVG dependency this package has never carried. `imageBuilder` is the extension point. |
| #41 | Use `Link` to render links | Links stay `TextSpan` + recognizer deliberately so they remain inside inline layout. |
| #66 | Custom builder for `'a'` breaks inline layout | Same as #41 — `MarkdownElementBuilder` on `'a'` replaces the span, which is the documented way. |
| #68 | Change default `MarkdownStyleSheet` down the tree | `MarkdownStyleSheet` is passed per widget on purpose. An inherited lookup would make it ambiguous which sheet applies. |
| #78 | Give access to children | Would freeze the internal widget tree as public API. `MarkdownBuilder` is the extension point. |
| #87 | Parse markdown inside custom `blockSyntax` | Recursive Markdown parsing inside a custom block risks unbounded recursion. Out of scope. |
| #88 | Limit/restrict markdown functionality | The grammar is `package:markdown`'s. Restricting it would mean owning a wrapper layer. |
| #98 | Let `MarkdownWidget` implement `Text` | A widget masquerading as a `Text` span breaks the `RichText` contract it relies on. |
| #101 | Text as root element | Would make the parser accept input CommonMark rejects. |
| #107 | Remove padding under headings | Already configurable — `h1Padding`…`h6Padding` on `MarkdownStyleSheet`, all default `EdgeInsets.zero`. |

Won't fix, spec or framework behaviour:

| # | Issue | Reason to write |
| --- | --- | --- |
| #51 | Image at end always on new line | Flutter's inline layout: an inline image that cannot fit wraps. Same as `WidgetSpan`. |
| #69 | `'@'` link label assumed `:mailto` | The CommonMark rule for `@`-prefixed destinations. Overriding it diverges from the spec the parser implements. |
| #74 | Wrap only the end of long text after inline code | Line breaking is Flutter's `Text` layout, not the renderer's. |
| #85 | `maxScrollExtent` is not a fixed value | Not a defect — it is undefined until layout has run. |
| #86 | Rich text breaks mid-sentence; unicode not shown | Line breaking is `Text` + `TextDirection`. The unicode half is font selection. |
| #102 | `TextWidthBasis` support | Same root cause as #86 — text layout is Flutter's. |
| #20 | Inline syntax for underlined text | Already supported — `MarkdownElementBuilder` is the extension point. Point at the README pattern. |
| #80 | Inline syntax for coloured text | Same as #20. |
| #91 | Custom widget for h1, h2 etc. | Already supported — register a builder for `'h1'`..`'h6'`. |

Unreproducible, close as stale with an invitation to reopen:

| # | Issue | Reason to write |
| --- | --- | --- |
| #30 | Table scrollbars drawn ~1 row too high | Cannot reproduce against the current golden suite. Platform scrollbar positioning. |
| #44 | Table scroll indicator not at bottom | Same surface as #30 — indicator position belongs to the platform scrollbar. |
| #36 | Can not jump to selection | Ambiguous with no reproduction. Close as stale; reopen with a sample. |
| #83 | Code lines in header not rendered properly | Cannot reproduce; the golden suite covers headers containing code. |

Documentation, close after the docs exist (do not close blind):

| # | Issue | Action first |
| --- | --- | --- |
| #89 | Example of use in `showDialog` | Two-line README example, then close. |
| #111 | Document URL parameters in links | README line, then close. |
| #120 | Better documentation on images | Fold into one docs pass, then close. |
| #77 | Restructure examples to avoid value types | Won't fix — rewriting examples for style is churn with no user benefit. |
| #118 | Add `onLongPressURL` | Not a separate API — `contextMenuBuilder` is the hook. |

---

## 4. Keep open — four items we do not agree should close

Give each a label (`a11y`, `platform: web`, `needs repro`, `feature`) so they stop looking abandoned.
The reasoning must be ours.

| # | Issue | Why it stays open | Suggested next step |
| --- | --- | --- | --- |
| #56 | Screenreader: ignore bullet points and icons | Real accessibility request. The ask is an **opt-out** (`excludeFromSemantics` / custom `semanticsLabel` on the marker), not unconditional suppression. The counter-argument ("markers are real text nodes") answers a different question. | Label `a11y`. Design a documented opt-out. |
| #75 | Markdown not properly rendered in Safari | Unreproducible is not invalid. We claim web support. | Label `platform: web`, `needs repro`, `help wanted`. |
| #110 | Checkboxes aren't checkable | The premise (the source string is immutable) is right and the conclusion does not follow. The renderer need not hold state — an `onTapTaskList`-style callback with consumer-supplied state is a normal pattern. | Label `feature`. Decide yes/no as a feature, not as "not a bug". |
| #65 | Support RTL | "Works via ambient `Directionality`" and "we chose not to do dedicated RTL" are different answers, and the first may not match the reporter's experience. | Either post a working repro snippet and close, or label `feature` and keep. Do not close with someone else's wording. |

---

## 5. Adoption map — what a community fork has already done, per ticket

A community fork of this package (`zuraffa_markdown` on pub.dev) shipped work and published a triage
of our backlog. Reviewed 27 Nov 2026 against its code, not its README. This section exists so nobody
re-derives work that is already done: it says, ticket by ticket, whether there is something to take.

Position: **thank, do not compete, adopt selectively.**

### 5.1 Its complete code inventory

Do not go looking for more. It has exactly **three** code changes beyond package renaming and
`dart format` reflow (its whole diff is 67 files but ~90% is reflow; `builder.dart` has zero semantic
hunks). All are merged on its own repo:

| Its PR | Commit | What |
| --- | --- | --- |
| #1 | `c84ef6a` | `material_ui` / `cupertino_ui` support, package rename to 7.6.1 |
| #2 | `dc31ee9` | `fix: SDK MaterialApp apps keep their own theme` (7.6.2 — fixes a bug its own #1 introduced) |
| #91 | `2f2555d` | `fix: correct invalid-scheme image test condition and skip leaky test on Linux` |

Everything else is docs (its triage index, README, CHANGELOG). Its 40 "planned" tickets have **no
code, no branches and no PRs** — only restated symptoms. Branches it has named `feature/*` and
`claude/*` are **our own history** carried over by the fork (they exist on this repo's remote too);
they are not its work.

### 5.2 Directly adoptable — verified patch, ready to take

**Ticket: `test/image_test.dart` correctness and Linux leak.** Not an issue number — a test defect
that our own suite carries.

Its PR #91 makes two changes. **Both defects are present in our tree right now:**

| Our location | Defect | Its fix |
| --- | --- | --- |
| `test/image_test.dart:355` — `if (kIsWeb \|\| isLinux) {` | Wrong. On non-web, an unrecognized scheme is treated as a *file* image and constructing it throws, so no `Image` is created on **any** non-web platform. Linux is not special. The comment above the line already describes the correct behaviour; the condition contradicts it. | Drop the `\|\| isLinux`. |
| The `'should show properly next to text'` test (opens near `test/image_test.dart:189`) | Has no `skip:`, and on Linux leaks `ImageStreamCompleter` handles — the Flutter leak tracker reports it. Every neighbouring image test already skips on Linux. | Add `skip: isLinux` to its closing. |

*Why it matters to us:* we already chase leak-tracker reports (`fix/golden-test-leak` was about
exactly this class of noise), and our goldens are platform-gated on the same `isLinux` convention.

*To take it:* two lines, re-derived against our tree — do not cherry-pick, its history is reformatted.
*Acceptance:* `flutter test test/image_test.dart` passes; the leak tracker stops reporting
`ImageStreamCompleter` on Linux; the invalid-scheme test's `findsOneWidget` branch is now reachable
on web only.

### 5.3 Study for in-flight work — do not merge

**Ticket #144 / PRs #150 and #153 (`material_ui`).** Its #1 and #2 are the same problem space.

| Take as an idea | Where | Note |
| --- | --- | --- |
| Discriminating theme families by **ancestor widget** rather than `Theme.of` (whose fallback always returns something, so it cannot tell you which family is present) | its `lib/src/_functions_io.dart` / `_functions_web.dart` | The one genuinely clever contribution. Re-implement dependency-free. |
| A style-sheet factory family where two theme sources feed one shared mapping | its `lib/src/style_sheet.dart` | Additive, cannot break callers. Its `_fromThemeParts` de-duplication is worth reading. |
| The *shape* of its theme-family test | its `test/theme_family_test.dart` (55 lines) | Re-creatable SDK-only: "style sheet follows `ThemeData.light()` / `ThemeData.dark()`". |

Its #2 is a useful **negative** example: its own `material_ui` change silently dropped the SDK theme
under an SDK `MaterialApp`, and it needed a second release to fix. That failure mode is exactly what
#153's theme-nesting work should be tested against.

### 5.4 Tickets where there is nothing to take

Checked, so nobody looks twice:

| Our ticket | Its disposition | Anything to take? |
| --- | --- | --- |
| #46, #48, #58, #62, #72, #81, #99 | "fixed" | No — those fixes are **ours**, already in our code before it forked. See §3.2 to close them. |
| #82 | "fixed" | No — it is **not** fixed anywhere. See §3.1; we fix it ourselves. |
| #61 | "fixed" | No — it changed nothing on the blamed code path. See §3.1. |
| #60, #121 | "fixed" | No — partial in both trees. See §3.1 for what's missing. |
| #146 | "planned" | No — the "~45-line fix" it cites is **ours**, written in our own issue. |
| #63, #64, #152 | "planned" (two of them P0) | No — we already fixed and closed all three. |
| The other 40 "planned" | planned | No code exists. |
| The 35 "declined" | declined | Nothing to take; see §3.3 and §4 for our own calls. |

### 5.5 Do not take

- **Its dependency set** — two hard third-party theme packages. A general-purpose Markdown renderer
  must not force every consumer to resolve and ship a theme family.
- **Its SDK floor** (`flutter >=3.47.0`, `sdk ^3.13.0`) — would drop every consumer on Flutter
  3.27–3.46 and break the Compatibility Floor rule in §8.
- **Its version numbering** (1.0.12 → 7.6.2) — fleet alignment with its other packages, not our history.
- **Its goldens** — regenerate under our own toolchain; our suite is platform-specific and pinned to
  the local Flutter.
- **Its README claims.** It states "The public API is unchanged: every class, constructor, named
  parameter and default value keeps its name, type and meaning." That is **false** for two factories,
  whose parameter type changed. Verify any such claim against code before repeating it.

### 5.6 Standing rules

- **Do not merge from its history.** It reformats every file to a different page width, so any
  cherry-pick produces enormous misleading diffs. Re-derive as small targeted patches against our tree.
- **Do not mirror its comment pattern** onto our tracker or theirs. Answer our issues in our own
  words. Visible activity and clear dispositions are the response.
- **Credit where we adopt.** If we take §5.2, say so in the commit message. That is normal open-source
  hygiene and costs nothing.

---

## 6. The `material_ui` migration — the real long-lead item

This is not about the fork. It is about the SDK.

`package:flutter/material.dart` is **deprecated** after `v3.47.0-0.0.pre`, with the message pointing
at `package:material_ui/material_ui.dart`. `cupertino.dart` is the same for `package:cupertino_ui`.
Verified in Flutter 3.50.1 at `packages/flutter/lib/material.dart:17-21`.

All five of our `lib/src/*.dart` files import `package:flutter/material.dart`. So the migration has to
happen; the only questions are **when** and **in what shape**.

**Open a work item for it now**, covering these decisions — do not let them be made inside a PR review:

1. **Dependency shape.** Hard dependency on `material_ui`, or an optional/companion package, or
   conditional resolution? A general-purpose Markdown renderer should not force every consumer to
   resolve and ship a whole third-party theme family. Leaning: keep the core free of the dependency.
2. **Floor.** Can the migration be done without raising the Compatibility Floor? If the floor must
   rise, that is a major release and needs saying up front.
3. **API.** Whether `MarkdownStyleSheet.fromTheme` keeps accepting the SDK `ThemeData` (it must, or
   every existing caller breaks) and how a `material_ui` theme is passed alongside it.
4. **Deprecation path.** What we do about the SDK deprecation warning in the meantime.

Already in flight and relevant: PRs #150 and #153 (community) add `material_ui`/`cupertino_ui` theme
support **additively** while keeping legacy apps working, and #153 fixes theme nesting and the
selection-toolbar localisations crash. They are held by the 1.1.0 freeze. Review them as the starting
point for decision 3 — #153's approach (legacy apps keep exactly what they have today) is the right
default.

---

## 7. Verification bar

Anything closing an issue as fixed needs one of:

- a regression test that fails before the change and passes after (sabotage the fix and watch it go
  red — a guard that has never failed proves nothing), or
- for a docs-only change, a check that the old broken thing is gone.

Anything closing as won't-fix needs the reason written on the issue in our own words.

Do not close an issue on the strength of someone else's claim. Verify against our code first.

---

## 8. Do not do

- Do not raise the Compatibility Floor in a patch release.
- Do not merge #145, #150 or #153 before 1.1.0 stable is tagged.
- Do not `git add -A`. Stage explicit paths. `docs/`, `AGENTS.md`, `.act/` and `worktrees/` are
  gitignored on purpose — the repo is public and those name internal tooling.
- Do not comment on external repos to argue about dispositions. Keep the response on our tracker.
- Do not adopt a change because it exists elsewhere. Adopt it because it is tested here.
