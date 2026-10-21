# Experimental signing research — not a popup fix

**Not required for installation. Disabled by default. Do not run this to stop Keychain prompts.**

A local self-signed certificate with a certificate-pinned, per-slot designated requirement was tested during development. Changed builds passed code-identity checks, but a separate dummy Keychain item was readable by the initial build and not by the rebuilt build with interaction disabled: `errSecAuthFailed` (-25293).

Apple's file-based Keychain implementation also considers a partition identifier. In the inspected implementation, self-signed apps can fall back to a code-hash partition, whereas eligible Apple-issued signing identities use other partitions. This explains why a stable designated requirement alone was insufficient in the test; it does not establish that another signing scheme would solve Roblox's complete login behavior. See [Apple's Security source](https://github.com/apple-oss-distributions/Security/blob/main/securityd/src/clientid.cpp).

## What the opt-in does

`setup-local-signing.sh` requires the explicit `--experiment` argument. It creates or reuses a code-signing certificate named RbxMulti Local Session Signing and a non-extractable private key in the login Keychain. Only `/usr/bin/codesign` is preauthorized to use that new key.

The script stores the public certificate fingerprint in:

`~/Library/Application Support/RbxMulti/Signing/identity.plist`

With that configuration present, new/rebuilt idle slots use the selected identity and a requirement pinned to the certificate and slot identifier. Missing/unusable signing keys cause preparation failure; there is no silent ad-hoc fallback. Running players are not migrated.

The script does not read Roblox passwords, change Roblox Keychain-item ACLs, grant all apps access, or install a system/TLS trust root. It does change your local signing setup, so review it before running it. Temporary key/export files are cleaned up by the script; never commit them.

## Reproduction for developers only

These commands change the login Keychain and local signing configuration. Use a deliberate test environment and review every prompt yourself:

```sh
bash setup-local-signing.sh --experiment
RBXMULTI_TEST_LOCAL_SIGNING=1 bash Tests/run.sh
bash Tests/test-keychain-continuity.sh
```

The identity tests check changed-build matching, slot separation, missing-key failure, and rejection of identifier-only impersonation. The separate continuity test creates a uniquely named disposable dummy Keychain item, tests it across builds, and deletes it. It does not query Roblox credential items. That continuity test **failed in the development experiment**; do not interpret the other passing tests as proof of persistent Keychain approval.

## Disable an experiment

Quit the manager first. In Finder, navigate to the exact Signing folder above and move `identity.plist` to a private backup location outside that folder. Do not upload it with other signing material. Without this opt-in file, normal ad-hoc preparation is used again for future idle-slot rebuilds.

This does not remove the certificate/private key or change already running players. Existing copies can be rebuilt on their next launch because the signature-mode fingerprint changes, potentially causing another prompt. If you choose to remove the experimental Keychain identity, verify its exact name and that no other experiment relies on it; do not delete Roblox credentials or the login Keychain itself. Never rotate signing identities casually or broaden credential access as a workaround.
