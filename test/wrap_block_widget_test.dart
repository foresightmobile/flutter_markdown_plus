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

void defineTests() {
  group('wrapBlockWidget', () {
    testWidgets(
      'wraps the default heading widget and keeps its inline formatting',
      (WidgetTester tester) async {
        final GlobalKey key = GlobalKey();
        final _RecordingBuilder builder = _RecordingBuilder(wrapWith: key);
        await tester.pumpWidget(
          boilerplate(
            MarkdownBody(
              data: '# **Bold** and [link](https://example.com) header',
              builders: <String, MarkdownElementBuilder>{'h1': builder},
              onTapLink: (String text, String? href, String title) {},
            ),
          ),
        );

        expect(builder.wrappedElements.map((md.Element e) => e.tag), <String>['h1']);

        // The default heading is still rendered, now as a descendant of the wrapper.
        final Finder wrapper = find.byKey(key);
        expect(wrapper, findsOneWidget);
        final Finder richText = find.descendant(of: wrapper, matching: find.byType(RichText));
        expect(richText, findsOneWidget);
        expectTextStrings(<Widget>[tester.widget(richText)], <String>['Bold and link header']);

        // Inline formatting inside the heading survives: bold style and link recognizer.
        final TextSpan span = tester.widget<RichText>(richText).text as TextSpan;
        final List<TextSpan> children = <TextSpan>[];
        span.visitChildren((InlineSpan child) {
          if (child is TextSpan && child.text != null) {
            children.add(child);
          }
          return true;
        });
        expect(children.map((TextSpan s) => s.text), <String>['Bold', ' and ', 'link', ' header']);
        expect(children[0].style?.fontWeight, FontWeight.bold);
        expect(children[2].recognizer, isA<TapGestureRecognizer>());
      },
    );

    testWidgets(
      'keeps the paddingBuilders padding inside the wrapped widget',
      (WidgetTester tester) async {
        const EdgeInsets padding = EdgeInsets.all(17);
        final GlobalKey key = GlobalKey();
        await tester.pumpWidget(
          boilerplate(
            MarkdownBody(
              data: '# Header',
              builders: <String, MarkdownElementBuilder>{'h1': _RecordingBuilder(wrapWith: key)},
              paddingBuilders: <String, MarkdownPaddingBuilder>{'h1': _FixedPaddingBuilder(padding)},
            ),
          ),
        );

        final Finder padded = find.descendant(
          of: find.byKey(key),
          matching: find.byWidgetPredicate((Widget w) => w is Padding && w.padding == padding),
        );
        expect(padded, findsOneWidget);
      },
    );

    testWidgets(
      'receives the widget returned by visitElementAfterWithContext',
      (WidgetTester tester) async {
        final _RecordingBuilder builder = _RecordingBuilder(
          wrapWith: GlobalKey(),
          replacement: const ColoredBox(color: Colors.red, child: Text('custom')),
        );
        await tester.pumpWidget(
          boilerplate(
            MarkdownBody(
              data: '# Header',
              builders: <String, MarkdownElementBuilder>{'h1': builder},
            ),
          ),
        );

        expect(builder.wrappedChildren, hasLength(1));
        expect(builder.wrappedChildren.single, isA<ColoredBox>());
        expect(find.text('custom'), findsOneWidget);
        expect(find.text('Header'), findsNothing);
      },
    );

    testWidgets(
      'receives the fully built list item including its bullet',
      (WidgetTester tester) async {
        final _RecordingBuilder builder = _RecordingBuilder(wrapWith: GlobalKey());
        await tester.pumpWidget(
          boilerplate(
            MarkdownBody(
              data: '- item',
              builders: <String, MarkdownElementBuilder>{'li': builder},
            ),
          ),
        );

        expect(builder.wrappedChildren, hasLength(1));
        // The list item child is the bullet + content row, not just the content.
        expect(builder.wrappedChildren.single, isA<Row>());
        expect(find.text('item'), findsOneWidget);
      },
    );

    testWidgets(
      'is not called for inline elements',
      (WidgetTester tester) async {
        final _RecordingBuilder builder = _RecordingBuilder(wrapWith: GlobalKey());
        await tester.pumpWidget(
          boilerplate(
            MarkdownBody(
              data: 'some *emphasis* here',
              builders: <String, MarkdownElementBuilder>{'em': builder},
            ),
          ),
        );

        expect(builder.wrappedElements, isEmpty);
        expectTextStrings(tester.allWidgets, <String>['some emphasis here']);
      },
    );

    testWidgets(
      'is called for custom block syntaxes',
      (WidgetTester tester) async {
        final _RecordingBuilder builder = _RecordingBuilder(wrapWith: GlobalKey(), isBlock: true);
        await tester.pumpWidget(
          boilerplate(
            MarkdownBody(
              data: '[!NOTE] note block',
              extensionSet: md.ExtensionSet.none,
              blockSyntaxes: <md.BlockSyntax>[_NoteSyntax()],
              builders: <String, MarkdownElementBuilder>{'note': builder},
            ),
          ),
        );

        expect(builder.wrappedElements.map((md.Element e) => e.tag), <String>['note']);
        expect(find.text('note block'), findsOneWidget);
      },
    );

    testWidgets(
      'lets anchor links scroll to a heading through a GlobalKey',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final ScrollController controller = ScrollController();
        addTearDown(controller.dispose);
        final _AnchorBuilder anchors = _AnchorBuilder();
        final String filler = List<String>.filled(30, 'Filler paragraph.').join('\n\n');
        await tester.pumpWidget(
          boilerplate(
            SingleChildScrollView(
              controller: controller,
              child: MarkdownBody(
                data: '[Jump to target](#target)\n\n$filler\n\n## Target\n\n$filler',
                builders: <String, MarkdownElementBuilder>{'h2': anchors},
                onTapLink: (String text, String? href, String title) {
                  final BuildContext? context = anchors.contextFor(href);
                  if (context != null) {
                    Scrollable.ensureVisible(context);
                  }
                },
              ),
            ),
          ),
        );

        expect(controller.offset, 0.0);
        expect(tester.getTopLeft(find.text('Target')).dy, greaterThan(600));

        _tapLink(tester, 'Jump to target');
        await tester.pumpAndSettle();

        expect(controller.offset, greaterThan(0.0));
        expect(tester.getTopLeft(find.text('Target')).dy, moreOrLessEquals(0.0, epsilon: 1.0));
      },
    );
  });
}

/// Taps the link with the given text by invoking its [TapGestureRecognizer].
void _tapLink(WidgetTester tester, String linkText) {
  for (final RichText richText in tester.widgetList<RichText>(find.byType(RichText))) {
    bool tapped = false;
    richText.text.visitChildren((InlineSpan span) {
      if (span is TextSpan && span.text == linkText && span.recognizer is TapGestureRecognizer) {
        (span.recognizer! as TapGestureRecognizer).onTap!();
        tapped = true;
        return false;
      }
      return true;
    });
    if (tapped) {
      return;
    }
  }
  fail('No link with text "$linkText" found.');
}

/// Records every call to [wrapBlockWidget] and wraps the child in a [KeyedSubtree].
class _RecordingBuilder extends MarkdownElementBuilder {
  _RecordingBuilder({required this.wrapWith, this.replacement, this.isBlock = false});

  final GlobalKey wrapWith;
  final Widget? replacement;
  final bool isBlock;
  final List<md.Element> wrappedElements = <md.Element>[];
  final List<Widget> wrappedChildren = <Widget>[];

  @override
  bool isBlockElement() => isBlock;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return replacement;
  }

  @override
  Widget wrapBlockWidget(BuildContext context, md.Element element, Widget child) {
    wrappedElements.add(element);
    wrappedChildren.add(child);
    return KeyedSubtree(key: wrapWith, child: child);
  }
}

/// Gives every heading a [GlobalKey] so `#fragment` links can scroll to it.
class _AnchorBuilder extends MarkdownElementBuilder {
  final Map<String, GlobalKey> _keys = <String, GlobalKey>{};

  BuildContext? contextFor(String? href) {
    if (href == null || !href.startsWith('#')) {
      return null;
    }
    return _keys[href.substring(1)]?.currentContext;
  }

  @override
  Widget wrapBlockWidget(BuildContext context, md.Element element, Widget child) {
    final String anchor = element.textContent.trim().toLowerCase();
    final GlobalKey key = _keys.putIfAbsent(anchor, GlobalKey.new);
    return KeyedSubtree(key: key, child: child);
  }
}

class _FixedPaddingBuilder extends MarkdownPaddingBuilder {
  _FixedPaddingBuilder(this.padding);

  final EdgeInsets padding;

  @override
  EdgeInsets getPadding() => padding;
}

class _NoteSyntax extends md.BlockSyntax {
  @override
  md.Node? parse(md.BlockParser parser) {
    final md.Line line = parser.current;
    parser.advance();
    return md.Element('note', <md.Node>[md.Text(line.content.substring(8))]);
  }

  @override
  RegExp get pattern => RegExp(r'^\[!NOTE] ');
}
