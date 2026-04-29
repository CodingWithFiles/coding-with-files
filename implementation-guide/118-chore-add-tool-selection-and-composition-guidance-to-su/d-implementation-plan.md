# Add Tool Selection and Composition Guidance to Subagent Instructions - Implementation Plan
**Task**: 118 (chore)

## Task Reference
- **Task ID**: internal-118
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/118-add-tool-selection-and-composition-guidance-to-su
- **Template Version**: 2.1

## Goal
Both surfaces, deliberately:
1. Create `.cwf/docs/conventions/subagent-tool-selection.md` as the canonical reference: full 5-tier preference order, the no-composition-for-simple-tasks principle, complete anti-pattern list with built-in equivalents.
2. Inline a brief tool-selection block in the CWF subagent prompt template at `.cwf/docs/skills/plan-review.md` — terse enough to read at decision time, with a reference to the convention doc for the full version.

The brief inline block is essential because subagents demonstrably reach for `sed -n 'X,Yp'` and `find … -exec` even when their prompt restricts them to Read/Grep/Glob; they need the principle and the top anti-patterns visible in the prompt itself, not buried behind a link. The convention doc is essential because it's the canonical, reusable home for the rubric — referenceable from any future subagent prompt and from CLAUDE.md or other docs that want to point at it.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cwf/docs/conventions/subagent-tool-selection.md` (**new**) — canonical reference, ~25–35 lines. Sits alongside `commit-messages.md` and `perl-git-paths.md` in the same directory. Contains the full 5-tier preference order, the no-composition principle stated verbatim, and the full anti-pattern list with built-in equivalents.
- `.cwf/docs/skills/plan-review.md` — replace the single restriction line with a brief inline rubric (≤8 lines): tightened restriction + the no-composition principle (verbatim) + 3 most important anti-patterns + reference to the convention doc for the full list.

### Supporting Changes
None.

### Out of Scope (deliberate)
- Frozen retrospective copies of the old wording in `implementation-guide/108-*` etc. — historical task docs, not active prompt templates. Do **not** edit.
- Loosening the Read/Grep/Glob restriction to allow Bash inside plan-review subagents — separate decision; this task only adds guidance.

**Inventory result** (from `grep -rn "subagent_type\|Agent(" .claude/skills/ .cwf/` excluding `implementation-guide/`):
- `plan-review.md:11` is the **sole** active subagent invocation template in the CWF system. Updating its prompt covers every current invocation site; the new convention doc covers any future site.

## Implementation Steps
### Step 1: Confirm inventory
- [ ] Re-run `grep -rn 'subagent_type\|Agent('` across `.claude/` and `.cwf/` (excluding `implementation-guide/`) and confirm `plan-review.md:11` is the only active subagent-invocation hit
- [ ] Confirm `.cwf/docs/conventions/` exists and currently holds `commit-messages.md` + `perl-git-paths.md`

### Step 2: Create the convention doc
- [ ] Create `.cwf/docs/conventions/subagent-tool-selection.md` with:
  - Title, one-line scope ("guidance for subagents launched via the Agent tool — applies within whatever tool grant the subagent has")
  - **Preference order** (top → bottom):
    1. Built-in tools: Read (use `offset`/`limit` for line ranges), Grep, Glob
    2. Skills: when a slash-command skill encapsulates the operation and is available to the subagent type
    3. Bash with `rg` / `grep`: only when Grep can't express the search (e.g. multiline patterns)
    4. Bash with `sed` / `awk` / `cat` / `head` / `tail`: only for transformations no built-in covers — never as substitutes for Read/Grep/Glob
    5. **Last resort** — Bash with program composition (`find … -exec …`, multi-stage pipelines, `xargs`): only when no combination of higher-tier options produces the result
  - **Core principle** (state verbatim): "Do not use program composition with the Bash tool for simple tasks; use the built-in tools instead." Followed by a sentence of justification (built-in tools have richer output, harness tracking, fewer off-by-one errors).
  - **Anti-patterns** (with built-in equivalents) — full list:
    - `sed -n 'X,Yp' file` → `Read file offset=X limit=Y-X+1`
    - `cat file | grep …` → `Grep`
    - `find … -name 'pat'` → `Glob`
    - `find … -exec cat {} \;` for a handful of files → call `Read` once per file (or batch parallel Read calls)
    - `for f in $(grep -l …); do …; done` → `Grep` first, then `Read` the matching paths
    - `head -n N file` / `tail -n N file` → Read with `offset`/`limit`
  - **Composition note**: when composition is genuinely required, chain by passing locations between tools (Glob → Read; Grep → Read with offset). Don't reproduce search-then-extract inside a single Bash pipeline.

### Step 3: Update plan-review.md
- [ ] Edit `.cwf/docs/skills/plan-review.md`. Inside the prompt template fenced block (currently lines 15–25):
  - Replace the line "You may only use Read, Grep, and Glob tools. Do not modify any files." with a brief inline block (≤8 lines) containing:
    - Tightened restriction: "You may only use Read, Grep, and Glob (no Bash, no edits)."
    - Principle (verbatim): "Do not use program composition with the Bash tool for simple tasks; use the built-in tools instead."
    - Composition hint: "Use Read with `offset`/`limit` for line ranges; chain Glob → Read or Grep → Read instead of pipelines."
    - 3 highest-value anti-patterns: `sed -n 'X,Yp' file` → Read offset/limit; `cat … | grep …` → Grep; `find … -exec cat {} \;` → batched Read calls
    - Reference: "Full rubric: `.cwf/docs/conventions/subagent-tool-selection.md`"
  - Keep parameterisation (`{plan_file_path}`, `{plan_type}`, `{focus_area}`, `{criteria}`) and numbered review steps unchanged

### Step 4: Render check
- [ ] Substitute placeholders for one concrete combination — `plan_type=implementation`, `focus_area=Improvements`, `plan_file_path=…/118-chore-…/d-implementation-plan.md`, `criteria=` (Improvements × implementation cell from the lookup table) — and read the rendered prompt top to bottom
- [ ] Confirm:
  - The inline block reads as imperative guidance the subagent will follow before reaching for Bash
  - The reference path to the convention doc is correct (relative to repo root)
  - No contradiction between the inline rubric and the convention doc (the inline block is a strict subset)
  - Prompt grew by ~6–8 lines

### Step 5: Validation
- [ ] Run `cwf-manage validate` (checkpoint commit script does this automatically)
- [ ] Run `grep -rn "may only use Read, Grep, and Glob tools" .claude/ .cwf/` (excluding `implementation-guide/`) — confirm zero matches remain after the edit
- [ ] Run `Read .cwf/docs/conventions/subagent-tool-selection.md` — confirm the file is well-formed and present

## Code Changes
### Before (`.cwf/docs/skills/plan-review.md` lines 15–25)
```markdown
Review the {plan_type} plan at {plan_file_path} for {focus_area}.

You may only use Read, Grep, and Glob tools. Do not modify any files.

1. Read the plan file.
2. Grep the codebase for existing code, patterns, or utilities relevant to what the plan proposes.
3. Assess the plan against these criteria: {criteria}

For each finding, state: what is wrong, where it is in the plan, and what to do about it. Be concise — report only actionable findings. If the plan is sound for your focus area, say so briefly.
```

### After (illustrative — final wording decided during exec)
```markdown
Review the {plan_type} plan at {plan_file_path} for {focus_area}.

You may only use Read, Grep, and Glob (no Bash, no edits).

Do not use program composition with the Bash tool for simple tasks; use the built-in tools instead. Read with `offset`/`limit` for line ranges; chain Glob → Read or Grep → Read instead of pipelines.

Common anti-patterns (use the built-in):
- `sed -n 'X,Yp' file` → Read with `offset=X limit=Y-X+1`
- `cat file | grep …` → Grep
- `find … -exec cat {} \;` for a few files → batched Read calls

Full rubric: `.cwf/docs/conventions/subagent-tool-selection.md`.

1. Read the plan file.
2. Grep the codebase for existing code, patterns, or utilities relevant to what the plan proposes.
3. Assess the plan against these criteria: {criteria}

For each finding, state: what is wrong, where it is in the plan, and what to do about it. Be concise — report only actionable findings. If the plan is sound for your focus area, say so briefly.
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Single-file change with no deferred work expected.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 118
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
