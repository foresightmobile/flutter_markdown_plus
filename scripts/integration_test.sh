#!/bin/sh
set -e -x

###############################################################################
# Runs the example app's integration tests on a connected device/emulator.
#
# Locally:  ANDROID_DEVICE=emulator-5554 sh ./scripts/integration_test.sh
# CI:       device id is omitted so the single booted emulator is auto-selected.
###############################################################################

cd "$(dirname "$0")/../example"

flutter pub get

if [ -n "$ANDROID_DEVICE" ]; then
  flutter test integration_test -d "$ANDROID_DEVICE"
else
  flutter test integration_test
fi
