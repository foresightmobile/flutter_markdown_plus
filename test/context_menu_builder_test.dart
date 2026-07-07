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
}
