# scrub private data from docs and history - Retrospective
**Task**: 231 (bugfix)

## Task Reference
- **Task ID**: internal-231
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/231-scrub-private-data-from-docs-and-history
- **Template Version**: 2.1
- **Retrospective Date**: 2026-07-18

## Executive Summary
- **Duration**: ~3 calendar days (2026-07-16 → 2026-07-18); estimated ~1 day (variance
  +200%). The overrun is entirely follow-on work discovered mid-task, not slippage on the
  planned redaction: a public-exposure investigation, a headless `gh` auth detour, two
  leak classes surfaced only by review/testing, and a doc-genericisation pass.
- **Scope**: Planned as "redact `implementation-guide` docs + rewrite history". Widened
  (owner decision) to the **whole tracked tree** and to **commit + annotated-tag messages**,
  then to **genericising the task's own workflow docs** so the scrub is not re-seeded by
  the very files that describe it.
- **Outcome**: Success. The redaction tooling and the D6 gate are built, and the gate is
  **green on a disposable clone** across all three categories × three surfaces × all 432
  refs, with negative controls proving it can fail. The live rewrite + push is staged as a
  verified **human-only runbook** — the deliberate task boundary, not deferred work.

## Variance Analysis
### Time and Effort
- **Estimated**: ~1 day total (mechanical redaction easy; history rewrite the risk).
- **Actual** (concentrated, not full-day-each):
  - Planning/Design/Impl-plan/Test-plan: ~0.5 day — smooth, one coupled design.
  - Implementation-exec: ~1 day — inventory, rules authoring, clone-first gate, the
    `lmm`-retention decision, and the dashified-username leak fix.
  - Testing-exec: ~0.5 day — TC-1..TC-12, the G1 self-leak fix, the 432-ref coverage proof.
  - Follow-on (this session): ~1 day — public-exposure investigation, `gh` headless auth,
    runbook push-safety fixes, and genericising a/c/d/f/g of raw private tokens.
- **Variance**: +200%. Cause is **discovery, not misestimation of the known work**. The
  original estimate priced the redaction; it did not price "the docs describing the
  redaction are themselves a leak surface" or "verify what is already public before
  claiming this is prevention".

### Scope Changes
- **Additions**:
  - **Whole-tree + message scope** (owner): not just `implementation-guide/**` but every
    tracked blob, plus commit-message and annotated-tag-message bodies (the `claude@…`
    trailers carried the personal address in every commit).
  - **Dashified-username path class**: review found scratch/analysis paths embed the
    username as `home-<user>` (a `-`, not `/`), invisible to the slash-anchored rules —
    72 committed docs. Added a dedicated regex + verify pattern.
  - **Task-doc genericisation**: the a/c/d/f/g docs themselves named raw private tokens.
    Genericised to categories so publication of the task record does not re-expose the
    data ("no point redacting the repo only to add it back in the task docs").
  - **Public-exposure remediation framing**: confirmed `origin/main` already carries 58
    private-data files → the scrub is remediation of a live exposure, not only prevention.
- **Removals / deferrals**:
  - **`lmm` retained entirely** (owner): entangled with the `mcp__lmm__*` API namespace and
    a tracked directory path (`--replace-text` cannot rewrite paths); scrubbing content-only
    would be inconsistent for no privacy gain.
  - **Tag re-push deferred** (owner): the 22 public tags still point at old unscrubbed
    commits; a `main` force-push does not move them. Exposure stays open until they are
    separately force-updated or deleted — captured as future work, not silently dropped.
- **Impact**: correctness improved (two real leak classes closed that the initial rules
  missed); timeline tripled; no quality compromise — every addition went through the gate.

### Quality Metrics
- **Test coverage**: TC-1..TC-12 all executed; 100% of D6 gate items; all 3 categories ×
  3 surfaces × 432 refs. Negative controls (TC-1/TC-2) demonstrate the gate fails on a
  planted leak — a gate never shown to fail is not trusted.
- **Defect rate**: two defects found and fixed **before** any live run — the dashified-path
  miss (review) and the G1 self-leak in f-exec (TC-4 content scan). One process defect in
  CWF tooling logged to BACKLOG (changeset helper re-execution gap). Zero escaped defects.
- **Integrity**: post-scrub `validate` shows **zero sha256/content/existence violations**;
  the only drift is umask-derived permission drift, cleared by `fix-security`. No hashed
  blob altered.

## What Went Well
- **Clone-first, never the live repo**: the "test DB, never production" rule applied to
  history. Every dry-run and the full gate ran on a disposable `--no-local` clone; the live
  rewrite is a human-only runbook. Both leak classes were caught on clones, pre-exposure.
- **Negative-control-first gate**: `verify.sh` was proven to *fire* on a planted leak (and
  *not* fire on the kept address) before any PASS was trusted.
- **All-refs coverage by construction**: `git filter-repo`'s single consistent object map
  means the `rev-list --all` pass genuinely covers all 432 refs (235 task + 197 checkpoint
  branches), not just `main` — verified empirically (433 remote-tracking → 432 local heads,
  0 leak hits).
- **Owner-in-the-loop on ambiguity**: `lmm` retention and the whole-tree/message scope were
  surfaced as decisions, not resolved unilaterally — the right calls for irreversible work.
- **Describe-don't-embed discipline** turned the review findings into a durable rule now
  recorded in f-exec/g-exec.

## What Could Be Improved
- **Leak inventory was incomplete twice.** The initial rules missed the dashified-username
  form and a made-up Class-B example string in the task's own doc. Both were caught
  downstream (review, then the all-history scan) rather than at inventory time. A redaction
  task should enumerate *path-embedding variants* (slash, dash, URL-encoded) up front.
- **The task's own workflow docs were a blind spot.** They embedded raw tokens and a
  synthetic tally that matched the leak pattern — the deliverable describing the redaction
  re-seeded it. Recognised late; genericising a/c/d/f/g was unplanned rework.
- **A CWF helper under-covered its own changeset.** On testing-exec *re-execution*,
  `security-review-changeset` captured the untracked `j-retrospective.md` but missed the
  tracked, already-committed `g-testing-exec.md` amendment — the file under review was
  absent from the diff handed to the reviewer. Worked around manually; logged to BACKLOG.
- **Estimate priced the mechanical work, not the epistemics.** "Is it complete?" and "what
  is already public?" dominated the effort and were not in the estimate.

## Key Learnings
### Technical Insights
- **filter-repo apply order is all-literals-first (file order), then all-regexes (file
  order)** over the whole blob — not "most-specific first". `#` is **not** a comment in a
  replace-text file (it becomes a literal). Verified by reading the installed source; this
  corrected an earlier design assumption.
- **git records only the exec bit**, so recorded sub-modes (0500/0444) always drift to
  umask on a fresh checkout. Any history-rewrite runbook must include a `fix-security`
  clamp step, or `validate` will read as failing when nothing was tampered with.
- **A force-push does not move tags and does not purge old commits.** Tags independently
  pin the old history; unreferenced commits stay reachable by SHA until the remote GCs.
  With **0 PRs and 0 forks** confirmed, no Support purge is needed for the branch — GC
  reclaims it — but the tags must be handled separately.
- **Dashified paths are a distinct leak class** from slash paths: scratch/analysis tooling
  embeds `home-<user>` with a hyphen, which slash-anchored rules silently miss.

### Process Learnings
- **A redaction effort's own artefacts are a leak surface.** The verification pattern will
  match the task's documentation of that pattern. Rule: *describe example/plant strings,
  never embed them*, and do not reintroduce raw tokens into the task docs you are about to
  publish.
- **Verify current exposure before framing the fix.** Checking `origin` (58 files already
  public, 0 PRs, 0 forks) reframed the work from prevention to remediation and determined
  that no delete/recreate was required.
- **Irreversible operations belong behind a human-only runbook**, same class as
  merge-to-main — surfaced as commands, gated, with a pre-push sole-branch check and an
  explicit backup/restore path.

### Risk Mitigation Strategies
- Clone-first + negative-control-first + all-surfaces scan is a reusable shape for any
  "prove something is absent everywhere" task.
- Surfacing entangled tokens (`lmm`) to the owner rather than forcing a brittle rule
  avoided an inconsistent, low-value partial scrub.

## Recommendations
### Process Improvements
- For redaction/scrub tasks, add an explicit **"scan the task's own docs against the leak
  pattern"** step before the checkpoint commit — the self-leak class (G1) is predictable
  and should be a gate, not a discovery.
- Enumerate **path-embedding variants** (slash, dash, URL-encoded, basename-only) during
  inventory, not after review.

### Tool and Technique Recommendations
- `git filter-repo --replace-text --replace-message` from one rules file is the right tool:
  one source of truth, one consistent object map across all refs, tags re-pointed
  automatically.
- Fix the changeset-review helper gap (BACKLOG item, below) so amendment re-executions
  review the file actually being amended.

### Future Work
- **[owner, human-only]** Run the staged live runbook (f-exec Step 4): backup → in-place
  `filter-repo` → `fix-security` → `verify.sh . <N>` → local purge → **`main`-only**
  force-push. Never `--all`/`--tags`/`--mirror`.
- **[owner, deferred]** Close the tag exposure: force-update or delete the 22 public tags
  so `git clone` + `git log <tag>` no longer reaches the old unscrubbed history.
- **[CWF backlog]** `security-review-changeset --wf-step=testing-exec misses tracked-file
  changes on re-execution` (Medium) — added to BACKLOG.md this task.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-07-18
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning/design/impl: a-task-plan.md, c-design-plan.md, d-implementation-plan.md
- Execution: e-testing-plan.md, f-implementation-exec.md, g-testing-exec.md
- Redaction tooling (`redact-rules.txt`, `scrub.sh`, `verify.sh`): **scratch only, never
  committed** — they embed the raw private data by construction (D4).
- Owner runbook: f-implementation-exec.md § Step 4 (human-only live rewrite + push).
- Follow-up: BACKLOG.md — changeset-helper re-execution coverage gap.
