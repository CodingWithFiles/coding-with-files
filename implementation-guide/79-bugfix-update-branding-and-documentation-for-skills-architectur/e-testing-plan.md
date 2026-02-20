# Update branding and documentation for skills architecture - Testing Plan
**Task**: 79 (bugfix)

## Task Reference
- **Task ID**: internal-79
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/79-update-branding-and-documentation-for-skills-architectur
- **Template Version**: 2.1

## Goal
Verify all stale "commands" terminology and v2.0 skill names are gone from
CLAUDE.md and README.md, and no regressions introduced.

## Test Strategy
Content review via `grep` — no runtime test harness needed. All test cases
are deterministic text searches.

## Test Cases

### TC-1: No "Available CWF Commands" heading in CLAUDE.md
- **Given**: CLAUDE.md updated
- **When**: `grep "Available CWF Commands" CLAUDE.md`
- **Then**: No matches

### TC-2: No stale v2.0 workflow skill names in CLAUDE.md
- **Given**: CLAUDE.md updated
- **When**: `grep -E "/cwf-plan\b|/cwf-requirements\b|/cwf-design\b|/cwf-implementation\b|/cwf-testing\b" CLAUDE.md`
- **Then**: No matches

### TC-3: Current v2.1 workflow skill names present in CLAUDE.md
- **Given**: CLAUDE.md updated
- **When**: `grep -c "cwf-task-plan\|cwf-requirements-plan\|cwf-design-plan\|cwf-implementation-plan\|cwf-implementation-exec\|cwf-testing-plan\|cwf-testing-exec" CLAUDE.md`
- **Then**: Count ≥ 7 (one per skill)

### TC-4: No "slash commands" in README.md
- **Given**: README.md updated
- **When**: `grep "slash commands" README.md`
- **Then**: No matches

### TC-5: `command-helpers` path strings left intact
- **Given**: Both files updated
- **When**: `grep "command-helpers" CLAUDE.md README.md`
- **Then**: Matches exist (directory name preserved, not renamed)

### TC-6: `prove t/` regression check
- **Given**: Only doc files changed
- **When**: `prove t/`
- **Then**: 158 tests, all pass

## Validation Criteria
- [ ] TC-1: no "Available CWF Commands" in CLAUDE.md
- [ ] TC-2: no stale v2.0 skill names in CLAUDE.md
- [ ] TC-3: all 7 current workflow skill names present
- [ ] TC-4: no "slash commands" in README.md
- [ ] TC-5: `command-helpers` path strings preserved
- [ ] TC-6: `prove t/` exits 0

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 79
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 6 TCs passed. TC-2 produced unexpected matches due to `\b` boundary
matching within `-plan`/`-exec` suffixed names — implementation is correct
but the test pattern has a design flaw documented in the retrospective.

## Lessons Learned
`\b` patterns match within prefix-style names. For negative grep tests on skill
names, use the full exact name or a negative lookahead to avoid false positives.
