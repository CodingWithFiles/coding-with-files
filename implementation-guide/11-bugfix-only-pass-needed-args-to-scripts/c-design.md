# Only pass needed args to scripts - Design

## Task Reference
- **Task ID**: internal-11
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/11-only-pass-needed-args-to-scripts
- **Template Version**: 2.0

## Goal
Enable CIG commands to safely pass only required arguments to helper scripts, while handling arbitrary user input including special characters (quotes, spaces, etc.).

## Design Priorities
Robustness → Simplicity → Consistency → Readability → Reversibility

## Key Decisions
### Argument Passing Strategy
- **Decision**: Remove inline bash execution (`!` notation) from Context section; have Claude parse `$ARGUMENTS` and invoke scripts via Bash tool
- **Rationale**:
  - **Problem discovered**: `$1`, `$2`, `$3` do NOT exist in Claude Code (GitHub issue #4370, #5520)
  - **Only `$ARGUMENTS` exists**: Contains full argument string
  - **Inline bash execution is unsafe**: Cannot handle arbitrary text with unmatched quotes, backticks, or special characters
  - **Claude can safely parse**: LLM reads text, extracts arguments, constructs Bash commands with literal values
- **Trade-offs**:
  - **Benefit**: Handles ANY user input safely (quotes, special chars, etc.)
  - **Benefit**: Works with multi-argument scripts (Claude can extract arg1, arg2, etc.)
  - **Benefit**: No bash parsing vulnerabilities
  - **Drawback**: Context section doesn't show pre-resolved task info (Claude resolves during workflow steps)
  - **Drawback**: Slightly more verbose instructions in command files

### Reference Implementation (Working Pattern)
**New pattern** - Claude parses arguments, validates format, and invokes scripts:
```markdown
## Context
**Task arguments**: $ARGUMENTS

## Your task
Guide the user through the X phase.

**CRITICAL - Argument Parsing**:
- Extract the FIRST space-separated word from the task arguments above as the task path
- Any additional words after the first provide user context about their intent
- Use the extra words to understand what the user wants, but do NOT pass them to script calls
- Example: "11 update the design" → task path is "11", extra text explains what to do

**CRITICAL - Task Path Validation**:
- Task paths MUST match hierarchical number format: digits separated by dots
- Valid formats: "11", "1.2", "12.2.3", "1.1.1.1"
- Invalid formats: "some text", "`date`", "11; rm -rf", "text.text"
- If first word does NOT match valid format, inform user and do not invoke scripts
- This prevents command injection and ensures only valid task identifiers reach scripts

Follow the 8-step workflow structure:

1. **Resolve Task Directory**:
   - Extract first word from task arguments
   - Validate it matches hierarchical number format (digits and dots only)
   - If valid: call `.cig/scripts/command-helpers/hierarchy-resolver.pl <task-path>` using the Bash tool
   - If invalid: inform user the task path format is invalid, do not invoke script

2. **Load Parent Context**:
   - Use the validated task path from step 1
   - Call `.cig/scripts/command-helpers/context-inheritance.pl <task-path>` using the Bash tool
```

## Security Model

### Defense in Depth
The new pattern implements multiple security layers:

1. **LLM Validation Layer** (NEW):
   - Claude validates task path format matches `^\d+(\.\d+)*$` regex pattern
   - Rejects invalid formats before invoking Bash tool
   - Prevents command injection attempts like `` `date` ``, `$(whoami)`, `11; rm -rf`
   - User receives clear error message, scripts never called

2. **Script Validation Layer** (Existing):
   - Helper scripts validate format and reject invalid paths
   - Provides second layer of defense if LLM validation is bypassed
   - Scripts report structured errors

### Valid Task Path Format
- **Pattern**: One or more numbers separated by dots
- **Regex**: `^\d+(\.\d+)*$`
- **Examples**:
  - Valid: `11`, `1.2`, `12.2.3`, `1.1.1.1`
  - Invalid: `text`, `` `date` ``, `11; echo`, `1.x`, `text.text`

### Security Properties
- **No bash injection**: Invalid formats rejected before reaching bash
- **No command execution**: Backticks, `$()`, etc. caught by format validation
- **No path traversal**: Only digits and dots allowed
- **Clear errors**: User informed when task path format is invalid

## Script Argument Requirements
### Single Argument Scripts (Most Common)
**hierarchy-resolver.pl**: `<task-path>` → Claude extracts and validates first word from `$ARGUMENTS`
**context-inheritance.pl**: `<task-path>` → Claude extracts and validates first word from `$ARGUMENTS`

### Optional Argument Scripts
**status-aggregator.pl**: `[task-path]` (optional) → Claude extracts first word if present

### Multi-Argument Scripts (Future Support)
**format-detector.pl**: `<task-dir> <workflow-file>` → Claude extracts first two words from `$ARGUMENTS`
- Instructions would specify: "Extract first two space-separated words as <task-dir> and <workflow-file>"
- Claude constructs: `.cig/scripts/format-detector.pl word1 word2`

## Files to Modify

### Commands Needing Fix (7 remaining files)
All currently use inline bash execution with `$1` (broken):

1. `.claude/commands/cig-design.md` - ✓ Already updated with new pattern (dogfood test)
2. `.claude/commands/cig-implementation.md` - Remove `!` notation, add argument parsing instructions
3. `.claude/commands/cig-maintenance.md` - Remove `!` notation, add argument parsing instructions
4. `.claude/commands/cig-plan.md` - Remove `!` notation, add argument parsing instructions
5. `.claude/commands/cig-requirements.md` - Remove `!` notation, add argument parsing instructions
6. `.claude/commands/cig-retrospective.md` - Remove `!` notation, add argument parsing instructions
7. `.claude/commands/cig-rollout.md` - Remove `!` notation, add argument parsing instructions
8. `.claude/commands/cig-testing.md` - Remove `!` notation, add argument parsing instructions

### Commands Not Requiring Changes
**cig-subtask.md** - May need similar update (uses bash expansion, has same vulnerability)
**cig-extract.md** - No script calls in Context section
**cig-new-task.md** - No script calls in Context section
**cig-status.md** - May need update if uses inline bash execution

## Implementation Pattern Comparison

**Old Pattern (Broken - Using `$1`)**:
```markdown
## Context
- Task resolution: !`.cig/scripts/command-helpers/hierarchy-resolver.pl $1 2>/dev/null...`
- Parent context: !`.cig/scripts/command-helpers/context-inheritance.pl $1 2>/dev/null...`

## Your task
Guide the user through the X phase for task: **$1**
**Additional context**: $ARGUMENTS
```
**Problems**:
- `$1` does not exist in Claude Code (only `$ARGUMENTS`)
- Inline bash execution fails on special characters (quotes, backticks, etc.)
- Cannot handle arbitrary user input safely

**New Pattern (Secure - Claude Validates & Parses)**:
```markdown
## Context
**Task arguments**: $ARGUMENTS

## Your task
Guide the user through the X phase.

**CRITICAL - Argument Parsing**:
- Extract the FIRST space-separated word from the task arguments above as the task path
- Any additional words after the first provide user context about their intent
- Use the extra words to understand what the user wants, but do NOT pass them to script calls
- Example: "11 update the design" → task path is "11", extra text explains what to do

**CRITICAL - Task Path Validation**:
- Task paths MUST match hierarchical number format: digits separated by dots
- Valid formats: "11", "1.2", "12.2.3", "1.1.1.1"
- Invalid formats: "some text", "`date`", "11; rm -rf", "text.text"
- If first word does NOT match valid format, inform user and do not invoke scripts
- This prevents command injection and ensures only valid task identifiers reach scripts

Follow the 8-step workflow:
1. **Resolve Task Directory**:
   - Extract first word from task arguments
   - Validate it matches hierarchical number format (digits and dots only)
   - If valid: call `.cig/scripts/command-helpers/hierarchy-resolver.pl <task-path>` using the Bash tool
   - If invalid: inform user the task path format is invalid, do not invoke script
```
**Benefits**:
- Validates task path format BEFORE invoking bash (defense in depth)
- Prevents command injection at LLM level, not just script level
- Claude parses text, validates format, constructs literal Bash commands
- No bash variable expansion vulnerabilities
- Extensible to multi-argument scripts

## Claude Code Variable Reference
- **`$ARGUMENTS`** - ONLY variable that exists; contains full argument string
- **`$1`, `$2`, `$3`** - Do NOT exist (GitHub issues #4370, #5520 confirm)
- **Inline bash execution (`!`)** - Unsafe for user input; bash parses and fails on special chars
- **Source**: https://code.claude.com/docs/en/slash-commands.md, GitHub issues

## Constraints
- Must not break existing command functionality
- Context section output must remain informative for LLM
- Pattern must be consistent across all modified commands

## Validation
- [x] Researched official Claude Code documentation
- [x] Confirmed `$1`, `$2`, `$3` do NOT exist via GitHub issues
- [x] Tested new pattern with cig-design.md (dogfood - successful!)
- [x] Documented Claude-parses-arguments pattern
- [x] Listed all 7 remaining files requiring modification

## Status
**Status**: Finished
**Next Action**: Proceed to implementation with Claude-parses pattern
**Blockers**: None

## Actual Results
### Discovery Process
1. **First attempt**: Implemented `$ARG1` based on reference implementation
2. **Testing failure**: `$ARG1` not recognized by Claude Code
3. **Documentation research**: Found `$1`, `$2`, `$3` in official docs
4. **Second attempt**: Implemented `$1` pattern
5. **Testing failure again**: `$1` receives full `$ARGUMENTS` string, not first word
6. **Deep research**: GitHub issues #4370, #5520 confirm `$1` does NOT exist
7. **Root cause**: Only `$ARGUMENTS` exists; inline bash execution unsafe for arbitrary input
8. **Final solution**: Claude parses `$ARGUMENTS` text, invokes scripts with literal values
9. **Dogfood test**: Updated cig-design.md, successfully invoked with extra text containing special chars

### Evidence
- GitHub issue #4370: Feature request for structured argument parsing
- GitHub issue #5520: Request for multiple argument support
- Both confirm: only `$ARGUMENTS` exists, `$1`/`$2`/`$3` do not exist
- Documentation showing `$1` appears to be outdated/incorrect (issue #8758 referenced but not found)

## Lessons Learned
- Always verify against BOTH documentation AND real-world usage (GitHub issues, examples)
- Test with edge cases (special characters, quotes) early
- Documentation can be outdated or incorrect
- Dogfooding changes incrementally catches issues before full rollout
- When bash is involved, assume input is malicious until proven safe
- LLM text parsing is safer than bash variable expansion for user input
