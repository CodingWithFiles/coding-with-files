# fix hook sandbox tmpdir scratch path - Implementation Execution
**Task**: 215 (bugfix)

## Task Reference
- **Task ID**: internal-215
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/215-fix-hook-sandbox-tmpdir-scratch-path
- **Template Version**: 2.1

## Goal
Execute Approach A (uid-path probe) per d-implementation-plan.md so the unsandboxed
context-inject hook emits the in-sandbox writable scratch base.

## Actual Results

### Step 1: Setup
- **Planned**: On branch `bugfix/215-…`, sandbox enabled, re-read c Approach A.
- **Actual**: Confirmed branch + task context (`task-context-inference` → task 215,
  workflow_step e-testing-plan). Sandbox active (`TMPDIR=/tmp/claude-1000`).
- **Deviations**: None.

### Step 2: Core Implementation (`.cwf/lib/CWF/Common.pm`)
- **Planned**: Add `our $SANDBOX_TMP_PROBE` at package scope + probe branch (with
  `!-l` reject) to `scratch_parent`; update the doc comment.
- **Actual**: Added `our $SANDBOX_TMP_PROBE = "/tmp/claude-$>";` after `@EXPORT_OK`.
  Replaced the single-line `$base` ternary with the three-way `if/elsif/else`
  (env → probe `!-l && -d _ && -w _` → `/tmp`). Rewrote the `scratch_parent` doc
  comment: pure/no-disk now holds **only** on the env branch; the probe branch does
  two stats (lstat + cached `-d`/`-w`).
- **Deviations**: None.

### Step 3: Doc/convention alignment (`.cwf/docs/conventions/tmp-paths.md`)
- **Planned**: Revise the "no sandbox-detection branch" rule; correct `/tmp/claude`
  → `/tmp/claude-<uid>` in examples + allowlist patterns.
- **Actual**: Rewrote §"Sandbox alignment" to describe the unsandboxed-hook probe
  branch (self-validating, best-effort, falls back to `/tmp`). Corrected every
  `/tmp/claude` reference to `/tmp/claude-<uid>` (worked example, threat model,
  "Why"); allowlist examples use the concrete `/tmp/claude-1000` with a `(uid 1000)`
  note. `grep` confirmed no bare `/tmp/claude` (non-uid) references remain.
- **Deviations**: None.

### Step 4: Testing (`t/scratch.t`)
- **Planned**: Add TC-9..TC-14 (localise `$CWF::Common::SANDBOX_TMP_PROBE`); run
  `prove`.
- **Actual**: Added TC-9 (env wins), TC-10 (probe adopted), TC-11 (absent→/tmp),
  TC-12 (non-writable `chmod 0500`→/tmp, skip if EUID 0), TC-13 (symlink→/tmp via
  `!-l`, skip if symlink unsupported), TC-14 (empty string→/tmp). Bumped `plan
  tests => 14`. `prove -lr t/scratch.t` → 14/14 PASS.
- **Deviations**: None.

### Step 5: Integrity (same commit)
- **Planned**: Pre-refresh `git log` verify; refresh `Common.pm` sha256; validate.
- **Actual**: `git log` confirmed the last committed `Common.pm` change is Task 206
  (source of the recorded hash); working-tree diff is this task's edit only.
  `sha256sum` → updated `script-hashes.json:84`. Perms 600 (lib module, no
  `permissions` key — no drift). `cwf-manage validate` → OK. (Re-refreshed to
  `2e6dfb84…` after the post-review doc-comment correction below.)
- **Deviations**: None.

### Step 6: Validation
- **Planned**: Full suite green; live check `$TMPDIR` unset → `/tmp/claude-<uid>/cwf-…`.
- **Actual**: Full `prove -lr t/` → **937 tests PASS**. Live check (scratch
  `probe-check.pl`, `delete $ENV{TMPDIR}`): `parent = /tmp/claude-1000/cwf-home-…`,
  `err = undef` — the unsandboxed-hook env now emits the in-sandbox writable base.
- **Deviations**: None.

## Deviations from plan

**Extra file fixed (same bug class): `t/backlog-bootstrap-changelog.t`.** The full
suite surfaced one pre-existing failure unrelated to the planned files: this test
hardcoded `tempdir(..., DIR => '/tmp')`, which fails `Read-only file system` under the
sandbox — the exact `/tmp`-vs-`$TMPDIR` defect Task 215 addresses. It is a one-line,
low-risk fix in the same family, and a green suite is an a-plan success criterion, so
it was fixed on sight: `DIR => ($TMPDIR or /tmp)`, mirroring the `${TMPDIR:-/tmp}` base
in tmp-paths.md. `grep` confirmed it was the **only** test with the hardcoded-`/tmp`
`DIR` anti-pattern. Not a hashed file; no integrity impact.

## Blockers Encountered
None.

## Changeset Reviews

Five reviewers ran in parallel over the changeset (1031 lines, 12 files, anchor
`ba88c17`). Classifier verdicts (deterministic, `security-review-classify`):
security / best-practice / robustness / misalignment = **no findings**;
improvements = **findings** (one advisory, accepted-and-deferred — see below).

### Security Review
**State**: no findings

scratch_parent probe uses the numeric effective uid (`$>`), rejects symlinks
(`!-l` before `-d _ && -w _`), and falls back to `/tmp`; no shell construction,
no new env-var or prompt-injection trust boundary. Two safe-here patterns noted
for future audit (stat-buffer reuse depends on the `!-l` guard; adopting a
world-writable probe is safe only under the single-user trust model — both
parity with the existing `/tmp` fallback). Safe under the documented single-user
trust model.

### Best-Practice Review
**State**: no findings

Resolved tags were `golang`/`postgres`; the changeset is Perl/Markdown/JSON with
no Go or SQL, so no rule in either corpus binds it. Sources read successfully
(not an `error`) — simply inapplicable. The few language-agnostic asides
(return-early, Rule of Three, document exported decls) are already honoured.

### Improvements Review
**State**: findings

Core probe change is well-scoped reuse (reuses the `scratch_dir` lstat-buffer
idiom; Approach A deliberately dropped Approach B's machinery). **One advisory
finding**: the collateral test fix `t/backlog-bootstrap-changelog.t:42` adds an
inline `(defined $ENV{TMPDIR} && length …) ? … : '/tmp'` ternary that now exists
in 4 sites (`Common.pm:111`, `pretooluse-bash-tool-check:116`,
`best-practice-resolve:294`, and this new site) — crossing Rule of Three. A
small exported `CWF::Common::tmp_base()` would consolidate all four.
**Disposition (accept + defer)**: the reviewer itself frames this as a judgement
call — the test deliberately matched the prevailing inline convention, and
extracting the helper touches the two production sites beyond this bugfix's
scope. Logged for the backlog rather than expanding this task's blast radius.

### Robustness Review
**State**: no findings

The three-way resolver is fail-safe by construction (every branch yields a
usable base; never dies / returns `undef` on the new path). Predicate correct
across all edge cases (absent → `-d _` false; symlink → `!-l` short-circuits;
non-writable → `-w _` false; empty → `length` guard), each with a test.
Correctness-first ordering preserved (env hot path stays disk-free). Noted a
doc-comment nit (says "two stats"; `-d _`/`-w _` reuse the lstat buffer so it is
one syscall — over-counts cost, no robustness impact).

### Misalignment Review
**State**: no findings

Probe reuses `scratch_dir`'s lstat-guard idiom and the `CWF::Backlog`
overridable-`our` pattern; `($parent,$err)` contract preserved; `tmp-paths.md`
corrections consistent; hash refreshed same-commit; lib `.pm` correctly stays
600 (no `permissions` key). Tests mirror the TC-1..TC-8 structure. Same advisory
on the test-fix ternary as improvements, treated as non-divergent.

### Post-review correction applied
The robustness reviewer's doc-comment nit was fixed in-task: the `scratch_parent`
comment now says the probe branch "costs a single lstat (the -d/-w checks reuse
its buffer)" instead of the inaccurate "two stats". `Common.pm` hash re-refreshed
to `2e6dfb84…` and `cwf-manage validate` re-run clean.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] No planned work deferred without user approval

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
The full-suite gate (not a touched-file run) was what surfaced the latent same-class
`/tmp` defect in `t/backlog-bootstrap-changelog.t`. The `${TMPDIR:-/tmp}` idiom is now
open-coded in four sites — an exported `CWF::Common::tmp_base()` is logged for the
backlog. See j-retrospective.md.
