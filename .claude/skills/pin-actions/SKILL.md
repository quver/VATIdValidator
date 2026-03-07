---
name: pin-actions
description: >
  Fetch the latest commit SHA1 for GitHub Actions tags and output pinned
  `uses:` lines ready to paste into workflow YAML files.
  Invoke when the user asks to: pin GitHub Actions, secure a workflow against
  supply-chain attacks, resolve action SHAs, or replace mutable tags with
  commit hashes.
disable-model-invocation: true
allowed-tools: Bash
---

# Pin GitHub Actions to Immutable Commit SHAs

Resolve these actions to exact commit SHAs: $ARGUMENTS

## Step 1 — Run the pinner script

```bash
bash .claude/skills/pin-actions/scripts/pin-actions.sh $ARGUMENTS
```

If that fails with "No API backend available":
- **Option A (gh CLI):** `gh auth login`, then re-run
- **Option B (curl):** `export GITHUB_TOKEN=<pat>`, then re-run with `--method curl`

To force a specific backend:
```bash
# gh CLI
bash .claude/skills/pin-actions/scripts/pin-actions.sh --method gh $ARGUMENTS

# curl + token
bash .claude/skills/pin-actions/scripts/pin-actions.sh --method curl $ARGUMENTS
```

## Step 2 — Apply the results

Show the user the pinned `uses:` lines from stdout in a code block.

Then, if the user's repository contains `.github/workflows/` files that use any
of the resolved actions with mutable tags, offer to update them automatically:

1. Search for matching `uses:` lines with `Grep`
2. Replace mutable tags with the pinned SHA (preserve the `# vX.Y.Z` comment)
3. Show a diff before writing

## Step 3 — Explain why pinning matters

Briefly note that pinning to a SHA prevents an attacker who gains write access
to the upstream action's repository from silently redirecting the tag to
malicious code. The comment `# vX.Y.Z` preserves human-readable context and
makes future version bumps easy to spot.

## Error handling

| Symptom | Likely cause | Suggested fix |
|---------|-------------|---------------|
| "No API backend available" | Neither gh nor token found | `gh auth login` or set `GITHUB_TOKEN` |
| "Authentication failed" | Bad/expired token | Re-authenticate or rotate token |
| "Not found" | Typo in action name | Check the action exists on github.com |
| "Rate limit exceeded" | Too many unauthenticated calls | Authenticate; wait for reset |
| "No tags found" | Action uses releases, not tags | Check repo manually on github.com |
