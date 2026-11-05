#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d /tmp/rbxmulti-player-tests.XXXXXX)
swiftc -parse-as-library Sources/OfficialPlayerLauncher.swift Tests/OfficialPlayerLaunchTests.swift -o "$test_dir/probe"
for slot in 1 2; do
  test_app="$test_dir/Session $slot.app"
  mkdir -p "$test_app/Contents/MacOS"
  cp "$test_dir/probe" "$test_app/Contents/MacOS/RobloxPlayer"
  cat > "$test_app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.rbxmulti.launch-probe.slot$slot</string>
<key>CFBundleExecutable</key><string>RobloxPlayer</string>
<key>CFBundleName</key><string>RbxMulti Launch Probe $slot</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSUIElement</key><true/>
</dict></plist>
EOF
  codesign --force --sign - "$test_app"
done
"$test_dir/probe" "$test_dir" "$@"
echo "Disposable fixture directory: $test_dir"
