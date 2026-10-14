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
  group('InlineWidget', () {
    testWidgets(
      'Test inline widget',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          boilerplate(
            MarkdownBody(
              data: 'Hello, foo bar',
              builders: <String, MarkdownElementBuilder>{
                'sub': SubscriptBuilder(),
              },
              extensionSet: md.ExtensionSet(
                <md.BlockSyntax>[],
                <md.InlineSyntax>[SubscriptSyntax()],
              ),
            ),
          ),
        );

        final Text textWidget = tester.firstWidget(find.byType(Text));
        final TextSpan span = textWidget.textSpan! as TextSpan;

        final TextSpan part1 = span.children![0] as TextSpan;
        expect(part1.toPlainText(), 'Hello, ');

        final WidgetSpan part2 = span.children![1] as WidgetSpan;
        expect(part2.alignment, PlaceholderAlignment.middle);
        expect(part2.child, isA<Text>());
        expect((part2.child as Text).data, 'foo');

        final TextSpan part3 = span.children![2] as TextSpan;
        expect(part3.toPlainText(), ' bar');
      },
    );

    for (final bool selectable in <bool>[false, true]) {
      group(selectable ? 'selectable' : 'non-selectable', () {
        testWidgets('tall widgets expand paragraph height', (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MarkdownBody(
                  data: 'Hello, foo bar',
                  selectable: selectable,
                  styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 12, height: 1.5)),
                  builders: <String, MarkdownElementBuilder>{'sub': _TallWidgetBuilder()},
                  inlineSyntaxes: <md.InlineSyntax>[SubscriptSyntax()],
                ),
              ),
            ),
          );

          final Finder paragraph = _paragraph(selectable);
          expect(_strutStyle(tester, selectable)!.forceStrutHeight, isFalse);
          final Rect paragraphBounds = tester.getRect(paragraph);
          final Rect widgetBounds = tester.getRect(find.byKey(const ValueKey<String>('tall-inline')));
          expect(widgetBounds.height, 80);
          expect(paragraphBounds.top, lessThanOrEqualTo(widgetBounds.top));
          expect(paragraphBounds.bottom, greaterThanOrEqualTo(widgetBounds.bottom));
          expect(tester.takeException(), isNull);
        });

        testWidgets('nested widgets expand highlighted text', (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MarkdownBody(
                  data: '```\nfoo\n```',
                  selectable: selectable,
                  syntaxHighlighter: _NestedWidgetHighlighter(),
                ),
              ),
            ),
          );

          expect(_strutStyle(tester, selectable)!.forceStrutHeight, isFalse);
          expect(tester.getSize(_paragraph(selectable)).height, greaterThanOrEqualTo(80));
          expect(find.byKey(const ValueKey<String>('tall-inline')), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('text keeps fixed strut height', (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MarkdownBody(
                  data: 'normal **bold** text',
                  selectable: selectable,
                  styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 12, height: 1.5)),
                ),
              ),
            ),
          );

          final StrutStyle? strut = _strutStyle(tester, selectable);
          expect(strut, isNotNull);
          expect(strut!.forceStrutHeight, isTrue);
          expect(strut.fontSize, 12);
          expect(strut.height, 1.5);
          expect(strut.leading, 0);
        });
      });
    }
  });
}

Finder _paragraph(bool selectable) =>
    find.descendant(of: find.byType(MarkdownBody), matching: find.byType(selectable ? SelectableText : Text)).first;

StrutStyle? _strutStyle(WidgetTester tester, bool selectable) => selectable
    ? tester.widget<SelectableText>(_paragraph(selectable)).strutStyle
    : tester.widget<Text>(_paragraph(selectable)).strutStyle;

class _TallWidgetBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return const Text.rich(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: SizedBox(key: ValueKey<String>('tall-inline'), width: 24, height: 80),
      ),
    );
  }
}

class _NestedWidgetHighlighter extends SyntaxHighlighter {
  @override
  TextSpan format(String source) => const TextSpan(
        style: TextStyle(fontSize: 12, height: 1.5),
        children: <InlineSpan>[
          TextSpan(
            children: <InlineSpan>[
              TextSpan(
                children: <InlineSpan>[
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: SizedBox(key: ValueKey<String>('tall-inline'), width: 24, height: 80),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
}

class SubscriptBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return Text.rich(WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Text(element.textContent),
    ));
  }
}

class SubscriptSyntax extends md.InlineSyntax {
  SubscriptSyntax() : super(_pattern);

  static const String _pattern = r'(foo)';

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('sub', match[1]!));
    return true;
  }
}
