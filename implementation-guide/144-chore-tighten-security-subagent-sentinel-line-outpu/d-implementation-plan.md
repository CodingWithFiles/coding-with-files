# Tighten security-subagent sentinel-line output - Implementation Plan
**Task**: 144 (chore)

## Task Reference
- **Task ID**: internal-144
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/144-tighten-security-subagent-sentinel-line-output
- **Template Version**: 2.1

## Goal
Edit the `cwf-security-reviewer-changeset` agent definition so the
sentinel line is emitted as the first output line, suppressing the
analysis-first preface that currently causes the primary classifier to
miss and the fallback to mis-classify clean reviews as `findings`.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.claude/agents/cwf-security-reviewer-changeset.md` — replace the
  "Start your response with one of three sentinel lines:" paragraph
  (lines 24–30) with stronger wording that:
  1. States explicitly that the sentinel is the **very first** output
     line — no greeting, no summary, no analysis preceding it.
  2. Names the failure mode the wording is preventing ("a verbose
     preface makes the calling SKILL fall back to a conservative
     `error`/`findings` classification, even when the diff is clean").
  3. Keeps the existing three sentinel strings unchanged
     (`findings:` / `no findings` / `error:`) — the classifier wiring
     in `.cwf/docs/skills/security-review.md` § "Exec-phase prompt
     template" is unaffected.

### Supporting Changes
None. The classifier doc, the SKILL-side prompts, and the BACKLOG
follow-up entries do not need to change as part of this task. The
BACKLOG entry is retired at the end of j-retrospective, not here.

## Implementation Steps
### Step 1: Setup
- [ ] Re-read `.claude/agents/cwf-security-reviewer-changeset.md` lines
      24–40 (sentinel paragraph + the trailing "do not paraphrase"
      sentence at line 38) so the new wording integrates cleanly with
      what remains.
- [ ] Re-read `.cwf/docs/skills/security-review.md` § "Exec-phase
      prompt template" lines 140–148 to confirm the three-tier
      classifier is the contract we must not break.

### Step 2: Core Edit
- [ ] Replace the sentinel-instruction paragraph in the agent file
      with stronger wording. Concrete draft (refine on read):
      > **Your VERY FIRST output line MUST be one of these three
      > sentinels — no greeting, no analysis, no markdown decoration
      > before it.** A preface (even a single line of context) causes
      > the calling SKILL to fall through to its conservative
      > fallback classifier and label a clean review as `findings`.
      >
      > - `findings:` followed by numbered actionable items (what is
      >   wrong, where in the diff, what to do).
      > - `no findings` if the diff is clean. May be followed by a
      >   one-line note on a subsequent line.
      > - `error:` if you cannot perform the review (state the reason
      >   on the same line).
- [ ] Leave the pattern-based-risk carve-out paragraph (lines 32–36)
      and the "do not paraphrase" sentence (line 38) untouched.

### Step 3: Testing
**See e-testing-plan.md.** Summary: at least one dogfood invocation on
a representative clean changeset must classify via the primary rule.

### Step 4: Documentation
- [ ] No README or `.cwf/docs/` text needs updating — the agent file
      is the single source of truth for the sentinel-line contract,
      and the classifier doc already refers to it.

### Step 5: Validation
- [ ] Diff review (self-review) confirms the edit touches only the
      sentinel-instruction paragraph.
- [ ] Run `cwf-security-check verify` to confirm no permission /
      integrity regressions on changed files.
- [ ] Dogfood: run the exec-phase security-review on this task's own
      changeset and capture the subagent's first non-blank line.
      Record the result in g-testing-exec.

## Code Changes
### Before
```markdown
**Start your response with one of three sentinel lines:**

- `findings:` followed by numbered actionable items (what is wrong,
  where in the diff, what to do).
- `no findings` if the diff is clean. May be followed by a one-line
  note.
- `error:` if you cannot perform the review (state the reason).
```

### After
```markdown
**Your VERY FIRST output line MUST be one of these three sentinels —
no greeting, no analysis, no markdown decoration before it.** A
preface (even a single line of context) causes the calling SKILL to
fall through to its conservative fallback classifier and label a
clean review as `findings`.

- `findings:` followed by numbered actionable items (what is wrong,
  where in the diff, what to do).
- `no findings` if the diff is clean. May be followed by a one-line
  note on a subsequent line.
- `error:` if you cannot perform the review (state the reason on the
  same line).
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Plan Review

All four `cwf-plan-reviewer-*` subagents (improvements, misalignment,
robustness, security) returned "Agent type … not found" — the agent
files at `.claude/agents/` exist but were not registered in this
Claude Code session (the `.claude/agents/` format landed in Task 143
and requires a session restart to load). Per
`.cwf/docs/skills/plan-review.md` § "Failure Handling", all-fail →
log a warning and proceed to checkpoint commit. The user has been
informed and will review the plan manually before f-exec begins.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Single in-scope edit. Out of scope (do not let creep in):
- Changing the sentinel **tokens** themselves (e.g. to `FINDINGS:` /
  `NO_FINDINGS:` / `ERROR:`). That is a separate decision; the backlog
  entry names it as an *option*, not a requirement.
- Touching the three-tier classifier in
  `.cwf/docs/skills/security-review.md`.
- Editing historical wf step files (e.g. Task 123's c-design-plan that
  quotes the old wording). Historical docs reflect the state at the
  time of writing.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
