#!/bin/bash
set -e -x # exit on first error

###############################################################################
# VERIFICATION FUNCTION FOR FLUTTER APP/PACKAGES
###############################################################################
verifyFlutter () {
  cd $1
  echo "Checking `pwd`"
  flutter --version
  flutter clean
  flutter pub get
  sh ./scripts/format.sh --set-exit-if-changed
  flutter analyze --no-pub .

  ###############################################################################
  # CODE COVERAGE
  ###############################################################################

  rm -rf coverage

  # Ensure every *_test.dart file under test/ is registered in test/all.dart
  missing_tests=""
  for test_file in $(find test -name '*_test.dart' | sort); do
    rel_path="${test_file#test/}"
    if ! grep -Fq "'$rel_path'" test/all.dart; then
      missing_tests="$missing_tests $test_file"
    fi
  done
  if [ -n "$missing_tests" ]; then
    echo "ERROR: Test files missing from test/all.dart:$missing_tests" >&2
    exit 1
  fi

  flutter test test/all.dart
}

###############################################################################
# INVOKE VERIFICATION FUNCTIONS
###############################################################################
verifyFlutter "."
