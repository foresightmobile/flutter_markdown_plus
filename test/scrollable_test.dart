// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'utils.dart';

void main() => defineTests();

void defineTests() {
  group('Scrollable', () {
    testWidgets('code block', (WidgetTester tester) async {
      const String data = "```\nvoid main() {\n  print('Hello World!');\n}\n```";

      await tester.pumpWidget(
        boilerplate(
          const MediaQuery(
            data: MediaQueryData(),
            child: MarkdownBody(data: data),
          ),
        ),
      );

      final Iterable<Widget> widgets = tester.allWidgets;
      final Iterable<SingleChildScrollView> scrollViews = widgets.whereType<SingleChildScrollView>();
      expect(scrollViews, isNotEmpty);
      expect(scrollViews.first.controller, isNotNull);
    });

    testWidgets('two code blocks use different scroll controllers', (WidgetTester tester) async {
      const String data =
          "```\nvoid main() {\n  print('Hello World!');\n}\n```"
          '\n'
          "```\nvoid main() {\n  print('Hello World!');\n}\n```";

      await tester.pumpWidget(
        boilerplate(
          const MediaQuery(
            data: MediaQueryData(),
            child: MarkdownBody(data: data),
          ),
        ),
      );

      final Iterable<Widget> widgets = tester.allWidgets;
      final Iterable<SingleChildScrollView> scrollViews = widgets.whereType<SingleChildScrollView>();
      expect(scrollViews, hasLength(2));
      expect(scrollViews.first.controller, isNotNull);
      expect(scrollViews.last.controller, isNotNull);
      expect(scrollViews.first.controller, isNot(equals(scrollViews.last.controller)));
    });

    // Regression test for #63: a single ScrollController shared by every code
    // block is attached to more than one ScrollPosition as soon as the markdown
    // holds two or more `pre` blocks, so the first horizontal scroll throws
    // "The provided ScrollController is attached to more than one ScrollPosition."
    // Each code block must own its controller and scroll on its own. The bug was
    // reported on macOS and Windows, where the scrollbar is interactive and the
    // assertion runs; the default test platform (android) suppresses it, so the
    // theme platform is set to match.
    testWidgets('multiple code blocks scroll horizontally independently (#63)', (WidgetTester tester) async {
      final String data = '```\n${'a' * 400}\n```\n\n```\n${'b' * 400}\n```';

      await tester.pumpWidget(
        boilerplate(
          Theme(
            data: ThemeData(platform: TargetPlatform.macOS),
            child: MediaQuery(
              data: const MediaQueryData(size: Size(400, 600)),
              child: MarkdownBody(data: data),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      final List<SingleChildScrollView> scrollViews = tester.allWidgets.whereType<SingleChildScrollView>().toList();
      expect(scrollViews, hasLength(2));

      // Scroll the first code block horizontally; the reported crash fires here.
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(-200, 0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // The second code block must not have moved. This is what makes the two
      // blocks independent rather than merely separately addressed, and it is
      // the only part of this test that would catch a shared controller on
      // TargetPlatform.android, where the Scrollbar assertion is suppressed.
      expect(scrollViews[0].controller!.position.pixels, greaterThan(0.0));
      expect(scrollViews[1].controller!.position.pixels, 0.0);

      await tester.drag(find.byType(SingleChildScrollView).last, const Offset(-150, 0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(scrollViews[1].controller!.position.pixels, greaterThan(0.0));

      // Each code block owns its own controller.
      expect(scrollViews[0].controller, isNotNull);
      expect(scrollViews[1].controller, isNotNull);
      expect(scrollViews[0].controller, isNot(same(scrollViews[1].controller)));
    });

    testWidgets('controller', (WidgetTester tester) async {
      final ScrollController controller = ScrollController(initialScrollOffset: 209.0);
      addTearDown(controller.dispose);

      await tester.pumpWidget(boilerplate(Markdown(controller: controller, data: '')));

      double realOffset() {
        return tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
      }

      expect(controller.offset, equals(209.0));
      expect(realOffset(), equals(controller.offset));
    });

    testWidgets('Scrollable wrapping', (WidgetTester tester) async {
      await tester.pumpWidget(boilerplate(const Markdown(data: '')));

      final List<Widget> widgets = selfAndDescendantWidgetsOf(find.byType(Markdown), tester).toList();
      expectWidgetTypes(widgets.take(2), <Type>[Markdown, ListView]);
      expectWidgetTypes(widgets.reversed.take(2).toList().reversed, <Type>[SliverPadding, SliverList]);
    });

    testWidgets('table with fixed column width', (WidgetTester tester) async {
      const String data =
          '|Header 1|Header 2|Header 3|'
          '\n|-----|-----|-----|'
          '\n|Col 1|Col 2|Col 3|';
      await tester.pumpWidget(
        boilerplate(
          MediaQuery(
            data: const MediaQueryData(),
            child: MarkdownBody(
              data: data,
              styleSheet: MarkdownStyleSheet(tableColumnWidth: const FixedColumnWidth(150)),
            ),
          ),
        ),
      );

      final Iterable<Widget> widgets = tester.allWidgets;
      final Iterable<SingleChildScrollView> scrollViews = widgets.whereType<SingleChildScrollView>();
      expect(scrollViews, isNotEmpty);
      expect(scrollViews.first.controller, isNotNull);
    });

    testWidgets('table with intrinsic column width', (WidgetTester tester) async {
      const String data =
          '|Header 1|Header 2|Header 3|'
          '\n|-----|-----|-----|'
          '\n|Col 1|Col 2|Col 3|';
      await tester.pumpWidget(
        boilerplate(
          MediaQuery(
            data: const MediaQueryData(),
            child: MarkdownBody(
              data: data,
              styleSheet: MarkdownStyleSheet(tableColumnWidth: const IntrinsicColumnWidth()),
            ),
          ),
        ),
      );

      final Iterable<Widget> widgets = tester.allWidgets;
      final Iterable<SingleChildScrollView> scrollViews = widgets.whereType<SingleChildScrollView>();
      expect(scrollViews, isNotEmpty);
      expect(scrollViews.first.controller, isNotNull);
    });

    testWidgets('two tables use different scroll controllers', (WidgetTester tester) async {
      const String data =
          '|Header 1|Header 2|Header 3|'
          '\n|-----|-----|-----|'
          '\n|Col 1|Col 2|Col 3|'
          '\n'
          '\n|Header 1|Header 2|Header 3|'
          '\n|-----|-----|-----|'
          '\n|Col 1|Col 2|Col 3|';

      await tester.pumpWidget(
        boilerplate(
          MediaQuery(
            data: const MediaQueryData(),
            child: MarkdownBody(
              data: data,
              styleSheet: MarkdownStyleSheet(tableColumnWidth: const FixedColumnWidth(150)),
            ),
          ),
        ),
      );

      final Iterable<Widget> widgets = tester.allWidgets;
      final Iterable<SingleChildScrollView> scrollViews = widgets.whereType<SingleChildScrollView>();
      expect(scrollViews, hasLength(2));
      expect(scrollViews.first.controller, isNotNull);
      expect(scrollViews.last.controller, isNotNull);
      expect(scrollViews.first.controller, isNot(equals(scrollViews.last.controller)));
    });

    testWidgets('noScroll renders content in a non-scrolling Column', (WidgetTester tester) async {
      const String data = '# A\n\npara one\n\npara two';

      await tester.pumpWidget(boilerplate(const Markdown(data: data, noScroll: true)));

      // No scroll view should be present when noScroll is true.
      expect(find.byType(Scrollable), findsNothing);

      // The content should be laid out in at least one Column.
      expect(find.byType(Column), findsWidgets);

      // Each direct child rendered by the noScroll branch is wrapped in Padding.
      final Finder columnFinder = find.descendant(of: find.byType(Markdown), matching: find.byType(Column));
      final Column column = tester.widgetList<Column>(columnFinder).first;
      expect(column.children, isNotEmpty);
      for (final Widget child in column.children) {
        expect(child, isA<Padding>());
      }
    });

    testWidgets('noScroll defaults to false and keeps the scrolling ListView', (WidgetTester tester) async {
      const String data = '# A\n\npara one\n\npara two';

      await tester.pumpWidget(boilerplate(const Markdown(data: data)));

      // With default args the ListView still scrolls.
      expect(find.byType(Scrollable), findsOneWidget);
    });
  });
}
