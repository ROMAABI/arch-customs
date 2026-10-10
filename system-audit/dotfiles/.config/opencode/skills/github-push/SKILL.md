---
name: github-push
description: Read the current project directory and push it to the correct GitHub repo — reuse origin if set, ask which repo if ambiguous, or create a suitable repo. Git transport via HTTPS + PAT, never MCP.
triggers:
  - push to github
  - push this project
  - publish repo
  - create github repo
  - upload to github
---

# GitHub-Push Skill

Push the current project to GitHub. MCP (including `api.githubcopilot.com/mcp`)
covers the GitHub **API** only — it has no push/commit tool. All git transport
goes through plain `git` over HTTPS authenticated with a PAT.

## 1. Inspect the project

- `git status --short`, `git log --oneline -5`, `git remote -v`
- List top-level files to understand what the project is (name, language,
  README presence) — needed to propose a repo name if creating one.

## 2. Determine the target repo

- **Origin exists** → push there. Confirm `owner/repo` with the user only if
  the directory name and remote disagree.
- **No origin, user names a repo** → verify it exists and is writable before
  committing:
  `git ls-remote https://github.com/OWNER/REPO.git HEAD`
- **No repo yet** → propose a name from the directory + README, ask for
  confirmation (private vs public), then create it:
  - Preferred: `gh repo create NAME --private --source=. --remote=origin`
    (requires `gh auth login` once per machine).
  - Fallback without `gh`: create via API with the PAT, then
    `git remote add origin https://github.com/OWNER/REPO.git`.
- **NEVER** push to a remote the user did not confirm when no origin exists.
- **NEVER** commit secrets — scan `git status` / `git diff` for keys, tokens,
  passwords before staging.

## 3. Commit (if needed)

- Stage only intended files (`git add -A` after review, or scoped paths).
- If no git identity is configured, commit with an explicit local fallback
  and tell the user how to fix it:
  `git -c user.name=spix -c user.email=spix@abix commit -m "..."`
  Fix: `git config user.name … && git config user.email … &&
  git commit --amend --reset-author --no-edit`

## 4. Push with the PAT (never print it)

- Preferred (one-time setup, then automatic everywhere):
  `gh auth login --with-token < TOKEN_FILE` + `gh auth setup-git`,
  then plain `git push`.
- Fallback when `gh` is not authenticated — PAT from secure storage
  (e.g. `~/.config/github-mcp-token`, mode 600, or the OpenCode MCP config),
  used only via a credential helper so the token never appears in commands
  or output:

  ```bash
  git -c credential.helper='!f() { echo username=x-access-token; echo password=$(cat TOKEN_FILE); }; f' \
    push origin BRANCH
  ```

- If the PAT must transit through a temp file, create it with mode 600 under
  `/tmp/opencode/` and `rm -f` it immediately after the push.
- If push fails with 403: the PAT is expired or lacks **Contents: read+write**
  on the repo — tell the user to regenerate it, update the token file, and
  re-run `gh auth login`.

## 5. Report

- Commit SHA, `old..new` range, remote URL, branch.
- State which repo was chosen/created and why.
- If push was impossible (no credentials), give the exact command for the
  user to run: `git push origin BRANCH`.
