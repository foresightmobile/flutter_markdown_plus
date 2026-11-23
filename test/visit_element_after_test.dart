// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

import 'utils.dart';

void main() => defineTests();

void defineTests() {
  group('MarkdownElementBuilder.visitElementAfter', () {
    // Regression test for issue #64 (migrated from flutter/flutter#139130).
    // A builder that overrides visitElementAfter for a block element used to
    // trip the `_inlines.isEmpty` assertion in MarkdownBuilder.build.
    testWidgets(
      'block builder returning a widget replaces the paragraph without asserting',
      (WidgetTester tester) async {
        // The sample from issue #64.
        Widget frame(String data) {
          return boilerplate(
            SizedBox(
              width: 400,
              child: MarkdownBody(
                data: data,
                selectable: true,
                builders: <String, MarkdownElementBuilder>{
                  'p': ParagraphBuilder(),
                },
              ),
            ),
          );
        }

        await tester.pumpWidget(frame('## Prompt\n\nHello World\n'));
        expect(tester.takeException(), isNull);
        expect(find.text('Replaced'), findsOneWidget);
        expect(find.text('Hello World'), findsNothing);

        // The reported assertion fired during didUpdateWidget -> _parseMarkdown,
        // not the first build, so change the data to force a re-parse.
        await tester.pumpWidget(frame('## Prompt\n\nHello World\n\nSecond\n'));
        expect(tester.takeException(), isNull);
        expect(find.text('Replaced'), findsWidgets);
        expect(find.text('Hello World'), findsNothing);
      },
    );
  });
}

/// The builder from issue #64: overrides the deprecated [visitElementAfter]
/// and returns a widget for every `p` element.
class ParagraphBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, _) {
    return const Text('Replaced');
  }
}
