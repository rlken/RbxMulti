# Privacy, permissions, and local changes

This describes the code in version 1.2.1, not Roblox's own data practices or a guarantee about future builds.

## Data flow

- The browser sends a Roblox protocol URL to RbxMulti, which passes it to the new player as its protocol argument. Those URLs can contain authentication tickets. The app logs only the scheme, not the full launch URL. Process arguments and raw Roblox logs should still be treated as sensitive.
- RbxMulti enumerates local Roblox processes. It uses `lsof` to associate open player log files with their process IDs and reads those files locally to extract numeric user IDs from join telemetry. It does not upload the log contents.
- It requests public profile names from `users.roblox.com` and headshot URLs from `thumbnails.roblox.com`, then loads the returned image. Manual username lookup sends the entered username to Roblox. These network services receive normal connection metadata, including the originating IP address.
- The source contains no analytics/crash-reporting backend for RbxMulti. Roblox and the browser have their own network behavior, outside this utility's control.
- Clicking the footer's GitHub button opens the maintainer's public profile in your default browser. The app does not contact GitHub automatically.
- Account names, detected IDs, avatar URLs, and the last 30 Activity events are held in memory. Keep Mac awake and native window placement are persisted in preferences. The launcher is not a password manager.

## Changes made during normal use

| Location or setting | Purpose |
| --- | --- |
| `/Applications/RbxMulti.app` | Launcher installed by the user. |
| `~/Library/Application Support/RbxMulti/Players/slotN/Roblox.app` | Cached private player app copy. Slots are reused when idle. |
| `source.plist` beside each private app | Source metadata and signature-mode fingerprint used to decide whether to rebuild. |
| `com.rbxmulti.app` preferences | Keep-awake choice and native window settings. |
| `com.roblox.RobloxPlayer` preference `NSAppSleepDisabled` | Set to true when the manager starts; intended to reduce App Nap interference. This does not prove game timers run reliably. |
| `roblox:` and `roblox-player:` default handlers | Set to RbxMulti on manager launch or Enable; restored through the gear menu. |
| A `caffeinate` child process | Prevents idle display/system sleep while enabled and tied to the manager's PID. |

Private copies have a per-slot bundle identifier, display name, and App Nap flag; their protocol registrations are removed, and they are re-signed locally. `/Applications/Roblox.app` is not modified by preparation. The utility does not copy browser cookies into the slot folders. The Roblox player and macOS can store login/session data elsewhere, including cookie stores and Keychain.

Normal setup does not create certificates or change Roblox Keychain access rules. Roblox may request Keychain access under a session app name. Review that request yourself. There is no need to share the login Keychain password with the maintainer.

## Local data and cleanup

Restore Roblox links and quit the launcher before uninstalling. Close all Roblox players before moving the exact `~/Library/Application Support/RbxMulti/Players` folder to Trash. This removes app-copy caches; it is **not** a complete account logout or credential erasure.

Optional preference resets, after quitting the manager:

```sh
# Resets this launcher's settings and window preferences.
defaults delete com.rbxmulti.app

# Removes the Roblox App Nap override set by the launcher.
# Do not do this if you intentionally rely on that setting for another tool.
defaults delete com.roblox.RobloxPlayer NSAppSleepDisabled
```

A “domain/key does not exist” result simply means there was nothing to reset. Reopening RbxMulti writes its App Nap override again. It does not record a prior value, so removing the override does not recover an earlier custom value.

Do not delete whole Roblox preference, cookie, or Keychain collections as routine cleanup. Sign out through Roblox's supported controls if you want to end account access.

The optional signing experiment creates a login-Keychain identity and configuration separately; uninstalling the app does not remove those. See [signing research](SIGNING-RESEARCH.md) before changing them. Never upload any local signing key, certificate export containing a key, runtime log, cookie, or authentication ticket to this repository.
