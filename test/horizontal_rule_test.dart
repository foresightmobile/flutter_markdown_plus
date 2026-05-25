// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'utils.dart';

void main() => defineTests();

void defineTests() {
  group('Horizontal Rule', () {
    testWidgets(
      '3 consecutive hyphens',
      (WidgetTester tester) async {
        const String data = '---';
        await tester.pumpWidget(boilerplate(const MarkdownBody(data: data)));

        final Iterable<Widget> widgets = selfAndDescendantWidgetsOf(
          find.byType(MarkdownBody),
          tester,
        );
        expectWidgetTypes(widgets, <Type>[MarkdownBody, Container, DecoratedBox, Padding, LimitedBox, ConstrainedBox]);
      },
    );

    testWidgets(
      '5 consecutive hyphens',
      (WidgetTester tester) async {
        const String data = '-----';
        await tester.pumpWidget(boilerplate(const MarkdownBody(data: data)));

        final Iterable<Widget> widgets = selfAndDescendantWidgetsOf(
          find.byType(MarkdownBody),
          tester,
        );
        expectWidgetTypes(widgets, <Type>[MarkdownBody, Container, DecoratedBox, Padding, LimitedBox, ConstrainedBox]);
      },
    );

    testWidgets(
      '3 asterisks separated with spaces',
      (WidgetTester tester) async {
        const String data = '* * *';
        await tester.pumpWidget(boilerplate(const MarkdownBody(data: data)));

        final Iterable<Widget> widgets = selfAndDescendantWidgetsOf(
          find.byType(MarkdownBody),
          tester,
        );
        expectWidgetTypes(widgets, <Type>[MarkdownBody, Container, DecoratedBox, Padding, LimitedBox, ConstrainedBox]);
      },
    );

    testWidgets(
      '3 asterisks separated with spaces alongside text Markdown',
      (WidgetTester tester) async {
        const String data = '# h1\n ## h2\n* * *';
        await tester.pumpWidget(boilerplate(const MarkdownBody(data: data)));

        final Iterable<Widget> widgets = selfAndDescendantWidgetsOf(
          find.byType(MarkdownBody),
          tester,
        );
        expectWidgetTypes(widgets, <Type>[
          MarkdownBody,
          Column,
          Column,
          Wrap,
          Text,
          RichText,
          SizedBox,
          Column,
          Wrap,
          Text,
          RichText,
          SizedBox,
          Container,
          DecoratedBox,
          Padding,
          LimitedBox,
          ConstrainedBox
        ]);
      },
    );
    testWidgets(
      'custom builder for hr is respected',
      (WidgetTester tester) async {
        const String data = '---';
        await tester.pumpWidget(
          boilerplate(
            MarkdownBody(
              data: data,
              builders: <String, MarkdownElementBuilder>{
                'hr': _CustomHrBuilder(),
              },
            ),
          ),
        );

        expect(find.byType(ColoredBox), findsOneWidget);
        final ColoredBox box = tester.widget(find.byType(ColoredBox));
        expect(box.color, Colors.red);
      },
    );

    testWidgets(
      'paddingBuilders for hr is applied',
      (WidgetTester tester) async {
        const String data = '---';
        const double paddingX = 16.0;
        await tester.pumpWidget(
          boilerplate(
            MarkdownBody(
              data: data,
              paddingBuilders: <String, MarkdownPaddingBuilder>{
                'hr': _CustomPaddingBuilder(paddingX),
              },
            ),
          ),
        );

        final Finder paddingFinder = find.byType(Padding);
        final List<Padding> paddings = tester.widgetList<Padding>(paddingFinder).toList();
        final bool hasHrPadding = paddings.any(
          (Padding p) => p.padding.along(Axis.horizontal) == paddingX * 2,
        );
        expect(hasHrPadding, isTrue);
      },
    );
  });
}

class _CustomHrBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return const ColoredBox(color: Colors.red, child: SizedBox(height: 2, width: double.infinity));
  }
}

class _CustomPaddingBuilder extends MarkdownPaddingBuilder {
  _CustomPaddingBuilder(this.paddingX);

  final double paddingX;

  @override
  EdgeInsets getPadding() {
    return EdgeInsets.symmetric(horizontal: paddingX);
  }
}
