> Beta 4 changes the launch architecture: see [current preview behavior and limits](RELEASE-1.2.2-beta.4.md). The description below includes the older stable implementation.

# Architecture

RbxMulti is a native SwiftUI/AppKit application, not a port of a Windows mutex utility. It has no package-manager dependencies or bundled Roblox binaries.

## Source map

| File | Responsibility |
| --- | --- |
| `Sources/AppLifecycle.swift` | AppKit entry point, menu-bar item, explicit window lifecycle, queued URL handling. |
| `Sources/LauncherViews.swift` | Accounts, avatars, warnings, Activity, confirmations, and guidance. |
| `Sources/AutoClicker.swift` | Optional interval-based clicker, F6 shortcut, and permission checks. |
| `Sources/RbxMulti.swift` | Process discovery, launch orchestration, identity/profile requests, URL handlers, wake assertion, and optional process-exit notifications. |
| `Sources/IsolatedPlayer.swift` | Occupancy checks, source selection, per-slot copies, signing, cache verification. |
| `Sources/PlayerSessionLog.swift` | PID-to-open-log association and initial/latest join user-ID parsing. |
| `Info.plist` | Version, URL schemes, minimum macOS version, menu-bar application flag. |

## Browser launch path

1. Launch Services delivers a Roblox URL to the delegate. Cold-start links are queued until startup finishes; link delivery hides rather than opens the manager.
2. The model checks live players and in-flight preparations. Occupancy includes both bundle identifiers and slot paths, because an update can reset the bundle identifier.
3. A serial worker queue chooses a source and prepares a free slot. The installed official app is the starting source; newer eligible cached sources are considered with signature checks.
4. Preparation stages a separate copy, updates metadata, removes its URL scheme registrations, signs it, and verifies it before replacing an idle slot. APFS copy-on-write is attempted, with ordinary copying as a fallback.
5. Before launch, the model checks occupancy again. It requests a new instance of the exact prepared application through Launch Services and passes the URL as `-protocolString`. Beta 3 restores this behavior after the earlier sandbox experiment caused a Keychain save dialog. The beta retains version checking and a verified source cache; see [test results](KEYCHAIN-ISOLATION.md).
6. The returned process must be new and match the expected path and bundle ID. An unexpected result is reported rather than counted as a successful new isolated session.

Normal signing is ad-hoc. The optional certificate configuration is explicitly opt-in and is not a verified Keychain fix.

## Tracking and identity

The model refreshes process state every two seconds and requests identity inspection at intervals longer than five seconds. `lsof` associates a PID with its open `_Player_*_last.log`; timestamps alone are not used to assign identities. Join entries supply the first and latest user IDs. A difference triggers a warning.

When enabled, macOS notifications are sent only when a tracked Roblox process exits. This does not detect an in-game disconnect or automate a rejoin; the user returns through Roblox's browser Play button.

Names and headshots use public Roblox APIs. Process lifetime, game connection state, and account identity are different signals: the first does not prove the other two. New PIDs are discovered independently. Closed rows expire after approximately 90 seconds; there is no general proof that a replacement PID belongs to a prior row.

## Safety boundaries and non-goals

- Do not mutate running private copies or the official installed Roblox app.
- Do not log protocol URLs or obtain browser cookies/passwords.
- Do not claim that signature checks demonstrate Keychain continuity.
- Keep process status distinct from in-game connectivity.
- The optional clicker posts ordinary mouse clicks at the current pointer location in the active app. It does not inject game code. Signed Sparkle updates use the appcast and public key configured in `Info.plist`.
- Opening/hiding/quitting the manager must not implicitly terminate players. Explicit confirmed Close controls are destructive and currently force termination.

Local code preparation tests cannot establish Roblox compatibility or long-running rejoin correctness. Those need separate, consented live tests.
