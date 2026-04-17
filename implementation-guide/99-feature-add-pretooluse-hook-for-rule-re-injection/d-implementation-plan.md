# Add PreToolUse hook for rule re-injection - Implementation Plan
**Task**: 99 (feature)

## Task Reference
- **Task ID**: internal-99
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/99-add-pretooluse-hook-for-rule-re-injection
- **Template Version**: 2.1

## Goal
Create the rules injection file, configure the hook, and update cwf-init to install it.

## Files to Modify
### New Files
- `.cwf/rules-inject.txt` — Plain text rules file (4 rules, 5 lines including header)

### Modified Files
- `.claude/skills/cwf-init/SKILL.md` — Add hook configuration step to cwf-init workflow
- `.cwf/docs/glossary.md` — Add "hook" and "rules injection" terms if needed

### Not Modified
- `scripts/install.bash` — Not needed; `.cwf/rules-inject.txt` is inside `.cwf/` which is already handled by the existing subtree split
- `.claude/settings.json` — Not modified directly; cwf-init skill instructs the agent to add hooks at init time (same as skill permissions)

## Implementation Steps

### Step 1: Create Rules Injection File
- [ ] Create `.cwf/rules-inject.txt` with content:
  ```
  CWF RULES (re-injected every turn):
  1. Use /cwf-{step} skills for wf step files — do not edit directly.
  2. Checkpoint commit after each wf phase — write → stage → commit → proceed.
  3. Never execute merge to main — suggest the command, do not run it.
  4. Run git status before every commit — check for untracked files.
  ```
- [ ] Verify file is exactly 5 lines

### Step 2: Update cwf-init Skill
- [ ] Add step after step 6b (Create Rules Directory) — call it step 6c:
  ```
  ### 6c. Configure Rule Re-Injection Hook
  - Read existing `.claude/settings.json`
  - Add hooks configuration if not present:
    ```json
    "hooks": {
      "PreToolUse": [
        {
          "matcher": "UserPromptSubmit",
          "hooks": [
            {
              "type": "command",
              "command": "cat .cwf/rules-inject.txt 2>/dev/null || true"
            }
          ]
        }
      ]
    }
    ```
  - If `hooks.PreToolUse` already exists, check for existing `UserPromptSubmit` matcher
  - If matcher already present, skip (idempotent)
  - If matcher absent, append to the array
  - Write back valid JSON
  ```
- [ ] Update success criteria to include hook configuration

### Step 3: Update Glossary
- [ ] Add "hook" term to `.cwf/docs/glossary.md` if not already defined

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 99
**Blockers**: None

## Actual Results
All 3 steps executed as planned. No deviations. Glossary got 2 terms instead of 1 (added "rules injection" alongside "hook").

## Lessons Learned
- Adding glossary terms during implementation is low-cost and improves documentation quality
