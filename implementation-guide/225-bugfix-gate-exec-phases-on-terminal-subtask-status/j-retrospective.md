# Gate exec phases on terminal subtask status - Retrospective
**Task**: 225 (bugfix)

## Task Reference
- **Task ID**: internal-225
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/225-gate-exec-phases-on-terminal-subtask-status
- **Template Version**: 2.1
- **Retrospective Date**: 2026-07-10

## Executive Summary
- **Duration**: ~1.5 hours (estimated: 0.5 day, variance: −60%)
- **Scope**: Delivered as planned. One question (`Finished` ≠ `merged`) was deliberately
  deferred at design time and is carried out as a follow-up, not descoped silently.
- **Outcome**: Success. A parent task can no longer enter `f`, `g`, `h`, `i`, or `j`
  while any direct child is in a non-terminal status. The reported failure — a
  retrospective squash rewriting the base an open subtask was branched from — is now
  unreachable by construction at three independent chokepoints.

## Variance Analysis

### Time and Effort
- **Estimated**: 0.5 day, complexity Low.
- **Actual** (from checkpoint commit timestamps, all 2026-07-10):
  - Planning (`a`): 11:51
  - Design (`c`): 12:05
  - Implementation plan (`d`): 12:15
  - Testing plan (`e`): 12:16
  - Implementation exec (`f`): 12:53
  - Testing exec (`g`): 13:03
  - Total from first to last checkpoint: 1h12m; ~1.5h including pre-`a` triage.
- **Variance**: ~60% under estimate. The two causes are worth separating. The estimate
  was honest about the *fix*, which is small. It failed to notice that the fix's two
  dependencies — `find_children()` and a terminal-status predicate — already existed,
  so the implementation was assembly rather than construction. The half-day figure
  priced work that the codebase had already done.

### Scope Changes
- **Additions**:
  - `CWF::TaskState::expected_files()` — extracted, not planned. The improvements and
    misalignment reviewers independently identified that the gate had copied
    `_get_all_statuses`' format-detection block, with "these must not disagree"
    enforced only by a comment. Extraction removed the duplicate.
  - `\A…\z` anchoring plus the `/a` flag on both validators in `workflow-manager.d/gate`
    and `cwf-checkpoint-commit` — a genuine fail-open found by the best-practice
    reviewer, with TC-24 and TC-25 as regressions.
  - `t/subtask-gate.t` grew TC-11b to cover the format-misdetection variant that TC-11
    had conflated with the real fail-open.
- **Removals / deferrals**:
  - **`Finished` does not imply `merged`** — deferred at design time with reasons
    (`c-design-plan.md:270-285`). The gate is a *status* invariant over the file tree;
    merged-ness is a *git* invariant needing branch resolution, ancestry checks, and a
    policy for deleted child branches. Filed as a follow-up backlog item.
  - Two reviewer findings declined with recorded rationale: `die` vs `Carp::croak`
    (the module's callers want the raw message, not a caller-frame trace), and the
    CLI's `eval` collapsing all exceptions to exit 2 (already fail-closed).
- **Impact**: The additions were absorbed inside the `f` phase and cost roughly ten
  minutes. None changed the design.

### Quality Metrics
- **Test coverage**: `t/subtask-gate.t` — 19 top-level subtests, TC-1…TC-25. Covers the
  no-children, terminal-children, and non-terminal-children cases named in the plan,
  plus phase-letter gating, `undef` inputs, Unicode digits, shell-metacharacter task
  paths, status clamping, and the `\A…\z` fail-open.
- **Full suite**: `prove -r t/` → 78 files, 1073 tests, all PASS.
- **Integrity**: `.cwf/scripts/cwf-manage validate` → OK at each checkpoint.
- **Defects found during testing**: one in the *plan*, zero in the implementation. See
  Key Learnings.
- **Review verdicts** (classified by `security-review-classify`, the sole classifier):
  - `f`: security `no findings`, robustness `no findings`; best-practice, improvements,
    misalignment each `findings` — all fixed or declined-with-reason before the commit.
  - `g`: security `no findings`, best-practice `no findings`.

## What Went Well

**The gate was assembled from existing parts, not invented.** `find_children()` already
existed and `/cwf-delete-task` already used it as a hard refusal. The terminal-status
predicate already existed as `TaskState::_is_closed()`, private and unused. Promoting it
to `status_is_terminal()` and having `_is_closed()` delegate meant one status list, not
two. The plan's "no new child-discovery or status-classification code path where one
already exists" constraint held.

**Three chokepoints, each guarding a distinct failure at a distinct time.** A reviewer
suggested cutting one as redundant. They are not: the SKILL Pre-Step refuses phase
*entry*; `cwf-checkpoint-commit` refuses before `status_set` stamps a phase Finished;
`checkpoints-branch-manager create` refuses immediately before the `git reset --soft`
squash. An agent that ignores a SKILL instruction still hits the second; a hand-run
squash still hits the third. Defence in depth was kept deliberately.

**The end-to-end probe exercised the real bug, not a mock of it.** A throwaway subtask
`225.1` was created under this very task. All three chokepoints refused it (exit 3,
exit 3, die). No `-checkpoints` branch was created, HEAD did not move. Cancelling the
child's phases opened the gate; the probe was then deleted. The reported user failure
was reproduced against the fix rather than reasoned about.

**Fail-closed throughout, and tested as such.** An unresolvable task `die`s rather than
reading as "no children" (TC-14). An unrecognised phase is exit 1, never a silent
ungated pass (TC-18). The instinct to make the halt "helpful" by degrading to permission
was resisted.

**The reviewers earned their cost.** Five parallel reviewers on `f` produced one real
security fail-open, one real duplication (found independently by two of them), and two
findings correctly declined. This is a good hit rate for a 400-line changeset.

## What Could Be Improved

**The testing plan's flagship regression test described a reproducer that does not
reproduce.** TC-11 as planned asserted that a child holding only a Finished
`a-task-plan.md` would aggregate to `state_done == 100`. It aggregates to **0**. The
plan reasoned about `_get_all_statuses`' two fail-open behaviours (`next unless -f`
skips missing files; `push … if $status ne "Unknown"` drops unknowns) without noticing
that deleting `f-implementation-exec.md` *also* flips the version detection at
`TaskState.pm:304` to v2.0, whose filenames are entirely different — so no expected file
is found at all and the aggregate is empty. The fix was unaffected; the *claim* was
wrong and had to be narrowed to "any partial file set **that retains the format-marker
file**".

**The implementation plan had a label correction backwards.** It instructed changing
`cwf-retrospective/SKILL.md:41` from "Step 6" to "Step 7". The SKILL was internally
consistent; the *doc* heading in `retrospective-extras.md` was the one off by one. Had
the plan been followed mechanically, a correct file would have been broken to match an
incorrect one.

**A reviewer finding was right about the defect and wrong about the exploit path.** The
best-practice reviewer reported the `^…$` trailing-newline fail-open as reachable via
the gate CLI. It is not: `CWF::Options::parse` anchors its own argument regex and strips
the newline before the validator sees it. The reachable path was `cwf-checkpoint-commit`,
which reads `$letter` straight from `@ARGV`. Probing before fixing found the real path;
accepting the report at face value would have produced a fix aimed at a shielded surface
and left the live one open.

**Self-inflicted process noise.** Two full-suite failures after the review fixes were
stale-hash and permission drift, caused by editing files after computing their hashes —
not regressions. Separately, a hash key was temporarily renamed to
`"cwf-checkpoint-commit-PLACEHOLDER"` as a crude way to locate a line, then repaired.
Both cost time and neither was necessary.

## Key Learnings

### Technical Insights

**Terminality is not completeness, and a percentage cannot express the difference.** The
probe made this concrete: `workflow-manager status 225 --workflow` reported subtask
`225.1` at **100%** while every one of its six phases read `Cancelled (0%)`. `state_done`
takes the MIN over `status_percent`, and `_is_closed` folds Finished / Cancelled /
Skipped alike to 100. A gate written as `state_done == 100` would have been *correct on
this input by accident* and wrong in general. The gate asks the right question
per-file — "is this status terminal?" — and gets the offending phase names for free.

**Given completeness, the two conditions collapse.** "Every expected status is terminal"
is exactly `state_done == 100`, because `status_percent` returns 0 (never `undef`) for
an unrecognised status, so the MIN is 100 iff all are closed. The design's conditions 2
and 3 are therefore one predicate. The gate does not use `state_done` as its test —
it reports it, and tests each file — precisely because completeness is what is in doubt.

**`$` is not end-of-string.** `/^[a-j]$/` accepts `"f\n"`. Combined with an exact hash
lookup in `phase_is_gated`, that is a silent ungated pass — the worst possible failure
mode for a gate. Validators that feed an exact-match lookup must anchor with `\A…\z`.
The `/a` flag matters for the same reason: `\d` otherwise admits Unicode digits, so
`\x{0662}\x{0662}\x{0665}` would pass a task-path validator and fail later, deeper, and
less legibly (TC-24).

**Induction keeps the gate cheap.** Only *direct* children are checked. Each child's own
gate holds back its grandchildren, so no recursive descent is needed and the cost is one
`glob` per phase entry.

### Process Learnings

**Write the regression test to fail against the *unfixed* code, and say so in the
assertion.** TC-11 asserts `state_done($child) == 100` inline *before* asserting the
gate blocks; TC-25 asserts `"f\n" =~ /^[a-j]$/` and `!~ /\A[a-j]\z/` inline before
asserting rejection. A `state_done`-only gate provably cannot pass TC-11, and a `^…$`
validator provably cannot pass TC-25. This "regression by construction" survives being
read by someone who never saw the bug — and it is what caught the plan's own error on
first run.

**Estimates should be made after checking what already exists.** The 0.5-day estimate
was formed before confirming that `find_children()` and `_is_closed()` were already
there. Ten minutes of grep before estimating would have halved the number.

**Probe a security finding before fixing it.** Reviewer reports name a defect and a
path. The defect was real; the path was wrong. Fixing the reported path alone would have
left the live one open while producing a green diff and a satisfying-looking commit.

### Risk Mitigation Strategies

- **Mid-`f` deadlock** (planned High risk): mitigated exactly as designed. The gate fires
  on phase *entry*, never on subtask *creation*. The `225.1` probe was created while `f`
  was already complete and did not deadlock anything; cancelling it restored flow.
- **Retroactive breakage** (planned Medium): CWF has no subtasks, confirmed. The halt
  message names the remedy — finish, skip, or cancel — so an external adopter always has
  a next action.
- **Gate placement drift** (planned Medium): one module, one exported predicate, one
  invocation line repeated verbatim across five SKILL files. The line is short enough
  that divergence would be visible in a grep.
- **Unforeseen**: the gate's halt message is read verbatim into agent context by the
  SKILL Pre-Step, making it a prompt-injection surface. The one free-text field (child
  status, returned unvalidated by `status_get`) is clamped — whitespace collapsed,
  truncated to 32 chars — with a code comment naming why. All other interpolated fields
  are constrained by `parse_dirname`'s regexes. Recorded because that safety property
  rests entirely on those regexes; a future caller populating `type`/`num` from a looser
  source would break it.

## Recommendations

### Process Improvements

- **Grep before estimating.** For any bugfix whose plan names existing helpers as
  dependencies, confirm they exist and read their signatures before assigning effort.
- **A testing plan's reproducer is a hypothesis, not a fact.** Where a plan asserts that
  unfixed code produces a specific wrong value, that assertion belongs in the test as a
  live assertion, so the plan is checked rather than trusted.
- **When a reviewer names an exploit path, reproduce it before fixing it.** Fixing a
  reported path without reproducing it can leave the reachable path untouched.

### Tool and Technique Recommendations

- The `**State**: <token>` + verbatim-agent-output record is the only durable copy of a
  review; scratch `.out` files are ephemeral. Summarising the reviewers in the exec file
  loses the finding text. Record verbatim.
- `security-review-classify` is the sole verdict classifier. Prose heuristics over
  reviewer output are not a substitute and were not used.

### Future Work

- **`Finished` does not imply `merged`** (backlog, Medium). A child can be Finished and
  unmerged, in which case `j` still squashes the parent and strands the child's base.
  `CWF::TaskPath::parent_branch_ancestry()` (`TaskPath.pm:536`) looks like the right
  primitive. Needs a policy for already-deleted child branches.
- **`plan-mechanical-check` `path:line` false positives** (already filed,
  `BACKLOG.md:1738`). It does not strip a trailing `:NN` before the existence test and
  misfired again during this task's own plan review, on `workflow-manager.d/control:39`.

## Status
**Status**: Finished
**Next Action**: Task complete — suggest merge to main
**Blockers**: None identified
**Completion Date**: 2026-07-10
**Sign-off**: Retrospective completed by the maintainer with Claude Opus 4.8

## Archived Materials
- Planning: `a-task-plan.md`, `c-design-plan.md`, `d-implementation-plan.md`,
  `e-testing-plan.md`
- Execution: `f-implementation-exec.md` (five verbatim reviewer records),
  `g-testing-exec.md` (two verbatim reviewer records)
- Implementation: `.cwf/lib/CWF/SubtaskGate.pm`,
  `.cwf/scripts/command-helpers/workflow-manager.d/gate`
- Tests: `t/subtask-gate.t` (TC-1…TC-25)
- Checkpoint commits preserved on
  `bugfix/225-gate-exec-phases-on-terminal-subtask-status-checkpoints`
