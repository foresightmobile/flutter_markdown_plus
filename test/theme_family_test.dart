// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cupertino_ui/cupertino_ui.dart' as cui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_markdown_plus/src/theme_family.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as mui;

import 'utils.dart';

void main() => defineTests();

const Color _legacyPrimary = Color(0xFF0000FF);
const Color _materialUiPrimary = Color(0xFFFF0000);
const Color _legacyCupertinoPrimary = Color(0xFF00FFFF);
const Color _cupertinoUiPrimary = Color(0xFFFFFF00);

Widget _legacyTheme(Widget child) => Theme(
      data: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: _legacyPrimary).copyWith(primary: _legacyPrimary)),
      child: child,
    );

Widget _materialUiTheme(Widget child) => mui.Theme(
      data: mui.ThemeData(
        colorScheme: mui.ColorScheme.fromSeed(seedColor: _materialUiPrimary).copyWith(primary: _materialUiPrimary),
      ),
      child: child,
    );

Widget _legacyCupertinoTheme(Widget child) => CupertinoTheme(
      data: const CupertinoThemeData(primaryColor: _legacyCupertinoPrimary),
      child: child,
    );

Widget _cupertinoUiTheme(Widget child) => cui.CupertinoTheme(
      data: const cui.CupertinoThemeData(primaryColor: _cupertinoUiPrimary),
      child: child,
    );

/// Pumps [wrap] around a probe and returns what both resolvers report at the probe.
Future<({bool material, bool cupertino})> _resolve(
  WidgetTester tester,
  Widget Function(Widget child) wrap,
) async {
  late BuildContext probe;
  await tester.pumpWidget(
    boilerplate(
      wrap(Builder(builder: (BuildContext context) {
        probe = context;
        return const SizedBox();
      })),
    ),
  );
  return (material: usesMaterialUiTheme(probe), cupertino: usesCupertinoUiTheme(probe));
}

/// The left border colour of the rendered blockquote, which the Material style sheets take from
/// `colorScheme.primary`.
Color _blockquoteBorderColor(WidgetTester tester) {
  final DecoratedBox box = tester.widget(
    find.descendant(of: find.byType(MarkdownBody), matching: find.byType(DecoratedBox)).first,
  );
  return ((box.decoration as BoxDecoration).border! as Border).left.color;
}

void defineTests() {
  group('Theme family', () {
    group('factory parity', () {
      // The material_ui factories must produce exactly what the legacy factories produce for the same theme.
      final Map<String, (ThemeData, mui.ThemeData)> themes = <String, (ThemeData, mui.ThemeData)>{
        'light': (ThemeData.light(), mui.ThemeData.light()),
        'dark': (ThemeData.dark(), mui.ThemeData.dark()),
        'seeded dark with a card colour': (
          ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00897B), brightness: Brightness.dark),
            cardTheme: const CardThemeData(color: Color(0xFF123456)),
          ),
          mui.ThemeData(
            colorScheme: mui.ColorScheme.fromSeed(seedColor: const Color(0xFF00897B), brightness: Brightness.dark),
            cardTheme: const mui.CardThemeData(color: Color(0xFF123456)),
          ),
        ),
      };

      // Theme.of localizes the text geometry (font sizes), which the factories rely on.
      ThemeData localized(ThemeData theme) => ThemeData.localize(theme, theme.typography.englishLike);
      mui.ThemeData localizedMaterialUi(mui.ThemeData theme) =>
          mui.ThemeData.localize(theme, theme.typography.englishLike);

      themes.forEach((String name, (ThemeData, mui.ThemeData) pair) {
        test('fromMaterialUiTheme matches fromTheme ($name)', () {
          final MarkdownStyleSheet legacy = MarkdownStyleSheet.fromTheme(localized(pair.$1));
          final MarkdownStyleSheet materialUi = MarkdownStyleSheet.fromMaterialUiTheme(localizedMaterialUi(pair.$2));
          expect(materialUi.styles, legacy.styles);
          expect(materialUi, legacy);
        });

        test('largeFromMaterialUiTheme matches largeFromTheme ($name)', () {
          final MarkdownStyleSheet legacy = MarkdownStyleSheet.largeFromTheme(localized(pair.$1));
          final MarkdownStyleSheet materialUi =
              MarkdownStyleSheet.largeFromMaterialUiTheme(localizedMaterialUi(pair.$2));
          expect(materialUi.styles, legacy.styles);
          expect(materialUi, legacy);
        });
      });

      // cupertino_ui has its own CupertinoDynamicColor class, so compare the colours the styles resolve to.
      Map<String, (TextStyle?, int?)> resolvedStyles(MarkdownStyleSheet sheet) => sheet.styles.map(
            (String tag, TextStyle? style) => MapEntry<String, (TextStyle?, int?)>(
              tag,
              (style?.copyWith(color: const Color(0x00000000)), style?.color?.toARGB32()),
            ),
          );

      for (final Brightness brightness in Brightness.values) {
        testWidgets('fromCupertinoUiTheme matches fromCupertinoTheme (${brightness.name})',
            (WidgetTester tester) async {
          late CupertinoThemeData legacyTheme;
          late cui.CupertinoThemeData cupertinoUiTheme;
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(platformBrightness: brightness),
              child: CupertinoTheme(
                data: const CupertinoThemeData(primaryColor: _legacyCupertinoPrimary),
                child: cui.CupertinoTheme(
                  data: const cui.CupertinoThemeData(primaryColor: _legacyCupertinoPrimary),
                  child: Builder(builder: (BuildContext context) {
                    legacyTheme = CupertinoTheme.of(context);
                    cupertinoUiTheme = cui.CupertinoTheme.of(context);
                    return const SizedBox();
                  }),
                ),
              ),
            ),
          );
          final MarkdownStyleSheet legacy = MarkdownStyleSheet.fromCupertinoTheme(legacyTheme);
          final MarkdownStyleSheet cupertinoUi = MarkdownStyleSheet.fromCupertinoUiTheme(cupertinoUiTheme);
          expect(resolvedStyles(cupertinoUi), resolvedStyles(legacy));
          expect(cupertinoUi.checkbox!.color!.toARGB32(), _legacyCupertinoPrimary.toARGB32());
          expect(cupertinoUi.tableCellsDecoration, legacy.tableCellsDecoration);
          expect(cupertinoUi.blockquoteDecoration, legacy.blockquoteDecoration);
          expect(cupertinoUi.codeblockDecoration, legacy.codeblockDecoration);
          expect(cupertinoUi.horizontalRuleDecoration, legacy.horizontalRuleDecoration);
          expect(cupertinoUi.tableBorder, legacy.tableBorder);
        });
      }
    });

    group('resolution', () {
      final Map<String, (Widget Function(Widget), bool, bool)> cases = <String, (Widget Function(Widget), bool, bool)>{
        // name: (tree, uses material_ui Theme, uses cupertino_ui CupertinoTheme)
        'no theme': ((Widget c) => c, false, false),
        'legacy Theme': (_legacyTheme, false, false),
        'material_ui Theme': (_materialUiTheme, true, true),
        'legacy CupertinoTheme': (_legacyCupertinoTheme, false, false),
        'cupertino_ui CupertinoTheme': (_cupertinoUiTheme, true, true),
        'legacy Theme inside material_ui Theme': ((Widget c) => _materialUiTheme(_legacyTheme(c)), false, false),
        'material_ui Theme inside legacy Theme': ((Widget c) => _legacyTheme(_materialUiTheme(c)), true, true),
        'cupertino_ui CupertinoTheme inside legacy Theme': (
          (Widget c) => _legacyTheme(_cupertinoUiTheme(c)),
          false,
          true,
        ),
        'legacy CupertinoTheme inside material_ui Theme': (
          (Widget c) => _materialUiTheme(_legacyCupertinoTheme(c)),
          true,
          false,
        ),
        'legacy CupertinoTheme inside cupertino_ui CupertinoTheme': (
          (Widget c) => _cupertinoUiTheme(_legacyCupertinoTheme(c)),
          false,
          false,
        ),
        'cupertino_ui CupertinoTheme inside legacy CupertinoTheme': (
          (Widget c) => _legacyCupertinoTheme(_cupertinoUiTheme(c)),
          true,
          true,
        ),
      };

      cases.forEach((String name, (Widget Function(Widget), bool, bool) testCase) {
        testWidgets(name, (WidgetTester tester) async {
          final ({bool material, bool cupertino}) result = await _resolve(tester, testCase.$1);
          expect(result.material, testCase.$2, reason: 'usesMaterialUiTheme');
          expect(result.cupertino, testCase.$3, reason: 'usesCupertinoUiTheme');
        });
      });
    });

    group('default style sheet', () {
      const String quote = '> quote';

      testWidgets('without any theme matches 1.0.x', (WidgetTester tester) async {
        await tester.pumpWidget(boilerplate(const MarkdownBody(data: quote)));
        expect(_blockquoteBorderColor(tester), ThemeData.fallback().colorScheme.primary);
      });

      testWidgets('legacy Theme', (WidgetTester tester) async {
        await tester.pumpWidget(boilerplate(_legacyTheme(const MarkdownBody(data: quote))));
        expect(_blockquoteBorderColor(tester), _legacyPrimary);
      });

      testWidgets('material_ui Theme', (WidgetTester tester) async {
        await tester.pumpWidget(boilerplate(_materialUiTheme(const MarkdownBody(data: quote))));
        expect(_blockquoteBorderColor(tester), _materialUiPrimary);
      });

      testWidgets('material_ui Theme inside a legacy Theme', (WidgetTester tester) async {
        await tester.pumpWidget(boilerplate(_legacyTheme(_materialUiTheme(const MarkdownBody(data: quote)))));
        expect(_blockquoteBorderColor(tester), _materialUiPrimary);
      });

      testWidgets('cupertino_ui CupertinoTheme inside a legacy Theme keeps the legacy Material theme',
          (WidgetTester tester) async {
        await tester.pumpWidget(boilerplate(_legacyTheme(_cupertinoUiTheme(const MarkdownBody(data: quote)))));
        expect(_blockquoteBorderColor(tester), _legacyPrimary);
      });

      testWidgets('cupertino_ui CupertinoTheme alone derives the Material theme from it', (WidgetTester tester) async {
        await tester.pumpWidget(boilerplate(_cupertinoUiTheme(const MarkdownBody(data: quote))));
        expect(_blockquoteBorderColor(tester), _cupertinoUiPrimary);
      });

      testWidgets('legacy CupertinoTheme alone derives the Material theme from it', (WidgetTester tester) async {
        await tester.pumpWidget(boilerplate(_legacyCupertinoTheme(const MarkdownBody(data: quote))));
        expect(_blockquoteBorderColor(tester), _legacyCupertinoPrimary);
      });

      testWidgets('cupertino base theme follows the nearest Cupertino theme', (WidgetTester tester) async {
        // The checkbox style takes the Cupertino primary colour.
        Color checkboxColor() => tester.widget<Icon>(find.byType(Icon)).color!;
        const MarkdownBody body =
            MarkdownBody(data: '- [x] done', styleSheetTheme: MarkdownStyleSheetBaseTheme.cupertino);

        await tester.pumpWidget(boilerplate(_legacyCupertinoTheme(_cupertinoUiTheme(body))));
        expect(checkboxColor(), _cupertinoUiPrimary);

        await tester.pumpWidget(boilerplate(_cupertinoUiTheme(_legacyCupertinoTheme(body))));
        expect(checkboxColor(), _legacyCupertinoPrimary);

        await tester.pumpWidget(boilerplate(_materialUiTheme(body)));
        expect(checkboxColor(), _materialUiPrimary);
      });
    });
  });
}
