# Aggregate cross-project retrospective lessons - Implementation Plan
**Task**: 219 (discovery)

## Task Reference
- **Task ID**: internal-219
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/219-aggregate-cross-project-retrospective-lessons
- **Template Version**: 2.1

## Goal
Execute the map-reduce corpus pipeline from the design and write the per-axis,
corroborated, novelty-filtered recommendation set into `f-implementation-exec.md`.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `f-implementation-exec.md` — the deliverable (written via `/cwf-implementation-exec`):
  §1 method + coverage reconciliation, §2 per-axis findings, §3 ranked
  recommendations, §4 seeded follow-up tasks. **This is the only tracked artefact.**

### Supporting Changes (scratch only — not committed)
- `SCRATCH/survey.sh` — deterministic survey script (fixed project-root list, `-z`).
- `SCRATCH/survey.json` — per-project retro file counts (both `h-`/`j-` conventions) + survey-gap list.
- `SCRATCH/digests/<project>[-shard].json` — per-project extraction digests.
- `SCRATCH/friction-overlay.json` — session-log + LMM signal.

Where `SCRATCH = /tmp/claude-1000/cwf-home-matt-repo-coding-with-files/task-219`
(the injected per-task leaf; already provisioned).

Assessment-only: **no `.cwf`/repo source changes**. No symbols deleted.

## Implementation Steps
### Step 1: Setup
- [ ] Leaf `SCRATCH` is already provisioned via `CWF::Common::scratch_dir(219)`
      (two-level guarded create + symlink-parent reject); create only the
      `SCRATCH/digests/` subdir.
- [ ] Fix the inputs: the 11-project root list (a fixed maintainer literal — safe
      because never derived from config/env/corpus), the axis taxonomy
      (`token` | `permission` | `sdlc`), the per-agent lesson cap, and the digest
      schema from the design.

### Step 2: Survey (denominator)
- [ ] Write `SCRATCH/survey.sh`: for each fixed project root, count retrospectives
      matching **both** conventions — `j-retrospective.md` (v2.1) **and**
      `h-retrospective.md` (pre-v2.1, older tasks) — so the denominator does not
      silently drop the `h-`era corpus. Enumerate with `git ls-files -z` per root
      (git-tracked, NUL-safe, convention-conformant — not `find … | wc -l`).
- [ ] A missing/unreadable project root is recorded as a **survey-level gap**
      (distinct from a legitimate 0-retro count), so it surfaces, never smooths.
- [ ] Emit `SCRATCH/survey.json` = `{project, retro_count}[]` + the survey-gap list.
      The shard plan is already fixed in the design (>50-retro projects), so the
      script need not re-derive it. Survey does **not** classify stubs.
- [ ] Run it; record the live total (supersedes the j-only ~558 snapshot, which is now
      known to undercount).

### Step 3: Parallel MAP (single fan-out)
- [ ] Launch, in one parallel batch (survey's shard plan is the only precedent):
  - [ ] one read-only extraction agent per project/shard → returns a bounded
        `ProjectDigest` JSON as final text (sole stub classifier; records
        `lessons_total_found` so cap loss is visible).
  - [ ] session-log miner (read-only) over `cwf-permissions-block`, `atch`, and any
        other on-point sessions → session signals.
  - [ ] per-axis LMM sweeps (`github@mattkeenan.net`) → LMM signals.
- [ ] Miners emit `FrictionOverlay` with a `gaps[]` list for absent/empty sources.

### Step 4: Persist + reconcile
- [ ] Orchestrator (sole writer) writes each returned digest to
      `SCRATCH/digests/<key>.json`, where `<key>` is the orchestrator's own dispatch
      identity (the survey project-root/shard it launched), **never** the
      agent-returned `project` field (attacker-influenceable — a `../` there must not
      escape the dir). Overlay → `SCRATCH/friction-overlay.json`.
- [ ] A digest that is missing / non-JSON / schema-violating, **or whose returned
      `project` ∉ the fixed survey set**, is logged as a **coverage gap**, not ingested.
- [ ] Reconcile (survey authoritative): `sum(retros_scanned + retros_stubbed)` over
      merged digests **+ sum(surveyed retro_count of each gap project)** == survey
      denominator. Gap projects contribute their *surveyed retro count* (not
      one-per-project); log any delta.

### Step 5: Two-stage reduce
- [ ] Stage (a) per-axis pre-reduce: cluster each axis's lessons into candidate findings.
- [ ] Stage (b) global merge: corroboration filter (≥2 **external** projects ⇒ general;
      this-repo ≤1 corroborator), novelty diff against `MEMORY.md`, feedback memories,
      `error-patterns.md`, `docs/conventions/`, `.cwf/docs/conventions/`
      (net-new / under-enforced[+cited violation] / already-codified→drop), then rank
      (impact desc, effort asc). Batched sub-reduce fallback if input exceeds context bound.

### Step 6: Write deliverable (in f-exec)
- [ ] Compose `f-implementation-exec.md` §1–§4. Every corpus-derived string treated as
      data (esp. `followup_task_title`); every recommendation source-attributed.

## Code Changes
No repo code. The only script is the ephemeral `SCRATCH/survey.sh` (bash over a
fixed literal root list; per root, count `{h,j}-retrospective.md` via
`git ls-files -z … | grep -zc .`, NUL-safe; JSON emit). Not committed, so no
before/after repo diff.

## Test Coverage
**See e-testing-plan.md for complete test plan** — reconciliation exactness, axis
coverage, corroboration rule, novelty classification, attribution presence, ranking order.

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned investigation before marking Finished. The
deliverable must cover all six ACs; any sampled/capped/gapped coverage is logged,
never silently dropped.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
