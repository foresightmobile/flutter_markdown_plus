// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Golden render regression tests for the Markdown widgets. These render a few
// representative documents (formatting, tables/task lists, code) and compare
// them against committed reference images, catching unintended changes to how
// content is laid out and styled.
//
// Real Roboto / MaterialIcons fonts are loaded from the Flutter SDK (located
// via FLUTTER_ROOT, which `flutter test` always sets) so the goldens show
// actual glyphs rather than the Ahem test font.
//
// Reference images are never regenerated on a developer machine. To
// regenerate them after an intentional change, run the manual
// `Regenerate golden references` workflow_dispatch job in GitHub Actions
// (from `main`), which runs on the pinned macOS runner and opens a PR.
//
// Goldens run only under --dart-define=GOLDENS=true (validate.sh forwards it),
// because the references are generated on one pinned CI runner and font
// rasterisation varies across machines and Flutter versions. Everywhere else
// they are skipped and say so. Comparison tolerates a little pixel drift;
// see TolerantGoldenComparator in utils.dart.
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils.dart';

/// Directory holding the Roboto and MaterialIcons fonts shipped with the
/// Flutter SDK, or `null` if it cannot be located.
String? _materialFontsDir() {
  final String? root = kIsWeb ? null : io.Platform.environment['FLUTTER_ROOT'];
  if (root == null) {
    return null;
  }
  final String dir = '$root/bin/cache/artifacts/material_fonts';
  return io.Directory(dir).existsSync() ? dir : null;
}

Future<void> _loadFont(String family, List<String> paths) async {
  final FontLoader loader = FontLoader(family);
  for (final String path in paths) {
    loader.addFont(Future<ByteData>.value(io.File(path).readAsBytesSync().buffer.asByteData()));
  }
  await loader.load();
}

const String _formatting = '''
# Flutter Markdown Plus

A **Markdown renderer** for Flutter with rich text, _emphasis_,
and ~~strikethrough~~ out of the box.

> Blockquotes are theme-aware and adapt to light and dark mode.

## Lists

- Headings, bold, and italics
- Links such as [flutter.dev](https://flutter.dev)
- Ordered and unordered lists

1. Parse GitHub Flavored Markdown
2. Style every element
3. Render native Flutter widgets
''';

const String _tablesAndTasks = '''
## Tables

| Feature    | Supported | Notes                     |
| :--------- | :-------: | :------------------------ |
| Headings   |    Yes    | H1-H6                     |
| Tables     |    Yes    | Alignment & column widths |
| Task lists |    Yes    | Rendered as checkboxes    |

## Task lists

- [x] Render tables with custom borders
- [x] Show task-list checkboxes
- [ ] Handle a link tap
''';

const String _code = '''
## Code blocks

Inline code like `MarkdownBody(data: source)` renders in its
own style.

Each fenced block manages its own scroll controller:

```dart
Markdown(
  data: markdownSource,
  selectable: true,
  onTapLink: (text, href, title) {
    launchUrl(Uri.parse(href!));
  },
);
```
''';

Future<void> _expectGolden(WidgetTester tester, String data, String file) async {
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  // Unmount the tree. Without this leak_tracker reports the still-mounted
  // MaterialApp (and its HeroController and _MaterialAppState) as
  // notDisposed at tearDownAll -- 520 objects, one whole failing test that
  // had nothing to do with the pixels being compared.
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
  });

  final ThemeData base = ThemeData(
    colorSchemeSeed: const Color(0xFF2962FF),
    useMaterial3: true,
    brightness: Brightness.light,
  );
  final ThemeData theme = base.copyWith(textTheme: base.textTheme.apply(fontFamily: 'Roboto'));

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Builder(
              builder: (BuildContext context) {
                final MarkdownStyleSheet sheet = MarkdownStyleSheet.fromTheme(Theme.of(context));
                // No monospace font is bundled, so render code in the body font
                // to exercise the code block's decoration and layout without the
                // Ahem fallback.
                return MarkdownBody(
                  data: data,
                  styleSheet: sheet.copyWith(code: sheet.code?.copyWith(fontFamily: 'Roboto')),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('assets/golden/render/$file'));
}

void main() => defineTests();

void defineTests() {
  final String? fontsDir = _materialFontsDir();

  group('Golden render', () {
    setUpAll(() async {
      setUpGoldens();
      if (!kGoldensEnabled) {
        return;
      }
      if (fontsDir == null) {
        final String? root = kIsWeb ? null : io.Platform.environment['FLUTTER_ROOT'];
        throw StateError(
          'GOLDENS=true is set, but Material fonts were not found under '
          'FLUTTER_ROOT ($root). Cannot run golden render tests without '
          'Roboto / MaterialIcons.',
        );
      }
      await _loadFont('Roboto', <String>[
        '$fontsDir/Roboto-Regular.ttf',
        '$fontsDir/Roboto-Bold.ttf',
        '$fontsDir/Roboto-Italic.ttf',
        '$fontsDir/Roboto-BoldItalic.ttf',
      ]);
      await _loadFont('MaterialIcons', <String>['$fontsDir/MaterialIcons-Regular.otf']);
    });

    testWidgets(
      'formatting, emphasis, blockquotes and lists',
      (WidgetTester tester) => _expectGolden(tester, _formatting, 'formatting.png'),
      skip: !kGoldensEnabled,
    );

    testWidgets(
      'tables and task lists',
      (WidgetTester tester) => _expectGolden(tester, _tablesAndTasks, 'tables.png'),
      skip: !kGoldensEnabled,
    );

    testWidgets(
      'inline and fenced code blocks',
      (WidgetTester tester) => _expectGolden(tester, _code, 'code.png'),
      skip: !kGoldensEnabled,
    );
  });
}
