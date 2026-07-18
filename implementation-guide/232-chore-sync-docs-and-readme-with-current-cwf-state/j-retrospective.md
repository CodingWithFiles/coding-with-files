# Sync docs and README with current CWF state - Retrospective
**Task**: 232 (chore)

## Task Reference
- **Task ID**: internal-232
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/232-sync-docs-and-readme-with-current-cwf-state
- **Template Version**: 2.1
- **Retrospective Date**: 2026-07-18

## Executive Summary
- **Duration**: chore phases a,d,e,f,g,j; plans in a prior session, exec (f/g) + retrospective
  this session. Estimate ~1 day; actual well under — one exec pass, no rework. On target.
- **Scope**: As planned — a recurring headline-doc sync (the Task 189 precedent, ~42 tasks of
  drift later). Four docs edited; COMMANDS.md and INSTALL.md audited clean and left untouched.
- **Outcome**: Success. All TC-1..TC-9 pass; `validate: OK`; suite `Files=78, Tests=1077, PASS`;
  all 7 changeset reviews (5 at f, 2 at g) `no findings`. Drift was smaller than Task 189 —
  two substantive fixes (the permission-model inversion and two missing skills), the rest
  cosmetic wording and version-example hygiene.

## Variance Analysis
### Time and Effort
- **Estimated**: ~1 day (Low–Medium; breadth across docs, each edit low-risk).
- **Actual** (concentrated, not day-each):
  - Plan (a/d/e): prior session — audit-first scoping (2 Explore agents + 5 plan reviewers).
  - Implementation-exec (f): ~0.5 day — 11 edits across 4 docs, ground-truth recount, 5-reviewer MAP.
  - Testing-exec (g): grep/ls TC-1..TC-9 + validate + suite; no throwaway task generated.
- **Variance**: On/under estimate. The audit front-loaded the thinking, so exec was mechanical
  and single-pass — the intended shape for a doc sync.

### Scope Changes
- **Additions**: The two `cwf-project.json` config-value samples (CWF-PROJECT-SPEC.md `v1.1.188`,
  README `v1.0.0`) were an **owner decision** surfaced at plan review — they cannot be genericised
  (schema `/^v\d+\.\d+\.\d+$/`). Owner chose to **refresh to v1.1.232** (the version this task
  bumps `last_released` to and the tag before the public push), bringing CWF-PROJECT-SPEC.md and
  the optional README JSON block into the change set.
- **Removals**: The generated-artefact smoke test from the a-plan was removed at plan review —
  prose edits do not flow into template output (not a rebrand), so it would exercise nothing and
  needlessly mutate repo state. The grep sweep is the complete check. `scratchpad.md` is untracked
  → out of scope (no public exposure).
- **Impact**: Correctness improved (config samples now forward-accurate, not re-stale); no timeline
  or quality cost.

### Quality Metrics
- **Test coverage**: 100% of d-plan edits asserted (TC-1..TC-7 functional; TC-8/TC-9 non-functional).
  Negative assertions included (no bare-tag `git describe`; audited-clean files unchanged).
- **Defect rate**: zero defects introduced; zero rework. The one load-bearing edit (permission
  model) was verified against ground truth before commit and re-verified by three independent
  reviewers.
- **Integrity**: `validate: OK` (docs-only, no hash-tracked file touched — verified: 0 of the 4
  edited paths appear in `script-hashes.json`); suite green.

## What Went Well
- **Audit-first scoping right-sized the task.** Two Explore audits + five plan reviewers
  established that drift was modest and that COMMANDS.md/INSTALL.md were already clean — so exec
  edited exactly what was wrong and left the rest, avoiding the "rewrite the architecture docs"
  trap the a-plan flagged as a medium risk.
- **The load-bearing edit was verified, not asserted.** The reworded permission prose was checked
  against `hash-updates.md` L20 and the actual `cwf-manage` clamp logic (`actual & recorded`)
  before the commit, and the robustness/security/misalignment reviewers each independently
  re-confirmed it. The old "minimum 0500" wording asserted the *inverse* invariant (a floor, not a
  ceiling) — a genuine docs bug a reader could act on incorrectly.
- **Genericise-don't-chase-numbers for version examples.** `git describe` examples were genericised
  to the format shape (`<tag>-<n>-g<sha>`) so they never re-stale; only the schema-constrained
  config-value samples took a concrete number (v1.1.232), and that number is forward-accurate
  because the version bump lands it this same task.
- **Clean, single-pass exec.** All 7 changeset reviews `no findings`, all TC pass, suite green —
  no fix-and-re-run cycle.

## What Could Be Improved
- **Skill-list drift is recurring and still fixed by hand.** Two installed skills
  (`cwf-current-task`, `cwf-backlog-manager`) had never been added to CLAUDE.md's list. A guard
  already exists in the backlog — **"README skill-list drift guard (documented vs shipped /cwf-*
  set)"** — but has not been picked up, so the drift recurred and was again fixed manually. This is
  the strongest candidate for automation surfaced by the task.
- **The a-plan's "23 skills" was a miscount** (it counted the 2 loose `.md` fragments in
  `.claude/skills/` as commands). Both audit agents flagged it and it was reconciled to 21 dirs /
  20 commands at the d-plan, with a Step-1 divergence rule added so exec recounts rather than trusts
  the number. Programmatic recount, not prose-copying, is the durable fix (and the plan adopted it).

## Key Learnings
### Technical Insights
- **A documentation invariant can be inverted, not just stale.** "u+rx (minimum 0500)" was not
  merely dated — it stated the opposite of the real model (recorded perms are an upper bound
  `validate` flags only when *exceeded*; `fix-security` clamps down, never raises). Doc-sync tasks
  should check invariants for *direction*, not only for currency.
- **Two version-example classes need opposite treatment.** Format examples (`git describe` output)
  must be genericised to their shape or they re-stale every release; schema-constrained config
  values must stay concrete and format-valid. Conflating them (genericising a config sample, or
  pinning a format example to a bare tag) breaks one or the other.

### Process Learnings
- **Surface schema-constrained samples to the owner rather than defaulting.** The config-value
  refresh could not be resolved by the genericise policy (schema forbids `v1.1.x`), so it was a real
  owner decision — leave (stability) vs refresh (accuracy). Tying the refresh value to the task's
  own version bump made "refresh" forward-accurate rather than a fresh source of staleness.

### Risk Mitigation Strategies
- **Audit + plan-review before editing** kept a broad-surface task from sprawling: the reviewers'
  "leave README's file-structure line", "don't chase version numbers", and "verify the security
  wording against real behaviour" caveats all landed as exec guardrails.

## Recommendations
### Process Improvements
- For recurring doc syncs, drive every count from a programmatic recount at exec (the Step-1
  divergence rule), and check documented invariants for inversion, not just currency.

### Tool and Technique Recommendations
- Keep the grep-sweep-only verification for prose-only syncs; the generated-artefact smoke test
  belongs to rebrands (where edits reach template output), not doc syncs.

### Future Work
- **[CWF backlog, existing]** Pick up **"README skill-list drift guard (documented vs shipped
  /cwf-* set)"** — it would automate the exact manual fix this task repeated. The broader headline-doc
  drift is partly covered by the existing **"Doc-drift check when a task changes an enforced shape"**
  item.
- **[context, existing]** The docs still use "CWF" in prose throughout; a uniform "CwF" rebrand is
  its own backlog item (**"Branding cleanup: CWF to CwF rebrand…"**) and was correctly out of scope
  here (this sync introduced no new "CWF"/"CwF" prose token).
- No new backlog item created — the automation candidates this task surfaced are already tracked.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-07-18
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: a-task-plan.md, d-implementation-plan.md, e-testing-plan.md
- Execution: f-implementation-exec.md (11 edits, 5-reviewer MAP), g-testing-exec.md (TC-1..TC-9)
- Change set: CLAUDE.md, DESIGN.md, README.md, CWF-PROJECT-SPEC.md (checkpoints f=1a338d0, g=8fcdfd9)
- Precedent: implementation-guide/189-chore-sync-docs-and-readme-with-current-cwf-state/
