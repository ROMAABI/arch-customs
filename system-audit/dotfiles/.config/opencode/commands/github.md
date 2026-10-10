---
description: Push current project to the correct GitHub repo (reuse origin, ask, or create)
agent: build
---
Load the `github-push` skill via the skill tool and follow `~/.config/opencode/skills/github-push/SKILL.md` exactly.

Invocation: /github $ARGUMENTS

1. Inspect the current working directory: `git status`, `git log`, `git remote -v`, top-level files.
2. If origin exists, push there. If not, use $ARGUMENTS as the target repo hint when provided (formats: `owner/repo`, `repo`, or `new:repo-name [--public]`); otherwise ask the user whether to pick an existing repo or create one.
3. Commit pending changes if any, then push via git HTTPS + PAT per the skill. Never print tokens.
4. Report commit SHA, old..new range, and remote URL.
