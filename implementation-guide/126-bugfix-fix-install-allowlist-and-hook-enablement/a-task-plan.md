# fix install allowlist and hook enablement - Plan
**Task**: 126 (bugfix)

## Task Reference
- **Task ID**: internal-126
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/126-fix-install-allowlist-and-hook-enablement
- **Template Version**: 2.1

## Goal
Make `/cwf-init` produce a `.claude/settings.json` that lets a fresh install run the CWF workflow end-to-end without per-invocation permission prompts and with the CWF Stop hooks active.

## Bug Description
A fresh install in a downstream project surfaced two gaps in `/cwf-init`:

1. **Allowlist gap.** Step 6 of `cwf-init/SKILL.md` only registers `Skill(cwf-<name>)` entries in `.claude/settings.json`. It does not register `Bash(.cwf/scripts/...)` entries for the helper scripts and hooks that every workflow phase shells out to (`context-manager`, `task-context-inference`, `task-workflow`, `workflow-manager`, `cwf-manage`, `cwf-checkpoint-commit`, `cwf-set-status`, `checkpoints-branch-manager`, `cwf-version-bump`, `cwf-version-tag`, the two hooks, etc.). On a fresh install every helper invocation triggers a permission prompt; this repo's working `.claude/settings.local.json` accreted those entries one at a time over months of use, which masked the absence of the install-time allowlist.

2. **Hook enablement gap.** Step 6c only registers the rule re-injection `PreToolUse` hook. It does not add `Stop` hook entries for `.cwf/scripts/hooks/stop-stale-status-detector` and `.cwf/scripts/hooks/stop-uncommitted-changes-warning`, so a fresh install ships without the two CWF safety nets the workflow assumes are active. The hook scripts are integrity-tracked (Task 125) and present on disk, but `.claude/settings.json` never references them.

Both gaps are install-time configuration omissions, not script bugs. The fix lives in `/cwf-init` (the canonical configuration entry point).

## Success Criteria
- [ ] After running `/cwf-init` in a fresh repo, `.claude/settings.json` `permissions.allow` contains a `Bash(.cwf/scripts/...:*)` entry for every executable file under `.cwf/scripts/command-helpers/**` (top-level + `<name>.d/`) and `.cwf/scripts/cwf-manage`, plus exact-match entries for the two `.cwf/scripts/hooks/` files.
- [ ] After running `/cwf-init`, `.claude/settings.json` `hooks.Stop[]` registers both `.cwf/scripts/hooks/stop-stale-status-detector` and `.cwf/scripts/hooks/stop-uncommitted-changes-warning` with the same shape used in this repo's `.claude/settings.local.json` (`type: command`, `timeout: 5`).
- [ ] Re-running `/cwf-init` is idempotent: it does not duplicate allowlist entries or hook registrations, and it does not clobber unrelated user-added entries.
- [ ] The integrity manifest is the source of truth for which scripts to register: the allowlist is derived by walking `.cwf/security/script-hashes.json`, not by hard-coding a list in the skill — so future helpers (added per Task 125's coverage guard) flow through automatically.
- [ ] A regression test under `t/` asserts both gaps are closed against a synthetic `.claude/settings.json` fixture, so this can't drift again.

## Original Estimate
**Effort**: 1 session
**Complexity**: Low
**Dependencies**: Task 125 (integrity manifest now covers every helper + both hooks — this task uses that as the source of truth).

## Major Milestones
1. **Design**: Decide whether the allowlist is generated (preferred — manifest-driven) or maintained as a static list in the skill, and where in `/cwf-init` the additions live (Step 6 extension vs new step). Decide on entry shape (`Bash(.cwf/scripts/.../<name>:*)` vs `Bash(./.cwf/scripts/.../<name> *)`).
2. **Implementation**: Update `cwf-init/SKILL.md` Steps 6 and 6c with the new logic; add a small helper if the manifest walk is non-trivial; ensure the writes to `.claude/settings.json` remain idempotent JSON merges.
3. **Test**: Add a coverage-style test under `t/` that takes a synthetic `.claude/settings.json` (empty, partially populated, fully populated) and asserts the post-init state matches expectations. Smoke-test the skill in a tempdir.
4. **Retrospective**: Confirm fresh-install behaviour by reading the skill's writes against a synthetic fixture; document min-prompt baseline.

## Risk Assessment
### High Priority Risks
- **Breaking existing `.claude/settings.json` files.** Downstream projects may have hand-edited entries. Merge logic must be additive only (no removals, no rewrites of unrelated entries).
  - **Mitigation**: Read existing JSON, merge new entries into `permissions.allow` (de-duplicated) and `hooks.Stop[]` (de-duplicated by command path), write back. Test against a fixture that has unrelated user entries.

### Medium Priority Risks
- **Allowlist entry shape drift.** Claude Code matches `Bash(...)` allowlist entries by glob; the wrong shape (`:*` vs ` *` vs bare path) silently fails to match and re-prompts. The `.claude/settings.local.json` in this repo has both `<path>:*` and `<path> *` shapes for the same script — evidence the right shape is non-obvious.
  - **Mitigation**: Pick the shape that matches the canonical invocation (`<path> [args]` → `Bash(<path>:*)` per Claude Code's matcher; verify against this repo's known-working entries before settling).
- **Manifest drift between install time and run time.** If `.cwf/security/script-hashes.json` is the source of truth, but `/cwf-init` runs before any task adds new helpers, the allowlist will be correct at init time but go stale as new helpers are added.
  - **Mitigation**: Document that re-running `/cwf-init` (idempotent) refreshes the allowlist. Out of scope: an automatic refresh on `cwf-manage update`. Worth a BACKLOG item.
- **Hook registration conflicts with existing `Stop` hooks.** A downstream project may already have its own Stop hooks (linters, formatters, custom safety nets).
  - **Mitigation**: Append to the `Stop[]` array's `hooks` list rather than replacing it; de-duplicate by exact `command` string match.

## Dependencies
- Task 125 (closed): integrity manifest is the canonical inventory of scripts to register.
- `.claude/settings.json` JSON merge must preserve existing structure — Perl `JSON::PP` round-trip already used by `cwf-init` Step 1a is a reasonable model.

## Constraints
- No new runtime dependencies. Stay within Perl 5.10+ core modules.
- Idempotent — `/cwf-init` is documented as safe to re-run.
- No PII or path leaks: paths written to `.claude/settings.json` should be repo-relative (`.cwf/scripts/...`), matching the pattern already in this repo's settings.
- Must not require Claude Code restart to take effect any more than the existing `/cwf-init` does.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? — No, single session.
- [ ] **People**: Does this need >2 people working on different parts? — No, single contributor.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? — No, two related concerns (allowlist + hooks) on the same `.claude/settings.json` file via the same skill.
- [ ] **Risk**: Are there high-risk components that need isolation? — No, additive JSON merges with idempotent semantics.
- [ ] **Independence**: Can parts be worked on separately? — Yes in principle, but they share the same edit point and the same test fixture, so bundling reduces churn.

**Decision**: No decomposition. Proceed as a single bugfix.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
