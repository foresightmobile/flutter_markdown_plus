// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

void main() => defineTests();

/// Regression test for #59: registering a block builder (`isBlockElement() => true`)
/// for `'div'` receives `visitElementAfterWithContext` for alert blocks.
///
/// Kept in its own file and registered last in `test/all.dart` because
/// `MarkdownBuilder`'s constructor appends every tag whose builder returns
/// `isBlockElement() == true` to the global `_kBlockTags` list and never
/// removes it. Running this test in the same isolate before tests that exercise
/// unknown `div` containers without a block builder (such as
/// `test/crash_regression_test.dart` and `test/alert_syntax_test.dart`) would
/// cause `'div'` to take the block branch instead and make those guards pass
/// vacuously.
void defineTests() {
  testWidgets('a block builder registered for div is called for an alert (#59)', (WidgetTester tester) async {
    final _AlertBlockBuilder builder = _AlertBlockBuilder();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Markdown(
            data: '> [!NOTE]\n> this does not work\n',
            extensionSet: md.ExtensionSet.gitHubWeb,
            builders: <String, MarkdownElementBuilder>{'div': builder},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(builder.visitedClasses, <String?>['markdown-alert markdown-alert-note']);
    expect(find.byKey(_AlertBlockBuilder.key), findsOneWidget);
  });
}

/// A block builder for the `div` that `> [!NOTE]` produces, as #59 asked for.
class _AlertBlockBuilder extends MarkdownElementBuilder {
  static const Key key = Key('alert-block');

  final List<String?> visitedClasses = <String?>[];

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    visitedClasses.add(element.attributes['class']);
    return const SizedBox(key: key, height: 10);
  }
}
