# RbxMulti 1.2 — public preview

Native macOS multi-instance Roblox launcher. Requires macOS 13+; universal Apple silicon / Intel launcher.

## Download and start

Download RbxMulti.zip and SHA256SUMS.txt from this release, compare the archive checksum, unzip, and move RbxMulti.app into Applications. Open the manager once, then sign in to an account on roblox.com and press Play. Switch accounts in the browser to open additional players.

The app is ad-hoc signed and not Apple-notarized. Review the README's installation and trust guidance before approving any macOS prompt.

## Included

- Per-slot private player copies and account identity/ avatar lookup.
- Redesigned Accounts and Activity views with clearer status and warnings.
- Menu-bar operation: Play links stay in the background; Hide/close keeps the manager running.
- Preserved existing player processes when opening or quitting the manager.
- Session preparation, identity parsing, window policy, and real Launch Services test fixtures.
- Detailed setup, privacy, troubleshooting, build, and contributor documentation.

## Important limits

This is a public preview, not a guaranteed AFK solution. Multi-account teleport/rejoin and repeated Keychain prompts remain unresolved. No 19-minute rejoin timer, input simulation, or auto-clicking is implemented. Player running describes a process, not a verified game connection. Roblox updates can reset a private copy's identity.

There is no automatic updater: quit only the manager, replace its app, and reopen it. Existing running players do not automatically gain updated isolation behavior.

Read the repository README and docs before use. This is unofficial and not affiliated with Roblox. The repository is public but has no open-source license at this time.
