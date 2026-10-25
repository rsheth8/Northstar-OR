#!/bin/bash
# Shared local/CI entry point. Uses an SDK-aligned iPad baseline unless overridden.
set -euo pipefail
cd "$(dirname "$0")/.."
command -v xcodegen >/dev/null || { echo 'Install XcodeGen: brew install xcodegen' >&2; exit 1; }
xcodegen generate
mkdir -p build
northstar_simulator_sdk="$(xcrun --sdk iphonesimulator --show-sdk-version)"
echo "Active simulator SDK: $northstar_simulator_sdk"
if [[ -z "${SIMULATOR_ID:-}" ]]; then
  SIMULATOR_ID="$(xcrun simctl list devices available --json | python3 scripts/select-ipad-simulator.py "$northstar_simulator_sdk")"
else
  echo "Explicit simulator override: $SIMULATOR_ID"
fi
# Complete first-boot migration before XCTest tries to connect to accessibility.
xcrun simctl bootstatus "$SIMULATOR_ID" -b
# A result bundle must have a fresh path; preserve earlier local runs.
RESULT_BUNDLE="$(mktemp -d "$PWD/build/check.XXXXXX")/Tests.xcresult"
echo "Testing on iPad simulator $SIMULATOR_ID"
echo "Results: $RESULT_BUNDLE"
xcodebuild test \
  -project NorthstarOR.xcodeproj \
  -scheme NorthstarOR \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath build/DerivedData \
  -resultBundlePath "$RESULT_BUNDLE" \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tee build/xcodebuild.log
