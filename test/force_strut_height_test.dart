// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

class _TallSyntax extends md.InlineSyntax {
  _TallSyntax() : super('TALL');
  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('tall', ''));
    return true;
  }
}

class _TallBuilder extends MarkdownElementBuilder {
  _TallBuilder(this.onTap);
  final VoidCallback onTap;
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) => Text.rich(
    TextSpan(
      children: <InlineSpan>[
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          // WidgetSpan applies the paragraph scaler to its child once.
          child: Builder(
            builder: (BuildContext context) => MediaQuery.withNoTextScaling(
              child: DefaultTextStyle(
                style: preferredStyle ?? const TextStyle(fontSize: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('a\nb\nc', key: ValueKey<String>('tall')),
                    TextButton(onPressed: onTap, child: const Text('Enlarge')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

void main() => defineTests();

void defineTests() {
  test('both public widgets preserve the default', () {
    expect(const Markdown(data: '').forceStrutHeight, isTrue);
    expect(const MarkdownBody(data: '').forceStrutHeight, isTrue);
  });

  for (final bool scrollable in <bool>[false, true]) {
    for (final double scale in <double>[1, 2]) {
      for (final TextDirection direction in TextDirection.values) {
        testWidgets('tall inline layout and cache update scroll=$scrollable scale=$scale direction=$direction', (
          WidgetTester tester,
        ) async {
          bool force = true;
          int taps = 0;
          late StateSetter update;
          final MarkdownStyleSheet style = MarkdownStyleSheet(p: const TextStyle(fontSize: 16, height: 1.2));
          final List<md.InlineSyntax> syntaxes = <md.InlineSyntax>[_TallSyntax()];
          final Map<String, MarkdownElementBuilder> builders = <String, MarkdownElementBuilder>{
            'tall': _TallBuilder(() => taps++),
          };
          TextDirection paragraphDirection(InlineSpan span) => direction;
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 300,
                      child: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          update = setState;
                          return scrollable
                              ? Markdown(
                                  key: const ValueKey<String>('reader'),
                                  padding: EdgeInsets.zero,
                                  data: 'Before TALL after with enough prose to wrap onto another line.',
                                  styleSheet: style,
                                  inlineSyntaxes: syntaxes,
                                  builders: builders,
                                  paragraphDirectionBuilder: paragraphDirection,
                                  forceStrutHeight: force,
                                )
                              : MarkdownBody(
                                  key: const ValueKey<String>('reader'),
                                  data: 'Before TALL after with enough prose to wrap onto another line.',
                                  styleSheet: style,
                                  inlineSyntaxes: syntaxes,
                                  builders: builders,
                                  paragraphDirectionBuilder: paragraphDirection,
                                  forceStrutHeight: force,
                                );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          final State<StatefulWidget> state = tester.state(find.byKey(const ValueKey<String>('reader')));
          final Finder paragraph = find.byWidgetPredicate(
            (Widget w) => w is RichText && w.text.toPlainText().startsWith('Before'),
          );
          final double forcedHeight = tester.getSize(paragraph).height;
          expect(tester.renderObject<RenderParagraph>(paragraph).strutStyle!.forceStrutHeight, isTrue);
          update(() => force = false);
          await tester.pumpAndSettle();
          expect(tester.state(find.byKey(const ValueKey<String>('reader'))), same(state));
          final RenderParagraph render = tester.renderObject<RenderParagraph>(paragraph);
          expect(render.strutStyle!.forceStrutHeight, isFalse);
          expect(render.textDirection, direction);
          expect(tester.getSize(paragraph).height, greaterThan(forcedHeight));
          final Rect bounds = tester.getRect(paragraph);
          final Rect tall = tester.getRect(find.byKey(const ValueKey<String>('tall')));
          final Rect button = tester.getRect(find.widgetWithText(TextButton, 'Enlarge'));
          expect(tall.top, greaterThanOrEqualTo(bounds.top - 1));
          expect(button.bottom, lessThanOrEqualTo(bounds.bottom + 1));
          expect(find.text('Enlarge').hitTestable(), findsOneWidget);
          await tester.tap(find.text('Enlarge'));
          expect(taps, 1);
          update(() => force = true);
          await tester.pumpAndSettle();
          expect(tester.getSize(paragraph).height, forcedHeight);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
