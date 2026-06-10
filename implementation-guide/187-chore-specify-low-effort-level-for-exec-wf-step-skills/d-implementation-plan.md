# Specify low effort level for exec wf step skills - Implementation Plan
**Task**: 187 (chore)

## Task Reference
- **Task ID**: internal-187
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/187-specify-low-effort-level-for-exec-wf-step-skills
- **Template Version**: 2.1

## Goal
Add `effort: low` frontmatter to the two exec-phase skills and `effort: high` to the
hash-tracked security-review subagent they spawn, so mechanical execution runs the
session-pinned Opus 4.8 at reduced effort while the FR4(a–e) review stays at high effort.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.claude/skills/cwf-implementation-exec/SKILL.md` — add `effort: low` to YAML frontmatter
- `.claude/skills/cwf-testing-exec/SKILL.md` — add `effort: low` to YAML frontmatter
- `.claude/agents/cwf-security-reviewer-changeset.md` — add `effort: high` to YAML frontmatter
  (hash-tracked: requires same-commit `sha256` refresh)

### Supporting Changes
- `.cwf/security/script-hashes.json` — refresh the `cwf-security-reviewer-changeset` `sha256`
  entry in the same commit as the agent edit (plan-time disclosure per
  `.cwf/docs/conventions/hash-updates.md`). The two exec SKILL.md files are NOT hash-tracked
  (verified absent from the manifest), so they need no refresh.

## Implementation Steps
### Step 1: Apply effort to exec skills (not hash-tracked)
- [ ] Edit `.claude/skills/cwf-implementation-exec/SKILL.md`: add `effort: low` as a top-level
      frontmatter key (e.g. immediately after `description:`).
- [ ] Edit `.claude/skills/cwf-testing-exec/SKILL.md`: add `effort: low` the same way.

### Step 2: Pin reviewer agent effort + refresh hash (hash-tracked)
> The `effort: high` pin is a **user-decided explicit guarantee**, not merely a hedge against
> uncertain inheritance: the FR4(a–e) review must run at high effort whatever the harness's
> skill→subagent effort-inheritance behaviour turns out to be. (Two plan reviewers note a
> subagent runs under its own frontmatter effort, so the pin is authoritative either way.)
- [ ] Edit `.claude/agents/cwf-security-reviewer-changeset.md`: add `effort: high` as a
      top-level frontmatter key (after `description:`, before/after `tools:`).
- [ ] `sha256sum .claude/agents/cwf-security-reviewer-changeset.md` to compute the new digest.
- [ ] Pre-refresh verification: `git log --oneline <last-hash-set-commit>..HEAD -- .claude/agents/cwf-security-reviewer-changeset.md`
      to confirm the only intervening change is this task's edit; document the result in f-exec.
- [ ] Update the matching `sha256` entry in `.cwf/security/script-hashes.json` (same commit).
- [ ] Restore the agent file's working perms to its RECORDED value (`0444`) after editing —
      do not leave it bumped (per the hashed-script working-perms rule).

### Step 3: Validate
- [ ] `.cwf/scripts/cwf-manage validate` → expect `validate: OK` (no sha256, no permission drift).

### Step 4: Documentation
- [ ] No user-facing docs change required — this is a behavioural knob on existing skills.
      Verified during planning: no CWF doc enumerates permitted skill/agent frontmatter keys,
      so adding `effort` makes no enumeration stale, and no doc asserts "no skill sets effort".
      No doc edit needed.

## Known Limitation
`cwf-manage validate` checks `sha256`/permissions only — it does NOT verify that the Claude
Code harness actually honours the `effort` key (an unrecognised frontmatter key could be
silently ignored). A clean `validate` therefore proves integrity, not that the knob took
effect. The only positive evidence that `effort` is honoured is an observable behaviour change
on a real exec run; the testing phase (e/g) owns that check. The `effort` key itself is
documented for SKILL.md/agent frontmatter at https://code.claude.com/docs/en/skills.md
(values `low|medium|high|xhigh|max`), verified against the live docs during this task.

## Code Changes
### cwf-implementation-exec/SKILL.md (and cwf-testing-exec/SKILL.md) — Before
```yaml
---
name: cwf-implementation-exec
description: Guide user through implementation execution phase
user-invocable: true
allowed-tools:
  - Read
  ...
---
```
### After
```yaml
---
name: cwf-implementation-exec
description: Guide user through implementation execution phase
effort: low
user-invocable: true
allowed-tools:
  - Read
  ...
---
```

### cwf-security-reviewer-changeset.md — Before
```yaml
---
name: cwf-security-reviewer-changeset
description: Review an exec-phase CWF changeset for FR4(a–e) security concerns. Ends with a machine-parseable cwf-review verdict block.
tools: Read, Grep, Glob, LSP, Bash
---
```
### After
```yaml
---
name: cwf-security-reviewer-changeset
description: Review an exec-phase CWF changeset for FR4(a–e) security concerns. Ends with a machine-parseable cwf-review verdict block.
effort: high
tools: Read, Grep, Glob, LSP, Bash
---
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

Headline checks: (1) `cwf-manage validate` clean after the hash refresh; (2) each edited
frontmatter is valid YAML and `effort` value is a documented option (`low`/`high`); (3) the
two exec skills still parse/invoke; (4) no stale "no skill sets effort" claim left in docs.

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Both the agent edit AND its `sha256` refresh land in the SAME commit — deferring the hash
refresh is the exact failure mode `hash-updates.md` exists to stop.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Executed as planned with no deviations — three frontmatter edits plus a same-commit hash
refresh. Details in f-implementation-exec.md.

## Lessons Learned
Plan review caught a vacuous verification step (grep for a never-written sentence) and the
limit of `validate` (proves integrity, not that the harness honours `effort`). Both folded in.
