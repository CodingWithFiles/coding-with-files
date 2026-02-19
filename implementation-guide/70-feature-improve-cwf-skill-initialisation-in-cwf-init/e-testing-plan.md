# Improve CWF skill initialisation in cwf-init - Testing Plan
**Task**: 70 (feature)

## Task Reference
- **Task ID**: internal-70
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/70-improve-cwf-skill-initialisation-in-cwf-init
- **Template Version**: 2.1

## Goal
Validate that the three changes to `.claude/skills/cwf-init/SKILL.md` satisfy FR1–FR3, NFR1–NFR3, and all acceptance criteria.

## Test Strategy

### Test Levels
This task modifies a single skill instruction file (no runnable code). All tests are **content inspection tests** — read the file and verify the instructions are correct, complete, and idempotency-safe.

One system-level test validates the overall CWF installation remains consistent.

### Coverage Targets
- FR1 (permissions): 3 test cases (exists, dynamic enumeration, user confirmation, idempotency)
- FR2 (CLAUDE.md preamble): 2 test cases (content correct, idempotency check present)
- FR3 (commit reminder): 2 test cases (mandatory wording, step numbering)
- NFR compliance: covered by idempotency and user-confirmation tests above
- System: 1 test case (cwf-manage validate)

## Test Cases

### TC-1: FR2 — CLAUDE.md preamble content and idempotency check
- **Given**: `cwf-init/SKILL.md` has been updated
- **When**: Step 4 ("Update CLAUDE.md") content is read
- **Then**:
  - Idempotency check `grep -q "CWF.*is installed"` is present before any prepend action
  - Blockquote preamble contains all three required lines:
    - "CWF (Coding with Files) is installed in this project."
    - Reference to `Skill` tool usage and prohibition on following SKILL.md directly
    - Instruction to mark inapplicable steps `Skipped` — not silently omit
  - Instruction to preserve existing CLAUDE.md content is present

### TC-2: FR2 — CLAUDE.md preamble is idempotent (skip if already present)
- **Given**: Step 4 instruction
- **When**: The skip condition is reviewed
- **Then**: Explicit "If preamble already present: Skip" instruction exists

### TC-3: FR1 — Step 6 "Register Skill Permissions" exists in correct position
- **Given**: `cwf-init/SKILL.md`
- **When**: Section headings are listed in order
- **Then**: `### 6. Register Skill Permissions` appears after `### 5.` and before `### 7.`

### TC-4: FR1 — Skill list derived dynamically (NFR3)
- **Given**: Step 6 instruction
- **When**: The method for enumerating skills is reviewed
- **Then**: References `ls .claude/skills/cwf-*/` (or equivalent glob) — no hardcoded skill names

### TC-5: FR1 — User asked before writing settings.json (NFR2)
- **Given**: Step 6 instruction
- **When**: User interaction requirement is reviewed
- **Then**: "Ask user to confirm" (or equivalent) instruction present before any write action

### TC-6: FR1 — Permissions merge is idempotent (NFR1)
- **Given**: Step 6 instruction
- **When**: The merge logic description is reviewed
- **Then**: "skip any already present" (or equivalent) instruction present

### TC-7: FR3 — Init commit is mandatory, not optional
- **Given**: The final commit step in `cwf-init/SKILL.md`
- **When**: Its wording is reviewed
- **Then**:
  - Step is numbered `### 8.`
  - "Do not begin task work" instruction present
  - `git commit` command is an explicit action (not "offer to commit")

### TC-8: Success criteria updated for 8-step workflow
- **Given**: The `## Success Criteria` checklist at the bottom of `cwf-init/SKILL.md`
- **When**: Checklist items are reviewed
- **Then**:
  - Entry for skill permissions registration present
  - Entry for mandatory init commit present (not "or offered to user")
  - `.claude/settings.json` mentioned as the target for permissions

### TC-9: System — cwf-manage validate exits 0
- **Given**: All edits complete
- **When**: `perl -I.cwf/lib .cwf/scripts/cwf-manage validate` is run
- **Then**: Exits 0 with no errors

## Test Environment

Manual inspection of a single file — no test environment setup required.

TC-9 requires the Bash tool with the CWF library path.

## Validation Criteria
- [ ] TC-1: CLAUDE.md preamble content and idempotency check correct
- [ ] TC-2: Skip-if-present instruction in step 4
- [ ] TC-3: Step 6 exists in correct position
- [ ] TC-4: Dynamic skill enumeration (no hardcoded list)
- [ ] TC-5: User confirmation before writing settings.json
- [ ] TC-6: Idempotent merge (skip duplicates)
- [ ] TC-7: Mandatory commit wording with "do not begin task work"
- [ ] TC-8: Success criteria updated for 8-step workflow
- [ ] TC-9: cwf-manage validate exits 0

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 70
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled during g-testing-exec*

## Lessons Learned
*To be captured during retrospective*
