# Gate exec phases on terminal subtask status - Implementation Plan
**Task**: 225 (bugfix)

## Task Reference
- **Task ID**: internal-225
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/225-gate-exec-phases-on-terminal-subtask-status
- **Template Version**: 2.1

## Goal
Land the `CWF::SubtaskGate` module, its `workflow-manager gate` CLI, three call sites,
and the doc/skill wiring, per `c-design-plan.md`.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### New files
| Path | Perms | Hash entry |
|---|---|---|
| `.cwf/lib/CWF/SubtaskGate.pm` | `0600` | `CWF::SubtaskGate`, no `permissions` key |
| `.cwf/scripts/command-helpers/workflow-manager.d/gate` | `0500` | `workflow-manager.d/gate`, `permissions: "0500"` |
| `t/subtask-gate.t` | `0644` | none (tests are not hashed) |

### Modified files
| Path | Recorded perms | Change |
|---|---|---|
| `.cwf/scripts/command-helpers/workflow-manager` | `0500` | `%commands` gains `gate`; usage string → `{status\|control\|gate}` |
| `.cwf/scripts/command-helpers/cwf-checkpoint-commit` | `0700` | gate call before `status_set` |
| `.cwf/scripts/command-helpers/checkpoints-branch-manager` | `0500` | gate call in `create_checkpoints_branch` |
| `.cwf/security/script-hashes.json` | n/a | 2 new entries + 3 refreshed `sha256` |
| `.claude/skills/cwf-implementation-exec/SKILL.md` | n/a | one-line Pre-Step |
| `.claude/skills/cwf-testing-exec/SKILL.md` | n/a | one-line Pre-Step |
| `.claude/skills/cwf-rollout/SKILL.md` | n/a | one-line Pre-Step |
| `.claude/skills/cwf-maintenance/SKILL.md` | n/a | one-line Pre-Step |
| `.claude/skills/cwf-retrospective/SKILL.md` | n/a | Pre-Step; fix "Step 6"→"Step 7" label |
| `.cwf/docs/skills/retrospective-extras.md` | n/a | gate in `j` `&&` chain + Verify Task Status |

**Hashed-file disclosure** (per `.cwf/docs/conventions/hash-updates.md`): this task edits
five hashed paths — two new, three modified. All five `script-hashes.json` changes land in
the **same commit** as the source edits (phase `f`).

## Verified Interfaces

Confirmed against source before planning, not assumed:

- `CWF::TaskPath::resolve($num, $base_dir)` → thin wrapper over `resolve_num`
  (`TaskPath.pm:197-200`), returning a hashref with `full_path`, `num`, `type`, `slug`,
  `format`, `parent_path`, `depth` (built at `TaskPath.pm:150-158`); `undef` on failure.
- `CWF::TaskPath::find_children($num, $base_dir)` → list of the same hashrefs, sorted
  (`TaskPath.pm:373-403`).
- `CWF::TaskPath::parse_branch($branch)` → `($num, $type, $slug)` or `()`
  (`TaskPath.pm:334-343`). Note the return order: **num first, type second**.
- `CWF::TaskState::state_done($task_dir)` → 0-100 (`TaskState.pm:99`); exported.
- `CWF::TaskState::status_get($file)` → status string or `"Unknown"` (`TaskState.pm:214`);
  exported. **Does not validate against the status enum on read** — only `status_set`
  validates (`TaskState.pm:260`). Consequence recorded under Security Notes.
- `CWF::WorkflowFiles::V21::get_workflow_files($task_type)` → arrayref of the expected wf
  filenames for that type, falling back to `feature` on an unknown type
  (`WorkflowFiles/V21.pm:114-118`); `V20` has the same signature.
- **`_get_all_statuses` already uses that expected set** (`TaskState.pm:309-312`) and
  **skips files that do not exist** (`:320`, `next unless -f`), dropping `Unknown`
  statuses (`:323`). Its v2.1 detection is `-f "$task_dir/f-implementation-exec.md"`
  (`:304`). The gate mirrors this exact detection so the two can never disagree on the
  file set.
- `CWF::Options::parse($spec, @args)` → opts hashref; spec is
  `{ options => [ { long => '...', type => 'value', desc => '...' } ] }`
  (`Options.pm:32-48`, shape copied from `workflow-manager.d/control:39`).
- `CWF::Common::check_perl5opt()` — assert `-CDSLA`; called at startup by `control:29`.

## Implementation Steps

### 1. `.cwf/lib/CWF/SubtaskGate.pm` (new)

```
nonterminal_children($num, $base_dir) -> @hashrefs
```

- `use strict; use warnings; use utf8; use Exporter 'import';`
  `our @EXPORT_OK = qw(nonterminal_children phase_is_gated format_blocked);`
- `use CWF::TaskPath qw(resolve find_children);`
  `use CWF::TaskState qw(state_done status_get);`
  `use CWF::WorkflowFiles::V21; use CWF::WorkflowFiles::V20;`
- Die (not return empty) when `resolve($num, $base_dir)` yields `undef` — fail closed
  per D5. Plain `die`, not `Carp::croak`: no module under `.cwf/lib/CWF/` uses `Carp`,
  and matching the siblings beats matching the textbook.
- **Thread `$base_dir` through to both** `resolve($num, $base_dir)` **and**
  `find_children($num, $base_dir)`. Omitting it makes each fall back to
  `find_base_dir()` (`TaskPath.pm:376`) — the real repo — so every fixture test would
  silently exercise the wrong tree and pass for the wrong reason.
- For each child from `find_children`, compute terminality as the conjunction of three
  conditions. A child is **terminal** iff all three hold:
  1. **Completeness**: every file in its expected set exists.
     `my $is_v21 = -f "$child->{full_path}/f-implementation-exec.md";` then
     `get_workflow_files($child->{type})` from `V21` or `V20` accordingly — the same
     detection `_get_all_statuses` performs at `TaskState.pm:304`.
  2. **Parseability**: `status_get` on each expected file returns something other than
     `Unknown`.
  3. **Closure**: `state_done($child->{full_path}) == 100`.
- Collect `(phase-file => status)` pairs for every expected file that is missing,
  `Unknown`, or whose status leaves `state_done` below 100.
- Push `{ num, type, percent, blocking_phases => \@pairs }` for each non-terminal child.
- Return the list (empty ⇒ permitted).
- `phase_is_gated($letter)` → true for `f`–`j`. Single source of truth for the gated set,
  imported by the CLI and by `cwf-checkpoint-commit`. (`checkpoints-branch-manager` does
  not import it — it is the `j`-only chokepoint and always gates.)
- `format_blocked($num, $letter, \@blocked)` → the blocked message string, so the three
  call sites render it once, not three times.

**Why all three conditions, not just `state_done == 100`.** This is the correction that
the design's D2 got wrong and plan review caught. `_get_all_statuses` iterates the
*expected* set but skips absent files (`TaskState.pm:320`) and discards `Unknown`
statuses (`:323`) before the MIN. So a child holding only a Finished `a-task-plan.md`
yields statuses `(Finished)` → MIN 100 → "terminal", and a bare `Unknown` check never
fires because no file parsed as `Unknown` — nothing was there to parse. Condition 1 is
what actually closes the partial-file fail-open; condition 2 closes the
present-but-corrupt case. Neither is redundant.

**Terminal-value list**: reuse, do not re-declare. `_is_closed` is private, so closure is
determined via `state_done == 100`, which folds it. The three literal status names appear
**once**, in the human-facing remedy string inside `format_blocked` — never as a
classification predicate.

**Status clamping in `format_blocked`.** `status_get` returns the raw text after
`**Status**:` without enum validation, and the SKILL Pre-Steps instruct the agent to
report the gate's message verbatim. Before interpolating a status into the message,
strip newlines and truncate to 32 characters. Cheap, and it keeps a crafted phase file
from routing arbitrary text into model context. See Security Notes.

### 2. `.cwf/scripts/command-helpers/workflow-manager.d/gate` (new, 0500)

- `#!/usr/bin/env perl`, `use utf8;`, `use FindBin; use lib "$FindBin::Bin/../../../lib";`
  (three levels up, matching `control:26`).
- `use CWF::Common qw(check_perl5opt); check_perl5opt();`
- `use CWF::Options qw(parse);` with `--task-path` and `--phase`, both `type => 'value'`.
- Validate: `--task-path` matches `/^\d+(\.\d+)*$/` else exit 1. `--phase` matches
  `/^[a-j]$/` else **exit 1** (fail closed on unknown phase — D5).
- `exit 0` silently unless `phase_is_gated($phase)`.
- `eval { nonterminal_children(...) }`; on death → exit 2 (task not found).
- Empty list → `exit 0`, silent.
- Otherwise print `format_blocked(...)` to **stderr** and `exit 3`.

Exit codes: `0` permitted, `1` invalid args, `2` task not found, `3` blocked. `0`–`2`
mirror `control:11-16`; `3` is subcommand-local, as `control`'s own `3`/`4` are.

Blocked message (stderr):
```
[CWF] BLOCKED: task <num> cannot enter phase <letter>
  <N> subtask(s) not in a terminal status:
    <child-num> (<type>) — <pct>% — <phase-file>: <status>[, ...]

A subtask blocks its parent until it is Finished, Skipped, or Cancelled.
Work that should not block the parent belongs in a top-level follow-up
task, not a subtask.
```
Pluralise "subtask" on `N`.

### 3. `.cwf/scripts/command-helpers/workflow-manager` (dispatcher)

Two edits, both required:
- `%commands` gains `gate => "$script_dir/workflow-manager.d/gate"` (line ~13)
- usage string on line 7 → `Usage: workflow-manager {status|control|gate}\n`

### 4. `.cwf/scripts/command-helpers/cwf-checkpoint-commit` (covers `f`–`i`)

Add the import — the file today imports only `resolve` and `status_set`
(`cwf-checkpoint-commit:8-9`), so without this the script will not compile:

```perl
use CWF::SubtaskGate qw(phase_is_gated nonterminal_children format_blocked);
```

`FindBin` and `use lib "$FindBin::Bin/../../lib"` are already present (`:5-6`); no change
there.

Insert **after** the `$letter =~ /^[a-j]$/` validation and the `resolve` (line ~30), and
**before** `status_set` (line 39):

```perl
if (phase_is_gated($letter)) {
    my @blocked = nonterminal_children($task->{num});
    if (@blocked) { warn format_blocked($task->{num}, $letter, \@blocked); exit 3 }
}
```

Called as a library function, not a subprocess — no `$? >> 8` decoding (D1). Any exception
from the module propagates and aborts the commit: fail closed (D5). It will surface as a
raw Perl `die` string rather than the `$PROG:`-prefixed messages used elsewhere in the
file; **do not "fix" that by wrapping it in an `eval`** that swallows the abort. Placement
before `status_set` matters — a blocked phase must not have its status stamped `Finished`.

### 5. `.cwf/scripts/command-helpers/checkpoints-branch-manager` (covers `j`)

In `create_checkpoints_branch` (defined at line 25), insert **after**
`my $branch = get_current_branch();` (line 26) and **before** the
`system("git", "branch", ...)` at line 29:

- `my ($num) = parse_branch($branch);` — remember num is the **first** return value
  (`TaskPath.pm:339` returns `($2, $1, $3)`).
- If `$num` is defined and `nonterminal_children($num)` is non-empty →
  `die format_blocked($num, 'j', \@blocked);` — pass the literal `'j'`, since this script
  is reached only from the retrospective.
- If `parse_branch` returns `()`, leave existing behaviour alone; no new failure path.
  `get_current_branch` (line 21) already dies when not on a branch.

This is the `j` chokepoint. It runs immediately before the `git reset --soft` squash and
is called by no other phase.

Adds to a script that currently imports no `CWF::*` modules:
```perl
use FindBin;
use lib "$FindBin::Bin/../../lib";   # TWO levels — this file is in command-helpers/,
                                     # not command-helpers/workflow-manager.d/
use CWF::TaskPath qw(parse_branch);
use CWF::SubtaskGate qw(nonterminal_children format_blocked);
```
The depth differs from the gate CLI's three levels (Step 2). Copying the three-level form
here would fail to locate `CWF::`. Matches `cwf-checkpoint-commit:6`.

### 6. Five SKILL.md Pre-Steps

One line each, above the existing preamble step. In `cwf-retrospective/SKILL.md` place it
alongside the existing "Pre-Step: Verify git branch":

```
**Pre-Step**: Subtask gate. Run `.cwf/scripts/command-helpers/workflow-manager gate --task-path=<task-path> --phase=<letter>`. Non-zero exit: STOP and report its message verbatim.
```

Substitute the phase letter per skill: `f`, `g`, `h`, `i`, `j`.

While in `cwf-retrospective/SKILL.md`, fix the pre-existing label error at line 41: it says
"Step 6: Verify task status" but the anchor it references is headed "(Step 7)" in
`retrospective-extras.md:15`. Align to Step 7.

### 7. `.cwf/docs/skills/retrospective-extras.md`

- In "Verify Task Status (Step 7)", add the gate as check 0, before the existing
  100%-status check.
- In "Retrospective Checkpoint Commit", prepend the gate to the `&&` chain so it precedes
  `cwf-set-status`, inheriting the documented "non-zero ⇒ no commit" property.

**Why `j` gets three gate sites and `f`–`i` get two.** Plan review asked whether this is
redundant. It is not: each site guards a distinct failure, and they fire at different
times.
1. The SKILL Pre-Step halts on *entry*, before a phase's work is wasted.
2. The `&&`-chain gate fires at the `j` *commit*, which happens **before** the Step-10
   squash. Without it, a blocked retrospective would still stamp `j-retrospective.md` as
   `Finished` and commit it — recording the parent as complete while a child is open.
3. `checkpoints-branch-manager create` fires at the *squash*, guarding the destructive
   branch rewrite that stranded the reporter's subtask base.

Removing (2) would leave a window where the parent is falsely marked done; removing (3)
would leave the reported bug's own operation unguarded. Only (1) is advisory.

### 8. Hash refresh (same commit — non-negotiable)

Per `.cwf/docs/conventions/hash-updates.md`:
1. Make all source edits.
2. `sha256sum` each of the five paths (use `sha256sum`, not a Perl digest —
   verifier/producer implementation diversity).
3. Add two new entries, refresh three `sha256` values, in `script-hashes.json`.
4. Restore each edited file to its **recorded** permission, not a bumped value:
   `workflow-manager` → `0500`, `checkpoints-branch-manager` → `0500`,
   `cwf-checkpoint-commit` → `0700` (its recorded ceiling is genuinely `0700`),
   new `gate` → `0500`, new `.pm` → `0600`.
5. `.cwf/scripts/cwf-manage validate` → must report OK.

**Pre-refresh verification**: `git log <last-hash-set-commit>..HEAD -- <path>` per file, to
confirm the only intervening changes are this task's. `validate` is currently OK at
`ffb4fd8`, so no inherited drift is being absorbed.

## Security Notes
- **Accepted, deliberate (FR4(c))**: `format_blocked` interpolates `status_get` output,
  which is *unvalidated on read* (`TaskState.pm:214` — only `status_set` validates against
  the enum), and the SKILL Pre-Steps tell the agent to report the message verbatim. A
  crafted phase file could therefore route text into model context. This sits inside the
  user's own-repo trust boundary, the same domain as the task docs themselves, so the risk
  is low — but it is mitigated rather than merely accepted: statuses are newline-stripped
  and truncated to 32 characters before interpolation (Step 1).
- **Safe, with a stated invariant (FR4(e))**: the expected-file existence check builds
  paths from `$child->{full_path}`, which derives from `base_dir` plus validated numeric
  task directories, carrying no user free-text. Matches the existing precedent at
  `cwf-checkpoint-commit:32`. Audit if ever reused with a slug- or branch-derived path.
- No `system($string)` shell calls; no new environment-variable reads.

## Known Residuals (recorded, not defended)
- A child directory whose name fails `parse_dirname` is silently skipped by
  `find_children` (`TaskPath.pm:388-389`), so a malformed child does not block its parent.
  Same class as the deleted-phase-file residual, and out of threat model: `/cwf-new-task`
  is the only supported way to create one.
- D3's induction (direct children only) presumes the gate exists. A repository already
  holding a Finished child above an open grandchild lets the parent through.

## Test Coverage
Specified in full in `e-testing-plan.md`. Summary of what `t/subtask-gate.t` must cover:
- no children → permitted
- all children Finished / Skipped / Cancelled (each alone, and mixed) → permitted
- one child In Progress / Testing / Blocked / Backlog / To-Do → blocked
- child with a present-but-`Unknown` status → blocked (condition 2)
- child with only `a-task-plan.md` present, Finished → blocked (condition 1, the
  partial-file fail-open). **This test fails against a `state_done == 100`-only
  implementation** — it is the regression test for the bug plan review found in D2.
- phase `a`–`e` → permitted even with a non-terminal child
- phase `z` / empty → exit 1, not exit 0 (the fail-open hole from D5)
- grandchild non-terminal, child terminal → parent permitted (D3 induction is intentional)
- exit codes 0/1/2/3 distinct

Fixtures build a temp task tree with `File::Temp::tempdir(CLEANUP => 1)` and pass an
explicit `$base_dir` — which the module must forward to `resolve` *and* `find_children`,
or the fixtures silently test the real repo. Mirrors `t/validate-hooks.t`. Perl core
modules only.

## Validation Criteria
- [ ] `prove -r t/` fully green (bare, no inline `PERL5OPT`)
- [ ] `.cwf/scripts/cwf-manage validate` reports OK
- [ ] `workflow-manager gate --task-path=225 --phase=j` exits 0 (225 has no children)
- [ ] `workflow-manager gate --task-path=225 --phase=Z` exits 1
- [ ] Manual: create a throwaway subtask, confirm `cwf-checkpoint-commit 225 f` refuses,
      then confirm it succeeds once the child is Cancelled; delete the throwaway
- [ ] Both exec-phase security review columns report `no findings`

## Sequencing
Module → CLI → dispatcher → tests green → three call sites → skills/docs → hash refresh →
`validate`. Tests precede the call sites so the module's contract is pinned before anything
depends on it.

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No.
- [ ] **Risk**: needs isolation? No.
- [ ] **Independence**: separable? No.

**Result**: 0 of 5 signals. No decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 225
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All ten steps executed; per-step Planned/Actual/Deviations are recorded in
`f-implementation-exec.md`. Two deviations from this plan:

1. The plan instructed changing `cwf-retrospective/SKILL.md:41` "Step 6" → "Step 7".
   The SKILL was internally consistent; the heading in `retrospective-extras.md` was the
   one off by one. Corrected in the opposite direction to what the plan specified.
2. `CWF::TaskState::expected_files()` was extracted (unplanned) after the improvements
   and misalignment reviewers independently flagged the duplicated format-detection block.

## Lessons Learned
A plan that names a `path:line` and the correction to make there must be checked against
the file before it is followed — this one would have broken a correct file to match an
incorrect one. Steps that edit hashed scripts must disclose the same-commit
`script-hashes.json` refresh at plan time; editing files *after* computing their hashes
produced two spurious full-suite failures that cost time to diagnose as drift, not
regression.
