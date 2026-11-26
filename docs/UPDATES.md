# Automatic updates

Version 1.2.5 is the first build with Sparkle. Users on older versions install it once from the website. RbxMulti then checks periodically and silently installs signed updates. The app’s **Updates** section shows the installed version and starts a manual check; Sparkle presents its native **Install Update** action when a newer version is available. **RbxMulti → Check for Updates…** is also available from the app menu.

The updater uses Sparkle 2.10.0 from its official release archive, pinned by SHA-256 in `build.sh`. Its Ed25519 private signing key is kept in the maintainer's login Keychain. Only the public key is embedded in `Info.plist`; signed ZIP archives are published on GitHub Pages through `site/appcast.xml`.

## Publishing a future update

1. Update `CFBundleShortVersionString` and increment `CFBundleVersion` in `Info.plist`. Update the site download link/card and changelog.
2. Run `scripts/publish-update.sh` on the Mac holding the Sparkle signing key. It builds the universal app, copies the ZIP into `site/downloads/v<version>/`, writes a checksum, signs the archive using the login Keychain, and adds a signed enclosure to `site/appcast.xml`.
3. Review the generated feed and package, commit the site files, and push to `main`. GitHub Pages deploys the new archive and feed. Keep GitHub Releases linking to the website; do not attach an unsigned ZIP.

Never export the private key into the repository, app bundle, GitHub Pages, or CI logs. Losing the key prevents publishing verified updates for already installed builds.
