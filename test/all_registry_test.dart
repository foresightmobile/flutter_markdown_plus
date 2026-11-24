// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the aggregated suite against drift.
///
/// `CONTRIBUTING.md` asks that every test file be registered in
/// `test/all.dart`, but nothing enforced it, and `all.dart` is not run by CI —
/// so a missing registration went unnoticed. This test runs in the ordinary
/// `flutter test` run and fails if any `*_test.dart` is absent from `all.dart`.
void main() => defineTests();

void defineTests() {
  test('every test file is registered in test/all.dart', () {
    final String aggregator = File('test/all.dart').readAsStringSync();

    final List<String> testFiles = Directory('test')
        .listSync()
        .whereType<File>()
        .map((File f) => f.uri.pathSegments.last)
        .where((String name) => name.endsWith('_test.dart'))
        .where((String name) => name != 'all_registry_test.dart')
        .toList()
      ..sort();

    final List<String> unregistered = testFiles
        .where((String name) => !aggregator.contains(name))
        .toList();

    expect(
      unregistered,
      isEmpty,
      reason: 'These test files exist but are not registered in test/all.dart, '
          'which CONTRIBUTING.md asks for. Add an import and a defineTests() '
          'call for each:\n  ${unregistered.join('\n  ')}',
    );
  });
}
