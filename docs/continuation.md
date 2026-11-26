# Continuation prompt — handing this repo to another agent

**Read this first, then `docs/release-plan.md`.** This file is the onboarding: what the repo is, what
state it is in, what is outstanding, and which process to follow. The release plan is the action
list. Together they should be enough to start work without any other context.

Last updated 25 Nov 2026.

---

## 1. What this is

`flutter_markdown_plus` — a Markdown renderer for Flutter. A continuation of Google's discontinued
`flutter_markdown`, maintained by [Foresight Mobile](https://foresightmobile.com).

| | |
| --- | --- |
| Repository | https://github.com/foresightmobile/flutter_markdown_plus |
| pub.dev | https://pub.dev/packages/flutter_markdown_plus |
| Current version | `1.1.0-dev.1` on `main` (1.0.12 is the last stable) |
| Issue tracker | https://github.com/foresightmobile/flutter_markdown_plus/issues |

Work Items are **GitHub Issues**. Specs live outside this repo (see the project's own working
agreements; they are deliberately not published here).

---

## 2. Start here

1. **`docs/release-plan.md`** — the action list. Release train, ordered work, issue dispositions to
   action, what to adopt from community work, the `material_ui` migration. Its status line says what
   has been done and what has not. **Read it before touching the issue tracker or planning a release.**
2. **`CONTRIBUTING.md`** — how this project is worked on, including the release runbook.
3. **`validate.sh`** and **`.github/workflows/`** — the actual CI gate. `flutter.yaml` runs tests;
   `publish.yaml` publishes to pub.dev and verifies the tag against `pubspec.yaml`.

---

## 3. Where things stand (25 Nov 2026)

**Landed recently.** `docs/release-plan.md` (#188, #191, #193), a `.pubignore` over-broad-pattern fix
(#189), and a fix for `> [!NOTE]` alert syntax crashing the builder (#192).

**In flight, held deliberately.** PRs **#150** and **#153** add `material_ui` / `cupertino_ui` theme
support additively while keeping legacy apps on exactly what they have today, and #153 fixes theme
nesting and a selection-toolbar localisations crash. **#145** is the wholesale-migration alternative
that #153 rejects. These are held by a merge freeze: **do not merge #145, #150 or #153 before 1.1.0
stable is tagged.** #147 and #148 are separate feature PRs from community contributors.

**Not yet actioned.** Nothing in the release plan's §3 or §4 — no issue has been closed and no fix
has been written from it yet.

**The one thing to do first:** [#190](https://github.com/foresightmobile/flutter_markdown_plus/issues/190).
Two-line test fix, acceptance criteria already on the issue, cheapest item on the plan.

---

## 4. Outstanding tickets

110 issues are open. Most are inherited from the old `flutter/flutter_markdown` tracker and have been
triaged; the release plan §3–§4 gives a disposition and a reason for each. Do not work the list top
to bottom — work the plan.

Broadly:

| Group | Where | Count |
| --- | --- | --- |
| Already fixed in our code, need closing | plan §3.2 | 7 |
| Agreed won't-fix, need closing with our own reason | plan §3.3 | 25 |
| Docs requests, close after the docs exist | plan §3.3 / §3.4 | 4 |
| We disagree with closing — keep open and label | plan §4 | 4 |
| Small fixes that close two issues outright | plan §3.1 (#82, #121) | 2 |
| Adoption already done elsewhere | [#190](https://github.com/foresightmobile/flutter_markdown_plus/issues/190) | 1 |
| Crash triage follow-ups | #158–#161 | 4 |
| Open feature/bug reports, prioritised in the plan | plan §5.4 | the rest |

Crash-triage issues (#158–#161) track the investigation of crashes reported against older releases;
some underlying fixes have already landed.

---

## 5. A community fork exists — read plan §5 before acting on it

`zuraffa_markdown` on pub.dev (https://pub.dev/packages/zuraffa_markdown,
https://github.com/arrrrny/zuraffa_markdown) is a genuine GitHub fork of this repository, published
21 Nov 2026. It has commented on many of our issues with per-issue dispositions and maintains a
triage of our whole backlog.

**`docs/release-plan.md` §5 is the adoption map** — per ticket, whether there is anything to take.
Summary: its complete code inventory is three changes; one of them (test fixes) is worth taking and
is filed as **#190**; the rest is study material for the `material_ui` work. Its "planned" tickets
have no code behind them.

Standing rules, decided:

- Do not mirror its comment pattern onto our tracker or theirs. Answer our issues in our own words.
- Do not merge from its history — it reformats every file, so cherry-picks produce misleading diffs.
  Re-derive as small targeted patches.
- Do not quote its README without checking code. At least one of its stated claims does not hold.

---

## 6. Process

- **Every non-trivial PR gets a first adversarial review from a reviewer that did not write the
  change**, briefed with the commit range, acceptance criteria and paths — never a summary. Ask it to
  falsify, and to run code rather than only read it. A guard that has never failed proves nothing:
  sabotage the thing the test names and watch it go red before trusting a green run.
- **Merge only a PR whose merge-base is the current tip of `main`**, in dependency order, re-running
  the gate after each.
- **Stage explicit paths. Never `git add -A`.** Some working files are gitignored on purpose.
- **The example's `flutter:` floor must not exceed the declared Compatibility Floor**, and a patch
  release must not raise the floor. See `pubspec.yaml` and the packaging notes in the project's
  working agreements.
- **A CHANGELOG entry belongs under the version heading that already exists**, even when that version
  is itself unreleased. There is no `## Unreleased` convention in this repo.
- **Say which claims are measurements and which are decisions.** Verify a fix by breaking it first.

---

## 7. External references

| What | Where |
| --- | --- |
| This package | https://pub.dev/packages/flutter_markdown_plus |
| Original package we continue | https://pub.dev/packages/flutter_markdown (discontinued) |
| Community fork | https://pub.dev/packages/zuraffa_markdown · https://github.com/arrrrny/zuraffa_markdown |
| Fork's triage of our backlog | `doc/issue-triage.md` in that repository |
| Flutter SDK | https://github.com/flutter/flutter |

Note the Flutter SDK deprecation that will eventually drive a major release here:
`package:flutter/material.dart` is deprecated after `v3.47.0-0.0.pre` in favour of
`package:material_ui`. All five `lib/src/*.dart` files import it. Plan that migration deliberately —
without hard third-party dependencies and without raising the Compatibility Floor in a patch.

---

## 8. Machine-local setup

If you are running on the maintainer's own machine, there is a second document beside this one,
**`docs/continuation-machine-setup.md`**, which is deliberately **not** committed to this public
repository. It holds the memory-store locations, skills and MCP configuration needed to pick up the
existing working context. Ask the operator for it; it is not in the repo on purpose.
