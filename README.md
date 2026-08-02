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
OPENCODE_REAL_BIN="$(command -v opencode)" tests/latest-opencode.sh
shellcheck bin/opencode tests/*.sh
```

GitHub Actions checks the npm `latest` version daily and on every change. A
successful version + shim/test hash is cached, so unchanged releases skip the
install and smoke entirely. A cache miss installs that exact release and runs
the compatibility smoke. Failures create or update one compatibility issue
with the OpenCode version, workflow/artifact links, reproduction commands, and
the captured log tail so an agent can start the repair immediately; successful
runs do not retain log artifacts.

## Why a shim?

OpenCode plugins load after CLI argument parsing, so they cannot register a
top-level flag. The shim supplies the missing pre-parser extension point while
leaving OpenCode itself untouched and independently upgradeable.
