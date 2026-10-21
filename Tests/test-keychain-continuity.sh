#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
umask 077
test_dir=$(mktemp -d /tmp/rbxmulti-keychain-test.XXXXXX)
service="com.rbxmulti.signing-test.$(/usr/bin/uuidgen)"
created=false
cleanup() {
  if [[ "$created" == true ]]; then
    if ! /usr/bin/security delete-generic-password -s "$service" -a disposable-test "$HOME/Library/Keychains/login.keychain-db" >/dev/null; then
      echo "Could not remove the disposable fixture: $service"
    fi
  fi
  rm -f "$test_dir/probe" "$test_dir/probe-next"
  rmdir "$test_dir"
}
trap cleanup EXIT
fingerprint=$(/usr/bin/plutil -extract certificateSHA1 raw "$HOME/Library/Application Support/RbxMulti/Signing/identity.plist")
[[ "$fingerprint" =~ ^[0-9A-Fa-f]{40}$ ]]
sign_probe() {
  /usr/bin/codesign --force --timestamp=none --sign "$fingerprint" --identifier com.rbxmulti.signing-continuity-test \
    --requirements "=designated => identifier \"com.rbxmulti.signing-continuity-test\" and certificate leaf = H\"$fingerprint\"" "$1"
}
swiftc Tests/SigningKeychainProbe.swift -o "$test_dir/probe"
sign_probe "$test_dir/probe"
"$test_dir/probe" create "$service"
created=true
"$test_dir/probe" read "$service"
swiftc -D UPDATED_BUILD Tests/SigningKeychainProbe.swift -o "$test_dir/probe-next"
sign_probe "$test_dir/probe-next"
mv "$test_dir/probe-next" "$test_dir/probe"
"$test_dir/probe" read "$service"
"$test_dir/probe" delete "$service"
created=false
echo "PASS: a rebuilt signed app accessed its own disposable Keychain fixture without prompting."
