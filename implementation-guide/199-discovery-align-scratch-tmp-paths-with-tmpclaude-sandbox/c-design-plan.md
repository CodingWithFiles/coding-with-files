# Align scratch tmp-paths with /tmp/claude sandbox - Design
**Task**: 199 (discovery)

## Task Reference
- **Task ID**: internal-199
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/199-align-scratch-tmp-paths-with-tmpclaude-sandbox
- **Template Version**: 2.1

## Goal
Decide how CWF's per-task scratch path is resolved so it lands inside the
sandbox-permitted temp root, with one mechanism that is portable across
sandboxed and unsandboxed hosts.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### D1 — Resolve scratch paths via `$TMPDIR` (do not hardcode a literal root)
- **Decision**: The canonical scratch base becomes `${TMPDIR:-/tmp}` (with any
  trailing slash stripped), giving `${TMPDIR:-/tmp}/<dashified-repo>-task-<num>/`.
  Both the `tmp-paths.md` shell snippet and `security-review-changeset`'s
  `$scratch` adopt this form. The `mkdir -m 0700` first-use guard and the
  cross-repo namespacing suffix are unchanged.
- **Rationale**:
  - **Empirically grounded**: `File::Temp` already resolves its dir from
    `$TMPDIR` (verified: `TMPDIR=/tmp/claude/...` → temp file created there;
    unset → `/tmp`). Making the *explicit* convention honour `$TMPDIR` too means
    every temp class — (a) DIR-pinned, (b) explicit convention, (c) default
    `File::Temp` — keys off the **same** signal. One fact (the sandbox sets
    `TMPDIR=/tmp/claude`) makes all of them sandbox-safe at once.
  - **Portable**: `tmp-paths.md` is a *shipped* convention binding on every CWF
    adopter, not only Claude-sandbox users. Honouring `$TMPDIR` keeps the
    default portable — `/tmp` off-sandbox (today's behaviour, no regression),
    the sandbox's temp root on-sandbox — without baking a harness-specific
    `/tmp/claude` literal into a convention shipped to everyone.
  - **Reversible**: if the sandbox's temp dir is ever renamed, nothing in CWF
    changes; the convention follows the environment.
- **Trade-offs**:
  - Introduces an env-var (`$TMPDIR`) into path resolution — the FR4(d)
    "env-var-influences-path" surface the security review flagged. Accepted
    because: the threat model is a single-user host where `$TMPDIR` is
    harness-set, not attacker-set; the `mkdir -m 0700` guard and the
    fail-closed-on-foreign-dir write survive unchanged; and an unset/escaped
    `$TMPDIR` degrades to `/tmp` — exactly today's behaviour, i.e. no *new*
    off-sandbox exposure. Recorded as a deliberate decision per FR4 AC(ii).
  - Correctness depends on the sandbox actually *setting* `TMPDIR`. See D2.
- **Requirements impact**: this supersedes FR2/FR3's original hardcoded-`/tmp/claude`
  framing; b-requirements FR2/FR3/AC2/AC3 were amended to the `$TMPDIR` form with a
  reconciliation note (design-reveals-requirements-gap loop-back).

### D2 — Sandbox-`TMPDIR` is the pivot fact; confirm before closing
- **Hypothesis (leading)**: the sandbox sets `TMPDIR=/tmp/claude`. Evidence:
  `/tmp/claude/go-build` exists, and Go's test/build temp keys off `$TMPDIR` —
  consistent with a prior sandboxed session running under that `TMPDIR`.
- **If confirmed**: D1 alone suffices. Class-(c) sites (`cwf-apply-artefacts`,
  `cwf-manage`) need **no change** — they already honour `$TMPDIR` (FR4
  disposition (ii)). The two-concern split dissolves; this stays one task.
- **If falsified** (sandbox restricts the `/tmp` path but leaves `$TMPDIR`
  unset): D1's default must change to `${TMPDIR:-/tmp/claude}` (hardcode the
  sandbox root as the fallback), and class-(c) needs an explicit fix (export
  `TMPDIR` in the affected helpers, or pin `DIR`). That explicit class-(c) fix
  becomes follow-up **199.x** / a BACKLOG entry — not in-scope here.
- **Resolution gate**: FR7's sandboxed-session check answers this. The dev
  session is unsandboxed (legacy-`/tmp` mkdir still succeeds), so this is
  BLOCKED-ENV until run in a real sandboxed session.

### D3 — Rejected alternatives
- **Hardcode `/tmp/claude/<...>` in the shipped convention**: rejected — couples
  every CWF adopter to one harness's sandbox dir; brittle if renamed; pollutes
  `/tmp/claude` semantics onto non-Claude users. (Retained only as the D2
  *fallback default* if the sandbox proves not to set `TMPDIR`.)
- **Pin `DIR` on every `File::Temp` call site**: rejected as the *primary* —
  more surface, repeated per-site, and unnecessary if `$TMPDIR` is honoured.
  Held as the class-(c) remedy only under the D2-falsified branch.
- **Sandbox-conditional branching** (detect sandbox, pick path): rejected —
  violates FR6's single-unconditional-form requirement; `${TMPDIR:-…}` already
  adapts without branching.

## System Design
### Component Overview
- **`tmp-paths.md`** (convention SSOT): owns the canonical form, the shell
  derivation snippet, the worked examples, and the threat-model/namespacing
  rationale. Single source every other site references.
- **`security-review-changeset`** (`:261` `$scratch`; comments `:59`, `:344`):
  the one helper that constructs the explicit scratch path in code. Adopts the
  Perl equivalent of D1; preserves the existing fail-closed `mkdir(...,0700) or
  exit 1`. Hash-tracked → same-commit `script-hashes.json` refresh.
- **Agent-memory + `MEMORY.md`** (behavioural guidance, user-global): example
  paths updated in-session to the D1 form; uncommittable, recorded as a
  cross-surface dependency.
- **`cwf-implementation-exec` / `cwf-testing-exec` SKILLs** (indirect): reference
  `tmp-paths.md` by name; self-update with D1. No literal edit — and so no
  hash churn on these hash-tracked files.

### Data Flow
1. A subagent / skill / helper needs scratch → reads `$TMPDIR`.
2. Constructs `${TMPDIR:-/tmp}/<dashified-main-repo-root>-task-<num>/`
   (trailing slash on `$TMPDIR` stripped; main-tree root via existing
   worktree-safe derivation).
3. `mkdir -m 0700` first-use guard (unchanged). Fail-closed paths: a
   foreign-owned pre-existing dir → the 0600 write fails (Perl) / the write fails
   (shell); an unwritable/missing resolved root → `mkdir` fails → surface + exit
   non-zero (NFR2). No silent fallback to `/tmp`.
4. Writes scratch artefacts (scripts, `.out` captures, msg drafts) there.
5. Under sandbox: `$TMPDIR=/tmp/claude` → path inside the permitted root.
   Off-sandbox: `$TMPDIR` unset → `/tmp` → today's behaviour, unchanged.

## Interface Design
The derivation contract: documented in `tmp-paths.md` (shell), mirrored in
`security-review-changeset` as a **minimal diff** against the existing `:255-261`
block — which already computes `$dashed` from `find_git_root()`; that
worktree-safe derivation is preserved, only the base changes.

```bash
# shell (tmp-paths.md snippet) — only the base= line is new vs today
base="${TMPDIR:-/tmp}"; base="${base%/}"           # NEW: honour $TMPDIR; empty-or-unset → /tmp
repo_root=$(cd "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")" && pwd)
scratch="${base}/${repo_root//\//-}-task-${num}"   # was: /tmp/${repo_root//\//-}-task-${num}
mkdir -m 0700 -p "$scratch"                        # write fails closed on a foreign-owned dir
```

```perl
# perl (security-review-changeset) — minimal diff at :255-261; $dashed via find_git_root unchanged
my $base = (defined $ENV{TMPDIR} && length $ENV{TMPDIR}) ? $ENV{TMPDIR} : '/tmp';
$base =~ s{/+$}{};                                 # match shell `:-` empty-string semantics
my $scratch = "$base/${dashed}-task-${task_num}";  # was: "/tmp/${dashed}-task-${task_num}"
# UNCHANGED below :261 — the `unless (-d $scratch) { mkdir($scratch,0700) or {warn;exit 1} }`
# guard and the 0600 write stay. On a pre-existing foreign-owned dir the fail-closed
# defence is the 0600 WRITE failing (the mkdir is skipped), NOT the mkdir.
```

- **Empty/degenerate `$TMPDIR`**: the `length`-check makes Perl match shell `:-`
  — `TMPDIR=""` falls back to `/tmp`, not to a filesystem-root `/<dashed>-task-N`.
  Both forms strip trailing slashes. (Closes the empty-string divergence.)
- **`$TMPDIR` used verbatim** — no `rel2abs`/`..` canonicalisation. Accepted
  under the single-user threat model (`$TMPDIR` is harness-set, not attacker-set)
  and consistent with `File::Temp`'s own raw handling; the `mkdir -m 0700` guard
  and the 0600 write remain the containment defence. (Closes FR4(d) AC(ii).)
- **Unwritable resolved root (NFR2)**: if the resolved `$scratch` cannot be
  created (sandbox sets `TMPDIR=/tmp/claude` but it is missing/denied), the code
  **fails closed with an actionable message** — it does NOT silently fall back to
  `/tmp`. The existing Perl `mkdir ... or { warn; exit 1 }` already does this; the
  shell relies on `mkdir -m 0700 -p` failing and the caller checking `$?`.

## Constraints
- POSIX-only; core-Perl-only (`$ENV{TMPDIR}`, no module).
- Preserve `mkdir -m 0700` symlink-pre-creation defence and fail-closed
  foreign-dir behaviour (NFR4).
- Hash-tracked `security-review-changeset` edit carries same-commit hash refresh.
- `tmp-paths.md` carve-outs (install-time, historical files, user-owned
  `settings.local.json`) unchanged.
- Distinct from Task-178 (conform vs build toggle); cross-reference only.

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2? No.
- [ ] **Complexity**: 3+ concerns? **No longer** — D1 collapses class (b) and
  (c) onto one `$TMPDIR` mechanism; class (c) needs no code change when the
  sandbox sets `TMPDIR`.
- [ ] **Risk**: isolation needed? No.
- [ ] **Independence**: separable? The previously-separable class-(c) fix is now
  contingent — it only materialises (as follow-up 199.x) if D2 is *falsified*.

**Conclusion**: Design **resolves the earlier 2-signal lean** — do NOT decompose.
Keep 199 as one task: adopt D1, audit, and confirm the D2 pivot fact. Spin out a
class-(c) follow-up **only if** FR7 shows the sandbox does not set `TMPDIR`.

## Validation
- [ ] Design review completed (plan-review subagents, Step 8)
- [x] Interface (derivation contract) verified against `File::Temp` behaviour
- [ ] D2 pivot fact confirmed in a sandboxed session (FR7; BLOCKED-ENV in dev)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
