# Test context injection syntax - Requirements
**Task**: 55 (discovery)

## Task Reference
- **Task ID**: internal-55
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/55-test-context-injection-syntax
- **Template Version**: 2.1

## Goal
Define what context injection syntaxes must be tested and what constitutes pass/fail for each.

## Functional Requirements

**Note**: Discovery task — FRs define test deliverables rather than software features.

### FR1: Test `!{bash}` Block Syntax in SKILL.md
Create a test skill that uses `!{bash}` to execute a shell command and inject the output into the skill prompt. This is the primary syntax CIG commands use for dynamic context loading (e.g., `!{bash}\n.cig/scripts/command-helpers/context-manager location`).

**Acceptance Criteria**:
- [ ] Test skill created with `!{bash}` block containing a simple command (e.g., `echo` or `date`)
- [ ] Test skill invoked via `/` command
- [ ] Result documented: command output appears in the skill's expanded prompt (PASS) or does not (FAIL)
- [ ] If PASS: test with an actual CIG helper script call to confirm real-world usage works

### FR2: Test `` ! ` `` Backtick Syntax in SKILL.md
Create a test skill that uses the inline backtick context injection syntax (`` ! `command` ``). CIG commands use this for inline dynamic values.

**Acceptance Criteria**:
- [ ] Test skill created with `` ! ` `` inline backtick syntax
- [ ] Test skill invoked via `/` command
- [ ] Result documented: inline output appears in the skill's expanded prompt (PASS) or does not (FAIL)

### FR3: Document Alternative Approaches (if needed)
If either FR1 or FR2 fails, identify how CIG commands could achieve dynamic context in SKILL.md format.

**Acceptance Criteria**:
- [ ] If both syntaxes work: document "no alternatives needed"
- [ ] If either fails: identify at least one alternative approach (e.g., `allowed-tools` with Bash, frontmatter `context:` field, external script reference)

### User Stories
- **As a** CIG maintainer **I want** to know if context injection works in skills **so that** I can plan the command-to-skill conversion with confidence
- **As a** CIG user **I want** skills that dynamically load context **so that** I get the same experience as commands

## Non-Functional Requirements

### NFR1: Evidence Quality
- Each test must produce observable evidence (the expanded skill prompt content or transcript excerpt)
- Results must be unambiguous: PASS, FAIL, or PARTIAL (with explanation)

### NFR2: Test Isolation
- Test skills must not interfere with existing CIG commands or skills
- Test skills must be cleanable (removable after experiment)

## Constraints
- Test only — no modifications to existing CIG commands or skills
- Use `.claude/skills/` directory (skills-only mode, not plugin mode)
- Time-boxed to < 1 hour total

## Decomposition Check
- [ ] **Time**: NO — < 1 hour
- [ ] **People**: NO
- [ ] **Complexity**: NO — 2 syntaxes to test, straightforward
- [ ] **Risk**: NO
- [ ] **Independence**: NO

## Acceptance Criteria
- [ ] AC1: `!{bash}` syntax tested with documented PASS/FAIL result
- [ ] AC2: `` ! ` `` backtick syntax tested with documented PASS/FAIL result
- [ ] AC3: If any syntax fails, at least one alternative documented
- [ ] AC4: All test skills cleaned up after experiment

## Status
**Status**: Finished
**Next Action**: /cig-design-plan 55
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
- AC1: `!{bash}` syntax tested — **FAIL** (raw literal, not expanded)
- AC2: `!` path shorthand tested — **FAIL** (raw literal, not expanded)
- AC3: 4 alternative approaches documented (allowed-tools Bash, thin skill + doc reference, context frontmatter, hybrid)
- AC4: All test skills cleaned up — confirmed via `ls` returning "No such file or directory"

## Lessons Learned
- Clear acceptance criteria with binary PASS/FAIL outcomes made experiment execution straightforward
- FR3 (alternatives) was the most valuable requirement — the expected outcome was always "probably fails"
