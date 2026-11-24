// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_implementing_value_types

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import '../shared/markdown_demo_widget.dart';

// ignore_for_file: public_member_api_docs

const String _filler = '''
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor
incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis
nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu
fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
culpa qui officia deserunt mollit anim id est laborum.
''';

// Markdown source data with a table of contents made of anchor links.
const String _data = '''
# Anchor Links

- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [**Bold** Heading](#bold-heading)
- [Back to top](#anchor-links)

## Getting Started

$_filler
$_filler

## Configuration

$_filler
$_filler

## **Bold** Heading

$_filler
$_filler

[Back to top](#anchor-links)
''';

const String _notes = '''
# Anchor Link Demo
---

## Overview

Markdown documents often start with a table of contents whose links point at
headings in the same document, such as `[Getting Started](#getting-started)`.
Flutter has no built-in notion of an anchor, so `flutter_markdown_plus` hands
the `#getting-started` href to `onTapLink` and leaves the rest to you.

This demo shows the two pieces needed to make such links scroll:

1. A `MarkdownElementBuilder` for the heading tags that overrides
   `wrapBlockWidget`. The hook receives the fully rendered heading (bold text,
   style sheet styles and padding included) and wraps it in a small widget that
   registers its `BuildContext` under the heading's slug. Because the default
   rendering is kept, the builder does not have to re-implement headings.
2. An `onTapLink` handler that looks up the slug from a `#fragment` href and
   calls `Scrollable.ensureVisible` on the registered context.

## Notes

- `Markdown` lays its blocks out lazily in a `ListView`, so off-screen
  headings have no `BuildContext` to scroll to. Use `MarkdownBody` inside a
  `SingleChildScrollView` (as this demo does) or `Markdown` with
  `shrinkWrap: true`.
- The slug here is the heading text in lower case with spaces replaced by
  hyphens. Match whatever convention your content authors use.
- Headings with the same text register under the same slug; links resolve to
  the first one in the document, like browsers do.
''';

class AnchorLinkDemo extends StatefulWidget implements MarkdownDemoWidget {
  const AnchorLinkDemo({super.key});

  static const String _title = 'Anchor Link Demo';

  @override
  String get title => AnchorLinkDemo._title;

  @override
  String get description => 'An example of scrolling to a heading when a '
      '`#fragment` link is tapped, using wrapBlockWidget.';

  @override
  Future<String> get data => Future<String>.value(_data);

  @override
  Future<String> get notes => Future<String>.value(_notes);

  @override
  State<AnchorLinkDemo> createState() => _AnchorLinkDemoState();
}

class _AnchorLinkDemoState extends State<AnchorLinkDemo> {
  final HeadingAnchorBuilder _anchors = HeadingAnchorBuilder();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: widget.data,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CircularProgressIndicator();
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: MarkdownBody(
            data: snapshot.data!,
            builders: <String, MarkdownElementBuilder>{
              for (final String tag in HeadingAnchorBuilder.headingTags) tag: _anchors,
            },
            onTapLink: (String text, String? href, String title) {
              final BuildContext? target = _anchors.contextFor(href);
              if (target != null) {
                Scrollable.ensureVisible(
                  target,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
        );
      },
    );
  }
}

/// Registers every heading under its slug so `#fragment` links can be resolved
/// to a [BuildContext].
///
/// Headings are tracked by a small stateful wrapper rather than by
/// [GlobalKey]s: repeated heading text would otherwise produce duplicate keys,
/// and the registry stays correct when the markdown is re-parsed.
class HeadingAnchorBuilder extends MarkdownElementBuilder {
  static const List<String> headingTags = <String>['h1', 'h2', 'h3', 'h4', 'h5', 'h6'];

  final List<_HeadingAnchorState> _anchors = <_HeadingAnchorState>[];

  /// Returns the context of the first heading matching [href], or null when
  /// [href] is not a fragment link or no heading matches.
  BuildContext? contextFor(String? href) {
    if (href == null || !href.startsWith('#')) {
      return null;
    }
    final String slug = Uri.decodeComponent(href.substring(1));
    for (final _HeadingAnchorState anchor in _anchors) {
      if (anchor.widget.slug == slug && anchor.mounted) {
        return anchor.context;
      }
    }
    return null;
  }

  @override
  Widget wrapBlockWidget(BuildContext context, md.Element element, Widget child) {
    return _HeadingAnchor(registry: this, slug: slugify(element.textContent), child: child);
  }

  static String slugify(String text) => text.trim().toLowerCase().replaceAll(' ', '-');
}

class _HeadingAnchor extends StatefulWidget {
  const _HeadingAnchor({required this.registry, required this.slug, required this.child});

  final HeadingAnchorBuilder registry;
  final String slug;
  final Widget child;

  @override
  State<_HeadingAnchor> createState() => _HeadingAnchorState();
}

class _HeadingAnchorState extends State<_HeadingAnchor> {
  @override
  void initState() {
    super.initState();
    widget.registry._anchors.add(this);
  }

  @override
  void dispose() {
    widget.registry._anchors.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
