// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cupertino_ui/cupertino_ui.dart' as cui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart' as mui;

/// Whether the nearest theme above [context] comes from `package:material_ui` or
/// `package:cupertino_ui` rather than from the legacy `flutter/material.dart` and
/// `flutter/cupertino.dart` libraries.
///
/// Returns false when no theme is found, so that apps without any theme keep the
/// legacy behavior.
bool usesMaterialUiTheme(BuildContext context) {
  bool result = false;
  context.visitAncestorElements((Element element) {
    final Widget widget = element.widget;
    if (widget is mui.Theme || widget is cui.CupertinoTheme) {
      result = true;
      return false;
    }
    return widget is! Theme && widget is! CupertinoTheme;
  });
  return result;
}
