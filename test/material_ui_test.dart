// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cupertino_ui/cupertino_ui.dart' as cui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as mui;
import 'utils.dart';

void main() => defineTests();

const TextStyle _materialUiBody = TextStyle(color: Color(0xFFFF0000), fontSize: 13.0);
const TextStyle _legacyBody = TextStyle(color: Color(0xFF0000FF), fontSize: 13.0);

void defineTests() {
  group('material_ui', () {
    testWidgets(
      'MarkdownStyleSheet.fromMaterialUiTheme',
      (WidgetTester tester) async {
        final mui.ThemeData theme = mui.ThemeData.light().copyWith(
          textTheme: const mui.TextTheme(bodyMedium: TextStyle(fontSize: 12.0)),
        );

        final MarkdownStyleSheet style = MarkdownStyleSheet.fromMaterialUiTheme(theme);

        expect(style.p, theme.textTheme.bodyMedium);
        expect(style.code!.fontSize, 12.0 * 0.85);
        expect(style.h1, theme.textTheme.headlineSmall);
        expect(style.tableBorder!.top.color, theme.dividerColor);
        expect(style.blockquoteDecoration, isA<BoxDecoration>());
        expect((style.blockquoteDecoration! as BoxDecoration).color, theme.colorScheme.surfaceContainerHighest);
      },
    );

    testWidgets(
      'MarkdownStyleSheet.largeFromMaterialUiTheme',
      (WidgetTester tester) async {
        final mui.ThemeData theme = mui.ThemeData.light().copyWith(
          textTheme: const mui.TextTheme(
            bodyMedium: TextStyle(fontSize: 12.0),
            displayMedium: TextStyle(fontSize: 45.0),
            titleMedium: TextStyle(fontSize: 16.0),
          ),
        );

        final MarkdownStyleSheet style = MarkdownStyleSheet.largeFromMaterialUiTheme(theme);

        expect(style.p, theme.textTheme.bodyMedium);
        expect(style.h1, theme.textTheme.displayMedium);
        expect(style.h6, theme.textTheme.titleMedium);
      },
    );

    testWidgets(
      'MarkdownStyleSheet.fromCupertinoUiTheme',
      (WidgetTester tester) async {
        const cui.CupertinoThemeData theme = cui.CupertinoThemeData(brightness: Brightness.dark);

        final MarkdownStyleSheet style = MarkdownStyleSheet.fromCupertinoUiTheme(theme);

        expect(style.a!.color, CupertinoColors.link.darkColor);
        expect(style.p, theme.textTheme.textStyle);
        expect(style.h1!.fontSize, theme.textTheme.textStyle.fontSize! + 10);
      },
    );

    testWidgets(
      'default style sheet uses the material_ui Theme',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          boilerplate(
            mui.Theme(
              data: mui.ThemeData(textTheme: const mui.TextTheme(bodyMedium: _materialUiBody)),
              child: const MarkdownBody(data: 'Hello'),
            ),
          ),
        );

        final Text widget = tester.widget(find.byType(Text));
        expect(widget.textSpan!.style!.color, _materialUiBody.color);
      },
    );

    testWidgets(
      'default style sheet still uses the legacy Theme',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          boilerplate(
            Theme(
              data: ThemeData(textTheme: const TextTheme(bodyMedium: _legacyBody)),
              child: const MarkdownBody(data: 'Hello'),
            ),
          ),
        );

        final Text widget = tester.widget(find.byType(Text));
        expect(widget.textSpan!.style!.color, _legacyBody.color);
      },
    );

    testWidgets(
      'default style sheet uses the nearest Theme',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          boilerplate(
            mui.Theme(
              data: mui.ThemeData(textTheme: const mui.TextTheme(bodyMedium: _materialUiBody)),
              child: Theme(
                data: ThemeData(textTheme: const TextTheme(bodyMedium: _legacyBody)),
                child: const MarkdownBody(data: 'Hello'),
              ),
            ),
          ),
        );

        final Text widget = tester.widget(find.byType(Text));
        expect(widget.textSpan!.style!.color, _legacyBody.color);
      },
    );

    testWidgets(
      'cupertino base theme uses the cupertino_ui CupertinoTheme',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          boilerplate(
            const cui.CupertinoTheme(
              data: cui.CupertinoThemeData(
                textTheme: cui.CupertinoTextThemeData(textStyle: _materialUiBody),
              ),
              child: MarkdownBody(
                data: 'Hello',
                styleSheetTheme: MarkdownStyleSheetBaseTheme.cupertino,
              ),
            ),
          ),
        );

        final Text widget = tester.widget(find.byType(Text));
        expect(widget.textSpan!.style!.color, _materialUiBody.color);
      },
    );
  });
}
