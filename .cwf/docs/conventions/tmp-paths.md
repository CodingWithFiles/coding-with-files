# Tmp Paths

Convention for naming per-task scratch directories under `/tmp/` so that
concurrent agents working in different repositories do not collide on
shared task numbers (e.g. two repos each having a task `145`).

## Convention

Canonical form — a single per-project parent holding per-task leaves:

```
${TMPDIR:-/tmp}/cwf<dashified-absolute-repo-path>/task-<num>/
```

Where `<dashified-absolute-repo-path>` is the repository's absolute path
with every `/` replaced by `-` (leading dash preserved), mirroring the
`~/.claude/projects/` directory-naming convention. The literal `cwf`
prefix abuts that leading dash — no extra separator — so the parent reads
cleanly as `cwf-home-matt-repo-coding-with-files`. The base is
`${TMPDIR:-/tmp}` (not a hardcoded `/tmp`) so scratch lands inside whatever
temp root the environment provides — see [Sandbox alignment](#sandbox-alignment).

The per-project parent is the unit a devops operator reasons about: every
CWF scratch dir for a repo lives under one clearly-named `cwf-<repo>/`, and
the `task-<num>/` leaves beneath it show what is live vs. deletable.

Worked example (this repository, task 145):

```
${TMPDIR:-/tmp}/cwf-home-matt-repo-coding-with-files/task-145/
```

resolving to `/tmp/claude/cwf-home-…/task-145/` under the sandbox
(`TMPDIR=/tmp/claude`) and `/tmp/cwf-home-…/task-145/` off-sandbox.

Reference derivation — the canonical **spec**, not for agents to run by hand
(a command carrying `$(...)`/`${...}` trips a Claude Code permission prompt on
every call; that is precisely what Task 206 removed):

```bash
# Worktree-safe: resolve the MAIN tree, not a linked worktree (Task 173), so the
# scratch namespace is stable whether you run from the main tree or a worktree.
base="${TMPDIR:-/tmp}"; base="${base%/}"   # honour the sandbox temp root; off-sandbox → /tmp
repo_root=$(cd "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")" && pwd)
num=145
parent="${base}/cwf${repo_root//\//-}"   # stable per-project parent (cwf abuts leading dash)
scratch="${parent}/task-${num}"          # per-task leaf
mkdir -m 0700 -p "$scratch"              # -p creates parent then leaf, 0700 on both
```

**Single source of truth (Task 206)**: agents do not run the snippet above. The
`userpromptsubmit-context-inject` hook injects the scratch **parent** into
context each turn (the `CWF PATHS` block), so a writer appends `task-<num>` as a
literal and creates it with an all-literal `mkdir -m 0700 -p <parent>/task-<num>`
(no expansion ⇒ no prompt). Code that needs to derive or create scratch calls
`CWF::Common::scratch_parent()` (parent string, pure, no filesystem) or
`scratch_dir($num)` (parent + leaf + the symlink-attack guard below) — the one
Perl implementation of this derivation. The shell snippet is the human-readable
definition those implement.

Use the leaf — `${TMPDIR:-/tmp}/cwf<dash>/task-<num>/` — for every scratch
artefact produced during the task: script files, commit-message drafts,
captured subagent output, diff captures, etc. Examples:

- One-off scripts (per [[feedback_no_heredocs]]):
  `${TMPDIR:-/tmp}/cwf-home-matt-repo-coding-with-files/task-145/refresh-hashes.pl`
- Commit-message drafts: `${TMPDIR:-/tmp}/cwf-home-matt-repo-coding-with-files/task-145/msg.txt`
- Subagent prompt / output captures (per [[feedback_no_tee_permissions]]):
  `${TMPDIR:-/tmp}/cwf-home-matt-repo-coding-with-files/task-145/f-changeset.diff`

## Sandbox alignment

The base is `${TMPDIR:-/tmp}`, not a hardcoded `/tmp`, so scratch lands inside
whatever temp root the environment provides. Under a Claude Code sandbox that
restricts `/tmp` writes to `/tmp/claude`, the sandbox sets `TMPDIR=/tmp/claude`,
so the form resolves to `/tmp/claude/cwf<dashified-repo>/task-<num>/`; off-sandbox
(`$TMPDIR` unset or empty) it resolves to `/tmp/cwf<dashified-repo>/task-<num>/`.
One unconditional form, no sandbox-detection branch.

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
of **both** the `cwf<dash>` parent and the `task-<num>` leaf, and is a no-op
(without changing mode) if a directory already exists and is owned by the
caller. If a directory exists but is owned by another user, the subsequent
write will fail closed. That atomic `0700` create plus the fail-closed write
is the containment boundary.

The per-project parent is now **shared across tasks and longer-lived** than a
per-task sibling was. Code that creates scratch dirs therefore routes through
`CWF::Common::scratch_dir($num)` (Task 206; used by `security-review-changeset`
and any future writer), which adds one **defence-in-depth** check the bare
`mkdir` above omits: after the parent `mkdir`, it rejects a parent that is a
**symlink** (`-d && !-l`, i.e. `lstat` semantics — a plain `stat` follows the
link and would validate the target, the dangerous symlink-to-dir case) by
returning a `symlink_parent` error (callers map it to a non-zero exit). It does
**not** re-assert ownership/mode (that stays enforced by the fail-closed write —
no TOCTOU stat masquerading as the boundary) and **never auto-chmods** a
wrong-mode parent (surface, never smooth). The bare `mkdir -m 0700 -p` form is
the single-user, one-shot case (e.g. the task-creation skills creating their
literal leaf); `scratch_dir` adds the guard because it may meet a pre-existing
shared parent. The leaf is intentionally left to the fail-closed write (no
redundant leaf check).

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
- **Trivially derivable** — a short, well-defined string transform, centralised
  in `CWF::Common::scratch_parent`/`scratch_dir` (Task 206).

A short-form fallback (`/tmp/<basename>-task-<num>/`) is *not* offered.
Multiple permitted forms invite drift; the dashified form is no harder
to construct programmatically than the basename form.

## Permission allowlist (optional, user-owned)

The stable per-project parent lets you collapse the per-task permission
prompts (one-off scripts written into scratch, captured output) into a
**single** allowlist rule. CWF does **not** edit any settings file — the
path embeds a machine-specific absolute path and `settings.local.json` is
user-owned. If you want to opt in, add these rules yourself (syntax verified
against `code.claude.com/docs/en/permissions.md` and existing entries):

- **Write tool** — gitignore-style paths (`//` = absolute root, `**` = subtree):

  ```
  Write(//tmp/cwf-home-matt-repo-coding-with-files/**)
  Write(//tmp/claude/cwf-home-matt-repo-coding-with-files/**)   # sandbox base
  ```

- **Script execution** — `Bash()` rules match the **command string**; `*`
  spans `/`; `**` is **not** supported in `Bash()`:

  ```
  Bash(/tmp/cwf-home-matt-repo-coding-with-files/*)
  Bash(/tmp/claude/cwf-home-matt-repo-coding-with-files/*)      # sandbox base
  ```

**Granularity trade-off (deliberate)**: the old sibling form let you
allowlist a *single* task's path; one subtree rule on the nested form
allowlists execution of scripts written into **any** task leaf by **any**
session. That is a conscious, user-owned widening, bounded to this project's
parent under the single-user threat model. It also makes the no-secrets rule
above more important, not less: the subtree is pre-approved for execution, so
never write credentials or `.env` content into it.

## Out of scope

- **Install-time scratch paths** (e.g. `INSTALL.md`): single-user,
  one-shot operations with no concurrency risk. Leave as-is.
- **Historical references in `BACKLOG.md` / `CHANGELOG.md` / older
  `implementation-guide/<task>/` files**: do not retroactively rewrite.
- **`.claude/settings.local.json` allowlist entries**: user-owned file,
  never edited by CWF (see [Permission allowlist](#permission-allowlist-optional-user-owned)).
  Existing entries like `Bash(/tmp/task-132/...)` predate this convention and
  must not be retroactively rewritten.
- **`pretooluse-bash-tool-check` state dir**: the hook
  `.cwf/scripts/hooks/pretooluse-bash-tool-check` writes
  `${TMPDIR:-/tmp}/<dashified-root>-tool-check/`. It is **not** nested under
  the `cwf<dash>/` parent: it is already one stable dir per project (no
  per-task proliferation, so no prompt problem), it is written
  programmatically by the hook (not via a Bash prompt, so the allowlist anchor
  is irrelevant to it), and it uses a different dashify rule
  (`s{[^A-Za-z0-9]+}{-}g`) than this convention (`s{/}{-}g`). A named exception
  beats unifying two hashed scripts' rules for no functional gain.
- **Helper script to compute the path**: ~~deferred~~ — **superseded by Task
  206**. The per-call permission-prompt storm from the inline `$(...)`/`${//}`
  derivation (a prompt on nearly every skill call) flipped this cost/benefit:
  the derivation now lives in `CWF::Common::scratch_parent`/`scratch_dir` and is
  injected into context by the `userpromptsubmit-context-inject` hook, so agents
  use a literal path and never run a prompting snippet. The hash-tracking surface
  is one shared lib (plus the hook), smaller than the deferred bullet imagined.

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
