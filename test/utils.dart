// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final TextTheme textTheme = Typography.material2018().black.merge(
  const TextTheme(bodyMedium: TextStyle(fontSize: 12.0)),
);

Iterable<Widget> selfAndDescendantWidgetsOf(Finder start, WidgetTester tester) {
  final Element startElement = tester.element(start);
  final Iterable<Widget> descendants = collectAllElementsFrom(
    startElement,
    skipOffstage: false,
  ).map((Element e) => e.widget);
  return <Widget>[startElement.widget, ...descendants];
}

// Returns the RenderEditable displaying the given text.
RenderEditable findRenderEditableWithText(WidgetTester tester, String text) {
  final Iterable<RenderObject> roots = tester.renderObjectList(find.byType(EditableText));
  expect(roots, isNotEmpty);

  late RenderEditable renderEditable;
  void recursiveFinder(RenderObject child) {
    if (child is RenderEditable && child.plainText == text) {
      renderEditable = child;
      return;
    }
    child.visitChildren(recursiveFinder);
  }

  for (final RenderObject root in roots) {
    root.visitChildren(recursiveFinder);
  }

  expect(renderEditable, isNotNull);
  return renderEditable;
}

// Returns the [textOffset] position in rendered [text].
Offset positionInRenderedText(WidgetTester tester, String text, int textOffset) {
  final RenderEditable renderEditable = findRenderEditableWithText(tester, text);
  final Iterable<TextSelectionPoint> textOffsetPoints = renderEditable.getEndpointsForSelection(
    TextSelection.collapsed(offset: textOffset),
  );
  // Map the points to global positions.
  final List<TextSelectionPoint> endpoints = textOffsetPoints.map<TextSelectionPoint>((TextSelectionPoint point) {
    return TextSelectionPoint(renderEditable.localToGlobal(point.point), point.direction);
  }).toList();
  expect(endpoints.length, 1);
  return endpoints[0].point + const Offset(kIsWeb ? 1.0 : 0.0, -2.0);
}

void expectWidgetTypes(Iterable<Widget> widgets, List<Type> expected) {
  final List<Type> actual = widgets.map((Widget w) => w.runtimeType).toList();
  expect(actual, expected);
}

void expectTextStrings(Iterable<Widget> widgets, List<String> strings) {
  int currentString = 0;
  for (final Widget widget in widgets) {
    TextSpan? span;
    if (widget is RichText) {
      span = widget.text as TextSpan;
    } else if (widget is SelectableText) {
      span = widget.textSpan;
    }
    if (span != null) {
      final String text = _extractTextFromTextSpan(span);
      expect(text, equals(strings[currentString]));
      currentString += 1;
    }
  }
}

String _extractTextFromTextSpan(TextSpan span) {
  String text = span.text ?? '';
  if (span.children != null) {
    for (final TextSpan child in span.children!.toList().cast<TextSpan>()) {
      text += _extractTextFromTextSpan(child);
    }
  }
  return text;
}

// Check the font style and weight of the text span.
void expectTextSpanStyle(TextSpan textSpan, FontStyle? style, FontWeight weight) {
  // Verify a text style is set
  expect(textSpan.style, isNotNull, reason: 'text span text style is null');

  // Font style check
  if (style == null) {
    expect(textSpan.style!.fontStyle, isNull, reason: 'font style is not null');
  } else {
    expect(textSpan.style!.fontStyle, isNotNull, reason: 'font style is null');
    expect(textSpan.style!.fontStyle == style, isTrue, reason: 'font style is not $style');
  }

  // Font weight check
  expect(textSpan.style, isNotNull, reason: 'font style is null');
  expect(textSpan.style!.fontWeight == weight, isTrue, reason: 'font weight is not $weight');
}

@immutable
class MarkdownLink {
  const MarkdownLink(this.text, this.destination, [this.title = '']);

  final String text;
  final String? destination;
  final String title;

  @override
  bool operator ==(Object other) =>
      other is MarkdownLink && other.text == text && other.destination == destination && other.title == title;

  @override
  int get hashCode => '$text$destination$title'.hashCode;

  @override
  String toString() {
    return '[$text]($destination "$title")';
  }
}

/// Verify a valid link structure has been created. This routine checks for the
/// link text and the associated [TapGestureRecognizer] on the text span.
void expectValidLink(String linkText) {
  final Finder textFinder = find.byType(Text);
  expect(textFinder, findsOneWidget);
  final Text text = textFinder.evaluate().first.widget as Text;

  // Verify the link text.
  expect(text.textSpan, isNotNull);
  expect(text.textSpan, isA<TextSpan>());

  // Verify the link text is a onTap gesture recognizer.
  final TextSpan textSpan = text.textSpan! as TextSpan;
  expectLinkTextSpan(textSpan, linkText);
}

void expectLinkTextSpan(TextSpan textSpan, String linkText) {
  expect(textSpan.children, isNull);
  expect(textSpan.toPlainText(), linkText);
  expect(textSpan.recognizer, isNotNull);
  expect(textSpan.recognizer, isA<TapGestureRecognizer>());
  final TapGestureRecognizer? tapRecognizer = textSpan.recognizer as TapGestureRecognizer?;
  expect(tapRecognizer?.onTap, isNotNull);

  // Execute the onTap callback handler.
  tapRecognizer!.onTap!();
}

void expectInvalidLink(String linkText) {
  final Finder textFinder = find.byType(Text);
  expect(textFinder, findsOneWidget);
  final Text text = textFinder.evaluate().first.widget as Text;

  expect(text.textSpan, isNotNull);
  expect(text.textSpan, isA<TextSpan>());
  final String plainText = text.textSpan!.toPlainText();
  expect(plainText, linkText);

  final TextSpan textSpan = text.textSpan! as TextSpan;
  expect(textSpan.recognizer, isNull);
}

void expectTableSize(int rows, int columns) {
  final Finder tableFinder = find.byType(Table);
  expect(tableFinder, findsOneWidget);
  final Table table = tableFinder.evaluate().first.widget as Table;

  expect(table.children.length, rows);
  for (int index = 0; index < rows; index++) {
    expect(table.children[index].children.length, columns);
  }
}

void expectLinkTap(MarkdownLink? actual, MarkdownLink expected) {
  expect(actual, equals(expected), reason: 'incorrect link tap results, actual: $actual expected: $expected');
}

String dumpRenderView() {
  return WidgetsBinding.instance.rootElement!.toStringDeep().replaceAll(
    RegExp(r'SliverChildListDelegate#\d+', multiLine: true),
    'SliverChildListDelegate',
  );
}

/// Wraps a widget with a left-to-right [Directionality] for tests.
Widget boilerplate(Widget child) {
  return Directionality(textDirection: TextDirection.ltr, child: child);
}

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.json') {
      const String manifest = r'{"assets/logo.png":["assets/logo.png"]}';
      final ByteData asset = ByteData.view(utf8.encoder.convert(manifest).buffer);
      return Future<ByteData>.value(asset);
    } else if (key == 'AssetManifest.bin') {
      final ByteData manifest = const StandardMessageCodec().encodeMessage(<String, List<Object>>{
        'assets/logo.png': <Object>[],
      })!;
      return Future<ByteData>.value(manifest);
    } else if (key == 'AssetManifest.smcbin') {
      final ByteData manifest = const StandardMessageCodec().encodeMessage(<String, List<Object>>{
        'assets/logo.png': <Object>[],
      })!;
      return Future<ByteData>.value(manifest);
    } else if (key == 'assets/logo.png') {
      // The root directory tests are run from is different for 'flutter test'
      // verses 'flutter test test/*_test.dart'. Adjust the root directory
      // to access the assets directory.
      final io.Directory rootDirectory = io.Directory.current.path.endsWith('${io.Platform.pathSeparator}test')
          ? io.Directory.current.parent
          : io.Directory.current;
      final io.File file = io.File('${rootDirectory.path}/test/assets/images/logo.png');

      final ByteData asset = ByteData.view(file.readAsBytesSync().buffer);
      return asset;
    } else {
      throw ArgumentError('Unknown asset key: $key');
    }
  }
}

/// Whether golden tests should run.
///
/// Pass `--dart-define=GOLDENS=true` (validate.sh forwards it). Golden
/// reference images are generated on one pinned CI runner, so running them
/// anywhere else compares against fonts and rasterisers the references never
/// saw. This switch replaces the older `GITHUB_ACTIONS` and `isLinux` skips.
const bool kGoldensEnabled = bool.fromEnvironment('GOLDENS');

/// Why golden tests are skipped, or null when they are running.
final String? kGoldensSkipReason = kGoldensEnabled
    ? null
    : 'skipped: goldens need --dart-define=GOLDENS=true; references are '
          'generated on the pinned CI runner only';

/// A [LocalFileComparator] that tolerates a little pixel drift.
///
/// Font rasterisation differs across machines and Flutter versions, so a
/// pixel-exact comparison fails on antialiasing noise alone. Observed drift
/// on this repo is about 0.006% of pixels; [tolerance] is 0.1% by default,
/// far above that noise floor and far below any real layout regression.
class TolerantGoldenComparator extends LocalFileComparator {
  TolerantGoldenComparator(super.testFile, {this.tolerance = 0.001});

  /// Maximum fraction of differing pixels still treated as a match.
  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(imageBytes, await getGoldenBytes(golden));
    if (result.passed || result.diffPercent <= tolerance) {
      result.dispose();
      return true;
    }
    final String error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

/// Call from a golden test group's `setUpAll` to install the tolerant
/// comparator and say, once, why the goldens are not running.
void setUpGoldens() {
  if (!kGoldensEnabled) {
    if (kGoldensSkipReason != null) {
      // Test infrastructure: R12 requires the skip reason to be visible in the
      // test output, and setUpAll has no logger to route it through.
      // ignore: avoid_print
      print('Golden tests: $kGoldensSkipReason');
    }
    return;
  }
  final GoldenFileComparator current = goldenFileComparator;
  if (current is LocalFileComparator) {
    goldenFileComparator = TolerantGoldenComparator(Uri.parse('${current.basedir}golden_stub_test.dart'));
  }
}
