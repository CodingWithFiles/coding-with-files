# cwf-new-subtask omits git branch creation - Implementation Plan
**Task**: 230 (bugfix)

## Task Reference
- **Task ID**: internal-230
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/230-cwf-new-subtask-omits-git-branch-creation
- **Template Version**: 2.1

## Goal
Insert a "Create Git Branch" step into `.claude/skills/cwf-new-subtask/SKILL.md` and remove the
prose that blessed the omission. The branch **command** is byte-identical to `cwf-new-task`
step 4; the step adds a short, deliberate subtask-specific note (decimal `<num>`, reuse the
script-produced slug, ff-merge-back-into-parent precondition) — a documented divergence, not a
verbatim mirror of the whole step. Single-file prose change.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.claude/skills/cwf-new-subtask/SKILL.md` — add branch-creation step; renumber later steps; correct the false "stays on the parent branch" prose; surface the branch in Next Steps and Success Criteria.

### Supporting Changes
- None. `.claude/skills/` is **not** hash-tracked (verified: no `cwf-new-subtask` or `claude/skills` entry in `.cwf/security/script-hashes.json`), so no `script-hashes.json` refresh. `task-workflow create` is untouched. No test-harness file (Decision 4).
- **No-code-change consumer to confirm (not assume)**: with the subtask now on its own branch, `CWF::TaskContextInference._get_branch_signal` (`.cwf/lib/CWF/TaskContextInference.pm:287`) resolves the subtask's *own* decimal number rather than the parent's — a behaviour change from Task 166's "subtasks share the parent branch" premise. It needs **no** code change (`resolve_branch` already accepts decimal subtask branches; the ancestry-collapse correlator resolves to the deepest task), so `Supporting Changes: None` holds — but `e-testing-plan.md` must **confirm** the branch signal still correlates correctly for a subtask on its own branch.
- **Out of scope (inherited)**: if `git checkout -b` fails (e.g. branch name already exists), Step 3's directory is left with no branch — the identical partial-completion seam `cwf-new-task` already has. Not addressed here; see c-design-plan "Failure mode (accepted, pre-existing)".

<!-- No named symbol is deleted — this is prose, not code — so no "- **Deletes**:" line. -->

## Implementation Steps

### Step 1: Setup
- [ ] Confirm on branch `bugfix/230-cwf-new-subtask-omits-git-branch-creation`
- [ ] Re-read the pattern source `.claude/skills/cwf-new-task/SKILL.md` steps 4 & 6 and Success Criteria to mirror wording

### Step 2: Edits to `.claude/skills/cwf-new-subtask/SKILL.md` (see Code Changes for exact before/after)
- [ ] **2a** Scope & Boundaries "This step" line — add the branch
- [ ] **2b** Insert `### 4. Create Git Branch` (bare command, no fatal/non-fatal annotation) after the current step 3, before scratch provisioning
- [ ] **2c** Renumber: `Provision the Scratch Directory` 4→5, `Provide Next Steps` 5→6
- [ ] **2d** Delete the false "no `git checkout -b` … stays on the parent branch" sentence (pure deletion, no replacement)
- [ ] **2e** Add "branch created and checked out — surface the branch name" to the Next Steps body
- [ ] **2f** Add "Git branch created and checked out" to Success Criteria

### Step 3: Verify (self-check before testing phase)
- [ ] `grep -n "checkout\|branch"` the file — the only **success-path** branch mention is the new Step 4; the two Type-Inference **failure-path** lines ("no directory, no branch" / "no branch checkout") are expected residual matches (and only become accurate once Step 4 exists); no residual "stays on the parent branch"
- [ ] Step numbering is contiguous 1→6
- [ ] Branch **command** byte-identical to `cwf-new-task` step 4 (the surrounding subtask note deliberately differs)

## Code Changes

**2a — Scope & Boundaries (current line 13)**
```
- **This step**: Create a subtask within an existing parent task.
+ **This step**: Create a subtask within an existing parent task, on its own git branch.
```

**2b — new step, inserted after current step 3 (`### 3. Validate and Create Subtask`), before `### 4. Provision the Scratch Directory`**
````
### 4. Create Git Branch
```bash
git checkout -b "<type>/<num>-<slug>"
```
`<num>` is the subtask's full decimal (e.g. `48.1`); reuse the slug from the directory Step 3
created — do not re-derive it. Branches off the current parent-branch `HEAD`, so the parent
branch is an ancestor of the subtask branch — the precondition the retrospective's ff-merge
back into the parent relies on.
````

**2c — renumber the two following headings**
```
- ### 4. Provision the Scratch Directory
+ ### 5. Provision the Scratch Directory
...
- ### 5. Provide Next Steps
+ ### 6. Provide Next Steps
```

**2d — delete the false prose (current lines 102-103), add nothing** — `cwf-new-task`'s scratch step carries no such ordering sentence, so the minimal mirror is a pure deletion
```
- There is **no `git checkout -b`** in this skill — the subtask stays on the
- parent branch — so provisioning follows subtask creation directly.
```

**2e — Next Steps body (renumbered step 6)**
```
  - Subtask directory, parent link, structural map shown
+ - Branch created and checked out — surface the branch name
  - Scratch dir provisioned (or noted as deferred to first use) — surface the path
  - Next action: `/cwf-task-plan <num>`
```

**2f — Success Criteria**
```
  - [ ] Subtask directory created with template files
+ - [ ] Git branch created and checked out
  - [ ] Scratch dir provisioned (non-fatal) and path surfaced
```

## Test Coverage
**See e-testing-plan.md for complete test plan** — a reproducible create→branch→ff-merge
smoke-test (Decision 4); no automated harness. Must also **confirm** the `CWF::TaskContextInference`
branch signal still correlates correctly for a subtask on its own branch (see Supporting Changes).

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
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
