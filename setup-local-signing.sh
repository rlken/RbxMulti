#!/bin/bash
# Opt-in setup only. Never called automatically by the app.
# Creates a local code-signing key, not a trusted system/TLS root certificate.
set -euo pipefail
cd "$(dirname "$0")"
if [[ "${1:-}" != "--experiment" ]]; then
  echo "Experimental only: local self-signing did NOT preserve prompt-free Keychain access across rebuilt apps on this Mac."
  echo "This is not a popup fix. Pass --experiment only to reproduce the signing tests."
  exit 1
fi
umask 077
signing_dir="$HOME/Library/Application Support/RbxMulti/Signing"
settings="$signing_dir/identity.plist"
if [[ -e "$settings" ]]; then
  echo "A signing identity is already configured. Refusing to rotate it automatically."
  exit 0
fi
temp_dir=$(mktemp -d /tmp/rbxmulti-signing.XXXXXX)
cleanup() {
  # Only known generated files; never remove a keychain or app here.
  rm -f "$temp_dir/key.pem" "$temp_dir/cert.pem" "$temp_dir/identity.p12" "$temp_dir/probe" "$temp_dir/identity.plist"
  rmdir "$temp_dir"
}
trap cleanup EXIT
keychain="$HOME/Library/Keychains/login.keychain-db"
if [[ ! -f "$keychain" ]]; then
  echo "No login keychain at the expected location; stop and configure it manually."
  exit 1
fi
# Do not create a duplicate after an interrupted setup.
if /usr/bin/security find-certificate -c "RbxMulti Local Session Signing" -p "$keychain" > "$temp_dir/cert.pem" 2>/dev/null; then
  echo "Reusing the existing local signing certificate."
else
  /usr/bin/openssl req -new -newkey rsa:3072 -nodes -x509 -sha256 -days 3650 \
    -config Resources/LocalSigning.cnf -keyout "$temp_dir/key.pem" -out "$temp_dir/cert.pem" 2>/dev/null
  # A one-use generated wrapping password, never the user's login password.
  export RBXMULTI_IMPORT_SECRET=$(/usr/bin/openssl rand -hex 32)
  /usr/bin/openssl pkcs12 -export -inkey "$temp_dir/key.pem" -in "$temp_dir/cert.pem" \
    -out "$temp_dir/identity.p12" -passout env:RBXMULTI_IMPORT_SECRET
  # Non-extractable key; only Apple's codesign is preauthorized to use it.
  # No -A, partition-list changes, password reads, or Roblox item ACL changes.
  /usr/bin/security import "$temp_dir/identity.p12" -k "$keychain" -f pkcs12 -P "$RBXMULTI_IMPORT_SECRET" -x -T /usr/bin/codesign
  unset RBXMULTI_IMPORT_SECRET
fi
fingerprint=$(/usr/bin/openssl x509 -in "$temp_dir/cert.pem" -noout -fingerprint -sha1 | /usr/bin/sed 's/.*=//;s/://g')
[[ "$fingerprint" =~ ^[0-9A-Fa-f]{40}$ ]]
/bin/cp /usr/bin/true "$temp_dir/probe"
/usr/bin/codesign --force --timestamp=none --sign "$fingerprint" --identifier com.rbxmulti.signing-probe \
  --requirements "=designated => identifier \"com.rbxmulti.signing-probe\" and certificate leaf = H\"$fingerprint\"" "$temp_dir/probe"
/usr/bin/codesign --verify --strict "$temp_dir/probe"
mkdir -p "$signing_dir"
/usr/bin/plutil -create xml1 "$temp_dir/identity.plist"
/usr/bin/plutil -insert certificateSHA1 -string "$fingerprint" "$temp_dir/identity.plist"
/bin/mv "$temp_dir/identity.plist" "$settings"
echo "Local signing configured. No existing Roblox Keychain permissions or system trust settings were changed."
