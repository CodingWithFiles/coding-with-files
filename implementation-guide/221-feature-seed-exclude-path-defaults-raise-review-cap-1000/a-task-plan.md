# Seed exclude-path defaults, raise review cap 1000 - Plan
**Task**: 221 (feature)

## Task Reference
- **Task ID**: internal-221
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/221-seed-exclude-path-defaults-raise-review-cap-1000
- **Baseline Commit**: aa0573dd0946c8c4b459c6875dfef21dbda8a63f
- **Template Version**: 2.1

## Goal
Give new CWF projects a sensible default `security.review` config (excluding
test/generated/doc-only paths from the production-line cap) and raise the
built-in cap from 500 to 1000, so the changeset review stops false-tripping on
non-production churn and full-task-back diffs.

## Background
Delivers backlog item **R1** (Task 219, High) plus a user-requested cap bump.
Task 218 already built the *mechanism*: `security.review.max-lines-exclude-paths`
(git `:(glob,exclude)` pathspecs, no Perl-side matching) and
`security.review.max-lines`, resolved as `--max-lines` > config > built-in
default. What is missing is (a) a seeded default exclude set — the keys ship
unset, so every project re-derives them — and (b) the built-in default of 500
(`security-review-changeset:101`) is hit semi-frequently, especially when a
review diffs all the way back to a task's baseline. R1's "deweight in
`security-review-changeset`" alternative needs no new code — the exclude
mechanism already provides it; this task only supplies the defaults and the cap.

## Success Criteria
- [ ] A fresh `cwf-init` produces a `cwf-project.json` carrying a `security.review`
      block with an exclude-path default set and no other behaviour change.
- [ ] With that seeded config, a changeset whose only churn is in excluded paths
      (tests, generated, doc-only) counts zero production lines against the cap.
- [ ] Absent any config, `security-review-changeset` caps at 1000 production lines
      (verified: 1000 passes, 1001 exits 2).
- [ ] Config precedence is unchanged: `--max-lines` > `security.review.max-lines` >
      built-in default.
- [ ] All seeded exclude globs are valid git pathspecs (helper does not exit 1 on
      a malformed-pattern read) and the hash of every edited hashed file is
      refreshed in the same commit.

## Original Estimate
**Complexity**: Low
**Dependencies**: Builds on Task 218's cap + exclude mechanism (shipped). No external deps.

## Major Milestones
1. **Requirements**: Pin the exact default exclude glob set and confirm the 1000 cap.
2. **Design**: Decide seeding surface (config template vs skill-side write) and
   whether to backfill this repo's own installed config.
3. **Implementation + Test**: Apply defaults + cap bump, refresh hashes, extend
   `t/` coverage for the new default behaviour.

## Open Decisions (resolve in requirements/design)
- **Exact exclude glob set** — which test (`*_test.*`, `t/**`?), generated/vendored,
  and doc-only markdown patterns. Doc-only markdown is the riskiest: too broad a
  `**/*.md` exempts real doc-heavy production work from the cap.
- **Seeding surface** — add the block to `.cwf/templates/cwf-project.json.template`
  (inherited only by new `cwf-init`) vs a skill-side merge. Template is the current
  seed path and lowest-friction.
- **Backfill** — whether to add the block to this repo's installed
  `implementation-guide/cwf-project.json`, or leave existing installs untouched.

## Risk Assessment
### High Priority Risks
- **Over-broad excludes weaken the review cap**: the cap is a review-scope guard;
  excluding a path also exempts genuine production code living there. Fail-open.
  - **Mitigation**: keep the default set conservative and unambiguous (test/vendored/
    generated only); treat doc-only markdown scope as a requirements decision, not a
    default assumption. Document each glob's intent.

### Medium Priority Risks
- **Malformed seeded glob makes the helper fatal**: a bad pathspec makes git fatal →
  helper exits 1.
  - **Mitigation**: test each seeded glob against `git diff --numstat` before shipping.
- **Hashed-file edit without hash refresh**: `security-review-changeset` is
  hash-tracked; the cap edit needs a same-commit `script-hashes.json` refresh.
  - **Mitigation**: disclose the hashed path + `script-hashes.json` as a Supporting
    Change in the d-plan (`hash-updates.md` rule).

## Dependencies
- Task 218 cap/exclude machinery (already merged).

## Constraints
- No new config surface beyond `security.review.*` (Task 218's namespace).
- Perl core-only; git owns glob matching (no Perl-side path classification).

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — one config seed + one constant.
- [ ] **Risk**: high-risk components needing isolation? No.
- [ ] **Independence**: separable parts? No.

No decomposition — single-concern feature.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five success criteria met with no scope change. Seeded a generic 20-glob
`security.review.max-lines-exclude-paths` default into the config template, raised the
built-in cap 500→1000, dog-fooded the new default (dropped this repo's redundant explicit
`max-lines`), and synced docs + tests. Reused Task 218's engine — no new runtime code.
979 tests pass; `cwf-manage validate` OK. See `j-retrospective.md` for variance analysis.

## Lessons Learned
The plan's top risk (over-broad excludes weakening the cap) was mitigated as designed via
a conservative glob set + a live-tree FR3 guardrail. The one defect produced — a
false-PASS in that guardrail's own test — was caught by the exec review MAP, validating
running the full review even on a Low-complexity task.
