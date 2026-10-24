#!/bin/bash
# Shared local/CI entry point. Uses any available iPad simulator unless overridden.
set -euo pipefail
cd "$(dirname "$0")/.."
command -v xcodegen >/dev/null || { echo 'Install XcodeGen: brew install xcodegen' >&2; exit 1; }
xcodegen generate
mkdir -p build
if [[ -z "${SIMULATOR_ID:-}" ]]; then
  SIMULATOR_ID="$(xcrun simctl list devices available --json | python3 -c '
import json, sys
catalog = json.load(sys.stdin)["devices"]
runtimes = sorted((r for r in catalog if ".iOS-" in r), key=lambda r: tuple(map(int, r.split(".iOS-")[1].split("-"))), reverse=True)
for runtime in runtimes:
    for device in catalog[runtime]:
        if device.get("isAvailable") and device["name"].startswith("iPad"):
            print(device["udid"])
            sys.exit(0)
sys.exit("No available iPad simulator. Install an iOS runtime in Xcode Settings > Components.")
')"
fi
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
