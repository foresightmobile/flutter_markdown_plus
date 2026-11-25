// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

void main() => defineTests();

/// Regression tests for #59.
///
/// `> [!NOTE]` alert syntax (from `md.ExtensionSet.gitHubWeb`) emits a `div`
/// wrapping two `p` elements. The builder did not know that container: it left
/// the inline stack inconsistent, so `_addAnonymousBlockIfNeeded` threw
/// `Bad state: Too many elements` on `_inlines.single` and `visitElementAfter`
/// threw `RangeError` on `_inlines.removeLast()`.
///
/// These assert the crashes are gone only. Rendering alert blocks properly —
/// recognising the `div`, most likely via a block builder — is deliberately
/// left open for phase 2 (Spec A R34).
void defineTests() {
  Future<void> pumpAlert(WidgetTester tester, String kind) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Markdown(data: '> [!$kind]\n> this does not work', extensionSet: md.ExtensionSet.gitHubWeb),
        ),
      ),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  group('Alert syntax', () {
    testWidgets('> [!NOTE] does not crash and keeps its body text', (WidgetTester tester) async {
      await pumpAlert(tester, 'NOTE');
      expect(tester.takeException(), isNull);
      // The alert body must still render — stopping the crash is not enough if
      // the content is dropped. `find.text` misses bare RichText, so match on
      // the plain text of every RichText instead.
      final Iterable<String> rendered = tester.allWidgets.whereType<RichText>().map(
        (RichText w) => w.text.toPlainText(),
      );
      expect(rendered, anyElement(contains('this does not work')));
    });

    testWidgets('every alert kind does not crash', (WidgetTester tester) async {
      for (final String kind in <String>['NOTE', 'TIP', 'IMPORTANT', 'WARNING', 'CAUTION']) {
        await pumpAlert(tester, kind);
        expect(tester.takeException(), isNull, reason: '> [!$kind] must not crash');
      }
    });

    testWidgets('an alert does not swallow the rest of the document', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Markdown(
              data: '# Heading\n\n> [!NOTE]\n> alert body\n\nTrailing paragraph.',
              extensionSet: md.ExtensionSet.gitHubWeb,
            ),
          ),
        ),
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });
      expect(tester.takeException(), isNull);
      expect(find.text('Trailing paragraph.'), findsOneWidget);
    });
  });
}
