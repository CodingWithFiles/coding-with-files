# Add Tool Selection and Composition Guidance to Subagent Instructions - Testing Plan
**Task**: 118 (chore)

## Task Reference
- **Task ID**: internal-118
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/118-add-tool-selection-and-composition-guidance-to-su
- **Template Version**: 2.1

## Goal
Validate that **both** surfaces — the new convention doc at `.cwf/docs/conventions/subagent-tool-selection.md` and the updated inline rubric in `.cwf/docs/skills/plan-review.md` — are well-formed, internally consistent, and pass CWF integrity checks. The inline block must contain the principle verbatim and the 3 highest-value anti-patterns; the convention doc must contain the full 5-tier hierarchy and full anti-pattern list. This is a docs-only chore — verification is manual + scripted via `cwf-manage validate` and targeted greps.

## Test Strategy
### Test Levels
- **Static checks** (file existence, content presence, integrity): `cwf-manage validate`, `grep`, `Read`
- **Render check** (manual): substitute the `plan-review.md` template parameters and inspect the rendered prompt
- **No unit, integration, or end-to-end test infrastructure required** — there is no executable code to test

### Test Coverage Targets
- **Critical paths**: 100% — both files must exist with expected content sections
- **Anti-pattern coverage**: every anti-pattern named in the plan (Step 2 of d-implementation-plan.md) must appear in the convention doc
- **Cross-reference integrity**: the link from `plan-review.md` to the convention doc must point at an existing file
- **No regressions**: `cwf-manage validate` must remain `OK`; existing behaviour of the plan-review skill (parameterisation, numbered steps) must be unchanged

## Test Cases
### Functional Test Cases

- **TC-1: Convention doc exists**
  - **Given**: Implementation complete on branch `chore/118-…`
  - **When**: Run `ls .cwf/docs/conventions/subagent-tool-selection.md`
  - **Then**: File exists; readable; ≤30 lines per the plan's size budget

- **TC-2: Convention doc contains the full hierarchy**
  - **Given**: Convention doc created
  - **When**: Read the file end-to-end
  - **Then**: All 5 tiers present in order (built-in → skills → `rg`/`grep` Bash → `sed`/`awk`/`cat`/`head`/`tail` Bash → `find -exec`/pipelines last resort)

- **TC-3: Core principle stated explicitly**
  - **Given**: Convention doc created
  - **When**: `grep -n "do not use program composition with the Bash tool for simple tasks" .cwf/docs/conventions/subagent-tool-selection.md`
  - **Then**: Returns exactly one match (the principle is stated verbatim, not just paraphrased)

- **TC-4: Anti-patterns enumerated**
  - **Given**: Convention doc created
  - **When**: Grep for each named anti-pattern: `sed -n 'X,Yp'`, `cat`/`grep` pipe, `find -name`, `find -exec`, `for f in $(grep -l`
  - **Then**: All five anti-patterns named with their built-in equivalents

- **TC-5: plan-review.md inline rubric present**
  - **Given**: Implementation complete
  - **When**: Read `.cwf/docs/skills/plan-review.md` lines 13–35 (or wherever the prompt block now ends)
  - **Then**: All of the following are present *inline in the prompt block*:
    - Tightened restriction: "You may only use Read, Grep, and Glob (no Bash, no edits)."
    - Principle (verbatim): "Do not use program composition with the Bash tool for simple tasks; use the built-in tools instead."
    - At least these 3 anti-patterns with arrows to built-ins: `sed -n 'X,Yp'` → Read offset/limit; `cat … | grep` → Grep; `find … -exec cat` → batched Read calls
    - Reference line containing `.cwf/docs/conventions/subagent-tool-selection.md`
    - Parameterisation (`{plan_file_path}`, `{plan_type}`, `{focus_area}`, `{criteria}`) and numbered review steps unchanged

- **TC-6: Old wording fully replaced (no stale duplicates)**
  - **Given**: Implementation complete
  - **When**: `grep -rn "may only use Read, Grep, and Glob tools" .claude/ .cwf/` (excluding `implementation-guide/`)
  - **Then**: Zero matches (the only updated copy is `plan-review.md`)

- **TC-7: Cross-reference resolves**
  - **Given**: Implementation complete
  - **When**: Take the path string from the prompt's reference line — `.cwf/docs/conventions/subagent-tool-selection.md` — and resolve it relative to the repo root
  - **Then**: Path resolves to the file created in TC-1

- **TC-8: Render check on a concrete prompt**
  - **Given**: Updated `plan-review.md`
  - **When**: Manually substitute `{plan_type}=implementation`, `{focus_area}=Improvements`, `{plan_file_path}=…/118-chore-…/d-implementation-plan.md`, `{criteria}` from the implementation × Improvements lookup-table cell
  - **Then**: Rendered prompt reads coherently top-to-bottom; the inline anti-patterns are scannable; the principle is stated as imperative guidance, not abstract documentation; reference to the convention doc reads as an "for full details" pointer, not a substitute for the inline block

- **TC-9: Inline rubric is a strict subset of the convention doc**
  - **Given**: Both files written
  - **When**: Cross-check each anti-pattern in `plan-review.md`'s inline block against the convention doc
  - **Then**: Every inline anti-pattern appears in the convention doc with the same built-in equivalent (no contradictions; the inline block is a subset, not a divergent fork)

- **TC-10: CWF integrity check still passes**
  - **Given**: Implementation complete and committed
  - **When**: `cwf-manage validate`
  - **Then**: Reports `OK` (no permission, hash, or structural violations)

### Non-Functional Test Cases

- **NFR-1 Maintainability — convention doc is the canonical reference**: The convention doc holds the full 5-tier hierarchy and full anti-pattern list; the inline block is a brief subset that points back to the doc. Test: convention doc has all 5 tiers and ≥6 anti-patterns; inline block has 3 anti-patterns and a reference to the doc; no third place duplicates the rubric.

- **NFR-2 Reliability — no broken cross-references**: For each cross-reference cited in the convention doc (`workflow-preamble.md#step-4`, etc.) and from the inline block (`.cwf/docs/conventions/subagent-tool-selection.md`), verify the target file and section exist. Test: `Read` each referenced file, confirm the section anchor is present.

- **NFR-3 Usability — terse prompt growth**: Diff `plan-review.md` prompt block before/after; growth must be ≤8 lines (per the d-plan render check budget). Test: `git diff main -- .cwf/docs/skills/plan-review.md`, count added lines inside the prompt block.

- **Performance / Security**: N/A — documentation-only change, no runtime, no auth surface.

## Test Environment

### Setup Requirements
- Working repo on branch `chore/118-add-tool-selection-and-composition-guidance-to-su`
- Implementation phase complete (f-implementation-exec.md status = Finished)
- No external services, no test fixtures

### Automation
- Static checks (TC-1, TC-3, TC-4, TC-6, TC-7, TC-9, TC-10, NFR-1, NFR-2, NFR-3) are scripted via `Read` / `Grep` / `Glob` tools and `cwf-manage validate`
- Render check (TC-8) is manual: read the rendered prompt and judge coherence

## Validation Criteria
- [ ] TC-1 through TC-10 all pass
- [ ] NFR-1, NFR-2, NFR-3 all pass
- [ ] `cwf-manage validate` returns `OK`
- [ ] No new failures introduced anywhere in the repo (no regression in any other CWF skill or script)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 118
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
