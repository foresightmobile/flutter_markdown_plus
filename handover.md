# Handover — flutter_markdown_plus

**For the agent taking this repository over.** Read this, then `docs/continuation.md`, then
`docs/release-plan.md`. Between them you should be able to start work without any other context.

Written 25 Nov 2026 after a session spent analysing a community fork of this package and settling
what follows from it. Everything below is either a **measurement** or a **decision**, and where the
two differ it says which.

---

## 1. What you are taking on

`flutter_markdown_plus` — a Markdown renderer for Flutter, continuing Google's discontinued
`flutter_markdown`, maintained by Foresight Mobile.

| | |
| --- | --- |
| Repository | https://github.com/foresightmobile/flutter_markdown_plus |
| pub.dev | https://pub.dev/packages/flutter_markdown_plus |
| Original (discontinued) | https://pub.dev/packages/flutter_markdown |
| Version on `main` | `1.1.0-dev.1` (1.0.12 is the last stable) |
| Issue tracker | https://github.com/foresightmobile/flutter_markdown_plus/issues |

Work Items are **GitHub Issues**. Read `CONTRIBUTING.md` for how the project is worked on,
`validate.sh` and `.github/workflows/` for the actual CI gate.

---

## 2. Do these first, in this order

1. **[#190](https://github.com/foresightmobile/flutter_markdown_plus/issues/190)** — take two
   `test/image_test.dart` fixes. Two lines. Acceptance criteria are on the issue. Cheapest item on
   the plan and it quiets leak-tracker noise we already chase. **Start here.**
2. **#82 and #121** — two small fixes that close two issues outright. Details in
   `docs/release-plan.md` §3.1.
3. **Close the already-fixed issues** (plan §3.2, seven of them) — no code, just disposition comments
   naming the version that fixed them.
4. **Close the agreed won't-fix set** (plan §3.3) — with our own reasoning, in our own words.
5. **Label the contested four and leave them open** (plan §4): #56, #75, #110, #65.
6. **Open a work item for the `material_ui` migration** (plan §6) — the only long-lead item.

The full ordered list with reasoning is `docs/release-plan.md` §2. **Nothing in §3 or §4 has been
actioned** — no issue closed, no fix written from it yet.

---

## 3. Where things stand

**Landed recently.** `docs/release-plan.md`, `docs/continuation.md`, this file; a `.pubignore`
over-broad-pattern fix; a fix for `> [!NOTE]` alert syntax crashing the builder (#192) plus its
format follow-up (#194).

**In flight, held deliberately.** PRs **#150** and **#153** add `material_ui` / `cupertino_ui` theme
support additively while keeping legacy apps on exactly what they get today. #153 also fixes theme
nesting and a "No MaterialLocalizations" selection-toolbar crash. **#145** is the wholesale-migration
alternative that #153 explicitly rejects. **#147** and **#148** are separate feature PRs from
community contributors.

> **Merge freeze.** Do not merge **#145, #150 or #153** before **1.1.0 stable** is tagged.

**Outstanding tickets:** 110 open. Most are inherited from the old `flutter/flutter_markdown`
tracker and have been triaged. Do not work the list top to bottom — work the plan. The plan groups
them by disposition with a reason for each.

---

## 4. The community fork — read plan §5 before acting

`zuraffa_markdown` on pub.dev (https://pub.dev/packages/zuraffa_markdown ·
https://github.com/arrrrny/zuraffa_markdown) is a genuine GitHub fork of this repository, published
21 Nov 2026. It has commented on many of our issues with per-issue dispositions and maintains a
triage of our entire backlog.

**`docs/release-plan.md` §5 is the adoption map** — per ticket, whether there is anything to take.

Summary of the analysis (measured against its code, not its README):

- Its **complete code inventory is three changes**. The rest of its 67-file diff is `dart format`
  reflow and package renaming; `builder.dart` has zero semantic hunks.
- **One is worth taking** — test fixes, filed as **#190**.
- **Two are study material** for the `material_ui` work above.
- Its **40 "planned" tickets have no code, no branches and no PRs** behind them.
- **Ten of its twelve "fixed" claims are ours or don't hold.** Seven are fixes we shipped before it
  forked; two are partial in both trees; two don't hold at all (one claims a fix that is broken in
  both trees, one changed nothing on the blamed code path).
- **Its triage is already stale.** Its snapshot was 21 Nov; we closed issues after that, including
  two of its top-priority items.

Standing rules, decided — please hold these:

- **Do not mirror its comment pattern** onto our tracker or theirs. Answer our issues in our own
  words. Visible activity and clear dispositions are the response.
- **Do not merge from its history.** It reformats every file to a different page width, so any
  cherry-pick produces enormous misleading diffs. Re-derive as small targeted patches against our tree.
- **Do not quote its README without checking code.** At least one of its stated claims does not hold.
- **Credit it if you adopt its work.** That costs nothing and is ordinary open-source hygiene.

---

## 5. Process — this matters more than the code

- **Every non-trivial PR gets a first adversarial review from a reviewer that did not write the
  change.** Brief it with the commit range, acceptance criteria and paths verbatim — never a summary.
  Ask it to falsify, and to run code rather than only read it.
- **A guard that has never failed proves nothing.** Sabotage the exact thing the test names and watch
  it go red before you trust a green run. Then prove the edit actually landed — a patch on the wrong
  line is indistinguishable from a guard that does not bite.
- **Verify a fix to an idempotent write by setting the target to the wrong value first.** Otherwise
  the "after" reading is indistinguishable from no change at all.
- **Merge only a PR whose merge-base is the current tip of `main`**, in dependency order, re-running
  the whole gate after each.
- **Stage explicit paths. Never `git add -A`.** Several working files are gitignored on purpose — see
  §8.
- **The example's `flutter:` floor must not exceed the declared Compatibility Floor**, and a patch
  release must not raise the floor. `pubspec.yaml` currently declares `sdk: ^3.9.0` /
  `flutter: ">=3.35.0"`.
- **A CHANGELOG entry belongs under the version heading that already exists**, even when that version
  is itself unreleased. There is no `## Unreleased` convention in this repo.
- **Say which claims are measurements and which are decisions.** They are different kinds of claim.
- **Run the `humanizer` skill over anything published as content** before it ships.
- **Keep work to the brief.** If a fix turns up adjacent defects, file them with evidence and ask —
  do not quietly expand the change.

---

## 6. Known traps

| Trap | Why |
| --- | --- |
| **Local `main` drifts behind `origin/main`.** | It has done so by 40+ commits. Branch from `origin/main`, never from local `main`. |
| **`.pubignore` patterns must be anchored.** | `.pubignore` is used *instead of* `.gitignore` by `pub publish`. A bare `docs/` matches at every depth and would also drop `lib/docs/`, `test/docs/`, `example/docs/`. Use `/docs/`. I shipped exactly this mistake and it took a post-merge read to catch. Verify in both directions with `flutter pub publish --dry-run` — create probe files under `lib/docs/` and `test/docs/`, confirm they still ship, confirm root `docs/` does not. |
| **Run `flutter pub get` in a new worktree before the first edit.** | A format hook runs after every edit and silently falls back to 80 columns before `.dart_tool/` exists, producing a huge misleading diff. |
| **`mockito` is pinned to exactly `5.6.4`.** | 5.6.5+ pulls an analyzer that conflicts with the floor SDK's `flutter_test`. Do not raise it until the floor rises. |
| **The repo is not `dart format`-stable** at any line length without the Dart 3.14 formatter. | Do not hand-format, and do not read a bare `dart format .` diff as meaningful. |
| **`package:flutter/material.dart` is deprecated** after `v3.47.0-0.0.pre`. | All five `lib/src/*.dart` import it. This will eventually force a major release. Plan it deliberately — without hard third-party dependencies, and without raising the floor in a patch. |
| **Do not touch another agent's worktree or branch.** | The `worktrees/` directory holds per-branch checkouts that may belong to another session. |

---

## 7. People and PRs you will see

| Who | What |
| --- | --- |
| `TheoGermain` | PR #150 — additive `material_ui` / `cupertino_ui` theme factories, legacy preserved. The right default. |
| `joelbrostrom` | PR #153 — stacked on #150. Theme nesting, selection-toolbar crash, scrollbars. |
| `dpatrongomez` | PR #145 — wholesale migration to `material_ui`. #153 rejects this approach because it drops legacy support. |
| `dkajiwara` | PR #147 — `MarkdownElementBuilder.wrapBlockWidget` |
| `st0ck` | PR #148 — optional per-paragraph direction |
| `vitor-correia` | PR #185 — run `test/all.dart` in `validate.sh` |
| `arrrrny` | Author of the community fork (§4). Did not open a PR here; its work shipped in its own repo. |

---

## 8. What is gitignored here, and why

The repository is **public**. These are deliberately not committed:

`AGENTS.md`, `GLOSSARY.md`, `CLAUDE.md`, `.act/`, `.mimocode/`, `.review/`, `worktrees/`, and
**everything in `docs/` except three files** — `docs/release-plan.md`, `docs/continuation.md`, and
this file if placed there. The reason is that the local-only docs name internal tooling.

The exceptions are tracked because an agent must be able to pull them in. `docs/release-plan.md` and
`docs/continuation.md` name no internal tooling and no personal paths. **This file does** — §9
deliberately lists absolute paths, memory-store locations and tooling config, at the operator's
request, so a new agent can pick up the working context from the repository alone.

There is a fifth file in `docs/`, `continuation-machine-setup.md`, which holds the same
machine-local detail and stays gitignored. It is kept as a working copy; `handover.md` §9 is now the
canonical version. Neither the tracked docs nor this file ship in the published package — see §6 and
`.pubignore`.

---

## 9. Machine-local setup

> This section names absolute paths on the maintainer's Mac and the location of private memory
> stores. It is committed to a public repository deliberately, at the operator's request. If you are
> not on that machine, ignore it.

### Working checkout

| | |
| --- | --- |
| Repo checkout | `/Users/gareth/git-fork/flutter_markdown_plus` |
| Remote | `git@github.com:foresightmobile/flutter_markdown_plus.git` |
| Local-only docs | `docs/` in that checkout — all gitignored except `release-plan.md` and `continuation.md` |
| Per-branch worktrees | `worktrees/` — belong to other sessions; do not touch without asking |

### Read these local docs before working

`AGENTS.md` at the repo root is the entry point and links the rest.

| Doc | Read before |
| --- | --- |
| `AGENTS.md` | Anything — the project's working agreement |
| `docs/release-plan.md` | Issue or release work *(tracked, on `main`)* |
| `docs/continuation.md` | Onboarding *(tracked, on `main`)* |
| `docs/zuraffa-fork-catalogue.md` | Touching any issue the community fork commented on, or quoting anything it claims |
| `docs/packaging-gotchas.md` | Touching `pubspec.yaml`, `.pubignore`, or the example |
| `docs/review-practice.md` | Reviewing or merging a PR |
| `docs/spec-storage.md` | Any spec or work-item step |
| `docs/session-handover-2026-11-25.md` | Starting a fresh session |

### Memory stores

**MiMoCode project memory** — `…/memory/projects/a59dc323-4541-48e4-9ab0-11781838d576/`

Full path: `/Users/gareth/.local/share/mimocode/memory/projects/a59dc323-4541-48e4-9ab0-11781838d576/`

- `MEMORY.md` — project context, rules, architecture decisions
- `MEMORY-*.md` — one spillover file per subject. **Read `MEMORY-repo-conventions-and-fork-provenance.md`
  first** — it holds the community-fork record and the code-verified verdicts on its claims.
  Also notable: `MEMORY-pub-publish.md` and `MEMORY-release-pipeline.md` (how a release actually
  reaches pub.dev and what silently goes wrong), `MEMORY-compat-floor-two-sdk.md` (why both SDKs are
  required), `MEMORY-test-registry-and-goldens.md` / `MEMORY-test-runtime-traps.md` /
  `MEMORY-test-and-toolchain-traps.md`, `MEMORY-ci-and-merge-mechanics.md` /
  `MEMORY-review-mechanics-lessons.md`, `MEMORY-icloud-backup.md`.

**MiMoCode session memory** — `/Users/gareth/.local/share/mimocode/memory/sessions/ses_ffe5deda42b31ffeWgO6TZnOEx/`
(`checkpoint.md`, `notes.md`, `tasks/`, `scratchpad/`). The scratchpad holds the raw fork-investigation
reports behind `docs/zuraffa-fork-catalogue.md`.

**Global user memory** — `/Users/gareth/.local/share/mimocode/memory/global/MEMORY.md`

**Claude Code memory** (if a Claude-based agent is used instead) —
`/Users/gareth/.claude/projects/-Users-gareth-git-fork-flutter-markdown-plus/memory/`

**Cross-project user instructions** — `/Users/gareth/.claude/CLAUDE.md`. Read regardless of tool.

### Skills

| Root | Contents |
| --- | --- |
| `/Users/gareth/.config/opencode/skills/` | ACT workflow skills (`act-interview`, `act-create-spec`, `act-implement`, `act-flutter-*`, `act-git-*`). ACT semantics live in the repo's `.act/workflow.md`; storage config in `.act/config.yaml`. |
| `/Users/gareth/.agents/skills/` | Android / Flutter / AWS skills (`adaptive`, `android-cli`, `testing-setup`, …) |
| `/Users/gareth/Sync/claude/skills/` | Personal skills: `subagent-practice`, `evidence-and-guards`, `shell-zsh-gotchas`, `mac-automation`, `client-docs-and-comms`, `claude-toolchain-upkeep`, `gameplan-flutter-kickoff`, `claude-design-to-flutter` |

Load `subagent-practice` before spawning more than one agent; `evidence-and-guards` before quoting a
measurement or verifying a fix; `shell-zsh-gotchas` before any shell loop, glob or regex. Run the
`humanizer` skill over anything published as content before it ships.

### MCP servers

Configured in `/Users/gareth/.config/mimocode/mimocode.jsonc`.

| Server | Use here |
| --- | --- |
| `dart` | `dart_run_tests`, `dart_analyze_files`, `dart_pub`, `dart_pub_dev_search`, `dart_dart_format`. **Use `dart_run_tests` rather than shelling out to `flutter test`.** |
| `slite` | Specs and Interview Ledgers for this project live in Slite, in the `flutter_markdown_plus` channel. Work Items are GitHub Issues; Slite is where Specs go. |
| GitHub | via the `gh` CLI — issues, PRs, forks, releases |
| `maestro`, `mobile-mcp` | Device and simulator interaction, screenshots, for visual checks |
| `observability`, `gcloud`, `firebase`, `supabase`, `aws-mcp`, `apple-notes` | Other projects; not needed here |

### Toolchain

| | |
| --- | --- |
| `flutter` on PATH | `/Users/gareth/development/flutter/bin/flutter` = **Flutter 3.50.1 / Dart 3.14.0** |
| Compatibility Floor | **Flutter 3.35.0 / Dart 3.9.0** at `/Users/gareth/development/flutter-versions/flutter-3.35.0/bin/flutter` |

**Both are required.** The floor gate wants every 1.1.0 fix to pass on 3.35.0 before merge. Do not
assume which is which — run `flutter --version`.

### Backups on this machine

An hourly one-way mirror copies `~/cowork`, `~/dev-sync`, `~/development` and this repo's local-only
`docs/` into iCloud Drive. See `/Users/gareth/ICLOUD-BACKUP.md`. Failures raise a Notification Center
alert. Across `~/git-fork`, **only this repo's `docs/` is gitignored** — everything else tracks its
docs in git and is safe once pushed. Durable notes belong in this repo's main `docs/` directory, not
in a worktree.

---

## 10. External references

| What | Where |
| --- | --- |
| This package | https://pub.dev/packages/flutter_markdown_plus |
| Original we continue | https://pub.dev/packages/flutter_markdown |
| Community fork | https://pub.dev/packages/zuraffa_markdown · https://github.com/arrrrny/zuraffa_markdown |
| Fork's triage of our backlog | `doc/issue-triage.md` in that repository |
| Flutter SDK | https://github.com/flutter/flutter |
| `material_ui` (the migration target) | https://pub.dev/packages/material_ui |

---

*Read next: `docs/continuation.md` (onboarding and current state) → `docs/release-plan.md` (the
action list). Start at issue #190.*
