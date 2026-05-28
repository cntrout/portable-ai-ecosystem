# Contributing

Thanks for your interest in this framework.

## Posture

This repo is published as MIT-licensed open source for educational use and adaptation. External commits are NOT accepted on the canonical repo at `main`. The framework encodes one person's specific working style: voice rules, naming conventions, decision history, opinionated playbooks. External contributions would dilute that consistency.

**If you want to use this framework, fork it.** The MIT license permits adaptation, modification, redistribution, and use for any purpose, including commercial.

## What's welcome

- **Bug reports.** Open an issue if something doesn't work as documented (broken script, wrong path, missing file).
- **Documentation clarity issues.** Open an issue if something in the README, INSTALL, or a playbook is confusing or wrong.
- **Compatibility issues.** Open an issue if a script breaks on a supported platform (the framework targets macOS and Linux; Windows is best-effort).
- **Security concerns.** See `SECURITY.md`.
- **Notes on how you've forked or adapted the framework.** Issues with the `[adaptation]` prefix are welcome; I find them interesting.

## What will be closed without action

- Pull requests of any kind (fork the repo instead)
- "Please add feature X for my use case" requests (fork the repo and add it)
- "Please change voice rules to match my style" requests (fork and customize `voice/` for yours)
- "Please support tool stack Y" requests (fork and adapt)

These aren't dismissive responses. They're a clear signal that the right move is to fork.

## How to fork productively

1. Fork the repo on GitHub
2. Follow `INSTALL.md` on your own device
3. Run the `engagement-bootstrap-from-urls` skill against your engagement's public URLs to populate the engagement layer
4. Customize the voice files (`Universal/FOLLOW-workflows-and-guides/voice/do-not.md`, `personal.md`, `formats.md`) to reflect your own writing style
5. Adapt playbooks to your team's conventions
6. Use your fork as your own working ecosystem
7. If you publish derivative work, include the MIT license notice with the original copyright

## Why the framework is opinionated

The voice files, folder framework, playbooks, and decision protocols are tightly coupled. The framework works as a system; pulling one piece out and replacing it with a different opinion often breaks the rest. Forking lets you make those swaps cleanly inside your own copy without arguing them through on the canonical repo.

## Cross-references

- Main playbook: `Universal/FOLLOW-workflows-and-guides/playbooks/portable-ai-ecosystem.md`
- Install steps: `INSTALL.md`
- License: `LICENSE`
- Security policy: `SECURITY.md`
