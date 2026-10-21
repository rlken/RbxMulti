#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d /tmp/rbxmulti-link-tests.XXXXXX)
test_app="$test_dir/LinkTest.app"
mkdir -p "$test_app/Contents/MacOS"
cp Tests/LinkDeliveryProbe.plist "$test_app/Contents/Info.plist"
swiftc -parse-as-library -D RBXMULTI_TESTING Sources/*.swift Tests/LinkDeliveryProbe.swift -o "$test_app/Contents/MacOS/Probe"
codesign --force --sign - "$test_app"
open -n -a "$test_app" 'roblox-player://test-only' --args "$test_dir/cold.json" cold
for attempt in {1..20}; do [[ -f "$test_dir/cold.json" ]] && break; sleep 0.2; done
[[ $(plutil -extract links raw "$test_dir/cold.json") == 1 ]]
[[ $(plutil -extract initiallyVisible raw "$test_dir/cold.json") == false ]]
[[ $(plutil -extract finallyVisible raw "$test_dir/cold.json") == false ]]
open -n -a "$test_app" --args "$test_dir/warm.json" warm
sleep 1
open -a "$test_app" 'roblox-player://test-only'
for attempt in {1..30}; do [[ -f "$test_dir/warm.json" ]] && break; sleep 0.2; done
[[ $(plutil -extract initiallyVisible raw "$test_dir/warm.json") == true ]]
[[ $(plutil -extract links raw "$test_dir/warm.json") == 1 ]]
[[ $(plutil -extract finallyVisible raw "$test_dir/warm.json") == false ]]
echo "PASS: real Launch Services cold and warm URL delivery stays in the background. Results: $test_dir"
