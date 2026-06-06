# Harden security-review-changeset agent contract - Plan
**Task**: 182 (feature)

## Task Reference
- **Task ID**: internal-182
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/182-harden-security-review-changeset-agent-contract
- **Baseline Commit**: 115d27084887827736520313056f0d435e7f70db
- **Template Version**: 2.1

## Goal
Make `security-review-changeset` a one-command, agent-friendly tool that self-manages its output file and reports what it did, so agents stop bolting on ad-hoc `> /tmp/…; echo EXIT=$?; wc -l; grep …` boilerplate.

## Success Criteria
- [ ] **SC1 (flag rename)**: Script accepts `--wf-step=<step>`; `--phase=` is removed (not aliased).
- [ ] **SC2 (default cap)**: `--max-lines` defaults to 500 and stays overridable; omitting it caps at 500 (was: no cap).
- [ ] **SC3 (self-managed output)**: Script creates the canonical per-task tmp dir (`mkdir -m 0700`) and writes the changeset to `<tmp>/security-review-changeset-<wf-step>.out`.
- [ ] **SC4 (stdout confirmation)**: Script prints the output path and its line count in one line; the agent needs no follow-up `wc`/`cat`/`grep`.
- [ ] **SC5 (invocation contract)**: Skill/agent docs instruct the exact form `.cwf/scripts/command-helpers/security-review-changeset --wf-step={wf_step}` with no surrounding boilerplate, and an output-level grep confirms no stale `--phase`/`--max-lines=500` examples remain.

## Original Estimate
**Effort**: ~1 day
**Complexity**: Medium (behavioural change to a hashed, multi-caller script)
**Dependencies**: tmp-paths convention, hash-updates convention, script-hashes.json, exec-phase skills + security-review-changeset agent doc

## Major Milestones
1. **Requirements/design settled**: authoritative `--wf-step` value set, task-num derivation strategy, and exact output/stdout contract.
2. **Script changed**: flag rename, default cap, self-managed file output, stdout confirmation; hash refreshed in the same commit.
3. **Docs/contract updated**: exec-phase skills + agent doc carry the exact one-command invocation; stale examples removed.
4. **Tested**: option-parsing/output unit coverage + output-level grep for stale invocation examples.

## Risk Assessment
### High Priority Risks
- **R1 — Default cap changes behaviour**: today, omitting `--max-lines` means *no cap*; defaulting to 500 means previously-passing large changesets newly exit 2.
  - **Mitigation**: settle exit-code semantics in requirements; document the change; confirm with the maintainer before coding.
- **R2 — wf-step value scope**: the script self-describes as *exec-phase* (implementation/testing) only, but the requested examples include plan phases (requirements-plan, design-plan), where there may be no code diff yet.
  - **Mitigation**: define the authoritative wf-step set and whether plan-phase invocations are valid *before* implementation; this is the key open question.

### Medium Priority Risks
- **R3 — task_num derivation**: a clean `--wf-step`-only contract requires the script to self-derive the task number (task-stack/branch); detached/ambiguous state could misroute output.
  - **Mitigation**: deterministic derivation with explicit failure when it cannot be resolved; keep `--task-num` as an override.
- **R4 — /tmp write surface**: writing into `/tmp` is a symlink-attack surface.
  - **Mitigation**: reuse the canonical tmp-paths `mkdir -m 0700` first-use guard verbatim.
- **R5 — Hashed-script edit**: changing the script requires a same-commit hash refresh.
  - **Mitigation**: plan-time disclosure per hash-updates convention; refresh in the implementation-exec commit.

## Dependencies
- `.cwf/docs/conventions/tmp-paths.md` (output path form + mkdir guard)
- `.cwf/docs/conventions/hash-updates.md` + `.cwf/security/script-hashes.json`
- Callers/docs: `cwf-implementation-exec`, `cwf-testing-exec` skills; the `security-review-changeset` / `cwf-security-reviewer-changeset` agent definition

## Constraints
- Perl core-only; POSIX; no `--no-verify`
- Hashed-file change → hash refresh in the same task and commit
- Recorded-permissions ceiling on the script (chmod to recorded value after edit)

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — ~1 day.
- [ ] **People**: Does this need >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — one script plus its docs/tests.
- [ ] **Risk**: High-risk components needing isolation? No — bounded behavioural change with hash refresh.
- [ ] **Independence**: Parts worked on separately? No.

**Conclusion**: 0 signals triggered. No decomposition; proceed as a single task.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five success criteria (SC1–SC5) met. 0 decomposition signals held — delivered as a single task. See `j-retrospective.md` for variance analysis and `f`/`g` for execution detail.

## Lessons Learned
The "single script + its docs/tests" framing under-counted the blast radius: the file-output model forced a four-site consumer migration. Captured in the retrospective; future scoping should trace stdout-contract consumers at plan time.
