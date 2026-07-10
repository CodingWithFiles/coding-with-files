# Gate exec phases on terminal subtask status - Implementation Execution
**Task**: 225 (bugfix)

## Task Reference
- **Task ID**: internal-225
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/225-gate-exec-phases-on-terminal-subtask-status
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met (`cwf-manage validate` OK at `ffb4fd8`)
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan

## Actual Results

### Step 1: `.cwf/lib/CWF/SubtaskGate.pm` (new)
- **Planned**: `nonterminal_children`, `phase_is_gated`, `format_blocked`; terminality as a
  three-condition conjunction (completeness, parseability, closure); `$base_dir` threaded to
  both `resolve` and `find_children`; status clamping in `format_blocked`.
- **Actual**: As planned. 0600, exports the three functions, no `Carp`, core-only.
- **Deviations**: Two, both simplifications the plan's own reasoning implies.
  1. **Conditions 2 and 3 collapse into one predicate.** The plan specified a literal
     `Unknown` check *and* `state_done == 100`. But `Unknown` is not a terminal status, so a
     per-file terminality test subsumes it. The gate now walks the expected set once, marking
     each file `missing` or non-terminal. Given condition 1 holds, this is exactly equivalent
     to `state_done == 100` (`state_done`'s MIN is 100 iff every status is closed), and it
     yields the offending phase names for free rather than requiring a second pass.
  2. **`state_done` is retained for display only** — the `percent` field of each blocked
     child. Calling it for the decision as well would be redundant.

### Step 1a: `.cwf/lib/CWF/TaskState.pm` — new exports `status_is_terminal`, `expected_files` (unplanned)
- **Planned**: Not planned. The plan said "reuse, do not re-declare … `_is_closed` is private,
  so closure is determined via `state_done == 100`".
- **Actual**: `_is_closed`'s body moved to a new exported `status_is_terminal($status)`;
  `_is_closed` now delegates to it. `@EXPORT_OK` gains the name.
- **Deviations**: Naming the *specific* phases that block a child needs a per-file terminality
  predicate. The alternatives were to re-declare `Finished|Cancelled|Skipped` inside
  `SubtaskGate` (the duplication the plan explicitly forbade) or to reach into a private sub.
  Promoting `_is_closed` keeps one source of truth and costs one extra hashed file. Terminal
  and complete stay distinct: Cancelled is 0% yet terminal, which is why a percentage
  comparison cannot substitute (TC-4b).

  `expected_files($task_dir, $task_type)` was added in the same file during the review
  response (Step 10), for the same reason: the gate's completeness check and `state_done`'s
  aggregation must agree on which files should exist, and a shared helper enforces that
  where a mirrored comment did not.

### Step 2: `.cwf/scripts/command-helpers/workflow-manager.d/gate` (new, 0500)
- **Planned**: `--task-path`/`--phase`, exit 0/1/2/3, silent when permitted, fail closed on an
  unrecognised phase.
- **Actual**: As planned.
- **Deviations**: Rejected `--task-path` and `--phase` values are **not echoed** back. `control`
  echoes its bad input, but this message is read verbatim by an agent under the SKILL Pre-Step,
  and the value is by definition unvalidated. The error names the expected shape instead.

### Step 3: `.cwf/scripts/command-helpers/workflow-manager` (dispatcher)
- **Planned**: `%commands` gains `gate`; usage string → `{status|control|gate}`.
- **Actual**: Both edits made, exactly as planned.

### Step 4: `.cwf/scripts/command-helpers/cwf-checkpoint-commit` (covers `f`–`i`)
- **Planned**: Import the gate; call it after `resolve`, before `status_set`; exit 3 when blocked.
- **Actual**: As planned. A `die` from the module propagates and aborts the commit — not wrapped
  in `eval`.

### Step 5: `.cwf/scripts/command-helpers/checkpoints-branch-manager` (covers `j`)
- **Planned**: Gate in `create_checkpoints_branch`, after `get_current_branch()`, before
  `git branch`. `parse_branch` returns num first. Two-level `use lib`.
- **Actual**: As planned.
- **Deviations**: None, but one behaviour is worth stating: if the branch name parses as a task
  but that task cannot be resolved, `nonterminal_children` dies and `create` aborts. That is the
  intended fail-closed posture for the operation immediately preceding a destructive squash. A
  branch that names no task at all (`parse_branch` returns `()`) is untouched.

### Step 6: Five SKILL.md Pre-Steps
- **Planned**: One line each in `cwf-implementation-exec`, `cwf-testing-exec`, `cwf-rollout`,
  `cwf-maintenance`, `cwf-retrospective` (phases `f`,`g`,`h`,`i`,`j`). Also "fix the label at
  `cwf-retrospective/SKILL.md:41`: it says Step 6, the doc anchor says Step 7 — align to Step 7."
- **Actual**: Five Pre-Steps added. The label fix went the **other** way.
- **Deviations**: The plan had the direction backwards. `cwf-retrospective/SKILL.md` is internally
  consistent — Step 6 verify-status, Step 7 Execute, Step 8 CHANGELOG — and its Step 8 matches
  `retrospective-extras.md`'s "CHANGELOG.md and BACKLOG.md Update (Step 8)". It is the doc's
  heading, "Verify Task Status (Step 7)", that was off by one. Corrected the doc to
  `(Step 6)`, along with the two prose references to "the Step-7 sweep". The anchor
  `#verify-task-status` that the skill links to is unaffected.

### Step 7: `.cwf/docs/skills/retrospective-extras.md`
- **Planned**: Gate as check 0 of Verify Task Status; gate prepended to the `j` `&&` chain.
- **Actual**: Both, plus a note under §10.1 recording that `checkpoints-branch-manager create`
  re-runs the gate itself and why (it is the last guard before the squash that rewrites the base
  an open subtask was cut from).

### Step 8: Hash refresh (same commit)
- **Planned**: Five hashed paths — two new, three modified.
- **Actual**: **Six** — `CWF::TaskState` joins them, per the Step 1a deviation. New entries for
  `CWF::SubtaskGate` and `workflow-manager.d/gate`; refreshed `sha256` for `CWF::TaskState`,
  `workflow-manager`, `cwf-checkpoint-commit`, `checkpoints-branch-manager`.
- **Verification**: `git log ffb4fd8..HEAD -- <each modified path>` returned no intervening
  commits, so no inherited drift was absorbed. Permissions clamped to recorded ceilings
  (`gate` 0500, `SubtaskGate.pm` 0600; the rest unchanged). `cwf-manage validate` → OK.

### Step 9: `t/subtask-gate.t` (new)
- **Actual**: 20 subtests covering TC-1 … TC-25 (TC-24 and TC-25 added during the review
  response), all passing. `prove -r t/` green: 78 files, 1073 tests.

## Deviations from the Testing Plan

**TC-11's reproducer in `e-testing-plan.md` was wrong, and the test proved it.** The plan
specified a child holding *only* `a-task-plan.md` at `Finished`, asserting `state_done` would
report 100. It reports **0**. Removing `f-implementation-exec.md` flips `_get_all_statuses`'
format detection (`TaskState.pm:304`) to v2.0, whose filenames are entirely different
(`a-plan.md`, `d-implementation.md`, …), so *no* expected file is found and the status list is
empty.

The genuine fail-open needs the v2.1 marker present: a child holding `a-task-plan.md` **and**
`f-implementation-exec.md`, both `Finished`, aggregates to 100% with four files absent. TC-11
now uses that fixture and asserts `state_done($child) == 100` inline — so the regression
property is encoded in the test rather than resting on a manual mutation run. TC-11b covers the
v2.0-misdetection variant, which blocks for a different reason (all four v2.0 files missing).

The correction does not change the fix. Condition 1 (completeness) is what closes the hole in
both variants. It does narrow the *claim*: the hole is not "any partial file set", it is "any
partial file set that retains the format-marker file".

### Step 10: Changeset review response (post-review edits)

The five-reviewer MAP returned three `findings` verdicts. Two were acted on; two were
declined with reasons. All fixes landed before the checkpoint commit, and the suite and
`cwf-manage validate` were re-run after.

**Acted on — a real fail-open, found by the best-practice reviewer.** `$` matches before a
trailing newline, so `/^[a-j]$/` accepts `"f\n"`. `phase_is_gated` is an exact hash lookup,
so it reports `"f\n"` **ungated** — the gate is skipped.

The reviewer's end-to-end claim was that the *CLI* was exploitable. **It was not**, and this
was worth checking rather than accepting: `CWF::Options::parse` anchors its own argument
regex with `^…$` (`Options.pm:62`), so `--phase=f\n` is stripped to `f` before the gate ever
sees it. A probe against a fixture parent with an open child confirmed the CLI blocks
(exit 3) either way.

The reachable path is `cwf-checkpoint-commit`, which reads `$letter` straight from `@ARGV`
with no such stripping. Pre-fix, `cwf-checkpoint-commit 225 $'f\n' …` passed the letter
validation, skipped the gate, and only then failed on the glob — the right exit code for the
wrong reason, with the gate bypassed. Both scripts now anchor with `\A…\z`; the task-path
validators also gain `/a` (a Unicode digit is not a task path) and a non-capturing group.
TC-24 and TC-25 are the regressions; both discriminate against the pre-fix code.

**Acted on — duplication flagged independently by the improvements and misalignment
reviewers.** `SubtaskGate::_expected_files` hand-copied the format-detection block from
`TaskState::_get_all_statuses`, with the "these must not disagree" invariant enforced only
by a comment. Extracted to an exported `CWF::TaskState::expected_files($task_dir, $type)`;
`_get_all_statuses` and the gate now share it, so divergence is impossible by construction.
Both reviewers independently identified the same correct extraction target and both correctly
warned off `TaskPath::detect_format`, whose broader rule would desync the two.

**Declined — `die` vs `Carp::croak`** (best-practice #4). Already a recorded divergence in
`d-implementation-plan.md`: no module under `.cwf/lib/CWF/` uses `Carp`, and the reviewer
concedes plain `die` suits a module's own internal invariant. Consistency wins.

**Declined — the CLI's `eval` maps every exception to exit 2** (robustness, raised as
advisory not a finding). A non-resolution failure would be labelled "task not found". It
still exits non-zero with the real message on stderr, so it fails closed. Not worth a second
exit code.

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] All requirements addressed (bugfix: no b-requirements-plan.md)
- [x] All design guidance in c-design-plan.md followed (D2 as corrected)
- [x] No planned work deferred without user approval
- [x] Follow-up recorded: "Finished does not imply merged" (c-design-plan.md), out of scope

Deferred to `/cwf-testing-exec`: the system-level probe (real throwaway subtask under 225,
confirming `cwf-checkpoint-commit` refuses). `e-testing-plan.md` assigns it to phase `g`.

## Validation Criteria
- [x] `prove -r t/` fully green, bare (78 files, 1073 tests)
- [x] `.cwf/scripts/cwf-manage validate` reports OK
- [x] `workflow-manager gate --task-path=225 --phase=j` exits 0, silent
- [x] `workflow-manager gate --task-path=225 --phase=Z` exits 1
- [ ] Manual subtask probe — deferred to phase `g` per the testing plan
- [x] Exec-phase review columns recorded below

All five reviewers ran in parallel against
`security-review-changeset --wf-step=implementation-exec` (exit 0, 2495 lines, 22 files,
448 production, anchor `ffb4fd8`, includes uncommitted). Verdict tokens below are as
emitted by `security-review-classify`, not by hand. All findings were reviewed **before**
the checkpoint commit; the resulting code changes are recorded in Step 10 above, so the
verbatim text below refers in places to line numbers and code that the fixes have since
changed.

## Security Review

**State**: no findings

I have reviewed the full changeset. The security-relevant code is: the new `CWF::SubtaskGate` module, the `status_is_terminal` addition to `CWF::TaskState`, the new `workflow-manager.d/gate` CLI, and the gate wiring into `cwf-checkpoint-commit` and `checkpoints-branch-manager`. The remainder is task-doc markdown, the hash-manifest refresh, a BACKLOG entry, and `t/subtask-gate.t`.

### Threat-category review

**(a) Bash injection / unsafe command construction.** No new shell-string execution. `checkpoints-branch-manager` invokes `system("git", "branch", $checkpoints_branch)` in list form (existing pattern, unchanged by this diff). The new gate CLI never shells out with its inputs at all — it validates and passes them to Perl functions. Test TC-19 explicitly fires `--task-path='1; rm -rf /'` and asserts exit 1 with the fixture tree intact, confirming the metacharacter payload never reaches a shell. Clean.

**(b) Perl consuming git/user output without `-z` / validation.** The new code introduces no git-porcelain parsing. `nonterminal_children` discovers children via the existing `find_children` (glob + `parse_dirname`), not by newline-splitting git output. The gate CLI validates `--task-path` against `/^\d+(\.\d+)*$/` and `--phase` against `/^[a-j]$/` before use, and on rejection prints a generic error **without echoing the rejected value** (`workflow-manager.d/gate:541`, comment states this is deliberate). Clean.

**(c) Prompt injection via user-supplied strings.** This is the sharpest surface here: `format_blocked` builds a message that the SKILL pre-steps instruct the agent to "report verbatim," so its output flows into model context. I traced every interpolated field:
- `$num` / `$letter` — CLI-validated (numeric / `[a-j]`), or internally derived from `resolve`/`parse_branch`. Constrained.
- `$child->{num}`, `$child->{type}` — from `parse_dirname` (`TaskPath.pm:309`), whose regex constrains num to `\d+(\.\d+)*` and type to `(\w+)` — no whitespace, newlines, or metacharacters can survive. The free-text slug is parsed but **not** printed.
- `$child->{percent}` — integer from `state_done`.
- child status — the one genuinely free-text field (raw text after `**Status**:`, unvalidated per `status_get`). It is explicitly run through `_clamp_status`, which collapses whitespace and truncates to 32 chars, with a code comment naming the verbatim-into-model-context risk. TC-15 verifies a `"A\tB" + 200×"X"` status is stripped and truncated.

The author has already closed this category deliberately and documented why. Clean.

**(d) Unsafe environment-variable handling.** No env vars introduced or consumed by the new code. Clean.

**(e) Pattern-based risks.** The gate is fail-closed throughout, which is the correct posture for a safety gate: unresolvable task dies rather than returning "no children" (TC-14), any non-zero gate result aborts the caller rather than permitting, and an unrecognised phase is exit 1 rather than a silent "ungated" pass (TC-18). One informational pattern observation, not an actionable finding: `format_blocked` clamps the status field but prints `$child->{type}` unclamped — this is **safe here because `parse_dirname` constrains type to `\w+`**; audit any future caller that populates `type` from a looser source (a raw dirname, a git ref, user argument) before feeding it to `format_blocked`, since the no-injection property rests entirely on that regex.

### Conclusion

No actionable security findings. The change is fail-closed, introduces no shell-string or unvalidated-git-output surface, and the one untrusted-text path that reaches model context (child status) is explicitly clamped with rationale. Hash-manifest refresh for the four touched hashed scripts plus the new module is present in the same diff (integrity verification itself is `cwf-manage validate`'s job, out of scope here).

Relevant files:
- `.cwf/lib/CWF/SubtaskGate.pm`
- `.cwf/scripts/command-helpers/workflow-manager.d/gate`
- `.cwf/lib/CWF/TaskState.pm`
- `.cwf/lib/CWF/TaskPath.pm` (`parse_dirname:309`, `find_children:373` — the invariants the safety rests on)

> verdict: `state: no findings` — "Gate code is fail-closed; status text clamped against prompt injection, dir-derived fields constrained by parse_dirname regex, no shell-string or env surface."

## Best-Practice Review

**State**: findings

I have enough to assess. The changeset is Perl-only; the golang and postgres sources listed don't apply. I read the relevant Perl best-practice sources (error-handling, subroutines, regular-expressions) and enumerated the full set. Here is my assessment.

### What I checked

I reviewed the new Perl in this changeset — `CWF::SubtaskGate` (`.cwf/lib/CWF/SubtaskGate.pm`), the `workflow-manager.d/gate` CLI, the `status_is_terminal` promotion in `CWF::TaskState`, and the two caller edits — against the user's curated Perl best-practice docs. The Markdown/doc/SKILL portions of the diff carry no code to assess against these sources.

The code is generally in good shape against the guidelines: explicit `return`s (subroutines #123), `die`-on-failure rather than sentinel returns for the unresolvable-task case (error-handling #171, correct fail-closed), no prototypes (#122), well-formed POD documenting the error contract (#178), `[a-j]` enumerated class where ASCII is intended (regex #157/#167). The findings below are divergences, most minor, one worth surfacing.

### Findings

1. **Input validators anchor with `^…$` instead of `\A…\z`, defeating the design's own fail-closed intent** — `workflow-manager.d/gate` lines 541 and 548:
   ```perl
   unless ($task_path =~ /^\d+(\.\d+)*$/) { ... exit 1 }
   unless ($phase =~ /^[a-j]$/)           { ... exit 1 }
   ```
   Per `regular-expressions.md` #149/#150 (flagged as "a genuine validation-security distinction, not style", with Schwartz's sharpening that `/^\d+$/` accepts `"35\n"` because `$` matches before a trailing newline), these anchors admit a trailing newline. This is not merely theoretical here: `--phase=$'f\n'` passes the `/^[a-j]$/` check, but `phase_is_gated` does an exact hash lookup on `%GATED_PHASES`, so `"f\n"` is not found, and the CLI takes `exit 0 unless phase_is_gated($phase)` → **silent exit 0 / permitted**. That directly contradicts design decision D5 ("An unrecognised phase is an error, never an implicit 'ungated'... a truncated or typo'd argument [must not] disable the gate"). The fix the source prescribes is `\A…\z`. The pre-existing `$letter =~ /^[a-j]$/` in `cwf-checkpoint-commit` shares the shape but is out of this changeset's newly-added lines.

2. **`\d` without `/a` in the task-path validator** — same line 541. `regular-expressions.md` states that since 5.14 `\d` matches Unicode digits by default and that "validation and tokenising almost always want the ASCII sense; the Unicode default is a latent bug." A task-path validator means `[0-9]`; a Unicode digit would pass validation before failing later at `resolve`. Add `/a` (i.e. `/\A\d+(?:\.\d+)*\z/a`).

3. **Unused capture group** — same line 541, `(\.\d+)*` captures but is never read. `regular-expressions.md` #160 ("Capture only when you intend to capture", Perl::Critic `ProhibitUnusedCapture`) calls for `(?:\.\d+)*`.

4. **Library module throws with `die`, not `Carp::croak`** — `SubtaskGate.pm:243`. `error-handling.md` #176 recommends `croak` from library/module code so the error reports the caller's location. This is a deliberate, documented divergence: `d-implementation-plan.md` records "Plain `die`, not `Carp::croak`: no module under `.cwf/lib/CWF/` uses `Carp`, and matching the siblings beats matching the textbook." Advisory only — the source itself notes plain `die` is right "when the error is your module's own internal invariant", and repo-wide consistency is a legitimate reason to hold.

Findings 2–4 are low-severity. Finding 1 is the one I would act on: it is a real fail-open path that contradicts the changeset's own stated D5 posture, on a source the user flags as security-relevant. All are advisory; the user decides.

> verdict: `state: findings` — "gate CLI validators use ^...$ (regex #149/150) enabling a trailing-newline fail-open vs the design's D5 fail-closed intent; plus /a, unused-capture, and die-vs-croak minor divergences"

**Disposition** (see Step 10): Finding 1 fixed, but the reviewer's *CLI* exploit did not
reproduce — `CWF::Options::parse` strips the trailing newline before the gate sees it. The
reachable path was the `cwf-checkpoint-commit` `@ARGV` read the reviewer set aside as
"out of this changeset's newly-added lines", which the gate call it now hosts made live.
Findings 2 and 3 fixed. Finding 4 declined.

## Improvements Review

**State**: findings

I read the full changeset and compared the new `CWF::SubtaskGate` module and its call-sites against the existing helpers in `.cwf/lib/CWF/` and `.cwf/scripts/command-helpers/`. On the whole this changeset reuses existing code well, and it is unusually disciplined about it:

- Child discovery reuses `CWF::TaskPath::find_children` / `resolve`; branch parsing reuses `parse_branch`.
- Progress uses `CWF::TaskState::state_done`; per-file status uses `status_get`.
- The terminal-status predicate is *consolidated*, not duplicated: `status_is_terminal` is added to `TaskState.pm` and the pre-existing private `_is_closed` is refactored to call it, so the three-status literal list (`Finished`/`Cancelled`/`Skipped`) now has a single source that `SubtaskGate` imports. That is the right direction.
- The gate logic lives in one module consumed both as a library (`cwf-checkpoint-commit`, `checkpoints-branch-manager`) and via one thin CLI (`workflow-manager.d/gate`), with `format_blocked` centralising the message — no copy-paste across the three call sites or five SKILL pre-steps. The CLI reuses `CWF::Options::parse`, `check_perl5opt`, and the documented `<name>.d/` subcommand pattern.

### Finding (advisory, low severity)

1. **Duplicated format-detection + expected-file lookup.** `SubtaskGate::_expected_files` hand-copies the exact block already in `CWF::TaskState::_get_all_statuses`: `-f "$dir/f-implementation-exec.md" ? V21::get_workflow_files : V20::get_workflow_files`. The design (D2) is explicit that the two *must not disagree* on the expected set, but it enforces that invariant only by a hand-mirroring comment rather than structurally. The reuse move is to extract that block into one shared helper — e.g. `CWF::TaskState::expected_files($task_dir, $task_type)` — that both `_get_all_statuses` and `SubtaskGate::_expected_files` call, so divergence becomes impossible by construction rather than by convention. This is the DRY-over-duplication case on a safety gate where the design itself rates disagreement as a real risk.

   Note the changeset was *right* not to reuse the already-computed `$child->{format}` field (from `CWF::TaskPath::detect_format`): that helper uses a header-version-first heuristic with an `e-testing-plan.md OR f-implementation-exec.md` fallback, which differs from `_get_all_statuses`'s `f-implementation-exec.md`-only test. Reusing it would introduce exactly the disagreement D2 warns against. So the correct reuse target is the `_get_all_statuses` block, not the `format` field — extract from the former.

This is the only avoidable duplication I found; it is a 2-3 line block and a conscious tradeoff, so it is advisory, not blocking. Everything else ships with no redundant new code.

> verdict: `state: findings` — "Strong reuse overall; one advisory duplication — SubtaskGate::_expected_files hand-copies the format-detection block from TaskState::_get_all_statuses; extract a shared helper."

**Disposition** (see Step 10): fixed. `CWF::TaskState::expected_files` extracted exactly as
prescribed; `_get_all_statuses` and the gate now share it.

## Robustness Review

**State**: no findings

I've reviewed the full changeset and verified the load-bearing interface assumptions against source (`TaskPath::find_children`, `TaskState::_get_all_statuses`, `_is_closed`).

This changeset is itself a robustness fix — a fail-closed subtask gate. I checked whether the new code handles its own errors and edge cases soundly, and whether it introduces any fragile failure paths.

**Fail-closed posture is consistent and deliberate.**
- `CWF::SubtaskGate::nonterminal_children` `die`s on an unresolvable task rather than returning the empty list, so an unresolvable parent halts rather than reading as "no children / permitted". Callers do not swallow this: `cwf-checkpoint-commit` calls it without `eval` so the die propagates and aborts before `status_set`; `checkpoints-branch-manager` likewise aborts before the destructive squash. The CLI wraps it in `eval` but maps any exception to a non-zero exit (2) with the real message printed — still fail-closed.
- The three historically fail-open holes the design identified are all closed and correspond to real defects in the underlying primitive: `_get_all_statuses` skips absent files and drops `Unknown` before aggregating, so `state_done == 100` alone would read partial/corrupt children as terminal. `_blocking_phases` instead walks the *expected* file set explicitly, marking missing files `missing` and non-terminal statuses by value — a strictly more defensive check than the aggregate it replaces. Its v2.1/v2.0 detection mirrors `_get_all_statuses` so the two cannot disagree on the expected set.
- Unknown/garbage phase letters exit 1 rather than silently collapsing into the ungated `a`–`e` path, closing the "typo disables the gate" hole.

**Untrusted input is defended.** `status_get` returns raw unvalidated text, and the refusal message is read verbatim into agent context. `_clamp_status` collapses whitespace and truncates to 32 chars before interpolation, blocking newline/blob injection through a crafted `**Status**:` line. Task-path input is regex-validated and never echoed on rejection; the CLI invokes no shell (list-form `system` only).

**Correctness ordering respected.** The refactor promoting `_is_closed`'s body to an exported `status_is_terminal` is behaviourally identical to the original predicate and marginally more robust (guards `undef` without a warning); `_is_closed` now delegates, so the terminal-status vocabulary lives in exactly one place rather than being re-declared in the gate. This keeps correctness (single source of truth) over the minor duplication the plan first contemplated.

**Minor, non-blocking observation (not a finding).** The CLI's `eval` maps *every* exception to exit 2 ("task not found"), so a hypothetical future internal failure unrelated to resolution would be mislabelled — but it still fails closed (non-zero, real message printed to stderr), so there is no fragile fail-open here. Advisory only.

Edge cases are handled correctly: childless parents return empty (permitted), grandchildren are held back by induction via the child's own gate (TC-8), `format_blocked` is only ever called with a non-empty list, and `parse_branch` returning `()` leaves existing checkpoints behaviour untouched. The test file exercises each fail-open regression with an assertion that pins the underlying `state_done` mis-behaviour inline, so the regression tests cannot silently stop testing the thing they guard.

No mishandled errors, no inverted correctness ordering, and no fragile failure paths introduced. The diff leans anti-fragile: bad input (missing files, corrupt status, unknown phase, unresolvable task) meets a halt, not a break.

> verdict: `state: no findings` — "Fail-closed subtask gate; errors and fail-open edge cases handled soundly, untrusted status text clamped, no fragile paths introduced."

## Misalignment Review

**State**: findings

The changeset adds a subtask gate: a new `CWF::SubtaskGate` module, a `workflow-manager gate` subcommand, three script call-sites, five SKILL.md pre-steps, and doc wiring. I grepped the referenced utilities to confirm they exist with the claimed signatures and to judge whether the diff reuses them or reinvents.

**Strong, verified reuse — well aligned:**
- `CWF::TaskPath::resolve`, `find_children`, `parse_branch` all exist and are used correctly. `parse_branch` genuinely returns `($num, $type, $slug)` num-first (`TaskPath.pm:339`), and the call site `my ($num) = parse_branch($branch)` in `checkpoints-branch-manager` respects that.
- `CWF::TaskState::state_done`/`status_get`/`get_workflow_files` are reused rather than re-implemented.
- The gate CLI mirrors its sibling `control`: `CWF::Options::parse`, `check_perl5opt()` at startup, the `<name>.d/` dispatch pattern (design-alignment.md convention), and exit-code layout (0–2 shared, 3 subcommand-local). The dispatcher edit follows the existing `%commands` shape.
- `CWF::SubtaskGate.pm` matches its `CWF/` siblings on `Exporter`/`@EXPORT_OK`, POD layout, `$VERSION`, `use utf8;`, plain `die` (no `Carp`, consistent with siblings), and no `permissions` key in the hash entry.
- The `status_is_terminal` addition is exemplary alignment: rather than open-coding a second `Finished|Cancelled|Skipped` list inside the gate, it promotes the body of the private `_is_closed` to an exported predicate and has `_is_closed` delegate to it. Single source of truth preserved.

### Finding (advisory, low severity)

1. **Triplicated workflow-format detection heuristic — `SubtaskGate::_expected_files`.** The new `_expected_files` re-derives the v2.0/v2.1 file set by open-coding `-f "$task_dir/f-implementation-exec.md"`. This is a third copy of a format-detection rule the codebase already abstracts:
   - `CWF::TaskPath::detect_format` is the canonical, header-authoritative detector, and `resolve()` already stores its result as the `format` field on every hashref `find_children` returns — so `$child->{format}` is in hand at the call site and goes unused.
   - `CWF::TaskState::_get_all_statuses` open-codes the same `-f f-implementation-exec.md` check.

   The changeset deliberately copies the `_get_all_statuses` variant ("so the two cannot disagree on the expected set") because `detect_format`'s file-based rule is broader (`-f e-testing-plan.md || -f f-implementation-exec.md`) and would desync the gate's completeness check from the `state_done` it cross-references. That reasoning is sound and documented in design D2. But the invariant is now enforced only by a prose comment, not by a shared code path — the exact coupling the repo's single-source-of-truth convention (`docs/conventions/design-alignment.md`) exists to prevent. If `_get_all_statuses`'s detection ever changes, `SubtaskGate` drifts silently. The aligned form would extract the detect-format-plus-expected-set lookup into one helper (in `TaskState` or `WorkflowFiles`) that both `_get_all_statuses` and the gate call.

I weighed this as advisory rather than blocking: `_get_all_statuses` is private and cannot be imported as-is, the new copy is consistent with the pre-existing duplication rather than worsening it, and the decision was consciously recorded. It is a genuine divergence from the reuse/single-source convention, but a bounded and defensible one — the user should decide whether extraction is in scope for a bugfix.

Everything else in the diff reuses the project's abstractions and matches its conventions.

> verdict: `state: findings` — "Well-aligned overall (reuses TaskPath/TaskState/Options, promotes _is_closed to shared status_is_terminal); one advisory: SubtaskGate open-codes a third copy of the v2.1 format-detection heuristic, comment-enforced rather than a shared code path."

**Disposition** (see Step 10): fixed, converging with the improvements reviewer on the same
extraction.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 225
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
