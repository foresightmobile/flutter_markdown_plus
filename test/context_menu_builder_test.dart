// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() => defineTests();

void defineTests() {
  group('contextMenuBuilder', () {
    testWidgets('uses the default context menu builder when omitted', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MarkdownBody(data: 'Selectable text', selectable: true)));

      final SelectableText text = tester.widget<SelectableText>(find.byType(SelectableText));

      expect(text.contextMenuBuilder, isNotNull);
    });

    testWidgets('can suppress the selectable text context menu', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MarkdownBody(data: 'Selectable text', selectable: true, contextMenuBuilder: null)),
      );

      final SelectableText text = tester.widget<SelectableText>(find.byType(SelectableText));

      expect(text.contextMenuBuilder, isNull);
    });

    testWidgets('passes a custom context menu builder to selectable text', (WidgetTester tester) async {
      Widget customContextMenuBuilder(BuildContext context, EditableTextState editableTextState) {
        return const SizedBox.shrink();
      }

      await tester.pumpWidget(
        MaterialApp(
          home: MarkdownBody(data: 'Selectable text', selectable: true, contextMenuBuilder: customContextMenuBuilder),
        ),
      );

      final SelectableText text = tester.widget<SelectableText>(find.byType(SelectableText));

      expect(text.contextMenuBuilder, same(customContextMenuBuilder));
    });

    testWidgets('selection callback receives rich text as plain text', (WidgetTester tester) async {
      String? selectedText;

      await tester.pumpWidget(
        MaterialApp(
          home: MarkdownBody(
            data: 'Selectable **rich** text',
            selectable: true,
            onSelectionChanged: (String? text, TextSelection selection, SelectionChangedCause? cause) {
              selectedText = text;
            },
          ),
        ),
      );

      final SelectableText text = tester.widget<SelectableText>(find.byType(SelectableText));
      text.onSelectionChanged?.call(const TextSelection(baseOffset: 0, extentOffset: 10), SelectionChangedCause.drag);

      expect(selectedText, 'Selectable rich text');
    });
  });

  // These tests pin down the behaviour change introduced with contextMenuBuilder:
  // onSelectionChanged now reports `TextSpan.toPlainText()` rather than the
  // top-level `TextSpan.text`. For any paragraph containing more than one inline
  // span (bold, italic, code, links, ...) the parent span is built as
  // `TextSpan(children: [...])` with a null `.text`, so the previous behaviour
  // handed callers `null`. The full plain text is what downstream selection UIs
  // actually need.
  group('onSelectionChanged plain text', () {
    // Invoke the SelectableText's own onSelectionChanged the way the framework
    // would, capturing what the MarkdownBody callback receives.
    Future<({String? reported, TextSpan? span})> selectAll(
      WidgetTester tester,
      String data,
    ) async {
      String? reported;
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MarkdownBody(
              data: data,
              selectable: true,
              onSelectionChanged: (String? text, TextSelection selection, SelectionChangedCause? cause) {
                reported = text;
              },
            ),
          ),
        ),
      );

      final SelectableText widget = tester.widget<SelectableText>(find.byType(SelectableText));
      final TextSpan? span = widget.textSpan;
      final int length = span?.toPlainText().length ?? 0;
      widget.onSelectionChanged?.call(
        TextSelection(baseOffset: 0, extentOffset: length),
        SelectionChangedCause.drag,
      );
      return (reported: reported, span: span);
    }

    testWidgets('plain-only paragraph is reported unchanged', (WidgetTester tester) async {
      final result = await selectAll(tester, 'Just some plain text');
      expect(result.reported, 'Just some plain text');
    });

    testWidgets('multiple mixed inline styles are fully concatenated', (WidgetTester tester) async {
      final result = await selectAll(tester, '**bold** _italic_ and `code`');

      // Regression guard: the parent span has no top-level text (it is built
      // from children), so the pre-change `text.text` path would have been null.
      expect(result.span?.text, isNull);
      expect(result.reported, 'bold italic and code');
    });

    testWidgets('link text is included in the reported plain text', (WidgetTester tester) async {
      final result = await selectAll(tester, 'Visit [our site](https://example.com) now');

      expect(result.span?.text, isNull);
      expect(result.reported, 'Visit our site now');
    });

    testWidgets('reported plain text is usable with TextSelection.textInside', (WidgetTester tester) async {
      String? reported;
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MarkdownBody(
              data: 'alpha **beta** gamma',
              selectable: true,
              onSelectionChanged: (String? text, TextSelection selection, SelectionChangedCause? cause) {
                reported = text;
              },
            ),
          ),
        ),
      );

      final SelectableText widget = tester.widget<SelectableText>(find.byType(SelectableText));
      // Select "beta" within "alpha beta gamma".
      const TextSelection selection = TextSelection(baseOffset: 6, extentOffset: 10);
      widget.onSelectionChanged?.call(selection, SelectionChangedCause.drag);

      expect(reported, 'alpha beta gamma');
      expect(selection.textInside(reported!), 'beta');
    });
  });
}
