// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cupertino_ui/cupertino_ui.dart' as cui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as mui;

void main() => defineTests();

// A distinctive primary colour, so that values taken from a default theme stand out.
const Color _primary = Color(0xFFFF8800);

const String _data = '''
Hello **world**

- [x] done
- [ ] todo

```
code that is long enough to need a horizontal scrollbar code that is long enough to need a horizontal scrollbar
```
''';

Widget _materialUiApp(Widget home) => mui.MaterialApp(
      theme: mui.ThemeData(),
      darkTheme: mui.ThemeData(colorScheme: const mui.ColorScheme.dark(primary: _primary)),
      themeMode: mui.ThemeMode.dark,
      home: mui.Scaffold(body: home),
    );

Widget _legacyApp(Widget home) => MaterialApp(
      theme: ThemeData(),
      darkTheme: ThemeData(colorScheme: const ColorScheme.dark(primary: _primary)),
      themeMode: ThemeMode.dark,
      home: Scaffold(body: home),
    );

EditableText _firstEditableText(WidgetTester tester) => tester.widget<EditableText>(find.byType(EditableText).first);

Color? _scrollbarThumbColor(WidgetTester tester) {
  for (final CustomPaint paint in tester.widgetList<CustomPaint>(find.byType(CustomPaint))) {
    final CustomPainter? painter = paint.foregroundPainter;
    if (painter is ScrollbarPainter) {
      return painter.color;
    }
  }
  return null;
}

Future<void> _openContextMenu(WidgetTester tester) async {
  await tester.longPress(find.byType(EditableText).first);
  await tester.pumpAndSettle();
}

void defineTests() {
  group('material_ui app', () {
    testWidgets('default style sheet follows the dark material_ui theme', (WidgetTester tester) async {
      await tester.pumpWidget(_materialUiApp(const MarkdownBody(data: _data, selectable: true)));
      final mui.ThemeData theme = mui.Theme.of(tester.element(find.byType(MarkdownBody)));
      expect(theme.brightness, Brightness.dark);

      expect(_firstEditableText(tester).style.color, theme.textTheme.bodyMedium!.color);

      // Task-list checkboxes are widgets-layer icons coloured by the style sheet.
      final List<Icon> icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons.map((Icon icon) => icon.icon), <IconData>[Icons.check_box, Icons.check_box_outline_blank]);
      expect(icons.map((Icon icon) => icon.color), everyElement(theme.primaryColor));
    });

    testWidgets('explicit fromMaterialUiTheme style sheet follows the dark material_ui theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(_materialUiApp(Builder(
        builder: (BuildContext context) => MarkdownBody(
          data: '> quote',
          styleSheet: MarkdownStyleSheet.fromMaterialUiTheme(mui.Theme.of(context)),
        ),
      )));
      final mui.ThemeData theme = mui.Theme.of(tester.element(find.byType(MarkdownBody)));

      final DecoratedBox quote = tester.widget(
        find.descendant(of: find.byType(MarkdownBody), matching: find.byType(DecoratedBox)).first,
      );
      final BoxDecoration decoration = quote.decoration as BoxDecoration;
      expect(decoration.color, theme.colorScheme.surfaceContainerHighest);
      expect((decoration.border! as Border).left.color, _primary);
      expect(tester.widget<RichText>(find.byType(RichText).first).text.style!.color, theme.textTheme.bodyMedium!.color);
    });

    testWidgets('selectable text uses material_ui and its theme', (WidgetTester tester) async {
      await tester.pumpWidget(_materialUiApp(const MarkdownBody(data: _data, selectable: true)));

      expect(find.byType(mui.SelectableText), findsWidgets);
      expect(find.byType(SelectableText), findsNothing);

      final EditableText editable = _firstEditableText(tester);
      expect(editable.cursorColor, _primary);
      expect(editable.selectionColor, _primary.withValues(alpha: 0.4));
      // The selection handles come from material_ui, so they are painted with its theme.
      expect(editable.selectionControls, same(mui.materialTextSelectionHandleControls));
    });

    testWidgets('code block scrollbar uses material_ui and matches a legacy app with the same theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(_legacyApp(const MarkdownBody(data: _data)));
      final Color? legacyThumb = _scrollbarThumbColor(tester);

      await tester.pumpWidget(_materialUiApp(const MarkdownBody(data: _data)));
      expect(find.byType(mui.Scrollbar), findsOneWidget);
      expect(find.byType(Scrollbar), findsNothing);
      expect(legacyThumb, isNotNull);
      expect(_scrollbarThumbColor(tester), legacyThumb);
    });

    testWidgets(
      'context menu opens without missing localizations',
      (WidgetTester tester) async {
        await tester.pumpWidget(_materialUiApp(const MarkdownBody(data: _data, selectable: true)));
        await _openContextMenu(tester);

        expect(tester.takeException(), isNull);
        expect(find.byType(mui.AdaptiveTextSelectionToolbar), findsOneWidget);
        expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.android, TargetPlatform.iOS}),
    );

    testWidgets('fixed-width table scrollbar uses material_ui', (WidgetTester tester) async {
      await tester.pumpWidget(_materialUiApp(MarkdownBody(
        data: '|a|b|\n|-|-|\n|1|2|',
        styleSheet: MarkdownStyleSheet(tableColumnWidth: const FixedColumnWidth(100)),
      )));
      expect(find.byType(mui.Scrollbar), findsOneWidget);
      expect(find.byType(Scrollbar), findsNothing);
    });
  });

  group('legacy app', () {
    testWidgets('keeps the legacy widgets', (WidgetTester tester) async {
      await tester.pumpWidget(_legacyApp(const MarkdownBody(data: _data, selectable: true)));

      expect(find.byType(SelectableText), findsWidgets);
      expect(find.byType(mui.SelectableText), findsNothing);
      expect(find.byType(Scrollbar), findsOneWidget);
      expect(find.byType(mui.Scrollbar), findsNothing);

      final ThemeData theme = Theme.of(tester.element(find.byType(MarkdownBody)));
      expect(_firstEditableText(tester).style.color, theme.textTheme.bodyMedium!.color);
      expect(_firstEditableText(tester).selectionControls, same(materialTextSelectionHandleControls));

      await _openContextMenu(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);
      expect(find.byType(mui.AdaptiveTextSelectionToolbar), findsNothing);
    });

    testWidgets('with a nested material_ui Theme keeps the legacy context menu', (WidgetTester tester) async {
      await tester.pumpWidget(_legacyApp(mui.Theme(
        data: mui.ThemeData(colorScheme: const mui.ColorScheme.dark(primary: _primary)),
        child: const MarkdownBody(data: _data, selectable: true),
      )));
      // The text follows the nested theme...
      expect(find.byType(mui.SelectableText), findsWidgets);
      expect(_firstEditableText(tester).cursorColor, _primary);

      // ...but only the legacy localizations exist, so the menu must stay legacy.
      await _openContextMenu(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);
    });
  });

  group('cupertino_ui app', () {
    testWidgets(
      'cupertino base theme follows the dark cupertino_ui theme',
      (WidgetTester tester) async {
        Widget app({required bool selectable}) => cui.CupertinoApp(
              theme: const cui.CupertinoThemeData(brightness: Brightness.dark, primaryColor: _primary),
              home: cui.CupertinoPageScaffold(
                child: MarkdownBody(
                  key: ValueKey<bool>(selectable),
                  data: '[link](https://flutter.dev)\n\n- [x] done',
                  selectable: selectable,
                  styleSheetTheme: MarkdownStyleSheetBaseTheme.cupertino,
                ),
              ),
            );

        await tester.pumpWidget(app(selectable: false));
        final RichText link = tester.widget(find.byType(RichText).first);
        final TextSpan linkSpan = (link.text as TextSpan).children!.single as TextSpan;
        expect(linkSpan.style!.color!.toARGB32(), CupertinoColors.link.darkColor.toARGB32());
        expect(tester.widget<Icon>(find.byType(Icon)).color!.toARGB32(), _primary.toARGB32());

        // There is no Material theme, so the selectable text uses material_ui and derives its theme from the
        // cupertino_ui theme.
        await tester.pumpWidget(app(selectable: true));
        expect(find.byType(mui.SelectableText), findsWidgets);
        expect(_firstEditableText(tester).cursorColor.toARGB32(), _primary.toARGB32());

        await _openContextMenu(tester);
        expect(tester.takeException(), isNull);
        expect(find.byType(mui.AdaptiveTextSelectionToolbar), findsOneWidget);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  });
}
