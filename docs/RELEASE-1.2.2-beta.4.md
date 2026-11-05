# RbxMulti 1.2.2-beta.4 — browser launch preview

Browser Play now starts an unmodified, Roblox-signed player copy directly, with a fresh cookie directory for each launch. The manager preserves verified update sources and checks Roblox’s current version before launching. It does not change Keychain permissions or block Keychain access.

## Install

Download RbxMulti.zip, extract it, quit RbxMulti, replace the app in Applications, and reopen it. Quit old Roblox clients when convenient before testing new launches. Sign into the desired account in your browser and click Play normally. The manager stays in the background.

Requires macOS 13+ and an up-to-date official Roblox installation. The manager is a universal Intel/Apple silicon app, ad-hoc signed, not notarized. Updates are manual. There is no open-source license granted.

## Evidence and limitations

Two disposable official-signature clients were tested on Intel macOS 26.6.2. The user reported both signed into different accounts and joined a game without a Keychain prompt. Earlier startup testing did show a prompt: this release does not guarantee prompt-free behavior.

Automated tests cover direct process registration, distinct identities, synthetic protocol arguments, session preparation, and browser URL handling. Real browser-ticket authentication with this integrated build, automatic rejoining after 19 minutes, update handoffs, and Apple silicon runtime behavior remain unverified. Shared preferences can still cross profile boundaries. Do not treat this as complete account isolation or an anti-idle solution.

Fresh profiles are stored under ~/Library/Application Support/RbxMulti/Players/slotN/Profiles. Roblox may save credentials and logs there; do not upload that folder. Profiles are retained and can consume disk space. No browser cookies are copied by the manager. Existing profiles are not migrated into new sessions.

If a Keychain prompt appears, report when it occurs; do not reset your Keychain or attach credentials/raw logs. To roll back, quit the manager, install stable 1.2.1, and relaunch players. Stable 1.2.1 still has the original repeated-prompt limitation.
