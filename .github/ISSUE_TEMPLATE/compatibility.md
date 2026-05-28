---
name: Compatibility issue
about: Works on one platform but breaks on another
title: "[compatibility] "
labels: compatibility
assignees: cntrout
---

## What broke

Which file, which step. Quote the error.

## Platform

- OS: (macOS X.Y / Linux distro X / Windows + WSL)
- Shell: (bash / zsh / fish / other; version)
- Claude Code version: (`claude --version`)
- Other relevant: (git version, terminal app, MDM constraints)

## What you tried

Any workarounds attempted. What helped, what didn't.

## Expected vs. actual

The framework targets macOS and Linux as primary. Windows + WSL is best-effort. If you're on a primary platform and it broke, that's a higher-priority report.

## Suggested fix (optional)

If you've identified the cause, paste it. PR not required (and not accepted); a diff in the issue body is fine.
