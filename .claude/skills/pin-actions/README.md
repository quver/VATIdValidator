# pin-actions — GitHub Actions SHA Pinner

Resolves GitHub Actions version tags to immutable commit SHAs for secure
workflow pinning, eliminating supply-chain risk from mutable tags.

## Why pin to SHA?

A tag like `actions/checkout@v4` can be silently redirected. A compromised
upstream repo can point `v4` at malicious code. Pinning to the exact SHA
(`actions/checkout@abc123...`) freezes the exact code that runs in CI.

## Claude Code skill invocation

```
/pin-actions actions/checkout actions/setup-node
/pin-actions actions/checkout@v4
```

## Direct script usage

```bash
# Auto-detect backend (gh CLI preferred, curl fallback)
./scripts/pin-actions.sh actions/checkout

# Specific tag
./scripts/pin-actions.sh actions/checkout@v4.2.2

# Multiple actions at once
./scripts/pin-actions.sh actions/checkout actions/setup-node@v4 actions/cache

# Force gh CLI backend
./scripts/pin-actions.sh --method gh actions/checkout

# Force curl backend (requires token)
export GITHUB_TOKEN=ghp_yourtoken
./scripts/pin-actions.sh --method curl actions/checkout

# Inline token
./scripts/pin-actions.sh --method curl --token ghp_yourtoken actions/checkout
```

## Example output

```
uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
uses: actions/setup-node@39370e3970a6d050c480ffad4ff0ed4d3fdee5af  # v4.1.0
```

Paste directly into your workflow YAML:

```yaml
steps:
  - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
  - uses: actions/setup-node@39370e3970a6d050c480ffad4ff0ed4d3fdee5af  # v4.1.0
```

## Authentication

| Method | Requirement |
|--------|-------------|
| `gh` CLI (default) | `gh auth login` already run |
| `curl` | `GITHUB_TOKEN` or `GH_TOKEN` env var, or `--token` flag |

Unauthenticated requests are subject to GitHub's 60 req/hour rate limit.
A token raises this to 5,000 req/hour.

## Environment variables

| Variable | Description |
|----------|-------------|
| `GITHUB_TOKEN` | GitHub PAT (classic or fine-grained, `read:public_repo` scope) |
| `GH_TOKEN` | Alternative token variable (same semantics) |
| `METHOD` | `gh` or `curl` — overrides auto-detection |

## How annotated vs lightweight tags are handled

GitHub Actions most commonly use **annotated tags** (e.g. `v4`). The Git
objects model has two levels:

```
ref/tags/v4  →  tag object (SHA-1 A)
                  └─ commit object (SHA-1 B)   ← this is what we want
```

The script always dereferences annotated tags to the underlying **commit SHA**
via `GET /repos/{owner}/{repo}/git/tags/{sha}`. Lightweight tags point
directly to a commit and need no extra step.

## Running tests

```bash
# Unit tests only (no network required)
bash tests/test-pin-actions.sh

# All tests including integration (requires GitHub auth)
INTEGRATION=1 bash tests/test-pin-actions.sh
```

## Files

```
.claude/skills/pin-actions/
├── SKILL.md                  Claude Code skill definition
├── README.md                 This file
├── scripts/
│   └── pin-actions.sh        Main script (both gh and curl implementations)
└── tests/
    └── test-pin-actions.sh   Unit + integration test suite
```
