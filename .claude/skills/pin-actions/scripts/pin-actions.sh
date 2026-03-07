#!/usr/bin/env bash
# pin-actions.sh
#
# PURPOSE:
#   Resolve GitHub Actions version tags (e.g. v4, v4.1.0) to their exact commit
#   SHA1. This allows pinning workflow steps to immutable references, eliminating
#   the supply-chain risk of mutable tags being redirected to different commits.
#
# USAGE:
#   ./pin-actions.sh [OPTIONS] ACTION [ACTION ...]
#
# OPTIONS:
#   --method, -m  gh|curl   API backend (default: auto — prefers gh, falls back to curl)
#   --token,  -t  TOKEN     GitHub token (overrides env vars)
#   --help,   -h            Show this help
#
# ARGUMENTS:
#   owner/repo              Resolve latest semver tag for this action
#   owner/repo@vX.Y.Z       Resolve a specific tag
#
# ENVIRONMENT VARIABLES:
#   GITHUB_TOKEN / GH_TOKEN  Authentication token (required for curl backend)
#   METHOD                   gh | curl (alternative to --method flag)
#
# EXAMPLES:
#   ./pin-actions.sh actions/checkout
#   ./pin-actions.sh actions/checkout@v4 actions/setup-node@v4
#   METHOD=curl ./pin-actions.sh actions/checkout
#   ./pin-actions.sh --method curl --token ghp_xxx actions/checkout
#
# OUTPUT (stdout):
#   uses: actions/checkout@abc123def456  # v4.2.2
#   (ready to paste into .github/workflows/*.yml)
#
# COMPATIBILITY: bash 3.2+ (macOS system bash), python3

set -euo pipefail

# ── Terminal colours (disabled when stderr is not a TTY, e.g. CI pipelines) ──
if [[ -t 2 ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'
  YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RESET='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; RESET=''
fi

# ── Configuration ─────────────────────────────────────────────────────────────
METHOD="${METHOD:-auto}"          # auto → prefer gh CLI, fallback to curl
TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
API_BASE="https://api.github.com"

# Use indexed arrays (compatible with bash 3.2 — macOS default).
# Associative arrays require bash 4.0+, which is not available by default on macOS.
ACTIONS=()

# ── Usage ─────────────────────────────────────────────────────────────────────
usage() {
  cat >&2 <<'EOF'
Usage: pin-actions.sh [OPTIONS] ACTION [ACTION ...]

Resolve GitHub Actions tags to immutable commit SHAs for secure workflow pinning.

OPTIONS:
  --method, -m  gh|curl    API backend (default: auto-detect)
  --token,  -t  TOKEN      GitHub token (or set GITHUB_TOKEN / GH_TOKEN)
  --help,   -h             Show this help

ACTIONS:
  owner/repo               Latest semver tag for this action
  owner/repo@vX.Y.Z        Specific version tag

EXAMPLES:
  pin-actions.sh actions/checkout
  pin-actions.sh actions/checkout@v4 actions/setup-node@v4
  pin-actions.sh --method curl actions/checkout

ENVIRONMENT:
  GITHUB_TOKEN / GH_TOKEN  GitHub personal access token
  METHOD                   gh | curl (alternative to --method flag)
EOF
}

# ── Argument parsing ──────────────────────────────────────────────────────────
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --method|-m)
        [[ $# -ge 2 ]] || { echo -e "${RED}Error:${RESET} --method requires a value" >&2; exit 1; }
        METHOD="$2"; shift 2 ;;
      --token|-t)
        [[ $# -ge 2 ]] || { echo -e "${RED}Error:${RESET} --token requires a value" >&2; exit 1; }
        TOKEN="$2"; shift 2 ;;
      --help|-h) usage; exit 0 ;;
      --) shift; ACTIONS+=("$@"); break ;;
      -*) echo -e "${RED}Error:${RESET} Unknown option '$1'. Use --help for usage." >&2; exit 1 ;;
      *)  ACTIONS+=("$1"); shift ;;
    esac
  done
}

# ── Method auto-detection ─────────────────────────────────────────────────────
resolve_method() {
  if [[ "$METHOD" == "auto" ]]; then
    if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
      METHOD="gh"
    elif [[ -n "$TOKEN" ]]; then
      METHOD="curl"
    elif command -v gh &>/dev/null; then
      # gh installed but may not be authenticated — try anyway (CI environments
      # often set GITHUB_TOKEN which gh picks up automatically)
      METHOD="gh"
    else
      echo -e "${RED}Error:${RESET} No API backend available." >&2
      echo -e "  Install gh CLI (https://cli.github.com) and run 'gh auth login'," >&2
      echo -e "  or set GITHUB_TOKEN / GH_TOKEN for the curl backend." >&2
      exit 1
    fi
  fi

  if [[ "$METHOD" != "gh" && "$METHOD" != "curl" ]]; then
    echo -e "${RED}Error:${RESET} --method must be 'gh' or 'curl', got '$METHOD'" >&2
    exit 1
  fi

  if [[ "$METHOD" == "curl" && -z "$TOKEN" ]]; then
    echo -e "${RED}Error:${RESET} curl backend requires a GitHub token." >&2
    echo -e "  Set GITHUB_TOKEN or GH_TOKEN, or use --token <token>." >&2
    exit 1
  fi

  if [[ "$METHOD" == "gh" ]] && ! command -v gh &>/dev/null; then
    echo -e "${RED}Error:${RESET} gh CLI not found. Install from https://cli.github.com" >&2
    exit 1
  fi
}

# ── Shared: semver-aware tag sorter ──────────────────────────────────────────
# Reads newline-separated tag names from stdin, prints the best candidate.
# Preference order: full semver (vX.Y.Z) > partial (vX.Y) > major alias (vX).
#
# Implementation note: we read stdin into a shell variable first, then pass it
# as a command-line argument to python3. This avoids the heredoc/pipe conflict
# where `python3 - <<'EOF'` uses the heredoc as python3's stdin (for the script
# source), which would silently consume the piped tag list before Python sees it.
best_tag() {
  local input
  input=$(cat)   # consume the piped tag list before invoking python3
  python3 -c '
import sys, re

tags = [t.strip() for t in sys.argv[1].split("\n") if t.strip()]
if not tags:
    sys.exit(1)

def semver_key(tag):
    # Priority by specificity: 3=X.Y.Z, 2=X.Y, 1=X, 0=non-numeric
    m = re.match(r"^v?(\d+)\.(\d+)\.(\d+)", tag)
    if m: return (3, int(m.group(1)), int(m.group(2)), int(m.group(3)))
    m = re.match(r"^v?(\d+)\.(\d+)", tag)
    if m: return (2, int(m.group(1)), int(m.group(2)), 0)
    m = re.match(r"^v?(\d+)", tag)
    if m: return (1, int(m.group(1)), 0, 0)
    return (0, 0, 0, 0)

# Prefer full X.Y.Z semver tags when available
full = [t for t in tags if re.match(r"^v?\d+\.\d+\.\d+", t)]
candidates = full if full else tags
print(sorted(candidates, key=semver_key)[-1])
' "$input"
}

# ── Shared: extract a field from JSON using python3 ──────────────────────────
# json_field <json_string> <dot.separated.path>
# Avoids a hard dependency on jq.
json_field() {
  local json="$1" path="$2"
  python3 -c "
import sys, json
d = json.loads(sys.argv[1])
for k in sys.argv[2].split('.'):
    d = d[k]
print(d)
" "$json" "$path"
}

# ═══════════════════════════════════════════════════════════════════════════════
# IMPLEMENTATION A: gh CLI
#
# Uses the official GitHub CLI. Automatically handles authentication tokens,
# follows system proxy settings, and provides cleaner error messages.
# Best choice for interactive developer use.
# ═══════════════════════════════════════════════════════════════════════════════

# Return the best tag name for owner/repo
gh_latest_tag() {
  local owner="$1" repo="$2"
  local output exit_code=0

  # --paginate fetches all pages; --jq '.[].name' streams tag names from each page's array
  output=$(gh api "repos/$owner/$repo/tags" \
    --paginate \
    --jq '.[].name' 2>&1) || exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    _gh_handle_error "$output" "$owner/$repo"
    return 1
  fi
  if [[ -z "$output" ]]; then
    echo -e "${RED}Error:${RESET} '$owner/$repo' has no tags" >&2
    return 1
  fi

  echo "$output" | best_tag
}

# Resolve tag name → commit SHA using gh api
# Handles both annotated tags (need extra deref step) and lightweight tags.
gh_resolve_sha() {
  local owner="$1" repo="$2" tag="$3"
  local ref_json exit_code=0

  ref_json=$(gh api "repos/$owner/$repo/git/refs/tags/$tag" 2>&1) || exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    _gh_handle_error "$ref_json" "$owner/$repo" "$tag"
    return 1
  fi

  local obj_type obj_sha
  obj_type=$(json_field "$ref_json" "object.type")
  obj_sha=$(json_field "$ref_json" "object.sha")

  if [[ "$obj_type" == "tag" ]]; then
    # Annotated tag: the sha points to a tag *object*, not a commit.
    # We must dereference the tag object to obtain the underlying commit sha.
    local tag_json exit_code2=0
    tag_json=$(gh api "repos/$owner/$repo/git/tags/$obj_sha" 2>&1) || exit_code2=$?
    if [[ $exit_code2 -ne 0 ]]; then
      echo -e "${RED}Error:${RESET} Could not dereference annotated tag '$tag'" >&2
      return 1
    fi
    json_field "$tag_json" "object.sha"
  else
    # Lightweight tag: the sha IS the commit sha directly.
    echo "$obj_sha"
  fi
}

_gh_handle_error() {
  local output="$1" action="${2:-unknown}" tag="${3:-}"
  if   echo "$output" | grep -qiE "HTTP 404|not found"; then
    local target
    if [[ -n "$tag" ]]; then target="tag '$tag' in '$action'"; else target="action '$action'"; fi
    echo -e "${RED}Error:${RESET} Not found: $target" >&2
  elif echo "$output" | grep -qiE "HTTP 401|HTTP 403|unauthorized|forbidden"; then
    echo -e "${RED}Error:${RESET} Authentication failed. Run 'gh auth login' or check token permissions." >&2
  elif echo "$output" | grep -qiE "HTTP 429|rate.?limit"; then
    echo -e "${RED}Error:${RESET} GitHub API rate limit exceeded. Authenticate or wait for reset." >&2
  else
    echo -e "${RED}Error:${RESET} gh API call failed: $output" >&2
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# IMPLEMENTATION B: curl + GitHub REST API
#
# Uses curl directly with GITHUB_TOKEN. No additional tools required beyond
# curl and python3, which are available in virtually all CI environments.
# Best choice for automated pipelines and environments without gh CLI.
# ═══════════════════════════════════════════════════════════════════════════════

# Thin wrapper around curl for GitHub REST API calls.
# Returns response body on success; prints error to stderr and returns 1 on failure.
_curl_api() {
  local endpoint="$1"

  # Use a temp file to separate response body from the HTTP status code.
  # --write-out only writes to stdout, so we capture body separately.
  local tmp
  tmp=$(mktemp)
  # Ensure temp file is always cleaned up, even on error
  # shellcheck disable=SC2064
  trap "rm -f '$tmp'" RETURN

  local http_code
  http_code=$(curl --silent --show-error \
    --write-out "%{http_code}" \
    --output "$tmp" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "$API_BASE/$endpoint" 2>&1)

  local response
  response=$(<"$tmp")

  case "$http_code" in
    200|201)
      echo "$response" ;;
    401|403)
      echo -e "${RED}Error:${RESET} Authentication failed (HTTP $http_code). Check your token." >&2
      return 1 ;;
    404)
      echo -e "${RED}Error:${RESET} Resource not found (HTTP 404): $API_BASE/$endpoint" >&2
      return 1 ;;
    429)
      local msg
      msg=$(python3 -c "import sys,json; print(json.loads(sys.argv[1]).get('message',''))" \
        "$response" 2>/dev/null || true)
      echo -e "${RED}Error:${RESET} GitHub API rate limit exceeded (HTTP 429). $msg" >&2
      return 1 ;;
    *)
      local msg
      msg=$(python3 -c "import sys,json; print(json.loads(sys.argv[1]).get('message',''))" \
        "$response" 2>/dev/null || echo "$response")
      echo -e "${RED}Error:${RESET} API error HTTP $http_code: $msg" >&2
      return 1 ;;
  esac
}

curl_latest_tag() {
  local owner="$1" repo="$2"
  local json
  json=$(_curl_api "repos/$owner/$repo/tags?per_page=100") || return 1

  local count
  count=$(python3 -c "import sys,json; print(len(json.loads(sys.argv[1])))" "$json")
  if [[ "$count" == "0" ]]; then
    echo -e "${RED}Error:${RESET} '$owner/$repo' has no tags" >&2
    return 1
  fi

  python3 -c "
import sys, json
for t in json.loads(sys.argv[1]):
    print(t['name'])
" "$json" | best_tag
}

curl_resolve_sha() {
  local owner="$1" repo="$2" tag="$3"
  local ref_json
  ref_json=$(_curl_api "repos/$owner/$repo/git/refs/tags/$tag") || return 1

  local obj_type obj_sha
  obj_type=$(json_field "$ref_json" "object.type")
  obj_sha=$(json_field "$ref_json" "object.sha")

  if [[ "$obj_type" == "tag" ]]; then
    local tag_json
    tag_json=$(_curl_api "repos/$owner/$repo/git/tags/$obj_sha") || {
      echo -e "${RED}Error:${RESET} Could not dereference annotated tag '$tag'" >&2
      return 1
    }
    json_field "$tag_json" "object.sha"
  else
    echo "$obj_sha"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# ORCHESTRATION
# ═══════════════════════════════════════════════════════════════════════════════

# Dispatch to the appropriate backend (set via $METHOD)
get_latest_tag() { "${METHOD}_latest_tag" "$@"; }
resolve_sha()    { "${METHOD}_resolve_sha" "$@"; }

# Process a single action specifier (owner/repo or owner/repo@tag).
# Diagnostics → stderr; result line → stdout.
process_action() {
  local spec="$1"

  # Split on '@' to get the path and optional tag hint
  local action_path tag_hint=""
  if [[ "$spec" == *"@"* ]]; then
    action_path="${spec%%@*}"
    tag_hint="${spec##*@}"
  else
    action_path="$spec"
  fi

  # Validate: must match owner/repo with no extra slashes or invalid chars
  if [[ ! "$action_path" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
    echo -e "${RED}Error:${RESET} Invalid action format '$spec'." >&2
    echo -e "  Expected: owner/repo  or  owner/repo@vX.Y.Z" >&2
    return 1
  fi

  local owner="${action_path%%/*}"
  local repo="${action_path##*/}"

  echo -e "${BLUE}→${RESET} $action_path" >&2

  # Resolve tag: use the hint if provided, otherwise fetch the latest semver tag
  local tag
  if [[ -n "$tag_hint" ]]; then
    tag="$tag_hint"
    echo -e "  Tag : $tag (pinned)" >&2
  else
    tag=$(get_latest_tag "$owner" "$repo") || return 1
    echo -e "  Tag : ${GREEN}$tag${RESET}" >&2
  fi

  # Resolve the tag to a commit SHA (handles annotated and lightweight tags)
  local sha
  sha=$(resolve_sha "$owner" "$repo" "$tag") || return 1
  echo -e "  SHA : ${GREEN}$sha${RESET}" >&2

  # Emit the ready-to-paste workflow line to stdout
  printf 'uses: %s@%s  # %s\n' "$action_path" "$sha" "$tag"
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  parse_args "$@"

  if [[ ${#ACTIONS[@]} -eq 0 ]]; then
    echo -e "${RED}Error:${RESET} No actions specified." >&2
    echo "" >&2
    usage
    exit 1
  fi

  resolve_method

  echo "" >&2
  echo -e "${BLUE}GitHub Actions Pinner${RESET}  [backend: $METHOD]" >&2
  echo "─────────────────────────────────────────────" >&2

  local failed=0

  # Use parallel indexed arrays to preserve insertion order of results.
  # (Associative arrays require bash 4.0+ — not available on macOS system bash 3.2)
  local result_specs=()
  local result_lines=()

  local spec result exit_code
  for spec in "${ACTIONS[@]}"; do
    exit_code=0
    result=$(process_action "$spec") || exit_code=$?
    if [[ $exit_code -eq 0 && -n "$result" ]]; then
      result_specs+=("$spec")
      result_lines+=("$result")
    else
      failed=$(( failed + 1 ))
    fi
    echo "" >&2
  done

  # Print clean results block to stdout (pasteable into workflow YAML)
  if [[ ${#result_lines[@]} -gt 0 ]]; then
    echo "─────────────────────────────────────────────" >&2
    echo -e "${GREEN}Pinned steps (paste into your workflow YAML):${RESET}" >&2
    echo "" >&2
    local i
    for i in "${!result_lines[@]}"; do
      echo "${result_lines[$i]}"
    done
  fi

  [[ $failed -eq 0 ]] || exit 1
}

# Guard allows sourcing this file in tests without running main()
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
