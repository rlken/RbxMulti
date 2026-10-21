#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d /tmp/rbxmulti-window-tests.XXXXXX)
trap 'rm -f "$test_dir/tests"; rmdir "$test_dir"' EXIT
swiftc -parse-as-library -D RBXMULTI_TESTING Sources/*.swift Tests/WindowBehaviorTests.swift -o "$test_dir/tests"
"$test_dir/tests"
