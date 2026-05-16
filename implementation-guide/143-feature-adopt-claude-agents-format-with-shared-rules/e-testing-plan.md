# Adopt .claude/agents format with shared rules - Testing Plan
**Task**: 143 (feature)

## Task Reference
- **Task ID**: internal-143
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/143-adopt-claude-agents-format-with-shared-rules
- **Template Version**: 2.1

## Goal
Verify each acceptance criterion from `b-requirements-plan.md` with a concrete test, prove the SKILL classifier contracts survive the migration, and exercise the install lifecycle in a scratch repo.

## Test Strategy
### Test Levels

- **Source-tree static checks** (run in this repo): grep / glob / `cwf-manage validate` against the just-modified files. Catch frontmatter shape, namespace prefix, anti-pattern grep verification, integrity-ledger registration.
- **Source-tree end-to-end smoke** (run in this repo): invoke the migrated `cwf-plan-reviewer` and `cwf-security-reviewer-changeset` agents via the Agent tool against this task's own plan files and against a known-good/known-bad changeset. Catch sentinel-line contract, prompt-injection guard (manual review), and the no-permission-prompt property.
- **Scratch-repo install lifecycle** (run in a fresh repo under `/tmp`): clean install + update + simulated rename + uninstall. Catch FR1-install ACs (materialise, propagate updates, leave non-CWF files alone).
- **Manual code review** (no automation): AC4c prompt-injection guard. Recorded in `g-testing-exec.md` per the verification protocol in `b-requirements-plan.md` § AC4c.

### Test Coverage Targets
- Every requirement AC in `b-requirements-plan.md` § "Acceptance Criteria" has at least one test case below that exercises it. Use the AC label as the test case label so traceability is by-name.
- All listed test cases pass before checkpoint commit on `g-testing-exec.md`.
- No regression in existing CWF skill / workflow behaviour: `cwf-manage validate` continues to exit 0; `cwf-status 143` continues to return correct state.

## Test Cases

### TC-AC1 — Agent definitions exist and are referenced (FR1)

- **Given**: Implementation phase completed; agent files written under `.claude/agents/`.
- **When**: Run `ls .claude/agents/cwf-*.md` and `git grep -n 'subagent_type' .claude/skills/ .cwf/docs/skills/`.
- **Then**: Exactly five files present (`cwf-plan-reviewer-improvements.md`, `cwf-plan-reviewer-misalignment.md`, `cwf-plan-reviewer-robustness.md`, `cwf-plan-reviewer-security.md`, `cwf-security-reviewer-changeset.md`); no in-scope grep hit for `subagent_type="Explore"`; every in-scope `subagent_type=...` reference names one of the five `cwf-*` roles.

### TC-AC1-namespace-files — Namespace prefix on every CWF agent file

- **Given**: `.claude/agents/` populated post-implementation.
- **When**: `ls .claude/agents/ | grep -v '^cwf-' | head` and inspect output.
- **Then**: No CWF-authored file appears in the output (any output represents either non-CWF user files — which is the property we're protecting — or a defect).

### TC-AC1-namespace-refs — SKILL-side role names are literals

- **Given**: SKILLs migrated.
- **When**: `git grep -nE 'subagent_type\s*=\s*"\$\{|subagent_type\s*=\s*\$\{|subagent_type\s*=\s*\{' .claude/skills/ .cwf/docs/skills/`.
- **Then**: Zero matches. Any match would indicate a SKILL constructing the role name from a substitution variable — forbidden per AC1-namespace-refs.

### TC-AC1-install — Clean install materialises agents (scratch repo)

- **Given**: A fresh `/tmp/cwf-test-143-install` repo (`git init`, single empty commit); upstream CWF at the merged HEAD of this task.
- **When**: Run `cwf-manage install` (or whatever the documented entry-point becomes — `cwf-manage update` against a clean target is the same code path). Observe `ls -l .claude/agents/cwf-*.md`.
- **Then**: All five symlinks present (`cwf-plan-reviewer-{improvements,misalignment,robustness,security}.md` + `cwf-security-reviewer-changeset.md`), each pointing to `../../.cwf-agents/cwf-*.md`; every target resolves via `readlink -f` to a real file inside `.cwf-agents/`; `cwf-manage validate` exits 0; the Agent tool can successfully invoke `subagent_type=cwf-security-reviewer-changeset` and `subagent_type=cwf-plan-reviewer-security` with trivial prompts.

### TC-AC1-update — Update propagates agent changes

- **Given**: Scratch repo from TC-AC1-install. Switch upstream CWF source to a synthetic later commit that renames one of the agent files — e.g. `cwf-plan-reviewer-improvements.md` → `cwf-plan-reviewer-improvements-v2.md`.
- **When**: Run `cwf-manage update`.
- **Then**: Stale symlink `.claude/agents/cwf-plan-reviewer-improvements.md` is gone; new symlink `cwf-plan-reviewer-improvements-v2.md` is present; the other four agent symlinks are unchanged; `.cwf-agents/` staging tree reflects the rename; `cwf-manage validate` exits 0.

### TC-AC1-cleanup-stale — Update does not touch non-CWF files

- **Given**: Scratch repo from TC-AC1-install. Manually create `.claude/agents/my-foo.md` (regular file, not a symlink, no `cwf-` prefix) and `.claude/agents/cwf-userlocal.md` (regular file, `cwf-` prefix but NOT a symlink — simulates a user file that happens to collide with the CWF namespace).
- **When**: Run `cwf-manage update`.
- **Then**: `my-foo.md` is untouched (verifies the cleanup loop's prefix-gated scope); `cwf-userlocal.md` triggers the conflict-check from design D2 — `cwf-manage update` aborts with the documented error mentioning the path and remediation; no symlink for a CWF agent of the same name was silently overwritten.

### TC-AC2 — Single shared-rules surface (FR2)

- **Given**: `cwf-agent-shared-rules.md` written; agent files migrated.
- **When**: `git grep -l 'cwf-agent-shared-rules.md' .claude/agents/` and `wc -l .cwf/docs/skills/cwf-agent-shared-rules.md`; also grep each agent file for duplicated shared-rules content.
- **Then**: Each CWF agent file contains exactly one link to the shared-rules file; the shared-rules file contains the inclusion-bar paragraph (per AC2c); no agent file restates the tool-tier rubric or anti-patterns table.

### TC-AC3a — Blocking anti-patterns named in shared rules

- **Given**: `cwf-agent-shared-rules.md` exists.
- **When**: Grep the file for each of the four blocking-pattern strings: `find … -exec grep`, `find … -exec cat`, `cat … | grep`, `sed -n 'X,Yp'` (use loose patterns: `-exec`, `\| grep`, `sed -n`).
- **Then**: Each blocking pattern is present and each has a "use this instead" sibling line within the same table row or list item.

### TC-AC3b — No permission-prompt on real run

- **Given**: Migrated agent files; CWF source repo or a scratch repo.
- **When**: Invoke `cwf-security-reviewer-changeset` on a real implementation-phase changeset (use this task's own diff up to the checkpoint commit). Invoke at least two distinct `cwf-plan-reviewer-<column>` roles (e.g. `…-improvements` + `…-security`, to cover both the improvements-style and security-style criteria) on a representative plan file from a prior task. All runs use the declared `Read`/`Grep`/`Glob` tool grant only.
- **Then**: No run triggers a blocking permission-prompt for `find -exec`, `cat | grep`, `sed -n 'X,Yp'`, or `find -exec cat`. If any prompt fires, classify as a defect, fix the agent body or shared-rules, and re-run.

### TC-AC4a — Explicit allowed-tools list on every agent

- **Given**: Agent files written.
- **When**: For each `.claude/agents/cwf-*.md`, parse the YAML frontmatter (Perl `YAML::Tiny` is NOT core — use a hand-roll line-scan or `python3 -c 'import yaml,sys; print(yaml.safe_load(sys.stdin)["allowed-tools"])'`).
- **Then**: Every file has an `allowed-tools:` (or whatever exact spelling Claude Code's schema uses at implementation time — see Constraint in `b-requirements-plan.md`) frontmatter key with a non-empty list.

### TC-AC4b — No Bash/Edit/Write in review agents

- **Given**: Agent files written.
- **When**: Grep each agent's `allowed-tools` block for `Bash`, `Edit`, `Write`.
- **Then**: Zero matches. (If a future agent needs Bash, this test will fail and force a deliberate decision.)

### TC-AC4c — Prompt-injection guard (manual review)

- **Given**: Agent files written.
- **When**: Reviewer (human) reads each agent body and inventories every `{...}` substitution.
- **Then**: Record per substitution in `g-testing-exec.md`: (i) the token; (ii) the SKILL that substitutes it; (iii) why the value is advisory (e.g. `{plan_file_path}` is a file path; the agent reads the file; the path content is not used to decide which tool to call); (iv) reviewer sign-off. No substitution drives tool selection, conditional logic, or role choice.

### TC-AC4d — No env-var reads in agents

- **Given**: Agent files written.
- **When**: `git grep -E '\$ENV|\$[A-Z_][A-Z0-9_]*' .claude/agents/cwf-*.md`.
- **Then**: Zero non-illustrative matches. Any literal `$ENV{...}` or `$VAR` in agent body is forbidden by FR4 / AC4d. (False positives in example code blocks are acceptable if clearly marked as illustrative; record any in `g-testing-exec.md`.)

### TC-AC5a — Exec-phase sentinel contract preserved

- **Given**: Migrated `cwf-security-reviewer-changeset`; two test inputs: (i) a known-clean changeset (e.g. a docs-only commit), (ii) a known-dirty changeset (e.g. a synthetic perl file that newline-splits `qx{git ls-files}` — a clear FR4(b) hit).
- **When**: Invoke the agent on each input via the Agent tool.
- **Then**: Each response's first non-blank line is one of `findings:`, `no findings`, `error:` (matches the three-tier classifier in `cwf-implementation-exec/SKILL.md`); the clean run returns `no findings`; the dirty run returns `findings:` with a numbered list naming the FR4(b) violation.

### TC-AC5b — Plan-review REDUCE step end-to-end

- **Given**: All four migrated `cwf-plan-reviewer-<column>` agents; a representative plan file (this task's own `c-design-plan.md`, or any prior task's design plan).
- **When**: Invoke a SKILL's plan-review (e.g. trigger `/cwf-design-plan 143` against the unchanged design plan, which fires all four parallel `subagent_type=cwf-plan-reviewer-<column>` calls then REDUCE).
- **Then**: The REDUCE step completes without error; the parent agent synthesises findings (or "no changes needed") and applies edits if any. Compare against a baseline run before the migration to confirm the synthesis behaviour didn't change shape.

### TC-AC6a — `cwf-manage validate` passes

- **Given**: All file edits from Steps 1-5 of `d-implementation-plan.md` complete; `script-hashes.json` updated.
- **When**: Run `.cwf/scripts/cwf-manage validate`.
- **Then**: Exit 0. Any non-zero exit blocks the checkpoint commit on `g-testing-exec.md`.

### TC-AC6b — `.claude/agents/` covered by security-review-changeset

- **Given**: `security-review-changeset` updated with the new prefix.
- **When**: Run `.cwf/scripts/command-helpers/security-review-changeset --phase=implementation` on the current branch's diff.
- **Then**: Output includes each `.claude/agents/cwf-*.md` file modified by this task. The helper does NOT silently skip them.

### TC-AC6c — Shared-rules file in integrity ledger

- **Given**: `script-hashes.json` updated.
- **When**: Grep `.cwf/security/script-hashes.json` for `cwf-agent-shared-rules`.
- **Then**: Exactly one entry; entry has `path: ".cwf/docs/skills/cwf-agent-shared-rules.md"`, `permissions: "0444"`, and a non-placeholder sha256 matching `sha256sum` output on the file.

### TC-Regression — Existing workflow continues to function

- **Given**: All migration changes complete.
- **When**: Run `cwf-status 143`, `cwf-manage validate`, and a sample workflow phase (e.g. `/cwf-task-plan <some-prior-task>` re-execution check).
- **Then**: All three return their pre-migration behaviour: status is accurate, validate exits 0, the workflow phase loads without errors.

### TC-NFR2-failure — Non-existent role surfaces an error

- **Given**: Migration complete.
- **When**: Construct a one-off SKILL invocation that requests `subagent_type=cwf-nonexistent-role` and observe the Agent tool's response.
- **Then**: The invocation fails with whatever clear error Claude Code emits (file-not-found or schema-mismatch); the error MUST surface to the user. Record the exact error text in `g-testing-exec.md` to confirm there's no silent fallback to a different role (per NFR2).

## Test Environment

### Setup Requirements
- **Source-tree tests** (TC-AC1, TC-AC1-namespace-*, TC-AC2 through TC-AC6c, TC-NFR2): run in this CWF source repo on `feature/143-...` branch after implementation execution.
- **Scratch-repo tests** (TC-AC1-install, TC-AC1-update, TC-AC1-cleanup-stale): require `/tmp/cwf-test-143-*` directories with `git init` and an upstream CWF source pointing to this task's HEAD. Use `CWF_SOURCE=$(pwd)` env-var from the source repo to point `cwf-manage` at the local clone. Clean up `/tmp/cwf-test-143-*` after each test.
- **No mocks, no test doubles**: every test exercises real code, real file system, real Agent invocations. Per project rule: "Testing that interacts with a database must always use a test database" — analogous here is the scratch-repo isolation for install tests.

### Automation
- All tests run manually during `cwf-testing-exec` (g phase). No CI/CD integration in scope for this task — CWF is a documentation/skill system, not a CI-driven codebase.
- Each test case has a single bash invocation or a sequence of ≤5 commands; record exact commands run in `g-testing-exec.md` so retrospective can audit.

## Validation Criteria
- [ ] Every AC from `b-requirements-plan.md` has a matching TC label above that passed.
- [ ] `cwf-manage validate` exits 0.
- [ ] Sentinel-line contract preserved (TC-AC5a).
- [ ] No blocking permission-prompts in agent runs (TC-AC3b).
- [ ] Scratch-repo install / update / cleanup tests pass (TC-AC1-install, TC-AC1-update, TC-AC1-cleanup-stale).
- [ ] No regression in existing CWF workflow behaviour (TC-Regression).

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
