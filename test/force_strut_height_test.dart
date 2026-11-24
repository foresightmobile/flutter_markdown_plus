// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

void main() => defineTests();

/// Inline syntax whose match renders a tall [WidgetSpan], so tests can put an
/// inline widget inside a prose block.
class _TallSyntax extends md.InlineSyntax {
  _TallSyntax() : super('TALL');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('tall', ''));
    return true;
  }
}

class _TallBuilder extends MarkdownElementBuilder {
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
        child: SizedBox(key: ValueKey<String>('tall'), width: 24, height: 80),
      ),
    );
  }
}

/// Like [_TallBuilder] but with a tappable button, so tests can prove the
/// inline widget is still reachable when it expands its line.
class _TallButtonBuilder extends MarkdownElementBuilder {
  _TallButtonBuilder(this.onTap);

  final VoidCallback onTap;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            // WidgetSpan applies the paragraph's text scaler to its child once,
            // so opt out to keep the tappable button at a stable size.
            child: MediaQuery.withNoTextScaling(
              child: DefaultTextStyle(
                style: preferredStyle ?? const TextStyle(fontSize: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(key: ValueKey<String>('tall'), width: 24, height: 80),
                    TextButton(onPressed: onTap, child: const Text('Enlarge')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StubDelegate implements MarkdownBuilderDelegate {
  @override
  BuildContext get context => throw UnsupportedError('not needed');

  @override
  GestureRecognizer createLink(String text, String? href, String title) => throw UnsupportedError('not needed');

  @override
  TextSpan formatText(MarkdownStyleSheet styleSheet, String code) => TextSpan(text: code);
}

MarkdownBuilder _builder({bool forceStrutHeight = true}) => MarkdownBuilder(
      delegate: _StubDelegate(),
      selectable: false,
      styleSheet: MarkdownStyleSheet(),
      imageDirectory: null,
      imageBuilder: null,
      checkboxBuilder: null,
      bulletBuilder: null,
      builders: const <String, MarkdownElementBuilder>{},
      paddingBuilders: const <String, MarkdownPaddingBuilder>{},
      listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.baseline,
      forceStrutHeight: forceStrutHeight,
    );

StrutStyle _strutStyle(WidgetTester tester, bool selectable) => selectable
    ? tester.widget<SelectableText>(find.byType(SelectableText).first).strutStyle!
    : tester.widget<Text>(find.byType(Text).first).strutStyle!;

void defineTests() {
  final MarkdownStyleSheet style = MarkdownStyleSheet(p: const TextStyle(fontSize: 16, height: 1.2));
  const String plainData = 'Plain prose laid out across enough words to wrap onto another line.';
  const String tallData = 'Before TALL after with enough prose to wrap onto another line.';
  final List<md.InlineSyntax> tallSyntaxes = <md.InlineSyntax>[_TallSyntax()];
  final Map<String, MarkdownElementBuilder> tallBuilders = <String, MarkdownElementBuilder>{'tall': _TallBuilder()};

  test('the flag defaults to true on every public entry point', () {
    expect(const Markdown(data: '').forceStrutHeight, isTrue);
    expect(const MarkdownBody(data: '').forceStrutHeight, isTrue);
    expect(_builder().forceStrutHeight, isTrue);
    expect(_builder(forceStrutHeight: false).forceStrutHeight, isFalse);
  });

  group('strut is forced only when the flag is on and the block has no WidgetSpan', () {
    for (final bool force in <bool>[true, false]) {
      for (final bool tall in <bool>[false, true]) {
        for (final bool selectable in <bool>[false, true]) {
          for (final double scale in <double>[1, 2]) {
            testWidgets('force=$force widgetSpan=$tall selectable=$selectable scale=$scale', (
              WidgetTester tester,
            ) async {
              await tester.pumpWidget(
                MaterialApp(
                  home: Scaffold(
                    body: MediaQuery(
                      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: 300,
                          child: MarkdownBody(
                            data: tall ? tallData : plainData,
                            selectable: selectable,
                            styleSheet: style,
                            forceStrutHeight: force,
                            inlineSyntaxes: tallSyntaxes,
                            builders: tallBuilders,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );

              final StrutStyle strut = _strutStyle(tester, selectable);
              // The strut still applies as a minimum line height either way.
              expect(strut.fontSize, 16);
              expect(strut.height, 1.2);
              expect(strut.forceStrutHeight, force && !tall);
              expect(tester.takeException(), isNull);
            });
          }
        }
      }
    }

    testWidgets('default flag with an inline widget present does not force the strut', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 300,
                child: MarkdownBody(
                  data: tallData,
                  styleSheet: style,
                  inlineSyntaxes: tallSyntaxes,
                  builders: tallBuilders,
                ),
              ),
            ),
          ),
        ),
      );

      expect(const MarkdownBody(data: '').forceStrutHeight, isTrue);
      expect(_strutStyle(tester, false).forceStrutHeight, isFalse);
      expect(tester.takeException(), isNull);
    });
  });

  group('tall inline layout and cache update', () {
    for (final bool scrollable in <bool>[false, true]) {
      for (final double scale in <double>[1, 2]) {
        testWidgets('scroll=$scrollable scale=$scale', (WidgetTester tester) async {
          // MarkdownBody does not scroll, so give the surface enough room for
          // the prose at the larger text scales.
          await tester.binding.setSurfaceSize(const Size(400, 2400));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          bool force = true;
          int taps = 0;
          late StateSetter update;
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
                                  data: '$plainData\n\n$tallData',
                                  styleSheet: style,
                                  inlineSyntaxes: tallSyntaxes,
                                  builders: <String, MarkdownElementBuilder>{
                                    'tall': _TallButtonBuilder(() => taps++),
                                  },
                                  forceStrutHeight: force,
                                )
                              : MarkdownBody(
                                  key: const ValueKey<String>('reader'),
                                  data: '$plainData\n\n$tallData',
                                  styleSheet: style,
                                  inlineSyntaxes: tallSyntaxes,
                                  builders: <String, MarkdownElementBuilder>{
                                    'tall': _TallButtonBuilder(() => taps++),
                                  },
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
          final Finder plain = find.byWidgetPredicate(
            (Widget w) => w is Text && (w.textSpan?.toPlainText() ?? '').startsWith('Plain'),
          );
          final Finder tall = find.byWidgetPredicate(
            (Widget w) => w is Text && (w.textSpan?.toPlainText() ?? '').startsWith('Before'),
          );
          expect(plain, findsOneWidget);
          expect(tall, findsOneWidget);

          // A text-only block is forced; a block with a WidgetSpan never is.
          final double forcedPlainHeight = tester.getSize(plain).height;
          final double tallHeight = tester.getSize(tall).height;
          expect(tester.widget<Text>(plain).strutStyle!.forceStrutHeight, isTrue);
          expect(tester.widget<Text>(tall).strutStyle!.forceStrutHeight, isFalse);
          expect(tester.renderObject<RenderParagraph>(plain).strutStyle!.forceStrutHeight, isTrue);

          // The tall inline widget must not be clipped by the block.
          final Rect tallBounds = tester.getRect(find.byKey(const ValueKey<String>('tall')));
          final Rect buttonBounds = tester.getRect(find.widgetWithText(TextButton, 'Enlarge'));
          expect(tallBounds.height, greaterThanOrEqualTo(80));
          expect(tallBounds.top, greaterThanOrEqualTo(tester.getRect(tall).top - 1));
          expect(buttonBounds.bottom, lessThanOrEqualTo(tester.getRect(tall).bottom + 1));

          update(() => force = false);
          await tester.pumpAndSettle();

          // Changing the flag re-parses without losing the element state.
          expect(tester.state(find.byKey(const ValueKey<String>('reader'))), same(state));
          expect(tester.widget<Text>(plain).strutStyle!.forceStrutHeight, isFalse);
          expect(tester.widget<Text>(tall).strutStyle!.forceStrutHeight, isFalse);
          // The StrutStyle still applies as a minimum line height.
          expect(tester.widget<Text>(plain).strutStyle!.height, 1.2);
          // The tall block is unchanged: a WidgetSpan already opted out.
          expect(tester.getSize(tall).height, tallHeight);

          expect(find.text('Enlarge').hitTestable(), findsOneWidget);
          await tester.tap(find.text('Enlarge'));
          expect(taps, 1);

          update(() => force = true);
          await tester.pumpAndSettle();
          expect(tester.widget<Text>(plain).strutStyle!.forceStrutHeight, isTrue);
          expect(tester.widget<Text>(tall).strutStyle!.forceStrutHeight, isFalse);
          expect(tester.getSize(plain).height, forcedPlainHeight);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
