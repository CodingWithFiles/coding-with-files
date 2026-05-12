# Intent-CTA skill descriptions with reference docs - Testing Plan
**Task**: 134 (chore)

## Task Reference
- **Task ID**: internal-134
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/134-intent-cta-skill-descriptions-with-reference-docs
- **Template Version**: 2.1

## Goal
Define concrete validation steps for the convention doc, the reference-doc
instance, and the rewritten frontmatter description. The task is docs-only —
no new code paths, no behavioural change in `cwf-backlog-manager` — so the
test plan is a set of structural and parse-level assertions, not a unit-test
suite.

## Test Strategy

### Test Levels
- **Structural**: file existence, location, byte/line/word budgets, absence of
  forbidden strings (e.g., `SKILL.md` references).
- **Parse**: YAML loader confirms the rewritten frontmatter is syntactically
  valid (`cwf-manage validate` does not inspect frontmatter syntax — D6).
- **Smoke (manual)**: an end user reads the new description and confirms the
  intent-CTA shape would plausibly match the original miss ("what's in the
  backlog").

### Test Coverage Targets
- **Critical paths**: 100% — every success criterion in `a-task-plan.md` is
  covered by at least one test case below.
- **Regression**: `cwf-manage validate` exit code unchanged (pass → pass).
- **No new automated test framework added**; budgets are checked via one-shot
  shell verifications in g-testing-exec.

## Test Cases

### Functional Test Cases

- **TC-1**: Convention doc exists at the canonical location
  - **Given**: Task 134 implementation complete
  - **When**: `ls .cwf/docs/skills/skill-reference-convention.md`
  - **Then**: File exists; exit 0

- **TC-2**: Convention doc names the four mandatory rules
  - **Given**: Convention doc written
  - **When**: Grep the doc for each rule keyword
  - **Then**: Matches for all of: "location", "≤ 30 words" (description
    budget), "≤ 30 lines" (instance budget), "SKILL.md" (in the context of
    prohibition), "author-curated" (or equivalent: "hardcoded", "not
    derived")

- **TC-3**: Reference doc exists at canonical location
  - **Given**: Task 134 implementation complete
  - **When**: `ls .cwf/docs/skills/reference/cwf-backlog-manager.md`
  - **Then**: File exists; exit 0

- **TC-4**: Reference doc respects ≤ 30 line budget
  - **Given**: Reference doc written
  - **When**: `wc -l .cwf/docs/skills/reference/cwf-backlog-manager.md`
  - **Then**: Line count ≤ 30

- **TC-5**: Reference doc contains 3-5 example user phrasings
  - **Given**: Reference doc written
  - **When**: Read the doc and count quoted user-phrasing strings
  - **Then**: Count is between 3 and 5 inclusive

- **TC-6**: Neither new doc references `SKILL.md`
  - **Given**: Convention doc and reference doc written
  - **When**: `grep -l 'SKILL\.md' .cwf/docs/skills/skill-reference-convention.md
    .cwf/docs/skills/reference/cwf-backlog-manager.md`
  - **Then**: Zero matches. (The convention doc *names* SKILL.md when
    explaining the prohibition — that mention must be phrased so it cannot be
    interpreted as a path. Test asserts no `.md` path token.) Refined check:
    `grep -nE '\bSKILL\.md\b' file | grep -vE 'must not|prohibit|do not'` →
    zero hits.

- **TC-7**: `cwf-backlog-manager` frontmatter description ≤ 30 words
  - **Given**: Frontmatter rewritten
  - **When**: Extract description value (Perl one-liner stripping the
    `description: ` key), pipe to `wc -w`
  - **Then**: Word count ≤ 30

- **TC-8**: `cwf-backlog-manager` SKILL.md parses as valid YAML
  - **Given**: Frontmatter rewritten
  - **When**: Load `.claude/skills/cwf-backlog-manager/SKILL.md` via
    `YAML::PP->new->load_file($path)` in a Perl one-liner (`use YAML::PP;`)
  - **Then**: No parse error; resulting hash contains `name`, `description`,
    `user-invocable`, `allowed-tools` keys

- **TC-9**: New description names the user-facing domain
  - **Given**: Frontmatter rewritten
  - **When**: Grep the description for the substring "backlog" (case-insensitive)
  - **Then**: At least one match

- **TC-10**: New description contains example phrasings
  - **Given**: Frontmatter rewritten
  - **When**: Read description, count quoted example strings (paired quotes)
  - **Then**: Count is 2-3 inclusive

- **TC-11**: SKILL.md body unchanged
  - **Given**: Frontmatter rewritten, body untouched
  - **When**: `git diff HEAD~ -- .claude/skills/cwf-backlog-manager/SKILL.md`
    after the implementation commit
  - **Then**: Diff is bounded to the frontmatter region (lines 1-7); no body
    line changed

- **TC-12**: Follow-up backlog entry filed
  - **Given**: Task 134 implementation complete
  - **When**: `.cwf/scripts/command-helpers/backlog-manager list --all-items |
    grep -i "intent-CTA"`
  - **Then**: One match present, at Low priority

### Non-Functional Test Cases

- **NFT-1 (Regression)**: `cwf-manage validate` passes
  - **Given**: All implementation changes committed
  - **When**: Run `.cwf/scripts/cwf-manage validate`
  - **Then**: Exit 0, "[CWF] validate: OK"

- **NFT-2 (Regression)**: `backlog-manager validate` passes
  - **Given**: BACKLOG.md updated with follow-up entry
  - **When**: Run `.cwf/scripts/command-helpers/backlog-manager validate --all`
  - **Then**: Exit 0

- **NFT-3 (Smoke, manual)**: Intent-match plausibility
  - **Given**: New description visible to operator
  - **When**: Read the description and ask "would I pick this skill for the
    user query 'what's in the backlog'?"
  - **Then**: Yes, by direct inspection. (No automated test for this; it is the
    qualitative goal of the task.)

## Test Environment

### Setup Requirements
- Local repo at git root; chore/134 branch checked out.
- Perl with `YAML::PP` available (verified once during TC-8 setup; install via
  the system perl if missing).
- No test database, no network, no mocks.

### Automation
- No new automated framework. Tests run as one-shot shell/Perl commands during
  g-testing-exec.
- Existing test suite (`prove t/`) MUST still pass — verified once at the end
  as a regression gate.

## Validation Criteria
- [ ] TC-1 through TC-12 all pass
- [ ] NFT-1, NFT-2 pass (exit 0)
- [ ] NFT-3 manually confirmed
- [ ] `prove t/` exit 0 (no existing-test regression)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 12 functional and 4 non-functional tests pass. Existing `prove t/` suite green
(441 tests). Test plan held without modification.

## Lessons Learned
Structural + parse + manual-smoke is sufficient testing for docs-only tasks of
this shape. No new test framework required. See j-retrospective.md.
