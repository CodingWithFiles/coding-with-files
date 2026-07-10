# Gate exec phases on terminal subtask status - Testing Execution
**Task**: 225 (bugfix)

## Task Reference
- **Task ID**: internal-225
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/225-gate-exec-phases-on-terminal-subtask-status
- **Template Version**: 2.1

## Goal
Execute `e-testing-plan.md` — the unit and CLI suite in `t/subtask-gate.t`, and the
system-level probe that proves the reported bug is unreachable.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Execute every functional test case, record PASS/FAIL
- [x] Execute non-functional test cases
- [x] Execute the system / manual validation probe
- [x] Document deviations

## Test Environment
- Local checkout at `3f93ff3`, no network, no database.
- `prove -r t/` invoked bare; `PERL5OPT=-CDSLA` from the settings env.
- Unit and CLI fixtures under `File::Temp::tempdir(CLEANUP => 1)`.
- The one real-tree probe (a throwaway subtask under 225) was created and deleted within
  this phase. No production or shared state touched.

## Suite Results

`prove -r t/` — **PASS**. 78 files, 1073 tests. `t/subtask-gate.t` contributes 19 top-level
subtests (TC-24 nests inside the `CLI exit codes` subtest, so it adds coverage without adding
a top-level count).

`.cwf/scripts/cwf-manage validate` — **OK**.

## Functional Test Cases

| TC | Case | Result |
|---|---|---|
| TC-1 | No children → permitted | PASS |
| TC-2/3/4 | Child wholly Finished / Skipped / Cancelled → permitted | PASS |
| TC-4b | Cancelled is 0% in the raw map yet terminal | PASS |
| TC-5 | Mixed terminal statuses across phases → permitted | PASS |
| TC-6 | Two children, both terminal → permitted | PASS |
| TC-7 | `phase_is_gated` false for a–e, true for f–j; `undef` not gated | PASS |
| TC-8 | Non-terminal grandchild does not block the grandparent (induction) | PASS |
| TC-9 | Each of In Progress / Testing / Blocked / Backlog / To-Do blocks, and is named | PASS |
| TC-10 | Present-but-unparseable status blocks (`Unknown`) | PASS |
| TC-11 | Partial file set blocks — **the D2 regression** | PASS |
| TC-11b | Child stripped of its v2.1 marker blocks as a v2.0 task | PASS |
| TC-12 | Only the non-terminal sibling is reported | PASS |
| TC-13 | `$base_dir` is honoured, not `find_base_dir()` | PASS |
| TC-14 | Unresolvable task dies (fail closed), not empty-list | PASS |
| TC-15 | `format_blocked` clamps status text (no tab, ≤32 chars) | PASS |
| TC-15b | `format_blocked` pluralises on count | PASS |
| TC-16/22 | Permitted is exit 0 and silent on both streams | PASS |
| TC-17 | Blocked is exit 3, `[CWF] BLOCKED` + child + remedy on stderr | PASS |
| TC-7b | Ungated phase `a` exits 0 despite an open child | PASS |
| TC-18 | `--phase=Z`, `1`, `aa`, empty, and missing each exit 1 | PASS |
| TC-19 | `--task-path='1; rm -rf /'`, `abc`, `../../etc` exit 1; no shell reached | PASS |
| TC-20 | Missing task exits 2, distinct from 1 and 3 | PASS |
| TC-21 | Dispatcher registers `gate`; usage names it | PASS |
| TC-24 | Unicode digits rejected as malformed (exit 1), not merely unresolvable — **added** | PASS |
| TC-25 | A trailing newline cannot disable the gate — **added** | PASS |

TC-24 and TC-25 were added during the `f`-phase review response. Both discriminate: TC-24
exits 2 (not 1) against a `\d` validator without `/a`; TC-25's `cwf-checkpoint-commit` probe
reports "expected 1 wf file" rather than "invalid phase letter" against `^…$` anchors.

### Regression tests verified to fail against the pre-fix code

`e-testing-plan.md` requires proof that the regressions actually regress. Two are proved
**by construction** rather than by a manual mutation run, which is stronger — the property
is asserted inside the test and cannot silently lapse:

- **TC-11** asserts `state_done($child) == 100` inline, then asserts the gate blocks. A
  `state_done == 100`-only implementation cannot satisfy both.
- **TC-25** asserts `"f\n" =~ /^[a-j]$/` and `"f\n" !~ /\A[a-j]\z/` inline, then asserts
  `cwf-checkpoint-commit` rejects the letter. The `^…$` implementation cannot satisfy all
  three.
- **TC-18** was checked directly during implementation: `gate --phase=Z` exits 1, and the
  only code path to exit 0 is `phase_is_gated`, reached solely after the `[a-j]` validation.

## Non-Functional Test Cases

- **TC-22 — permitted path stays silent**: PASS. `gate --task-path=225 --phase=j` writes
  nothing to stdout or stderr. A gate that chatters on every phase entry trains users to
  ignore it.
- **TC-23 — suite and integrity gates**: PASS. `prove -r t/` green invoked bare;
  `cwf-manage validate` OK; permissions match recorded ceilings (`gate` 0500,
  `SubtaskGate.pm` 0600).

## System / Manual Validation

Executed against the real repository with a throwaway subtask, then reverted.

**Deviation from the plan**: the plan says `/cwf-new-subtask 225 1 chore …`. That skill also
creates and checks out a git branch, which would have churned branch state mid-task for a
directory that was about to be deleted. The probe used the underlying helper,
`task-workflow create`, which produces the identical directory and template set without
touching git. Nothing the probe tests depends on the branch.

| Step | Expected | Observed |
|---|---|---|
| 1. Create `225.1` (chore, 6 files, all `Backlog`) | subtask exists | 6 files copied |
| 2. `workflow-manager gate --task-path=225 --phase=g` | exit 3, names `225.1` | exit 3, named all six Backlog phases |
| 3. `cwf-checkpoint-commit 225 f "probe"` | **refuses**, exit 3 | exit 3, refused |
| 4. `checkpoints-branch-manager create` | **refuses** | refused (die), exit 255 |
| 5. No side effects | no branch, no commit | no `…-225-…-checkpoints` branch; HEAD still `3f93ff3` |
| 6. Cancel all six `225.1` phases | gate opens | `gate … --phase=g` exit 0, silent |
| 7. `task-workflow delete 225.1 --force` | probe gone | `[CWF] deleted task 225.1` |
| 8. `cwf-manage validate` | OK | OK; working tree clean |

**Step 3 is the end-to-end proof that the reported bug is fixed.** Step 4 is the sharper
one: `checkpoints-branch-manager create` is the operation that immediately precedes the
retrospective's `git reset --soft` squash — the squash that rewrote the base an open subtask
had branched from, and stranded it. That squash is now unreachable while a child is open.

Step 6 also demonstrates the Cancelled-is-terminal property in the real aggregator:
`workflow-manager status 225 --workflow` reported `225.1 … 100%` while every one of its six
phases showed `Cancelled (0%)`. A gate comparing percentages would have blocked here.

## Test Coverage

Every branch of the terminality conjunction is exercised: missing file (TC-11, TC-11b),
`Unknown` status (TC-10), non-terminal status (TC-9, five sub-cases), and each terminal
status (TC-2/3/4). Every CLI exit code (0, 1, 2, 3) is asserted, and each shown distinct from
the others. Both fail-open holes named in the design (unknown `--phase`; partial child) and
both found in review (trailing newline; Unicode digit) have named regressions.

Uncovered, and recorded rather than defended (from `d-implementation-plan.md` § Known
Residuals): a child directory whose name fails `parse_dirname` is skipped by `find_children`
and so does not block its parent; and D3's induction presumes the gate already existed, so a
repository already holding a Finished child above an open grandchild lets the parent through.
Neither is reachable through `/cwf-new-task`.

## Failures

None. No test failed at any point in this phase.

## Validation Criteria
- [x] TC-1 … TC-25 all pass
- [x] TC-11 verified to fail against a `state_done == 100`-only implementation (by construction)
- [x] TC-18 verified to fail against an implementation that exits 0 on unknown phases
- [x] `prove -r t/` green; test-file count rose by one (77 → 78)
- [x] `cwf-manage validate` OK
- [x] Both exec-phase review columns recorded below

Both reviewers ran in parallel against
`security-review-changeset --wf-step=testing-exec` (exit 0, 2883 lines, 22 files, 484
production, anchor `ffb4fd8`, includes uncommitted). Verdict tokens are as emitted by
`security-review-classify`, not by hand.

## Security Review

**State**: no findings

I have read the entire changeset (2884 lines) and the CWF threat model. The security-relevant code is the new `CWF::SubtaskGate` module, the `status_is_terminal`/`expected_files` additions to `CWF::TaskState`, the new `workflow-manager.d/gate` CLI, and the gate wiring into `cwf-checkpoint-commit` and `checkpoints-branch-manager`. The rest of the diff is task-doc markdown, the hash-manifest refresh, a BACKLOG entry, and the new `t/subtask-gate.t`. This is the `testing-exec` changeset, so it carries the same code as the reviewed implementation-exec changeset (with the post-review `\A…\z` fixes already folded in) plus `g-testing-exec.md` and the test file.

### Threat-category review

**(a) Bash injection / unsafe command construction.** No new shell-string execution is introduced. The one new `system` surface is absent — `workflow-manager.d/gate` validates its two arguments and passes them to pure-Perl functions, never a shell. `checkpoints-branch-manager` keeps its existing list-form `system("git", "branch", $checkpoints_branch)`. The test harness itself (`run_cmd`) uses list-form `system(@argv)`; the single backtick (`TC-21`) interpolates only a fixed script-path variable, no user input. `TC-19` fires `--task-path='1; rm -rf /'` and asserts exit 1 with the fixture tree intact. Clean.

**(b) Perl consuming git/user output without `-z` / validation.** The new code adds no git-porcelain parsing. Child discovery goes through the existing `find_children` (glob + `parse_dirname`), not newline-splitting. Inputs are regex-validated before use: `--task-path` against `/\A\d+(?:\.\d+)*\z/a` and `--phase` against `/\A[a-j]\z/` (both anchored with `\A…\z`, not `^…$`, closing the trailing-newline fail-open, and `/a` keeping `\d` ASCII). The same `\A…\z` + `/a` hardening was applied to `cwf-checkpoint-commit`'s `@ARGV` validators — that was the genuinely reachable path (the CLI was shielded by `CWF::Options::parse`'s own anchoring), and `TC-25` pins it. Clean.

**(c) Prompt injection via user-supplied strings.** The sharpest surface: `format_blocked` builds a message the SKILL Pre-Steps instruct the agent to report verbatim, so it reaches model context. I traced every interpolated field. `$num`/`$letter` are CLI-validated or `resolve`/`parse_branch`-derived. `$child->{num}` and `$child->{type}` come from `parse_dirname` (num constrained to `\d+(\.\d+)*`, type to `\w+`). `$child->{percent}` is an integer from `state_done`. The one genuinely free-text field — the child status, returned unvalidated by `status_get` — is explicitly run through `_clamp_status`, which collapses whitespace (neutralising embedded newlines) and truncates to 32 characters, with a code comment naming the verbatim-into-context risk. `TC-15` verifies a `"A\tB" + 200×"X"` status is stripped and truncated. This category is deliberately closed and documented. Clean.

**(d) Unsafe environment-variable handling.** No env vars introduced or consumed by the new code beyond the existing `check_perl5opt()` assertion. Clean.

**(e) Pattern-based risks.** The gate is fail-closed throughout (unresolvable task dies rather than reading as "no children" — `TC-14`; any non-zero gate result aborts the caller; an unrecognised phase is exit 1, never a silent ungated pass — `TC-18`), which is the correct posture. One informational pattern observation, not an actionable finding: `format_blocked` clamps the status field but interpolates `$child->{type}` and `$child->{num}` unclamped. This is **safe here because `parse_dirname` constrains `num` to `\d+(\.\d+)*` and `type` to `\w+`** (no whitespace, newlines, or shell metacharacters survive, and the string is only displayed into model context, never executed). Audit any future caller that populates `type`/`num` from a looser source — a raw dirname, a git ref, or user argument — before feeding it to `format_blocked`, since the no-injection property rests entirely on those `parse_dirname` regexes.

### Conclusion

No actionable security findings. The change is fail-closed, introduces no shell-string or unvalidated-git-output execution surface, and the single untrusted-text path that reaches model context (child status) is explicitly clamped with rationale. Hash-integrity of the touched hashed scripts is `cwf-manage validate`'s deterministic job and out of scope here.

> verdict: `state: no findings` — "Fail-closed subtask gate; status text clamped against prompt injection, dir-derived fields constrained by parse_dirname regex, no shell-string/git-porcelain/env surface."

## Best-Practice Review

**State**: no findings

The testing-exec delta centres on the new test suite `t/subtask-gate.t` and its execution record in `g-testing-exec.md`. Of the three tagged source sets, only Perl applies: the changeset is Perl plus Markdown, with no Go or SQL. I weighted `testing-debugging.md`, `error-handling.md`, and `modules.md`.

### Assessment against the Perl testing best-practices

`testing-debugging.md` is the governing source, and the suite aligns closely with it:

- **Strictures (guidelines 235-236).** The file opens with `use strict; use warnings; use utf8;`. Aligned.
- **Tests that fail / failing-test-before-fix (232, 234).** The doc calls the failing regression test "the single highest-leverage debugging habit." The suite goes further than a manual mutation run: TC-11 asserts `state_done($child) == 100` inline *then* asserts the gate blocks, so a `state_done`-only implementation provably cannot pass both; TC-25 asserts `"f\n" =~ /^[a-j]$/` and `!~ /\A[a-j]\z/` inline before asserting rejection. This "regression by construction" satisfies 234's intent robustly.
- **Test the unlikely / boundary and pathological inputs (233).** Strong coverage: Unicode digits (TC-24), trailing newline (TC-25), shell-injection-shaped task paths (TC-19, `'1; rm -rf /'`), empty and missing `--phase` (TC-18), 32-char truncation boundary and embedded tab (TC-15), `undef` phase (TC-7).
- **`done_testing()` over a hard-coded plan (231 notes).** Used. Aligned.
- **Fail-closed error assertion (232 + error-handling.md 171).** TC-14 asserts the unresolvable-task case *dies* rather than returning an empty list, and asserts the message — testing the error path, not just the happy path.

### Points checked and cleared

- **Test::More vs Test2::V0.** `testing-debugging.md` prefers `Test2::V0` for new test files but explicitly carves out that `Test::More` "remains correct ... where you want zero new deps (it is core)." CWF's hard core-only constraint (Test2::Suite is not core) makes `Test::More` the correct choice. Not a divergence.
- **File naming.** The doc suggests `NN-description.t`. The file is `subtask-gate.t` with no numeric prefix — but every existing suite in `t/` uses the un-numbered `description.t` form. Project consistency governs; not a finding.
- **`eval { } / $@` catching.** `error-handling.md` flags raw `eval`/`$@` catching as high-drift, preferring `Try::Tiny` or native `try`. In TC-14 this is the standard Test::More exception-assertion idiom, `Try::Tiny` is non-core, and native `try` is newer than CWF's portability floor. Appropriate as written.

One very minor readability note (below the bar for a finding, no citable rule): several `use CWF::TaskState qw(...)` imports sit inside subtest blocks rather than with the top-of-file imports. Because `use` is compile-time, those imports are global despite their local placement — a reader could misread them as block-scoped.

The testing-exec changeset is consistent with the applicable Perl testing best-practices.

> verdict: `state: no findings` — "t/subtask-gate.t aligns with the Perl testing best-practices (strict/warnings, failing regressions by construction, pathological-input coverage, done_testing); Test::More and core-only eval-catch are correct under CWF's core-only constraint; golang/postgres sources not applicable."

**Disposition**: the readability note was acted on even though it was sub-finding — the four
subtest-local `use CWF::TaskState` lines were hoisted to the top-of-file import block.
`prove -r t/` re-run green afterwards (78 files, 1073 tests).

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 225
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned test cases executed: 25 functional, 2 non-functional, all PASS. The system probe
confirms all three chokepoints refuse while a subtask is open, and that the destructive
squash is unreachable in that state.

## Lessons Learned
*To be captured during retrospective*
