# fix hook sandbox tmpdir scratch path - Implementation Plan
**Task**: 215 (bugfix)

## Task Reference
- **Task ID**: internal-215
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/215-fix-hook-sandbox-tmpdir-scratch-path
- **Template Version**: 2.1

## Goal
Implement **Approach A** (chosen at review): a self-validating uid-path probe in `CWF::Common::scratch_parent` so the unsandboxed hook emits the in-sandbox writable scratch base.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cwf/lib/CWF/Common.pm` — in `scratch_parent`, when `$ENV{TMPDIR}` is unset/empty, probe a per-uid sandbox temp and adopt it only if it is a non-symlink writable directory; else keep today's `/tmp` fallback. Probe target is an overridable **package-scope** variable for testability. **Also update the sub's doc comment** (`Common.pm:80-83`), which currently asserts "Pure string derivation, NO filesystem work … must not touch disk" — now false on the probe branch.

### Supporting Changes
- `t/scratch.t` — add probe-branch cases (TC-9..TC-14; see e-testing-plan).
- `.cwf/security/script-hashes.json` — **refresh `Common.pm` sha256 in the same commit** (`Common.pm` is hashed at `script-hashes.json:83`; required by `hash-updates.md` plan-time disclosure). No other hashed file is touched (the hook is unchanged; `tmp-paths.md` is **not** hashed).
- `.cwf/docs/conventions/tmp-paths.md` (not hashed) — convention alignment: (a) §"One unconditional form, no sandbox-detection branch" (line 78) must be revised — Approach A *is* a sandbox-detection branch; (b) the `/tmp/claude` references (lines 33-34, 75-77, 99, 153, 182, 190) are factually wrong — the real sandbox base is `/tmp/claude-<uid>`; correct the examples and the `Bash(/tmp/claude/…)` / `Write(//tmp/claude/…)` allowlist patterns to the uid-suffixed form.

<!-- No symbols deleted; contract unchanged ((parent,err) return kept — no $source needed once the symbolic fallback was dropped). -->

## Design notes carried from c
- **No hook change**: `userpromptsubmit-context-inject` calls `scratch_parent`; fixing the resolver fixes the emitted line. The hook stays hashed-but-untouched (no hook hash refresh).
- **No contract change**: dropping the symbolic fallback removed the only need for a `$source` return; keep `($parent, $err)`.
- **Change is global to `scratch_parent`, not hook-only** (robustness #4): the probe also reaches `scratch_dir` and its callers (`plan-mechanical-check`, `security-review-changeset`). Those run in-sandbox with `$TMPDIR` set, so they stay on the env branch; an *unsandboxed* writer with `$TMPDIR` unset + probe present would now create under `/tmp/claude-<uid>/cwf…/task-N` instead of `/tmp/cwf…` — intended and benign (still writable, single owner).
- **No string-injection surface; symlink handled; trust model named** (security #1/#2): the probe is `"/tmp/claude-$>"` where `$>` is the numeric effective uid — no external string is interpolated. `-d && -w` follow symlinks, so they prove *writability*, not *trustworthiness*; this is safe under the single-user threat model in `tmp-paths.md:80-96`. For defence-in-depth parity with `scratch_dir`'s leaf `lstat` guard (`Common.pm:120`), reject a symlinked probe (`!-l`) before adopting it.
- **Per-turn cost** (robustness #1): the probe adds two `stat`s per turn on the unsandboxed-hook branch only — negligible; the env branch (in-sandbox hot path) stays disk-free. Recorded in the updated doc comment.

## Code Changes
### Before (`.cwf/lib/CWF/Common.pm`, scratch_parent)
```perl
my $base = (defined $ENV{TMPDIR} && length $ENV{TMPDIR}) ? $ENV{TMPDIR} : '/tmp';
$base =~ s{/+$}{};
return ("$base/cwf${dashed}", undef);
```

### After
```perl
# --- at PACKAGE scope (top of file, with the other package vars) ---
# Overridable so tests can point the probe at a tempdir instead of the real
# per-uid sandbox temp (shared state). Initialiser MUST run once at load —
# declaring it inside the sub would re-run every call and clobber a test's
# `local` override. Default: the path observed under Claude Code's bash
# sandbox on Linux/WSL2.
our $SANDBOX_TMP_PROBE = "/tmp/claude-$>";

# --- inside scratch_parent ---
my $base;
if (defined $ENV{TMPDIR} && length $ENV{TMPDIR}) {
    $base = $ENV{TMPDIR};                        # in-sandbox (or a real shell TMPDIR)
} elsif (length $SANDBOX_TMP_PROBE
         && !-l $SANDBOX_TMP_PROBE               # lstat: reject a planted symlink
         && -d _ && -w _) {                      # ...real writable dir (reuses lstat buf)
    $base = $SANDBOX_TMP_PROBE;                  # hook unsandboxed: borrow sandbox temp
} else {
    $base = '/tmp';                              # off-sandbox / convention absent
}
$base =~ s{/+$}{};
return ("$base/cwf${dashed}", undef);
```
Note the `our` declaration lives at **package scope, outside the sub** (the diff splits it out above). `!-l` then `-d _ && -w _` reuse the single `lstat` buffer.

## Implementation Steps
### Step 1: Setup
- [ ] On branch `bugfix/215-…`; sandbox enabled; re-read c-design-plan Approach A.

### Step 2: Core Implementation
- [ ] Add `our $SANDBOX_TMP_PROBE` at **package scope** and the probe branch (with `!-l` reject) to `scratch_parent`.
- [ ] Update the `scratch_parent` doc comment (`Common.pm:80-83`): the pure-string/no-disk guarantee now holds only on the env branch; the probe does two `stat`s on the unsandboxed-hook branch.
- [ ] Confirm `scratch_dir` (calls `scratch_parent`) behaves as intended — in-sandbox it stays on the env branch (§Design notes).

### Step 3: Doc/convention alignment
- [ ] Update `.cwf/docs/conventions/tmp-paths.md`: revise the "no sandbox-detection branch" rule (line 78) to describe the probe; correct `/tmp/claude` → `/tmp/claude-<uid>` in the examples and allowlist patterns (lines 33-34, 75-77, 99, 153, 182, 190).

### Step 4: Testing
- [ ] Add TC-9..TC-14 to `t/scratch.t` (localise `$CWF::Common::SANDBOX_TMP_PROBE`).
- [ ] `prove -lr t/scratch.t` then the full `prove` suite — no regressions (TC-1..TC-8 use `$TMPDIR`, unaffected).

### Step 5: Integrity (same commit)
- [ ] Pre-refresh verify: `git log --oneline <last-Common.pm-hash-commit>..HEAD -- .cwf/lib/CWF/Common.pm` shows only this task's edit.
- [ ] `sha256sum .cwf/lib/CWF/Common.pm` → update its entry in `script-hashes.json`.
- [ ] `cwf-manage validate` → clean.

### Step 6: Validation
- [ ] Live sandbox check: with `$TMPDIR` unset, `scratch_parent` resolves to `/tmp/claude-<uid>/cwf-…` (already reproduced manually during task creation).

## Test Coverage
**See e-testing-plan.md for the complete test plan (TC-9..TC-14 + regression).**

## Validation Criteria
**See e-testing-plan.md.**

## Scope Completion
Single-file core change + tests + hash refresh, all in one commit. No deferral expected.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Executed as planned (Common.pm probe + doc comment, t/scratch.t TC-9..TC-14, same-commit
sha256 refresh). One unplanned collateral fix: `t/backlog-bootstrap-changelog.t` (same
bug class, hardcoded `/tmp`) surfaced by the full-suite gate and fixed on sight. See
f-implementation-exec.md.

## Lessons Learned
The plan correctly scoped the production change; the only surprise was a latent
same-class defect in an unrelated test, which only a full-suite run (not a touched-file
run) could surface. See j-retrospective.md.
