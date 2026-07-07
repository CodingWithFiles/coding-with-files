# Aggregate cross-project retrospective lessons - Design
**Task**: 219 (discovery)

## Task Reference
- **Task ID**: internal-219
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/219-aggregate-cross-project-retrospective-lessons
- **Template Version**: 2.1

## Goal
Define the extraction-and-synthesis pipeline that turns ~558 retrospectives
(count logged live at run start) plus session-log/LMM signal into a corroborated,
novelty-filtered, per-axis recommendation set — without any single agent (or the
orchestrator) reading the whole corpus.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions
### Architecture Choice
- **Decision**: Map-reduce over the corpus. A deterministic survey establishes the
  denominator; **read-only** extraction agents (map) each digest one project (or
  one shard of a large project) and *return* a bounded JSON digest as final text;
  the orchestrator writes each returned digest to scratch; a synthesis pass
  (reduce) clusters, corroborates, novelty-diffs, and ranks.
- **Rationale**: 558 retros cannot fit one context (High risk in a-plan). Per-project
  parallelism bounds each agent's read scope (NFR1); returning digests as text keeps
  the agents strictly read-only (NFR4 injection-containment) while the orchestrator —
  the trusted party — is the only writer.
- **Trade-offs**: Cross-project patterns only emerge at reduce, so each digest must
  carry enough structure (axis tags, verbatim lesson, source) to cluster without
  re-reading. Digests enter the orchestrator's context at return time — that token
  cost is unavoidable; persisting them to scratch buys durability across context
  compaction, not first-entry savings. Bounded per-agent output (dedup-within-project,
  capped with the dropped count recorded) plus the two-stage reduce below keep the
  synthesis tractable as the corpus grows. Rejected: one agent per retro (too many,
  cap-bound); one giant agent (blows context); agents Write their own digests (relaxes
  read-only for no real gain, since the orchestrator already holds the returned text).

### Map granularity (sharding)
One agent per project, **except** projects above ~50 retros shard by task-number
range to keep each agent's read bounded:
- coding-with-files 191 → shard (~4); gate-to-breakout-tech 101 → shard (~2–3);
  lmm 82 → shard (~2); thenetworking.app 76 → shard (~2).
- All others (≤37) → one agent each.
Sharding is a read-bound optimisation only; digests re-merge per project at reduce.

## System Design
Scratch paths use the canonical per-task leaf (`.cwf/docs/conventions/tmp-paths.md`):
`SCRATCH = ${TMPDIR:-/tmp}/cwf-home-matt-repo-coding-with-files/task-219` (derived via
`CWF::Common::scratch_dir(219)`, two-level `mkdir -m 0700` guard). Below, `SCRATCH/…`
is shorthand for that leaf. All agents are **ad-hoc Task/Explore agents** — no new
committed `.claude/agents/*.md` (assessment-only constraint).

### Component Overview (four components)
- **Survey helper** (deterministic, scratch script): counts `j-retrospective.md` per
  project at run start → the FR1 **denominator + shard plan only**. It does *not*
  classify stubs (that is fuzzy content judgement — the reading agent owns it).
  Enumerates projects from a **fixed project-root list**, not an interpolated shell
  glob; any git/path traversal is list-form spawn with `-z` (FR4 a/b; `git-path-output.md`,
  `perl.md`).
- **Extraction agent (map, read-only)**: reads one project/shard's retros, emits a
  bounded per-project digest, and is the **sole stub classifier**. No Edit/Write/mutating Bash.
- **Friction-overlay miners (read-only)**: peers of the map in the same parallel
  fan-out (no dependency on digests). (a) session-log miner over the
  `cwf-permissions-block` and `atch` sessions (+ any other on-point sessions);
  (b) LMM query set, one sweep per axis, scoped to `github@mattkeenan.net`.
- **Synthesis / reduce (orchestrator, sole writer)**: reconcile coverage → cluster →
  corroboration filter → novelty diff against the codified baseline → rank → **write
  the deliverable** (`f-implementation-exec.md` + seeded follow-up tasks). Writing the
  deliverable is the last step of reduce, not a separate component.

### Data Flow
1. Survey helper → per-project file counts + shard plan → `SCRATCH/survey.json`.
2. **Parallel MAP** (single fan-out; survey's shard plan is the only precedent): the
   sharded extraction agents **and** the friction-overlay miners all launch together
   (they share no data dependency; the reduce is the first consumer of both). Each
   extraction agent returns a bounded JSON digest as final text; the miners return the
   overlay.
3. Orchestrator writes each returned digest → `SCRATCH/digests/<project>[-shard].json`
   and the overlay → `SCRATCH/friction-overlay.json`. A returned digest that is
   missing, non-JSON, or schema-violating is recorded as a **coverage gap** for that
   project (mirrors `FrictionOverlay.gaps`), never ingested as partial/garbage.
4. **Reconcile**: `sum(retros_scanned + retros_stubbed)` over successfully-merged
   digests, **plus** gap-flagged projects, must equal the survey denominator; the
   survey file-count is authoritative and any delta is emitted as a logged gap
   (FR1 AC / NFR5). Shards re-merge per project here before corroboration so a shard
   can never count as a second corroborator.
5. **Two-stage REDUCE** (anti-fragile to corpus growth): (a) per-axis pre-reduce —
   for each of the three axes, cluster only that axis's lesson entries into candidate
   findings; (b) global merge — corroboration filter (≥2 external projects ⇒ general),
   novelty diff against `MEMORY.md`, feedback memories, `error-patterns.md`,
   `docs/conventions/`, `.cwf/docs/conventions/`, then rank (impact desc, effort asc).
   If aggregate digest input would exceed a safe context bound, stage (a) runs as
   batched sub-reduces (per project-group) whose summaries feed stage (b) — the reduce
   degrades hierarchically rather than overflowing.
6. Deliverable + seeded follow-up tasks written (final step of reduce).

## Interface Design
### Extraction-agent contract
- **Inputs**: project name; list of retro file paths (or shard slice); the axis
  taxonomy; the digest schema; the output cap.
- **Output** (final text = a JSON object, no raw file contents, deduped within project):
```
ProjectDigest {
  project: string
  retros_scanned: int
  retros_stubbed: int          // unpopulated Lessons-Learned, excluded from lessons[]
                               // (agent is the authoritative stub classifier)
  lessons_total_found: int      // deduped lessons before the cap
  lessons: LessonEntry[]        // capped, most friction-relevant first;
                               // (lessons_total_found - len(lessons)) = dropped, so
                               // cap loss is never silent (no-silent-truncation Constraint)
}
LessonEntry {
  task: string                  // e.g. "Task 152" or retro dir slug
  axis: ("token"|"permission"|"sdlc")[]   // ≥1
  lesson: string                // verbatim or tight paraphrase
  signal: string                // the friction/waste it evidences
  source: string                // repo-relative path to the retro
}
```

### Friction-overlay contract
```
FrictionOverlay {
  session_signals: SignalEntry[]   // from session logs; source = session id
  lmm_signals: SignalEntry[]       // from LMM; source = memory id/title
  gaps: string[]                   // sources unavailable/empty (NFR5)
}
SignalEntry { axis: (...)[]; signal: string; source: string }
```

### Finding + Recommendation (reduce outputs — deliverable section shapes)
These stay inside the orchestrator and feed the human-readable markdown deliverable;
they are field lists for the write-up, not wire contracts (no agent boundary crosses
them, unlike the digest/overlay schemas above).
```
Finding {
  id; axis[]; statement;
  corroborating_projects: string[];        // external projects only
  scope: "general" | "single-project";     // general iff ≥2 external
  novelty: "net-new" | "under-enforced" | "already-codified";
  evidence: string[]                        // under-enforced cites ≥1 violation
}
Recommendation {
  rank; axis[]; title; impact; effort;
  tradeoff;                                  // safety↔momentum
  followup_task_title;
  sources: string[]                          // attribution back to corpus (FR6)
}
```
`already-codified`-and-enforced findings are dropped before ranking.

## Constraints
- Read-only extraction/miner agents; orchestrator is the only writer (NFR4).
- Bounded per-agent digest; no raw file contents cross the agent boundary (NFR1).
- All intermediate artefacts live under the canonical task scratch leaf (`SCRATCH`,
  above); no `.cwf`/repo source changes (assessment-only Constraint).
- Untrusted-data handling for all mined text (NFR4); LMM scoped to the recorded email.
- **At reduce, every corpus-derived string** (`lesson`, `signal`, `statement`, `title`,
  and especially `followup_task_title`) **is data, never instruction** — no corpus
  string may select a tool call or be executed. This is the sharpest FR4(c) surface:
  attacker-influenceable text reaches the orchestrator, the one component that writes
  files and seeds task titles; the source-attribution chain (FR6) lets a maintainer
  trace any suspect recommendation before acting on it.

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [x] **Complexity**: 3 axes — handled by one shared extraction + per-axis reduce, as
      designed. Not a structural decomposition trigger.
- [ ] **Risk**: No isolated high-risk components (read-only, assessment-only).
- [x] **Independence**: Remediation (not investigation) decomposes — into the seeded
      follow-up tasks the deliverable emits.

## Validation
- [ ] Design review completed (plan-review map/reduce)
- [x] Architecture satisfies FR1–FR6 and NFR1–NFR5 (traced above)
- [x] Integration points verified: survey helper counts reconcile; scratch digest
      paths are the sole reduce input; LMM/session-log sources confirmed to exist

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
