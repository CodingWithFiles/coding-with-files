# Remove cd to git root from backlog-manager skill - Implementation Plan
**Task**: 138 (bugfix)

## Task Reference
- **Task ID**: internal-138
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/138-remove-cd-to-git-root-from-backlog-manager-skill
- **Template Version**: 2.1

## Goal
Apply the deletion specified in `c-design-plan.md` to `.claude/skills/cwf-backlog-manager/SKILL.md` in three Edit-tool calls.

## Files to Modify
### Primary Changes
- `.claude/skills/cwf-backlog-manager/SKILL.md` — strip `cd "$(git rev-parse --show-toplevel)" && ` from every example, delete the "Mandatory pre-step" paragraph, delete one Success Criteria checkbox.

### Supporting Changes
None. No tests, no helper code, no other skills, no docs.

**Convention note**: The rest of the CWF skill corpus already invokes command-helpers without a cd prefix (e.g. `cwf-status`, `cwf-task-plan`, `cwf-security-check`, `cwf-delete-task`). This task aligns `cwf-backlog-manager` with that existing convention; it does not establish a new one.

## Implementation Steps

### Step 1: Delete the "Mandatory pre-step" paragraph and its example fence
Edit `.claude/skills/cwf-backlog-manager/SKILL.md`. Remove lines 18-24 inclusive (the `**Mandatory pre-step**:` line, the fenced example, the threat-model paragraph, AND the trailing blank line at 24). The trailing blank must be included; otherwise the blank at line 17 and the blank that was line 24 collapse into a double-blank before `## Subcommands` (line 25).

Post-edit structure: line 16 `**Helper path**:` bullet → line 17 blank → line 18 `## Subcommands`.

- [ ] Use Edit with `old_string` = the 7-line block spanning lines 18-24, `new_string` = empty

### Step 2: Strip the cd prefix from all eight subcommand examples
Each occurrence is the literal string `cd "$(git rev-parse --show-toplevel)" && ` followed by `.cwf/scripts/command-helpers/backlog-manager`. The prefix appears identically in 8 places (post-Step-1 line numbers: 27, 34, 42, 54, 62, 70, 71, 78).

- [ ] Use Edit with `replace_all: true`, `old_string` = `cd "$(git rev-parse --show-toplevel)" && .cwf/scripts/command-helpers/backlog-manager`, `new_string` = `.cwf/scripts/command-helpers/backlog-manager`. Single call replaces all 8.

### Step 3: Delete the Success Criteria checkbox that references the cd
Edit `.claude/skills/cwf-backlog-manager/SKILL.md`. Remove the line:
```
- [ ] Subcommand invoked from git-root via `cd "$(git rev-parse --show-toplevel)"`
```
The Success Criteria section retains the two remaining checkboxes (list-form args, helper exit code).

- [ ] Use Edit with `old_string` = the checkbox line **including its trailing newline**, `new_string` = empty. The checkbox text contains the unique substring `Subcommand invoked from git-root`, so no extra anchor is needed.

### Step 4: Verify no residue
- [ ] `grep -rn 'git rev-parse --show-toplevel\|Mandatory pre-step' .claude/ docs/ .cwf/` returns exactly one match: line 87 of `.claude/skills/cwf-init/SKILL.md` (the out-of-scope `GIT_ROOT="$(...)"` pattern). Any other match is a residue and must be fixed before proceeding.

### Step 5: Smoke-test rewritten examples (deferred to g-testing-exec)
The actual execution of the rewritten examples and `cwf-security-check verify` happens in g-testing-exec; the implementation phase is just the edits.

## Code Changes

### Before (SKILL.md lines 14-23)
```markdown
## Context

**Helper path**: `.cwf/scripts/command-helpers/backlog-manager` (relative to git root).

**Mandatory pre-step**: Resolve the git root with `git rev-parse --show-toplevel` and invoke from there. Example:
```bash
cd "$(git rev-parse --show-toplevel)" && .cwf/scripts/command-helpers/backlog-manager <subcommand> [...]
```

This guards against working-directory pivots: an attacker who can change `cwd` to e.g. `/tmp` and stages `/tmp/.cwf/scripts/command-helpers/backlog-manager` would otherwise win the path lookup. Anchoring at `git rev-parse --show-toplevel` makes that attack impossible.
```

### After (SKILL.md lines 14-16)
```markdown
## Context

**Helper path**: `.cwf/scripts/command-helpers/backlog-manager` (relative to git root).
```

### Before (each subcommand example, e.g. `list`)
````markdown
```bash
cd "$(git rev-parse --show-toplevel)" && .cwf/scripts/command-helpers/backlog-manager list
```
````

### After
````markdown
```bash
.cwf/scripts/command-helpers/backlog-manager list
```
````

### Before (Success Criteria)
```markdown
## Success Criteria
- [ ] Subcommand invoked from git-root via `cd "$(git rev-parse --show-toplevel)"`
- [ ] Arguments passed as separate Bash array elements (list form), not interpolated string
- [ ] Helper exit code observed; user informed of failure if non-zero
```

### After
```markdown
## Success Criteria
- [ ] Arguments passed as separate Bash array elements (list form), not interpolated string
- [ ] Helper exit code observed; user informed of failure if non-zero
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
Single-file deletion. No staged delivery, no follow-up tasks expected. If the post-edit grep returns any unexpected match in the skill file, fix it in this task before marking Finished.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 138
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
