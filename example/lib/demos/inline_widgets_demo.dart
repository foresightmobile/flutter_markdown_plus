// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(goderbauer): Restructure the examples to avoid this ignore, https://github.com/flutter/flutter/issues/110208.
// ignore_for_file: avoid_implementing_value_types

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../shared/markdown_demo_widget.dart';

const String _data =
    '## Tall inline widget\n\n'
    'The ![tall star](inline-star) fits between two words.\n\n'
    '## Mixed-size text\n\n'
    'Small text **and big text** share a line.  \n'
    'Watch the space between these lines as you toggle the switch.';

const String _notes = '''
The image builder replaces the Markdown image with a tall Flutter widget.
Lines with inline widgets always leave room for those widgets.

Use the switch to compare the text-only paragraph. With forced strut height
enabled, each line uses the paragraph's fixed height. Turn it off to let
the larger bold text expand its line.
''';

/// Demonstrates line height with a tall inline widget and mixed-size text.
class InlineWidgetsDemo extends StatefulWidget implements MarkdownDemoWidget {
  /// Creates an inline widgets demo.
  const InlineWidgetsDemo({super.key});

  @override
  String get title => 'Inline widgets';

  @override
  String get description => 'Compare how an inline widget and mixed-size text affect line height.';

  @override
  Future<String> get data => Future<String>.value(_data);

  @override
  Future<String> get notes => Future<String>.value(_notes);

  @override
  State<InlineWidgetsDemo> createState() => _InlineWidgetsDemoState();
}

class _InlineWidgetsDemoState extends State<InlineWidgetsDemo> {
  bool _forceStrutHeight = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SwitchListTile(
          title: const Text('Force strut height'),
          value: _forceStrutHeight,
          onChanged: (bool value) => setState(() => _forceStrutHeight = value),
        ),
        Expanded(
          child: Markdown(
            data: _data,
            forceStrutHeight: _forceStrutHeight,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(fontSize: 16, height: 1.2),
              strong: const TextStyle(fontSize: 32, height: 1.2, fontWeight: FontWeight.bold),
            ),
            imageBuilder: (Uri uri, String? title, String? alt) => Semantics(
              image: true,
              label: alt,
              child: SizedBox(
                width: 48,
                height: 64,
                child: Icon(Icons.star, size: 44, color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
