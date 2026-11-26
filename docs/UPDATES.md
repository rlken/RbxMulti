# Automatic updates

Version 1.2.5 is the first build with Sparkle. Users on older versions install it once from the website. RbxMulti then checks periodically and silently installs signed updates. The app’s **Updates** section shows the installed version and starts a manual check; Sparkle presents its native **Install Update** action when a newer version is available. **RbxMulti → Check for Updates…** is also available from the app menu.

The updater uses Sparkle 2.10.0 from its official release archive, pinned by SHA-256 in `build.sh`. Its Ed25519 update key and persistent code-signing identity are kept separately in the maintainer's login Keychain. Only the Sparkle public key is embedded in `Info.plist`; signed ZIP archives are published on GitHub Pages through `site/appcast.xml`.

Website releases must be built with the persistent `RbxMulti Stable Code Signing` identity. Its certificate-anchored designated requirement keeps macOS Accessibility/event-posting grants matched across app versions; ad-hoc local and CI builds do not. This self-signed identity provides stable local code identity, not Apple Developer ID trust or notarization. Users upgrading from older ad-hoc builds may need to remove the stale RbxMulti permission row and grant the new build access once.

## Publishing a future update

1. Update `CFBundleShortVersionString` and increment `CFBundleVersion` in `Info.plist`. Update the site download link/card and changelog.
2. Run `scripts/publish-update.sh` on the Mac holding both login-Keychain identities. It builds the universal app with the stable code signature, copies the ZIP into `site/downloads/v<version>/`, writes a checksum, signs the archive with Sparkle, and adds a signed enclosure to `site/appcast.xml`.
3. Review the generated feed and package, commit the site files, and push to `main`. GitHub Pages deploys the new archive and feed. Keep GitHub Releases linking to the website; do not attach an unsigned ZIP.

Never export the private key into the repository, app bundle, GitHub Pages, or CI logs. Losing the key prevents publishing verified updates for already installed builds.
