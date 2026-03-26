// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'utils.dart';

void main() => defineTests();

void defineTests() {
  group('Blockquote', () {
    testWidgets(
      'simple one word blockquote',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          boilerplate(
            const MarkdownBody(data: '> quote'),
          ),
        );

        final Iterable<Widget> widgets = tester.allWidgets;
        expectTextStrings(widgets, <String>['quote']);
      },
    );

    testWidgets(
      'soft wrapping in blockquote',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          boilerplate(
            const MarkdownBody(data: '> soft\n> wrap'),
          ),
        );

        final Iterable<Widget> widgets = tester.allWidgets;
        expectTextStrings(widgets, <String>['soft wrap']);
      },
    );

    testWidgets(
      'should work with styling',
      (WidgetTester tester) async {
        final ThemeData theme = ThemeData.light().copyWith(
          textTheme: textTheme,
        );
        final MarkdownStyleSheet styleSheet = MarkdownStyleSheet.fromTheme(
          theme,
        );

        const String data =
            '> this is a link: [Markdown guide](https://www.markdownguide.org) and this is **bold** and *italic*';
        await tester.pumpWidget(
          boilerplate(
            MarkdownBody(
              data: data,
              styleSheet: styleSheet,
            ),
          ),
        );

        final Iterable<Widget> widgets = tester.allWidgets;
        final DecoratedBox blockQuoteContainer = tester.widget(
          find.byType(DecoratedBox),
        );
        final Text quoteText = tester.widget(find.byType(Text));
        final List<TextSpan> styledTextParts = (quoteText.textSpan! as TextSpan).children!.cast<TextSpan>();

        expectTextStrings(
          widgets,
          <String>['this is a link: Markdown guide and this is bold and italic'],
        );
        expect(
          (blockQuoteContainer.decoration as BoxDecoration).color,
          (styleSheet.blockquoteDecoration as BoxDecoration?)!.color,
        );
        expect(
          (blockQuoteContainer.decoration as BoxDecoration).borderRadius,
          (styleSheet.blockquoteDecoration as BoxDecoration?)!.borderRadius,
        );

        /// this is a link
        expect(styledTextParts[0].text, 'this is a link: ');
        expect(
          styledTextParts[0].style!.color,
          theme.textTheme.bodyMedium!.color,
        );

        /// Markdown guide (link - should use link color)
        expect(styledTextParts[1].text, 'Markdown guide');
        expect(styledTextParts[1].style!.color, Colors.blue);

        /// and this is
        expect(styledTextParts[2].text, ' and this is ');
        expect(
          styledTextParts[2].style!.color,
          theme.textTheme.bodyMedium!.color,
        );

        /// bold (should be bold)
        expect(styledTextParts[3].text, 'bold');
        expect(styledTextParts[3].style!.fontWeight, FontWeight.bold);

        /// and
        expect(styledTextParts[4].text, ' and ');

        /// italic (should be italic)
        expect(styledTextParts[5].text, 'italic');
        expect(styledTextParts[5].style!.fontStyle, FontStyle.italic);
      },
    );

    testWidgets(
      'bold text in blockquote renders with bold font weight',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          boilerplate(
            const MarkdownBody(data: '> **bold text**'),
          ),
        );

        final Text quoteText = tester.widget(find.byType(Text));
        final TextSpan textSpan = quoteText.textSpan! as TextSpan;

        // The bold span is either the root span directly (when it's the only element)
        // or the first child span.
        final TextSpan boldSpan = textSpan.children != null ? textSpan.children!.cast<TextSpan>().first : textSpan;

        expect(boldSpan.text, 'bold text');
        expect(boldSpan.style!.fontWeight, FontWeight.bold);
      },
    );
  });
}
