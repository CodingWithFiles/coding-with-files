# Progress-signal inference conflict still present - Requirements
**Task**: 157 (discovery)

## Task Reference
- **Task ID**: internal-157
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/157-progress-signal-inference-conflict-still-present
- **Template Version**: 2.1

## Goal
Define what this discovery must establish and deliver: a verified answer to
whether the progress signal can still drive a spurious inconclusive inference
for a correctly-finished task, and a decision on the backlog item's fate.

## Functional Requirements
### Core Features
- **FR1 — Trace the cliff path**: Establish, from source, the complete path that determines whether a finished task can be a progress-signal candidate: `_get_progress_signal` → `_calculate_task_progress` → `CWF::TaskState::state_achievable` (cliff at completion ≥ 100% → 0) → `_score_progress` → zero-score filter (`TaskContextInference.pm:418`). Acceptance: each hop cited with file:line, and the conclusion (finished task → work potential 0 → filtered out) stated as confirmed or refuted.
- **FR2 — Reproduce the reported scenario**: Reconstruct the Task 104 conditions — a correctly-finished task (all steps terminal) alongside a low-progress non-active task (Backlog/To-Do, ~10% — the role task 104 played) and an active task — and exercise the progress signal against them. This step is empirical because the FR1 trace proves only the finished-task *exclusion*; it does not prove whether the originally-reported conflict still reproduces, which is the question the backlog poses. Acceptance: observed candidate list and `top` recorded; whether the set drives an inconclusive result recorded, with the deciding signal identified. The fixture lives in the project-namespaced scratch dir (per tmp-paths), never under the live `implementation-guide/` tree that `_get_progress_signal` scans (`TaskContextInference.pm:385`). Commands + output recorded.
- **FR3 — Classify the backlog premise**: Determine whether the backlog claim — "a 100% task gets score 60 (maximum), finished tasks dominate the progress signal" — holds or is a misread. The deciding question is whether `_score_progress` receives raw completion or a post-cliff value. Acceptance: a one-line verdict (holds / misread) supported by FR1 and FR2 evidence. The verdict must be falsifiable — record explicitly what FR2 output *would* have shown the premise to hold (a finished task surviving as a candidate, or driving the inconclusive), so a confirming result is established by evidence, not assumed.
- **FR4 — Recommendation**: Produce a recommendation with rationale and a concrete follow-up backlog action — either (a) retire the backlog item, or (b) rescope it to a clarity-only chore. The clarity fix spans two different subs: rename the misleading `$percentage` parameter in `_score_progress` (`TaskContextInference.pm:447`) to a work-potential name, and delete the stale "bell curve, peak at 50%" comment in `_get_progress_signal` (`TaskContextInference.pm:410`). Note the backlog's "line 409" citation is stale. Acceptance: recommendation names the exact backlog action (retire / modify) and whether any behaviour change is implied (expected: none).

### User Stories
- **As a** maintainer triaging the backlog **I want** a verified verdict on this "bug" **so that** I can retire or rescope it without re-deriving the cliff logic.
- **As an** agent reading `_score_progress` later **I want** the intent to be unambiguous **so that** I do not re-file the same misread as a bug.

## Non-Functional Requirements
### Performance (NFR1)
- N/A — investigation; no runtime performance target.

### Usability (NFR2)
- The recorded finding must be readable cold: each conclusion cites file:line so a future reader can re-verify without re-tracing from scratch.

### Maintainability (NFR3)
- Any fixture or probe used for FR2 must rely on existing CWF test scaffolding / core Perl only (no new non-core dependencies); it is throwaway evidence, not shipped code.
- The fixture lives in the project-namespaced scratch dir (`/tmp/-home-matt-repo-coding-with-files-task-157/`, created `mkdir -m 0700`); it must not be created under the tracked `implementation-guide/` tree (which the live progress signal scans).

### Security (NFR4)
- N/A — read-only investigation; no auth, data, or trust-boundary surface. No changes to hash-tracked files in this discovery task.

### Reliability (NFR5)
- FR2 evidence must be reproducible: the commands recorded must reproduce the observed candidate list deterministically.

## Constraints
- Discovery only: deliverable is a finding + recommendation, not a behaviour change. Any later code edit (rename/comment removal) is a separate task and would require a `script-hashes.json` refresh in the same commit (hash-updates convention).
- Investigation is bounded to the specific backlog claim about the progress signal — not a general review of the inference system, signal weights, or correlation model.

## Decomposition Check
- [ ] **Time**: >1 week? No
- [ ] **People**: >2 people? No
- [ ] **Complexity**: 3+ distinct concerns? No
- [ ] **Risk**: High-risk components needing isolation? No
- [ ] **Independence**: Parts separable? No

No decomposition signals triggered.

## Acceptance Criteria
- [ ] AC1 (FR1): Cliff path traced end-to-end with file:line citations; finished-task-exclusion confirmed or refuted
- [ ] AC2 (FR2): Reported 103-vs-104 scenario reconstructed in scratch; progress-signal candidate list + `top` recorded and reproducible; whether the set drives inconclusive recorded with the deciding signal named
- [ ] AC3 (FR3): Backlog premise classified holds/misread, supported by FR1+FR2 evidence, with the falsifying condition stated
- [ ] AC4 (FR4): Recommendation recorded naming the exact backlog action and whether any behaviour change is implied; clarity-fix citations correct (`_score_progress` :447, `_get_progress_signal` comment :410)

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
FR1–FR4 all satisfied. ACs: AC1 (trace) PASS, AC2 (scenario reproduced; `201` absent, top=203) PASS, AC3 (premise = misread, falsifying condition stated) PASS, AC4 (recommendation + correct citations `:447`/`:410`) PASS. Evidence in f-/g-testing-exec.md.

## Lessons Learned
Making the verdict falsifiable up front (defining the output that would show the premise holds) was what let the "misread" classification rest on evidence rather than assertion.
