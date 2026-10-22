Requires macOS 13+ and the official Roblox app. Supports Apple silicon and Intel.

## Changes

- Add a small GitHub profile button in the manager's footer.
- Remove unused helpers and inactive session-tracking state without changing launch behavior.
- Update rejoin status: the maintainer reports no recurrence in recent use. Rejoin failures are no longer listed as a current known issue; this release does not add new rejoin logic.

## Install or update

Download **RbxMulti.zip**, unzip it, and move **RbxMulti.app** into Applications. Quit the manager before replacing an older copy, then reopen it. Existing Roblox players can stay open.

The app is ad-hoc signed and **not Apple-notarized**. **SHA256SUMS.txt** is included for download verification. See the [installation guide](https://github.com/rlken/RbxMulti#install).

## Notes

Keychain prompts may still repeat. Names and avatars depend on player logs and Roblox's public APIs. Rejoining is handled by the game; RbxMulti does not simulate input or reset the idle timer.

[User guide](https://github.com/rlken/RbxMulti/blob/main/docs/USAGE.md) · [Troubleshooting](https://github.com/rlken/RbxMulti/blob/main/docs/TROUBLESHOOTING.md)

Unofficial; not affiliated with Roblox. No open-source license has been granted.
