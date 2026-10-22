# Changelog

This is a feature history, not a claim that every earlier version had a public GitHub release.

## 1.2.1

- Add a small footer button linking to the maintainer's GitHub profile.
- Remove rejoin failures from the current known-issues list: the maintainer reports no recurrence in recent use as of October 22, 2026. This is a status update, not a new rejoin implementation.
- Remove unused player-closing and URL-delivery helpers, redundant identity data, and inactive reconnect state.
- Clarify closed-player retention comments and shorten internal design notes.
- Add regression checks for duplicate process tracking and running-player counts.

## 1.2

- Refreshed native account list, larger avatar presentation, clearer warnings, Add account guidance, and a separate Activity tab.
- Menu-bar operation with explicit Show/Hide controls; incoming Play links stay in the background on cold and warm launch.
- Closing the manager window keeps the app running. Explicit manager opening shows it again.
- Persisted Keep Mac awake preference and confirmation for destructive player controls.
- Added window-policy, real Launch Services delivery, and synthetic visual-render fixtures.
- Public documentation covering setup, limitations, privacy, troubleshooting, development, and signing research.

Remaining known issues: repeated Keychain prompts and incomplete identity/avatar detection. This version does not introduce an automatic rejoin timer. See 1.2.1 for the updated rejoin status.

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
