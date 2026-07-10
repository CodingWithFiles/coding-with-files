# Gate exec phases on terminal subtask status - Design
**Task**: 225 (bugfix)

## Task Reference
- **Task ID**: internal-225
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/225-gate-exec-phases-on-terminal-subtask-status
- **Template Version**: 2.1

## Goal
Define the mechanism by which a parent task is prevented from entering phase `f`, `g`,
`h`, `i`, or `j` while any direct child subtask is in a non-terminal status.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### D1: The gate is a shared library function, not a subprocess contract

- **Decision**: The scan — "find direct children, classify each, collect the
  non-terminal ones" — lives in one new module, `CWF::SubtaskGate`, exporting
  `nonterminal_children($num, $base_dir)`. Both callers `use` it directly.
- **Rationale**: Every caller (`workflow-manager.d/gate`, `cwf-checkpoint-commit`,
  `checkpoints-branch-manager`) is already Perl importing the same `CWF::*` modules the
  scan needs. Shelling out would force each caller to decode `$? >> 8` to tell a policy
  block from a broken invocation, and would make the core logic testable only through an
  exit-code contract. A pure function returning a list of hashrefs is directly
  unit-testable, which is this design's top-priority quality.
- **Trade-offs**: One new module file. Justified: `CWF::TaskPath` (paths, no status
  awareness) and `CWF::TaskState` (status of a directory, no path/hierarchy awareness)
  are cleanly layered today, and the scan needs both. Hosting it in `TaskState` would
  make the status layer depend on the path layer purely for this one function.
- **Rejected — inline the scan in each caller**: would create the second
  child-discovery/status-classification code path this task exists to avoid.

### D2: Reuse `state_done()` as the terminal predicate — write no new status logic

- **Decision**: A child is *terminal* iff all three hold: (1) every file in its expected wf
  set exists, (2) none yields an `Unknown` status, and (3)
  `CWF::TaskState::state_done($child_dir) == 100`.

> **Corrected during implementation-plan review.** This decision originally read
> "`state_done == 100` **and** no `Unknown`", with the `Unknown` conjunct claimed to close
> the partial-file fail-open. It does not. `_get_all_statuses` skips files that do not
> exist (`TaskState.pm:320`) *before* dropping `Unknown` ones (`:323`), so a child holding
> only a Finished `a-task-plan.md` produces statuses `(Finished)` → MIN 100 → "terminal",
> and no `Unknown` is ever seen because no file was there to parse. Condition (1) — an
> explicit expected-set existence check via
> `CWF::WorkflowFiles::V21::get_workflow_files($type)` — is what actually closes it.
> Retained here rather than silently rewritten: the original reasoning was wrong in a way
> worth recording.
- **Rationale**: `state_done` (`TaskState.pm:99`) folds every closed status to 100 via
  `_is_closed` (`TaskState.pm:330` — exactly `Finished || Cancelled || Skipped`) then
  takes the MIN across phases. The non-terminal statuses top out at `Testing` (75), so
  `state_done == 100` holds iff every *counted* phase is closed. A fully-Cancelled child
  correctly reads terminal despite Cancelled being 0% in the raw map, because `_is_closed`
  shortcircuits it before the MIN.
- **Conditions (1) and (2) are load-bearing, not belt-and-braces.** `_get_all_statuses`
  (`TaskState.pm:318-323`) iterates the type's *expected* file set, skips any file that
  does not exist (`next unless -f`), and drops any status parsing as `Unknown` — all
  before the MIN. So `state_done == 100` alone is **fail-open on a safety gate** in two
  distinct ways: a child missing most of its phase files reads terminal (closed by
  condition 1), and a child whose only remaining statuses are corrupt reads terminal
  (closed by condition 2). The gate obtains the expected set from the same primitive
  `_get_all_statuses` uses, `CWF::WorkflowFiles::V21/V20::get_workflow_files($type)`,
  mirroring its v2.1 detection (`-f f-implementation-exec.md`, `TaskState.pm:304`) so the
  two can never disagree on the file set. This composes existing primitives rather than
  duplicating any.
- **Residual (bounded, accepted)**: a child whose *directory name* is malformed is skipped
  by `find_children` (`TaskPath.pm:388-389`) and does not block its parent. `/cwf-new-task`
  is the only supported way to create a subtask. Out of threat model; recorded, not
  defended.
- **Rejected**: a second status-classification list inside the gate. CWF has exactly one;
  a second would drift.

### D3: Direct children only — recursion is unnecessary

- **Decision**: The gate inspects `find_children()` (`TaskPath.pm:373`), not
  `find_descendants()` (`:467`).
- **Rationale**: Induction. If grandchild `1.1.1` is non-terminal, its parent `1.1` cannot
  itself have passed the gate to reach its own `j`, so `1.1` is not terminal, so `1.1`
  blocks `1` at the direct-child level. Scanning descendants re-detects the same condition
  at greater cost, and names tasks the user cannot act on directly.
- **Trade-offs**: The induction holds only once the gate exists. A repository with
  pre-existing malformed state (a Finished `1.1` above an open `1.1.1`) lets `1` through.
  Acceptable — that state is already invalid.

### D4: Gate CLI lives in `workflow-manager.d/gate`, a new subcommand

- **Decision**: `workflow-manager gate --task-path=<num> --phase=<letter>`, a thin CLI
  wrapper over `CWF::SubtaskGate`.
- **Rationale**: `workflow-manager` owns wf-step semantics and already exposes `status`
  and `control`, both taking `--task-path`. The `<name>.d/` dispatch pattern is the
  documented convention (`docs/conventions/design-alignment.md`, §"`<name>.d/` subdirectory
  pattern"). The gate is a statement about a *phase transition* — `workflow-manager`'s
  domain, not `task-workflow`'s (task lifecycle) or `context-manager`'s (hierarchy).
- **The CLI is required, not decorative**: the five SKILL.md pre-steps (D6) need a callable
  entry point; they cannot `use` a Perl module.
- **Consistency**: `gate` reuses `CWF::Options::parse` and calls `check_perl5opt()` at
  startup, matching its sibling `control` (`workflow-manager.d/control:27-31`). The
  `check_perl5opt()` call is what makes the em dash in the blocked-path message safe to
  print; without the `-CDSLA` layer Perl warns "Wide character in print".
- **Rejected — extending `control`**: `control` answers "what comes next after this step"
  (an *exit* question). The gate answers "may I begin this step" (an *entry* question).
  One subcommand serving both directions would have an ambiguous contract and overloaded
  exit codes.

### D5: Fail closed, always

Three distinct fail-open holes were identified in review; all are closed by decision here.

- **Unrecognised phase → error, not permission.** `--phase` values outside `a`–`j` exit 1
  (usage error). Collapsing "known-ungated `a`–`e`" and "unknown garbage" into the same
  silent exit 0 would let a truncated or typo'd argument disable the gate.
- **Any non-zero gate result aborts the caller.** `cwf-checkpoint-commit` and
  `checkpoints-branch-manager` abort on *any* failure, not only on the "blocked" code. A
  gate that silently permits when it malfunctions (resolve failure, base-dir not found, a
  future `state_done` refactor) is precisely the defect this task exists to prevent.
  Because callers `use` the module rather than shelling out (D1), a malfunction surfaces
  as a Perl exception, not a swallowed exit code.
- **Unknown or absent statuses → non-terminal.** Covered in D2. A child with no parseable
  wf status yields `state_done == 0` and blocks, which is already the correct direction.

### D6: Two enforcement layers — prose pre-step *and* script chokepoint

- **Decision**:
  1. **Advisory, early**: each of the five SKILL.md files gains a one-line Pre-Step running
     `workflow-manager gate`.
  2. **Mandatory, deterministic**: `cwf-checkpoint-commit` calls `CWF::SubtaskGate` before
     `status_set` and refuses to commit on failure.
- **Rationale**: Layer 2 alone delivers the guarantee, so layer 1 is a deliberate,
  weighed addition rather than a default. It is kept because it halts the agent *before*
  it does a phase's worth of work, rather than after — the difference between a wasted
  turn and a wasted phase. It is one line per skill with no backing doc, so its
  maintenance cost is proportionate.
- **Layer 1 is explicitly not trusted.** Agents skip prose steps they judge low-value
  (this skill's own Gotcha 1 states as much). Enforcement lives in the scripts.
- **Trade-offs**: The check runs twice on the happy path — a directory glob and a few
  small file reads. Irrelevant beside the failure it prevents.
- **Rejected — a `.cwf/docs/skills/subtask-gate.md` reference doc**: what each skill needs
  is one command line. The rationale already lives in this design doc, and the user-facing
  remedy is already emitted by the gate's own stderr. A new file, cross-linked from five
  places, to hold one invocation is a part the design is better without.

### D7: Phase `j` gets a real script chokepoint at the squash

- **Decision**: `checkpoints-branch-manager create` calls `CWF::SubtaskGate` and refuses to
  run when a child is non-terminal. It derives the task number from the current branch via
  the existing `CWF::TaskPath::parse_branch`.
- **Rationale**: Phases `a`–`i` commit through `cwf-checkpoint-commit`, but `j` makes its
  own whole-directory commit and never calls it. Leaving `j` on prose enforcement alone
  would put the *softest* layer on the phase where the reported damage actually occurred.
  `checkpoints-branch-manager create` is invoked at Step 10.1, immediately before the
  `git reset --soft` squash, and is called by no other phase. Gating it guards the exact
  destructive operation — the branch rewrite that stranded the reporter's subtask base.
- **Trade-offs**: Adds `CWF::*` imports to a script that currently has none. Accepted:
  `parse_branch` already exists and the alternative is leaving the reported bug's own
  phase unenforced.
- **Also**: the gate is prepended to the `j` commit `&&` chain and to the "Verify Task
  Status" section of `retrospective-extras.md`. Note a pre-existing discrepancy to fix in
  passing — `cwf-retrospective/SKILL.md:41` calls it "Step 6" while
  `retrospective-extras.md:15` heads the section "(Step 7)".

### D8: Phases `a`–`e` are explicitly ungated

- **Decision**: For phase letters `a`–`e` the gate exits 0, silently.
- **Rationale**: Decomposition is *discovered* during `f`. The documented flow is: enter
  `f`, hit a decomposition signal, create a subtask, complete it, resume `f`. A gate on
  subtask *creation*, or one that could not be re-entered, would make that flow
  impossible. Gating only on phase *entry* preserves it: the parent's `f` simply cannot be
  committed until the child reaches a terminal status.
- **Trade-offs**: The parent's `f` file sits at `In Progress` while children run. That is
  an accurate description of reality, not a defect.

## System Design

### Component Overview
- **`.cwf/lib/CWF/SubtaskGate.pm`** (new): `nonterminal_children($num, $base_dir)` →
  list of hashrefs `{ num, type, percent, blocking_phases }`. Pure, read-only, no side
  effects. The single home for the scan.
- **`workflow-manager.d/gate`** (new, hashed, 0500): thin CLI over the module. Formats the
  blocked message, maps to exit codes.
- **`workflow-manager`** (modified, hashed): dispatcher `%commands` hash gains `gate`, and
  the usage string becomes `{status|control|gate}`. Both edits are required, not
  incidental.
- **`cwf-checkpoint-commit`** (modified, hashed): calls the module before `status_set`;
  aborts the whole commit on any failure. Covers phases `f`–`i`.
- **`checkpoints-branch-manager`** (modified, hashed): `create` calls the module; aborts
  before the squash. Covers phase `j`.
- **Five SKILL.md files** (`cwf-implementation-exec`, `cwf-testing-exec`, `cwf-rollout`,
  `cwf-maintenance`, `cwf-retrospective`): one-line Pre-Step each.
- **`retrospective-extras.md`** (modified): gate joins the `j` commit chain and the Verify
  Task Status section.

### Data Flow
1. Agent enters phase `f`–`j` → SKILL.md Pre-Step runs `workflow-manager gate`
2. `gate` → `CWF::SubtaskGate::nonterminal_children()`
3. → `CWF::TaskPath::resolve()` → task dir; `find_children()` → direct child hashrefs
4. For each child → `CWF::TaskState::state_done($child->{full_path})`, plus `status_get`
   over the child's `[a-j]-*.md` files to detect `Unknown`
5. Any child non-terminal → gate prints the blocked message → exit 3
6. No children, all terminal, or phase `a`–`e` → exit 0, silent
7. At commit time, `cwf-checkpoint-commit` (`f`–`i`) or `checkpoints-branch-manager create`
   (`j`) calls the same module function directly and aborts on any failure

## Interface Design

### Library
```
CWF::SubtaskGate::nonterminal_children($num, $base_dir) -> @hashrefs
```
Returns the empty list when the task has no children or all are terminal. Dies on an
unresolvable task (callers do not catch — see D5, fail closed).

### Command
```
workflow-manager gate --task-path=<num> --phase=<letter>
```

### Exit Codes
Codes 0–2 are aligned with the sibling `control` subcommand; 3+ are subcommand-specific,
which is the pattern `control` itself already follows (its 3 and 4 are local meanings).

- **0** — permitted (phase `a`–`e`, or no children, or all children terminal)
- **1** — invalid arguments (including any `--phase` outside `a`–`j`)
- **2** — task not found
- **3** — blocked: at least one direct child is non-terminal

### Blocked-path stderr
```
[CWF] BLOCKED: task 68 cannot enter phase j
  1 subtask is not in a terminal status:
    68.1 (bugfix) — 25% — a-task-plan: In Progress

A subtask blocks its parent until it is Finished, Skipped, or Cancelled.
Work that should not block the parent belongs in a top-level follow-up
task, not a subtask.
```
The remedy line is mandatory: a user hitting this gate must never be left without a next
action, and the three terminal statuses are named explicitly.

### Permitted path
Silent, exit 0. A gate that chatters on every phase entry trains users to ignore it.

## Constraints
- Perl core modules only; `#!/usr/bin/env perl` and `use utf8;` in the new script and module
- `check_perl5opt()` in the new CLI, matching `control` — required for the em dash to print
- **Hashed files needing a same-commit `script-hashes.json` refresh**: `workflow-manager.d/gate`
  (new), `CWF/SubtaskGate.pm` (new), `workflow-manager` (modified), `cwf-checkpoint-commit`
  (modified), `checkpoints-branch-manager` (modified) — five entries, not two
- New CLI permissions 0500 (sibling-matched); the new `.pm` takes no `permissions` key and
  stays `100644`, matching its `CWF/` siblings
- No new child-discovery or status-classification code path

## Security Notes
- No shell: the module is pure Perl over `glob` and file reads; the CLI adds no `system`
  call. Existing `system` sites in the modified callers remain list-form.
- No environment-variable reads beyond the existing `check_perl5opt()` assertion.
- **Accepted, deliberate**: the blocked message renders child-derived strings (task number,
  type, status text) into agent-visible output, so task-tree content reaches model context.
  These are controlled-vocabulary values from directory names and a fixed status set;
  practical injection risk is negligible. Recorded because it is the one place task-tree
  content flows verbatim into context.

## Open Question Deferred From Planning

**"Finished" does not imply "merged".** The strict gate makes the reported squash stranding
unreachable *provided* Finished children have been merged into the parent branch. A child
can today be Finished and unmerged, in which case `j` squashes the parent and strands the
child's base exactly as reported.

**Resolution**: out of scope, recorded as a follow-up. The gate is a *status* invariant,
testable purely against the file tree; a merged-ness check is a *git* invariant needing
branch resolution, ancestry checks, and a policy for already-deleted child branches.
Bundling them would double the surface and delay the fix for the common case.
`CWF::TaskPath::parent_branch_ancestry()` (`TaskPath.pm:536`) already exists and looks like
the right primitive.

A deliberate narrowing, not an oversight — recorded so the retrospective raises the
follow-up task.

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — one module, three call sites, one doc set.
- [ ] **Risk**: high-risk components needing isolation? No.
- [ ] **Independence**: separable parts? No — gate and wiring are meaningless apart.

**Result**: 0 of 5 signals. No decomposition.

## Validation
- [x] Design review completed (5-agent map/reduce, Step 8; all five columns ran)
- [x] Integration points verified against source (`TaskPath.pm:373,467,536`,
      `TaskState.pm:99,320,330`, `cwf-checkpoint-commit:18,39,45`,
      `workflow-manager:7-13`, `workflow-manager.d/control:11-16,27-31`,
      `script-hashes.json:404`)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 225
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
The design was implemented as specified. All three chokepoints were kept against a
reviewer's suggestion to cut one, because each guards a distinct failure at a distinct
time. Design conditions 2 and 3 collapsed into a single per-file terminality predicate,
which also yields the offending phase names for free. One unplanned extraction —
`CWF::TaskState::expected_files()` — removed a format-detection block the gate had
copied from `_get_all_statuses`.

## Lessons Learned
The "Finished does not imply merged" deferral was correct: it is a git invariant, not a
status invariant, and bundling it would have doubled the surface. The prompt-injection
note (task-tree content reaching model context verbatim) proved load-bearing — the
implementation clamps the one free-text field, and the security reviewer traced every
other interpolated field back to `parse_dirname`'s regexes.
