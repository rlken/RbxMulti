# Keychain isolation experiment — withdrawn in 1.2.2-beta.3

## Follow-up checks — November 6, 2026

### Official-signature profile test: authenticated launch passed

Two disposable copies of the preserved Roblox 0.746 client retained their verified Roblox vendor signatures and original bundle identifiers. Each was started directly with its own `CFFIXED_USER_HOME` directory; the singleton semaphore name was removed before launch. No Keychain access restriction, ACL modification, credential extraction, or application re-signing was applied.

The initial short smoke test produced a user-reported prompt. On the subsequent controlled run, the user reported no prompt for either client, without completing a new Always Allow approval. The user then signed into different accounts inside those test windows and reported that both joined the same game without a prompt. Therefore this demonstrates successful authenticated launch in that run, **not** persistence of a newly granted approval or guaranteed absence of future prompts.

Remaining gates: both accounts must retain their identities through the game's automatic rejoin; test browser-ticket launches, fresh profile creation, restart persistence, and Roblox updates before replacing the installed launch architecture. Foundation preferences were not isolated reliably by the earlier synthetic profile test, so the successful join result alone does not establish complete account-storage isolation. Installed beta 3 remains unchanged.

### External implementation review

RORORO's [ADR 0010](https://github.com/estevanhernandez-stack-ed/rororo-mac/blob/main/docs/decisions/0010-keychain-prompt-elimination.md) reports Roblox deleting its placeholder Studio-sharing item during launch, forcing repopulation each time. This is evidence from that project, not proof of the exact write sequence on this Mac. It supports investigating replacement of the item, not only changes in app signatures, as the reason approvals disappear.

RORORO suppresses prompts by prepending an empty-password Keychain containing an item with an allow-any-app ACL. Its own ADR acknowledges that Roblox may write a real credential into that item. Do not adopt this as a safe placeholder-only mechanism.

[Toolblox's macOS implementation notes](https://toolblox.dev/docs/app/background-services/#macos) describe directly launching the unmodified official executable after removing the singleton semaphore name. This preserves the vendor signature and avoids re-signing copies. It does not establish per-account cookie isolation or correct teleport identity; replacing RbxMulti's isolation with that mechanism alone could reintroduce the original account collisions. The profile-directory tests above therefore remain relevant. This is a candidate architectural direction, not a verified fix.

- Installed version remains beta 3. No additional changes were installed during these checks.
- Two identical, disposable app bundles tested with `CFFIXED_USER_HOME` kept fake HTTP cookies separate, but `UserDefaults` values crossed profiles. Adding `__CFPREFERENCES_AVOID_DAEMON=1` did not preserve separate preference values across restarts. These switches are not a verified replacement for session isolation. No real Roblox cookies were used.
- Inspection of the preserved Roblox 0.746 binary found the Studio-sharing log group and credential-save messages, but no identifiable switch to disable that specific request. A log-group name is not a supported feature toggle. Broad cookie-management flags were not changed.
- Repeated authorization remains unresolved. Do not repeat the ACL-list, self-signed-certificate, or Keychain-blocking experiments as purported fixes, and do not publish these betas as prompt-free.

**The sandbox approach failed live testing and is no longer used.** Beta 2 reached the game, but macOS displayed “Keychain Not Found” when Roblox tried to store its shared Studio credential. Cancel dismissed the dialog. Resetting Keychain defaults is not a remedy for this launcher-induced failure and must not be recommended.

Beta 3 restores Launch Services launching with no additional Keychain restriction. It retains the update-source cache and version check. Already running restricted players retain their restrictions until they exit; replacing the manager cannot change another process's sandbox. No saved credentials, Keychain ACLs, or search lists were changed by this rollback.

The old implementation lives under `Tests/Experiments`, outside the application's build inputs. Its tests disabled Keychain interaction and exercised existing-item reads, updates, and deletion. They did not cover the interactive credential-creation failure seen in Roblox. Passing those tests was insufficient evidence for a prompt-free client.

The original repeated authorization prompt remains unresolved. Version 1.2.1 remains the published release; no beta has been promoted as a fix. The following sections record the failed experiment, not current application behavior.

## Why the previous workaround failed

Adding session copies to the shared Studio credential's approved-app list was not durable. The list contained ten session paths after approval, but a later metadata-only inspection found just one. Updated player copies also had different versions and signatures. This establishes that the saved approvals did not persist; it does not establish which process replaced them. Repeating that manual setup is not the proposed solution.

## Beta 1 live-test failure and beta 2 changes

The first live test still produced a Keychain prompt. The session had updated from Roblox 0.745.0.7451137 to 0.746.0.7461264 and the running replacement had the vendor bundle identifier instead of the session identifier. The restricted startup smoke test did not cover this updater handoff.

Beta 2 preserves an untouched, vendor-signature-verified source under `Players/Sources/<version>/Roblox.app` before preparing session copies. Previously an updated slot could be the only current vendor-signed source; re-signing that slot made it ineligible as a source on the next launch, so an older installed copy could be chosen again. The preserved source remains reusable across launches.

Before each browser launch, an ephemeral, cookie-free HTTPS request checks Roblox's public MacPlayer version endpoint for the link's validated channel (LIVE by default). Only a matching local version can launch. A failed check or missing version produces an error asking the user to retry or update the official app; it does not launch a known outdated copy. This does not download or install Roblox updates automatically. It also cannot eliminate a version change between the check and launch or guarantee what a future updater does.

The updated 0.746.0.7461264 copy on the test Mac was successfully checked against the live version endpoint, preserved, verified with Roblox's Apple-issued signing requirement, and selected again as the latest source. The subsequent authenticated launch exposed the credential-save dialog described above; beta 2 failed the release gate.

## Candidate change

The withdrawn `Tests/Experiments/PlayerLauncher.swift` starts each prepared player directly through macOS `sandbox-exec`. Its profile denies file reads and writes under the user's `Library/Keychains`, including the resolved path if that directory is a symlink. Other operations remain allowed. The manager's own access is unchanged.

On the tested Mac this prevents a child process from obtaining or modifying a disposable login-Keychain item, without presenting an approval dialog. It avoids editing real credentials, granting additional applications access, changing the Keychain search order, or patching Roblox's executable. The browser's normal launch ticket is still passed as one argument and is never written to manager diagnostics.

There is no unrestricted fallback if the restricted launch fails. Existing players are unaffected; only newly launched processes use the restriction. The manager checks the child's PID, bundle identifier, and exact application path before tracking it.

## Validation so far

- Two disposable AppKit players registered separately and received exact synthetic protocol arguments, including punctuation and spaces.
- Each fixture executable created and successfully read its own uniquely named dummy login-Keychain item without restrictions. The same executable, launched with the restriction, could not read, update, or delete it. An unrestricted invocation then verified it was unchanged and deleted it. This controls for ordinary app-specific Keychain approval differences.
- A child HTTPS request to Roblox succeeded with the system curl and its inherited restrictions.
- A disposable real Roblox 0.745.0.7451137 copy reached its sign-in screen without a Keychain prompt.
- Existing session-isolation, AppKit window, and real Launch Services link-delivery tests passed. The universal arm64/x86_64 build passed signature verification. The installed candidate's executable hash matches the tested build.

These results do not prove authenticated gameplay or rejoining. Testing was on macOS 26.6.2, Intel. Apple silicon and other supported macOS versions have not been exercised with this candidate.

## Release gates

Before promoting this to a public fix, verify distinct accounts joining concurrently, no prompt when switching accounts or opening another client, each account's automatic in-game rejoin, and behavior after Roblox updates. Verify that updater or Launch Services handoffs do not start an unrestricted replacement. Confirm normal foreground behavior and closing/reopening the manager.

`sandbox-exec` is deprecated and may change or disappear in future macOS versions. This profile covers the normal per-user Keychain directory, not custom Keychains stored elsewhere. Blocking access may affect Roblox features that rely on Keychain data; authenticated testing is required. It is not a general security boundary against an adversarial application.

## Historical tests (not a fix or release gate)

```sh
# Launch two temporary GUI fixtures; no Keychain items or real accounts used.
bash Tests/run-player-launch-tests.sh

# Explicit opt-in: creates two uniquely named dummy login-Keychain items,
# tests the restriction and HTTPS, then deletes those dummy items.
bash Tests/run-player-launch-tests.sh --allow-disposable-keychain-item
```

The opt-in test requires an unlocked login Keychain and network access. It disables interactive Keychain authorization for the test processes and does not query Roblox credentials. It attempts cleanup on assertion failures and reports the exact dummy service if cleanup fails. It is not included in default CI. Temporary fixture directories are printed for inspection.

To roll back the local candidate, quit only RbxMulti, replace it with the published 1.2.1 app, and reopen it. Players already running retain their original launch restrictions until closed. No real Keychain changes need undoing.
