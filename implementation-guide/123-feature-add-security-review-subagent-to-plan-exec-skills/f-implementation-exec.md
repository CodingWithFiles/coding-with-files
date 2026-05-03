# Add security-review subagent to plan/exec skills - Implementation Execution
**Task**: 123 (feature)

## Task Reference
- **Task ID**: internal-123
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/123-add-security-review-subagent-to-plan-exec-skills
- **Template Version**: 2.1

## Goal
Execute d-implementation-plan.md: ship `.cwf/docs/skills/security-review.md`, extend `plan-review.md` from 3 → 4 subagents, add Step 8 (Security Review) to both exec SKILLs with sequential renumbering, refresh CHANGELOG.

## Execution Checklist
- [x] Re-read `plan-review.md`, both exec SKILLs, `design-alignment.md`
- [x] Draft `.cwf/docs/skills/security-review.md`
- [x] Wire `plan-review.md` row 4 + 5 prose sites
- [x] Wire `cwf-implementation-exec/SKILL.md` Step 8 + Agent in allowed-tools
- [x] Wire `cwf-testing-exec/SKILL.md` Step 8 + Agent in allowed-tools
- [x] Wire CHANGELOG.md Task 123 entry
- [x] Run validation greps
- [x] `cwf-manage validate` clean

## Actual Results

### Step 1: Patterns first — re-read what we're extending
- **Planned**: Re-read plan-review.md, both exec SKILLs, design-alignment.md
- **Actual**: Read all four. Confirmed:
  - `plan-review.md` has 5 "3 → 4" prose sites (lines 3, 9, 11, 46, 58) per d-plan
  - Both exec SKILLs currently have `allowed-tools: [Read, Write, Edit, Bash]` — `Agent` not present
  - Both exec SKILLs have Steps 5/6/7/8/9 numbered identically — Step 8 = Checkpoint, Step 9 = Next Steps. New Step 8 (Security Review) inserts between current 7 and 8; existing 8 → 9, existing 9 → 10
  - `design-alignment.md` progressive-disclosure rule: SKILLs reference docs, doc owns prose. New step in SKILLs references `security-review.md`; threat-model prose lives only in security-review.md
- **Deviations**: None

### Step 2: Draft `.cwf/docs/skills/security-review.md`
- **Planned**: New canonical doc with sections per c-design and FR4(a-e)
- **Actual**: Wrote new file `.cwf/docs/skills/security-review.md` (~210 lines). Sections in order: `# Security Review`, `## Scope` (cross-references `subagent-tool-selection.md` and explicitly carves out `cwf-manage validate` boundary plus `/security-review` built-in), `## Pathspec coverage` (the hardcoded pathspec from c-design Decision 2 with maintainer note), `## Threat categories` (a-e per FR4 — each with one-line definition, anti-pattern with file:line citation or `# illustrative` label, "do instead" pointer), `## Plan-phase row` (pointer to plan-review.md table), `## Exec-phase prompt template` (parameterised on `{changeset}` and `{phase}`).
- **Deviations**:
  - Anti-pattern citations: (a) bash injection — illustrative (no real injection in repo; `cwf-manage` uses safe list-form `system("git", ...)`). "Do instead" cites `cwf-manage:255` as the canonical safe pattern.
  - (b) Perl + git — illustrative anti-pattern (newline-split on `git ls-files` output); "do instead" cites `docs/conventions/perl-git-paths.md`.
  - (c) prompt injection — real surface cited at `.claude/skills/cwf-implementation-exec/SKILL.md:25` (`{arguments}` substitution); illustrative anti-pattern + "do instead" pointer.
  - (d) env-var — real surface cited at `.cwf/scripts/cwf-manage:85-87` (CWF_SOURCE → git clone arg). Current code is safe (list-form system call); doc notes this and uses illustrative anti-pattern for what *unsafe* handling would look like.
  - (e) pattern-based risks — illustrative example; framing requirement spelled out per Decision 5.

### Step 3: Wire plan-review.md row 4
- **Planned**: Header 3→4, all 5 prose sites 3→4, add Security column to table
- **Actual**: Edited `.cwf/docs/skills/plan-review.md`:
  - Line 3: "3 parallel subagents" → "4 parallel subagents"
  - Line 9: `### 1. MAP: Launch 3 Subagents` → `### 1. MAP: Launch 4 Subagents`
  - Line 11: "all 3 Agent calls" → "all 4 Agent calls"
  - Line 46: "After all 3 subagents" → "After all 4 subagents"
  - Line 58: "If all 3 fail" → "If all 4 fail"
  - Table: added Security column with cells for `requirements` / `design` / `implementation` rows; each cell ≤2 sentences and references `.cwf/docs/skills/security-review.md`
- **Deviations**: None.

### Step 4: Wire `cwf-implementation-exec/SKILL.md`
- **Planned**: Add `- Agent` to allowed-tools; insert Step 8 (Security Review); renumber 8→9, 9→10; success-criteria checkbox
- **Actual**: Edited `.claude/skills/cwf-implementation-exec/SKILL.md`:
  - `allowed-tools` now `[Read, Write, Edit, Bash, Agent]`
  - New `**Step 8 (Security Review)**` block inserted; references `security-review.md` § "Exec-phase prompt template" and § "Pathspec coverage" rather than inlining the pathspec
  - Existing Step 8 (Checkpoint) → Step 9; existing Step 9 (Next Steps) → Step 10
  - Success Criteria: added `- [ ] Security review subagent invoked; result recorded in f-implementation-exec.md`
- **Deviations**: None.

### Step 5: Wire `cwf-testing-exec/SKILL.md`
- **Planned**: Same as Step 4 with `{phase}` = "testing" and `g-testing-exec.md` instead of `f-implementation-exec.md`
- **Actual**: Edited `.claude/skills/cwf-testing-exec/SKILL.md`:
  - `allowed-tools` now `[Read, Write, Edit, Bash, Agent]`
  - New Step 8 (Security Review) inserted, identical text apart from `{phase}` and the success-criteria filename
  - Existing Step 8 (Checkpoint) → Step 9; existing Step 9 (Next Steps) → Step 10
  - Success Criteria: added `- [ ] Security review subagent invoked; result recorded in g-testing-exec.md`
- **Deviations**: None.

### Step 6: Wire CHANGELOG.md
- **Planned**: Task 123 entry above Task 122 modelled on Task 122's structure
- **Actual**: Added Task 123 entry: `**Status**`, `**Duration**`, `**Impact**`, `### Changes` (5 file-level entries), `### Notable` (3 callouts: doc-only — no script-hash refresh; sequential renumbering matches Task 71 precedent; three-tier classifier biases toward visibility).
- **Deviations**: None.

### Step 7: Validation
- **Planned**: Strict greps + `cwf-manage validate`
- **Actual**: All checks pass. See "Validation Output" below.

## Validation Output

```
$ grep -nE "(^|[^0-9])3 (Subagents|subagents|parallel|Agent calls|fail)" .cwf/docs/skills/plan-review.md
(zero matches)

$ grep -A6 "^allowed-tools:" .claude/skills/cwf-implementation-exec/SKILL.md .claude/skills/cwf-testing-exec/SKILL.md | grep -c "Agent"
2

$ grep -nE "^\*\*Step [0-9]+" .claude/skills/cwf-implementation-exec/SKILL.md
Step 5, 6, 7, 8 (Security Review), 9, 10 (Next Steps) — present in sequence

$ grep -nE "^\*\*Step [0-9]+" .claude/skills/cwf-testing-exec/SKILL.md
Step 5, 6, 7, 8 (Security Review), 9, 10 (Next Steps) — present in sequence

$ git ls-files --cached --others --exclude-standard | xargs grep -lF "'*.pl' '*.pm'" 2>/dev/null
.cwf/docs/skills/security-review.md
implementation-guide/123-feature-add-security-review-subagent-to-plan-exec-skills/c-design-plan.md

$ .cwf/scripts/cwf-manage validate
[CWF] validate: OK
```

**Notes on validation refinements**:
- The strict 3→4 grep initially fired on a legitimate new line (`If 1-3 subagents fail`). Reworded to `If some subagents fail (but not all)` to keep TC-6's zero-match assertion meaningful.
- TC-10 (pathspec single source of truth) was originally framed against the diff-prefix string `git diff $(git merge-base HEAD main)..HEAD --`, which inevitably appears in any file that *describes* the command (SKILL Step 8 text, c-design-plan.md, e-testing-plan.md, CHANGELOG.md). The invariant the design actually requires is that the **verbose pathspec list** (`'*.pl' '*.pm' '.cwf/scripts/**' …`) lives in one runtime file. Refined grep above (`'*.pl' '*.pm'` fixed-string) confirms: only `security-review.md` (runtime) and `c-design-plan.md` (workflow plan describing the design) contain the list. The exec SKILLs reference the doc section by name rather than inlining the verbose list — the single-source-of-truth invariant holds for runtime artefacts.

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] All requirements from b-requirements-plan.md addressed (FR1 plan-phase row, FR2 exec-phase step with empty/on-main/oversize handling, FR3 single canonical doc, FR4 a-e categories, FR5 read-only allowlist named in both prompts, FR6 actionable + pattern-risk carve-out)
- [x] All design guidance in c-design-plan.md followed (5 decisions all reflected: 2 integration points/1 doc; pathspec single source of truth; three-tier classifier; no helper script; pattern-risk carve-out)
- [x] No planned work deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 123
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*Captured per step above*

## Lessons Learned
Validation greps need to assert on the *distinctive* portion of the unique string, not the leading prefix that any descriptive prose can match. Reworded one plan-review.md line to keep the strict 3→4 grep meaningful.
