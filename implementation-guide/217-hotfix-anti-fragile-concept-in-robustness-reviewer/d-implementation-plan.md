# Anti-fragile concept in robustness reviewer - Implementation Plan
**Task**: 217 (hotfix)

## Task Reference
- **Task ID**: internal-217
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/217-anti-fragile-concept-in-robustness-reviewer
- **Template Version**: 2.1

## Goal
Introduce the anti-fragile concept into the robustness reviewer's instructions
as one added clause, distinguishing anti-fragile (strengthens under stress) from
merely robust (resists stress), without adding criteria the reviewer cannot judge
from its input.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Design Decision: what to change, and where

The concept is expressed via the **fragile → robust → anti-fragile** spectrum
(Taleb's triad). Naming the triad is deliberate: it is what distinguishes
anti-fragile from robust, satisfying the "must distinguish" success criterion.
The existing "avoid fragile failure paths" wording is the *fragile* end of that
same spectrum, so the new clause subsumes it rather than adding a parallel idea.

**Scope of files** — two agents carry a robustness focus:
- `cwf-robustness-reviewer-changeset.md` — reviews the actual diff. **Primary,
  definite change.** The concept applies most directly here — but note the
  reviewer's input is a *static* `.out` diff with no Bash/execution, so the
  wording must stay to properties visible in a diff (see robustness-review
  finding folded below).
- `cwf-plan-reviewer-robustness.md` — reviews plan prose; its `design` focus
  already asks "Are degradation paths defined?", which is the same idea one
  altitude up. **Secondary — OPEN DECISION for user review** (see below).

**Integrity (corrected after plan review)**: both agent def files ARE recorded
in `.cwf/security/script-hashes.json` (at `permissions: 0444`, sha256 tracked) —
an earlier draft wrongly claimed they were untracked. Editing either therefore
requires a same-commit hash refresh per `.cwf/docs/conventions/hash-updates.md`;
`script-hashes.json` is listed as a Supporting Change below (plan-time
disclosure) and the refresh is Step 4.

**Decision (resolved by the user): both files.** Both robustness reviewers get
the concept — the changeset reviewer (static diff) and the plan reviewer (design
prose) — keeping the role consistent (task-plan Risk 2). Both edits incur a
same-commit `script-hashes.json` refresh.

## Files to Modify
### Primary Changes
- `.claude/agents/cwf-robustness-reviewer-changeset.md` — extend the single
  robustness-focus sentence (step 3) with the anti-fragile clause. No other line
  changes; the verdict-block `findings` trigger already covers "fragile failure
  path" and stays as-is.

- `.claude/agents/cwf-plan-reviewer-robustness.md` — add a matching short clause
  to the `design` bullet (both-file scope confirmed).

### Supporting Changes
- `.cwf/security/script-hashes.json` — refresh the `sha256` entry for BOTH edited
  agent files in the SAME commit (mandatory; see Step 4).

<!-- No symbols deleted; no Deletes line. Both edited agent files ARE hash-tracked
     in .cwf/security/script-hashes.json (perms 0444), so a same-commit hash
     refresh IS in scope — see Step 4. -->

## Implementation Steps
### Step 1: Unlock the hashed file(s)
- [ ] `chmod u+w` each agent file to edit (recorded/on-disk mode is 0444).

### Step 2: Apply primary edit
- [ ] Edit `cwf-robustness-reviewer-changeset.md` step 3 per Code Changes below.

### Step 3: Apply plan-reviewer edit
- [ ] Edit `cwf-plan-reviewer-robustness.md` `design` bullet per Code Changes below.

### Step 4: Refresh integrity + restore perms (same commit as the edit)
Per `.cwf/docs/conventions/hash-updates.md` — `fix-security` does NOT recompute
sha256 (by design); the refresh is manual:
- [ ] Pre-refresh check, per edited file: `git log --oneline <last-hash-set-commit>..HEAD -- <path>`
      confirms the only intervening change is this task's edit.
- [ ] `sha256sum <path>` for each edited file; Edit its matching `sha256` entry
      in `.cwf/security/script-hashes.json`.
- [ ] `chmod 0444` each edited file (restore recorded perms — do not bump).
- [ ] `.cwf/scripts/cwf-manage validate` passes (no sha256 / permission drift).

### Step 5: Verify content
- [ ] Grep tool (not `git grep`) for `anti-fragil` over `.claude/agents/`: term
      present in the intended file(s), nowhere unintended.
- [ ] Re-read each edited sentence: term present, distinction from robust clear,
      concise, and every named property is observable from the reviewer's input
      (static diff for the changeset reviewer — no runtime-only criteria).
- [ ] Confirm `cwf-agent-shared-rules.md` was NOT touched (single-role rule).

## Code Changes
### Before — `cwf-robustness-reviewer-changeset.md` (step 3)
```markdown
3. Review the changeset against the **robustness** focus: does the diff handle
   errors and edge cases, follow correct > maintainable > performant ordering,
   and avoid fragile failure paths? Cite the specific diff location each finding
   derives from.
```

### After — `cwf-robustness-reviewer-changeset.md` (step 3)
Runtime-only properties (`load`, `partial failure`, `self-hardening`) are dropped
per the robustness review — this reviewer sees only a static diff. The named
properties (fail-safe defaults, defensive fallbacks, bad-input handling) are all
diff-observable. A second sentence keeps the verdict semantics honest: leaning
anti-fragile is advisory, so its mere absence is not a `findings` trigger.
```markdown
3. Review the changeset against the **robustness** focus: does the diff handle
   errors and edge cases, follow correct > maintainable > performant ordering,
   and avoid fragile failure paths — ideally leaning anti-fragile on the
   fragile → robust → anti-fragile spectrum, where bad input meets fail-safe
   defaults and defensive fallbacks rather than a break? Anti-fragility is
   advisory: note where the diff could climb the spectrum, but its absence alone
   is not a finding — only fragile paths or mishandling are. Cite the specific
   diff location each finding derives from.
```

### After — `cwf-plan-reviewer-robustness.md` `design` bullet
```markdown
   - **design**: Are failure modes identified? Are degradation paths defined?
     Does the design sit toward the anti-fragile (strengthens under stress) end
     of the spectrum rather than the fragile end? Does it prioritise correctness
     over maintainability over performance?
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
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Executed as planned after the hash-tracking correction: both files edited, both
`sha256` entries refreshed same-commit, perms restored to 0444, `validate` clean.
See f-implementation-exec.md for step-by-step results.

## Lessons Learned
`cwf-manage fix-security` clamps perms only; the sha256 refresh is manual
(`sha256sum` → edit manifest → `validate`).
