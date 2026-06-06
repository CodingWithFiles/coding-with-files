# Harden security-review-changeset agent contract - Retrospective
**Task**: 182 (feature)

## Task Reference
- **Task ID**: internal-182
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/182-harden-security-review-changeset-agent-contract
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-06

## Executive Summary
- **Duration**: ~1 day (estimate: ~1 day; on estimate). Single session, ten phases a–j.
- **Scope**: Delivered the five requested changes (flag rename, default cap, self-managed output file, stdout confirmation, stricter agent-invocation docs). Scope grew during planning from "edit the script" to a **four-site contract migration** plus a test-suite migration — a consequence of the change, not a creep.
- **Outcome**: Success. All five success criteria (SC1–SC5) met; 35-subtest suite green; both exec security reviews `no findings`; `cwf-manage validate: OK`. Merge to main is the only remaining (human-only) step.

## Variance Analysis
### Time and Effort
- **Estimated**: ~1 day total (a-task-plan), Medium complexity.
- **Actual**: ~1 day, single session. No phase dominated; the implementation (f) and test migration (g) carried most of the work.
- **Variance**: On estimate. The decomposition check (0 signals) held — no subtasks needed.

### Scope Changes
- **Additions** (surfaced in planning/exec, all in-scope consequences):
  - Four-site consumer migration (both exec SKILLs, the agent, `security-review.md`) — the file-output model removed the skills' stdout-content branching, forcing their rewrite.
  - Agent-file hash refresh — the agent is hash-tracked; editing it required a same-commit SHA refresh the d-plan's file list under-specified. `cwf-manage validate` caught the omission.
- **Removals**: none. Two *planned* new test cases (TC-EMPTY, TC-CAP-WRITES-FILE) were consolidated into migrated equivalents (TC-EMPTY1, TC-CAP1) rather than duplicated — no coverage lost.
- **Impact**: scope grew but stayed single-commit-atomic; no timeline impact.

### Quality Metrics
- **Test Coverage**: every AC (AC1–AC8, incl. AC4.1/4.2/4.3, AC6.1/6.2, AC7) has ≥1 dedicated case; all pre-existing subtests migrated and green. TC-SYMLINK and TC-WORKTREE ran (not skipped) on Linux.
- **Defect Rate**: one self-inflicted defect during g (a missed stdout→file assertion migration in TC-WIDEN1), caught by running the suite; zero defects from the security reviews.
- **Performance**: NFR1 neutral — one extra `mkdir` + one file write replace the prior stdout emit; TC-NF5 confirms O(diff) not O(repo).

## What Went Well
- **`cwf-manage validate` did its job twice**: caught the un-refreshed agent hash, and the working-tree perm drift the maintainer told me to fix. The integrity gate, not vigilance, is what kept the commit consistent.
- **Reuse over hand-rolling** (D1): `find_git_root` (worktree-safe) and `atomic_write_text` (`rename`-replace = truncate + symlink no-write-through) gave the security properties for free; no new non-core modules.
- **Parsing the confirmation line in tests** instead of re-deriving the `.out` path sidestepped the macOS `/private/tmp` symlink-resolution divergence — the test consumes the contract exactly as the agent does.
- **The 4-reviewer plan pass earned its keep**: it caught the requirements/design symlink-semantics divergence (O_NOFOLLOW "refuse" vs `rename` "replace") and forced a requirement correction rather than a wrong implementation.

## What Could Be Improved
- **The d-plan's hashed-file list was incomplete** — it enumerated only the script under `script-hashes.json`, missing the hash-tracked agent file it also edited. Plan-time, cross-check every file touched against `script-hashes.json`, not just the "primary" artefact.
- **A migration site was missed by reasoning** (TC-WIDEN1): proof again that source-level grep/reasoning is insufficient for rename/migration work — only running the suite is. (Exactly the standing "rebrand needs an output-level smoke-test" lesson.)
- **I twice parked the `cwf-claude-settings-merge` perm drift as "out of scope"** until the maintainer pushed back; it was a one-line `chmod`. When a fix is trivial and makes `validate` clean, do it rather than defer it.

## Key Learnings
### Technical Insights
- `rename(2)` over a destination symlink replaces the link, leaving its referent untouched — this is the testable safety property (referent unchanged), stronger and simpler to verify than an open-time `O_NOFOLLOW` refusal.
- A fixed-literal allowlist is what makes an interpolated filename component injection-safe; the safety lives in the *literal-ness*, so any future relaxation to a regex reopens the surface (recorded as an audit note in i-maintenance).

### Process Learnings
- Plan-time file enumeration should be driven by "what does `script-hashes.json` track that I'm touching?", not by an author's mental "primary vs supporting" split.
- Consolidating duplicate planned test cases into migrated equivalents is fine when documented; the AC traceability is what matters, not the case count.

### Risk Mitigation Strategies
- The same-commit hash refresh (hash-updates convention) is also a *rollback* enabler: one `git revert` restores file + recorded hash together, so `validate` never sees a torn state.

## Recommendations
### Process Improvements
- Add a plan-time checklist item to the implementation-plan phase: "list every file you will edit, then grep `script-hashes.json` for each — any match needs a same-commit hash refresh line in the plan."

### Tool and Technique Recommendations
- For any stdout→file (or rename) migration, treat "run the affected test suite" as the *only* acceptable completeness proof; do not rely on a source grep.

### Future Work
- No follow-up task required. Two forward-looking audit notes (allowlist relaxation; `atomic_write_text` callers into `/tmp`) are recorded in i-maintenance for whoever next touches that surface — they are watch-items, not debt.

## Status
**Status**: Finished
**Next Action**: Task complete — awaiting maintainer merge to main
**Blockers**: None identified
**Completion Date**: 2026-06-06
**Sign-off**: The maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning/spec: `a-task-plan.md`, `b-requirements-plan.md`, `c-design-plan.md`, `d-implementation-plan.md`, `e-testing-plan.md`
- Implementation: commit `b327ea1` (f); test migration: commit `5263e2f` (g); rollout/maintenance: `e89495f` (h), `0bf0e16` (i)
- Test results: `prove t/security-review-changeset.t` — 35 subtests, 0 failures (recorded in `g-testing-exec.md`)
- Security reviews: `## Security Review` sections in `f-implementation-exec.md` and `g-testing-exec.md` (both `no findings`)
