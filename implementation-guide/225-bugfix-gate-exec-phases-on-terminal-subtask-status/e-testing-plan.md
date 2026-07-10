# Gate exec phases on terminal subtask status - Testing Plan
**Task**: 225 (bugfix)

## Task Reference
- **Task ID**: internal-225
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/225-gate-exec-phases-on-terminal-subtask-status
- **Template Version**: 2.1

## Goal
Define the test strategy for `CWF::SubtaskGate` and the `workflow-manager gate` CLI, with
particular weight on the fail-open cases, since a safety gate that wrongly *permits* is
the only failure mode that matters.

## Test Strategy

### Test Levels
- **Unit** (`t/subtask-gate.t`): `nonterminal_children`, `phase_is_gated`,
  `format_blocked` called directly with an explicit `$base_dir` against a `File::Temp`
  task tree. This is where the bulk of coverage lives — the module is a pure function.
- **Integration (CLI)** (`t/subtask-gate.t`, same file): execute
  `workflow-manager gate` as a subprocess and assert on exit codes and stderr.
- **System (manual, recorded in `g-testing-exec.md`)**: a throwaway real subtask under
  task 225, confirming `cwf-checkpoint-commit` actually refuses.

### Coverage Target
Every branch of `nonterminal_children`'s three-condition conjunction, plus every exit
code of the CLI. The three fail-open holes identified in design and plan review each get
a dedicated, named regression test.

### Environment
- Perl core modules only (`Test::More`, `File::Temp`, `File::Path`, `FindBin`) — the
  macOS system-perl portability constraint forbids CPAN deps.
- `PERL5OPT=-CDSLA` comes from the settings env; the suite runs as bare `prove -r t/`.
- Fixtures under `File::Temp::tempdir(CLEANUP => 1)`, mirroring `t/validate-hooks.t`.

### Fixture Design

A helper builds a task tree at an arbitrary root:

```
<root>/implementation-guide/<num>-<type>-<slug>/{a-task-plan.md, c-…, d-…, e-…, f-…, g-…, j-…}
```

Each file carries a `**Status**: <value>` line and a `- **Template Version**: 2.1` header
line. The presence of `f-implementation-exec.md` is what makes `_get_all_statuses` treat
the task as v2.1 (`TaskState.pm:304`), so fixtures must include it for the expected-set
lookup to match. A `bugfix` child expects exactly the 7 files `a c d e f g j`.

**Two fixture hazards, both load-bearing:**
1. `$base_dir` must be passed explicitly into `nonterminal_children`. If the module fails
   to forward it to `resolve` *and* `find_children`, both silently fall back to
   `find_base_dir()` (`TaskPath.pm:376`) — the real CWF repo — and the tests pass for the
   wrong reason. **TC-13 exists specifically to detect that.**
2. The CLI takes no `--base-dir`. `find_base_dir` returns the git root's
   `implementation-guide` when one exists (`TaskPath.pm:39-42`). CLI tests must therefore
   `chdir` to a tempdir **outside** this repository, where `find_git_root()` returns
   undef and the relative-path fallback (`:45-47`) picks up the fixture. Restore the
   original cwd afterwards.

## Functional Test Cases

### Permitted paths (gate must not fire)

**TC-1 — No children**
Given a parent task with no subtask directories
When `nonterminal_children(parent)` is called
Then it returns the empty list

**TC-2 — Single Finished child**
Given a child whose 7 expected files all read `Finished`
When the gate runs for phase `f`
Then permitted

**TC-3 — Single Skipped child**
As TC-2 but all statuses `Skipped` → permitted

**TC-4 — Single Cancelled child**
As TC-2 but all statuses `Cancelled` → permitted.
This one matters: `Cancelled` maps to **0%** in the raw status map
(`TaskState.pm:33`) and is only rescued to 100 by `_is_closed` inside `state_done`. A
naive percentage check would wrongly block here.

**TC-5 — Mixed terminal statuses across phases**
Given one child with a mix of `Finished`, `Skipped`, and `Cancelled` across its 7 files
Then permitted

**TC-6 — Multiple children, all terminal**
Given two sibling children, both fully terminal → permitted

**TC-7 — Plan phases are ungated**
Given a child that is `In Progress`
When `phase_is_gated` is asked about `a`, `b`, `c`, `d`, `e`
Then false for each; and the CLI exits 0 for `--phase=a` despite the open child

**TC-8 — Induction: grandchild does not block grandparent**
Given parent `1`, child `1.1` fully terminal, grandchild `1.1.1` `In Progress`
When the gate runs for parent `1`
Then permitted (D3 — `1.1`'s own gate is what catches `1.1.1`)

### Blocked paths (gate must fire)

**TC-9 — Non-terminal status blocks, one case per status**
Given a child with one phase set to each of `In Progress`, `Testing`, `Blocked`,
`Backlog`, `To-Do` (five sub-cases, rest `Finished`)
Then blocked in every case, and `blocking_phases` names the offending file and status

**TC-10 — `Unknown` status blocks** *(regression: condition 2)*
Given a child whose `c-design-plan.md` has a corrupt/absent `**Status**:` line, so
`status_get` returns `Unknown`, and all other files read `Finished`
Then blocked.
Rationale: `_get_all_statuses` *discards* `Unknown` (`TaskState.pm:323`), so
`state_done` returns 100 here. Without the explicit `Unknown` check the gate fails open.

**TC-11 — Partial file set blocks** *(regression: condition 1 — the D2 bug)*
Given a child directory containing **only** `a-task-plan.md`, status `Finished`
Then blocked, and `blocking_phases` names the six missing files.
Rationale: `_get_all_statuses` skips absent files (`TaskState.pm:320`), so `state_done`
returns 100 and no `Unknown` is ever seen. **This test fails against the original design
(D2 as first written) and passes only with the expected-set existence check.** It is the
single most important case in this file.

**TC-12 — One terminal child, one non-terminal sibling**
Given two children, one fully `Finished`, one `In Progress`
Then blocked, and only the `In Progress` child appears in the returned list

### Contract and plumbing

**TC-13 — `$base_dir` is honoured** *(regression: fixture-integrity)*
Given a fixture tree with a non-terminal child, at a tempdir root
When `nonterminal_children($num, $fixture_base)` is called from a cwd inside the real CWF
repository
Then the result reflects the **fixture**, not the real repo.
Asserted by using a task number that exists in the fixture with an open child and either
does not exist in the real repo, or exists there with no children — so a `$base_dir`
regression flips the result.

**TC-14 — Unresolvable task dies**
Given a task number absent from the fixture
When `nonterminal_children` is called
Then it dies (fail closed), rather than returning the empty list (which would read as
"permitted")

**TC-15 — `format_blocked` clamps status text** *(security)*
Given a child whose status line contains embedded newlines and 200 characters of text
When `format_blocked` renders it
Then the emitted status token contains no newline and is ≤ 32 characters

### CLI exit codes

**TC-16 — Exit 0, silent, on permitted**
`gate --task-path=<terminal-parent> --phase=j` → exit 0, empty stderr

**TC-17 — Exit 3 on blocked, with remedy**
`gate --task-path=<parent-with-open-child> --phase=f` → exit 3; stderr contains
`[CWF] BLOCKED`, the child's number, and the words `Finished`, `Skipped`, `Cancelled`

**TC-18 — Exit 1 on unknown phase** *(regression: the D5 fail-open)*
`--phase=Z`, `--phase=1`, and `--phase=` (empty) each → **exit 1**, not exit 0.
Rationale: an unrecognised phase must never be silently treated as ungated.

**TC-19 — Exit 1 on malformed task path**
`--task-path='1; rm -rf /'` and `--task-path=abc` → exit 1, and no shell execution occurs

**TC-20 — Exit 2 on task not found**
`--task-path=99999` against the fixture → exit 2, distinct from both 1 and 3

**TC-21 — Dispatcher registers the subcommand**
`workflow-manager gate --help`-less invocation with no args → the dispatcher does not
report `Unknown subcommand`; and `workflow-manager` with no args prints a usage string
containing `gate`

## Non-Functional Test Cases

**TC-22 — Permitted path stays silent**
No output on stdout or stderr when permitted (TC-16). A gate that chatters on every phase
entry trains users to ignore it.

**TC-23 — Suite and integrity gates**
- `prove -r t/` fully green, invoked bare (no inline `PERL5OPT`)
- `.cwf/scripts/cwf-manage validate` reports OK after the hash refresh
- File permissions match recorded ceilings: `gate` 0500, `SubtaskGate.pm` 0600

## System / Manual Validation

Recorded in `g-testing-exec.md` at execution time:
1. `/cwf-new-subtask 225 1 chore "throwaway gate probe"` creates `225.1`
2. `cwf-checkpoint-commit 225 f "probe"` → **must refuse**, exit 3, naming `225.1`
3. Set every `225.1` phase to `Cancelled`
4. `cwf-checkpoint-commit 225 f "probe"` → now proceeds
5. `/cwf-delete-task 225.1` to remove the probe; confirm `cwf-manage validate` still OK

Step 2 is the end-to-end proof of the reported bug being fixed. Steps 3-5 must leave the
tree exactly as found — the probe is scaffolding, not a deliverable.

## Test Environment
- Local checkout, no network, no database.
- No production or shared state touched: all fixtures under `File::Temp` with
  `CLEANUP => 1`; the one real-tree probe is created and deleted within the same phase.

## Validation Criteria
- [ ] TC-1 … TC-23 all pass
- [ ] TC-11 verified to **fail** against a `state_done == 100`-only implementation before
      the fix is applied (a regression test that never fails is not a regression test)
- [ ] TC-18 verified to **fail** against an implementation that exits 0 on unknown phases
- [ ] `prove -r t/` green; total test-file count rises by one
- [ ] `cwf-manage validate` OK
- [ ] Both exec-phase security review columns report `no findings`

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No.
- [ ] **Risk**: needs isolation? No.
- [ ] **Independence**: separable? No.

**Result**: 0 of 5 signals. No decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 225
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned test cases executed and PASS; `t/subtask-gate.t` is 19 top-level subtests
covering TC-1…TC-25. Full suite: 78 files, 1073 tests, all PASS. Three cases were added
beyond this plan: TC-11b (format-misdetection variant), TC-24 (Unicode-digit task path),
TC-25 (trailing-newline phase letter). Results and the system probe are recorded in
`g-testing-exec.md`.

## Lessons Learned
**This plan's TC-11 reproducer was factually wrong, and the test caught it.** The plan
asserted a child holding only a Finished `a-task-plan.md` would aggregate to
`state_done == 100`. It aggregates to 0: removing `f-implementation-exec.md` flips the
version detection at `TaskState.pm:304` to v2.0, whose filenames differ entirely, so no
expected file is found. The genuine fail-open requires the v2.1 marker to be present.
The lesson generalises — a testing plan's claim about what unfixed code *does* is a
hypothesis. Asserting it inline in the test (TC-11 asserts `state_done == 100` before
asserting the gate blocks) turns that hypothesis into something the suite verifies
rather than something the reader trusts.
