// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cupertino_ui/cupertino_ui.dart' as cui;
import 'package:flutter/cupertino.dart' show CupertinoTheme, InheritedCupertinoTheme;
import 'package:flutter/material.dart' show Theme;
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as mui;

import 'style_sheet.dart';

/// Whether the Material theme that applies at [context] comes from `package:material_ui` rather than from the
/// legacy `flutter/material.dart` library.
///
/// The nearest [mui.Theme] or legacy [Theme] decides. When there is neither, the nearest Cupertino theme decides,
/// because both `Theme.of` implementations derive a Material theme from a Cupertino theme of their own library.
/// With no theme at all this returns false, so apps without a theme keep the legacy behavior.
///
/// This walks up the tree until it finds a Material theme, so call it once per parse rather than once per widget.
bool usesMaterialUiTheme(BuildContext context) {
  bool? materialUiTheme;
  bool? materialUiCupertinoTheme;
  context.visitAncestorElements((Element element) {
    final Widget widget = element.widget;
    if (widget is mui.Theme) {
      materialUiTheme = true;
    } else if (widget is Theme) {
      materialUiTheme = false;
    } else if (materialUiCupertinoTheme == null) {
      if (widget is cui.CupertinoTheme) {
        materialUiCupertinoTheme = true;
      } else if (widget is CupertinoTheme) {
        materialUiCupertinoTheme = false;
      }
    }
    return materialUiTheme == null;
  });
  return materialUiTheme ?? materialUiCupertinoTheme ?? false;
}

/// Whether the Cupertino theme that applies at [context] comes from `package:cupertino_ui` rather than from the
/// legacy `flutter/cupertino.dart` library.
///
/// The nearest inherited Cupertino theme decides. A Material [mui.Theme] or legacy [Theme] provides one of its own
/// library, so this also follows the nearest Material theme when there is no explicit Cupertino theme. With no theme
/// at all this returns false.
bool usesCupertinoUiTheme(BuildContext context) {
  final int materialUiDepth =
      context.getElementForInheritedWidgetOfExactType<cui.InheritedCupertinoTheme>()?.depth ?? 0;
  final int legacyDepth = context.getElementForInheritedWidgetOfExactType<InheritedCupertinoTheme>()?.depth ?? 0;
  return materialUiDepth > legacyDepth;
}

/// Creates the default Material-based [MarkdownStyleSheet] from the theme that applies at [context].
MarkdownStyleSheet materialStyleSheetOf(BuildContext context) => usesMaterialUiTheme(context)
    ? MarkdownStyleSheet.fromMaterialUiTheme(mui.Theme.of(context))
    : MarkdownStyleSheet.fromTheme(Theme.of(context));

/// Creates the default Cupertino-based [MarkdownStyleSheet] from the theme that applies at [context].
MarkdownStyleSheet cupertinoStyleSheetOf(BuildContext context) => usesCupertinoUiTheme(context)
    ? MarkdownStyleSheet.fromCupertinoUiTheme(cui.CupertinoTheme.of(context))
    : MarkdownStyleSheet.fromCupertinoTheme(CupertinoTheme.of(context));
