// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() => defineTests();

const String _english = 'Hello **world** [link](https://example.org).';
const String _arabic = 'مرحبا **بالعالم** [رابط](https://example.org).';

TextDirection _direction(InlineSpan span) =>
    span.toPlainText(includeSemanticsLabels: false).startsWith('مرحبا') ? TextDirection.rtl : TextDirection.ltr;

Widget _host(Widget child, TextDirection direction) => MaterialApp(
      home: Scaffold(body: Directionality(textDirection: direction, child: child)),
    );

Iterable<TextSpan> _textSpans(InlineSpan span) sync* {
  if (span is TextSpan) {
    yield span;
    for (final InlineSpan child in span.children ?? <InlineSpan>[]) {
      yield* _textSpans(child);
    }
  }
}

void defineTests() {
  for (final bool scrollable in <bool>[false, true]) {
    for (final bool selectable in <bool>[false, true]) {
      for (final TextDirection ambient in TextDirection.values) {
        testWidgets('mounted callback updates scrollable=$scrollable selectable=$selectable ambient=$ambient',
            (WidgetTester tester) async {
          const String data = 'Hello [link](https://example.org).';
          const Key key = ValueKey<String>('markdown');
          final MarkdownStyleSheet style = MarkdownStyleSheet(p: const TextStyle(fontSize: 16));
          final List<MarkdownParagraphDirectionBuilder?> callbacks = <MarkdownParagraphDirectionBuilder?>[
            null,
            (InlineSpan span) => TextDirection.ltr,
            (InlineSpan span) => TextDirection.rtl,
            null,
            (InlineSpan span) => TextDirection.rtl,
            (InlineSpan span) => null,
          ];
          final List<TextDirection> expected = <TextDirection>[
            ambient,
            TextDirection.ltr,
            TextDirection.rtl,
            ambient,
            TextDirection.rtl,
            ambient
          ];
          int step = 0;
          int taps = 0;
          late StateSetter rebuild;
          void onTapLink(String text, String? href, String title) {
            expect(href, 'https://example.org');
            taps++;
          }

          await tester.pumpWidget(_host(StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
            rebuild = setState;
            return scrollable
                ? Markdown(
                    key: key,
                    data: data,
                    styleSheet: style,
                    selectable: selectable,
                    paragraphDirectionBuilder: callbacks[step],
                    onTapLink: onTapLink)
                : MarkdownBody(
                    key: key,
                    data: data,
                    styleSheet: style,
                    selectable: selectable,
                    paragraphDirectionBuilder: callbacks[step],
                    onTapLink: onTapLink);
          }), ambient));
          final State<StatefulWidget> originalState = tester.state(find.byKey(key));
          for (int next = 0; next < callbacks.length; next++) {
            if (next > 0) {
              rebuild(() => step = next);
              await tester.pump();
            }
            expect(tester.state(find.byKey(key)), same(originalState));
            final MarkdownWidget mounted = tester.widget<MarkdownWidget>(find.byKey(key));
            expect(mounted.data, data);
            expect(mounted.styleSheet, same(style));
            if (selectable) {
              final RenderEditable editable = tester.state<EditableTextState>(find.byType(EditableText)).renderEditable;
              expect(editable.textDirection, expected[next], reason: 'update step $next');
              final Rect box =
                  editable.getBoxesForSelection(const TextSelection(baseOffset: 6, extentOffset: 10)).first.toRect();
              await tester.tapAt(editable.localToGlobal(box.center));
            } else {
              final Finder rendered = find.descendant(of: find.byKey(key), matching: find.byType(RichText));
              expect(tester.renderObject<RenderParagraph>(rendered).textDirection, expected[next],
                  reason: 'update step $next');
              await tester.tapOnText(find.textRange.ofSubstring('link'));
            }
            await tester.pump();
            expect(taps, next + 1, reason: 'exactly one link callback after each update');
            expect(tester.takeException(), isNull);
          }
        });
      }
    }
  }
  for (final bool selectable in <bool>[false, true]) {
    for (final TextDirection ambient in TextDirection.values) {
      for (final bool reverse in <bool>[false, true]) {
        final List<String> paragraphs = reverse ? <String>[_arabic, _english] : <String>[_english, _arabic];
        final String a = paragraphs[0];
        final String b = paragraphs[1];
        final Map<String, String> cases = <String, String>{
          'plain': '$a\n\n$b',
          'tight list': '- $a\n- $b',
          'loose list': '- $a\n\n  $b',
          'quote': '> $a\n>\n> $b',
          'quote in list': '- > $a\n  >\n  > $b',
        };
        for (final MapEntry<String, String> entry in cases.entries) {
          testWidgets('${entry.key}, selectable=$selectable, ambient=$ambient, reverse=$reverse',
              (WidgetTester tester) async {
            final List<InlineSpan> seen = <InlineSpan>[];
            await tester.pumpWidget(_host(
              MarkdownBody(
                data: entry.value,
                selectable: selectable,
                paragraphDirectionBuilder: (InlineSpan span) {
                  seen.add(span);
                  return _direction(span);
                },
              ),
              ambient,
            ));
            expect(seen, hasLength(2));
            expect(
                seen.map(_direction),
                reverse
                    ? <TextDirection>[TextDirection.rtl, TextDirection.ltr]
                    : <TextDirection>[TextDirection.ltr, TextDirection.rtl]);
            for (final InlineSpan span in seen) {
              final Finder text = find.byWidgetPredicate((Widget widget) => selectable
                  ? widget is SelectableText && identical(widget.textSpan, span)
                  : widget is Text && identical(widget.textSpan, span));
              expect(text, findsOneWidget, reason: 'Render the assembled span unchanged');
              final Finder rendered =
                  find.descendant(of: text, matching: find.byType(selectable ? EditableText : RichText));
              if (selectable) {
                final RenderEditable editable = tester.state<EditableTextState>(rendered).renderEditable;
                expect(editable.textDirection, _direction(span));
              } else {
                expect(tester.renderObject<RenderParagraph>(rendered).textDirection, _direction(span));
              }
              expect(_textSpans(span).any((TextSpan part) => part.style?.fontWeight == FontWeight.bold), isTrue);
              expect(_textSpans(span).where((TextSpan part) => part.recognizer is TapGestureRecognizer), hasLength(1));
            }
            expect(tester.takeException(), isNull);
          });
        }
      }
      for (final bool useNullCallback in <bool>[false, true]) {
        testWidgets('inherits $ambient selectable=$selectable callback=$useNullCallback', (WidgetTester tester) async {
          await tester.pumpWidget(_host(
              MarkdownBody(
                data: '$_english\n\n$_arabic',
                selectable: selectable,
                paragraphDirectionBuilder: useNullCallback ? (InlineSpan span) => null : null,
              ),
              ambient));
          if (selectable) {
            expect(
                tester
                    .stateList<EditableTextState>(find.byType(EditableText))
                    .map((EditableTextState s) => s.renderEditable.textDirection),
                everyElement(ambient));
          } else {
            expect(
                tester
                    .renderObjectList<RenderParagraph>(find.byType(RichText))
                    .map((RenderParagraph p) => p.textDirection),
                everyElement(ambient));
          }
        });
      }
    }
    testWidgets('start alignment uses paragraph direction, selectable=$selectable', (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        SizedBox(
            width: 600,
            child: MarkdownBody(
              data: 'Hello.\n\nمرحبا.',
              selectable: selectable,
              fitContent: false,
              paragraphDirectionBuilder: _direction,
            )),
        TextDirection.ltr,
      ));
      for (final String text in <String>['Hello.', 'مرحبا.']) {
        final Finder widget = find.byWidgetPredicate((Widget w) => selectable
            ? w is SelectableText && w.textSpan?.toPlainText() == text
            : w is Text && w.textSpan?.toPlainText() == text);
        final Rect bounds = tester.getRect(widget);
        if (text == 'Hello.') {
          expect(bounds.left, closeTo(0, 0.1));
        } else {
          expect(bounds.right, closeTo(600, 0.1));
        }
      }
    });
    testWidgets('preserves tappable link and inline code, selectable=$selectable', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(_host(
          MarkdownBody(
            data: 'Hello [link](https://example.org), `code`.',
            selectable: selectable,
            paragraphDirectionBuilder: (InlineSpan span) => TextDirection.rtl,
            onTapLink: (String text, String? href, String title) {
              expect(href, 'https://example.org');
              taps++;
            },
          ),
          TextDirection.ltr));
      if (selectable) {
        final RenderEditable editable = tester.state<EditableTextState>(find.byType(EditableText)).renderEditable;
        final Rect box =
            editable.getBoxesForSelection(const TextSelection(baseOffset: 6, extentOffset: 10)).first.toRect();
        await tester.tapAt(editable.localToGlobal(box.center));
      } else {
        await tester.tapOnText(find.textRange.ofSubstring('link'));
      }
      expect(taps, 1);
      final InlineSpan span = selectable
          ? tester.widget<SelectableText>(find.byType(SelectableText)).textSpan!
          : tester.widget<Text>(find.byWidgetPredicate((Widget w) => w is Text && w.textSpan != null)).textSpan!;
      expect(span.toPlainText(), 'Hello link, code.');
      expect(_textSpans(span).singleWhere((TextSpan s) => s.text == 'code').style?.fontFamily, 'monospace');
    });
    testWidgets('excludes heading, fenced code and table, selectable=$selectable', (WidgetTester tester) async {
      final List<String> seen = <String>[];
      await tester.pumpWidget(_host(
          MarkdownBody(
            data: '# Heading\n\n```\ncode\n```\n\n| Column |\n| --- |\n| Cell |\n\nHello.',
            selectable: selectable,
            paragraphDirectionBuilder: (InlineSpan span) {
              seen.add(span.toPlainText());
              return TextDirection.rtl;
            },
          ),
          TextDirection.ltr));
      expect(seen, <String>['Hello.']);
    });
    testWidgets('text separated by image shares direction, selectable=$selectable', (WidgetTester tester) async {
      final List<InlineSpan> seen = <InlineSpan>[];
      await tester.pumpWidget(_host(
          MarkdownBody(
            data: 'Hello ![alt](image.png) world.',
            selectable: selectable,
            imageBuilder: (Uri uri, String? title, String? alt) => const SizedBox(width: 12, height: 12),
            paragraphDirectionBuilder: (InlineSpan span) {
              seen.add(span);
              return TextDirection.rtl;
            },
          ),
          TextDirection.ltr));
      expect(seen, hasLength(1));
      expect(seen.single.toPlainText(), 'Hello  world.');
      final List<InlineSpan> children = (seen.single as TextSpan).children!;
      expect(children, hasLength(2));
      for (final InlineSpan span in children) {
        final Finder text = find.byWidgetPredicate((Widget w) =>
            selectable ? w is SelectableText && identical(w.textSpan, span) : w is Text && identical(w.textSpan, span));
        expect(text, findsOneWidget);
        expect(Directionality.of(tester.element(text)), TextDirection.rtl);
      }
    });
  }
}
