# RbxMulti 1.2.2

Launch multiple Roblox accounts from your browser while RbxMulti runs quietly in the menu bar. This update changes how clients start so they retain Roblox’s official signature, allowing macOS to recognize the approved app across copies.

## What changed

- **Official Roblox signatures are preserved.** Player copies are no longer given modified bundle identifiers or re-signed locally—the previous approach could cause macOS to ask for Keychain approval again.
- **Browser Play uses the new launcher.** Each Play link starts the official player executable directly with its launch ticket. RbxMulti handles Roblox’s single-instance semaphore so additional clients can open.
- **Separate cookie directories.** Each launch receives a fresh profile through `CFFIXED_USER_HOME`, without modifying the Roblox application bundle.
- **Verified update sources.** The launcher checks the current Roblox version and preserves an untouched, signature-verified source for preparing clients.
- **Normal Keychain access restored.** The earlier blocking workaround has been removed. RbxMulti does not delete credentials or broaden their access permissions.

## Install or update

1. Download **RbxMulti.zip** below and extract it.
2. Quit RbxMulti and your old Roblox clients.
3. Replace **RbxMulti.app** in Applications, then open it.
4. Sign into Roblox in your browser and press **Play**.
5. Switch browser accounts and press **Play** again to open another client.

Requires macOS 13+ and an up-to-date Roblox installation. The download includes Intel and Apple silicon builds. RbxMulti is ad-hoc signed and is not Apple-notarized. Updates are installed manually.

## One-time Keychain approval

If macOS displays the expected Roblox request for **SharedROBLOSECURITYForStudio**, enter your login Keychain password in that system dialog and select **Always Allow**. Never enter that password into RbxMulti or send it to anyone.

In the maintainer’s testing, Always Allow stopped the prompt on subsequent launches with this version. Two different accounts also joined a game successfully using the new launch method.

The maintainer confirmed that automatic rejoining works with the new launch method. Build and launch tests also passed.

**Downloads:** `RbxMulti.zip` contains the app; `SHA256SUMS.txt` lets you verify the archive.
