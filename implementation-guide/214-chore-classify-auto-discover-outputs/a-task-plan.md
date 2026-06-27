# classify auto-discover review outputs - Plan
**Task**: 214 (chore)

## Task Reference
- **Task ID**: internal-214
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/214-classify-auto-discover-outputs
- **Baseline Commit**: cf5131fd011b212d8edacfca0f8fd2bf67b1373b
- **Template Version**: 2.1

## Goal
Add an additive directory/auto-discovery mode to `security-review-classify` so the exec skills classify all reviewer outputs in one invocation, eliminating the per-file shell loop whose `$var` redirect defeats the allowlist and triggers a blocking permission prompt.

## Background
The exec skills (`cwf-implementation-exec`, `cwf-testing-exec`) launch several reviewer subagents, write each verbatim output to its own scratch `*-review-output-<phase>.out` file, then classify **each** by piping it through `security-review-classify < <file>`. "For each launched agent" forces a shell loop with a `$f`-style redirect. That command does not match the allowlist pattern `Bash(.cwf/scripts/command-helpers/security-review-classify:*)`, so Claude Code raises a blocking permission prompt on every exec run. A single invocation that discovers the files itself sidesteps the loop entirely.

## Success Criteria
- [ ] The helper gains a directory/auto-discovery mode that locates the phase's `*-review-output-<phase>.out` files and prints one classification line per file in a stable, parseable form.
- [ ] The existing `stdin → one canonical token` contract is byte-for-byte unchanged (SubagentStop guard hook and single-file callers keep working).
- [ ] A single allowlist-matching invocation classifies every reviewer output with no loop and no `$var` redirect — verified to not raise a permission prompt under the existing allowlist entry.
- [ ] The two exec skills are updated to call the new mode instead of the per-file loop.
- [ ] `t/` test coverage exercises both modes; `cwf-manage validate` passes (script hash refreshed in the same commit).

## Original Estimate
**Effort**: ~0.5 day
**Complexity**: Low
**Dependencies**: None (self-contained helper + two skill docs + hash refresh)

## Major Milestones
1. **Design**: Fix the CLI surface (flag for dir mode + how the phase/dir is named), the file-discovery glob, and the per-file output line format.
2. **Implement**: Add the dir mode to the helper, preserving the stdin path; update both exec skills; refresh the script hash.
3. **Verify**: Tests for both modes; allowlist/no-prompt check; `cwf-manage validate`.

## Risk Assessment
### High Priority Risks
- **Risk 1**: Breaking the stdin contract relied on by the SubagentStop guard hook.
  - **Mitigation**: Dir mode is strictly additive; keep stdin as the default no-arg path; assert byte-identical stdin output in tests.

### Medium Priority Risks
- **Risk 2**: New invocation still fails to match the allowlist pattern (prompt persists).
  - **Mitigation**: Validate the exact command shape against the `:*` allowlist entry during design; the call must be a literal argv with no redirect/var. Confirm no-prompt empirically before close.
- **Risk 3**: Discovery glob misses a reviewer's file or mis-orders output, desyncing skill recording.
  - **Mitigation**: Derive the canonical filename set from the skills; design a deterministic ordering and an explicit "missing file" signal rather than silent omission.

## Dependencies
- External requirements and prerequisites: none.
- Coupling: the canonical `*-review-output-<phase>.out` filenames are defined by the two exec skills — discovery rule and skills must stay in lockstep.

## Constraints
- POSIX/core-Perl only; the helper stays a single self-contained script (no new deps).
- Hash-update convention: refresh `.cwf/security/script-hashes.json` in the same commit as the helper edit.
- Backward compatibility: existing stdin callers and the SubagentStop guard hook must not change behaviour.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: <1 week (~0.5 day) — no decomposition.
- [x] **People**: Single contributor — no decomposition.
- [x] **Complexity**: One helper + two skill docs + hash; one concern — no decomposition.
- [x] **Risk**: Contained, mitigated by additive design — no isolation needed.
- [x] **Independence**: Single cohesive change — no decomposition.

**Verdict**: 0 signals triggered. Proceed as a single task.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five success criteria met. Additive `--dir`/`--phase` discovery mode delivered; stdin contract byte-identical; single allowlist-matching invocation verified prompt-free in this task's own f/g reviews; both exec skills updated; both modes covered by tests; `cwf-manage validate` OK with same-commit hash refresh.

## Lessons Learned
Additive-only design made the backward-compatibility risk a non-event. See j-retrospective.md for the full write-up.
