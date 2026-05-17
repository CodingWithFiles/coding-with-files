# Fix Task 147 hash drift, clarify hash rule - Implementation Execution
**Task**: 149 (chore)

## Task Reference
- **Task ID**: internal-149
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/149-fix-task-147-hash-drift-clarify-hash-rule
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Actual Results

### Step 1: Per-file pre-refresh diff verification

- **Planned**: Run `git log --oneline <baseline>..HEAD -- <path>` for each file; expect exactly one line attributable to commit `246e6c4` (Task 147).
- **Actual**:
  ```
  $ git log --oneline 4f47494..HEAD -- .cwf/lib/CWF/Backlog.pm
  246e6c4 Task 147: retire bootstraps missing CHANGELOG task entry

  $ git log --oneline f833bbf..HEAD -- .cwf/scripts/command-helpers/backlog-manager
  246e6c4 Task 147: retire bootstraps missing CHANGELOG task entry
  ```
- **Deviations**: None. Both files show single-commit drift, attributable to Task 147.

### Step 2: Recompute hashes

- **Planned**: `sha256sum` both files; expect digests matching d-plan §Files to Modify.
- **Actual**:
  ```
  $ sha256sum .cwf/lib/CWF/Backlog.pm .cwf/scripts/command-helpers/backlog-manager
  375ce811ecb4f507e304075c96bd99393f75a93ccc09085ece1124b16849b7e7  .cwf/lib/CWF/Backlog.pm
  f9045c722c469eaacb2afeeb60d965fb0d43a35d892fc7239f6c8d35931fce9e  .cwf/scripts/command-helpers/backlog-manager
  ```
- **Deviations**: None. Both digests match validate "Actual" values from Task 148.

### Step 3: Refresh the two hash entries in-diff

- **Planned**: Two single-field Edit replacements in `.cwf/security/script-hashes.json`.
- **Actual**:
  - `CWF::Backlog.sha256`: `8c4bd187…ebdb85c` → `375ce811…49b7e7` ✓
  - `backlog-manager.sha256`: `1b360005…62e0b6b5c3` → `f9045c72…931fce9e` ✓
- **Deviations**: None.

### Step 4: Write the canonical convention doc

- **Planned**: Create `.cwf/docs/conventions/hash-updates.md`, ~60-70 lines, with the seven required sections.
- **Actual**: Created. 49 lines (under 80-line ceiling, under target). All seven sections present: Convention, Why, How (mechanical), Plan-time disclosure, Pre-refresh verification, Carve-out (4 invariants), What NOT to build, Historical example.
- **Deviations**: Length came in under the 60-70 target; declarative-criteria framing kept prose compact. The recipes-doc pattern from Task 148 confirms: minimum-viable doc estimates skew low, but tightness is a feature not a defect.

### Step 5: Wire the rule into cwf-implementation-exec

- **Planned**: Insert Gotcha 3 in `.claude/skills/cwf-implementation-exec/SKILL.md` via string-anchor Edit.
- **Actual**: Gotcha 3 inserted between existing Gotcha 2 and `## Scope & Boundaries` heading. Text matches d-plan verbatim. Anchor: blank line + heading line.
- **Deviations**: None.

### Step 6: Wire the rule into cwf-retrospective

- **Planned**: Insert Gotcha 4 in `.claude/skills/cwf-retrospective/SKILL.md` via string-anchor Edit.
- **Actual**: Gotcha 4 inserted between existing Gotcha 3 and `## Scope & Boundaries` heading. Text matches d-plan verbatim.
- **Deviations**: None.

### Step 7: Register convention in CLAUDE.md

- **Planned**: Append `**Hash Updates**` subsection to `## Conventions`, in the existing Perl/Tmp Paths/Git Path Handling style.
- **Actual**: Subsection appended immediately after `**Tmp Paths**`, before `## Architecture Overview`. 4 bullets + `See` line.
- **Deviations**: None.

### Step 8: Cross-reference from design-alignment.md

- **Planned**: Append one sentence to the existing `script-hashes.json` paragraph (line 80) pointing at the new convention doc.
- **Actual**: Two-line addendum inline with the existing paragraph: "When a rename or edit touches a hashed file, refresh the entry in the same commit — see `.cwf/docs/conventions/hash-updates.md`."
- **Deviations**: None.

### Step 9: Validate

- **Planned**: `cwf-manage validate` should report ONLY the misalignment-agent permission violation; zero `[SECURITY]` lines naming `CWF/Backlog.pm` or `backlog-manager`. STOP on any other drift.
- **Actual**:
  ```
  [SECURITY] /home/matt/repo/coding-with-files/.claude/agents/cwf-plan-reviewer-misalignment.md
    Field:    permissions
    Actual:   0600
    Expected: 0444
    Fix:      Run: chmod 0444 /home/matt/repo/coding-with-files/.claude/agents/cwf-plan-reviewer-misalignment.md

  [CWF] 1 violation(s) found.
  ```
  Zero `[SECURITY]` lines for `CWF/Backlog.pm` or `backlog-manager`. Sole remaining violation is the misalignment-agent perm bit (out of scope per a-plan §Constraints — git tracks only the executable bit, so this requires structural treatment in a separate task).
- **Deviations**: None. STOP condition not triggered.

## Blockers Encountered

None.

## Deferral Check

- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met (validate clean for the two entries; rule documented; canonical doc exists; pre-refresh verification recorded; Task 147 named as the historical example)
- [x] No planned work deferred
- [x] Misalignment-agent permission violation explicitly out of scope per a-plan §Constraints; flagged as Future Work, not deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 149
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: no findings

no findings
Both additions are documentation-only edits to SKILL.md files. They strengthen the security posture (hash-tracked file refresh discipline; explicit prohibition against absorbing hash drift at retrospective time) rather than weakening it. No code paths, permissions, inputs, or trust boundaries are affected.

## Lessons Learned
*To be captured during retrospective*
