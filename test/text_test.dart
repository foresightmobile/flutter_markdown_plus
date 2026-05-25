// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils.dart';

void main() => defineTests();

void defineTests() {
  group('Data', () {
    testWidgets(
      'simple data',
      (WidgetTester tester) async {
        // extract to variable; if run with --track-widget-creation using const
        // widgets aren't necessarily identical if created on different lines.
        const Markdown markdown = Markdown(data: 'Data1');

        await tester.pumpWidget(boilerplate(markdown));
        expectTextStrings(tester.allWidgets, <String>['Data1']);

        final String stateBefore = dumpRenderView();
        await tester.pumpWidget(boilerplate(markdown));
        final String stateAfter = dumpRenderView();
        expect(stateBefore, equals(stateAfter));

        await tester.pumpWidget(boilerplate(const Markdown(data: 'Data2')));
        expectTextStrings(tester.allWidgets, <String>['Data2']);
      },
    );
  });

  group('Text', () {
    testWidgets(
      'Empty string',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          boilerplate(
            const MarkdownBody(data: ''),
          ),
        );

        final Iterable<Widget> widgets = selfAndDescendantWidgetsOf(
          find.byType(MarkdownBody),
          tester,
        );
        expectWidgetTypes(widgets, <Type>[
          MarkdownBody,
          Column,
        ]);
      },
    );

    testWidgets(
      'Simple string',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          boilerplate(
            const MarkdownBody(data: 'Hello'),
          ),
        );

        final Iterable<Widget> widgets = selfAndDescendantWidgetsOf(
          find.byType(MarkdownBody),
          tester,
        );
        expectWidgetTypes(widgets, <Type>[
          MarkdownBody,
          Column,
          Wrap,
          Text,
          RichText,
        ]);
        expectTextStrings(widgets, <String>['Hello']);
      },
    );
  });

  group('Leading spaces', () {
    testWidgets(
        // Example 192 from the GitHub Flavored Markdown specification.
        'leading space are ignored', (WidgetTester tester) async {
      const String data = '  aaa\n bbb';
      await tester.pumpWidget(
        boilerplate(
          const MarkdownBody(data: data),
        ),
      );

      final Iterable<Widget> widgets = selfAndDescendantWidgetsOf(
        find.byType(MarkdownBody),
        tester,
      );
      expectWidgetTypes(widgets, <Type>[
        MarkdownBody,
        Column,
        Wrap,
        Text,
        RichText,
      ]);
      expectTextStrings(widgets, <String>['aaa bbb']);
    });
  });

  group('Line Break', () {
    testWidgets(
      // Example 654 from the GitHub Flavored Markdown specification.
      'two spaces at end of line inside a block element',
      (WidgetTester tester) async {
        const String data = 'line 1  \nline 2';
        await tester.pumpWidget(
          boilerplate(
            const MarkdownBody(data: data),
          ),
        );

        final Iterable<Widget> widgets = selfAndDescendantWidgetsOf(
          find.byType(MarkdownBody),
          tester,
        );
        expectWidgetTypes(widgets, <Type>[MarkdownBody, Column, Wrap, Text, RichText]);
        expectTextStrings(widgets, <String>['line 1\nline 2']);
      },
    );

    testWidgets(
      // Example 655 from the GitHub Flavored Markdown specification.
      'backslash at end of line inside a block element',
      (WidgetTester tester) async {
        const String data = 'line 1\\\nline 2';
        await tester.pumpWidget(
          boilerplate(
            const MarkdownBody(data: data),
          ),
        );

        final Iterable<Widget> widgets = selfAndDescendantWidgetsOf(
          find.byType(MarkdownBody),
          tester,
        );
        expectWidgetTypes(widgets, <Type>[MarkdownBody, Column, Wrap, Text, RichText]);
        expectTextStrings(widgets, <String>['line 1\nline 2']);
      },
    );

    testWidgets(
      'non-applicable line break',
      (WidgetTester tester) async {
        const String data = 'line 1.\nline 2.';
        await tester.pumpWidget(
          boilerplate(
            const MarkdownBody(data: data),
          ),
        );

        final Iterable<Widget> widgets = selfAndDescendantWidgetsOf(
          find.byType(MarkdownBody),
          tester,
        );
        expectWidgetTypes(widgets, <Type>[
          MarkdownBody,
          Column,
          Wrap,
          Text,
          RichText,
        ]);
        expectTextStrings(widgets, <String>['line 1. line 2.']);
      },
    );

    testWidgets(
      'non-applicable line break',
      (WidgetTester tester) async {
        const String data = 'line 1.\nline 2.';
        await tester.pumpWidget(
          boilerplate(
            const MarkdownBody(data: data),
          ),
        );

        final Iterable<Widget> widgets = selfAndDescendantWidgetsOf(
          find.byType(MarkdownBody),
          tester,
        );
        expectWidgetTypes(widgets, <Type>[
          MarkdownBody,
          Column,
          Wrap,
          Text,
          RichText,
        ]);
        expectTextStrings(widgets, <String>['line 1. line 2.']);
      },
    );

    testWidgets(
      'soft line break',
      (WidgetTester tester) async {
        const String data = 'line 1.\nline 2.';
        await tester.pumpWidget(
          boilerplate(
            const MarkdownBody(
              data: data,
              softLineBreak: true,
            ),
          ),
        );

        final Iterable<Widget> widgets = selfAndDescendantWidgetsOf(
          find.byType(MarkdownBody),
          tester,
        );
        expectWidgetTypes(widgets, <Type>[MarkdownBody, Column, Wrap, Text, RichText]);
        expectTextStrings(widgets, <String>['line 1.\nline 2.']);
      },
    );
  });

  group('Selectable', () {
    testWidgets(
      'header with line of text',
      (WidgetTester tester) async {
        const String data = '# Title\nHello _World_!';
        await tester.pumpWidget(
          boilerplate(
            const MediaQuery(
              data: MediaQueryData(),
              child: Markdown(
                data: data,
                selectable: true,
              ),
            ),
          ),
        );

        expect(find.byType(SelectableText), findsNWidgets(2));
      },
    );

    testWidgets(
      'header with line of text and onTap callback',
      (WidgetTester tester) async {
        const String data = '# Title\nHello _World_!';
        String? textTapResults;

        await tester.pumpWidget(
          boilerplate(
            MediaQuery(
              data: const MediaQueryData(),
              child: Markdown(
                data: data,
                selectable: true,
                onTapText: () => textTapResults = 'Text has been tapped.',
              ),
            ),
          ),
        );

        final Iterable<Widget> selectableWidgets = tester.widgetList(find.byType(SelectableText));
        expect(selectableWidgets.length, 2);

        final SelectableText selectableTitle = selectableWidgets.first as SelectableText;
        expect(selectableTitle, isNotNull);
        expect(selectableTitle.onTap, isNotNull);
        selectableTitle.onTap!();
        expect(textTapResults == 'Text has been tapped.', true);

        textTapResults = null;
        final SelectableText selectableText = selectableWidgets.last as SelectableText;
        expect(selectableText, isNotNull);
        expect(selectableText.onTap, isNotNull);
        selectableText.onTap!();
        expect(textTapResults == 'Text has been tapped.', true);
      },
    );

    testWidgets(
      'Selectable without onSelectionChanged',
      (WidgetTester tester) async {
        const String data = '# abc def ghi\njkl opq';

        await tester.pumpWidget(
          const MaterialApp(
            home: Material(
              child: MarkdownBody(
                data: data,
                selectable: true,
              ),
            ),
          ),
        );

        // Find the positions before character 'd' and 'f'.
        final Offset dPos = positionInRenderedText(tester, 'abc def ghi', 4);
        final Offset fPos = positionInRenderedText(tester, 'abc def ghi', 6);
        // Select from 'd' until 'f'.
        final TestGesture firstGesture = await tester.startGesture(dPos, kind: PointerDeviceKind.mouse);
        addTearDown(firstGesture.removePointer);
        await tester.pump();
        await firstGesture.moveTo(fPos);
        await firstGesture.up();
        await tester.pump();

        // Find the positions before character 'j' and 'o'.
        final Offset jPos = positionInRenderedText(tester, 'jkl opq', 0);
        final Offset oPos = positionInRenderedText(tester, 'jkl opq', 4);
        // Select from 'j' until 'o'.
        final TestGesture secondGesture = await tester.startGesture(jPos, kind: PointerDeviceKind.mouse);
        addTearDown(secondGesture.removePointer);
        await tester.pump();
        await secondGesture.moveTo(oPos);
        await secondGesture.up();
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'header with line of text and onSelectionChanged callback',
      (WidgetTester tester) async {
        const String data = '# abc def ghi\njkl opq';
        String? selectableText;
        String? selectedText;
        void onSelectionChanged(String? text, TextSelection selection, SelectionChangedCause? cause) {
          selectableText = text;
          selectedText = text != null ? selection.textInside(text) : null;
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: MarkdownBody(
                data: data,
                selectable: true,
                onSelectionChanged: onSelectionChanged,
              ),
            ),
          ),
        );

        // Find the positions before character 'd' and 'f'.
        final Offset dPos = positionInRenderedText(tester, 'abc def ghi', 4);
        final Offset fPos = positionInRenderedText(tester, 'abc def ghi', 6);
        // Select from 'd' until 'f'.
        final TestGesture firstGesture = await tester.startGesture(dPos, kind: PointerDeviceKind.mouse);
        addTearDown(firstGesture.removePointer);
        await tester.pump();
        await firstGesture.moveTo(fPos);
        await firstGesture.up();
        await tester.pump();

        expect(selectableText, 'abc def ghi');
        expect(selectedText, 'de');

        // Find the positions before character 'j' and 'o'.
        final Offset jPos = positionInRenderedText(tester, 'jkl opq', 0);
        final Offset oPos = positionInRenderedText(tester, 'jkl opq', 4);
        // Select from 'j' until 'o'.
        final TestGesture secondGesture = await tester.startGesture(jPos, kind: PointerDeviceKind.mouse);
        addTearDown(secondGesture.removePointer);
        await tester.pump();
        await secondGesture.moveTo(oPos);
        await secondGesture.up();
        await tester.pump();

        expect(selectableText, 'jkl opq');
        expect(selectedText, 'jkl ');
      },
    );
  });

  group('Strikethrough', () {
    testWidgets('single word', (WidgetTester tester) async {
      const String data = '~~strikethrough~~';
      await tester.pumpWidget(
        boilerplate(
          const MarkdownBody(data: data),
        ),
      );

      final Iterable<Widget> widgets = selfAndDescendantWidgetsOf(
        find.byType(MarkdownBody),
        tester,
      );
      expectWidgetTypes(widgets, <Type>[
        MarkdownBody,
        Column,
        Wrap,
        Text,
        RichText,
      ]);
      expectTextStrings(widgets, <String>['strikethrough']);
    });
  });

  group('Strut style', () {
    testWidgets(
      'paragraph rich text forces a consistent strut height across font weights',
      (WidgetTester tester) async {
        // A bold span should not change the paragraph line height. The builder
        // applies a forced strut height derived from the span's base style so
        // the line height is consistent regardless of font weight (see PR #130).
        const double paragraphFontSize = 17.0;
        final MarkdownStyleSheet styleSheet = MarkdownStyleSheet(
          p: const TextStyle(fontSize: paragraphFontSize, height: 1.5),
        );

        await tester.pumpWidget(
          boilerplate(
            MarkdownBody(
              data: 'normal **bold** text',
              styleSheet: styleSheet,
            ),
          ),
        );

        final Text text = tester.widget<Text>(find.byType(Text));
        expect(text.strutStyle, isNotNull);
        expect(text.strutStyle!.forceStrutHeight, isTrue);
        expect(text.strutStyle!.fontSize, paragraphFontSize);
        expect(text.strutStyle!.height, 1.5);
      },
    );

    testWidgets(
      'header strut is derived from the header style, not the paragraph style',
      (WidgetTester tester) async {
        // Regression guard: _buildRichText is the generic rich-text builder used
        // for headers/blockquotes/list items as well as paragraphs. The strut
        // must follow each block's own style so a large header is not forced
        // down to the (smaller) paragraph size, which would clip the header.
        const double headerFontSize = 32.0;
        const double paragraphFontSize = 14.0;
        final ThemeData theme = ThemeData.light().copyWith(textTheme: textTheme);
        final MarkdownStyleSheet styleSheet = MarkdownStyleSheet.fromTheme(theme).merge(
          MarkdownStyleSheet(
            h1: const TextStyle(fontSize: headerFontSize),
            p: const TextStyle(fontSize: paragraphFontSize),
          ),
        );

        await tester.pumpWidget(
          boilerplate(
            MarkdownBody(
              data: '# Heading\n\nbody',
              styleSheet: styleSheet,
            ),
          ),
        );

        // The first Text is the header, the second is the paragraph body.
        final List<Text> texts = tester.widgetList<Text>(find.byType(Text)).toList();
        expect(texts.length, 2);

        final Text headerText = texts.first;
        final Text bodyText = texts.last;

        expect(headerText.strutStyle, isNotNull);
        expect(headerText.strutStyle!.forceStrutHeight, isTrue);
        expect(headerText.strutStyle!.fontSize, headerFontSize);

        expect(bodyText.strutStyle, isNotNull);
        expect(bodyText.strutStyle!.fontSize, paragraphFontSize);

        // The header strut must be taller than the paragraph strut, otherwise
        // the header text would be vertically clipped.
        expect(headerText.strutStyle!.fontSize! > bodyText.strutStyle!.fontSize!, isTrue);
      },
    );
  });
}
