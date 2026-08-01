# opencode-worktree

Claude Code-style `-w` worktrees for [OpenCode](https://opencode.ai/):

```sh
opencode -w                  # generated name
opencode -w auth-refresh     # .worktrees/auth-refresh
opencode --worktree=fix-123
opencode -w run "fix it"     # `run` remains the OpenCode subcommand
```

The shim creates a branch named `worktree-<name>`, adds `.worktrees/` to the
repository-local Git exclude, changes into the worktree, and delegates every
remaining argument to the real OpenCode binary. Reusing a name reopens its
existing worktree.

Invocations without `-w` are delegated unchanged.

## Install

Place `bin/opencode` earlier on `PATH` than the real OpenCode executable:

```sh
git clone https://github.com/phall1/opencode-worktree.git \
  "${XDG_DATA_HOME:-$HOME/.local/share}/opencode-worktree"
ln -s "${XDG_DATA_HOME:-$HOME/.local/share}/opencode-worktree/bin/opencode" \
  "$HOME/.local/bin/opencode"
```

The official OpenCode installer uses `~/.opencode/bin/opencode`; the shim finds
that automatically. For another installation layout, set `OPENCODE_REAL_BIN`.

## Configure

The optional config file is `~/.config/opencode/worktree.conf`:

```sh
OPENCODE_WORKTREE_DIR=.worktrees
OPENCODE_WORKTREE_BRANCH_PREFIX=worktree-
# OPENCODE_REAL_BIN=/custom/path/to/opencode
```

Relative worktree directories are anchored to the repository's main worktree,
even when `opencode -w` is invoked from another linked worktree.

## Test

```sh
tests/test.sh
shellcheck bin/opencode tests/test.sh
```

## Why a shim?

OpenCode plugins load after CLI argument parsing, so they cannot register a
top-level flag. The shim supplies the missing pre-parser extension point while
leaving OpenCode itself untouched and independently upgradeable.
