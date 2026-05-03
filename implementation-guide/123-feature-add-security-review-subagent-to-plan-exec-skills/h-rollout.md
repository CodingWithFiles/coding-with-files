# Add security-review subagent to plan/exec skills - Rollout
**Task**: 123 (feature)

## Task Reference
- **Task ID**: internal-123
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/123-add-security-review-subagent-to-plan-exec-skills
- **Template Version**: 2.1

## Deployment Strategy

**Strategy**: Immediate — single-developer internal tool; docs-and-skills only (no scripts, no `.cwf/security/script-hashes.json` change). Mirrors the standard CWF self-development rollout (Tasks 117, 118, 122 — chore/docs precedents; Task 119 for the feature template).

**Deployment**:
- One new doc (`.cwf/docs/skills/security-review.md`), three doc/skill edits (`.cwf/docs/skills/plan-review.md`, `.claude/skills/cwf-implementation-exec/SKILL.md`, `.claude/skills/cwf-testing-exec/SKILL.md`), one CHANGELOG entry. All on the task branch; deployed by the human-driven fast-forward of `main` after the retrospective squash.
- No data migration. The new behaviour fires on the next invocation of any plan SKILL (4th subagent now appears in the map/reduce) and on the next invocation of either exec SKILL (Step 8 runs).
- Existing in-progress tasks on disk are unaffected — the only state the new code touches is the wf step file *being written by the current invocation*.

**Rollback**: Single-commit revert. The change is one logical unit (1 new doc + 3 edits + 1 CHANGELOG line block); reverting the squashed `Task 123:` commit on `main` restores the prior 3-subagent map/reduce and removes Step 8 from both exec SKILLs. No external state to undo.

**Breaking change**: Yes (mild) — both `cwf-implementation-exec` and `cwf-testing-exec` now require the `Agent` tool to be available, and both run an additional Agent call as part of Step 8. Cost: one extra Explore-tier Agent invocation per phase per task. Documented in CHANGELOG.

## Pre-Deployment Checklist
- [x] All 15 functional + 4 non-functional + TC-AC8 dogfood test cases pass (g-testing-exec.md)
- [x] `cwf-manage validate` clean (no script-hash drift since the task touches no `.cwf/scripts/` or `.cwf/lib/` files)
- [x] Strict 3→4 grep on plan-review.md returns zero matches
- [x] Both exec SKILLs have `- Agent` in `allowed-tools` and Steps 5/6/7/8/9/10 in sequence
- [x] Verbose pathspec list lives only in the canonical doc (runtime); workflow plan files mention it descriptively, which is expected
- [x] BACKLOG entry "Add Security Verification to Testing Workflow" untouched (separate `cwf-manage validate` concern)
- [x] CHANGELOG Task 123 entry added during f-implementation-exec (commit `a9ff0d6`); retrospective will reconcile any further updates

## Monitoring
- Next invocation of any plan SKILL (`/cwf-requirements-plan`, `/cwf-design-plan`, `/cwf-implementation-plan`) exercises the 4-subagent map/reduce.
- Next invocation of either exec SKILL exercises Step 8 (Security Review). Token-cost regression visible immediately as one extra Agent call per phase.
- The three-tier classifier's behaviour is observable in the wf step file's `## Security Review` section: a `**State**: findings` with substantively-no-findings body (as observed in TC-AC8) signals subagents are not complying with the sentinel-line-first rule. Track frequency over the next few feature tasks; if persistent, the prompt template should be tightened (noted as retrospective follow-up).
- No separate monitoring infrastructure needed.

## Rollback Triggers
- Step 8 produces consistent `error:` classifications across multiple tasks (signals a wiring issue in the prompt template or pathspec).
- Token cost per task rises beyond an acceptable budget (one extra Agent call per phase × two phases ≈ 2 Agent calls per task; if this is found unacceptable, the rollback strategy is to revert Step 8 in exec SKILLs while keeping the plan-phase 4th subagent — partial rollback is feasible because the two integration points are independent).
- Subagent's read-only allowlist is found to be insufficient for legitimate review (no current evidence; would require re-design rather than rollback).

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance 123
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*Captured per phase above*

## Lessons Learned
Partial-rollback strategy was worth documenting even on a docs-only task: the plan-phase 4th subagent and exec-phase Step 8 are independent integration points, which would matter if token-cost regression demanded partial revert.
