# cwf-init dead UserPromptSubmit hook matcher - Plan
**Task**: 195 (bugfix)

## Task Reference
- **Task ID**: internal-195
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/195-cwf-init-dead-userpromptsubmit-hook-matcher
- **Baseline Commit**: 057f995afc9504260e2653aeb1c624b03e997af1
- **Template Version**: 2.1

## Goal
Make `/cwf-init` register the rules-inject re-injection hook as a working top-level
`UserPromptSubmit` event (not a dead `PreToolUse` matcher), and clean up the dead
entry that existing installs already carry.

## Success Criteria
- [ ] `/cwf-init` step 6c emits the hook under a top-level `"UserPromptSubmit"` key as a
      flat hook-object array — no `matcher`, no nested `hooks` wrapper.
- [ ] The step is idempotent: re-running `/cwf-init` neither duplicates the
      `UserPromptSubmit` hook nor leaves the dead `PreToolUse`/`UserPromptSubmit` entry.
- [ ] Existing installs are migrated: any pre-existing dead
      `PreToolUse` group whose `matcher == "UserPromptSubmit"` is removed, and unrelated
      `PreToolUse` matchers are left untouched.
- [ ] Step 6d (`cwf-claude-settings-merge`) is confirmed not to re-introduce the wrong
      shape (its event-validation regex currently excludes `UserPromptSubmit`).
- [ ] Output-level smoke test: running `/cwf-init` against a scratch repo yields a
      `.claude/settings.json` with a working top-level `UserPromptSubmit` hook and no
      dead `PreToolUse` matcher.

## Original Estimate
**Effort**: <1 day
**Complexity**: Low
**Dependencies**: None (self-contained SKILL.md / helper change)

## Major Milestones
1. **Design**: Decide where the forward fix + migration live — SKILL.md step 6c prose
   only, or moved into a deterministic helper (`cwf-claude-settings-merge`). Settle the
   migration/cleanup contract (which entries to strip, what to preserve).
2. **Implement**: Apply the forward fix (correct hook shape) and the migration/cleanup
   path; update step 6c prose and JSON block; refresh hashes if a helper changes.
3. **Verify**: Output-level smoke test against a scratch repo + idempotency re-run.

## Risk Assessment
### High Priority Risks
- **Over-broad migration clobbers user hooks**: A cleanup that strips the dead entry
  could also remove legitimate, unrelated `PreToolUse` matchers a user has added.
  - **Mitigation**: Scope removal to exactly the group where `matcher == "UserPromptSubmit"`
    under `PreToolUse`; leave all other groups intact. Cover with a regression test.

### Medium Priority Risks
- **Non-idempotent migration**: Forward-fix + cleanup run together could duplicate the
  new `UserPromptSubmit` hook on re-run.
  - **Mitigation**: Presence-check the top-level `UserPromptSubmit` command before
    appending; smoke-test a double `/cwf-init` run.
- **LLM-driven prose drift**: Step 6c is executed by the model from prose, so an
  imprecise instruction can regress the shape again (this bug's root cause).
  - **Mitigation**: Prefer/raise in design whether registration should move into the
    deterministic helper rather than remain prose-driven.

## Dependencies
- None — self-contained change to `.claude/skills/cwf-init/SKILL.md` and optionally
  `.cwf/scripts/command-helpers/cwf-claude-settings-merge`.

## Constraints
- Must follow [[hash-updates]]: if `cwf-claude-settings-merge` (a hashed script) is
  edited, refresh `.cwf/security/script-hashes.json` in the same commit.
- Migration must not touch unrelated user-authored hook config.
- This repo's own `settings.json` has empty `hooks: {}` — no self-migration here; the
  migration matters for downstream installs.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — <1 day.
- [ ] **People**: Does this need >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — one concern (hook shape + its migration).
- [ ] **Risk**: High-risk components needing isolation? No — single migration risk, mitigated in-task.
- [ ] **Independence**: Can parts be worked separately? No — forward fix and migration are coupled.

**Verdict**: 0 signals triggered — no decomposition. Proceed as a single bugfix.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Plan held: <1 day, Low complexity, 0 decomposition signals — all confirmed. The one
correction: **SC1's "flat hook-object array — no nested `hooks` wrapper" was wrong**.
Design established that Claude Code's `UserPromptSubmit` event uses the same three-level
group-wrapper as every other event (it ignores `matcher` but still nests under `hooks`);
the implementation followed the corrected shape. SC2–SC5 (idempotency, matcher-scoped
migration, helper does not re-introduce the wrong shape, output-level smoke test) all met.

## Lessons Learned
The BACKLOG-prescribed flat shape was a wrong hypothesis carried into SC1; a flat-array
"fix" would itself have been malformed. Verify externally-proposed shapes against the
actual tool contract before adopting them as success criteria — and amend the SC in place
when design overturns it (this SC was contradicted downstream rather than corrected here).
