# Resolve tool-check hook paths from git root - Retrospective
**Task**: 224 (bugfix)

## Task Reference
- **Task ID**: internal-224
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/224-resolve-tool-check-hook-paths-from-git-root
- **Template Version**: 2.1
- **Retrospective Date**: 2026-07-10

## Executive Summary
- **Duration**: 1 session, spanning 2026-07-09 to 2026-07-10 (estimated: <1 day — on target)
- **Scope**: **Materially changed at plan time.** The seeded defect no longer existed. The
  task was re-aimed, with user approval, at the two residuals of the same class.
- **Outcome**: Success. The `${CLAUDE_PROJECT_DIR}/`-rooting of CWF hook commands is now an
  invariant enforced by `cwf-manage validate`, not a convention upheld by one generator. The
  doc that still taught the fail-open form is corrected. Both are locked by regression tests
  that were mutation-verified rather than merely observed green.

## Variance Analysis

### Time and Effort
Phase-level day estimates were never made (the plan estimated the whole task at <1 day), so
the honest measure is relative effort, not a fabricated day-count variance:

| Phase | Relative effort | Note |
|---|---|---|
| Planning (a) | **Much higher than expected** | Consumed by verifying that the reported bug still existed. It did not. |
| Design (c) | Higher than expected | The predicate looked trivial and was not. Two false-positive traps. |
| Implementation plan (d) | As expected | |
| Testing plan (e) | As expected | |
| Implementation exec (f) | **Lower than expected** | The module was ~145 lines and worked on the first green run. Front-loading paid. |
| Testing exec (g) | Higher than expected | Mutation verification and the live-tree system test were not free. |

**The variance is the finding.** Effort moved from execution to planning, and the task is
better for it. Had planning trusted the backlog entry, the deliverable would have been a
"fix" for a bug fixed a year earlier, and the two live residuals would have survived.

### Scope Changes
- **Removals**: The originally stated defect — *"tool-check hook fails open from a
  subdirectory; resolve the hook path from the git root, not cwd"* — was descoped because it
  is **already fixed**. Task 204 (`d985db3`, 2026-06-15) landed the `${CLAUDE_PROJECT_DIR}/`
  prefix one day after R7's evidence was recorded (2026-06-14). `find_git_root()` was probed
  directly and was never implicated: it returns the repo root from a nested subdirectory and
  `undef` only outside a repo.
- **Additions** (the replacement scope, user-approved via an explicit rescope question):
  - **D1** — `stop-hooks-framework.md:164` still documented the bare-relative registration.
  - **D2** — no `cwf-manage validate` guard, so a hand-edited `.claude/settings.json`
    silently reverts to a disabled hook with no signal.
- **Also rejected, recorded so it is not re-litigated**: resolving the hook's rule layers from
  `CLAUDE_PROJECT_DIR` rather than the process cwd's git root. That failure mode has not been
  reproduced, and hooks are spawned with cwd set to the project directory.
- **Impact**: net positive. Same task size; the delivered change closes a real gap.

### Success Criteria — actual outcomes
| Criterion | Outcome |
|---|---|
| `validate` fails on an unrooted CWF hook command, passes on the current tree | **Met.** Verified end-to-end on the live tree, not only in fixtures. |
| Surfaces the offending hook, never rewrites it | **Met.** No `--fix`; not wired into `fix-security`. |
| Doc shows only the prefixed form | **Met.** Line 164 only; the prose refs at 115/138 correctly left bare. |
| A regression test asserts the doc example and the generator output agree | **Partially met — see below.** |
| Full suite passes; validate clean; hashes refreshed in the same commit | **Met.** 1054 tests; `253bc7a` carries the hash refresh. |

The fourth criterion is worth stating precisely rather than ticking. TC-8 asserts the doc
registers no bare-relative command; TC-9 asserts the generator still emits the literal. Each
pins its own site. Neither compares the two strings to each other, so a coordinated change to
both would pass. Binding them literally would require a shared constant in a second
hash-tracked file for a three-site literal — below the Rule of Three, and rejected as D5. The
criterion as written ("agree") overstates what was built; what was built is what the design
argued for.

### Quality Metrics
- **Test coverage**: 46 assertions in `t/validate-hooks.t`. Branch coverage of the critical
  path enumerated (predicate: both interesting inputs, all three accepted imprecisions, both
  totality guards; `_read_settings`: all four failure branches; `validate`: absence gate and
  present-but-unusable; `_scan_hooks`: every type-check-before-descent guard). Line-coverage
  percentage deliberately not targeted for an ~80-line module.
- **Defect rate**: zero defects escaped to testing exec. Three plan defects and two
  implementation-plan defects were caught by plan review before any code existed; one
  best-practice divergence was caught by changeset review and fixed.
- **Performance**: not applicable; two small JSON reads per `validate`.

## What Went Well

- **Planning refused to take the backlog entry at face value.** The task began by asking
  whether the reported bug was still real, verified it empirically (a probe of
  `find_git_root()` from three cwds; a grep of every shipped hook registration), and found it
  fixed. The rescope was then put to the user rather than decided unilaterally.
- **Plan review earned its cost, twice over.** It caught a design claim that was simply false
  — that TC-3 bound the generator and validator together (it tests a hardcoded string shape
  and would keep passing if the generator changed). TC-9 exists because of that catch. It also
  caught that the "don't die on a bad settings file" reasoning defended only the JSON decode,
  leaving a present-but-unreadable `settings.local.json` to die on `open` and abort the other
  eight validators — the exact failure the guard existed to prevent.
- **The absence-vs-unreadable trap was designed against, not discovered in production.**
  `_read_settings` returns `$ok = 0` for both. Driving the violation off `$ok` alone would
  emit a spurious violation for every project lacking the gitignored `settings.local.json` —
  the common case — and the validator would have been switched off within a day. The existence
  gate is pinned inside `validate` and TC-7 holds it there.
- **Mutation verification.** TC-8 and TC-9 assert "the source still says X" and would pass
  just as happily against a typo'd pattern matching nothing. Both were verified by mutating
  the real site and observing red. Green tests were not accepted as evidence of green tests.
- **The system test found what fixtures structurally cannot.** Fixtures prove the module;
  they cannot prove the wiring. Mutating one real hook command in `.claude/settings.json`
  produced exactly one violation — confirming D2 (the `permissions.allow` bare pattern on
  line 84 was *not* flagged) end-to-end.
- **Hash discipline held.** Pre-refresh `git log 3da49ca..HEAD -- .cwf/scripts/cwf-manage`
  returned empty, proving the diff being signed was solely this task's. Permissions needed no
  clamping (checked, not assumed).

## What Could Be Improved

- **The doc was the leading indicator and nobody read it.** Task 204 fixed the generator and
  left `stop-hooks-framework.md` teaching the broken form. That doc sat wrong for a year. A
  rename/behaviour-change checklist that includes "grep the docs for the old shape" would have
  caught it at 204, not 224. This is the same class as the existing MEMORY.md rule
  *"rebrands need output-level smoke-test"* — source-level correctness is not doc correctness.
- **The backlog entry aged into a lie.** R7 was recorded 2026-06-14 and fixed 2026-06-15, but
  the entry survived to 2026-07-09 describing a live severe defect. Nothing in the workflow
  re-checks a backlog item's premise before a task is opened against it. Cheap mitigation
  below.
- **A success criterion was written aspirationally.** "A regression test asserts the doc
  example and the generator output agree" describes a stronger property than the design
  concluded was worth building. Criteria written at `a` should be revisited at `c` when the
  design settles what is actually buildable, rather than being quietly satisfied by something
  weaker.
- **I wrote a stray Cyrillic word** ("без") into the `g` results table and caught it only on
  re-read. Minor, but a reminder that generated tables get less scrutiny than prose.

## Key Learnings

### Technical Insights
- **The obvious invariant was the wrong one.** "A hook command must *start with*
  `${CLAUDE_PROJECT_DIR}/`" is the natural rule and it is false: the shipped rules-inject hook
  registers as `cat "${CLAUDE_PROJECT_DIR}/.cwf/rules-inject.txt" 2>/dev/null || true`, with
  the prefix mid-string. The correct invariant is *no bare `.cwf/` reference anywhere in the
  command*, expressed as a fixed-width negative lookbehind.
- **Scope the scan, or the validator gets switched off.** Both settings files carry
  `permissions.allow` entries like `Bash(.cwf/scripts/hooks/…)`. Those are match patterns, not
  exec paths. A whole-document scan would fire on ~6 legitimate entries on day one.
- **A validator composed into a list must never die.** `CWF::Validate::Hooks` degrades every
  bad-file path (absent, unreadable, symlinked, non-regular, malformed) to one `json-parse`
  violation. It deliberately diverges from its `Agents.pm` sibling, which dies on `open`,
  because a die would abort the eight validators composed alongside it.
- **`.claude/settings.json` is a sandbox bind-mount.** `git checkout --` fails on it with
  *Device or resource busy*; `cp` onto it fails with *Read-only file system*. Only the Edit
  tool writes it. Same family as the null-routed dotfiles (character devices) already known.
  Worth remembering before any future task tries to script an edit to it.

### Process Learnings
- **Verify the premise before planning the fix.** The single highest-value act in this task
  was checking whether the bug existed. Cost: one probe script and one grep. Benefit: the
  entire delivered scope.
- **Effort front-loaded into planning came back with interest.** Implementation was one clean
  green run because five reviewer findings had already been applied to the plan.
- **Asserting on source text needs mutation verification.** Any test of the form "the file
  still contains/omits X" is vacuous until you have watched it fail.

### Risk Mitigation Strategies
- **R-A** (a blanket rule fires on users' own hooks) — mitigated exactly as planned: the check
  only looks at commands referencing a `.cwf/` path. A user hook pointing elsewhere is none of
  CWF's business.
- **R-B** (editing a hashed file) — mitigated: disclosed at plan time, per-file `git log`
  pre-refresh check, refresh in the same commit, perms confirmed at the recorded value.
- **R-C** (the fix reads as trivial, tempting a skipped test) — the real risk, and it landed
  the other way: the tests were written, and two of them turned out to be the *only* thing
  standing between a passing suite and a vacuous one.
- **Unexpected**: the plan's risk register never anticipated "the bug does not exist". That is
  the risk that actually materialised.

## Recommendations

### Process Improvements
- Before opening a task against a backlog item older than ~2 weeks, spend one command
  verifying the premise still holds. Record the verification in `a-task-plan.md` §Origin.
- Revisit `a`-phase success criteria at the end of `c`. If the design concludes a criterion is
  not worth building as written, amend the criterion rather than satisfying it loosely.

### Tool and Technique Recommendations
- **Mutation-verify every source-assertion test.** Mutate, observe red, revert, observe green.
  Cheap, and the only thing that distinguishes a real guard from a decorative one.
- **Reach for the live-tree system test when the unit under test is the wiring.** Fixtures
  cannot prove that a validator is actually composed into `cmd_validate`.

### Future Work
Two follow-ups, both recorded in BACKLOG.md:
- **Doc-drift check for behaviour changes** (chore, Medium) — this task's root cause. A
  convention enforced in code but taught wrongly in docs is still broken for anyone reading
  the docs.
- **Make CwF aware that sandbox null-routing pollutes git status** (chore, Medium) — added
  during this task's kickoff (`d10dc9d`), when the null-routed config files were briefly
  misread as stray untracked files.

## Status
**Status**: Finished
**Next Action**: Task complete — suggest merge to main
**Blockers**: None identified
**Completion Date**: 2026-07-10
**Sign-off**: The maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md`, `c-design-plan.md` (D1–D5), `d-implementation-plan.md`, `e-testing-plan.md`
- Execution: `f-implementation-exec.md` (5 reviewers), `g-testing-exec.md` (2 reviewers, mutation + system tests)
- Checkpoint commits: `f8da469` (a), `ea5d06d` (c), `2f56ad5` (d), `55255df` (e), `253bc7a` (f), `e640b8d` (g)
- Also on this branch: `d10dc9d` — the sandbox null-routing BACKLOG entry
- Baseline: `3da49ca`
