# Specify low effort level for exec wf step skills - Testing Plan
**Task**: 187 (chore)

## Task Reference
- **Task ID**: internal-187
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/187-specify-low-effort-level-for-exec-wf-step-skills
- **Template Version**: 2.1

## Goal
Validate that the three frontmatter edits are well-formed and integrity-clean, and document
the one thing integrity tooling cannot prove (that the harness honours `effort`).

## Test Strategy
### Test Levels
This is a documentation/config change (YAML frontmatter on three Markdown files). No code paths
change, so testing is verification-oriented: well-formedness, value validity, and integrity.
- **Static checks**: YAML parses; `effort` value is in the documented set; no `model:` key on
  the exec skills.
- **Integrity check**: `cwf-manage validate` clean (sha256 refreshed, perms at recorded ceiling).
- **Regression**: the two exec skills still resolve/invoke; the security-review subagent still
  spawns and emits its verdict block.

### Test Coverage Targets
- **Critical paths**: 100% — all three edited files and the hash refresh are covered by a TC.
- **Regression**: exec-skill invocation and the security-review subagent path validated.

## Test Cases
### Functional Test Cases
- **TC-1**: `effort: low` present on both exec skills, no `model:` key
  - **Given**: Steps 1 of the implementation plan applied
  - **When**: Inspect the frontmatter of `cwf-implementation-exec/SKILL.md` and
    `cwf-testing-exec/SKILL.md`
  - **Then**: each has a top-level `effort: low` key and NO `model:` key; the rest of the
    frontmatter (`name`, `description`, `allowed-tools`, …) is unchanged

- **TC-2**: `effort: high` present on the security-review agent
  - **Given**: Step 2 applied
  - **When**: Inspect `.claude/agents/cwf-security-reviewer-changeset.md` frontmatter
  - **Then**: a top-level `effort: high` key is present; `name`, `description`, `tools` unchanged

- **TC-3**: All three edited frontmatters are valid YAML and use a documented `effort` value
  - **Given**: Steps 1–2 applied
  - **When**: Parse each file's frontmatter block
  - **Then**: each parses without error; every `effort` value is one of
    `low|medium|high|xhigh|max` (here only `low` and `high` are used)

- **TC-4**: Hash refresh is consistent and `validate` is clean
  - **Given**: Step 2 hash refresh applied and agent file restored to recorded perms `0444`
  - **When**: `sha256sum .claude/agents/cwf-security-reviewer-changeset.md` vs the manifest
    entry, then run `.cwf/scripts/cwf-manage validate`
  - **Then**: the computed digest equals the `.cwf/security/script-hashes.json` entry; `validate`
    reports `OK` (no sha256, no permission violation)

- **TC-5**: Same-commit discipline for the hashed file
  - **Given**: the implementation-exec checkpoint commit
  - **When**: `git show --stat` the commit that edits the agent file
  - **Then**: that same commit also contains the `.cwf/security/script-hashes.json` change
    (the refresh is not deferred to a later commit)

- **TC-6 (regression)**: Exec skills and the security-review subagent still function
  - **Given**: edits applied and committed
  - **When**: the exec skills are resolvable and the `cwf-security-reviewer-changeset` subagent
    is invoked on a non-empty changeset
  - **Then**: both skills load without a frontmatter error and the subagent still returns its
    machine-parseable `cwf-review` verdict block (the `effort: high` key does not break parsing)

### Non-Functional Test Cases
- **Security**: TC-4/TC-5 are the security-relevant checks — the integrity manifest stays
  consistent and the FR4(a–e) reviewer is pinned at `effort: high` so the review is never
  downgraded. No new attack surface (no code, no shell, no env-var reads).

## Test Environment
### Setup Requirements
- The task working tree on branch `chore/187-…`; no test database or external services needed.
- `cwf-manage` available at `.cwf/scripts/cwf-manage`.

### Automation
- Static/integrity checks are one-shot commands run in g-testing-exec; no CI wiring added.

## Validation Criteria
- [ ] TC-1 … TC-6 all PASS
- [ ] `cwf-manage validate` reports `OK`
- [ ] No `model:` key introduced on the exec skills
- [ ] Known limitation acknowledged: a clean `validate` does NOT prove the harness honours
      `effort`; the only positive evidence is an observable behaviour change on a real exec run
      (recorded as an observation, not a blocking gate)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All six test cases executed in g-testing-exec.md — TC-1…TC-6 PASS.

## Lessons Learned
For a docs/config change, verification-oriented TCs (well-formedness, value validity, integrity,
same-commit discipline, regression) are the right shape — there is no code path to unit-test.
