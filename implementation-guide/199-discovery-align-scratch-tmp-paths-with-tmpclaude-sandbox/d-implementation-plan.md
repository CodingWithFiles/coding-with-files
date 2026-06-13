# Align scratch tmp-paths with /tmp/claude sandbox - Implementation Plan
**Task**: 199 (discovery)

## Task Reference
- **Task ID**: internal-199
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/199-align-scratch-tmp-paths-with-tmpclaude-sandbox
- **Template Version**: 2.1

## Goal
Implement the honour-`$TMPDIR` scratch resolution (c-design D1) across the
convention, the one helper that hardcodes the scratch path, the test harness, and
the agent-behaviour guidance — preserving the `mkdir -m 0700` guard and fail-closed
semantics, refreshing the hash in the same commit.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes (committable)
- `.cwf/scripts/command-helpers/security-review-changeset` — `$scratch`
  construction at `:261` (+ doc-comment path literals `:59`, `:344`) to honour
  `$TMPDIR` per the c-design Perl mirror. **Hash-tracked** → same-commit
  `script-hashes.json` refresh. Fail-closed `unless -d / mkdir … or exit 1` block
  (`:264-272`) left intact.
- `.cwf/docs/conventions/tmp-paths.md` (not hash-tracked) — prose edits: canonical
  form (`:12`), worked examples (`:22`, `:40-44`), threat-model note (`:46-78`),
  namespacing "Why" (`:80-96`). **Derivation snippet (`:27-34`) is the discrete
  design-pinned edit**: add the two `base=` lines incl. the `base="${base%/}"`
  trailing-slash strip and substitute `/tmp/…` → `${base}/…` (c-design `:111-116`);
  the `%/}` strip keeps shell/Perl semantics aligned — do not omit it. Add a
  **Sandbox alignment** subsection: honour `$TMPDIR`; sandbox provides
  `/tmp/claude`; **`$TMPDIR` is trusted only under the single-user threat model —
  the `mkdir -m 0700` guard remains the containment boundary if that assumption is
  relaxed**; Task-199 ref; Task-178 cross-ref.
- `.cwf/security/script-hashes.json` — refresh the `security-review-changeset`
  sha256 (same commit as the helper edit).

### Supporting Changes (committable)
- `t/security-review-changeset.t` — add TMPDIR-contract subtests (below).

### Cross-surface Changes (in-session, NOT committable — user-global)
- `~/.claude/projects/.../memory/feedback_no_heredocs.md` — example scratch paths.
- `~/.claude/projects/.../memory/feedback_no_tee_permissions.md` — example paths.
- `~/.claude/projects/.../memory/MEMORY.md` — the squash-commit `/tmp/-home-…-task-NNN/msg.txt`
  example. (No standalone `tmp-paths` memory exists.)
  Record these in f-exec **Actual Results** as a cross-surface dependency.

### No change (verified, with reason)
- `cwf-apply-artefacts:647-648`, `cwf-manage:490` — class (c), `File::Temp`/`tempdir`
  honour `$TMPDIR` natively → safe once the sandbox sets it (FR4 disposition (ii),
  pending D2 confirmation). Record disposition in g-testing.
- `ArtefactHelpers.pm:66`, `Versioning.pm:131` — class (a), `DIR`-pinned in-repo → safe.
- `cwf-implementation-exec/SKILL.md:65`, `cwf-testing-exec/SKILL.md:59` — indirect,
  delegate to `tmp-paths.md`; self-update, no literal edit, no hash churn.
- `template-copier` `/tmp/test`, `security-review.md:104` `/tmp/cwf-update` — illustrative.

## Implementation Steps
### Step 1: Test first (red)
- [ ] Add `t/security-review-changeset.t` subtests asserting the reported `.out`
  path honours `$TMPDIR` (reuse the existing `run_helper_raw` fork/exec +
  `out_path` parse; the child inherits `%ENV`, so set state in the parent precisely):
  - **TC-TMPDIR-1**: `local $ENV{TMPDIR} = tempdir(CLEANUP=>1)` (writable, non-`/tmp`)
    → `.out` under `$TMPDIR/<dashified>-task-<num>/`. CLEANUP tempdir reclaims the
    outer dir; the harness `END` block already rmdirs the inner scratch.
  - **TC-TMPDIR-2**: **unset** via `delete local $ENV{TMPDIR}` (NOT bare `local`,
    which leaves the inherited value) → `.out` under `/tmp/<dashified>-task-<num>/`
    (no regression).
  - **TC-TMPDIR-3**: `local $ENV{TMPDIR} = ''` (empty) → `.out` path **matches
    `^/tmp/`** and **does NOT match `^/-`** (the root-collapse failure mode). This
    is the load-bearing length-check assertion — a weak "falls back" check would
    pass even with the length-check dropped.
- [ ] Run; confirm TC-TMPDIR-1/3 fail against the current hardcoded `/tmp/` code.

### Step 2: Core implementation (green)
- [ ] Edit `security-review-changeset:255-261` to the c-design Perl mirror
  (`$base` length-checked + trailing-slash strip; `$scratch = "$base/${dashed}-task-${task_num}"`).
- [ ] Update doc-comment path literals `:59`, `:344` to the `${TMPDIR:-/tmp}/…` form.
- [ ] Refresh the `security-review-changeset` hash: `cwf-manage fix-security`
  (then `git add` `script-hashes.json`) — same commit.
- [ ] Re-run `t/security-review-changeset.t`; all green.

### Step 3: Convention doc
- [ ] Apply the `tmp-paths.md` edits (form/snippet/examples/threat-model/Why +
  Sandbox-alignment subsection) per Files to Modify.

### Step 4: Cross-surface guidance (in-session)
- [ ] Update the two memory files + `MEMORY.md` example to the honour-`$TMPDIR`
  form; note in f-exec Actual Results (uncommittable).

### Step 5: Validation
- [ ] `prove t/security-review-changeset.t` green.
- [ ] `cwf-manage validate` clean (hash refreshed).
- [ ] AC3 grep gate (reproducible): `grep -rn '/tmp/' .cwf/docs/conventions/tmp-paths.md
  .cwf/scripts/command-helpers/security-review-changeset` shows only
  `${TMPDIR:-/tmp}` / `$base`-rooted forms — zero bare-`/tmp/${...}-task-` scratch
  literals. Carve-out exclusions (legitimate `/tmp/`, NOT scratch): `template-copier`
  `/tmp/test`, `security-review.md:104` `/tmp/cwf-update`, INSTALL.md install-time,
  historical `implementation-guide/`/BACKLOG/CHANGELOG, user-owned `settings.local.json`.
  e-testing-plan owns the exact gate.
- [ ] Output smoke: run the helper in a synthetic repo with `TMPDIR` set; confirm
  `.out` lands under `$TMPDIR` (rebrand-smoke-test discipline).
- [ ] g-testing records the FR4 (ii) class-(c) disposition and the FR7 sandbox
  denial result (BLOCKED-ENV in the unsandboxed dev session).

## Code Changes
### Before (`security-review-changeset:261`)
```perl
my $scratch = "/tmp/${dashed}-task-${task_num}";
```
### After (`:255-261`, minimal diff; `$dashed` via `find_git_root` unchanged)
```perl
my $base = (defined $ENV{TMPDIR} && length $ENV{TMPDIR}) ? $ENV{TMPDIR} : '/tmp';
$base =~ s{/+$}{};
my $scratch = "$base/${dashed}-task-${task_num}";
# :264-272 unchanged — unless(-d){mkdir 0700 or {warn;exit 1}}; 0600 write is the
# fail-closed defence on a pre-existing foreign-owned dir.
```

## Test Coverage
**See e-testing-plan.md for complete test plan** — TC-TMPDIR-1/2/3 (path
construction, sandbox-independent) plus the FR7 sandbox-denial check (BLOCKED-ENV).

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results.**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.
The committable change is self-contained; the class-(c) follow-up only materialises
if D2 is falsified (FR7), in which case raise a BACKLOG entry — do not silently defer.

## Decomposition Check
- [ ] Time >1 week? No. — [ ] People >2? No. — [ ] Complexity 3+? No (one
  mechanism). — [ ] Risk isolation? No. — [ ] Independence? Class-(c) follow-up
  only if D2 falsified.
**Conclusion**: single task confirmed; no decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
