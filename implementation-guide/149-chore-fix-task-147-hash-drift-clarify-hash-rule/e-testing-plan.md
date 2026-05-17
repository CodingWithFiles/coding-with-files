# Fix Task 147 hash drift, clarify hash rule - Testing Plan
**Task**: 149 (chore)

## Task Reference
- **Task ID**: internal-149
- **Branch**: chore/149-fix-task-147-hash-drift-clarify-hash-rule
- **Baseline Commit**: 95c32d8f092dc7435347fd9750a08d3728df2c08
- **Template Version**: 2.1

## Goal
Define the verification steps that prove (a) the hash refresh is bounded to Task 147's intended modifications and (b) the rule is wired into every advertised consumption point.

## Test Strategy

### Test Levels
- **Functional integrity**: `cwf-manage validate` output before/after.
- **Reference integrity**: greppable links from each advertised consumer to the convention doc.
- **Document integrity**: convention doc references the canonical hash table by exact path.
- **Pre-refresh provenance**: `git log` per file shows only intended commits in the drift window.

No unit tests; the deliverable is config + docs.

### Test Coverage Targets
- **100%** of the d-plan Validation Criteria covered by an executable test case.
- **100%** of advertised consumption points (cwf-implementation-exec SKILL, cwf-retrospective SKILL, CLAUDE.md, design-alignment.md) covered.

## Test Cases

### Functional Test Cases (pre-refresh provenance, Step 1 of d-plan)

- **TC-1**: Backlog.pm drift is single-commit and attributable to Task 147.
  - **Given**: working tree at `chore/149-…` HEAD, `Backlog.pm` hash last set at `4f47494` (Task 132).
  - **When**: `git log --oneline 4f47494..HEAD -- .cwf/lib/CWF/Backlog.pm`.
  - **Then**: stdout is exactly one line; that line's SHA prefix is `246e6c4`; that line mentions Task 147.

- **TC-2**: backlog-manager drift is single-commit and attributable to Task 147.
  - **Given**: working tree at HEAD, `backlog-manager` hash last set at `f833bbf` (Task 140).
  - **When**: `git log --oneline f833bbf..HEAD -- .cwf/scripts/command-helpers/backlog-manager`.
  - **Then**: stdout is exactly one line; SHA prefix `246e6c4`; line mentions Task 147.

### Functional Test Cases (post-refresh integrity, Step 9 of d-plan)

- **TC-3**: validate clears the two Task 147 entries.
  - **Given**: hash refresh complete (d-plan Step 3 executed).
  - **When**: `.cwf/scripts/cwf-manage validate` runs.
  - **Then**: stdout contains zero lines matching `\[SECURITY\] .*CWF/Backlog\.pm` and zero lines matching `\[SECURITY\] .*backlog-manager`. The misalignment-agent permission violation is the only remaining violation (out of scope; flagged in a-plan §Constraints).

- **TC-4**: no unexpected drift was introduced or absorbed.
  - **Given**: post-refresh state.
  - **When**: `.cwf/scripts/cwf-manage validate` runs.
  - **Then**: total `[SECURITY]` line count is exactly 1 (the misalignment-agent permission entry). Any additional drift triggers the STOP rule in d-plan Step 9.

### Reference-Integrity Test Cases (Step 5-8 wiring)

- **TC-5**: cwf-implementation-exec links the convention doc.
  - **Given**: edit per d-plan Step 5 applied.
  - **When**: `grep -F '.cwf/docs/conventions/hash-updates.md' .claude/skills/cwf-implementation-exec/SKILL.md`.
  - **Then**: ≥1 match, within the `## Gotchas` section.

- **TC-6**: cwf-retrospective links the convention doc.
  - **Given**: edit per d-plan Step 6 applied.
  - **When**: `grep -F '.cwf/docs/conventions/hash-updates.md' .claude/skills/cwf-retrospective/SKILL.md`.
  - **Then**: ≥1 match, within the `## Gotchas` section.

- **TC-7**: CLAUDE.md registers the new convention.
  - **Given**: edit per d-plan Step 7 applied.
  - **When**: `grep -nF 'hash-updates' CLAUDE.md`.
  - **Then**: ≥1 match, in the `## Conventions` section (≤ 30 lines from a heading matching `## Conventions`).

- **TC-8**: design-alignment.md cross-references the new doc.
  - **Given**: edit per d-plan Step 8 applied.
  - **When**: `grep -F 'hash-updates' docs/conventions/design-alignment.md`.
  - **Then**: ≥1 match.

### Document-Integrity Test Cases (Step 4 deliverable)

- **TC-9**: convention doc names the canonical hash table.
  - **Given**: file `.cwf/docs/conventions/hash-updates.md` exists.
  - **When**: `grep -F '.cwf/security/script-hashes.json' .cwf/docs/conventions/hash-updates.md`.
  - **Then**: ≥1 match.

- **TC-10**: convention doc contains all four required content sections.
  - **Given**: file exists.
  - **When**: greps for the headings/bullets required by d-plan Step 4.
  - **Then**: doc contains the strings (case-insensitive):
    - "Convention"
    - "Plan-time disclosure"
    - "Pre-refresh verification"
    - "Carve-out"
    - "What NOT to build"
    - "Historical example"
    - "Task 147"

- **TC-11**: convention doc encodes the four carve-out invariants.
  - **Given**: file exists.
  - **When**: read the `Carve-out` section.
  - **Then**: section enumerates: (1) named drifted entries, (2) per-file pre-refresh verification, (3) no other source edits, (4) originating commit(s) named. Test pass condition: all four numerals/bullets present.

### Non-Functional Test Cases

- **TC-12**: convention doc length is within budget.
  - **Given**: file exists.
  - **When**: `wc -l .cwf/docs/conventions/hash-updates.md`.
  - **Then**: ≤ 80 lines (target ~60-70 per d-plan).

- **TC-13**: gotcha-insert anchor robustness (no line-number assumption).
  - **Given**: d-plan Steps 5/6 specify string-anchor Edit.
  - **When**: read the diff for each SKILL.md edit.
  - **Then**: the Edit's `old_string` contains an `## Scope & Boundaries` heading (or the prior Gotcha's terminating context), not a numeric line reference.

## Test Environment

- **Setup**: working tree at `chore/149-…` branch HEAD; `cwf-manage` on PATH; standard Perl 5 + `sha256sum`.
- **No mocks or fixtures**: every TC operates on real working-tree files; no DB, no network.
- **Determinism**: all TCs are pure file inspection; results stable across runs given a fixed commit.

## Validation Criteria
- [ ] TC-1 through TC-13 all PASS.
- [ ] Zero `[SECURITY]` lines from `cwf-manage validate` reference `CWF/Backlog.pm` or `backlog-manager` sha256.
- [ ] The four advertised consumers (two SKILLs, CLAUDE.md, design-alignment.md) each contain a greppable link to `.cwf/docs/conventions/hash-updates.md`.

## Decomposition Check
- [ ] **Time**: testing pass is ~15 min. No.
- [ ] **People**: solo. No.
- [ ] **Complexity**: 13 small grep/log/wc tests. No.
- [ ] **Risk**: low. No.
- [ ] **Independence**: TC-1/TC-2 are gating, others are independent — but the suite is short enough to run as one batch. No.

No decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 149
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
