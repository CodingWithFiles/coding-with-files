# Add PreToolUse hook for rule re-injection - Requirements
**Task**: 99 (feature)

## Task Reference
- **Task ID**: internal-99
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/99-add-pretooluse-hook-for-rule-re-injection
- **Template Version**: 2.1

## Goal
Specify what the hook must do, which rules to re-inject, and how to integrate into the install pipeline.

## Functional Requirements
### Core Features
- **FR1**: A rules injection file (`.cwf/rules-inject.txt`) must contain the most critical CWF rules drawn from documented recurring process errors
- **FR2**: A PreToolUse hook on `UserPromptSubmit` must be configured in project-level `.claude/settings.json` that outputs the rules file content on every user message
- **FR3**: The hook must use `cat .cwf/rules-inject.txt` (or equivalent) so rules are maintained in a separate file, not embedded in settings.json
- **FR4**: `/cwf-init` must add the hook configuration to `.claude/settings.json` during project initialisation (merging with existing permissions)
- **FR5**: `install.bash` must include `.cwf/rules-inject.txt` as part of the `.cwf/` subtree (no additional split needed — it's inside `.cwf/`)

### Rules Content (FR1 detail)
The following rules are the most frequently violated (from MEMORY.md recurring process errors analysis):
1. **Use skills for wf step files** — do not edit directly, invoke the corresponding `/cwf-{step}` skill
2. **Checkpoint commit after each phase** — write file → stage → commit → proceed
3. **Never execute merge to main** — suggest the merge command, never run it
4. **git status before committing** — check for untracked files to avoid missing new files

### User Stories
- **As an** agent in a long CWF session **I want** critical rules re-injected after compaction **so that** I don't lose awareness of process requirements
- **As a** CWF installer **I want** the hook auto-configured during `/cwf-init` **so that** protection is active from first use

## Non-Functional Requirements
### Context Efficiency (NFR1)
- Rules injection file must be under 10 lines of content
- Every line appears as a system reminder on every turn — token cost is linear with content length and conversation length
- No explanatory prose — imperative statements only

### Portability (NFR2)
- Hook configuration must work in any project where CWF is installed
- Rules file path must be relative to git root (`.cwf/rules-inject.txt`)
- No assumptions about shell, OS, or installed tools beyond `cat`

### Reliability (NFR3)
- If rules file is missing, hook must fail silently (non-zero exit does not block tool use — it just doesn't inject)
- Hook must not interfere with normal tool use flow

### Maintainability (NFR4)
- Rules are in a separate file, not embedded in JSON — editable without JSON escaping
- Single file to update when rules change

## Constraints
- Hook output becomes a system reminder — consumes context tokens on every turn
- `.claude/settings.json` is shared between skill permissions (from `/cwf-init`) and hook config — must merge cleanly
- `UserPromptSubmit` is the correct matcher — fires once per user message, not per tool call
- Hook runs outside the reasoning loop — no compute cost, but output is injected into context

## Decomposition Check
0/5 signals triggered — no decomposition needed.

## Acceptance Criteria
- [ ] AC1: `.cwf/rules-inject.txt` exists with the 4 critical rules, under 10 lines
- [ ] AC2: Hook configured in `.claude/settings.json` with correct event/matcher/command
- [ ] AC3: Hook fires on user message and outputs rules content
- [ ] AC4: `/cwf-init` merges hook configuration into existing settings.json
- [ ] AC5: Rules file included in `.cwf/` subtree (no additional install.bash changes needed)
- [ ] AC6: Missing rules file does not block tool use

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 99
**Blockers**: None

## Actual Results
All 6 acceptance criteria met. Rules file is 5 lines (under 10), hook fires on UserPromptSubmit, cwf-init merges hook config, install pipeline handles rules via existing .cwf/ subtree.

## Lessons Learned
- Keeping rules to imperative one-liners with no explanation is the right trade-off for per-turn injection
