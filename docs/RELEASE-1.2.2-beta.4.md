# RbxMulti 1.2.2-beta.4 — browser launch preview

Browser Play now starts an unmodified, Roblox-signed player copy directly, with a fresh cookie directory for each launch. The manager preserves verified update sources and checks Roblox’s current version before launching. It does not change Keychain permissions or block Keychain access.

## What changed

- **Preserved Roblox's official signature.** Previous versions changed each copy's bundle identifier and re-signed it locally. Those copies had different code identities, which could invalidate remembered Keychain approvals. This version copies the official player without editing or re-signing its bundle.
- **Changed how browser Play launches a client.** RbxMulti receives the browser link and starts the player's executable directly with `-protocolString`. It removes the `/RobloxPlayerUniq` semaphore name before launch so another client can start. Roblox's official bundle identifier is retained.
- **Moved cookie separation out of the app identity.** Each launch gets a fresh profile directory through `CFFIXED_USER_HOME`. This separates the tested cookie stores without changing the player's signature. It does not guarantee that every preference or account-related file is isolated.
- **Prevented repeated use of outdated copies.** RbxMulti retains an untouched, signature-verified source and checks the current Roblox version before preparing a session.
- **Removed the failed Keychain-blocking workaround.** No sandbox restriction, credential deletion, automatic approval, or allow-all-applications permission is used.

## Install

Download RbxMulti.zip, extract it, quit RbxMulti, replace the app in Applications, and reopen it. Quit old Roblox clients when convenient before testing new launches. Sign into the desired account in your browser and click Play normally. The manager stays in the background.

Requires macOS 13+ and an up-to-date official Roblox installation. The manager is a universal Intel/Apple silicon app, ad-hoc signed, not notarized. Updates are manual. There is no open-source license granted.

## First-launch Keychain prompt

If macOS asks Roblox to access `https://www.roblox.com/:SharedROBLOSECURITYForStudio`, check that it is the expected Roblox request, enter your login Keychain password **only in the macOS dialog**, and choose **Always Allow**. Do not enter that password in RbxMulti or send it to anyone.

The maintainer reports that, with this build, choosing Always Allow stopped the prompt on subsequent launches. Preserving the official player signature is intended to let macOS recognize the approved app across copies. This is a tested result on the maintainer's Mac, not a guarantee across all macOS versions, Roblox updates, or replacement of the credential item. If it repeats, report the manager and Roblox versions; do not reset your Keychain.

## Evidence and limitations

Two disposable official-signature clients were tested on Intel macOS 26.6.2. The user reported both signed into different accounts and joined a game without a Keychain prompt. Earlier startup testing did show a prompt: this release does not guarantee prompt-free behavior.

Automated tests cover direct process registration, distinct identities, synthetic protocol arguments, session preparation, and browser URL handling. The maintainer subsequently reported that Always Allow persisted with the new version. Automatic rejoining after 19 minutes, update handoffs, and Apple silicon runtime behavior remain unverified. Shared preferences can still cross profile boundaries. Do not treat this as complete account isolation or an anti-idle solution.

Fresh profiles are stored under ~/Library/Application Support/RbxMulti/Players/slotN/Profiles. Roblox may save credentials and logs there; do not upload that folder. Profiles are retained and can consume disk space. No browser cookies are copied by the manager. Existing profiles are not migrated into new sessions.

If a Keychain prompt appears, report when it occurs; do not reset your Keychain or attach credentials/raw logs. To roll back, quit the manager, install stable 1.2.1, and relaunch players. Stable 1.2.1 still has the original repeated-prompt limitation.
