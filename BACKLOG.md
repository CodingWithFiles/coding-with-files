# CIG System Backlog

Future tasks and improvements for the Code Implementation Guide system.

---

## Task: Rollout Task 11 - Secure Argument Parsing

**Task-Type**: chore
**Priority**: High

Deploy the updated CIG command files with secure argument parsing pattern. All 8 workflow commands (cig-plan, cig-requirements, cig-design, cig-implementation, cig-testing, cig-rollout, cig-maintenance, cig-retrospective) have been updated with LLM-level format validation to prevent command injection. Changes are currently on local branch `bugfix/11-only-pass-needed-args-to-scripts`. Rollout involves creating PR, merging to main, and monitoring for any issues in production usage.

---

## Task: Update cig-subtask.md with Secure Argument Parsing

**Task-Type**: bugfix
**Priority**: Medium

Apply the same secure argument parsing pattern to `cig-subtask.md` that was implemented for the 8 workflow commands in Task 11. This command may use bash expansion with `$ARGUMENTS` and could have the same command injection vulnerability. Requires: (1) Remove inline bash execution, (2) Add LLM argument parsing instructions, (3) Add format validation for task paths, (4) Test with special characters and injection attempts.

---

## Task: Verify and Update cig-status.md

**Task-Type**: bugfix
**Priority**: Medium

Check if `cig-status.md` uses inline bash execution with `$ARGUMENTS` and update if needed. This command takes optional task path argument and may be vulnerable to command injection if using unsafe pattern. If vulnerable, apply same secure argument parsing pattern as Task 11. If already safe, document why and close task.

---

## Task: Threat Model CIG Bash Invocations

**Task-Type**: discovery
**Priority**: Medium

Systematic security review of all bash invocations in the CIG system to identify potential command injection vulnerabilities. Task 11 revealed that LLM-level validation is critical for security. Review all command files, helper scripts, and workflow documentation for places where user input reaches bash. Document threat model with attack scenarios and existing defenses. Create bugfix tasks for any vulnerabilities found.

---

## Task: Complete TC-8 Testing Coverage

**Task-Type**: chore
**Priority**: Low

Test all 7 remaining workflow commands (cig-plan, cig-requirements, cig-design, cig-implementation, cig-rollout, cig-maintenance, cig-retrospective) with special character patterns to complete test coverage. TC-8 was deferred from Task 11 testing phase. While cig-testing was thoroughly tested (TC-1 through TC-7), the other 7 commands should be validated to ensure consistent behaviour. Test with at least one pattern containing quotes, backticks, or shell metacharacters per command.

---

## Task: Submit Claude Code Documentation Fix

**Task-Type**: chore
**Priority**: Low

Submit issue or PR to Claude Code repository to correct documentation showing `$1`, `$2`, `$3` variables that don't actually exist. Official docs at https://code.claude.com/docs/en/slash-commands.md show these variables, but GitHub issues #4370 and #5520 confirm only `$ARGUMENTS` exists. This caused significant time waste during Task 11 implementation. Documentation correction will help future developers avoid this pitfall.

---

## Task: Extract CIG Argument Validation Pattern to Documentation

**Task-Type**: feature
**Priority**: Needs-Triage

Create reusable documentation for the secure argument parsing pattern developed in Task 11. This pattern (LLM validates format → extracts arguments → invokes bash with literals) prevents command injection and handles arbitrary user input safely. Should be documented in `.cig/docs/` for use in future CIG commands or similar systems. Include: (1) Security model explanation, (2) Format validation regex patterns, (3) Example implementation, (4) Test scenarios.

---

## Task: Add --workflow Option to status-aggregator.pl

**Task-Type**: feature
**Priority**: Medium

Add a `--workflow` command line option to `status-aggregator.pl` that provides a status breakdown for all workflow steps (a-plan.md, b-requirements.md, c-design.md, d-implementation.md, e-testing.md, f-rollout.md, g-maintenance.md, h-retrospective.md). Currently, `/cig-status` shows overall task progress (e.g., "25%") but doesn't show which specific workflow files are Finished, In Progress, or Backlog. The --workflow option would display: (1) Status of each workflow file, (2) Current workflow step highlighted, (3) Next recommended action based on progression. This improves visibility into task state and helps identify which phase a task is currently in.

---

## Task: Standardize Exit Codes to errno-Style Values

**Task-Type**: chore
**Priority**: Low

Consolidate exit codes across all CIG helper scripts to use errno-compatible values for better semantic meaning and consistency. Currently, exit codes are inconsistent across scripts (e.g., exit 3 means "Missing required argument" in hierarchy-resolver.pl but "No parent tasks" in context-inheritance.pl). Proposed standard:
- 0 = Success
- 2 = ENOENT (No such file or directory) - for "not found" errors
- 13 = EACCES (Permission denied) - for permission errors
- 22 = EINVAL (Invalid argument) - for validation errors

Scripts to update: hierarchy-resolver.pl, context-inheritance.pl, status-aggregator.pl, format-detector.pl, template-version-parser.sh, and any future helper scripts. Update documentation in script headers and `.cig/docs/` to reflect standard.

---

## Task: Improve status-aggregator.pl Error Message Clarity

**Task-Type**: chore
**Priority**: Low

Improve error message in `status-aggregator.pl` to clarify that it expects a task number (e.g., "17", "1.2.3"), not a full file path. Current error "Invalid task path format: 17-feature-new-helper-script-to-setup-templates-for-new-task" is confusing because users might provide the directory name or full path. Updated error should say something like "Error: Invalid task number format. Expected decimal notation (e.g., '17', '1.2', '1.2.3'), not a file path or directory name." This improves usability by helping users understand the correct input format immediately.

---

## Task: Fix d-implementation.md Template to Reference e-testing.md

**Task-Type**: chore
**Priority**: Low

Remove duplicate "Test Coverage" and "Validation Criteria" sections from d-implementation.md template and replace with static reference to e-testing.md. Currently the d-implementation.md template (`.cig/templates/pool/d-implementation.md.template`) contains:
1. **Line 67-70**: "Test Coverage" section with placeholder test cases
2. **Line 72-76**: "Validation Criteria" section with test-related checkboxes

**Problem**: This creates confusion about where tests belong and duplicates content between d-implementation.md and e-testing.md. The testing phase (e-testing.md) should be the single source of truth for test strategy, test cases, and validation criteria.

**Solution**:
1. Verify all 5 task types (feature, bugfix, hotfix, chore, discovery) use e-testing.md.template (VERIFIED: all include it)
2. Replace "Test Coverage" section with: "**See e-testing.md for complete test plan**"
3. Replace "Validation Criteria" with: "**See e-testing.md for validation criteria and test results**"
4. Keep "Implementation Steps" as-is (includes Step 3: Testing and Step 5: Validation which reference executing the tests defined in e-testing.md)
5. Update any existing tasks using the old template pattern (consider migration script or manual update)

**Rationale**: Maintains single source of truth for testing, eliminates confusion about workflow phase responsibilities, and follows DRY principle.
