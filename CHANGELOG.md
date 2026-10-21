# Changelog

This is a feature history, not a claim that every earlier version had a public GitHub release.

## 1.2

- Refreshed native account list, larger avatar presentation, clearer warnings, Add account guidance, and a separate Activity tab.
- Menu-bar operation with explicit Show/Hide controls; incoming Play links stay in the background on cold and warm launch.
- Closing the manager window keeps the app running. Explicit manager opening shows it again.
- Persisted Keep Mac awake preference and confirmation for destructive player controls.
- Added window-policy, real Launch Services delivery, and synthetic visual-render fixtures.
- Public documentation covering setup, limitations, privacy, troubleshooting, development, and signing research.

Known issues remain: multi-account rejoin/idle disconnections, repeated Keychain prompts, and incomplete identity/avatar detection. This version does not introduce an automatic rejoin timer.

## 1.1.1

- Count occupied private slots by application path as well as bundle ID after Roblox updates.
- Prefer newer eligible official player copies when preparing a session.
- Warn when an update removes a running slot's expected identity; do not rebuild it while running.
- Validate that launch returns a new player at the intended path and identity.

## 1.1

- Separate app identifiers and locally signed copies per concurrent slot.
- Detect identity from the log actually held open by each player.
- Flag changed account IDs during rejoin.
- Leave existing players open when starting the manager.

## Signing research (not released as a fix)

A local certificate experiment passed code-identity checks but failed a separate rebuilt-app Keychain continuity test. It remains disabled by default. See [research notes](docs/SIGNING-RESEARCH.md).
