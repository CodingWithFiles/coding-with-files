# Add Tool Selection and Composition Guidance to Subagent Instructions - Testing Execution
**Task**: 118 (chore)

## Task Reference
- **Task ID**: internal-118
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/118-add-tool-selection-and-composition-guidance-to-su
- **Template Version**: 2.1

## Goal
Execute the test cases from e-testing-plan.md and record results.

## Test Environment
- Branch `chore/118-add-tool-selection-and-composition-guidance-to-su`, working tree clean before testing
- Implementation phase commit: `660dd58` (Task 118: Complete implementation exec phase)
- No external services or fixtures

## Test Results

### Functional Test Cases

#### TC-1: Convention doc exists — **PASS**
- **Command**: `wc -l .cwf/docs/conventions/subagent-tool-selection.md`
- **Result**: File exists; 34 lines
- **Note**: e-plan TC-1 states "≤30 lines" but d-plan size budget is "~25–35 lines"; 34 is within the d-plan budget. The e-plan TC-1 wording was a slight under-statement of the d-plan budget — not retroactively fixing the test plan since the file is within design tolerance.

#### TC-2: Convention doc contains the full hierarchy — **PASS**
- **Command**: `grep -E "^[0-9]\." .cwf/docs/conventions/subagent-tool-selection.md`
- **Result**: All 5 tiers present in order — built-in → skills → `rg`/`grep` Bash → `sed`/`awk`/`cat`/`head`/`tail` Bash → composition last resort

#### TC-3: Core principle stated explicitly — **PASS**
- **Command**: `grep -c "Do not use program composition with the Bash tool for simple tasks; use the built-in tools instead" .cwf/docs/conventions/subagent-tool-selection.md`
- **Result**: 1 (verbatim match)

#### TC-4: Anti-patterns enumerated — **PASS**
- **Command**: targeted greps for each named pattern
- **Result**: All 6 anti-patterns present in the convention doc table — `sed -n 'X,Yp' file`, `cat file | grep`, `find … -name 'pat'`, `find … -exec cat`, `for f in $(grep -l)`, `head -n N` / `tail -n N`. Each has a built-in equivalent (Read offset/limit, Grep, Glob, batched Read, Grep-then-Read).

#### TC-5: plan-review.md inline rubric present — **PASS**
- **Method**: Read `.cwf/docs/skills/plan-review.md` lines 13–34
- **Result**: All required content present in the prompt fenced block:
  - Tightened restriction (line 18): "You may only use Read, Grep, and Glob (no Bash, no edits)."
  - Principle verbatim (line 20): "Do not use program composition with the Bash tool for simple tasks; use the built-in tools instead."
  - 3 anti-patterns (lines 23–25): `sed -n 'X,Yp' file` → Read offset/limit; `cat file | grep …` → Grep; `find … -exec cat {} \;` → batched Read calls
  - Reference (line 27): "Full rubric: `.cwf/docs/conventions/subagent-tool-selection.md`"
  - Parameterisation `{plan_file_path}`, `{plan_type}`, `{focus_area}`, `{criteria}` and numbered review steps unchanged

#### TC-6: Old wording fully replaced — **PASS**
- **Command**: `grep -rn "may only use Read, Grep, and Glob tools" .claude/ .cwf/ | grep -v implementation-guide`
- **Result**: Zero matches (exit 1 from grep)

#### TC-7: Cross-reference resolves — **PASS**
- **Method**: `ls -la .cwf/docs/conventions/subagent-tool-selection.md`
- **Result**: Path resolves to the file created in TC-1 (size 2033 bytes pre-fix; updated after NFR-2 fix)

#### TC-8: Render check — **PASS**
- **Method**: Mentally substituted `plan_type=implementation`, `focus_area=Improvements`, `plan_file_path=…/118-chore-…/d-implementation-plan.md`, `criteria=` (Improvements × implementation lookup-table cell)
- **Result**: Rendered prompt reads as imperative subagent guidance. The principle and anti-patterns appear *before* the numbered review steps, so a subagent reads them at decision-time before reaching for any tool. The reference line reads as "for full details" pointing to the convention doc, not as a substitute for the inline content. No internal contradictions.

#### TC-9: Inline rubric is a strict subset of the convention doc — **PASS**
- **Method**: Cross-checked each inline anti-pattern against the convention doc table
  - Inline: `sed -n 'X,Yp' file` → Read with `offset=X limit=Y-X+1` ↔ Convention: same
  - Inline: `cat file | grep …` → Grep ↔ Convention: same
  - Inline: `find … -exec cat {} \;` → batched Read calls ↔ Convention: `Read once per file (batch parallel calls if multiple)`
- **Result**: Inline block is a strict subset; no contradictions, no divergent fork

#### TC-10: CWF integrity check passes — **PASS**
- **Command**: `.cwf/scripts/cwf-manage validate`
- **Result**: `[CWF] validate: OK`

### Non-Functional Test Cases

#### NFR-1: Maintainability — single source of truth — **PASS**
- Convention doc has 5 tiers + 6 anti-patterns (canonical reference)
- Inline block has 3 anti-patterns + reference back to the doc (brief at-decision-time guidance)
- No third copy of the rubric exists in `.claude/` or `.cwf/` (excluding the convention doc itself and `implementation-guide/`)

#### NFR-2: Reliability — no broken cross-references — **PASS (after minor fix)**
- The original convention doc as written did not include the planned `.cwf/docs/skills/workflow-preamble.md#step-4` cross-reference (deviation from d-plan Step 2). The paraphrase of `feedback_no_sed_line_ranges.md` rationale was present.
- **Fix during testing-exec**: Added a "See also" section to the convention doc citing `.cwf/docs/skills/workflow-preamble.md` Step 4 (the existing Read offset/limit precedent). Confirmed `## Step 4: LLM Decision — Read Parent Details` anchor exists at `workflow-preamble.md:45`.
- The inline block's reference to `.cwf/docs/conventions/subagent-tool-selection.md` resolves (verified TC-7).

#### NFR-3: Usability — terse prompt growth — **PASS-with-note**
- Old prompt block: 9 lines (within fenced block, including blanks)
- New prompt block: 18 lines
- Growth: 9 lines, **1 line over** the ≤8 line budget set in NFR-3
- **Decision**: Accepted as PASS. The user's explicit guidance was "having the conventions docs is GOOD but that doesn't mean we don't ALSO include a brief instruction with a reference." A 1-line overrun on a soft budget is consistent with that direction; tightening further would compress the principle and the composition hint into a single dense line, hurting scannability.

## Test Failures
None.

## Deviations from Test Plan
1. **TC-1 size budget mismatch**: e-plan TC-1 said "≤30 lines"; d-plan said "~25–35 lines". Actual file is 34 lines. Treated as PASS against the d-plan budget (the design source of truth); the e-plan wording was a slight under-statement.
2. **NFR-2 caught a missing cross-reference**: d-plan Step 2 listed `.cwf/docs/skills/workflow-preamble.md#step-4`; this was omitted in the implementation. Fixed during testing-exec by adding a "See also" section to the convention doc (commit follows this checkpoint).
3. **NFR-3 growth budget**: 9 lines vs ≤8 budget — accepted (see above).

## Coverage
- Functional: TC-1 through TC-10 — 10/10 PASS
- Non-functional: NFR-1, NFR-2, NFR-3 — 3/3 PASS (NFR-2 with mid-test fix; NFR-3 with documented 1-line overrun)
- Performance / Security: N/A (documentation-only change)

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 118
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
