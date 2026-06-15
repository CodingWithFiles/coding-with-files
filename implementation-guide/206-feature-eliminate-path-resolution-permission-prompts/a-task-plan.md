# Eliminate path-resolution permission prompts - Plan
**Task**: 206 (feature)

## Task Reference
- **Task ID**: internal-206
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/206-eliminate-path-resolution-permission-prompts
- **Baseline Commit**: 5a955ceeb3e4dbe3e11ffb3e4b401cefe23fc95d
- **Template Version**: 2.1

## Goal
Anchor CWF skills and docs to the project root (and derive the scratch dir) through a single allowlistable mechanism so routine path resolution triggers zero permission prompts.

## Success Criteria
- [ ] Routine project-root anchoring and scratch-dir derivation in skills/docs incur **zero** permission prompts in a default Claude Code session (verified by running a migrated skill end-to-end).
- [ ] A single chosen mechanism replaces every inline command-substitution / `${//}` parameter-expansion anchor block across all affected skills (~20), the `tmp-paths` convention, and the `cwf-new-task`/`cwf-new-subtask` scratch snippets.
- [ ] Migrated snippets remain worktree-safe (main repo root via `--git-common-dir`) and produce paths **byte-identical** to the current snippets (golden comparison).
- [ ] No new non-core dependencies; mechanism runs on macOS system Perl / POSIX sh.
- [ ] Script hashes and any security records updated in the same commit as the file edits; helper covered by tests.

## Original Estimate
**Effort**: 1-2 days
**Complexity**: Medium
**Dependencies**: Builds on Task 204 (resolve `.cwf` paths from project root) and the `tmp-paths` convention (Tasks 199/203).

## Major Milestones
1. **Mechanism selected**: Empirically determine what actually triggers the prompt, then choose among the backlog's candidate approaches (a–d) the one needing the fewest allowlist entries and no inline `${//}` expansions.
2. **Mechanism implemented & tested**: Helper/script in place with golden-path and worktree-safety coverage.
3. **Migration complete**: All skill "anchor the shell" blocks + `tmp-paths` derivation snippet migrated to the chosen mechanism.
4. **Zero-prompt confirmed**: Allowlist entries documented; a migrated skill run end-to-end shows no routine path-resolution prompts.

## Risk Assessment
### High Priority Risks
- **Risk 1**: The prompt may be triggered by *command substitution itself* (`$(...)`), so wrapping the same logic in a helper still invoked via `$(...)` would not eliminate it. Impact: chosen mechanism fails its sole purpose.
  - **Mitigation**: In design, empirically confirm the exact trigger before committing to a mechanism; prefer a form the harness can allowlist as an exact/prefix command with no nested substitution or `${//}` expansion (e.g. helper prints/creates the path and the skill consumes its output without a `cd "$(...)"`).
- **Risk 2**: Path drift or lost worktree-safety while migrating ~25 files. Impact: scratch collisions or wrong-root anchoring.
  - **Mitigation**: Golden test comparing old-snippet output vs new mechanism across plain-repo and worktree cases; output-level smoke test (per retrospective rule) before sign-off.

### Medium Priority Risks
- **Risk 3**: Allowlist patterns are harness/user-config specific; we cannot guarantee zero prompts across every possible config. Impact: residual prompts for some users.
  - **Mitigation**: Choose the mechanism needing the fewest, most-stable allowlist entries; document the required entries explicitly in the convention.

## Dependencies
- Task 204 (project-root path resolution) — the snippets this task migrates were introduced there.
- `tmp-paths` convention (`.cwf/docs/conventions/tmp-paths.md`) — canonical scratch derivation must move in lockstep.

## Constraints
- macOS system Perl / POSIX sh; core modules only (no new deps).
- Cannot modify the harness permission engine — must work within what it allowlists.
- Hash-update convention: hashed-file edits refreshed in the same task/commit.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — 1-2 days.
- [ ] **People**: Does this need >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — one mechanism, then a mechanical migration.
- [ ] **Risk**: High-risk components needing isolation? No — risk is concentrated in the mechanism choice, resolved in design.
- [ ] **Independence**: Can parts be worked on separately? No — migration is strictly downstream of the mechanism choice (sequential, not independent).

**Verdict**: 0 signals triggered — single task, no subtasks.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All four success criteria met. Zero-prompt anchoring confirmed **live** (the injected
`CWF PATHS` block appears each turn). One mechanism — a UserPromptSubmit hook plus
`scratch_parent`/`scratch_dir` — replaced the ~20 anchor blocks and the `tmp-paths`/
task-creation snippets. Byte-identity held (golden TC-1); no new deps; hashes refreshed
in-commit; full suite 874 green, `cwf-manage validate` OK.

## Lessons Learned
Risk 1 (the prompt is triggered by `$(...)` itself) was the crux: it forced the pivot from
a *called* helper to *injection*. Naming the highest-uncertainty risk in planning is what
made the design correct. See `j-retrospective.md` for the full write-up.
