# Tighten security-subagent sentinel-line output - Testing Plan
**Task**: 144 (chore)

## Task Reference
- **Task ID**: internal-144
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/144-tighten-security-subagent-sentinel-line-output
- **Template Version**: 2.1

## Goal
Verify that the tightened sentinel-line instruction in
`.claude/agents/cwf-security-reviewer-changeset.md` (a) parses
correctly as agent frontmatter + markdown, (b) preserves the
classifier contract (three sentinel strings unchanged), and
(c) actually changes subagent behaviour: at least one dogfood run
classifies via the primary rule, not the fallback.

## Test Strategy
### Test Levels
- **Static check**: structural and string-level checks against the
  edited agent file (no test framework — `grep`-based assertions,
  consistent with how Task 143 verified the agent format).
- **Dogfood (system) test**: invoke the agent on a real changeset
  (this task's own diff) and inspect the first non-blank line of the
  response. This is the only way to validate behavioural change; unit
  testing prompt wording is not meaningful.
- **No unit tests, no integration tests**: there is no Perl/library
  change. Adding scaffolding would be cargo-culting.

### Test Coverage Targets
- **Static checks**: 100% of the static assertions below must pass.
- **Dogfood**: a single positive observation is sufficient evidence
  the wording change has the intended effect for this task's
  retrospective. We are not claiming a quantitative reduction in
  preface-rate — that would require the methodology described in the
  separate backlog entry "Quantitatively justify the security-review
  subagent line-count cap"-style follow-up, which is out of scope.

## Test Cases
### Functional Test Cases

- **TC-1 (static)**: Frontmatter integrity.
  - **Given**: edited `.claude/agents/cwf-security-reviewer-changeset.md`.
  - **When**: `head -5` is read.
  - **Then**: lines 1–5 are the original frontmatter block (`---`,
    `name:`, `description:`, `allowed-tools:`, `---`) unchanged.

- **TC-2 (static)**: Sentinel tokens preserved verbatim.
  - **Given**: the edited file.
  - **When**: `grep -E '^- \`(findings:|no findings|error:)\`' .claude/agents/cwf-security-reviewer-changeset.md`.
  - **Then**: exactly three matches, one per token, spelled exactly
    `findings:`, `no findings`, `error:` — the classifier in
    `.cwf/docs/skills/security-review.md` § "Exec-phase prompt
    template" depends on this and must not be relaxed by this task.

- **TC-3 (static)**: New wording is present.
  - **Given**: the edited file.
  - **When**: `grep -i 'VERY FIRST' .claude/agents/cwf-security-reviewer-changeset.md`.
  - **Then**: at least one match, on a line that also mentions
    "sentinel" (case-insensitive). Confirms the strengthening
    actually landed.

- **TC-4 (static)**: Old loose wording is gone.
  - **Given**: the edited file.
  - **When**: `grep -i 'Start your response with one of three sentinel lines' .claude/agents/cwf-security-reviewer-changeset.md`.
  - **Then**: zero matches.

- **TC-5 (static)**: Pattern-based-risk carve-out paragraph
  preserved.
  - **Given**: the edited file.
  - **When**: `grep -F 'safe here because' .claude/agents/cwf-security-reviewer-changeset.md`.
  - **Then**: at least one match. The carve-out paragraph is
    explicitly out of scope per d- and must survive.

- **TC-6 (static)**: "do not paraphrase" sentence preserved.
  - **Given**: the edited file.
  - **When**: `grep -F 'do not\n  paraphrase' .claude/agents/cwf-security-reviewer-changeset.md`
    (or, equivalently, a multiline-aware `grep -Pzo` for
    `do not[\s\n]+paraphrase`).
  - **Then**: at least one match. The sentence underpins the SKILL's
    parsing assumption.

- **TC-7 (dogfood)**: Primary-rule classification on a clean
  changeset.
  - **Given**: this task's own working-tree changeset at the point of
    g-testing-exec (i.e. all edits from a/d/e/f).
  - **When**: the exec-phase security-review SKILL is invoked
    (`/cwf-testing-exec 144` performs this as part of its standard
    procedure) — or, if the agent is still unregistered in the
    session, the dogfood is deferred and recorded as a known limit.
  - **Then**: the agent's first non-blank output line begins with
    one of the three sentinel strings, and the SKILL classifies via
    the **primary** rule (not the numbered-list fallback, not the
    conservative-default error). The verbatim subagent output and
    the recorded `**State**:` line are appended to g-testing-exec.

### Non-Functional Test Cases
- **Integrity**: `cwf-security-check verify` reports no permission or
  SHA mismatches on the edited file.
- **No regressions**: `git diff --stat` on the task branch (excluding
  `implementation-guide/144-*`) shows a single file changed
  (`.claude/agents/cwf-security-reviewer-changeset.md`) with a small
  line delta (estimate: ±10–20 lines).

## Test Environment
### Setup Requirements
- Static checks: no environment — just `grep` against the edited
  file in the working tree.
- Dogfood: requires a Claude Code session where
  `cwf-security-reviewer-changeset` is registered. If the agent file
  was only just installed and the session has not been restarted,
  the dogfood test is deferred and the limitation is logged in
  g-testing-exec.

### Automation
- None. All checks are one-line greps run via the Bash tool in
  g-testing-exec, and the dogfood is the standard
  `/cwf-testing-exec` flow.

## Validation Criteria
- [ ] TC-1 through TC-6 (static) all pass.
- [ ] TC-7 (dogfood) either passes, or is deferred with a logged
      reason ("agent not registered in this session"). A deferred
      TC-7 is acceptable for closing this task because the
      classifier safety net is unchanged — worst case, the wording
      change is a no-op until the next session restart.
- [ ] `cwf-security-check verify` clean.
- [ ] No unexpected files changed.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
