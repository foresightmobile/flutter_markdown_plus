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
2. **Two small fixes that close two issues outright** (§3.1) — both are one-file changes with tests.
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

## 5. Adoption decisions

A community fork of this package (`zuraffa_markdown` on pub.dev) has shipped work and published a
triage of our backlog. Reviewed 27 Nov 2026. Position: **thank, do not compete, adopt selectively.**

- **Do not mirror its comment pattern onto our tracker or theirs.** Answer our issues in our own
  words. Visible activity and clear dispositions are the response.
- **Do not merge from its history.** It reformats every file to a different page width, so any
  cherry-pick produces enormous misleading diffs. Re-derive anything we take as a small targeted patch
  against our tree.
- **Worth taking, as patterns rather than as code:**
  1. The *idea* of discriminating theme families by ancestor widget rather than by `Theme.of`
     (which returns a fallback instead of failing). Useful for §6. Re-implement without a hard
     dependency on any third-party theme package.
  2. A style-sheet factory family that lets two theme sources share one mapping
     (`fromTheme`-style entry points feeding one shared builder). Additive, so it cannot break callers.
  3. The *shape* of its theme-family test: assert the resolved style sheet follows whichever theme
     ancestor is present. Re-creatable SDK-only as "style sheet follows `ThemeData.light()`/`.dark()`".
- **Do not take:** its dependency set (two hard third-party theme packages), its SDK floor, its
  version numbering, or its goldens. Regenerate goldens under our own toolchain — the suite is
  platform-specific and pinned to the local Flutter.
- **Known trap if someone quotes its README:** it claims the public API is unchanged, but two
  factories changed parameter type. Verify any such claim against code before repeating it.

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
