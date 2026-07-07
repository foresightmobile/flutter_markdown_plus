# Contributing to flutter_markdown_plus

Thanks for your interest in contributing! This document covers how to develop,
test, and release the package.

Flutter Markdown Plus is the community-maintained successor to the discontinued
`flutter_markdown`. It renders Markdown text into Flutter widgets, built on top
of the Dart [`markdown`](https://pub.dev/packages/markdown) package, and supports
GitHub Flavored Markdown by default. This is the **canonical** repo (despite any
`git-fork/` parent folder in a maintainer's checkout) — the only remote is
`origin` (`foresightmobile/flutter_markdown_plus`), and releases publish to
pub.dev.

## Development commands

### Testing

- Run all tests: `flutter test`
- Run tests with coverage: `rm -rf coverage && flutter test`
- Run all tests via the aggregated suite: `flutter test test/all.dart`
- Run a single test file: `flutter test test/<test_name>.dart`

New test files should define a `defineTests()` entry point and be registered in
`test/all.dart` so they run as part of the aggregated suite.

### Code quality

- Format code: `dart format . -l 120` or `sh ./scripts/format.sh`
- Format only staged files: `sh ./scripts/format.sh --only-staged`
- Format with exit-on-change: `sh ./scripts/format.sh --set-exit-if-changed`
- Analyze code: `flutter analyze --no-pub .`
- Full validation: `./validate.sh` (runs clean, pub get, format, analyze, and test)

### Package management

- Get dependencies: `flutter pub get`
- Clean build: `flutter clean`

### Example app

- Run the example app: `cd example && flutter run`
- Demos live in `example/lib/demos/`, showcasing various features.
- Shared widgets in `example/lib/shared/` include reusable demo components and
  sample custom-syntax implementations.

## Code style

- Line length: 120 characters (configured in `pubspec.yaml`).
- Follows the Flutter/Dart team's `analysis_options.yaml` with minor
  modifications.
- Public API documentation is required (`public_member_api_docs`).
- Strict type checking is enabled.
- Uses `prefer_single_quotes` and other Flutter conventions.

## Architecture

### Core components

- **Main entry point** (`lib/flutter_markdown_plus.dart`) — exports the three
  main modules: builder, style_sheet, and widget.
- **Widget layer** (`lib/src/widget.dart`) — `Markdown` (scrollable with
  padding), `MarkdownBody` (non-scrolling, for embedding), and `MarkdownRaw`
  (base widget without Material theming), plus callback typedefs for link taps,
  selection changes, and custom builders.
- **Builder layer** (`lib/src/builder.dart`) — `MarkdownBuilder` converts
  markdown AST nodes into Flutter widgets, handling all elements (headers,
  paragraphs, lists, tables, images, etc.), text styling, link handling, and
  block vs. inline nesting.
- **Style layer** (`lib/src/style_sheet.dart`) — `MarkdownStyleSheet` is the
  theming system, integrating with Material Design and supporting custom text
  styles, colors, decorations, and spacing.

### Platform abstractions

- `_functions_io.dart` and `_functions_web.dart` provide IO and web
  implementations; conditional imports handle the platform differences.

### Extension points

- **Custom builders**: `imageBuilder`, `checkboxBuilder`, `bulletBuilder`.
- **Syntax extensions**: the markdown package's extension system (GitHub Flavored
  Markdown by default); custom inline/block syntaxes and emoji syntax can be
  added.
- **Selection & interaction**: configurable text selection with callbacks, link
  tap handling, and `SelectionArea` integration.

## Testing strategy

Tests are organized by feature: individual element tests (headers, lists,
images, etc.), style-sheet tests, selection/interaction tests, platform
compatibility tests, and mock-based image tests. `test/all.dart` runs the
complete suite. An integration suite in `example/integration_test/` runs on a
device or emulator (link taps, scrolling, task-list checkboxes, text selection,
example app launch).

## Releasing & publishing

Publishing goes to pub.dev and is **tag-triggered**.

- **Publishing is tag-triggered.** `.github/workflows/publish.yaml` fires on a
  pushed tag matching `v[0-9]+.[0-9]+.[0-9]+` and runs `flutter pub publish --force`
  via pub.dev **OIDC** (configured in the pub.dev package admin — no token in the
  repo). **Pushing the `vX.Y.Z` tag *is* the publish action**; there is no manual
  `pub publish` step. It is irreversible — a published version cannot be
  unpublished.
- **CI:** `.github/workflows/flutter.yaml` runs `./validate.sh` plus Android
  integration tests on every push to `main` and every PR.
- **Trunk-based, no `develop` branch.** `main` is the trunk *and* the release
  branch; the tag gate keeps unreleased work safely on `main`.

### Release flow

1. Create a `release/vX.Y.Z` (or `fix/...`) branch.
2. Open a PR into `main`.
3. Wait for CI to go green, then merge (use a merge commit).
4. Bump the `pubspec.yaml` version and update `CHANGELOG.md`.
5. Push the `vX.Y.Z` tag to publish.

### Gotchas

- A branch-protection ruleset restricts tag *creation*; the maintainer has
  bypass, so `git push origin vX.Y.Z` succeeds with a "Bypassed rule violations"
  notice — this is expected, not an error.
- pub.dev takes **up to ~10 minutes** to index a new version; the API/listing
  lags a successful publish.
- Community PRs that are re-implemented locally (rather than merged) will **not**
  auto-close on push — close them manually with credit. Prefer merging PRs
  directly, or use `Fixes #NNN` in the PR body to auto-close the linked issue.
