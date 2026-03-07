#!/usr/bin/env bash
# test-pin-actions.sh
#
# Test suite for pin-actions.sh
#
# UNIT TESTS:  Run without network access; mock API calls via function overrides.
# INTEGRATION: Marked [INTEGRATION] — require GitHub access; skipped by default.
#
# Usage:
#   ./test-pin-actions.sh                 # unit tests only
#   INTEGRATION=1 ./test-pin-actions.sh  # include integration tests

# set -e intentionally omitted: test subshells must not abort the whole suite
# on assertion failures; each section captures errors and reports them.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../scripts/pin-actions.sh"

# ── Minimal test harness ──────────────────────────────────────────────────────
# Counters live in temp files so subshells can share them (bash variables are
# not propagated back to the parent shell from a subshell).
_PASS_F=$(mktemp); _FAIL_F=$(mktemp); _SKIP_F=$(mktemp)
echo 0 > "$_PASS_F"; echo 0 > "$_FAIL_F"; echo 0 > "$_SKIP_F"
trap 'rm -f "$_PASS_F" "$_FAIL_F" "$_SKIP_F"' EXIT

_inc() { local f="$1"; echo $(( $(cat "$f") + 1 )) > "$f"; }

if [[ -t 1 ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; RESET=''
fi

assert_contains() {
  local desc="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    echo -e "  ${GREEN}PASS${RESET} $desc"
    _inc "$_PASS_F"
  else
    echo -e "  ${RED}FAIL${RESET} $desc"
    echo     "       expected to contain: $needle"
    echo     "       actual output:       $(echo "$haystack" | head -3)"
    _inc "$_FAIL_F"
  fi
}

assert_not_contains() {
  local desc="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    echo -e "  ${RED}FAIL${RESET} $desc (found unexpected: $needle)"
    _inc "$_FAIL_F"
  else
    echo -e "  ${GREEN}PASS${RESET} $desc"
    _inc "$_PASS_F"
  fi
}

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo -e "  ${GREEN}PASS${RESET} $desc"
    _inc "$_PASS_F"
  else
    echo -e "  ${RED}FAIL${RESET} $desc"
    echo     "       expected: $expected"
    echo     "       actual:   $actual"
    _inc "$_FAIL_F"
  fi
}

assert_exit_nonzero() {
  local desc="$1"; shift
  local code=0
  "$@" &>/dev/null || code=$?
  if [[ $code -ne 0 ]]; then
    echo -e "  ${GREEN}PASS${RESET} $desc (exited $code)"
    _inc "$_PASS_F"
  else
    echo -e "  ${RED}FAIL${RESET} $desc (expected non-zero exit, got 0)"
    _inc "$_FAIL_F"
  fi
}

skip_test() {
  echo -e "  ${YELLOW}SKIP${RESET} $1"
  _inc "$_SKIP_F"
}

section() { echo -e "\n${YELLOW}▶ $1${RESET}"; }

# ── Helper: run the main script, capturing combined output ────────────────────
run_script() {
  bash "$SCRIPT" "$@" 2>&1 || true
}

# ── Helper: source the script's functions into current shell (test context) ───
# The BASH_SOURCE guard in pin-actions.sh prevents main() from running on source.
# set +e before source so that function definitions with non-zero subexpressions
# don't abort the test subshell.
source_script() {
  set +e
  # shellcheck disable=SC1090
  source "$SCRIPT"
  set +e   # keep off — tests check exit codes manually
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 1: Argument validation (no network required)
# ═══════════════════════════════════════════════════════════════════════════════
section "Argument validation"

out=$(run_script)
assert_contains "no args → prints error" "No actions specified" "$out"

out=$(run_script --help)
assert_contains "--help prints usage header" "Usage:" "$out"

out=$(run_script -h)
assert_contains "-h prints usage header" "Usage:" "$out"

out=$(run_script --method bad actions/checkout)
assert_contains "bad --method value → error" "must be 'gh' or 'curl'" "$out"

out=$(run_script bad-format-no-slash)
assert_contains "bare name (no slash) → format error" "Invalid action format" "$out"

out=$(run_script owner/repo/extra)
assert_contains "triple-slash path → format error" "Invalid action format" "$out"

out=$(run_script --method curl actions/checkout)
assert_contains "curl without token → token error" "requires a GitHub token" "$out"

out=$(run_script --unknown-flag actions/checkout)
assert_contains "unknown flag → error" "Unknown option" "$out"

assert_exit_nonzero "no args → non-zero exit" bash "$SCRIPT"
assert_exit_nonzero "bad method → non-zero exit" bash "$SCRIPT" --method bad actions/checkout

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 2: json_field helper (no network required)
# ═══════════════════════════════════════════════════════════════════════════════
section "json_field helper"

(
  source_script

  result=$(json_field '{"object":{"type":"tag","sha":"abc123"}}' "object.type")
  assert_eq "nested string field" "tag" "$result"

  result=$(json_field '{"object":{"type":"commit","sha":"def456"}}' "object.sha")
  assert_eq "sha field" "def456" "$result"

  result=$(json_field '{"name":"v4.2.2"}' "name")
  assert_eq "top-level field" "v4.2.2" "$result"
)

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 3: best_tag semver sorter (no network required)
# ═══════════════════════════════════════════════════════════════════════════════
section "best_tag semver sorter"

(
  source_script

  result=$(printf 'v4\nv4.1.0\nv4.2.0\nv3.9.9\n' | best_tag)
  assert_eq "prefers full semver over major alias" "v4.2.0" "$result"

  result=$(printf 'v1\nv2\nv3\n' | best_tag)
  assert_eq "picks highest major alias when no full semver" "v3" "$result"

  result=$(printf 'v4.1.0\nv4.0.0\nv4.0.1\n' | best_tag)
  assert_eq "correct patch-level ordering" "v4.1.0" "$result"

  result=$(printf '4.0.0\n4.1.0\n' | best_tag)
  assert_eq "handles tags without leading v" "4.1.0" "$result"

  result=$(printf 'v4.2.0\nv4.2.1\nv4\n' | best_tag)
  assert_eq "full semver beats alias even if alias is listed last" "v4.2.1" "$result"
)

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 4: process_action with mocked backends (no network required)
# ═══════════════════════════════════════════════════════════════════════════════
section "process_action with mocked gh backend"

(
  source_script

  # Override the gh backend functions with deterministic stubs
  gh_latest_tag()  { echo "v4.2.2"; }
  gh_resolve_sha() { echo "abc1234567890abcdef1234567890abcdef123456"; }
  METHOD="gh"

  result=$(process_action "actions/checkout" 2>/dev/null)
  assert_contains "gh mock: output contains SHA" "abc1234567890abcdef1234567890abcdef123456" "$result"
  assert_contains "gh mock: output contains tag"  "v4.2.2" "$result"
  assert_contains "gh mock: output starts with uses:" "uses: actions/checkout@" "$result"
)

(
  source_script

  # Test with specific tag hint (no latest-tag lookup should occur)
  gh_latest_tag()  { echo "SHOULD_NOT_BE_CALLED"; }
  gh_resolve_sha() { echo "pinned000sha111abc222def333ghi444jkl555mn"; }
  METHOD="gh"

  result=$(process_action "actions/checkout@v4" 2>/dev/null)
  assert_contains "pinned tag: SHA present" "pinned000sha111abc222def333ghi444jkl555mn" "$result"
  assert_contains "pinned tag: tag comment" "# v4" "$result"
  assert_not_contains "pinned tag: latest-tag fn not called" "SHOULD_NOT_BE_CALLED" "$result"
)

section "process_action with mocked curl backend"

(
  source_script

  curl_latest_tag()  { echo "v4.2.2"; }
  curl_resolve_sha() { echo "curl000sha111abc222def333ghi444jkl555mno"; }
  METHOD="curl"
  TOKEN="mock-token"

  result=$(process_action "actions/setup-node" 2>/dev/null)
  assert_contains "curl mock: SHA in output" "curl000sha111abc222def333ghi444jkl555mno" "$result"
  assert_contains "curl mock: tag in comment" "v4.2.2" "$result"
)

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 5: Output format validation
# ═══════════════════════════════════════════════════════════════════════════════
section "Output format"

(
  source_script

  gh_latest_tag()  { echo "v4.2.2"; }
  gh_resolve_sha() { echo "abc1234567890abcdef"; }
  METHOD="gh"

  result=$(process_action "actions/checkout" 2>/dev/null)
  assert_eq "exact output format" \
    "uses: actions/checkout@abc1234567890abcdef  # v4.2.2" \
    "$result"
)

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 6: Integration tests (require real GitHub access)
# ═══════════════════════════════════════════════════════════════════════════════
section "Integration tests (set INTEGRATION=1 to run)"

if [[ "${INTEGRATION:-0}" != "1" ]]; then
  skip_test "[INTEGRATION] actions/checkout → resolves to real SHA"
  skip_test "[INTEGRATION] actions/setup-node@v4 → SHA + tag comment"
  skip_test "[INTEGRATION] curl backend → actions/checkout"
  skip_test "[INTEGRATION] nonexistent action → 404 error message"
  skip_test "[INTEGRATION] SHA is exactly 40 hex characters"
else
  # Detect which backend is available
  BE=""
  if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
    BE="gh"
  elif [[ -n "${GITHUB_TOKEN:-${GH_TOKEN:-}}" ]]; then
    BE="curl"
  fi

  if [[ -z "$BE" ]]; then
    skip_test "No auth available — all integration tests skipped"
  else
    out=$(bash "$SCRIPT" --method "$BE" actions/checkout 2>/dev/null)
    assert_contains "[INTEGRATION] actions/checkout resolves" "uses: actions/checkout@" "$out"

    sha=$(echo "$out" | grep -oE '@[a-f0-9]{40}' | head -1 | tr -d '@' || true)
    assert_eq "[INTEGRATION] SHA is exactly 40 hex chars" "40" "${#sha}"

    out=$(bash "$SCRIPT" --method "$BE" actions/setup-node@v4 2>/dev/null)
    assert_contains "[INTEGRATION] pinned tag appears in comment" "# v4" "$out"

    tok="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
    if [[ -n "$tok" ]]; then
      out=$(bash "$SCRIPT" --method curl --token "$tok" actions/checkout 2>/dev/null || true)
      assert_contains "[INTEGRATION] curl backend resolves checkout" "uses: actions/checkout@" "$out"
    else
      skip_test "[INTEGRATION] curl backend — no GITHUB_TOKEN available"
    fi

    out=$(bash "$SCRIPT" --method "$BE" nonexistent-org-xyz/nonexistent-repo-xyz 2>&1 || true)
    assert_contains "[INTEGRATION] nonexistent → error" "Not found" "$out"
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
PASS=$(cat "$_PASS_F"); FAIL=$(cat "$_FAIL_F"); SKIP=$(cat "$_SKIP_F")
echo ""
echo "─────────────────────────────────────────────"
echo -e "Results: ${GREEN}${PASS} passed${RESET}  ${RED}${FAIL} failed${RESET}  ${YELLOW}${SKIP} skipped${RESET}"
echo ""

[[ $FAIL -eq 0 ]] || exit 1
