# specify low effort level for retrospective skill - Implementation Plan
**Task**: 198 (chore)

## Task Reference
- **Task ID**: internal-198
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/198-specify-low-effort-level-for-retrospective-skill
- **Template Version**: 2.1

## Goal
Add `effort: low` to the `cwf-retrospective` SKILL.md frontmatter, mirroring the
Task 187 exec-skill change.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.claude/skills/cwf-retrospective/SKILL.md` — add `effort: low` as a top-level
  frontmatter key, immediately after `description:` (matches Task 187 layout on the
  exec skills).

### Supporting Changes
- None. The skill is **not** hash-tracked (verified absent from
  `.cwf/security/script-hashes.json`), so no `sha256` refresh is required.
- No CWF doc enumerates permitted skill frontmatter keys, and none asserts "the
  retrospective skill sets no effort" — so adding `effort` makes no doc stale
  (same finding as Task 187 Step 4). No doc edit needed.

## Implementation Steps
### Step 1: Edit frontmatter (not hash-tracked)
- [ ] Edit `.claude/skills/cwf-retrospective/SKILL.md`: insert `effort: low` between
      the `description:` line and `user-invocable: true`.

### Step 2: Validate
- [ ] `.cwf/scripts/cwf-manage validate` → expect `validate: OK` (no sha256, no
      permission drift — the skill is not in the manifest, so this is a regression
      check on the system as a whole).
- [ ] Confirm the frontmatter still parses: extract the leading `---`-delimited block
      and check `effort: low` sits at column 0 with the same indentation as sibling
      top-level keys (`name:`, `description:`). The realistic failure mode for a
      frontmatter insert is exactly a YAML break (stray indent/character), so this is
      a deterministic visual/diff check, not deferred prose. Testing phase (e/g)
      formalises it.

### Rollback
Single additive line — revert by deleting the `effort: low` line (or `git checkout --
.claude/skills/cwf-retrospective/SKILL.md`). No coupled state to unwind.

## Code Changes
### `.claude/skills/cwf-retrospective/SKILL.md` — Before
```yaml
---
name: cwf-retrospective
description: Guide user through retrospective phase
user-invocable: true
allowed-tools:
  - Read
  ...
---
```
### After
```yaml
---
name: cwf-retrospective
description: Guide user through retrospective phase
effort: low
user-invocable: true
allowed-tools:
  - Read
  ...
---
```

## Known Limitation
`cwf-manage validate` checks `sha256`/permissions only — it does NOT verify that the
Claude Code harness actually honours the `effort` key (an unrecognised frontmatter key
could be silently ignored). A clean `validate` proves integrity, not that the knob took
effect. `effort` is documented for SKILL.md frontmatter at
https://code.claude.com/docs/en/skills.md (values `low|medium|high|xhigh|max`). This is
the same limitation Task 187 recorded for the exec skills. Empirically, the harness
*ignores* unrecognised frontmatter keys rather than rejecting them: the two Task 187
exec skills have carried `effort: low` and loaded/invoked cleanly since, so a malformed
or unhonoured key degrades to a silent no-op, not a load failure.

## Test Coverage
**See e-testing-plan.md for complete test plan**

Headline checks: (1) `cwf-manage validate` clean; (2) edited frontmatter is valid YAML
and `effort: low` is a documented value; (3) the retrospective skill still parses.

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Executed exactly as planned — one additive line (`effort: low`) inserted between `description:`
and `user-invocable:`. No supporting changes needed (not hash-tracked, confirmed). Details in
f-implementation-exec.md.

## Lessons Learned
The robustness-review fold-ins (concrete YAML check, harness ignore-vs-reject note, rollback
path) all proved accurate at exec time. See j-retrospective.md.
