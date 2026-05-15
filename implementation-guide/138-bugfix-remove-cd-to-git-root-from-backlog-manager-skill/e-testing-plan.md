# Remove cd to git root from backlog-manager skill - Testing Plan
**Task**: 138 (bugfix)

## Task Reference
- **Task ID**: internal-138
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/138-remove-cd-to-git-root-from-backlog-manager-skill
- **Template Version**: 2.1

## Goal
Confirm that the edits applied in `f-implementation-exec` (a) remove every targeted occurrence, (b) leave `.claude/skills/cwf-backlog-manager/SKILL.md` syntactically clean, (c) keep every rewritten example executable, and (d) do not perturb anything else in the repo.

## Test Strategy
This is a documentation/skill edit. There is no compiled artefact, no Perl module, no helper-script change. The "tests" are a sequence of greps and two smoke-test invocations of the helper from the repo root, all run by hand in `g-testing-exec`. No new automated test files are added.

### Test Levels
- **Static (grep) checks**: presence/absence of literal strings in the edited file and the surrounding tree.
- **Smoke-test invocations**: run two rewritten examples (`list`, `validate --all`) verbatim from the repo root and check exit codes.
- **System integrity**: `cwf-manage validate` and `cwf-security-check verify` clean (sanity, since the change is outside `.cwf/`).

### Test Coverage Targets
- 100% of targeted strings removed (8 prefix instances + 1 paragraph + 1 checkbox).
- 100% of retained examples in the file remain executable (verified by running 2 of the 8 — `list` and `validate --all` — as representative read-only subcommands; the prefix is identical across all 8 so a single passing case is strong evidence for the others).

## Test Cases

### Functional / Static (Grep) Tests

- **TC-1**: Prefix fully stripped from the skill file
  - **Given**: f-implementation-exec has run all three Edit calls.
  - **When**: `grep -n 'git rev-parse --show-toplevel' .claude/skills/cwf-backlog-manager/SKILL.md`
  - **Then**: zero matches; non-zero exit code from grep.

- **TC-2**: Threat-model paragraph fully removed
  - **Given**: Edit 1 has run.
  - **When**: `grep -n 'Mandatory pre-step\|guards against working-directory pivots' .claude/skills/cwf-backlog-manager/SKILL.md`
  - **Then**: zero matches.

- **TC-3**: Success-Criteria checkbox removed; the other two are retained verbatim
  - **Given**: Edit 3 has run.
  - **When**: Read lines from `## Success Criteria` to end of file.
  - **Then**: exactly two checkboxes remain: "Arguments passed as separate Bash array elements (list form), not interpolated string" and "Helper exit code observed; user informed of failure if non-zero". No checkbox referencing `cd` or `git-root`.

- **TC-4**: No collateral damage repo-wide
  - **Given**: All edits applied.
  - **When**: `grep -rn 'git rev-parse --show-toplevel\|Mandatory pre-step' .claude/ docs/ .cwf/`
  - **Then**: exactly one match remains — `.claude/skills/cwf-init/SKILL.md:87` (`GIT_ROOT="$(git rev-parse --show-toplevel)"`), which is out of scope.

- **TC-5**: No double blank lines or other markdown structural damage
  - **Given**: All edits applied.
  - **When**: Read lines 14-20 of the edited file.
  - **Then**: pattern is `## Context` → blank → `**Helper path**: ...` → blank → `## Subcommands`. No consecutive blank lines anywhere in the file (`grep -Pzo '\n\n\n' SKILL.md` exits non-zero / no match).

### Smoke-Test (Behavioural) Tests

- **TC-6**: Rewritten `list` example executes from repo root
  - **Given**: cwd is `/home/matt/repo/coding-with-files`. All edits applied.
  - **When**: `.cwf/scripts/command-helpers/backlog-manager list` (copy-paste from the post-edit SKILL.md).
  - **Then**: exit code 0; output begins with `## Very High` (or whatever the current top priority band is — non-empty output is sufficient).

- **TC-7**: Rewritten `validate --all` example executes from repo root
  - **Given**: cwd is repo root. All edits applied.
  - **When**: `.cwf/scripts/command-helpers/backlog-manager validate --all`
  - **Then**: exit code 0; no errors reported (or only the pre-existing warnings that exist on `main` today — a baseline diff, not an absolute zero).

- **TC-8** *(negative — confirms the runtime invariant the deleted checkbox used to encode)*: Running the rewritten example from outside the repo fails loudly
  - **Given**: cwd is `/tmp`. The repo's `.cwf/scripts/command-helpers/backlog-manager` exists at its real path but `/tmp/.cwf/scripts/command-helpers/backlog-manager` does not.
  - **When**: `cd /tmp && .cwf/scripts/command-helpers/backlog-manager list`
  - **Then**: bash reports "No such file or directory"; exit code 127. This confirms the design-phase claim that the relative-path invocation form is self-anchoring; ENOENT is the safe failure mode.

### System-Integrity Tests

- **TC-9**: CWF installation validates clean
  - **When**: `.cwf/scripts/cwf-manage validate`
  - **Then**: exit code 0.

- **TC-10**: Script-hash manifest unaffected
  - **When**: `.cwf/scripts/cwf-manage status` (or the equivalent integrity-check entry point — confirm at exec time).
  - **Then**: no hash drift reported. (Sanity check — the change is outside `.cwf/`, so this should be a no-op, but worth running.)

## Test Environment

### Setup Requirements
- Working tree is the task branch `bugfix/138-remove-cd-to-git-root-from-backlog-manager-skill` with all three Edit calls applied.
- cwd for TC-1..TC-7, TC-9, TC-10 is the repo root.
- cwd for TC-8 is `/tmp` (or any directory outside the repo that contains no `.cwf/` subtree).
- No mocks, fixtures, or external services required.

### Automation
- All test cases are manual one-liners; no test runner is wired up for this task.
- No CI changes.

## Validation Criteria
- [ ] TC-1 through TC-5 (static checks) all pass
- [ ] TC-6 and TC-7 (smoke tests) exit 0
- [ ] TC-8 (negative test) exits 127 with ENOENT message — confirms self-anchoring claim
- [ ] TC-9 (`cwf-manage validate`) exits 0
- [ ] TC-10 reports no hash drift

## Decomposition Check
No new test files, no new fixtures, no new test infra. Decomposition not relevant.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 138
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled in g-testing-exec*

## Lessons Learned
*To be captured during implementation*
