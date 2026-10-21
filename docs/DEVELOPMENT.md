# Build, test, and release

## Prerequisites

Use macOS 13+ with Apple's Xcode Command Line Tools (or a suitable full Xcode installation). Building is not supported on Windows or Linux.

```sh
xcode-select --install
git clone https://github.com/rlken/RbxMulti.git
cd RbxMulti
swiftc --version
```

Complete any Apple installation/terms prompts yourself. The project uses the system frameworks and command-line tools; no CocoaPods, Swift Package Manager packages, or npm dependencies are required. The repository currently has no open-source license; see the README before reusing or distributing code.

## Build

From the repository root:

```sh
bash build.sh
```

The script **replaces the generated `build/` directory**. Do not store personal files there. It compiles arm64 and x86_64 targets with a macOS 13 deployment minimum, combines them with `lipo`, generates the icon, ad-hoc signs the bundle, and creates:

- `build/RbxMulti.app`
- `build/RbxMulti.zip`

Verify the result:

```sh
codesign --verify --deep --strict build/RbxMulti.app
lipo -archs build/RbxMulti.app/Contents/MacOS/RbxMulti
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' build/RbxMulti.app/Contents/Info.plist
```

This verifies the local signature structure and output metadata, not notarization, malware absence, account safety, or successful gameplay. No certificate secret is required for normal builds.

Launching the real app claims Roblox URL handlers, sets its App Nap preference, and starts the default keep-awake assertion. Do not open a development copy while relying on the installed copy's link routing. Use isolated test fixtures for lifecycle changes.

## Automated tests

```sh
bash Tests/run.sh
bash Tests/run-window-tests.sh
bash Tests/run-link-tests.sh
```

| Test | Coverage / side effects |
| --- | --- |
| `run.sh` | Synthetic player bundles: log parsing, PID association, occupancy after updates, live-slot protection, source preservation, cache reuse, signing, update repair. Uses temporary files; does not launch real Roblox. |
| `run-window-tests.sh` | AppKit window state, manual opening, URL hiding, close-to-background, reopening. Uses a model with runtime services disabled and a fake link handler. Requires a usable macOS GUI session. |
| `run-link-tests.sh` | Actual Launch Services cold/warm URL delivery to a temporary test app. Does not claim Roblox URL schemes or launch Roblox. Leaves the printed temporary directory for inspection; requires a logged-in graphical session. |

GUI tests may not work in a headless SSH/CI session. Default CI runs the non-GUI session tests and universal build; run GUI tests locally before shipping a lifecycle change. Neither suite proves that multiple live accounts can rejoin indefinitely.

The link fixture's output directory contains only the test app and result JSON. Once the probe has exited, move that exact printed temporary directory to Trash if desired.

## Synthetic visual fixtures

These use fake names and no Roblox login/network calls:

```sh
render_dir=$(mktemp -d /tmp/rbxmulti-render.XXXXXX)
swiftc -parse-as-library -D RBXMULTI_TESTING Sources/*.swift Tests/RenderViews.swift -o "$render_dir/render"
"$render_dir/render" "$render_dir"
```

Inspect light, dark, compact, warning, missing-avatar, and empty states. Do not substitute screenshots of real accounts without reviewing them for privacy. Follow [DESIGN.md](../DESIGN.md).

## Live validation checklist

Use accounts you are authorized to access, and do not disturb important running sessions.

- Launch multiple distinct accounts one at a time; verify identity inside each game.
- Confirm Play links leave the manager hidden, manual opening works, and closing the window does not stop players.
- Confirm names/avatars or clear fallback states; test public username fallback.
- Observe the game's own teleport/rejoin separately for each account. Record event time, identity, warnings, and actual connection outcome.
- Check behavior after a Roblox update without modifying active player copies.
- Confirm restore-link/uninstall behavior and keep-awake disable/quit behavior.

Report live results separately from unit/build results. Unknown or untested outcomes stay unknown.

## GitHub Actions and releases

The workflow runs session tests and builds on pushes to main, pull requests, and manual dispatch. It uploads the archive and a SHA-256 checksum as a workflow artifact. A `v*` tag initially publishes a **prerelease** for review. After checking the assets and release notes, the maintainer can promote it to a regular release and mark it Latest. Version 1.2 is published this way; its documented limitations still apply.

Before tagging:

1. Review the source and staged file list for credentials, account data, runtime copies, and logs.
2. Update both version fields in `Info.plist`, README, and CHANGELOG as appropriate. Add the version's release notes and update the workflow's `body_path` to match.
3. Run the test suites and build. Record the limitations and live tests actually performed.
4. Commit and push the reviewed changes.
5. Create an annotated tag matching the new version and push that tag. `v1.2` is already published; do not reuse it.

Do not reuse or move an already published tag. Inspect Actions and the resulting release assets before telling users the download is ready. CI does not install or update any user's app automatically.
