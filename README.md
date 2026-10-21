# RbxMulti for macOS

A native macOS menu-bar launcher for running multiple Roblox accounts in separate player instances. Sign in through your browser, press Play, and manage the players from one account list.

**Current version: 1.2 · macOS 13+ · Apple silicon and Intel**

> **Experimental compatibility utility.** RbxMulti is not an official Roblox product, an anti-idle tool, or a guarantee of uninterrupted AFK play. Multi-account teleport/rejoin problems and recurring macOS Keychain prompts remain unresolved. Read [known limitations](#known-limitations) before using it with important sessions.

[Releases](https://github.com/rlken/RbxMulti/releases) · [Troubleshooting](docs/TROUBLESHOOTING.md) · [Privacy and permissions](docs/PRIVACY.md) · [Build and test](docs/DEVELOPMENT.md) · [Changelog](CHANGELOG.md) · [Report a bug](https://github.com/rlken/RbxMulti/issues/new/choose)

## What it does

- Opens separate Roblox players from browser Play links without intentionally closing existing players.
- Prepares a separate, locally signed Roblox app copy for each occupied session slot, with a distinct macOS application identifier to separate cookie-store identities.
- Detects usernames from each player's own join log and loads public Roblox avatar headshots when available.
- Shows process status, elapsed time since launch, account-change warnings, and update/isolation warnings.
- Provides per-player Show, Edit account name, and confirmed Close controls, plus a separate Activity tab.
- Runs in the menu bar. Roblox links do not open the manager window; manual opening does.
- Optionally keeps the Mac awake while the manager runs. Closed-process rows disappear after about 90 seconds.

## Requirements

- macOS 13 Ventura or later. The launcher builds as a universal app; Roblox itself must also support your Mac and macOS version.
- The official Roblox desktop app installed, preferably at `/Applications/Roblox.app`, and working normally for one account first.
- An internet connection, browser access to your Roblox accounts, and enough memory/storage for additional players. Each player runs a full Roblox client; resource use depends on the experience and settings.
- Apple's developer command-line tools may be needed if local player signing fails. See [preparation errors](docs/TROUBLESHOOTING.md#session-preparation-failed).

Roblox is not bundled in this repository or the launcher download. There is no fixed supported account-count guarantee and no Windows/Linux build.

## Install

1. Download `RbxMulti.zip` from a release on this repository. If no binary release is available, [build from source](docs/DEVELOPMENT.md).
2. If a release includes `SHA256SUMS.txt`, compare the archive's checksum before extracting:

   ```sh
   cd ~/Downloads
   shasum -a 256 RbxMulti.zip
   ```

   Compare the output with the release checksum. A checksum detects mismatches; it is not a developer identity or notarization guarantee.
3. Unzip the archive and move `RbxMulti.app` into Applications. Keep one installed launcher copy to avoid ambiguous Play-link handling.
4. Open RbxMulti manually once. It registers itself to handle `roblox-player:` and `roblox:` links. Confirm any expected macOS/browser prompt only after checking the application name.
5. Look for **Play links ready** in the manager. Its stacked-windows icon remains in the macOS menu bar.

The app is ad-hoc signed, **not Apple-notarized or Developer ID signed**. macOS may block its first launch. Review [Apple's guidance for opening downloaded apps](https://support.apple.com/en-us/102445); only approve an exception if you trust the source. Do not disable Gatekeeper globally or ignore a malware warning. Building from reviewed source is another option.

## Use multiple accounts

1. Open RbxMulti from Applications.
2. In your browser, sign in to the first account on [roblox.com](https://www.roblox.com), select an experience, and press **Play**.
3. Wait for the player to finish opening. Preparing a new slot can take longer than reusing one.
4. Sign out **in the browser**, then sign in to a different account. Do not use “log out of all sessions,” which can affect active sessions.
5. Press Play again. Repeat for each additional account, letting each launch finish before starting the next.
6. Check the account names and actual game windows. The launcher does not guarantee that players join the same server; use the experience's normal join/friend/private-server flow where supported.

RbxMulti does not store account passwords or offer a saved-account login vault. A slot number identifies an app copy, not a permanent binding to one account. Avoid opening the same account in two places at once.

### Background operation

- **Hide**, Command-H, or the red window-close button keeps the launcher running in the menu bar.
- A browser Play link is handled in the background, even if the launcher starts from that link. The Roblox player can still come to the foreground.
- Choose the stacked-windows menu-bar icon → **Show accounts**, or open RbxMulti manually, to see the manager again.
- **Quit RbxMulti** ends the manager and its keep-awake assertion, but does not deliberately close the Roblox players. It does not restore the URL handlers; another Play link can start RbxMulti again.
- The app does not install a login item or automatically start when you log in to macOS.

### Account list and controls

| Item | Meaning |
| --- | --- |
| Detecting account… | The player is running, but its user ID has not been found in a readable join log. |
| Player running | A Roblox process exists. It may still be loading, on the home page, or disconnected. |
| Account changed during rejoin | The same process's join log reports a different user ID than its initial join. Investigate before leaving it unattended. |
| Roblox updated · relaunch needed | An update changed the private copy's identifier. Relaunch that account when ready to restore isolation. |
| Player closed | The process ended; its row is retained briefly, then removed. |
| Show | Brings that player's window forward. |
| Edit account name… | Allows a public username lookup when automatic identification is missing. Labels are not a saved account configuration. |
| Close player… / Close all players… | Force-closes the selected processes after confirmation; unfinished game progress can be lost. |

**Activity** lists recent manager events, not a complete Roblox log. **Keep Mac awake** is saved between launcher runs and defaults to on. It prevents idle display/system sleep through `caffeinate`; it does not simulate input, reset Roblox's idle timer, or guarantee operation with the lid closed, after manual sleep, or through a network interruption. Expect additional battery and power use.

## Known limitations

- **AFK and rejoin:** the app does not implement a 19-minute rejoin timer, auto-click Reconnect, inject game scripts, or prevent Roblox's idle timeout. A game's own teleport/rejoin may work for one account and fail for others. Windows multi-instance behavior is not proof of equivalent macOS behavior.
- **Account collision / Error 276:** separate app identities address one possible shared-login cause, but multi-account rejoin is not verified reliable. Another session using the same account can also cause this error. See [troubleshooting](docs/TROUBLESHOOTING.md).
- **Keychain prompts:** “Always Allow” may not persist when private copies are rebuilt or replaced. An opt-in self-signing experiment did not solve this. It is disabled by default and is not normal setup.
- **Roblox updates:** Roblox can replace a private copy and reset its application identity. The launcher warns rather than replacing a running player's files. Restart the affected player when safe.
- **Status accuracy:** disconnected players with live processes remain in the list. The app cannot reliably identify every in-game disconnection or automatically remove those rows.
- **Names and avatars:** log format changes, missing join events, network errors, or Roblox API limits can prevent lookup. A placeholder is expected in these cases; automatic retry coverage is limited.
- **Compatibility:** future Roblox/macOS changes can break launching or session separation. Ad-hoc re-signing changes the private copy's trust identity. No promise is made about platform approval, account safety, or game-rule compliance.

Only use accounts you are authorized to access and follow Roblox's and the experience creator's rules. This project is not affiliated with, endorsed by, or supported by Roblox Corporation.

## Update

There is **no automatic updater**. Download a newer release, quit the RbxMulti manager from its menu-bar menu, replace `/Applications/RbxMulti.app`, then reopen it. Existing game processes are left alone by the manager; close/relaunch them yourself when needed to apply player-isolation changes. Updating only the manager cannot repair an already running player's login storage.

## Restore normal Roblox launching or uninstall

1. Open RbxMulti and choose the gear menu → **Restore Roblox links…** → confirm.
2. Quit RbxMulti from its menu-bar menu. Opening it again registers its link handlers again.
3. Move `/Applications/RbxMulti.app` to Trash if uninstalling.
4. Optionally reclaim private-copy storage **after closing every Roblox player**: in Finder → Go → Go to Folder, open `~/Library/Application Support/RbxMulti/Players` and move that exact folder to Trash. Do not remove Roblox's own app or shared Library folders.

This does not delete Roblox account data, Keychain items, or system cookie stores. See [local data and preference cleanup](docs/PRIVACY.md#local-data-and-cleanup) for remaining settings and experimental-signing caveats.

## For developers and contributors

Read [development instructions](docs/DEVELOPMENT.md), [architecture](docs/ARCHITECTURE.md), [design conventions](DESIGN.md), and [contribution guidance](CONTRIBUTING.md). Tests cover session preparation, identity parsing, and window/link behavior; passing them does not prove unattended gameplay works.

Please keep bug reports reproducible and sanitized. **Never post `.ROBLOSECURITY` cookies, authentication tickets, complete launch URLs, Keychain contents, or unreviewed raw Roblox logs.**

## License

This repository is public for visibility, but **no open-source license has been granted at this time**. Do not assume permission to reuse, modify, or redistribute the code beyond rights otherwise available to you. Contact the owner before reuse. No rights to Roblox's software, assets, or trademarks are granted by this repository.
