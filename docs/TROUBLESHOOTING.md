# Troubleshooting

Start by opening the manager → Activity. Record the launcher version, macOS version, chip type, Roblox version, number of players, and exact error text. Confirm whether a single official Roblox player works without RbxMulti before investigating multi-instance behavior.

## Play opens ordinary Roblox or nothing happens

1. Open `/Applications/RbxMulti.app` manually. Keep only one installed manager copy.
2. If the window says Play links are bypassing RbxMulti, press Enable and complete the expected system prompt.
3. In your browser, allow the Play link to open the expected app. Retry once after the first attempt has finished.
4. Check Activity for Link received, preparation failure, or an unexpected-player message.
5. If the official client is missing or broken, restore Roblox links, quit the manager, and reinstall Roblox through its official website.

The manager intentionally stays hidden when it receives Play links. Lack of a manager window is not itself a launch failure.

## The third player returns to the home page

This symptom is not enough to identify one cause. Check the affected row for an account-change or update warning. Confirm the browser is logged in to the intended account and that account is not already playing elsewhere. Wait for preparation to complete; repeated Play clicks can create extra sessions. When ready, close only the affected player and retry from the browser. Preserve the other players.

If it repeats, report whether there was a Roblox update, whether the affected row changes username, and the exact Activity events. Do not share the browser's full launch link. The launcher reserves both running and preparing slots and checks paths as well as bundle IDs, but this does not guarantee all join failures are solved.

## Error 278: idle for 20 minutes

RbxMulti does not reset Roblox's idle timer. Keep Mac awake only affects macOS sleep. A game may provide pre-timeout teleporting, but the launcher does not guarantee that this works across all clients.

Distinguish a game never initiating its rejoin from a rejoin starting and failing. Note which accounts rejoin, whether a warning appears, and the approximate event time/timezone. A late log collection time is not the rejoin time. There is no hidden 19-minute auto-rejoin option in version 1.2.

## Error 276: same account launched elsewhere

This error indicates a competing session for the same account, not the same issue as idle timeout. Check other devices and browser logins. The launcher flags an identity change if one process's join log switches user IDs; it does not prove which external session caused it.

Separate per-slot app identities reduce one source of shared-cookie identity collisions. Roblox updates can undo that identity change; look for Roblox updated · relaunch needed. When safe, close and relaunch the affected account through RbxMulti. This is a diagnostic/recovery step, not a verified permanent fix.

## Keychain asks again after Always Allow

A private player copy has a different signature from the official app; rebuilding it can change the identity used in Keychain access checks. Roblox itself may also replace the copy. Repeated approval is a known issue, not a configuration step that users have failed to perform.

Check the requesting app and item carefully. Do not give passwords to the launcher or share them in issues. Do not allow all applications to access Roblox credentials, disable Keychain protections, or delete credential items as a generic workaround. Cancelling a request can affect login/rejoin.

The local certificate experiment is **not a fix**: code-signature verification passed, but a separately rebuilt dummy app failed the Keychain continuity test with `errSecAuthFailed` (-25293). See [research notes](SIGNING-RESEARCH.md). No tested prompt-free setup is offered in this release.

## Session preparation failed

- Verify the official `/Applications/Roblox.app` is installed and launches normally.
- Check free disk space and permissions on your user Application Support directory. Do not run the launcher as root.
- Check that `/usr/bin/codesign` and Apple's command-line tools are available. If needed, run `xcode-select --install` and complete Apple's installer yourself.
- If you explicitly enabled signing research, an invalid configuration or missing private key makes preparation fail rather than silently falling back. Follow the research notes to disable that opt-in configuration; ordinary users do not need it.
- Never replace or delete a slot while its Roblox process is running. Close that player before cache maintenance.

## Username is Account N or avatar is missing

Automatic identity comes from `game_join_loadtime` entries in the log file actually open by that process. A player still on the home page, a missing entry, permissions, or a changed log format can prevent detection. Public profile/headshot requests can fail independently.

Join a game and give the scan time to run. Use the row's menu → Edit account name… and enter the **username**, not a display name, to try a public lookup. Manual naming is a fallback, not verification of the logged-in account. Labels are not persisted as a login vault, and a detected identity may overwrite a manual label.

## Disconnected players remain listed

The account list monitors processes, not the game's connection state. A disconnect dialog leaves its process running, so that row remains. Close the player when you want to remove it; after the process exits, its row clears in approximately 90 seconds, or immediately via Clear closed players. That command does not remove live disconnected clients.

## Window does not stay open / cannot find the manager

Receiving a Play link hides the manager by design. Use the stacked-windows menu-bar icon → Show accounts or open RbxMulti manually. Hide and the red close button do not quit it. No Dock icon is expected for a menu-bar utility. Quit RbxMulti from its menu to stop the manager.

## Reporting safely

Use the [bug report form](https://github.com/rlken/RbxMulti/issues/new/choose). Include reproduction steps, expected/actual behavior, error code, versions, and relevant sanitized Activity lines. Crop screenshots to the problem and blur names if desired.

Do not attach entire raw Roblox logs, process command lines, or launch URLs: they can contain authentication material. URL removal alone does not guarantee a log is safe. Never include `.ROBLOSECURITY`, ticket values, headers, cookies, Keychain exports, passwords, private-server access links, or unrelated personal information.
