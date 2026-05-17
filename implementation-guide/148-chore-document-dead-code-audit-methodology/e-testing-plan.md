# Document Dead Code Audit Methodology - Testing Plan
**Task**: 148 (chore)

## Task Reference
- **Task ID**: internal-148
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/148-document-dead-code-audit-methodology
- **Template Version**: 2.1

## Goal
Verify that (a) the canonical methodology produces correct verdicts against historical fixtures, (b) the two integration points correctly reference the canonical doc, and (c) the produced docs are internally link-clean. Manual verification — no automated test suite — because the deliverable is a methodology and four small file edits, not code.

## Test Strategy
### Test Levels
- **Methodology self-test (functional)**: Apply the canonical doc's caller-category checklist to known historical cases. The methodology itself is the system under test.
- **Integration check**: Verify the two reference points (misalignment agent, i-maintenance template) point at the canonical doc and that the target exists.
- **Structural / regression**: Markdown link integrity, agent line budget, `cwf-manage validate` clean.

### Test Coverage Targets
Not a code-coverage task. The substantive coverage target is:
- **Methodology coverage**: both directions tested (false-positive caught + positive control flagged).
- **Reference integrity**: both integration points greppable for the canonical-doc path + target file exists.
- **Document integrity**: 100% of in-doc anchors resolve to existing headings; 100% of cross-file `.md` references resolve to existing files.

## Test Cases

### Functional Test Cases — Methodology Self-Test
*(Records into `g-testing-exec.md`. d-plan §Decision D6 governs pass conditions and the 3-strikes refinement bound.)*

- **TC-1**: Methodology catches `workflow_file_mappings()` callers (false-positive direction)
  - **Given**: The function definition as it stood prior to Task 51's removal commit (fixture recovered per d-plan Step 1 — first try `implementation-guide/51-*/j-retrospective.md`; fall back to `git log main --oneline -S 'workflow_file_mappings' --diff-filter=D` and `git show <commit>^:path`). The full repo tree at that commit, available via `git show <commit>^:` checkouts.
  - **When**: Walk the canonical doc's 6 caller-category checklist against the function.
  - **Then**: At least one category surfaces a real caller. The expected category is #3 (same-file private callers), since that was the class Task 51 missed. Record which category caught it and the call-site line number.

- **TC-2**: Methodology catches `format_error()` callers (false-positive direction)
  - **Given**: Function definition at the pre-removal commit, as for TC-1.
  - **When**: Walk the 6-category checklist.
  - **Then**: At least one category surfaces a real caller. The expected category is #2 (static cross-module — script-to-library), per the BACKLOG entry's diagnosis. Record the category and call site.

- **TC-3**: Methodology correctly flags a positive-control function as dead
  - **Given**: A removed function whose name string still appears elsewhere in the tree (POD, comments, similar-name symbol). Function chosen at exec time per d-plan D6 selection rule. Record the function name, the appearance site that could trick a naïve grep, and the removal-commit SHA.
  - **When**: Walk the 6-category checklist treating the function as a removal candidate (i.e. ask the doc to predict the right verdict).
  - **Then**: All 6 categories return "no caller"; the appearance site is correctly classified as appearance-not-caller (e.g. by category #6 if it's a POD mention, by "not a category at all" if it's a comment). Verdict: dead, matching the historical outcome.

### Functional Test Cases — Integration Points

- **TC-4**: Misalignment-agent references the canonical doc
  - **Given**: `.claude/agents/cwf-plan-reviewer-misalignment.md` after Step 4 edit.
  - **When**: `grep -F '.cwf/docs/dead-code-audit.md' .claude/agents/cwf-plan-reviewer-misalignment.md`
  - **Then**: ≥1 line returned AND `.cwf/docs/dead-code-audit.md` exists AND the reference's containing Procedure step is phrased declaratively (criteria-shaped, not imperative — Security S1).

- **TC-5**: i-maintenance template references the canonical doc
  - **Given**: `.cwf/templates/pool/i-maintenance.md.template` after Step 5 edit.
  - **When**: `grep -F '.cwf/docs/dead-code-audit.md' .cwf/templates/pool/i-maintenance.md.template`
  - **Then**: ≥1 line returned AND the matched line is the last bullet of `### Preventive Maintenance` AND `.cwf/docs/dead-code-audit.md` exists.

### Functional Test Cases — Document Integrity

- **TC-6**: All in-doc anchor links resolve
  - **Given**: Both new docs written.
  - **When**: `grep -nE '\]\(#' .cwf/docs/dead-code-audit.md docs/dead-code-audit-perl.md` — for each anchor target, look for a matching `## ` or `### ` heading (slugified comparison) in the *same* file.
  - **Then**: Every anchor resolves. Zero broken `(#...)` links.

- **TC-7**: All cross-file `.md` references resolve
  - **Given**: Both new docs + edited agent + edited template.
  - **When**: For each `.md` path referenced from any of the four files, check the file exists via Read or `ls`.
  - **Then**: All referenced paths exist.

### Non-Functional Test Cases

- **TC-8**: Agent line budget
  - **Given**: `.claude/agents/cwf-plan-reviewer-misalignment.md` after Step 4 edit.
  - **When**: `wc -l .claude/agents/cwf-plan-reviewer-misalignment.md`
  - **Then**: Output < 55 (a-task-plan SC3 ceiling, A3 reconciliation).

- **TC-9**: Recipes doc compactness (D1 anti-bloat guard)
  - **Given**: `docs/dead-code-audit-perl.md` after Step 3.
  - **When**: `wc -l docs/dead-code-audit-perl.md`
  - **Then**: Output ≤ 40. If exceeded, recipes doc has started mirroring the canonical's structure — refactor to recipe-only form before passing.

- **TC-10**: `cwf-manage validate` clean
  - **Given**: All edits committed (or staged for the f-exec checkpoint).
  - **When**: `.cwf/scripts/cwf-manage validate`
  - **Then**: Exits 0. Claim: no regression on tracked files. The four new/edited doc paths are not in `script-hashes.json` so are not directly validated.

## Test Environment

### Setup Requirements
- Repo at chore/148 branch HEAD after f-exec phase commits.
- `.git/` history reachable back to Task 51 era (default for any clone of this repo).
- No external services, no test database, no mocks. All checks run against the working tree + `git show` against past commits.

### Automation
None. All tests run manually via shell commands documented in each TC. Results recorded by hand into `g-testing-exec.md`.

**Rationale for no automation**: The substantive test (TC-1 through TC-3) is "an auditor walks the checklist." That's the *thing being tested* and the *test execution* — there's no separation worth automating. The structural tests (TC-4 through TC-10) are one-line shell commands; wrapping them in test scaffolding is more code than the docs they test.

## Validation Criteria
- [ ] TC-1 and TC-2 pass (false-positive direction; methodology catches what Task 51 missed).
- [ ] TC-3 passes (positive-control direction; methodology distinguishes appearance from caller-ness).
- [ ] If any of TC-1–TC-3 require refinement to the methodology, the refinement is bounded at 3 attempts per direction (d-plan D6); after 3 failures, stop and escalate.
- [ ] TC-4 and TC-5 pass (integration points wired and target exists).
- [ ] TC-6 and TC-7 pass (link integrity).
- [ ] TC-8, TC-9, TC-10 pass (line budgets, validate clean).

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 148
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
