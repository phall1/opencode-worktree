#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRIPT="$ROOT/bin/opencode"
TMP=$(mktemp -d)
TMP=$(cd "$TMP" && pwd -P)
trap 'rm -rf "$TMP"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  [[ "$1" == *"$2"* ]] || fail "expected '$1' to contain '$2'"
}

mkdir -p "$TMP/bin" "$TMP/repo"
cat > "$TMP/bin/opencode-real" <<'EOF'
#!/usr/bin/env bash
printf 'cwd=%s\n' "$PWD" > "$OPENCODE_TEST_LOG"
printf 'arg=%s\n' "$@" >> "$OPENCODE_TEST_LOG"
if [[ "${1:-}" == "--help" ]]; then printf 'real help\n'; fi
EOF
chmod +x "$TMP/bin/opencode-real"

git -C "$TMP/repo" init -q -b main
git -C "$TMP/repo" config user.name test
git -C "$TMP/repo" config user.email test@example.com
printf 'seed\n' > "$TMP/repo/README.md"
git -C "$TMP/repo" add README.md
git -C "$TMP/repo" commit -qm seed

export OPENCODE_REAL_BIN="$TMP/bin/opencode-real"
export OPENCODE_TEST_LOG="$TMP/invocation.log"
export OPENCODE_WORKTREE_DIR=.worktrees

(
  cd "$TMP/repo"
  "$SCRIPT" -w 'Feature Name' --model test/model
)
[[ -d "$TMP/repo/.worktrees/feature-name" ]] || fail "named worktree was not created"
[[ "$(git -C "$TMP/repo/.worktrees/feature-name" branch --show-current)" == "worktree-feature-name" ]] || fail "unexpected branch"
[[ -z "$(git -C "$TMP/repo" status --porcelain)" ]] || fail ".worktrees polluted git status"
log=$(<"$OPENCODE_TEST_LOG")
assert_contains "$log" "cwd=$TMP/repo/.worktrees/feature-name"
assert_contains "$log" 'arg=--model'
assert_contains "$log" 'arg=test/model'

# A stable name reopens the same worktree instead of creating a suffix.
(
  cd "$TMP/repo"
  "$SCRIPT" --worktree=feature-name
)
[[ "$(git -C "$TMP/repo" worktree list --porcelain | grep -c '^worktree ')" -eq 2 ]] || fail "reuse created another worktree"

# Known OpenCode subcommands are not consumed as optional worktree names.
(
  cd "$TMP/repo"
  "$SCRIPT" -w run 'say hello'
)
log=$(<"$OPENCODE_TEST_LOG")
assert_contains "$log" 'arg=run'
assert_contains "$log" 'arg=say hello'

# Without -w, cwd and arguments pass through unchanged.
(
  cd "$TMP/repo"
  "$SCRIPT" run plain
)
log=$(<"$OPENCODE_TEST_LOG")
assert_contains "$log" "cwd=$TMP/repo"
assert_contains "$log" 'arg=run'
assert_contains "$log" 'arg=plain'

help=$("$SCRIPT" --help)
assert_contains "$help" 'real help'
assert_contains "$help" '--worktree [name]'

printf 'ok\n'
