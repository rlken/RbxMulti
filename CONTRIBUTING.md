# Contributing and reporting problems

Start with [troubleshooting](docs/TROUBLESHOOTING.md) and search existing issues. Report one reproducible problem per issue. Include versions, chip type, account count, steps, exact error text, and sanitized Activity events. Avoid posting account credentials or complete Roblox logs.

There is currently **no open-source license**. Public visibility is not a general grant to reuse or redistribute the code. Contact the owner through an issue before proposing substantial code contributions or reuse, and agree on permissions first. Bug reports and documentation feedback are welcome.

For local development, read [build/test instructions](docs/DEVELOPMENT.md) and [architecture](docs/ARCHITECTURE.md). Keep changes focused. Include what was tested and what remains unverified; never describe a successful build as proof that AFK or teleport behavior is fixed.

Changes must preserve these boundaries:

- Existing players remain running unless the user explicitly closes them.
- Launch tickets, cookies, passwords, and raw logs stay out of commits, screenshots, and CI output.
- App-copy preparation does not modify a running slot or the official Roblox installation.
- Security prompts are not “fixed” by broadening Keychain access or disabling macOS protections.
- New settings explain their scope and limits. Process status is not game connection status.

Do not run the opt-in signing experiment as ordinary setup. Do not use real account credentials in test fixtures.
