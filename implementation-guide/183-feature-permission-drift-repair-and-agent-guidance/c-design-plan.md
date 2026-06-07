# Permission-drift repair and agent guidance - Design
**Task**: 183 (feature)

## Task Reference
- **Task ID**: internal-183
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/183-permission-drift-repair-and-agent-guidance
- **Template Version**: 2.1

## Goal
Decide where the fix-on-sight permission rule and its safe/unsafe boundary live, how they are
made discoverable at the point of friction, and confirm the repair reuses existing tooling —
with no new code and no validate-silencing surface.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Verified Assumptions (measure twice)
Confirmed against the codebase before designing:
- **`cwf-manage fix-security` is clamp-only** (`cwf-manage` `_apply_recorded_perms`, ~`:649-778`):
  `$want = $actual & $recorded` — clears excess bits, never raises; sha256/missing-file entries
  are reported `UNFIXABLE` and never auto-repaired; `--dry-run` supported; idempotent (no-op
  `next` guards). The plan-reviewers independently confirmed this. **Reuse — no new engine.**
- **`hash-updates.md` is NOT hash-tracked** (`grep` of `.cwf/security/script-hashes.json`: the
  only hashed `.cwf/docs` path is `cwf-agent-shared-rules.md`). Editing `hash-updates.md` needs
  **no** `sha256` refresh. It already owns "recorded permissions are a ceiling" (`:18-22`) and
  "what NOT to build" (`:47-49`) — the adjacent content this rule complements.
- **`.cwf/docs/skills/checkpoint-commit.md` is NOT hash-tracked** — free to edit, and it is the
  doc the main agent follows when `validate` surfaces drift at checkpoint time.
- **`cwf-agent-shared-rules.md` is subagent-scoped** (its own Inclusion Bar: "applies to two or
  more agent roles"). Perm-drift fix-on-sight is a **main-loop** behaviour (it fires during
  checkpoint commits, not inside plan/security reviewers). **Wrong audience — rejected.**
- **`claude-md-preamble.md` is hash-tracked and installed** into consumer `CLAUDE.md`. It is the
  only automatic consumer-**main**-agent vector, but is deliberately 3 lines. Touching it means
  a hash refresh + expanding the injected preamble. **Considered, rejected (D8).**
- **Project `CLAUDE.md` is not hash-tracked and not installed to consumers**; its `## Conventions`
  list already points to installed convention docs (Hash Updates → `.cwf/docs/conventions/hash-updates.md`).
- **`backlog-manager retire` exists** and appends a `#### <title>` under the task's
  `### Retired Backlog Items` block (FR5 mechanism).
- **Live drift already cleared**: `fix-security --dry-run` reports `0` files (planning-phase
  clamp of two Task-182 files; the Task-173 three were clamped back in Task 174). FR1 is a
  confirm-clean step; FR6's induce-drift procedure is what exercises the mechanism.

## Key Decisions
### D1 — Canonical home: extend `hash-updates.md`
- **Decision**: add one section, `## Fix permission drift on sight`, to
  `.cwf/docs/conventions/hash-updates.md`. It is the single source of truth (NFR3).
- **Rationale**: the doc already carries the ceiling/clamp model and the "what NOT to build"
  prohibition; the fix-on-sight norm is their behavioural complement. Co-locating avoids a new
  doc and the sprawl risk (R3). Installed tree ⇒ reaches consumer agents. Not hashed ⇒ no refresh.
- **Trade-off**: lengthens one doc rather than creating a focused one; acceptable — the content
  is genuinely the same subject.

### D2 — Boundary is explicit in the same section (FR3)
- **Decision**: the section states plainly: **permission clamping is the one violation an agent
  repairs on sight** (`cwf-manage fix-security`); **sha256/content drift is NOT** — it is
  surfaced, never smoothed, cross-referencing the existing "what NOT to build" section (no
  "recompute the hash" instruction). It quotes the exact command byte-for-byte (NFR2/AC2).
- **Rationale**: keeps the safe/unsafe line adjacent to the prohibition it depends on; one read,
  no cross-doc hop for the critical distinction.

### D3 — Persistence semantics by cross-reference (FR3/AC3)
- **Decision**: the section states permission drift is a working-tree property git does not
  record (modes tracked as `100755`/`100644`) so the repair leaves `git status` clean and is not
  a committable diff; it **cross-references** the existing "recorded permissions are a ceiling"
  section rather than re-deriving the mode model.
- **Rationale**: avoids duplicating the mode explanation; satisfies "do not promise a committable
  fix" (R2).

### D4 — Negative example drawn from real incidents (FR2/AC2)
- **Decision**: include ≥1 concrete "don't do this" example: the Task-182
  `cwf-claude-settings-merge` defer-as-"separate backlog item", and the Task-174 clamp deferred
  to a backlog item. Phrased by **rationalisation and incident number** (e.g. "deferred as a
  separate backlog item"), never by task-author identity — **no personal names** (per convention).
- **Rationale**: the rule must name the exact rationalisation it forbids, not gesture at it.

### D5 — Reinforce at the friction point: `checkpoint-commit.md` (FR2 discoverability)
- **Decision**: add a short fix-on-sight note to `checkpoint-commit.md` reachable on **both**
  the doc's paths — the "Script (primary method)" section (near the line stating the helper runs
  `validate`, ~`:16`) and the "Manual Procedure" validate step (`:46-50`, currently only the
  generic "fix them before proceeding"). The note: permission violations are fix-on-sight via
  `cwf-manage fix-security` (do not defer); sha256 violations are surface-not-smooth — each with
  a cross-reference to the `hash-updates.md` section. No prose duplication beyond the one-line norm.
- **Rationale**: this is where the main agent actually sees drift (the checkpoint helper prints
  violations "non-fatal"); a pointer here is higher-salience than the convention index alone. A
  script-path agent does not read the manual section, so the note must appear on both paths.
  Directly targets the user's "stop the most common deferral response" goal.

### D6 — Index pointer in project `CLAUDE.md` (FR2 discoverability, this repo)
- **Decision**: extend the existing `## Conventions` → "Hash Updates" entry blurb to mention the
  fix-on-sight rule (cross-reference, not new prose).
- **Rationale**: the dev-repo main agent (the audience that failed this session) indexes
  conventions here; keep it a pointer to the single source (NFR3).

### D7 — Repair path & backlog (FR1/FR4/FR5)
- **Decision**: repair is the existing clamp-only `fix-security`; **no** new `cwf-manage`
  subcommand/flag (FR4). Retire the Task-173 BACKLOG item via `backlog-manager retire --task=183`.
- **CHANGELOG ordering (reconciles AC5)**: `retire` is self-bootstrapping and re-run-safe — if
  the `## Task 183:` CHANGELOG section is absent it calls `bootstrap_changelog_entry` to create it
  (with a placeholder `Status`/`Impact`), and a duplicate block is deduped. Ordering is therefore
  cosmetic, not a correctness prerequisite: prefer running `retire` at retrospective time *after*
  the retrospective has authored the `## Task 183:` section, purely to avoid the placeholder
  Impact line — but it is not blocked if run earlier.

### D8 — Rejected: editing `claude-md-preamble.md`
- **Decision**: do **not** expand the hashed, installed CLAUDE.md preamble in this task.
- **Rationale**: minimality/reversibility — the convention doc (installed) + checkpoint-commit
  note already reach consumer agents through the docs they read; expanding the deliberately-terse
  injected preamble is a heavier, hash-bearing change. Recorded as a future option if deferral
  recurs in consumer repos (forward note in i-maintenance).

## System Design
### Component Overview
- **`hash-updates.md`** — gains the canonical fix-on-sight section (rule + boundary + persistence
  + example). Single source of truth.
- **`checkpoint-commit.md`** — gains a one-line fix-on-sight note at the validate step (pointer).
- **project `CLAUDE.md`** — Hash Updates blurb extended (pointer).
- **BACKLOG.md / CHANGELOG.md** — Task-173 item retired (at retrospective).
- **No script/code/agent/rule/hash changes.**

### Data Flow (the behaviour the design enables)
1. Agent runs a checkpoint commit → helper runs `validate` → prints a permission violation +
   `run: cwf-manage fix-security`.
2. Agent (following `checkpoint-commit.md`'s note) recognises this as fix-on-sight → runs
   `cwf-manage fix-security` → drift clamped → `validate: OK`, `git status` clean.
3. If instead `validate` reports a **sha256** violation, the same docs route the agent to
   **surface, not smooth** (hash-updates "what NOT to build") — never recompute the hash.

**Recovery (FR6 induce-drift step)**: FR6 deliberately induces a security-relevant state by
`chmod 0700` on a recorded-`0500` tracked script. If the procedure is interrupted between the
`chmod` and the repair, the tree is left drifted — `validate` keeps flagging it (the signal is
not lost), and recovery is simply re-running the idempotent `cwf-manage fix-security`. The
induced state is local and reversible; nothing to clean up beyond the clamp.

## Interface Design
- **No new interfaces.** The only command surface is the existing
  `cwf-manage fix-security [--dry-run]` and `cwf-manage validate`, quoted verbatim in the docs.

## Constraints
- No new validate-silencing surface (FR4 / hash-updates "what NOT to build").
- British spelling; no superlatives; no personal names in committed CWF docs.
- This task edits only non-hash-tracked files → no `script-hashes.json` refresh (stated decision).
- CWF self-hosted workflow.

## Decomposition Check
Unchanged: 0 signals. One convention section + two pointers + a backlog retire. No decomposition.

## Validation
- [ ] D1 home choice (`hash-updates.md`) confirmed non-hashed and installed
- [ ] D2 boundary + D3 persistence stated in one section; exact command quoted (AC2/AC3)
- [ ] D4 negative example present, role-phrased (no names)
- [ ] D5/D6 pointers added at friction point + index, cross-referencing the single source
- [ ] D7 reuse-only repair; retire ordering reconciled (AC5)
- [ ] D8 preamble-edit rejection recorded with rationale

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
