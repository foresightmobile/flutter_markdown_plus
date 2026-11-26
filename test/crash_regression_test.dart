// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

import 'utils.dart';

void main() => defineTests();

/// Regression tests for crashes reported against the original
/// `flutter_markdown` package and migrated to this tracker: #59, #72, #62 and
/// #93. Each test replays the scenario from the original report and asserts
/// the crash does not come back.
void defineTests() {
  /// The plain text of every [RichText] on screen. `find.text` misses
  /// `RichText` built from nested spans, so match on this instead.
  Iterable<String> renderedText(WidgetTester tester) =>
      tester.allWidgets.whereType<RichText>().map((RichText w) => w.text.toPlainText());

  // The `div` block-builder test for #59 lives in `test/alert_div_builder_test.dart`
  // because `MarkdownBuilder` permanently adds block-builder tags to the global
  // `_kBlockTags` list; keeping it separate prevents `'div'` from leaking into
  // the non-builder `#59` test below under random test ordering.
  group('#59 alert syntax', () {
    testWidgets('the #59 sample (> [!NOTE] with gitHubWeb) does not throw', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Markdown(data: '> [!NOTE]\n> this does not work\n', extensionSet: md.ExtensionSet.gitHubWeb),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(renderedText(tester), anyElement(contains('this does not work')));
    });
  });

  group('#72 footnotes', () {
    testWidgets('the #72 sample (footnote with markup) does not throw', (WidgetTester tester) async {
      const String data = 'Footnote 1 link[^first].\n[^first]: Footnote **can have markup**\n';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownBody(
              styleSheet: MarkdownStyleSheet(h1Align: WrapAlignment.center, h2Align: WrapAlignment.end),
              data: data,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final Iterable<String> rendered = renderedText(tester);
      expect(rendered, anyElement(contains('Footnote 1 link1')));
      expect(rendered, anyElement(contains('Footnote can have markup')));
    });
  });

  group('#62 selectable without onSelectionChanged', () {
    testWidgets('selecting text with no onSelectionChanged does not throw', (WidgetTester tester) async {
      const String data = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MarkdownBody(data: data, selectable: true)),
        ),
      );

      // A tap moves the caret and a drag extends the selection; both report
      // through SelectableText.onSelectionChanged, where #62 hit
      // `onSelectionChanged!` on a null callback.
      final Offset start = positionInRenderedText(tester, data, 6);
      final Offset end = positionInRenderedText(tester, data, 17);
      await tester.tapAt(start);
      await tester.pump(const Duration(milliseconds: 500));
      final TestGesture gesture = await tester.startGesture(start, kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(end);
      await gesture.up();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('#93 custom block syntax with an inline builder', () {
    testWidgets('the #93 sample (custom tag at the root) does not throw', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Markdown(
            selectable: true,
            data: '# Just to showcase the bug\n\n<testTag />\n',
            extensionSet: md.ExtensionSet(md.ExtensionSet.gitHubFlavored.blockSyntaxes, <md.InlineSyntax>[
              md.EmojiSyntax(),
              ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
            ]),
            builders: <String, MarkdownElementBuilder>{_TestElementBuilder.id: _TestElementBuilder()},
            blockSyntaxes: <md.BlockSyntax>[_TestBlockSyntax(RegExp(r'<testTag([^>]*)/>'))],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      // The rest of the document still renders around the custom element.
      final Iterable<String> selectable = tester
          .widgetList<SelectableText>(find.byType(SelectableText))
          .map((SelectableText w) => w.textSpan!.toPlainText());
      expect(selectable, contains('Just to showcase the bug'));
      expect(find.text('Example'), findsOneWidget);
    });
  });
}

/// The block syntax from the #93 report: emits an empty custom element.
class _TestBlockSyntax extends md.BlockSyntax {
  _TestBlockSyntax(this.pattern);

  @override
  final RegExp pattern;

  @override
  md.Node? parse(md.BlockParser parser) {
    parser.advance();
    return md.Element(_TestElementBuilder.id, <md.Node>[]);
  }
}

/// The builder from the #93 report. It does not override `isBlockElement`, so
/// the custom element is treated as inline at the document root.
class _TestElementBuilder extends MarkdownElementBuilder {
  static const String id = 'aCustomElement';

  @override
  Widget visitElementAfter(md.Element? element, TextStyle? preferredStyle) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: Colors.black,
      padding: const EdgeInsets.all(5),
      child: const Text('Example', style: TextStyle(color: Colors.white)),
    );
  }
}
