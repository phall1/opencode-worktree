#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRIPT="$ROOT/bin/opencode"
REAL=${OPENCODE_REAL_BIN:-$(command -v opencode)}
TMP=$(mktemp -d)
TMP=$(cd "$TMP" && pwd -P)
trap 'rm -rf "$TMP"' EXIT

[[ -x "$REAL" ]] || {
  printf 'latest smoke: OpenCode binary is not executable: %s\n' "$REAL" >&2
  exit 1
}

version=$($REAL --version)
printf 'latest smoke: OpenCode %s at %s\n' "$version" "$REAL"

git -C "$TMP" init -q -b main
git -C "$TMP" config user.name opencode-worktree-ci
git -C "$TMP" config user.email ci@example.invalid
printf 'seed\n' > "$TMP/README.md"
git -C "$TMP" add README.md
git -C "$TMP" commit -qm seed

output=$(
  cd "$TMP"
  OPENCODE_REAL_BIN="$REAL" "$SCRIPT" -w ci-smoke --version
)

[[ "$output" == "$version" ]] || {
  printf 'latest smoke: delegated version mismatch: expected %s, got %s\n' "$version" "$output" >&2
  exit 1
}
[[ -d "$TMP/.worktrees/ci-smoke" ]] || {
  printf 'latest smoke: .worktrees/ci-smoke was not created\n' >&2
  exit 1
}
[[ "$(git -C "$TMP/.worktrees/ci-smoke" branch --show-current)" == "worktree-ci-smoke" ]] || {
  printf 'latest smoke: expected branch worktree-ci-smoke\n' >&2
  exit 1
}
[[ -z "$(git -C "$TMP" status --porcelain)" ]] || {
  printf 'latest smoke: parent repository is dirty\n' >&2
  git -C "$TMP" status --short >&2
  exit 1
}

printf 'latest smoke: opencode -w passed\n'
