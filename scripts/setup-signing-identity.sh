#!/bin/bash
set -euo pipefail

identity_name=${RBXMULTI_CODESIGN_IDENTITY:-"RbxMulti Stable Code Signing"}
keychain=$(security default-keychain -d user | sed -E 's/^[[:space:]]*"//; s/"[[:space:]]*$//')
temporary_dir=$(mktemp -d)
cleanup() { rm -rf "$temporary_dir"; }
trap cleanup EXIT

if security find-identity -v -p codesigning "$keychain" | grep -Fq "$identity_name"; then
  echo "Signing identity already exists: $identity_name"
  exit 0
fi

openssl req -quiet -x509 -newkey rsa:3072 -sha256 -nodes -days 3650 \
  -keyout "$temporary_dir/private-key.pem" \
  -out "$temporary_dir/certificate.pem" \
  -subj "/CN=$identity_name" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,digitalSignature,keyCertSign,cRLSign" \
  -addext "extendedKeyUsage=critical,codeSigning"

archive_password=$(openssl rand -hex 32)
openssl pkcs12 -export -legacy \
  -inkey "$temporary_dir/private-key.pem" \
  -in "$temporary_dir/certificate.pem" \
  -out "$temporary_dir/identity.p12" \
  -name "$identity_name" \
  -passout "pass:$archive_password"

security import "$temporary_dir/identity.p12" \
  -k "$keychain" \
  -P "$archive_password" \
  -T /usr/bin/codesign
security add-trusted-cert -r trustRoot -p codeSign -k "$keychain" "$temporary_dir/certificate.pem"

if ! security find-identity -v -p codesigning "$keychain" | grep -Fq "$identity_name"; then
  echo "Could not create a usable signing identity in $keychain" >&2
  exit 1
fi

echo "Created persistent signing identity: $identity_name"
echo "Its private key is stored in the login Keychain; no key file was kept in the repository."
