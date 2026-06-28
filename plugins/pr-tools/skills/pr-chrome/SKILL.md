---
name: pr-chrome
description: Use when the user wants to open a GitHub pull request in Google Chrome (e.g. "이 PR 크롬에서 열어줘", "PR 크롬으로 열어줘", "open this PR in chrome") — resolves the PR for the current branch, or an explicit PR number, and opens its URL with `open -a "Google Chrome"` on macOS.
argument-hint: '[PR number]'
---

# pr-chrome

Open a GitHub pull request in Google Chrome on the local Mac.

## Procedure

1. Resolve the PR URL with `gh` (pass `--repo owner/name` if not run from inside the repo):
   - Explicit PR number argument:
     ```bash
     gh pr view <NUMBER> --json url -q .url
     ```
   - Otherwise the current branch's PR:
     ```bash
     gh pr view --json url -q .url
     ```
2. Open it in Chrome:
   ```bash
   open -a "Google Chrome" "<url>"
   ```
3. Confirm with the URL that was opened.

## Notes

- If the current branch has no PR, `gh pr view` exits non-zero — report that instead of guessing a URL. Only run `gh pr create` if the user asks.
- macOS only (`open -a`); requires Google Chrome to be installed. `gh pr view --web` would respect the default browser instead, so this skill forces Chrome explicitly.
- This opens the PR in the browser; to keep a stacked-PR series section in sync, use **pr-stack**.
