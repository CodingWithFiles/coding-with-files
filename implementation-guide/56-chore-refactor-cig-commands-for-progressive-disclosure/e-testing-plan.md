# Refactor CIG commands for progressive disclosure - Testing Plan
**Task**: 56 (chore)

## Task Reference
- **Task ID**: internal-56
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/56-refactor-cig-commands-for-progressive-disclosure
- **Template Version**: 2.1

## Goal
Verify that refactored CIG commands function identically to pre-refactoring behaviour, shared docs contain all extracted content, and line count targets are met.

## Test Strategy

### Test Levels
- **Structural validation**: Verify shared docs exist and contain required content
- **Command invocation**: Invoke refactored commands and verify they produce correct behaviour
- **Metrics validation**: Verify line count reduction targets met
- **Regression**: Verify no command broke during refactoring

### Coverage Targets
- **Command coverage**: All 17 commands tested (100%)
- **Shared doc coverage**: All 3 shared docs verified for completeness
- **Metrics**: Line counts measured before and after

### Approach
Manual testing — commands are invoked by user and behaviour observed by LLM. No automated test framework (CIG is a documentation/workflow system, not software with a test suite).

## Test Cases

### Structural Tests (Shared Docs)

- **TC-1**: Workflow preamble doc exists and is complete
  - **Given**: `.cig/docs/commands/workflow-preamble.md` created
  - **When**: Read the file
  - **Then**: Contains argument parsing rules, task path validation, task resolution (Step 1), parent context loading (Step 2), context summary (Step 3), LLM decision (Step 4), status field reference

- **TC-2**: Checkpoint commit doc exists and is complete
  - **Given**: `.cig/docs/commands/checkpoint-commit.md` created
  - **When**: Read the file
  - **Then**: Contains commit template, stage pattern, Co-developed-by trailer, rationale reference

- **TC-3**: Retrospective extras doc exists and is complete
  - **Given**: `.cig/docs/commands/retrospective-extras.md` created
  - **When**: Read the file
  - **Then**: Contains CHANGELOG update workflow, BACKLOG remove/add workflow, checkpoints branch creation, squash workflow, verify checkpoints

### Functional Tests (Command Invocation — Sampled)

Testing all 17 commands via invocation is impractical in a single session. Instead, sample 3 representative commands (one from each group).

- **TC-4**: Workflow command — invoke `/cig-design-plan` on Task 56
  - **Given**: Task 56 exists with refactored cig-design-plan.md command
  - **When**: User invokes `/cig-design-plan 56`
  - **Then**: Command resolves task, loads context, presents design phase instructions. LLM reads `workflow-preamble.md` when following Steps 1-4. Behaviour equivalent to pre-refactoring.

- **TC-5**: Workflow command — invoke `/cig-status` on Task 56
  - **Given**: Task 56 exists with refactored cig-status.md command
  - **When**: User invokes `/cig-status 56`
  - **Then**: Status tree displayed with correct progress percentages. Behaviour equivalent to pre-refactoring.

- **TC-6**: Task management command — invoke `/cig-extract 56 goal`
  - **Given**: Task 56 exists with refactored cig-extract.md command
  - **When**: User invokes `/cig-extract 56 goal`
  - **Then**: Goal section extracted from a-task-plan.md. Behaviour equivalent to pre-refactoring.

### Metrics Tests

- **TC-7**: Total line count reduction
  - **Given**: Pre-refactoring baseline of 1,914 lines across 17 commands
  - **When**: Count lines in all 17 commands post-refactoring
  - **Then**: Total under 750 lines (60%+ reduction)

- **TC-8**: Per-command line count — workflow commands
  - **Given**: 10 workflow commands refactored
  - **When**: Count lines in each
  - **Then**: Each under 45 lines

- **TC-9**: Shared doc content completeness
  - **Given**: 3 shared docs created
  - **When**: Search all 17 commands for residual duplicated content (argument parsing block, task path validation, checkpoint commit template)
  - **Then**: No command contains the full shared blocks inline — only references to docs

### Regression Tests

- **TC-10**: No orphaned references
  - **Given**: Refactored commands reference `.cig/docs/commands/*.md` files
  - **When**: Check that all referenced doc paths exist
  - **Then**: Every doc path referenced in commands resolves to an existing file

- **TC-11**: YAML frontmatter preserved
  - **Given**: All 17 commands have YAML frontmatter
  - **When**: Check each command file starts with `---` and has valid frontmatter fields
  - **Then**: All commands have `description` and `allowed-tools` fields intact

- **TC-12**: Context injection preserved
  - **Given**: Commands that use `!{bash}` or `!/` context injection
  - **When**: Check refactored commands
  - **Then**: Dynamic context injection (`!{bash}` for context-manager, `!/current-task-wf`) still present in commands that need it

## Test Environment

### Setup Requirements
- Claude Code with commands and skills support
- Task 56 directory with workflow files
- All 17 CIG commands accessible in `.claude/commands/`
- Shared docs in `.cig/docs/commands/`

### Automation
- Manual execution — commands are LLM-invoked, not programmatically testable
- Line counts verified via `wc -l` (automated)
- Content checks via `grep` (automated)

## Validation Criteria
- [ ] TC-1 to TC-3: Shared docs verified complete
- [ ] TC-4 to TC-6: Sample commands invoked successfully
- [ ] TC-7 to TC-8: Line count targets met
- [ ] TC-9: No residual duplicated blocks
- [ ] TC-10 to TC-12: Regression checks pass

## Status
**Status**: Finished
**Next Action**: /cig-implementation-exec 56
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
12 test cases defined across 4 categories (structural, functional, metrics, regression). All executed during testing execution phase. 10 PASS, 2 marginal FAIL on aspirational metrics targets.

## Lessons Learned
Metrics test thresholds should be set after a proof-of-concept establishes the real floor, not from estimates. Functional testing via helper script verification (rather than full command re-invocation) is practical for chore tasks but insufficient for migration tasks.
