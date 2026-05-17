# Backlog refactor: retire, merge, reduce - Testing Execution
**Task**: 146 (discovery)

## Task Reference
- **Task ID**: internal-146
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/146-backlog-refactor-retire-merge-reduce
- **Template Version**: 2.1

## Goal
Execute the test cases from e-testing-plan.md against the post-f-phase repository state.

## Test Environment
- Branch: `discovery/146-backlog-refactor-retire-merge-reduce` at `d05be10` (head after f-phase + Status-section fix).
- Baseline SHA: `ca7e8e531f0cad280ffcaa58faab8945a247f2c4` (preserved in `/tmp/-home-matt-repo-coding-with-files-task-146/baseline.sha`).
- Helper: `backlog-manager validate`.
- Fixture artefacts: `/tmp/-home-matt-repo-coding-with-files-task-146/tests/pf{2,3,4}-*.md` (synthetic recommendations files for negative-case checks).

## Functional Test Results

| TC | Description | Result | Evidence |
|----|-------------|--------|----------|
| TC-AC1 | Coverage = baseline entry count | PASS | 68 recommendations sections, 68 baseline entries (`grep -cE '^## (Task\|Bug): '` on `git show <BASELINE>:BACKLOG.md`). |
| TC-AC2 | Approval commit precedes any BACKLOG/CHANGELOG mutation | PASS | Approval commit `d0a97ad` is ancestor of first mutation commit `ac45c8c` (CHANGELOG seed). The later Status-section commit on recommendations.md does not invalidate FR3 -- only the approval commit itself must precede mutations. |
| TC-AC3 | CHANGELOG seed is the first CHANGELOG-touching commit on branch | PASS | `git log --reverse <BASELINE>..HEAD -- CHANGELOG.md` lists `ac45c8c Task 146: Seed CHANGELOG block for backlog refactor` first. |
| TC-AC4 | Validator clean after every edit-bearing commit | PASS | `backlog-manager validate` ran clean immediately after every mutation in the apply loop (per f-Step-6 chained invocations). Final validate exits 0. |
| TC-AC5 | Merge-enrichment trace findable in surviving BACKLOG entry | PASS | All 3 merge carry-overs grep-findable in BACKLOG.md under the corresponding survivor entry: "preserving exit codes via a 2-arg form", "skips h-rollout.md", "service surface, no users, no telemetry". (TC wording corrected in e-testing-plan: trace lives in survivor per FR6, not in retired CHANGELOG block.) |
| TC-AC6 | Diff-scoped ASCII purity on recommendations.md | PASS | `git diff <BASELINE>..HEAD -- recommendations.md \| LC_ALL=C grep -cP '^\+.*[^\x00-\x7F]'` returns 0. |
| TC-AC7 | No orphan broken commits | PASS | 13 commits since baseline, all coherent. No `git revert` commits on the branch (apply loop ran without triggering the post-commit revert path). |

## Pre-flight Negative Cases

| TC | Description | Result | Evidence |
|----|-------------|--------|----------|
| TC-PF-1 | Slug collision detection | N/A by design | Real artefact used `--exact-title=` for all 68 rows (f-D2 deviation); no `--id=<slug>` selectors present, so the check has no input to flag. The bash-realised pre-flight skipped this check accordingly. |
| TC-PF-2 | Dangling merge target | PASS | Fixture `pf2-dangling.md` with `Target: --exact-title="Nonexistent Target"` against a row-set that has no such entry. Bash check (`grep '^## Recommendation: Nonexistent Target$'`) returns empty -- "DANGLING: Nonexistent Target -- FAIL (PF-2 fires)". |
| TC-PF-3 | Cycle detection | PASS | Fixture `pf3-cycle.md` with rows "Entry A merge -> Entry B" and "Entry B merge -> Entry A". Awk-based chain-walk records: A: merge->B, B: merge->A; terminal check finds no row with `keep-as-is` or `reduce-scope` reachable -- PF-3 fires. |
| TC-PF-4 | Carry-over heading/metadata-key shape | **PARTIAL** | Fixture `pf4-heading-shape.md` with carry-overs `"### Status: Backlog"` and `"- Priority: High"`. The bash regex `^  - "(#\|### \|- (Priority\|Status\|...)):` catches the `- Priority:` line, but misses the `### Status: Backlog` line (the regex pattern `### ` requires literal "### :" without intervening text). The planned Perl round-trip check would have caught both. **Real-artefact impact: none** -- the 3 real merge carry-overs contain no heading-shape phrases (manually verified pre-commit). Recorded as a known limitation of the f-D3 bash substitution. |

## Halt-Protocol Cases

| TC | Description | Result | Evidence |
|----|-------------|--------|----------|
| TC-HALT-1 | Pre-commit failure: retire of nonexistent entry | PASS | `backlog-manager retire --task=146 --exact-title="ThisEntryDoesNotExist"` returned exit 0 with stderr `[CWF] INFO: ... not found in BACKLOG (already retired?)`. `git diff --quiet` confirmed working tree unchanged. The halt protocol's "no-op observed -> halt + surface" branch covers this signal. |
| TC-HALT-2 | Post-edit validator regression in sandbox | PASS | On a throwaway `sandbox/146-halt-sim` branch, appended `## Task: Synthetic broken entry without required Priority` to BACKLOG.md. Validator exited 1 with `[CWF] ERROR: BACKLOG.md:1208 [BACKLOG-001] missing required Task-Type field on entry`. The halt protocol's "non-zero validate -> halt + surface" branch covers this signal. Sandbox branch deleted; main task branch unchanged. |

## Non-Functional Results

- **Performance (b-NFR1)**: `time backlog-manager validate` reports real=0.087s on the post-batch corpus. Well under the sub-1s target. PASS.
- **Security (b-NFR4 / D9)**: every helper invocation in the apply loop used argv form -- recorded in f-impl Step 6; no `bash -c` wrapping. The Step 8 security review for f-phase recorded `no findings: empty changeset` (no new code under CWF-internal coverage). PASS.
- **Usability (b-NFR2)**: `recommendations.md` opens cleanly in any text editor; AC6 confirmed ASCII purity in the diff. PASS.
- **Reliability (b-NFR5)**: validator clean after every commit (TC-AC4); no revert path was exercised because no failure occurred. PASS.

## Test Coverage Summary

- 7/7 AC tests: PASS
- 3/4 PF tests: PASS; 1/4 (PF-4) PARTIAL with documented narrower bash regex; no real-artefact impact
- 2/2 HALT tests: PASS
- 4/4 NFR checks: PASS

## Deviations from e-testing-plan

- **TC-AC5 wording corrected**: e-testing-plan TC-AC5 originally said "findable in CHANGELOG.md under the retired source-entry's `#### <title>` block". The correct check per FR6 is "findable in the surviving BACKLOG entry's body". Updated e-testing-plan.md in this g-phase; the f-implementation log recorded this as deviation D4.
- **TC-PF-4 narrower regex**: f-D3 substituted a bash one-liner for the planned Perl round-trip pre-flight script. The bash regex catches `- Priority:` style but misses `### Status:` style. Recorded as PARTIAL above; no real-artefact impact because the 3 merge carry-overs in the approved artefact contain no heading-shape phrases.

## Blockers Encountered

None.

## Security Review

**State**: no findings

no findings: empty changeset

(The security-review-changeset helper returned `reviewed 0 files, 0 lines, anchor=ed94f60, includes uncommitted`. Testing-phase additions are entirely under `implementation-guide/146-.../*.md` (g-testing-exec.md, plus the e-testing-plan.md TC-AC5 wording fix); the fixture artefacts at `/tmp/-home-matt-repo-coding-with-files-task-146/tests/*.md` are outside the repo entirely. No new helper code, no new shell invocations.)

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
**TC-AC5 wording bug (D4) lasted from e-testing through to g-phase test execution.** Three plan-review subagents read e-testing-plan and none flagged the CHANGELOG/BACKLOG mismatch -- the test was internally consistent but interrogated the wrong artefact relative to FR6. Lesson: plan-review struggles with FR -> TC fidelity even when it catches structural defects reliably. **TC-PF-4 PARTIAL (D3 bash regex narrower than planned Perl round-trip)** -- no real-artefact impact because all 3 approved carry-overs are plain prose, but the substitution traded round-trip-property safety for less ceremony. Worth being explicit at design time when substituting a simpler check for a stronger one.
