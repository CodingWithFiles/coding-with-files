# Add security-review subagent to plan/exec skills - Testing Plan
**Task**: 123 (feature)

## Task Reference
- **Task ID**: internal-123
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/123-add-security-review-subagent-to-plan-exec-skills
- **Template Version**: 2.1

## Goal
Verify the new `.cwf/docs/skills/security-review.md`, the 4-row plan-review.md, and the new Step 8 in both exec SKILLs are correctly wired, internally consistent, and behave as designed — including the dogfood AC8 case.

## Test Strategy
This is a docs-and-skills task; tests are checks (manual greps, Reads, and one live subagent invocation), not automated unit tests. Pass/fail is binary with single-line evidence per case. The dogfood case (TC-AC8) is the only one that exercises the runtime behaviour end-to-end.

### Test Levels
- **Content tests** — the new doc covers the agreed structure with all FR4 categories
- **Wiring tests** — plan-review.md table grew correctly; exec SKILLs have new Step 8, renumbered subsequent steps, and `Agent` in allowed-tools
- **Integrity tests** — `cwf-manage validate` clean; pathspec lives in one place
- **Behavioural tests** — the security subagent actually runs (TC-AC8) and produces a classifiable verbatim result

### Coverage Targets
- 100% of FR1–FR6 acceptance criteria exercised
- 100% of files in d-implementation-plan §"Files to Modify" inspected
- 1 live subagent invocation (TC-AC8) — proves the wiring works end-to-end

## Test Cases

### Functional

- **TC-1: Canonical doc exists with required structure**
  - **Given**: Branch `feature/123-…`
  - **When**: Read `.cwf/docs/skills/security-review.md`
  - **Then**: Heading `# Security Review`; sections `## Scope`, `## Pathspec coverage`, `## Threat categories`, `## Plan-phase row`, `## Exec-phase prompt template` all present in that order

- **TC-2: All FR4(a–e) threat categories present with required structure**
  - **When**: Grep `## Threat categories` section for category headings
  - **Then**: Five sub-headings present, each with (i) one-line definition, (ii) anti-pattern example (file:line citation if real, `# illustrative` label otherwise), (iii) "do instead" pointer. AC4 satisfied per b-requirements-plan.md.

- **TC-3: Subagent-tool-selection cross-reference present**
  - **When**: Grep `security-review.md` for `subagent-tool-selection.md`
  - **Then**: At least one match in `## Scope`

- **TC-4: cwf-manage validate boundary explicitly carved out**
  - **When**: Grep `security-review.md` `## Scope` for `cwf-manage validate`
  - **Then**: One match describing the boundary; the doc explicitly notes it does not duplicate deterministic checks

- **TC-5: plan-review.md grew from 3 to 4 subagents (header)**
  - **When**: Grep `plan-review.md` for the procedure header
  - **Then**: `Launch 4 Subagents` present; `Launch 3 Subagents` absent

- **TC-6: plan-review.md prose audit — no stale "3" references**
  - **When**: Run the strict grep from d-implementation-plan §"Step 7": `grep -nE "(^|[^0-9])3 (Subagents|subagents|parallel|Agent calls|fail)"`
  - **Then**: Zero matches

- **TC-7: plan-review.md table has Security column for all 3 plan types**
  - **When**: Read the criteria-lookup table
  - **Then**: Header row contains `Security`; each of `requirements`, `design`, `implementation` rows has a Security cell that references `security-review.md`

- **TC-8: Both exec SKILLs have `Agent` in allowed-tools**
  - **When**: Read frontmatter of `cwf-implementation-exec/SKILL.md` and `cwf-testing-exec/SKILL.md`
  - **Then**: `- Agent` appears in `allowed-tools` for both

- **TC-9: Both exec SKILLs have Step 8 (Security Review) inserted, with sequential renumbering**
  - **When**: Grep `^\*\*Step [0-9]+` in both SKILLs
  - **Then**: Steps 5, 6, 7, 8 (Security Review), 9 (Checkpoint commit), 10 (Next Steps) — exact sequence in both files

- **TC-10: Pathspec is single source of truth**
  - **When**: Grep the literal `git diff $(git merge-base HEAD main)..HEAD --` pathspec across the repo
  - **Then**: Appears in exactly one file (`.cwf/docs/skills/security-review.md` § "Pathspec coverage"); both exec SKILLs reference the doc rather than inlining the pathspec

- **TC-11: Exec SKILL Step 8 implements the three-tier classifier**
  - **When**: Read Step 8 in both exec SKILLs
  - **Then**: Text describes (a) primary sentinel-line classification, (b) numbered-list fallback, (c) conservative-default error. Records `**State**: ...` line above verbatim block.

- **TC-12: Exec SKILL Step 8 handles edge cases (on-main, empty diff, >500 lines)**
  - **When**: Read Step 8 text
  - **Then**: Three pre-checks present — branch is main → `no findings: on main`; empty diff → `no findings: empty changeset`; >500 lines → `error: changeset exceeds 500-line review cap`

- **TC-13: BACKLOG.md "Add Security Verification to Testing Workflow" entry untouched**
  - **When**: Grep BACKLOG.md for `Add Security Verification to Testing Workflow`
  - **Then**: Match present unchanged (one match for the heading); no new BACKLOG entry added by Task 123

- **TC-14: CHANGELOG.md has Task 123 entry above Task 122**
  - **When**: Grep CHANGELOG.md for `^## Task 123`
  - **Then**: One match; entry has `**Status**`, `**Duration**`, `**Impact**`, `### Changes`, `### Notable` matching Task 122's structure

- **TC-15: cwf-manage validate clean**
  - **When**: Run `.cwf/scripts/cwf-manage validate`
  - **Then**: Exit 0, `[CWF] validate: OK`

- **TC-AC8: Dogfood — security subagent runs against this task's own changeset**
  - **Given**: All the above wiring is in place; current branch is `feature/123-…`
  - **When**: g-testing-exec executes the new Step 8 against `git diff $(git merge-base HEAD main)..HEAD -- <pathspec>` for this task's own changes (which include the new doc, plan-review.md row 4, and the two SKILL edits)
  - **Then**: Subagent returns one of: `findings:` (with numbered actionable items), `no findings`, or `error:`. The verbatim output is recorded in g-testing-exec.md under `## Security Review`. State is classified per Decision 3.
  - **Outcome handling**:
    - On `no findings`: TC-AC8 PASS; record verbatim and proceed
    - On `findings`: TC-AC8 PASS for *wiring* (the subagent works); user decides between (a) returning to f-implementation-exec to address each finding and re-running TC-AC8, or (b) accepting the findings with a documented rationale in g-testing-exec.md. Either path closes AC8.
    - On `error`: TC-AC8 FAIL; the wiring is broken — return to f-implementation-exec to diagnose

### Non-Functional

- **NFR-1: Token budget for the security prompt template (≤400 tokens)**
  - **When**: Read the `## Exec-phase prompt template` section in `security-review.md` and the row-4 `criteria` cells in `plan-review.md`
  - **Then**: Each prompt body (between the template's start and the `{changeset}` / `{focus_area}` substitution) is ≤400 tokens. Approximated by line count: ≤30 lines of prompt text per template.

- **NFR-2: Allowlist explicit in both prompts**
  - **When**: Grep both prompts (plan-review row 4, security-review.md exec template) for the allowlist string
  - **Then**: Both contain `Read, Grep, and Glob` (or equivalent); both explicitly forbid Bash and Edit

- **NFR-3: British spelling in new prose**
  - **When**: Grep `security-review.md` for American variants `\b(color|behavior|organize|center|favor|optimize)\b`
  - **Then**: Zero matches

- **NFR-4: Anti-pattern examples are concrete (not generic)**
  - **When**: Read all five threat-category subsections
  - **Then**: Every anti-pattern is either a real `file:path:lineno` citation OR labelled `# illustrative` and uses CWF-shaped names (skill paths, helper script paths, slug variables) — not generic "user input" placeholders

## Test Environment
- Local repo at `/home/matt/repo/coding-with-files`, branch `feature/123-…`
- No external services, no test fixtures, no test database
- Tools used: Read, Grep, Glob, Bash (only for `cwf-manage validate` and the live Agent call in TC-AC8)
- For TC-AC8: Claude Code with Agent tool available; subagent_type=Explore

### Automation
None for TC-1…TC-15; one-shot greps and Reads. TC-AC8 is the only test that triggers a tool call beyond Read/Grep — and that's intentional, since exercising the security subagent end-to-end is the point of AC8.

## Validation Criteria
- [ ] TC-1 through TC-15 PASS
- [ ] TC-AC8: subagent invocation returns a classifiable result; verbatim output recorded
- [ ] NFR-1, NFR-2, NFR-3, NFR-4 spot-check PASS
- [ ] If TC-AC8 returns `findings:`, the user-decision-and-record loop is closed in g-testing-exec.md before that file is marked Finished
- [ ] No `find` / `sed` used by g-testing-exec to perform any of these checks (use Grep / Read / `git ls-files` per memory `feedback_no_find_no_sed_permissions`)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 123
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
20/20 PASS (15 functional TC-1…TC-15, 4 non-functional NFR-1…NFR-4, 1 dogfood TC-AC8). TC-AC8 outcome handling exercised real path: classifier returned `findings`, substance was clean, disposition was option (b) accept-with-rationale.

## Lessons Learned
The "single source of truth" claim in TC-10 needs to specify *which substring* counts. Originally framed against the diff-prefix; refined during exec to the verbose pathspec list.
