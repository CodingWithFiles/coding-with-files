# Add security-review subagent to plan/exec skills - Implementation Plan
**Task**: 123 (feature)

## Task Reference
- **Task ID**: internal-123
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/123-add-security-review-subagent-to-plan-exec-skills
- **Template Version**: 2.1

## Goal
Ship the new canonical `.cwf/docs/skills/security-review.md`, add the 4th row to the existing plan-review map/reduce, and insert a new Step 8 (Security Review) into both exec SKILLs — all per the design in c-design-plan.md.

## Workflow
Patterns first (re-read existing plan-review.md and design-alignment.md) → Draft canonical doc → Wire plan-review row 4 → Wire exec SKILL Step 8 → Validate → Plan-review subagents on this implementation plan.

## Files to Modify

### Primary Changes
- **`.cwf/docs/skills/security-review.md`** (new) — Canonical threat-model doc plus the exec-phase prompt template and pathspec coverage section. Structure per c-design-plan.md §"Threat-model doc structure".
- **`.cwf/docs/skills/plan-review.md`** (edit) — `## Procedure` heading: "3 Subagents" → "4 Subagents". Criteria-lookup table: add 4th column `Security` with cells for `requirements` / `design` / `implementation` per c-design-plan.md §"Plan-review.md changes".
- **`.claude/skills/cwf-implementation-exec/SKILL.md`** (edit) — Insert new Step 8 (Security Review) after current Step 7; renumber existing Step 8 (Checkpoint commit) → 9, Step 9 (Next Steps) → 10. `allowed-tools` is currently `[Read, Write, Edit, Bash]` — **add `- Agent`**.
- **`.claude/skills/cwf-testing-exec/SKILL.md`** (edit) — Same insertion + renumber. `allowed-tools` is currently `[Read, Write, Edit, Bash]` — **add `- Agent`**.
- **`CHANGELOG.md`** (edit) — Task 123 entry above Task 122; modelled on Task 122's structure. (Listed as Primary because it's a required deliverable, not optional supporting paperwork.)

### Supporting Changes
- **`BACKLOG.md`** — leave the existing "Add Security Verification to Testing Workflow" entry **untouched**; it's a separate (deterministic-`cwf-manage validate`) concern per requirements constraints. No new BACKLOG entry needed; this task is self-contained.

### Files NOT modified (deliberate — verify during exec)
- `.claude/skills/cwf-{requirements,design,implementation}-plan/SKILL.md` — these already say "follow plan-review.md procedure"; extending plan-review.md propagates the 4th subagent automatically. **No SKILL edit required.**
- `.cwf/security/script-hashes.json` — only tracks scripts (`.cwf/scripts/`), not docs or skill prompts. Verify with Read after edits.

## Implementation Steps

### Step 1: Patterns first — re-read what we're extending
- [ ] Re-read `.cwf/docs/skills/plan-review.md` (full file) to confirm exact procedure-header wording and table format
- [ ] Re-read `.claude/skills/cwf-implementation-exec/SKILL.md` and `.claude/skills/cwf-testing-exec/SKILL.md` (full files) to identify the exact Step 8 insertion point and whether `Agent` is in `allowed-tools`
- [ ] Re-read `docs/conventions/design-alignment.md` (the doc we just shipped in Task 122) to confirm progressive-disclosure compliance is honoured

### Step 2: Draft `.cwf/docs/skills/security-review.md`
- [ ] Sections in order: `# Security Review`, `## Scope` (caller list, boundary vs `cwf-manage validate`, boundary vs `/security-review` built-in, **plus a one-line cross-reference to `.cwf/docs/conventions/subagent-tool-selection.md` for the Read/Grep/Glob allowlist rationale**), `## Pathspec coverage` (the hardcoded pathspec from c-design Decision 2 with the maintainer note), `## Threat categories` (a–e per FR4, each with definition / anti-pattern with file:line citation if real / "do instead"), `## Plan-phase row` (explanatory pointer to plan-review.md table), `## Exec-phase prompt template` (parameterised on `{changeset}`, `{phase}` per c-design)
- [ ] Each anti-pattern example MUST cite a real CWF file:line if such a pattern exists in the current codebase; if no real instance, label as `# illustrative` and use a plausible CWF-shaped snippet
- [ ] Length target: 150–250 lines. Bigger than `perl-git-paths.md` because it carries the prompt template and the threat categories with examples.

### Step 3: Wire plan-review.md row 4
- [ ] Procedure header: `### 1. MAP: Launch 3 Subagents` → `### 1. MAP: Launch 4 Subagents`.
- [ ] Update **all** "3 → 4" prose in the doc — there are 5 sites (verified via Grep): `"3 parallel subagents"` (line 3), `"3 Subagents"` (line 9), `"3 Agent calls in a single message"` (line 11), `"After all 3 subagents complete"` (line 46), `"If all 3 fail"` (line 58). Update each to "4".
- [ ] Criteria-lookup table: add `Security` column. Cells per c-design-plan.md §"Plan-review.md changes". Each cell ≤2 sentences and references `.cwf/docs/skills/security-review.md` rather than restating the threat model.
- [ ] No other plan-review.md changes; the prompt template machinery already handles arbitrary `{focus_area}` and `{criteria}`.

### Step 4: Wire `cwf-implementation-exec/SKILL.md`
- [ ] Add `- Agent` to `allowed-tools` (currently `[Read, Write, Edit, Bash]`; Agent is missing — confirmed by plan review).
- [ ] Insert new `**Step 8 (Security Review)**` block after current Step 7 ("Execute implementation steps systematically per d-implementation-plan.md…") and before current Step 8 (Checkpoint commit). Block content per c-design-plan.md §"Exec SKILL changes". Only the `{phase}` parameter substitution differs from Step 5's variant; the rest is identical.
- [ ] Renumber: existing **Step 8** → **Step 9**; existing **Step 9 (Next Steps)** → **Step 10 (Next Steps)**.
- [ ] Update `## Success Criteria` to add a checkbox: `- [ ] Security review subagent invoked; result recorded in f-implementation-exec.md`.

### Step 5: Wire `cwf-testing-exec/SKILL.md`
- [ ] Add `- Agent` to `allowed-tools` (currently `[Read, Write, Edit, Bash]`; Agent is missing — confirmed by plan review).
- [ ] Insert new `**Step 8 (Security Review)**` block — same content as Step 4, with `{phase}` = "testing" instead of "implementation". The Step 8 prose is otherwise identical between the two SKILLs (single canonical template lives in `security-review.md`; SKILLs reference it).
- [ ] Renumber: existing **Step 8** → **Step 9**; existing **Step 9 (Next Steps)** → **Step 10 (Next Steps)**.
- [ ] Update `## Success Criteria` to add the same checkbox (s/f-implementation-exec/g-testing-exec/).

### Step 6: Wire CHANGELOG.md
- [ ] Add Task 123 entry above Task 122 with `**Status**`, `**Duration**`, `**Impact**`, `### Changes` (4 file changes), `### Notable` (callout: doc-only — no script-hash refresh needed; design pivot from "Step 7a" to sequential renumbering after plan review; three-tier classifier added after design review).

### Step 7: Validation (during exec — pre-test sanity)
- [ ] `.cwf/scripts/cwf-manage validate` exits 0 (script-hashes.json untouched; no script edits — verified by plan review that `.claude/skills/` and `.cwf/docs/` are not in the hash manifest)
- [ ] All "3 → 4" prose in plan-review.md has been updated. Strict check: `grep -nE "(^|[^0-9])3 (Subagents|subagents|parallel|Agent calls|fail)" .cwf/docs/skills/plan-review.md` returns zero matches. Backstop: `grep -n " 3 " .cwf/docs/skills/plan-review.md` returns zero matches (no naked "3" left).
- [ ] Both exec SKILLs have `- Agent` in `allowed-tools`: `grep -A6 "^allowed-tools:" .claude/skills/cwf-implementation-exec/SKILL.md .claude/skills/cwf-testing-exec/SKILL.md | grep -c "Agent"` returns `2`.
- [ ] Renumbering consistent in both exec SKILLs: `grep -nE "^\*\*Step [0-9]+" .claude/skills/cwf-implementation-exec/SKILL.md .claude/skills/cwf-testing-exec/SKILL.md` shows Step 5, 6, 7, 8 (Security Review), 9 (Checkpoint commit), 10 (Next Steps).
- [ ] Pathspec is a single source of truth: extract the `git diff … -- <pathspec>` line from `.cwf/docs/skills/security-review.md` § "Pathspec coverage" via Read; confirm both exec SKILLs reference the doc rather than inlining the pathspec literally. The pathspec string appears in *one* file (security-review.md), not three.
- [ ] `security-review.md` § "Scope" cross-references `.cwf/docs/conventions/subagent-tool-selection.md`.

## Code Changes

This is a docs-and-skills task; no executable code changes. Sketch of the structural additions:

### `.cwf/docs/skills/plan-review.md` — table extension

Before:
```
|              | Improvements | Misalignment | Robustness |
|--------------|-------------|--------------|------------|
| requirements | …           | …            | …          |
| design       | …           | …            | …          |
| implementation | …         | …            | …          |
```

After (4th column added; existing columns verbatim):
```
|              | Improvements | Misalignment | Robustness | Security |
|--------------|-------------|--------------|------------|----------|
| requirements | …           | …            | …          | <see security-review.md> |
| design       | …           | …            | …          | <see security-review.md> |
| implementation | …         | …            | …          | <see security-review.md> |
```

### Exec SKILL — Step 8 insertion

Before (current Step 7 / Step 8):
```
**Step 7**: Execute test cases systematically. …

**Step 8**: Checkpoint commit. See `.cwf/docs/skills/checkpoint-commit.md`. …
```

After (new Step 8 / renumbered Step 9):
```
**Step 7**: Execute test cases systematically. …

**Step 8 (Security Review)**:
- Read `.cwf/docs/skills/security-review.md` § "Exec-phase prompt template" and § "Pathspec coverage".
- … (full block per c-design-plan.md §"Exec SKILL changes") …

**Step 9**: Checkpoint commit. See `.cwf/docs/skills/checkpoint-commit.md`. …
```

## Test Coverage
**See e-testing-plan.md for complete test plan.** Includes the AC8 dogfood case: run the new security subagent against this very task's f-implementation-exec.md changeset.

**AC8 outcome handling** (deferred from c-design via plan review): if the dogfood subagent returns `findings:` on this task's own changeset, the testing-exec skill records the verbatim findings in g-testing-exec.md and prompts the user to choose between (a) returning to f-implementation-exec to address them and re-run, or (b) accepting the findings with a documented rationale. The testing plan owns the explicit decision point; this plan just notes the requirement so it is not lost.

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results.**

## Scope Completion
This task is complete only when:
1. `.cwf/docs/skills/security-review.md` exists with the full structure per c-design.
2. `plan-review.md` has 4 subagents (procedure header + table column).
3. Both exec SKILLs have new Step 8 + renumbered 9/10 + Agent in allowed-tools.
4. `cwf-manage validate` clean.
5. AC8 dogfood subagent run during g-testing-exec, output recorded.

If any threat category in FR4(a–e) cannot be illustrated with a real CWF file:line, the doc uses an illustrative example (labelled `# illustrative`) — this is not a deferral, just a recognition that not every category has a known live anti-pattern.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 123
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 7 implementation steps executed in order with the recorded validation greps. Two minor sharpenings during exec: (i) the strict 3→4 grep needed rewording of "If 1-3 subagents fail" → "If some subagents fail (but not all)" to keep the test's zero-match assertion meaningful; (ii) TC-10's grep target sharpened from the diff-prefix to the verbose pathspec list.

## Lessons Learned
Validation greps in implementation plans should specify the *most distinctive substring* of the asserted-unique string, not a leading prefix that descriptive prose would also legitimately match.
