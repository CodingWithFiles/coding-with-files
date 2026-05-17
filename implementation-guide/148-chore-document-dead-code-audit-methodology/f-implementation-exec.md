# Document Dead Code Audit Methodology - Implementation Execution
**Task**: 148 (chore)

## Task Reference
- **Task ID**: internal-148
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/148-document-dead-code-audit-methodology
- **Template Version**: 2.1

## Goal
Execute d-implementation-plan.md steps 1-5 (step 6 self-test runs in g-testing-exec; step 7 validation runs here).

## Actual Results

### Step 1: Recover Task 51 false-positive context
- **Fixture source**: `implementation-guide/51-bugfix-dead-code-removal/j-retrospective.md` (lines 67-76 "What Could Be Improved" + lines 100-105 "Process Learnings"). Retrospective had the detail; no git archaeology needed.
- **Fixture A — `workflow_file_mappings()`**: Active caller was `context-inheritance-v2.0` (a script consuming the library). Maps to **Category #2** (static cross-module — script-to-library), NOT Category #3 as TC-1 in e-plan stated.
- **Fixture B — `format_error()`**: Active caller was internal to `Common.pm` (same-file). Maps to **Category #3** (same-file private), NOT Category #2 as TC-2 in e-plan stated.
- **Plan deviation noted**: e-plan TC-1/TC-2 had the expected categories swapped relative to the retrospective evidence. Recording here; TC-1/TC-2 still pass on substance (each surfaces ≥1 real caller in *some* category) — only the predicted category is wrong. The g-testing-exec record will use the correct categories from this fixture.
- **Positive control**: `_format_uncorrelated()`. Removed in commit `6ad9ce3` (Task 51, 2026-02-10). Appearance sites that could trick a naïve grep:
  - `CHANGELOG.md:2320` (removal entry)
  - `CHANGELOG.md:2955` (deprecation entry)
  - `implementation-guide/32-feature-task-tracking-using-inference-scoring/f-implementation-exec.md:89`
  - `implementation-guide/32-feature-task-tracking-using-inference-scoring/c-design-plan.md:192,202` (commented-out)
  - `implementation-guide/37-bugfix-fix-inconclusive-inference-output-format/d-implementation-plan.md:19,30,49,50,149,153,175`
  - `implementation-guide/37-bugfix-fix-inconclusive-inference-output-format/c-design-plan.md:46,53`
  All appearances are historical-doc mentions (CHANGELOG entries, planning-doc snapshots), not callers. None are live invocations.

### Step 2: Write `.cwf/docs/dead-code-audit.md`
- **Status**: written. 168 lines.
- Sections delivered: Principle; When to audit (links shift-left agent + shift-right template); Caller categories (D3's 6, each with definition + why-it-matters + cross-language example + grep guidance); Plan-time heuristics (5 declarative criteria, all "Flag if …" phrasing per Security S1); Maintenance-time audit (4-step loop); Verdict template (5-column).
- Plan-time heuristics list ended up with 5 items, within the D4 "4-6 declarative criteria" budget.

### Step 3: Write `docs/dead-code-audit-perl.md`
- **Status**: written. 30 lines.
- Sections: deferral preamble (D1 wording verbatim); per-category greps; structured-report row matching the canonical verdict template.
- 30 lines is ≤ 40 (TC-9 ceiling) but above the "~20 lines" target in d-plan §Files to Modify. Concrete content (one-line-per-category greps + reflective + advertised + historical + verdict template) reads cleanly at 30; trimming to 20 would compress at the cost of legibility. Not a contract failure; recording the variance.
- "Symbol names operator-supplied" inline note included (Security S2).

### Step 4: Wire misalignment-reviewer reference
- **Status**: edited `.claude/agents/cwf-plan-reviewer-misalignment.md`. Inserted Procedure step `2a` between current `2` and `3`. Used declarative framing per Security S1 ("the heuristics are a deepening of the bullets below — same concern, sharper criteria").
- Post-edit guard: `grep -F '.cwf/docs/dead-code-audit.md' .claude/agents/cwf-plan-reviewer-misalignment.md` returns 1 match. Target file exists.
- Line count: 41 (was 37). Under SC3 ceiling of 55. A3 reconciliation respected.

### Step 5: Wire i-maintenance template reference
- **Status**: edited `.cwf/templates/pool/i-maintenance.md.template`. Appended one bullet at end of `### Preventive Maintenance` list.
- Post-edit guard: `grep -F '.cwf/docs/dead-code-audit.md' .cwf/templates/pool/i-maintenance.md.template` returns 1 match.

### Step 7: Validation (Step 6 self-test deferred to g-testing-exec per skill scope)
- **`cwf-manage validate`**: initial run fired on `.claude/agents/cwf-plan-reviewer-misalignment.md` — the agent file IS in `script-hashes.json` (entry `cwf-plan-reviewer-misalignment` at JSON line 9-13). d-plan §Supporting Changes was wrong to claim no hash coverage was needed. Updated sha256 from `a10a3bd8…` to `f60c26a2…` in-task per the rule clarified in the Very High BACKLOG entry committed during a-task-plan (commit `0c9a4e5`). Re-ran validate: `[CWF] validate: OK`.
- **Agent line budget**: 41 < 55. Pass.
- **Anchor links** in canonical doc: `#plan-time-heuristics`, `#maintenance-time-audit`, `#caller-categories` — all three resolve to `##` headings in the same file.
- **Cross-file `.md` references** in canonical: `docs/dead-code-audit-perl.md`, `.claude/agents/cwf-plan-reviewer-misalignment.md`, `.cwf/templates/pool/i-maintenance.md.template` — all exist.

## Deviations from Plan

1. **e-plan TC-1/TC-2 had categories swapped** vs. the Task 51 retrospective evidence. Recorded in Step 1 above; will use the correct mapping in g-testing-exec. Substantive pass condition (each surfaces ≥1 caller) is independent of which category does the catching, so TCs do not need to be rewritten.
2. **d-plan §Supporting Changes "None" was wrong** — the misalignment-agent file is hash-tracked. Hash refreshed in-task; no further follow-up needed.
3. **Recipes doc 30 lines, not ~20**. Within TC-9 ceiling (≤ 40). Variance recorded; no refactor.

## Blockers Encountered

None.

## Deferral Check
- [x] All planned steps 1-5 + step 7 validation executed (step 6 self-test runs in g-testing-exec per skill scope)
- [x] a-task-plan SC1-SC4 met here; SC5 (self-test) deferred to g-testing-exec
- [x] b-requirements / c-design-plan N/A for chore step set
- [x] All design guidance in d-implementation-plan.md followed except where deviations above are documented
- [x] No work deferred without rationale

## Security Review

**State**: no findings

no findings
The two diff hunks add documentation references only (a bullet pointing reviewers to a heuristics doc, and a maintenance-template bullet listing periodic dead-code audits). No code, no shell, no inputs, no permissions, no secrets — purely informational prose additions. No security surface introduced or altered.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 148
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
