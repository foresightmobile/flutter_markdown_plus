#!/bin/bash
set -e -x # exit on first error

# Golden tests compare against reference images generated on one pinned CI
# runner, so they run only when asked. Pass --goldens (or set GOLDENS=true) and
# this forwards --dart-define=GOLDENS=true to `flutter test`. See R12 in the
# spec: the switch is passed only by the pinned latest job and the golden
# regeneration job.
GOLDENS_DEFINE=""
for arg in "$@"; do
  if [ "$arg" = "--goldens" ]; then
    GOLDENS_DEFINE="--dart-define=GOLDENS=true"
  fi
done
if [ "$GOLDENS" = "true" ]; then
  GOLDENS_DEFINE="--dart-define=GOLDENS=true"
fi

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
  flutter test $GOLDENS_DEFINE
}

###############################################################################
# INVOKE VERIFICATION FUNCTIONS
###############################################################################
verifyFlutter "."
