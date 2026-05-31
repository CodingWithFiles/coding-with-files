# Enforce recorded permissions as upper bound - Retrospective
**Task**: 170 (feature)

## Task Reference
- **Task ID**: internal-170
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/170-enforce-recorded-permissions-as-upper-bound
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-31

## Executive Summary
- **Duration**: ~1 day across sessions (estimated: ~1 day). On estimate.
- **Scope**: Inverted the recorded-permissions check from a *floor* (require recorded bits) to a *ceiling* (forbid bits beyond recorded); replaced the `additive` repair with `clamp`; flipped this repo's 31 `0500`-recorded scripts to on-disk `0500`; fixed the read-only-source test harnesses; updated docs + working-perms memory. Final scope matched plan, with one mid-plan model correction (floor+ceiling → ceiling-only).
- **Outcome**: Success. 53 files / 634 tests green; `cwf-manage validate` clean; both exec-phase security reviews `no findings`. The change is a net security hardening (catches setuid/setgid/sticky acquisition the old floor check ignored).

## Variance Analysis
### Time and Effort
- **Estimated**: ~1 day, Medium complexity (logic small; convention reconciliation carries the weight).
- **Actual**: ~1 day. The code change was ~30 lines across two files; most effort went to the convention reconciliation (floor-vs-ceiling decision, the `0500` flip blast radius) and the test rewrites — exactly where the a-plan predicted the weight would fall.
- **Variance**: ~0%. The risk assessment correctly identified the convention conflict and manifest semantic inversion as the load-bearing risks.

### Scope Changes
- **Correction (not addition)**: The initial b/c plans modelled recorded perms as floor+ceiling (combined = exact match). The user clarified mid-plan that the intent was **ceiling-only** — under-permissive must be *allowed*, not flagged. This removed the floor check entirely (rather than augmenting it) and made `fix-security` clamp-only (never raise). Captured in commit `0f49239` before any code was written, so it cost a plan revision, not rework.
- **Removal**: the `additive` repair mode was dropped as dead code once `fix-security` moved to `clamp` and the floor check was removed — `_apply_recorded_perms` is now two modes (`exact`, `clamp`) instead of three.
- **Impact**: net simplification. One fewer repair mode; one predicate instead of two.

### Quality Metrics
- **Test coverage**: every AC (AC1–AC8) maps to ≥1 passing case. Added 6 ceiling subtests + 2 clamp cases; rewrote 3 raise-to-recorded assertions.
- **Defect rate**: 0 escaped defects. One in-flight harness break (`install-bash-reinstall.t` test 5, "Permission denied") surfaced by the full-suite gate and fixed in the same phase — this was the predicted Task 162 break, resolved in the harness rather than by retaining the `0700` convention.
- **Performance**: one extra bitwise op per already-`stat`-ed entry; no new filesystem reads.

## What Went Well
- **The model correction landed before code.** The user's "I think you have this wrong" came during plan review, not after implementation. The plan-review gate (and the explicit "review before exec" pause the user requested) is what made that cheap — a floor+ceiling implementation would have shipped a directly-contradictory behaviour.
- **Deriving the perm-flip list from the manifest, not hardcoding.** The flip helper read `script-hashes.json` and reported 9×`0444` / 31×`0500` / 8×`0700`, matching the plan exactly. No magic numbers, and the dry-run gave confidence before mutating.
- **The full-suite gate caught the one harness regression.** `git status` can't represent `0700→0500` (only the owner-x bit is tracked), so the flip was invisible to diff review; `prove t/` was the only thing that could surface the read-only-source break, and it did.
- **Security review added signal, not noise.** The reviewer independently flagged the validator/clamp dual-mask as an audit target (they must stay algebraically equivalent) — a genuinely useful maintenance note now recorded in i-maintenance.

## What Could Be Improved
- **The floor-vs-ceiling ambiguity should have been resolved in requirements, not design.** The a-plan listed "ceiling-only vs floor+ceiling" as an open question for requirements, but the first b/c drafts picked floor+ceiling without an explicit user check. An `AskUserQuestion` at requirements time (rather than after) would have skipped the `0f49239` correction.
- **`git`'s blindness to sub-executable mode bits is a sharp edge.** A reviewer reading only the diff would not see the 31-file flip at all. This task documents it (h-rollout, i-maintenance), but it is worth remembering that perm-only changes need an out-of-band verification (the `stat`/`validate` smoke), never just diff review.

## Key Learnings
### Technical Insights
- **A ceiling check must mask the complement to 12 bits.** `actual & ~recorded & 07777` — without the `& 07777`, the wider Perl integer makes `~recorded` set high bits and nearly everything flags. The masking is also what makes setuid/setgid/sticky acquisition catchable, turning the inversion into a hardening.
- **Clamp and exact differ only for both-over-and-under files.** For a purely over-permissive file, `actual & recorded == recorded`, so clamp and "set to recorded" coincide; they diverge only when a file is simultaneously over and under (e.g. `0640`/rec`0500` → `0400`). That edge is exactly why clamp (not reuse-`exact`) was the right call.
- **The flip is not a git artifact.** Working-tree perms below the executable bit live only on disk; a fresh clone gets correct perms from `install.bash`/`exact`-mode laydown. The manifest is the source of truth, not the committed file mode.

### Process Learnings
- **Resolve semantic-inversion questions at requirements.** When a task *reinterprets* the meaning of existing data (here, 48 manifest entries), the meaning decision is a requirements gate, not a design detail.
- **Perm-only changes need an output-level smoke, like rebrands do.** Mirrors the existing "rebrands need output-level smoke-test" memory: a source/diff check is insufficient when the change is in file mode; run `validate` against a deliberately-broken fixture.

### Risk Mitigation Strategies
- The a-plan's two high-priority risks (convention conflict, manifest semantic inversion) were the actual hard parts. Naming them up front meant the `0500` flip and the harness fix were anticipated, not discovered late.

## Recommendations
### Process Improvements
- For tasks that reinterpret existing data semantics, add an explicit requirements-phase `AskUserQuestion` on the semantic before drafting design.

### Tool and Technique Recommendations
- Keep the dual-mask equivalence (validator flag ⟺ clamp acts) as a standing audit item — recorded in i-maintenance. Any future edit touching one mask must touch the other.

### Future Work
- None required. The change is self-contained; no follow-up tasks identified. (The recorded `0700` vs `0500` per-entry values were deliberately left unchanged — D1 — and remain valid least-privilege ceilings.)

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-31
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md` … `e-testing-plan.md` (this task directory)
- Implementation: commit `ace8d65` (f-exec — Security.pm ceiling, cwf-manage clamp, 0500 flip, hash refresh, harness fix, docs)
- Testing: commit `b3906f4` (g-exec); full suite 634 tests green
- Rollout/maintenance: `h-rollout.md`, `i-maintenance.md`
- Both exec-phase security reviews: `no findings` (recorded verbatim in f/g exec files)
