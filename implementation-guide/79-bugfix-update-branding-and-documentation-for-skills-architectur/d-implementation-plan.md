# Update branding and documentation for skills architecture - Implementation Plan
**Task**: 79 (bugfix)

## Task Reference
- **Task ID**: internal-79
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/79-update-branding-and-documentation-for-skills-architectur
- **Template Version**: 2.1

## Goal
Fix stale "commands" terminology and outdated v2.0 skill names in CLAUDE.md and README.md.

## Files to Modify

- `CLAUDE.md` — rename "Commands" sections to "Skills", fix v2.0 skill names, fix prose
- `README.md` — replace "slash commands" with "skills" in prose

## Implementation Steps

### Step 1: Fix CLAUDE.md

#### 1a — Section header and skill list prose
- [ ] "Progressive disclosure pattern (commands reference docs..." → "skills reference docs..."
- [ ] "### Available CWF Commands" → "### Available CWF Skills"
- [ ] "**Core Commands (v2.0)**" → "**Core Skills**"
- [ ] "**Workflow Commands (v2.0 - New)**" → "**Workflow Skills**"
- [ ] "**Utility Commands**" → "**Utility Skills**"

#### 1b — Fix stale v2.0 workflow skill names
Replace the entire workflow skills list. Old names → new names:
- `/cwf-plan` → `/cwf-task-plan`
- `/cwf-requirements` → `/cwf-requirements-plan`
- `/cwf-design` → `/cwf-design-plan`
- `/cwf-implementation` → `/cwf-implementation-plan` and `/cwf-implementation-exec`
- `/cwf-testing` → `/cwf-testing-plan` and `/cwf-testing-exec`
- `/cwf-rollout`, `/cwf-maintenance`, `/cwf-retrospective` — unchanged

#### 1c — File Protection section
- [ ] "Use the designated commands instead" → "Use the designated skills instead"

### Step 2: Fix README.md

- [ ] Line 3: "slash commands" → "skills"
- [ ] Line 9: "slash commands" → "skills"
- [ ] Line 196: "Test all commands before submission" → "Test all skills before submission"

### Step 3: Verify no stale references remain

```bash
grep -n "CWF Commands\|slash commands\|/cwf-plan\b\|/cwf-requirements\b\|/cwf-design\b\|/cwf-implementation\b\|/cwf-testing\b" CLAUDE.md README.md
```
Expected: no matches (or only matches inside path strings like `command-helpers/`).

## Validation Criteria
- [ ] `grep "Available CWF Commands" CLAUDE.md` → no match
- [ ] `grep "slash commands" README.md` → no match
- [ ] `grep "/cwf-plan\b" CLAUDE.md` → no match (old v2.0 name gone)
- [ ] All current skill names in CLAUDE.md match `.claude/skills/` directory listing
- [ ] `prove t/` exits 0 (no regressions — docs-only change, but confirm)

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 79
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All implementation steps executed as planned. CLAUDE.md and README.md updated;
verification grep confirmed no stale references remain.

## Lessons Learned
The risk of replacing path strings (`command-helpers/`) was fully mitigated by
targeted prose-only edits and TC-5 confirming path strings intact.
