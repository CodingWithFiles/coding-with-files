# Fix Task 147 hash drift, clarify hash rule - Implementation Plan
**Task**: 149 (chore)

## Task Reference
- **Task ID**: internal-149
- **Branch**: chore/149-fix-task-147-hash-drift-clarify-hash-rule
- **Baseline Commit**: 95c32d8f092dc7435347fd9750a08d3728df2c08
- **Template Version**: 2.1

## Goal
Refresh the two drifted hashes (`CWF::Backlog`, `backlog-manager`) and codify the in-task-hash-update rule in a single convention doc that the two relevant skill instruction sets, the project CLAUDE.md index, and `design-alignment.md` all link to.

## Files to Modify

### Hash table (target of the refresh)
- `.cwf/security/script-hashes.json` — two sha256 fields updated:
  - `CWF::Backlog.sha256` (line 60): `8c4bd187…ebdb85c` → `375ce811…49b7e7`
  - `backlog-manager.sha256` (line 197): `1b360005…62e0b6b5c3` → `f9045c72…931fce9e`

### Skill instructions (link to the convention doc)
- `.claude/skills/cwf-implementation-exec/SKILL.md` — append a Gotcha entry pointing at the convention doc.
- `.claude/skills/cwf-retrospective/SKILL.md` — append a Gotcha entry pointing at the convention doc.

### Convention doc (canonical source of truth)
- `.cwf/docs/conventions/hash-updates.md` (NEW) — the rule, the carve-out, the verification pattern, the Task 147 historical example. Placed under `.cwf/docs/conventions/` (not `docs/conventions/`) because the consumers are runtime CWF skills shipped under `.claude/skills/` — matching the precedent of `tmp-paths.md` and `subagent-tool-selection.md`.

### Index / cross-reference
- `CLAUDE.md` (project root) — add an entry under `## Conventions` registering the new doc, in the same style as the existing Perl / tmp-paths / design-alignment entries.
- `docs/conventions/design-alignment.md` — append a 1-line cross-reference from the existing `script-hashes.json`-related guidance to the new doc.

## Supporting Changes
Per `.cwf/docs/conventions/hash-updates.md` §Plan-time disclosure (the rule this task codifies), any plan that modifies a hashed path lists `.cwf/security/script-hashes.json` here. This plan modifies it *as the deliverable*; no separate supporting refresh.

`.claude/skills/`, `.cwf/docs/conventions/`, `CLAUDE.md`, and `docs/conventions/` are confirmed not in `.cwf/security/script-hashes.json` — no supporting hash refreshes.

## Implementation Steps

### Step 1 — Per-file pre-refresh diff verification
Goal: prove the only modifications to each file since *its own* hash entry was last set come from Task 147 commit `246e6c4`. Per-file baselines differ:
- `CWF::Backlog.pm`: last hash refresh in `4f47494` (Task 132).
- `backlog-manager`: last hash refresh in `f833bbf` (Task 140).

Actions:
- [ ] `git log --oneline 4f47494..HEAD -- .cwf/lib/CWF/Backlog.pm` — expect exactly one line: `246e6c4 Task 147: ...`. STOP if anything else.
- [ ] `git log --oneline f833bbf..HEAD -- .cwf/scripts/command-helpers/backlog-manager` — expect exactly one line: `246e6c4 Task 147: ...`. STOP if anything else.
- [ ] Record both verification commands and outputs verbatim in f-implementation-exec Step 1.

(The original baseline `7500aef` (Task 137) used in plan review was a false unification — Tasks 139 and 140 each touched `backlog-manager` but properly refreshed its hash in-task. The plan-review process surfaced this; the convention doc encodes per-file baselines as the rule.)

### Step 2 — Recompute hashes
- [ ] `sha256sum .cwf/lib/CWF/Backlog.pm` — expect `375ce811ecb4f507e304075c96bd99393f75a93ccc09085ece1124b16849b7e7`.
- [ ] `sha256sum .cwf/scripts/command-helpers/backlog-manager` — expect `f9045c722c469eaacb2afeeb60d965fb0d43a35d892fc7239f6c8d35931fce9e`.
- [ ] If either differs from the validate "Actual" value, STOP — the working tree has been modified since the last validate; investigate.

### Step 3 — Refresh the two hash entries in-diff
Edit `.cwf/security/script-hashes.json` (two single-field replacements):
- [ ] `CWF::Backlog.sha256`: `8c4bd187…ebdb85c` → `375ce811…49b7e7`.
- [ ] `backlog-manager.sha256`: `1b360005…62e0b6b5c3` → `f9045c72…931fce9e`.

### Step 4 — Write the canonical convention doc
Create `.cwf/docs/conventions/hash-updates.md` with these sections:

- **Convention**: hash refreshes happen in the same task — and the same commit — as the underlying file modification.
- **Why**: each hash entry signs the file at the moment a maintainer last reviewed it. A deferred refresh by an unrelated task means signature was never matched to intent. Friction from `cwf-manage validate` IS the integrity check working.
- **How (mechanical, in order)**:
  1. Make the source edit.
  2. `sha256sum <path>` to compute the new digest.
  3. Edit the matching entry in `.cwf/security/script-hashes.json` in the same commit.
  4. `cwf-manage validate` to confirm clean.
- **Plan-time disclosure**: any implementation plan whose Files-to-Modify list includes a hashed path MUST list `.cwf/security/script-hashes.json` as a Supporting Change.
- **Pre-refresh verification**: when refreshing a hash, first verify with `git log --oneline <last-hash-set-commit>..HEAD -- <path>` that the intervening commits are the known, intended modifications — **per file**, not assumed-shared baselines. Use `--` to separate revision range from path; if scripting the verification, use `-z` per `docs/conventions/git-path-output.md`.
- **Carve-out** (narrow, invariant-guarded): a task whose explicit deliverable IS a hash-table change (fixing prior drift, like Task 149) doesn't need to "match" an unrelated source edit. The carve-out is **only safe** when ALL of the following hold:
  1. The dedicated task names every drifted entry it intends to refresh in its plan.
  2. The dedicated task verifies per-file pre-refresh via `git log <last-hash-set-commit>..HEAD -- <path>` and documents the result.
  3. The dedicated task contains no other source edits to the drifted files.
  4. The originating commit(s) of the drift are explicitly named in the task.
  Without all four, the carve-out does not apply; "dedicated hash-fix task" is not a self-applied label.
- **What NOT to build (principle, not enumeration)**: any tool, flag, or mode whose effect is to silence `cwf-manage validate` output without first surfacing it to a human is forbidden. Concrete anti-patterns this covers: a `recompute-hashes` helper; an auto-update hook; a `validate --fix` mode; a `validate --ignore=<path>` flag; a `validate --baseline=HEAD` flag. New surface that smooths a tampering signal into a no-op falls under the same prohibition even when not enumerated here.
- **Historical example**: Task 147 (`246e6c4`) added two CWF::Backlog helpers + 4 cmd_retire lines but did not refresh the two hash entries; Task 148 discovered the drift mid-flow but, correctly, did not absorb it; Task 149 refreshes the hashes properly. Tasks 139 (`d3d7b86`) and 140 (`f833bbf`) are the positive control — both touched `backlog-manager` and refreshed its hash in the same commit, per their commit messages.

Target length: ~60-70 lines. Declarative criteria framing.

### Step 5 — Wire the rule into cwf-implementation-exec
Edit `.claude/skills/cwf-implementation-exec/SKILL.md` using string anchors (not line numbers):
- [ ] `old_string`: existing Gotcha 2 final sentence + blank line + `## Scope & Boundaries` heading line.
- [ ] `new_string`: same, with a new Gotcha 3 inserted before the blank line.
- Gotcha 3 text:
  ```
  3. **Editing a hash-tracked file requires an in-task hash refresh**: any source change to a file listed in `.cwf/security/script-hashes.json` (typically paths under `.cwf/scripts/`, `.cwf/lib/CWF/`, `.claude/agents/`, `.claude/hooks/`, `.claude/rules/`) MUST refresh the matching sha256 entry in the same commit. See `.cwf/docs/conventions/hash-updates.md`. Deferring the refresh — even to "the next task" or retrospective — defeats the integrity check.
  ```

### Step 6 — Wire the rule into cwf-retrospective
Edit `.claude/skills/cwf-retrospective/SKILL.md` using string anchors:
- [ ] `old_string`: existing Gotcha 3 final sentence + blank line + `## Scope & Boundaries` heading line.
- [ ] `new_string`: same, with a new Gotcha 4 inserted before the blank line.
- Gotcha 4 text:
  ```
  4. **Do not absorb hash drift at retrospective time**: if `cwf-manage validate` reports sha256 drift, the fix belongs in the task that originally modified the file, in-diff (see `.cwf/docs/conventions/hash-updates.md`). Recomputing a hash during retrospective to clear validate output silently signs whatever shape the file has now. Surface the drift instead; either re-open the originating task or schedule a dedicated follow-up task (the Task 149 pattern).
  ```

### Step 7 — Register convention in CLAUDE.md
Edit `CLAUDE.md` (project root). Append to the `## Conventions` section a new entry in the existing style (subsection heading + 2-4 bullet summary + `See <path>` line). Choose a position next to `Tmp Paths` since both live under `.cwf/docs/conventions/` and are consumed by skills.

### Step 8 — Add cross-reference from design-alignment.md
Edit `docs/conventions/design-alignment.md`. Locate the existing guidance that names `script-hashes.json` (per misalignment-reviewer note: §3.3) and append a single bullet: `When a rename or edit touches a hashed file, refresh the entry in the same commit — see ` `.cwf/docs/conventions/hash-updates.md` `.`

### Step 9 — Validate (with explicit STOP condition for unexpected drift)
- [ ] `.cwf/scripts/cwf-manage validate` should report ONLY the misalignment-agent permission violation. Specifically: zero `[SECURITY]` lines naming `CWF/Backlog.pm` or `backlog-manager` sha256.
- [ ] If validate reports ANY sha256 drift beyond the misalignment-agent permission issue, DO NOT refresh further entries in this task — surface the unexpected drift and escalate to a new dedicated task per the carve-out invariants (Step 4). Refreshing unexpected entries here would itself violate the rule this task codifies.

## Validation Criteria
- `cwf-manage validate` reports zero `[SECURITY]` lines for `CWF/Backlog.pm` or `backlog-manager` sha256.
- `grep -F '.cwf/docs/conventions/hash-updates.md' .claude/skills/cwf-implementation-exec/SKILL.md` returns ≥1 match.
- `grep -F '.cwf/docs/conventions/hash-updates.md' .claude/skills/cwf-retrospective/SKILL.md` returns ≥1 match.
- `grep -F 'hash-updates' CLAUDE.md` returns ≥1 match (registry entry present).
- `grep -F 'hash-updates' docs/conventions/design-alignment.md` returns ≥1 match (cross-reference present).
- `grep -F '.cwf/security/script-hashes.json' .cwf/docs/conventions/hash-updates.md` returns ≥1 match (the doc names the canonical hash table).

## Test Coverage
Detailed test cases live in e-testing-plan.md. Targets:
- Functional: per-file pre-refresh verification passes (Step 1); post-refresh validate clean for the two entries (Step 9).
- Reference integrity: greppable links from both skills, CLAUDE.md, and design-alignment.md to the convention doc.
- Document integrity: convention doc references the hash table by canonical path; no dangling links.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 149
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
