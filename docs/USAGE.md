# User guide

Start with the [README](../README.md) for installation and your first launch. This guide covers the additional controls and behaviors.

## Verify a download

Download `RbxMulti.zip` and `SHA256SUMS.txt` from the same release into the same folder. In Terminal, change to that folder and run:

```sh
cd ~/Downloads
shasum -a 256 -c SHA256SUMS.txt
```

Confirm `RbxMulti.zip: OK` before extracting. A checksum detects a mismatch; it does not establish developer identity or notarization. The launcher is ad-hoc signed, not Developer ID signed or Apple-notarized.

## Launching accounts

Wait for each player to finish opening before pressing Play for the next account. New session copies can take longer to prepare than cached ones. A slot number identifies an app copy, not a permanent account assignment.

RbxMulti uses separate application identities to separate cookie-store identities. It does not save account passwords or provide a login vault. Confirm the intended account inside each game, especially after a rejoin. Joining the same server requires the experience's normal join/friend/private-server flow where supported.

The launcher is macOS-only. The universal binary supports Apple silicon and Intel, but Roblox itself must also support your hardware and operating system. Account capacity depends on your Mac and the experience; there is no guaranteed maximum. If signing tools are unavailable, see [preparation errors](TROUBLESHOOTING.md#session-preparation-failed).

## Account status and controls

| Item | Meaning |
| --- | --- |
| Detecting account… | The process is running, but its user ID has not been found in a readable join log. |
| Player running | A Roblox process exists. It may be loading, on the home page, or disconnected. |
| Account changed during rejoin | The same process's join log reports a different user ID than its initial join. Check that player's account. |
| Roblox updated · relaunch needed | An update changed the private copy's identifier. Relaunch that account when ready to restore isolation. |
| Player closed | The process ended. Its row clears after approximately 90 seconds. |
| Show | Brings that player's window forward. |
| Edit account name… | Looks up an entered public username and avatar when automatic identification is missing. Labels are not saved account configurations. |
| Close player… / Close all players… | Force-closes the selected processes after confirmation. Unfinished game progress can be lost. |
| Clear closed players | Removes stopped-process rows immediately, but not disconnected players whose processes are still running. |

**Activity** shows the last 30 manager events, not a full Roblox log. Account names and avatars depend on player logs and public Roblox APIs. A manual username is a fallback, not proof of which account is logged in.

## Background operation and sleep

- Hide, Command-H, or the red close button keeps the manager in the menu bar. No Dock icon is expected.
- Show accounts or manually opening RbxMulti restores its window. Receiving a Play link hides it again.
- Quit RbxMulti stops the manager and its keep-awake assertion, without deliberately closing players. It does not restore Roblox's URL handlers; another Play link can restart the manager.
- No login item is installed. RbxMulti does not automatically start when you log in to macOS.

**Keep Mac awake** defaults to on and is saved between launches. It prevents idle display/system sleep through `caffeinate`. It does not send game input, reset Roblox's idle timer, or guarantee operation with a closed lid, after manual sleep, or through a network interruption. Expect higher battery and power use.

## Updates and removal

Manager updates are manual. Quit RbxMulti, replace its app in Applications, then reopen it. Existing players are left alone; relaunch them when needed to apply isolation changes. Updating the manager does not repair an already running player's login storage.

To restore ordinary Roblox launching, choose the gear menu → Restore Roblox links… and confirm, then quit RbxMulti. Opening the manager again registers its link handlers again.

After uninstalling the launcher, you can reclaim its private-copy storage by closing **all Roblox players**, then moving the exact `~/Library/Application Support/RbxMulti/Players` folder to Trash through Finder. Do not remove Roblox's own app or broad Library folders. This does not delete account credentials or sign out of Roblox. See [privacy and cleanup](PRIVACY.md#local-data-and-cleanup) for remaining preferences and experimental signing data.
