// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// Wraps a scrollable [Markdown] widget in a minimal [MaterialApp] so
/// integration tests can pump a deterministic widget tree without depending on
/// the example app's demo navigation.
Widget buildMarkdownApp({
  required String data,
  MarkdownTapLinkCallback? onTapLink,
  bool selectable = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SafeArea(
        child: Markdown(
          data: data,
          onTapLink: onTapLink,
          selectable: selectable,
        ),
      ),
    ),
  );
}

/// Wraps a non-scrolling [MarkdownBody] in a minimal [MaterialApp] for cases
/// where the rendered content fits on screen (e.g. checkbox rendering).
Widget buildMarkdownBodyApp({required String data}) {
  return MaterialApp(
    home: Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: MarkdownBody(data: data),
        ),
      ),
    ),
  );
}
