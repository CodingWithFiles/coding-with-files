# Refactor workflow docs for efficiency - Testing Plan
**Task**: 88 (bugfix)

## Task Reference
- **Task ID**: internal-88
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/88-refactor-workflow-docs-for-efficiency
- **Template Version**: 2.1

## Goal
Verify that all duplicated content has been removed and every removal has a working reference chain to its canonical source.

## Test Strategy
### Test Levels
- **Content verification (grep)**: Confirm removed content is absent and references are present
- **Reference chain verification**: Confirm each reference target file exists and contains the expected content
- **System test**: `cwf-manage validate` passes end-to-end

### Test Coverage Targets
- Every removal in the plan has a corresponding test case
- Every reference target is verified to exist and contain the promised content

## Test Cases

### TC-1: checkpoint-commit.md — stale command removed
- **When**: `grep "perl -I" .cwf/docs/skills/checkpoint-commit.md`
- **Then**: No match

### TC-2: workflow-steps.md — checkpoint blocks replaced with references
- **When**: `grep -c "checkpoint-commit.md" .cwf/docs/workflow/workflow-steps.md`
- **Then**: Count ≥ 8 (one reference per phase)
- **And**: `grep "git commit -m" .cwf/docs/workflow/workflow-steps.md` → no match (blocks gone)
- **And**: `checkpoint-commit.md` still contains the actual commit procedure (`git commit -m`)

### TC-3: workflow-steps.md — Typical Structure sections removed
- **When**: `grep "Typical Structure" .cwf/docs/workflow/workflow-steps.md`
- **Then**: No match
- **And**: Each phase has a `.cwf/templates/pool/` reference (count ≥ 8)
- **And**: `.cwf/templates/pool/` directory exists

### TC-4: workflow-steps.md — jq blocks removed
- **When**: `grep "jq -r" .cwf/docs/workflow/workflow-steps.md`
- **Then**: No match
- **And**: `grep "cwf-project.json" .cwf/docs/workflow/workflow-steps.md` → match
- **And**: `.cwf/implementation-guide/cwf-project.json` exists and contains `status-values`

### TC-5: blocker-patterns.md — skill calls present in all Reversion Guidance sections
- **When**: `grep "/cwf-" .cwf/docs/workflow/blocker-patterns.md`
- **Then**: Matches present (skill calls replacing file-edit instructions)
- **And**: `grep "Update.*\.md.*then" .cwf/docs/workflow/blocker-patterns.md` → no match (file-edit instructions gone)

### TC-6: blocker-patterns.md — Decomposition Signals references decomposition-guide.md
- **When**: `grep "decomposition-guide" .cwf/docs/workflow/blocker-patterns.md`
- **Then**: Match present
- **And**: `decomposition-guide.md` still contains all 5 signal names (When to Split, complexity, risk, independence, time, people)

### TC-7: decomposition-guide.md — Context Inheritance references workflow-overview.md
- **When**: `grep "workflow-overview" .cwf/docs/workflow/decomposition-guide.md`
- **Then**: Match present
- **And**: `workflow-overview.md` contains context inheritance content (`grep -i "context inheritance" .cwf/docs/workflow/workflow-overview.md`)

### TC-8: blocker-patterns.md — no stale .claude/commands/ references
- **When**: `grep "\.claude/commands/" .cwf/docs/workflow/blocker-patterns.md`
- **Then**: No match

### TC-9: Placeholder convention — no `<>` substitution variables in skill docs
- **When**: Check `checkpoint-commit.md` and `retrospective-extras.md` for `<[a-z_-]` pattern (angle-bracket vars)
- **Then**: No match in either file

### TC-10: System test — cwf-manage validate passes
- **When**: `.cwf/scripts/cwf-manage validate`
- **Then**: Exit 0, no errors

## Test Environment
- Local repo, no external dependencies
- All tests are grep/file existence checks + one script invocation

## Validation Criteria
- [ ] TC-1 through TC-10 all pass
- [ ] No reference target files are missing or empty

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 88
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
