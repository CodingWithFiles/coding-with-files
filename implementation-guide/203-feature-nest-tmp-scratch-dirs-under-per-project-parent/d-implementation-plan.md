# Nest tmp scratch dirs under per-project parent dir - Implementation Plan
**Task**: 203 (feature)

## Task Reference
- **Task ID**: internal-203
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/203-nest-tmp-scratch-dirs-under-per-project-parent
- **Template Version**: 2.1

## Goal
Implement Nest tmp scratch dirs under per-project parent dir following the approved design and requirements.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cwf/scripts/command-helpers/security-review-changeset` — path assembly (line 263:
  `$base/${dashed}-task-${task_num}` → nested parent+leaf) and mkdir block (255-275:
  two-level create + lstat symlink-reject per design D2). Header comment (59) and usage
  text (347) updated to the nested form.
- `.cwf/security/script-hashes.json` — refresh the helper's sha256 **in this commit**
  (hash-updates convention).
- `.cwf/docs/conventions/tmp-paths.md` — canonical form (12, 24), derivation snippet
  (30-40), artefact examples (47-50), worked example, threat-model guard text (94-103),
  optional-allowlist-pattern note (D4, correct syntax + granularity trade-off + no-secrets
  caution), agent active-use instruction (D6), `-tool-check` carve-out note (D5).
- `CLAUDE.md` — Tmp Paths convention bullet (~line 89) canonical form.
- `.claude/skills/cwf-new-task/SKILL.md` and `.claude/skills/cwf-new-subtask/SKILL.md` —
  add a provisioning step (D6): create parent+leaf via the `tmp-paths.md` snippet, non-fatal,
  surface the path. Not hashed files. (new-task: after step 4 branch create; new-subtask:
  after its Create-Subtask step — it has no `git checkout -b`.)

### Supporting Changes
- `t/security-review-changeset.t` — extend (reuse existing file): assert nested `.out`
  path shape + parent **and** leaf 0700; add a parent-symlink negative case (exit 1); add a
  shared-parent-reuse positive case.
- **NOT modified**: any `settings.json`/`settings.local.json` (D4 — documented only); the
  `-tool-check` state dir (D5). Accepted limitation: `-tool-check` stays a sibling, so the
  "single per-project parent" goal is intentionally only partially met (D5 rationale).

## Implementation Steps
### Step 1: Tests first
- [ ] Extend `t/security-review-changeset.t` TC-OUTFILE: assert reported `.out` matches
      `…/cwf<dash>/task-<num>/security-review-changeset-<step>.out` and that **both** the
      `cwf<dash>` parent and the `task-<num>` leaf are mode 0700. (The existing TC-OUTFILE
      already derives `$dir` from the `.out` path and checks leaf 0700, so the **parent**
      mode + nested-shape regex are the load-bearing new assertions.)
- [ ] Add TC-PARENT-SYMLINK: pre-create the `cwf<dash>` parent as a symlink → helper exits
      1 (skip if symlinks unsupported, matching the existing TC-SYMLINK skip idiom). Use an
      **isolated repo root**; tear the symlink down with **`unlink`** (not `rmdir`) in an
      END/guard that runs **even on subtest failure**, so a leaked symlinked parent cannot
      poison a re-run or sibling subtests.
- [ ] Add TC-PARENT-REUSE (positive): pre-create the `cwf<dash>` parent at a **non-0700 mode
      (e.g. 0755)** → helper proceeds and writes the leaf, and the parent mode is left
      **unchanged (0755, not clamped)** — the observable form of "never auto-chmod"; exercises
      `mkdir … unless -d` short-circuit + step-2 recheck passing.
- [ ] Update the cleanup **END block** (`t/security-review-changeset.t:114-120`): it
      currently `rmdir`s only the immediate parent of `.out` (now the `task-<num>` leaf),
      leaking the new `cwf<dash>` grandparent each run. Extend it to also remove the
      `cwf<dash>` parent (now empty once the leaf is gone — no sentinel).
- [ ] Run suite → new assertions fail (red)

### Step 2: Helper
- [ ] Anchor edits **by content, not line number** (numbers drift once editing starts): the
      `${dashed}-task-${task_num}` assembly string, the `unless (-d $scratch)` mkdir block,
      the header comment carrying `<dashified-…>-task-<num>`, and the usage-text equivalent.
- [ ] Change path assembly to the nested parent/leaf (see Code Changes), **reusing the
      existing `$base`/`$dashed`** — do not re-derive `find_git_root()`/`$TMPDIR`.
- [ ] Replace single mkdir with two-level create: `mkdir 0700 parent unless -d`; reject
      `unless -d parent && !-l parent` (warn+exit 1, recheck-after-mkdir is race-tolerant;
      also catches a non-symlink step-1 mkdir failure, fail-closed); `mkdir 0700 leaf unless
      -d` (or warn+exit 1). No `.cwfkeep`.
- [ ] Update header comment and usage text to the nested form
- [ ] Run suite → green

### Step 3: Hash refresh (same commit as Step 2)
- [ ] `cwf-manage fix-security` (or recompute) to refresh the helper's sha256; verify
      `cwf-manage validate` is clean

### Step 4: Docs + skills
- [ ] **First** rewrite the `tmp-paths.md` derivation snippet to the nested
      `cwf<dash>/task-<num>` form (form, examples, threat text, optional-allowlist note with
      correct syntax + per-project-vs-per-task trade-off + no-secrets caution, agent
      active-use instruction, D5 carve-out note). The skills (next bullet) reference **this
      rewritten snippet** — ordering matters so the parent-form stays single-sourced.
- [ ] Update `CLAUDE.md` Tmp Paths bullet
- [ ] Add the D6 provisioning step to `/cwf-new-task` (after step 4) and `/cwf-new-subtask`
      (after Create-Subtask; it has no `git checkout -b`) — reuse the rewritten `tmp-paths.md`
      snippet (worktree-safe), non-fatal, honest signpost (no path printed if mkdir failed).
      **No settings file edits.**

### Step 5: Validation
- [ ] Full `t/` suite green; `cwf-manage validate` clean
- [ ] Output-level smoke test: run the helper, confirm `.out` at the nested path; assert the
      parent basename **begins with `cwf`** (keeps it provably disjoint from `-tool-check`)
- [ ] Provisioning smoke (**MANUAL** — skill, not a `t/` test): `/cwf-new-task` creates
      parent+leaf and surfaces the path; **and** the non-fatal path — a forced `mkdir` failure
      warns, does **not** block branch creation, and does **not** print the path as if created
- [ ] Grep sweep (anchored on `-task-` so it ignores `-tool-check`): old `<repo>-task-<num>`
      (dash) form gone except carve-outs; `-tool-check` dir untouched (D5)

## Code Changes (helper mkdir block — the security-critical section)
### Before (security-review-changeset:263, 269-275)
```perl
my $scratch = "$base/${dashed}-task-${task_num}";
...
unless (-d $scratch) {
    mkdir($scratch, 0700)
        or do { warn "$PROG: cannot create scratch dir $scratch: $!\n"; exit 1; };
}
my $out = "$scratch/security-review-changeset-$opt{wf_step}.out";
```
### After
```perl
my $parent  = "$base/cwf${dashed}";          # stable per-project parent
my $scratch = "$parent/task-${task_num}";    # per-task leaf
mkdir($parent, 0700) unless -d $parent;
# defence-in-depth: reject a symlinked parent (lstat via -l), not the boundary.
# recheck AFTER mkdir is race-tolerant (concurrent create ok, symlink still rejected).
# NB: deliberately NO chmod-clamp here (cf. hooks/pretooluse-bash-tool-check, which clamps) —
# never auto-chmod a foreign/wrong-mode parent (design D2: surface, never smooth).
unless (-d $parent && !-l $parent) {
    warn "$PROG: scratch parent $parent is not a usable directory\n"; exit 1;
}
unless (-d $scratch) {
    mkdir($scratch, 0700)
        or do { warn "$PROG: cannot create scratch dir $scratch: $!\n"; exit 1; };
}
my $out = "$scratch/security-review-changeset-$opt{wf_step}.out";
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five planned steps executed in order (tests-red → helper-green → in-commit hash
refresh → docs+skills → validation). No deferred work. The plan-review subagents' guidance
was followed; no plan revision was needed during execution.

## Lessons Learned
*Consolidated in j-retrospective.md.*
