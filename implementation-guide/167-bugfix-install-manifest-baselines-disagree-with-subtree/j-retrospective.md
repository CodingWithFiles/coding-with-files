# install manifest baselines disagree with subtree - Retrospective
**Task**: 167 (bugfix)

## Task Reference
- **Task ID**: internal-167
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/167-install-manifest-baselines-disagree-with-subtree
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-28

## Executive Summary
- **Duration**: ~1 day across one working session (all phases planned and
  executed end-to-end). Estimate from a-plan: 0.5–1 day. **Within estimate.**
- **Scope**: Fixed exactly as scoped — drop the `rules-inject` manifest
  entry, cascade 14 cleanup sites, add INV-1/INV-2 regression test,
  refresh four hashes in-commit. One mid-execution scope micro-adjustment
  (retire 5 test subtests rather than 1, per user-approved Deviation A
  in f-exec).
- **Outcome**: Bug fully fixed at the source-of-truth level. Every
  consumer on v1.1.155 → v1.1.166 unblocked from the
  `cwf-manage update` rules-inject abort. Architectural rule (INV-2)
  codified so the defect class cannot recur.

## Variance Analysis

### Time and Effort
- **Estimated** (a-plan):
  - Planning + Design + Implementation-plan + Testing-plan: bundled
  - Implementation exec + Testing exec: bundled
  - Total: 0.5–1 day
- **Actual** (rough — same-session work, no per-phase wall-clock):
  - Planning (a): brief — well-scoped from bug report
  - Design (c): moderate — converged in one revision after plan review
  - Implementation plan (d): moderate — converged in one revision after
    plan review; carried five "Refinements" forward from review findings
  - Testing plan (e): brief — most TCs delegated to existing test files
  - Implementation exec (f): the heaviest phase — Deviation A
    required investigation and user-facing reconciliation
  - Testing exec (g): brief — five gates ran first-time green
  - Retrospective (j): brief
- **Variance**: Within estimate. The five-Refinement carry-forward in
  d-plan absorbed plan-review work that would otherwise have surfaced
  in f-exec; the one plan-review-undetected gap (synthetic-fixture
  fallout) cost roughly an additional 15 minutes including the user
  question.

### Scope Changes
- **Additions**: None — what landed matches the design and plan.
- **Removals (in-exec)**: Five subtests retired in `t/cwf-apply-artefacts.t`
  (TC-RI-1, TC-RI-2, TC-RI-3, TC-FR5-KEEP, TC-FR5-NEW). They tested
  apply_replace via the rules-inject artefact specifically; once the
  artefact left the manifest inventory, the tests no longer drove the
  intended code path. Backlog follow-up filed at Low priority.
- **Impact**: Net test delta `+6 new − 5 retired = +1 subtest` that
  covers a stronger invariant than the retired ones did.

### Quality Metrics
- **Test Coverage**: 100% of shipped manifest artefacts covered by
  ≥1 subtest in `t/installmanifest-integrity.t`. Full suite green
  (619 tests, 53 files).
- **Defect Rate**: Zero defects introduced. The new test fails-on-HEAD
  (pre-fix) and passes post-fix — the strongest evidence the regression
  check is meaningful.
- **Security**: Both exec-phase security-review subagent verdicts
  returned `no findings`. Allowlist contraction is strictly tightening,
  hash refresh landed in-commit per `[[hash-updates]]`.

## What Went Well

- **Root-cause investigation was sharp**: three-layer diagnosis
  (manifest entry → empty source → subtree-shipped file) found the
  defect's true location (Task 127's misclassification) rather than
  patching the symptom (the conflict prompt).
- **INV-2 as a schema rule, not a value-equality check**: the design
  pivot from "make the SHAs agree" to "no artefact `dest`/`container`
  under `.cwf/`" is a stronger institutional memory — it catches the
  whole defect class, not just this instance.
- **Fail-on-HEAD test-first**: writing the regression check before the
  fix and confirming it caught the live defect on the unmodified tree
  is exactly the verification discipline that earns the test its
  permanent place in the suite.
- **Plan-review subagents earned their cost**: the two rounds of
  4-parallel-reviewer review caught a JSON-malforming comma error
  (would have broken the fix immediately), an under-scoped SKILL.md
  edit list (would have shipped stale docs), and a non-existent
  helper reference (would have failed at first test run). All three
  caught at plan-time, not exec-time.
- **`AskUserQuestion` for Deviation A**: presented a binary/trinary
  choice with concrete trade-offs, took the answer, executed cleanly.
  This is the right exec-time surface for plan-vs-reality gaps.

## What Could Be Improved

- **The d-plan's "tests survive unchanged" claim was unverified**: the
  d/e plan-review process didn't catch that `build_source`'s synthetic
  manifest still re-declared the `rules-inject` artefact, which the
  helper would later reject schema-side. The review subagents read the
  changeset description, not the actual fixture code. **Recommendation**:
  when a plan claims "test fixtures unchanged", the reviewer should be
  pointed at the specific fixture-builder function to read.
- **Hash-tracking ergonomics** (continuing pattern, not specific to
  this task): four files needed hash refreshes; each required a
  separate `sha256sum`, manual transcription into `script-hashes.json`,
  and a sanity re-read. This is well-understood but mechanical;
  worth tracking but not specific to this bugfix.
- **The `index.lock` race surfaced again**: the background-git
  contention caused multiple `git add` retries during the f-phase
  checkpoint. The user prompted manual `rm .git/index.lock` once.
  Likely a separate Claude Code harness/model regression in the last
  24 hours per the user's comment — outside this task's scope, but
  noted because it cost more time than usual.

## Key Learnings

### Technical Insights
- **Strategy dispatch via static @INVENTORY decouples manifest schema
  from helper behaviour**: removing the manifest entry alone isn't
  enough — the inventory row must also go, or the inventory row alone
  must change. Pairing the two is correct; mismatch is a category of
  defect (caught here only by the f-exec test run).
- **Path-allowlist contractions cascade into fixtures**: any test
  fixture that builds a manifest entry naming the just-removed dest
  prefix will now fail validation. This is the same mechanism that
  caught Task 127's defect (the runtime helper rejecting the
  consumer's manifest entry); it's also what made the synthetic
  fixtures fail here. The mechanism is doing what it should.
- **Test-first works for manifest schema rules too**: writing
  `t/installmanifest-integrity.t` before any source edit, then
  confirming INV-2 fails on the live tree, gives the rest of the
  task the strongest possible verification rail. The same discipline
  scales beyond code to any structured-data invariant.

### Process Learnings
- **Plan-review must read fixture code, not just plan text**: the
  Misalignment/Robustness reviewers caught real defects in the plans
  but missed the synthetic-fixture mismatch because that's a fact
  about test code the plan didn't explicitly mention. Going forward,
  "TC-X..Y survive unchanged" claims should be paired with a fixture
  audit citation in the plan itself.
- **Refinements as a plan-review carry-forward**: the d-plan's five
  Refinements section worked well as a bridge between plan-review
  findings and execution. It prevented the implementation from
  re-litigating the design and kept the f-exec checklist mechanical.

### Risk Mitigation Strategies
- **Documented hard-defer with rationale**: the e-plan §Reproducer
  Scope Decision explicitly chose INV-2 + existing e2e tests over a
  literal v1.1.155 → post-fix reproducer. The decision is held up by
  this retrospective — the fix landed, the bug is gone, the test
  catches recurrence, and ~60 lines of fixture plumbing was avoided.
- **Per-file pre-refresh `git log` check**: Step 1's verification
  that the currently-recorded sha256 in `script-hashes.json` matches
  a sha256 visible in each file's git history is cheap insurance
  against amending the wrong baseline. Did not catch anything this
  time, but it's the right discipline.

## Recommendations

### Process Improvements
- **Add a "fixture audit" line to plan-review prompts**: when a plan
  changes a path-allowlist, regex pattern, or schema rule, the
  reviewer should be explicitly asked to enumerate every fixture that
  declares an entry matching the change. This is the specific gap that
  caused Deviation A.
- **Plan-time "fixture decl census" snippet**: a one-liner like
  `git grep -nE 'rules-inject' t/` should appear in plans that touch
  any allowlist/inventory key. Cheap to run, would have surfaced the
  `build_source` declaration site immediately.

### Tool and Technique Recommendations
- **Schema-rule tests over value-equality tests**: when fixing a
  configuration defect, ask whether the underlying invariant is a
  *value* or a *rule*. Where it's a rule (as here — "no `.cwf/`
  prefix"), encode it as a rule. Future regressions of the same
  shape will fail the test; value-equality tests only catch this
  specific instance.

### Future Work
- **Low**: Restore CWF_UPGRADE_RESOLVE=keep/new coverage without
  rules-inject (already filed in BACKLOG — pivot TC-FR5-* against
  `cwf-rules-bundle` tree-replace or `claude-md-preamble`
  embedded-block).
- **Medium** (pre-existing, depends on this task): Reclassify
  rules-inject.txt as consumer-owned; add seed-once artefact
  strategy. The bug here was the surface symptom; this addresses the
  ownership-model confusion that put rules-inject in the manifest
  in the first place.
- **Low** (pre-existing, optional): Historical-bug reproducer TC —
  synthesise a v1.1.155-style upstream and assert the post-fix update
  succeeds non-interactively. ~60 lines of git-historical fixture
  plumbing for one assertion; only worth doing if a future bug-class
  walk-through needs it.

## Status
**Status**: Finished
**Next Action**: Task complete; suggest merge.
**Blockers**: None
**Completion Date**: 2026-05-28
**Sign-off**: Maintainer (Co-developed-by Claude Opus 4.7)

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- `a-task-plan.md` — bug-report-driven plan, ACs and milestones
- `c-design-plan.md` — D1 + D2 + D3 design with 14-site cascade
- `d-implementation-plan.md` — 10-step checklist + 5 Refinements
- `e-testing-plan.md` — three-tier validation strategy
- `f-implementation-exec.md` — execution log + Deviation A
- `g-testing-exec.md` — all 5 gates green
- Commits on this branch: `d6f2087` (a), `509d6d3` (c), `f7e44f4` (d),
  `61f9140` (e), `47ba0fa` (f), `d3db8fe` (g), j-phase to follow.
- Pre-fix test failure artefact:
  `/tmp/-home-matt-repo-coding-with-files-task-167/test-fail-pre-fix.txt`
- BACKLOG follow-up: "Restore CWF_UPGRADE_RESOLVE keep/new coverage
  without rules-inject" (Low, chore).
