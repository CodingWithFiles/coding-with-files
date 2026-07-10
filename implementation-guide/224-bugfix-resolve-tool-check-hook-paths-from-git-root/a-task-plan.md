# Resolve tool-check hook paths from git root - Plan
**Task**: 224 (bugfix)

## Task Reference
- **Task ID**: internal-224
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/224-resolve-tool-check-hook-paths-from-git-root
- **Baseline Commit**: 3da49ca10049ccb45d2db6e34043b2cb0d3726ac
- **Template Version**: 2.1

## Goal
Make the `${CLAUDE_PROJECT_DIR}/`-prefixed hook-command form an *enforced invariant*
rather than a convention upheld by a single generator, and remove the shipped
documentation that still teaches the bare-relative form.

## Origin and Scope Correction

Seeded as R7 of the Task 219 cross-project friction group: *"tool-check hook fails open
from a subdirectory — resolve the hook path from the git root, not cwd"* (source P3,
`[S, severe]`, verified 2026-06-14).

**The defect as originally stated is already fixed.** Verified during this plan:

- Task 204 (`d985db3`, 2026-06-15 — one day after P3 was recorded) changed
  `cwf-claude-settings-merge` to emit `"${CLAUDE_PROJECT_DIR}/$path"` for every hook
  `command`, and added a prune pass that re-links pre-existing bare-relative CWF hook
  commands on regen instead of duplicating them.
- All six hook registrations in `.claude/settings.json` carry the prefix.
- `find_git_root()` was never implicated: probed directly, it returns the repo root from
  a nested subdirectory (git walks up) and `undef` only outside a repo. The hook's rule-layer
  lookup is therefore correct from any cwd inside the tree.

Two residuals of the same class survive, and they are this task's scope:

- **D1 — stale doc teaches the broken pattern.** `.cwf/docs/workflow/stop-hooks-framework.md:164`
  documents the registration shape with a bare relative command
  (`".cwf/scripts/hooks/subagentstop-security-verdict-guard"`). Task 204 did not touch this
  file. An operator hand-registering a hook from this example reproduces the original
  fail-open.
- **D2 — no guard.** The prefix is enforced only inside the generator and its unit tests.
  `cwf-manage validate` does not check it. A hand-edited `.claude/settings.json` silently
  reverts to a disabled hook with no signal — the same "guard is off, no signal" property
  that made P3 severe.

Out of scope (considered, rejected): resolving the hook's rule layers from
`CLAUDE_PROJECT_DIR` instead of the process cwd's git root. This would close the case where
cwd sits in a nested or different repository, but that failure mode has not been reproduced
and hooks are spawned with cwd set to the project directory. Recorded here so the decision
is not silently re-litigated.

## Success Criteria
- [ ] `cwf-manage validate` fails when any CWF hook `command` in `.claude/settings.json`
      is not `${CLAUDE_PROJECT_DIR}/`-prefixed, and passes on the current tree
- [ ] The check surfaces the offending hook path and event — it does not offer to rewrite
      the file (surface, never smooth)
- [ ] `.cwf/docs/workflow/stop-hooks-framework.md` shows only the prefixed form
- [ ] A regression test asserts the doc example and the generator output agree
- [ ] Full `t/` suite passes; `cwf-manage validate` clean; hashes refreshed in the same commit

## Original Estimate
**Effort**: <1 day
**Complexity**: Low
**Dependencies**: None. Task 204 (prefix form) and Task 220 (tool-check seed) are landed.

## Major Milestones
1. **Validate check**: hook-command prefix invariant enforced by `cwf-manage validate`
2. **Doc correction**: the one stale registration example brought in line
3. **Regression coverage**: test locking both, so the doc cannot drift from the generator

## Risk Assessment
### High Priority Risks
- **R-A: A new validate check fires on legitimate non-CWF hooks.** Users register their own
  hooks in `.claude/settings.json`; a blanket "every command must be prefixed" rule would
  fail their tree on upgrade.
  - **Mitigation**: scope the check to commands that reference a `.cwf/` path — CWF's own
    hooks. A user hook pointing anywhere else is none of CWF's business.

### Medium Priority Risks
- **R-B: Editing a hashed file.** `cwf-claude-settings-merge` and any touched `.cwf/` script
  are hash-tracked.
  - **Mitigation**: per `hash-updates.md`, disclose the hashed-file edit at plan time (done:
    this section), refresh `.cwf/security/script-hashes.json` in the same commit, and verify
    per-file with `git log` before refreshing. Restore working perms to the *recorded* value.
- **R-C: The fix is documentation-shaped and reads as trivial**, tempting a skipped test.
  - **Mitigation**: the regression test is a success criterion, not an optional extra. The
    whole point of the task is that an unenforced convention drifted.

## Dependencies
- External requirements and prerequisites: none
- Team dependencies and coordination needs: none

## Constraints
- Perl core modules only; `use utf8;`; `PERL5OPT=-CDSLA` (see `docs/conventions/perl.md`)
- The validate check must **surface**, never auto-repair — no tooling that silences the
  signal (see `.cwf/docs/conventions/hash-updates.md`)
- Fail-open posture of the hook itself is deliberate and unchanged by this task

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — under a day
- [ ] **People**: Does this need >2 people working on different parts? No
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — one invariant, two sites
- [ ] **Risk**: Are there high-risk components that need isolation? No
- [ ] **Independence**: Can parts be worked on separately? Doc and check are coupled by the
      regression test; separating them would lose the point

**Result**: 0 of 5 signals triggered. No decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five success criteria met, with one qualification. Criterion 4 ("a regression test asserts
the doc example and the generator output agree") was satisfied by TC-8 and TC-9 pinning each
site independently, not by binding the two literals together — the design (D5) rejected a
shared constant in a second hash-tracked file as below the Rule of Three. The criterion as
written overstates what was built. `cwf-manage validate` now fails on an unrooted CWF hook
command (verified end-to-end on the live tree) and passes on the current tree; the check
surfaces and never rewrites; the doc shows only the prefixed form; 1054 tests pass; hashes were
refreshed in commit `253bc7a`.

## Lessons Learned
The risk register anticipated a validator that false-positives on user hooks (R-A), a hashed-file
edit (R-B), and a skipped test (R-C). All three were mitigated as planned. The risk that
actually materialised was absent from the register entirely: **the reported bug did not exist.**
Task 204 fixed it one day after the evidence was recorded, and the backlog entry aged into a
description of a live severe defect that had already been closed. One probe of `find_git_root()`
and one grep of the shipped hook registrations cost almost nothing and redirected the entire
task. Verify the premise before planning the fix.
