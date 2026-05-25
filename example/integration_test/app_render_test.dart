// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_example/main.dart' as app;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'markdown_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('flutter_markdown_plus on-device rendering', () {
    testWidgets('tapping a link fires onTapLink with the href', (WidgetTester tester) async {
      String? tappedHref;
      await tester.pumpWidget(
        buildMarkdownApp(
          data: '[tap me](https://example.com)',
          onTapLink: (String text, String? href, String title) => tappedHref = href,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('tap me'));
      await tester.pumpAndSettle();

      expect(tappedHref, 'https://example.com');
    });

    testWidgets('a long document scrolls to reveal off-screen content', (WidgetTester tester) async {
      final StringBuffer buffer = StringBuffer();
      for (int i = 0; i < 80; i++) {
        buffer.writeln('Paragraph $i with enough text to occupy vertical space on screen.');
        buffer.writeln();
      }
      buffer.writeln('THE_BOTTOM_SENTINEL');

      await tester.pumpWidget(buildMarkdownApp(data: buffer.toString()));
      await tester.pumpAndSettle();

      // The sentinel is below the fold and the ListView has not built it yet.
      expect(find.text('THE_BOTTOM_SENTINEL'), findsNothing);

      await tester.drag(find.byType(Markdown), const Offset(0, -8000));
      await tester.pumpAndSettle();

      expect(find.text('THE_BOTTOM_SENTINEL'), findsOneWidget);
    });

    testWidgets('GFM task list renders checkbox icons', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildMarkdownBodyApp(data: '- [ ] todo item\n- [x] done item'),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
      expect(find.byIcon(Icons.check_box), findsOneWidget);
      expect(find.text('todo item'), findsOneWidget);
      expect(find.text('done item'), findsOneWidget);
    });

    testWidgets('selectable markdown surfaces the selection toolbar on long press', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildMarkdownApp(
          data: 'A selectable paragraph of text.',
          selectable: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.textContaining('selectable paragraph'));
      await tester.pumpAndSettle();

      // The Material selection toolbar exposes a Copy action once text is selected.
      expect(find.text('Copy'), findsWidgets);
    });

    testWidgets('the example app launches and lists its demos', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.text('Markdown Demos'), findsOneWidget);
    });
  });
}
