# Fix normalise wrapped-field stranding - Plan
**Task**: 208 (bugfix)

## Task Reference
- **Task ID**: internal-208
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/208-fix-normalise-wrapped-field-stranding
- **Baseline Commit**: c12b6c97d0ab6d47cfb6f44b91bc0ecd1639e87b
- **Template Version**: 2.1

## Goal
Make `backlog-manager normalise` preserve hard-wrapped legacy `**Field**:` metadata values intact, and close the AC5d guard gap that let the corruption pass silently.

## Success Criteria
- [ ] A legacy `**Field**: value` whose value wraps across ≥2 physical lines normalises to a single `### Field: <full value>` heading with all continuation text folded into the value (no orphaned prose in the body).
- [ ] AC5d compares per-entry **metadata-value** bytes pre/post (not just whole-entry bytes), so a misplace-not-delete regression trips the gate instead of passing.
- [ ] A regression fixture containing a hard-wrapped legacy field is added and asserts both the correct fold and the tightened guard; full `t/` suite passes.
- [ ] `normalise` remains idempotent on already-canonical input (re-run writes nothing) and single-line fields are unaffected.

## Original Estimate
**Effort**: <1 day
**Complexity**: Low
**Dependencies**: None — change is localised to `backlog-manager` (`_canonicalise_entry_inplace`, `_entry_byte_count`/AC5d) plus its test file.

## Major Milestones
1. **Fold continuations**: `_canonicalise_entry_inplace` accumulates continuation lines into the field value until the next `**Field**:`, blank line, or `---` separator.
2. **Tighten AC5d**: add a metadata-value byte comparison so misplaced-not-deleted content fails the gate.
3. **Regression coverage**: hard-wrapped-field fixture proving both the fold and the guard; suite green.

## Risk Assessment
### High Priority Risks
- **Continuation-fold boundary errors**: greedily folding could swallow a following field, a blank-line break, or a `---` separator that should terminate the value.
  - **Mitigation**: explicit terminator set (next `**Field**:` / blank / `---` / end-of-entry); fixture covers each boundary; idempotency re-run asserts no drift.

### Medium Priority Risks
- **AC5d false positives**: a metadata-value byte check could trip on legitimate reflow (e.g. trimmed bold markers, collapsed inter-line whitespace).
  - **Mitigation**: compare semantic value bytes (whitespace-normalised), keep the ≥90% tolerance band, and validate against the existing canonical corpus which must still pass.

## Dependencies
- None external. Self-contained within the CWF repo (helper + `t/`).

## Constraints
- Perl core-modules only; `use utf8;`; `#!/usr/bin/env perl` conventions.
- Must stay idempotent and backward-compatible with already-canonical files.
- Hash refresh to `script-hashes.json` happens in the same commit as the helper edit.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — sub-day fix.
- [ ] **People**: Does this need >2 people working on different parts? No.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — one helper, one guard, one fixture.
- [ ] **Risk**: Are there high-risk components that need isolation? No.
- [ ] **Independence**: Can parts be worked on separately? No — fold + guard + test are one cohesive change.

No signals triggered → single task, no subtasks.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Delivered within the <1-day estimate (~28 min wall-clock). SC#1, SC#3, SC#4 met. SC#2
(AC5d metadata-value byte guard) superseded by KD4 (user-approved): the guard is a no-op
for this bug class (legacy fields carry an empty `metadata` array pre-normalise, so the
pre/post comparison is always 0→N), so it was dropped rather than implemented as dead code.
The regression fixture is the real safety net. Full suite 869 tests green; `validate` OK.

## Lessons Learned
Validate that a proposed guard can actually fire against the real data shape before writing
it into success criteria — SC#2 was specified before its no-op nature was understood. See
j-retrospective.md for the full analysis.
