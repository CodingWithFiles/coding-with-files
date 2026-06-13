# Tmp Paths

Convention for naming per-task scratch directories under `/tmp/` so that
concurrent agents working in different repositories do not collide on
shared task numbers (e.g. two repos each having a task `145`).

## Convention

Canonical form:

```
${TMPDIR:-/tmp}/<dashified-absolute-repo-path>-task-<num>/
```

Where `<dashified-absolute-repo-path>` is the repository's absolute path
with every `/` replaced by `-` (leading dash preserved), mirroring the
`~/.claude/projects/` directory-naming convention. The base is `${TMPDIR:-/tmp}`
(not a hardcoded `/tmp`) so scratch lands inside whatever temp root the
environment provides — see [Sandbox alignment](#sandbox-alignment).

Worked example (this repository, task 145):

```
${TMPDIR:-/tmp}/-home-matt-repo-coding-with-files-task-145/
```

resolving to `/tmp/claude/-home-…-task-145/` under the sandbox
(`TMPDIR=/tmp/claude`) and `/tmp/-home-…-task-145/` off-sandbox.

Derivation snippet (copy-pastable):

```bash
# Worktree-safe: resolve the MAIN tree, not a linked worktree (Task 173), so the
# scratch namespace is stable whether you run from the main tree or a worktree.
base="${TMPDIR:-/tmp}"; base="${base%/}"   # honour the sandbox temp root; off-sandbox → /tmp
repo_root=$(cd "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")" && pwd)
num=145
scratch="${base}/${repo_root//\//-}-task-${num}"
mkdir -m 0700 -p "$scratch"
```

Use the same directory for every scratch artefact produced during the
task — script files, commit-message drafts, captured subagent output,
diff captures, etc. Examples:

- One-off scripts (per [[feedback_no_heredocs]]):
  `${TMPDIR:-/tmp}/-home-matt-repo-coding-with-files-task-145/refresh-hashes.pl`
- Commit-message drafts: `${TMPDIR:-/tmp}/-home-matt-repo-coding-with-files-task-145/msg.txt`
- Subagent prompt / output captures (per [[feedback_no_tee_permissions]]):
  `${TMPDIR:-/tmp}/-home-matt-repo-coding-with-files-task-145/f-changeset.diff`

## Sandbox alignment

The base is `${TMPDIR:-/tmp}`, not a hardcoded `/tmp`, so scratch lands inside
whatever temp root the environment provides. Under a Claude Code sandbox that
restricts `/tmp` writes to `/tmp/claude`, the sandbox sets `TMPDIR=/tmp/claude`,
so the form resolves to `/tmp/claude/<dashified-repo>-task-<num>/`; off-sandbox
(`$TMPDIR` unset or empty) it resolves to `/tmp/<dashified-repo>-task-<num>/` —
prior behaviour, unchanged. One unconditional form, no sandbox-detection branch.

`$TMPDIR` is honoured verbatim (no `..`/`rel2abs` canonicalisation), trusted
**only** under the single-user threat model below — `$TMPDIR` is set by the
harness, not an attacker. If that assumption is relaxed (multi-user host), the
`mkdir -m 0700` guard remains the containment boundary; do not copy the
verbatim-`$TMPDIR` handling into a context where the single-user invariant does
not hold.

This aligns CWF's own scratch discipline with the sandbox (Task 199). It is
distinct from the CWF-managed sandbox *configuration* feature seeded by Task 178
(a toggle that writes sandbox settings): that conforms the harness; this conforms
our paths.

## Threat model

Scope: a single-user developer host. Multiple agent sessions may run
concurrently in different working trees owned by the same user, but no
untrusted local user is assumed.

The base resolves to either `/tmp` (world-writable) or a sandbox-set `$TMPDIR`
such as `/tmp/claude` (per-user `drwx------`). `/tmp/` is world-writable on POSIX
systems and the directory name is predictable (it embeds the repo path and task
number); the per-user sandbox base narrows the read-after-write surface, but the
guard below applies to both bases. On a multi-user host the predictable name
opens two attack surfaces:

1. **Symlink pre-creation**: a hostile local user could pre-create the
   scratch directory or a file within it as a symlink to an attacker-owned
   target, causing subsequent writes to clobber arbitrary files the
   user-of-record can write to.
2. **Read-after-write**: world-readable scratch content (default umask
   produces `0644` files) lets other local users read whatever the
   session writes.

Mandatory first-use guard:

```bash
mkdir -m 0700 -p "$scratch"
```

`mkdir -m 0700 -p` is sufficient: it sets the mode atomically on creation
and is a no-op (without changing mode) if the directory already exists
and is owned by the caller. If the directory exists but is owned by
another user, the subsequent write will fail closed.

Do not write secrets, `.env` content, or credentials into the scratch
directory even with the `0700` guard — the directory is intended for
diffs, generated scripts, and similar inputs/outputs that are not
sensitive on their own.

## Why

Without namespacing, two concurrent agents in two different repos both
working on a task numbered `145` would race for the same
`/tmp/task-145/` directory, with each potentially overwriting the
other's scratch state. Under the sandbox this matters more, not less:
`/tmp/claude` is a host-global root shared across *all* projects (not just CWF
repos), so the dashified prefix is what keeps repos from colliding there. The
dashified-absolute-repo-path form is:

- **Unambiguous across worktrees of the same repo** — a basename-only
  form like `/tmp/coding-with-files-task-145/` would collide between
  two checkouts of the same repository.
- **Familiar** — it mirrors the `~/.claude/projects/` directory naming
  convention the user already encounters.
- **Trivially derivable** — three lines of shell, no helper script.

A short-form fallback (`/tmp/<basename>-task-<num>/`) is *not* offered.
Multiple permitted forms invite drift; the dashified form is no harder
to construct programmatically than the basename form.

## Out of scope

- **Install-time scratch paths** (e.g. `INSTALL.md`): single-user,
  one-shot operations with no concurrency risk. Leave as-is.
- **Historical references in `BACKLOG.md` / `CHANGELOG.md` / older
  `implementation-guide/<task>/` files**: do not retroactively rewrite.
- **`.claude/settings.local.json` allowlist entries**: user-owned file.
  Existing entries like `Bash(/tmp/task-132/...)` predate this
  convention and must not be retroactively rewritten. Future allowlist
  entries should use the canonical form.
- **Helper script to compute the path**: deferred. The derivation
  snippet is three lines; a helper would add hash-tracking surface for
  no proportionate benefit.

## See also

- `.cwf/docs/conventions/worktree-process.md` — sibling scratch
  convention for disposable *worktrees* (which live under
  `.claude/worktrees/`, governed there), not `/tmp/` directories.
- `docs/conventions/design-alignment.md` — repo-wide naming and
  cross-reference conventions.
- `~/.claude/projects/-home-matt-repo-coding-with-files/memory/feedback_no_heredocs.md`
  — agent memory: write one-off scripts to a per-task `/tmp/` dir.
- `~/.claude/projects/-home-matt-repo-coding-with-files/memory/feedback_no_tee_permissions.md`
  — agent memory: redirect to a per-task `/tmp/` file rather than
  `tee`-ing.
