# RbxMulti

Run multiple Roblox accounts on one Mac with a native menu-bar launcher.

**Version 1.2.3 · macOS 13+ · Apple silicon and Intel**

**[Download 1.2.3 from the website](https://rlken.github.io/RbxMulti/#download)** — adds an optional clicker for general accessibility and app testing, with a Roblox frontmost-app guard. Browser Play continues to use separate player instances. See the [user guide](docs/USAGE.md#auto-clicker).

**First launch:** macOS may ask RbxMulti for Accessibility and Input Monitoring access if you enable the Auto Clicker. Grant only the permissions you want to use; the Start/Stop button works without the global F6 shortcut permission.

[Download](https://rlken.github.io/RbxMulti/#download) · [User guide](docs/USAGE.md) · [Troubleshooting](docs/TROUBLESHOOTING.md) · [Report a bug](https://github.com/rlken/RbxMulti/issues/new/choose)

## Features

- Open separate Roblox players from browser Play links.
- See account names, avatars, running processes, and session warnings.
- Show or close individual players and view recent launch activity.
- Keep the manager in the menu bar without opening its window on every Play click.
- Optionally keep your Mac awake while the manager runs.
- Use the optional Auto Clicker for general accessibility and app testing; it stops when Roblox comes to the front.
- Optionally receive a macOS notification when a tracked Roblox player process closes.

## Install

Requires macOS 13 or later and the official Roblox app, preferably installed at `/Applications/Roblox.app`. Roblox must work normally on your Mac first. Each extra player uses additional memory and storage; Roblox is not included in the download.

1. Download **RbxMulti.zip** from the [RbxMulti website](https://rlken.github.io/RbxMulti/#download).
2. Unzip it and move **RbxMulti.app** into Applications. Keep only one installed copy.
3. Open RbxMulti once and confirm any expected link-opening prompts.
4. Check that the manager says **Play links ready**.

The app is ad-hoc signed, **not Apple-notarized**. If macOS blocks it, review [Apple's guidance](https://support.apple.com/en-us/102445) and approve it only if you trust the source. Do not disable Gatekeeper globally or ignore malware warnings. See the [user guide](docs/USAGE.md#verify-a-download) for checksum verification.

## Open multiple accounts

1. Sign in to your first account on [roblox.com](https://www.roblox.com) and press **Play**.
2. Wait for the player to open.
3. Sign out in the browser, sign in to a different account, and press Play again.

Repeat for additional accounts. Avoid “log out of all sessions” and opening the same account twice. RbxMulti does not save passwords or guarantee that accounts join the same server.

## Keep it in the background

Click **Hide**, press Command-H, or close the manager window. RbxMulti stays in the menu bar, and your Roblox players remain open.

To reopen the manager, use its stacked-windows menu-bar icon → **Show accounts**. Play links stay in the background; the Roblox player itself may still come forward.

**Quit RbxMulti** stops the manager and its keep-awake function, not your players. Another Play click can start the manager again.

## Important limitations

- **No Roblox automation.** The optional Auto Clicker is blocked while Roblox is the frontmost app and stops if Roblox comes forward. It is for other apps, accessibility, and app testing only.
- **Keychain prompts may repeat**, including after “Always Allow.” The experimental signing option is not a fix and is disabled by default.
- **Player running means the process exists**, not that it is connected to a game. A disconnected player remains listed until its process closes.
- **Roblox updates can reset session isolation.** Relaunch an affected player when the manager warns you.
- Names and avatars depend on readable player logs and Roblox's public APIs; placeholders may appear.
- **Keep Mac awake does not prevent Roblox's idle timeout.** It increases power use and cannot guarantee operation through sleep or network loss.

See [troubleshooting](docs/TROUBLESHOOTING.md) for errors 276/278, missing avatars, launch failures, and Keychain prompts.

## Update or uninstall

There is **no automatic updater**. Quit the manager, replace the app in Applications with the new download, and reopen it. Running players need their own relaunch to pick up isolation changes.

To stop using RbxMulti, select the gear menu → **Restore Roblox links…**, then quit the manager. You can then move its app to Trash. See [cleanup instructions](docs/PRIVACY.md#local-data-and-cleanup) before removing player caches or settings.

## More information

- [User guide](docs/USAGE.md): controls, status labels, checksums, and background behavior
- [Privacy](docs/PRIVACY.md): network requests, local storage, and permissions
- [Build and test](docs/DEVELOPMENT.md) · [Architecture](docs/ARCHITECTURE.md) · [Changelog](CHANGELOG.md)
- [Contributing](CONTRIBUTING.md) · [Signing research](docs/SIGNING-RESEARCH.md)
- [Website source](site/index.html)

Never include cookies, authentication tickets, full launch URLs, Keychain contents, or raw Roblox logs in public reports.

Unofficial and not affiliated with Roblox. Use only accounts you are authorized to access and follow Roblox's and each experience's rules.

**License:** RbxMulti source code is released under the [MIT License](LICENSE). This license does not grant rights to Roblox's software, assets, or trademarks.
