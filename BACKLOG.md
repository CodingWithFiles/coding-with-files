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
