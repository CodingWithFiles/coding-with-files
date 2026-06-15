# Resolve .cwf paths from project root, not cwd - Retrospective
**Task**: 204 (bugfix)

## Task Reference
- **Task ID**: internal-204
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/204-resolve-cwf-paths-from-project-root-not-cwd
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-15

## Executive Summary
- **Duration**: ~2 days (estimated: 1–2 days; on-estimate despite a mid-task scope addition).
- **Scope**: Planned fix for cwd-relative `.cwf/...` resolution across skills + scripts;
  grew by one surface (hook registration) discovered live and folded in.
- **Outcome**: Success. All four success criteria met; 860 tests pass, `cwf-manage
  validate` green, two exec-phase security reviews returned no findings.

## Variance Analysis
### Time and Effort
- **Estimated**: 1–2 days total (bugfix path: a, c, d, e, f, g, j).
- **Actual**: ~2 days. Planning/design/impl-plan/test-plan were light; the bulk of
  effort was the broad mechanical edit (20 skills) plus the folded-in surface-3 fix
  and its tests.
- **Variance**: ~0% against the upper bound. The scope addition was absorbed without
  schedule slip because the spike (see below) *narrowed* the skill-side work at the
  same time it surfaced the hook-side work.

### Scope Changes
- **Additions**:
  - **Surface 3 — hook registration** (`cwf-claude-settings-merge`): a live
    `PreToolUse:Bash hook error … not found` was observed mid-task; the operator
    chose to fold the fix into Task 204. Hook `command` strings now carry the literal
    `${CLAUDE_PROJECT_DIR}/` prefix, with a gate-state-independent anchored prune that
    re-links stale relative entries. c/d/e were amended and re-reviewed (round 2).
- **Removals / narrowing**:
  - The Phase-0 spike **disproved assumption A1** (that Read/Edit tool paths resolve
    against the project root). They resolve against the **shell** cwd — so the single
    cwd anchor already fixes relative doc-reads too, removing the need for any
    separate Read/Edit-path treatment.
  - `CLAUDE_PROJECT_DIR` was **not** adopted as a general resolution mechanism (it is
    hooks-only); it is used *only* on surface 3, where it is guaranteed.
- **Impact**: Net surface count held at the originally-scoped breadth; the addition
  and the narrowing roughly cancelled on effort.

### Quality Metrics
- **Test Coverage**: Critical paths at 100% per the e-plan targets (anchor:
  at-root/subdir/worktree/outside; hooks: prefix/prune/fail-open-closed). No
  line-coverage target — change is shell-idiom-in-markdown + a generator edit.
- **Defect Rate**: Zero post-implementation defects. One in-flight slip (invalid
  status `Implemented` in f) was caught by the workflow-status validator and
  corrected before the testing-exec sign-off.
- **Security**: Two changeset reviews (implementation-exec, testing-exec) — no
  findings. FR4(e) constant-command invariant confirmed: the prefix is emitted as a
  compile-time literal, never `$ENV{...}` at generate-time.

## What Went Well
- **The repo's own canonical pattern carried the fix**: `find_git_root()` (Task 173,
  worktree-safe via `--git-common-dir`) gave a proven anchoring mechanism; the skill
  anchor idiom mirrors it exactly, so worktree-safety was inherited, not re-invented.
- **Spike-first paid off**: running Phase-0 probes before the mechanical edit
  corrected A1 and prevented an entire unnecessary work-stream (Read/Edit path
  rewriting).
- **Drift guard built in**: `t/skill-anchor-drift.t` asserts byte-identical anchor
  form *and* coverage (anchor present before first action), so a future skill that
  omits or mutates the anchor fails CI rather than silently breaking off-root.
- **Hash discipline held**: the one hashed file changed (`cwf-claude-settings-merge`)
  had its sha256 refreshed in the same commit; a pre-existing perm drift on an
  unrelated script was clamped on sight rather than deferred.

## What Could Be Improved
- **Assumption A1 should have been a spike item from the design phase, not a
  discovery during it** — it materially shaped scope. A short "what does each path
  surface resolve against?" probe belongs in design for any cwd/root task.
- **The surface-3 bug pre-existed and was only caught by a live hook error**, not by
  the original survey. The survey counted bare `.cwf/...` in SKILL.md but did not
  audit generated `.claude/settings.json`. Path-resolution audits should include
  *generated* artefacts, not just source.
- **Plan-reviewer false positive**: three reviewers claimed
  `update-cwf-skill-docs.sh` did not exist; it does (`git ls-files` confirmed). The
  finding was correctly rejected, but it cost a verification cycle.

## Key Learnings
### Technical Insights
- **Path surfaces resolve differently**: Bash invocations and Read/Edit tool paths
  both resolve against the **shell** cwd (so one persistent `cd` fixes both); hook
  commands resolve in a harness-provided environment where only
  `${CLAUDE_PROJECT_DIR}` is guaranteed. One bug class, two distinct fixes.
- **cwd persistence is load-bearing**: because cwd persists across Bash tool calls
  within a skill invocation (env vars do not), a single anchor block at the top of a
  skill suffices for every later relative call — no per-call re-anchoring.
- **The permission allowlist keys on relative command strings**, so hook `command`
  strings could be prefixed while the allowlist entries stayed relative — the fix did
  not disturb permission matching.

### Process Learnings
- **Fold-in over fork**: absorbing the surface-3 fix into the live task (with c/d/e
  re-review) kept one coherent changeset and one security-review boundary, rather
  than splitting a tightly-related fix across two tasks.
- **Output-level verification matters**: per the standing "rebrands need
  output-level smoke-test" memory, the generator was dry-run + real-run checked, not
  just source-grepped — that is how the prefix/prune/no-duplicate behaviour was
  confirmed end-to-end.

### Risk Mitigation Strategies
- The High-Priority risk (broad mechanical change, missed sites) was mitigated as
  planned by a single canonical form + an automated coverage test — the missed-site
  failure mode is now machine-checked, not eyeballed.

## Recommendations
### Process Improvements
- For any cwd/root-resolution task, add a design-phase spike line: "enumerate every
  path surface (Bash, tool-path, hook, generated config) and what each resolves
  against" — so A1-class assumptions surface before planning, not during exec.
- Extend path-resolution surveys to cover **generated** files (`.claude/settings.json`),
  not only checked-in source.

### Tool and Technique Recommendations
- The byte-identical-form + coverage drift test (`t/skill-anchor-drift.t`) is a
  reusable pattern for any "same idiom replicated across N files" change; reach for it
  whenever a snippet must stay uniform across many skills/templates.

### Future Work
- None required for this task. If CWF ever supports being vendored as a git
  submodule, the anchor's plain `dirname` would need the `--show-toplevel` submodule
  fallback that `find_git_root()` has — out of scope today (submodule use
  unsupported), noted for that future.

## Status
**Status**: Finished
**Next Action**: Task complete — suggest merge to main (human decision)
**Blockers**: None identified
**Completion Date**: 2026-06-15
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning + design: `a-task-plan.md`, `c-design-plan.md`, `d-implementation-plan.md`,
  `e-testing-plan.md` (this task directory).
- Execution: `f-implementation-exec.md`, `g-testing-exec.md`.
- Tests: `t/skill-root-anchor.t`, `t/skill-anchor-drift.t`,
  `t/cwf-claude-settings-merge.t` (extended TC-13–17).
- Security reviews: scratch dir `security-review-output-{implementation,testing}-exec.out`.
- Commits: branch `bugfix/204-resolve-cwf-paths-from-project-root-not-cwd`
  (`8895d3e` c, `d8820d2` d, `ee8a1d2` e, `bd847ac` f, `d97fa2c` g, `1eac335` sweep).
