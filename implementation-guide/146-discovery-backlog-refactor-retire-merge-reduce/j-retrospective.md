# Backlog refactor: retire, merge, reduce - Retrospective
**Task**: 146 (discovery)

## Task Reference
- **Task ID**: internal-146
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/146-backlog-refactor-retire-merge-reduce
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-17

## Executive Summary
- **Duration**: 1 session on 2026-05-17 (estimated: 1 day; variance: ~0).
- **Scope**: 68 BACKLOG.md entries classified against three axes (still-applicable / mergeable / scope-reducible); 8 approved mutations applied (4 retire, 3 merge, 1 reduce-scope); 60 keep-as-is. Net BACKLOG shrink 68 -> 61 entries (~10%), plus one entry slimmed from ~210 lines to ~17 (~94% reduction). Original scope held end-to-end; no descope, no addition.
- **Outcome**: Success. All 7 acceptance criteria pass; validator clean after every mutation commit; round-trip property held; recommendations artefact preserved as the discovery deliverable; halt-on-failure path defined but not exercised (no failures observed).

## Variance Analysis
### Time and Effort
- **Estimated**: 1 day total, no per-phase breakdown in `a-task-plan.md` beyond "single coherent review pass".
- **Actual**: All 8 workflow phases (a, b, c, d, e, f, g, j) completed in one session on 2026-05-17.
- **Variance**: At or under estimate. The dominant time sink was the 68-entry classification pass in f-Step-2 (each entry required reading its body and -- for ~15 entries -- a referenced retrospective). The single-session ceiling was preserved by deferring deep retrospective reads except where the entry's own body was too thin to judge.

### Scope Changes
- **Additions**: None.
- **Removals**: None.
- **Mid-execution corrections** (not scope changes; defect fixes during the phase that originated them):
  - b-requirements draft introduced a phantom `--baseline=<SHA>` flag on `backlog-manager list`; caught by plan-review subagents and fixed in commit 017169a before c-design started.
  - d-implementation Step 1 baseline regex `^## Task: '` was incomplete (missed `## Bug:`); caught in f-Step-1 and corrected mid-execution (deviation D1).
  - e-testing TC-AC5 originally pointed the merge-trace grep at CHANGELOG.md; FR6 places the trace in the survivor BACKLOG entry. Fixed in commit 9891039 during g-phase (deviation D4).
- **Impact**: Each correction was caught at the next phase boundary (plan review, execution, or testing) and resolved without rewinding to an earlier phase. The corrections themselves are documented at the phase that caught them, not the phase that introduced them.

### Quality Metrics
- **Test coverage**: 7/7 AC tests PASS, 3/4 PF tests PASS + 1 PARTIAL (TC-PF-4 narrower bash regex; no real-artefact impact), 2/2 HALT tests PASS, 4/4 NFR checks PASS.
- **Defect rate**: 0 defects in the deliverable. 3 mid-execution corrections to in-progress workflow files, all caught before the file's exit gate.
- **Performance**: `backlog-manager validate` real=0.087s on the post-batch corpus -- well under the sub-1s NFR1 target.

## What Went Well
- **Plan-review map/reduce caught the phantom flag.** The subagents flagged a non-existent `--baseline=<SHA>` flag in b-requirements before any helper invocation. Without that catch, f-Step-1 would have hit a hard error and had to re-plan.
- **Pre-flight + single-commit merge mechanic preserved invariants without exception handling.** Designing merges as a single Edit-then-retire-then-validate-then-commit unit (c-design D5) meant any partial failure was discarded by `git checkout -- BACKLOG.md CHANGELOG.md`, with no orphan commit to revert. The post-commit revert path (D6) was specified for completeness but never needed.
- **Recommendations artefact as commit-anchored approval (D3).** Recording approval as a committed line in the artefact, rather than a conversational ack, gave AC2 a single deterministic check (`git log -- recommendations.md` vs `git log -- BACKLOG.md CHANGELOG.md`). The audit trail survives the conversation buffer.
- **`--exact-title=` over `--id=<slug>` simplified pre-flight (D2 deviation).** Using `--exact-title=` for all 68 selectors made D8.1 (slug uniqueness) vacuous and saved a per-row slug derivation step. The deviation reduced complexity at the cost of nothing meaningful -- both selectors are first-class on `backlog-manager retire`.
- **File-based commit messages (`git commit -F`) bypassed shell-quoting hazards.** Several BACKLOG titles contain backticks, dashes, and embedded quotes. Writing each message to `/tmp/.../msg-*.txt` and passing via `-F` removed an entire class of escape failures from the apply loop.
- **Scratch-dir `baseline.sha` file outlived shell-variable scope.** Persistent state across Bash tool calls via `/tmp/.../baseline.sha` (rather than `BASELINE_SHA=$(...)` in a single command) made the baseline durable across every phase that needed it.

## What Could Be Improved
- **Baseline-enumeration regex was incomplete in the plan (D1).** d-implementation Step 1 used `^## Task: '` -- the BACKLOG parser at `CWF::Backlog.pm:222` also recognises `^## Bug: '`. Plan-review subagents did not catch this because the regex matched the typical case and they were looking at design correctness, not corpus coverage. Caught in f-Step-1 by sanity-checking the regex count against `backlog-manager list --all-items`. The corrective discipline -- always cross-check a grep-derived count against an authoritative helper count -- is worth standardising.
- **TC-AC5 wording bug (D4) lasted until g-phase.** e-testing TC-AC5 said "grep in CHANGELOG.md"; FR6 puts the trace in the surviving BACKLOG entry. Three plan-review subagents reviewed e-testing and none flagged it. The wording was internally self-consistent (a plausible test, just for the wrong artefact), which is exactly the failure mode plan-review struggles with -- the reviewers check the test against the test plan, not against the requirement it traces to.
- **Pre-flight realised as bash, not Perl (D3).** d-design and d-impl specified a Perl helper that imports `CWF::Backlog` and round-trips carry-overs through the parser. f-phase substituted a bash one-liner. The bash regex catches `- Priority:` shape but misses `### Status:` shape -- TC-PF-4 documents this as PARTIAL. No real-artefact impact (the 3 approved merge carry-overs are plain prose), but the substitution traded round-trip-property safety for less ceremony, and that trade was not made consciously at design time.
- **No machine-checked "did the merge actually carry over the union?"** D1 explicitly traded that guarantee away, accepting human-readable FR6 carry-over phrases as the trace. With 3 merges and 3 carry-overs each, manual verification was tractable. At a larger batch size, this would need to grow.

## Key Learnings
### Technical Insights
- **The BACKLOG parser accepts both `## Task:` and `## Bug:` heading prefixes** (verified at `CWF::Backlog.pm:222`). Any future "count baseline entries" check must use `^## (Task|Bug): ` -- not `^## Task: `.
- **`backlog-manager retire` is idempotent and silent on already-retired entries** -- it returns exit 0 with stderr `info` "not found in BACKLOG (already retired?)" rather than non-zero. The apply loop must therefore observe `git diff --quiet` as the secondary signal that the helper actually did something, not rely on exit code alone (TC-HALT-1 simulation confirmed this).
- **Single-commit merge atomicity matters more than commit-granularity reasoning.** The temptation is "Edit commit, then retire commit, easier to read in `git log`". The real cost of two commits is that a clean-Edit + failed-retire sequence leaves a half-finished state that's hard to characterise. One commit per merge makes the pre-commit `git checkout --` discard path uniformly correct.

### Process Learnings
- **Plan-review subagents are good at structural defects, weak at requirement-trace fidelity.** They caught the phantom `--baseline=<SHA>` flag (structural: this API does not exist) but missed TC-AC5 grepping the wrong file (trace: FR6 says survivor BACKLOG, TC said CHANGELOG). When a test plan references a requirement, an explicit "does the test actually check what the FR says?" pass is needed beyond the standard plan-review map/reduce.
- **Discovery tasks should pin a baseline SHA into the deliverable.** Without `Baseline:` in the artefact preamble, AC1's "row count equals baseline entry count" check becomes ambiguous as soon as BACKLOG.md changes. The pin is cheap; the alternative is irreproducible audit trails.
- **Per-action mechanic mapping (D5) generalises.** Future batch-mutation tasks (e.g. priority sweeps, retrospective backfills) benefit from the same shape: one mechanic per action, single commit per row, validator gate, per-commit message file. Already proven on this corpus.

### Risk Mitigation Strategies
- **R1 (subjective judgement discards items the user wants) was mitigated by the approval gate, as designed.** Maintainer reviewed 68 recommendations and approved as-is; no per-row override needed. The gate was the right structural choice -- it would have absorbed any number of overrides without changing the workflow.
- **R3 (merge loses nuance) was mitigated by carry-over phrases listed in the artefact.** All 3 merges preserved 3 carry-over phrases each in the surviving entry's body, grep-verifiable post-commit (TC-AC5). The mechanism worked at this batch size; would need machine-checking at larger scale (see D1 trade-off above).
- **R4 (ASCII regression) was mitigated by AC6 + the validator's existing ASCII gate.** No upper-plane codepoints introduced; recommendations.md diff scanned clean.

## Recommendations
### Process Improvements
- **Add a "trace-check" pass to plan-review for test plans.** When TC-N traces to FR-M, the reviewer should explicitly confirm the test interrogates the same artefact the FR identifies. The standard map/reduce checks plan internal consistency but does not check FR -> TC fidelity. (Surfaced by D4.)
- **Cross-check grep-derived corpus counts against an authoritative helper count before locking a baseline.** A regex that "looks right" can miss header variants (`## Bug:` in this case). At baseline-pinning time, run the helper's own enumeration and compare. (Surfaced by D1.)

### Tool and Technique Recommendations
- **The `--exact-title=` over `--id=<slug>` selector choice is a sound default for retire batches.** Avoids per-row slug derivation, sidesteps slug-uniqueness pre-flight, and works equally well on `backlog-manager retire`. Worth carrying forward as the default for future batch-retirement tasks.
- **Persistent-state-in-scratch-dir-file pattern is reusable.** Writing `baseline.sha`, per-commit message files, and any other "must outlive a single Bash tool call" state to the namespaced scratch dir (per [[tmp-paths]]) is a clean idiom; standardising it across batch-mutation tasks would help.

### Future Work
- **None directly warranted.** The deviations (D1 regex, D3 bash pre-flight, D4 TC wording) were all caught within the same task, do not have lingering effects, and do not motivate follow-up tasks. The reduce-scope on Task 40 ("Implement Interface-Based Version Dispatch for status-aggregator") was the substantive simplification -- the remaining 60 keep-as-is entries are intentionally parked, not deferred.

## Status
**Status**: Finished
**Next Action**: Task complete -- suggest merge to main
**Blockers**: None identified
**Completion Date**: 2026-05-17
**Sign-off**: Maintainer (approved 2026-05-17)

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md` (commit 0bc3d39)
- Requirements: `b-requirements-plan.md` (commits 775b0c7, 017169a)
- Design: `c-design-plan.md` (commit 6cf6780)
- Implementation plan: `d-implementation-plan.md` (commit ac964d8)
- Testing plan: `e-testing-plan.md` (commits ca7e8e5, 9891039)
- Implementation execution: `f-implementation-exec.md` (commit d68a6c3)
- Testing execution: `g-testing-exec.md` (commit 1394ea5)
- Discovery deliverable: `recommendations.md` (commits dda0c0f, d0a97ad, d05be10)
- Mutation commits: 7c77215, 24f2512, c44acd0, 6a845ed (retires); 287a97e, 910eb6f, d38ab83 (merges); 5b37b28 (reduce-scope)
- CHANGELOG seed: ac45c8c
