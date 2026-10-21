#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d /tmp/rbxmulti-tests.XXXXXX)
trap 'rm -f "$test_dir/tests"; rmdir "$test_dir"' EXIT
swiftc -parse-as-library Sources/IsolatedPlayer.swift Sources/PlayerSessionLog.swift Tests/SessionIsolationTests.swift -o "$test_dir/tests"
"$test_dir/tests"
