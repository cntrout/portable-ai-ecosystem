# Security Policy

## Scope

This is a personal AI workflow framework released as MIT-licensed open source. It runs locally on the user's device via Claude Code; the repo itself does not host services, run code, or process user data in any centralized way.

Security concerns worth reporting fall into a few categories:

1. **Vulnerabilities in shipped scripts** (`scripts/bootstrap.sh`, `.claude/hooks/session-start.sh`) that could cause unintended file modifications, privilege escalation, or arbitrary code execution
2. **Vulnerabilities in shipped skills** that could cause Claude to leak data outside the user's intended boundaries or modify files outside the working folder
3. **Supply-chain issues** with the repo itself: tampering, account compromise, malicious commits to `main`
4. **Documentation issues** that would lead a user to take an action with security implications (e.g., misleading IT-approval ask, unsafe default permissions in `settings.json.template`)

## Supported versions

The repo is a single ongoing release. Always pull `main` for the latest. Older commits are not separately supported.

## How to report

Open a GitHub issue with the prefix `[security]` in the title. For sensitive issues (a vulnerability that has not yet been disclosed publicly), you can also DM the maintainer on GitHub at @cntrout.

## What to expect

- Acknowledgment within 7 days
- A decision within 14 days on whether to fix, document as a known limitation, or decline (with reasoning)
- A fix landing in `main` if accepted, with a note in the commit message that references the report

This framework is not production-critical infrastructure. Response times reflect the personal-project nature of the repo. If a vulnerability needs faster response than this offers, please calibrate accordingly.

## Out of scope

- Bugs that affect functionality but have no security implication (open a regular issue)
- Concerns about MIT license terms or use-case appropriateness (the MIT license is the license)
- Requests for security features that would dilute the framework's design (fork it and add what you need)
