# Session hygiene guidance from past deviations - Testing Plan
**Task**: 150 (discovery)

## Task Reference
- **Task ID**: internal-150
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/150-session-hygiene-guidance-from-past-deviations
- **Template Version**: 2.1

## Goal
Define test cases that verify every FR / NFR / AC from b-requirements-plan against the f-exec output. Documentation-only deliverable; tests are grep / `wc -l` / helper-exit-code gates plus one judgement gate.

## Test Strategy
- **Test level**: integration only — the unit is the produced doc + its CLAUDE.md wiring. There is no executable code under test.
- **Approach**: Mechanical (grep / `wc -l` / helper exit code) where the AC pass condition is structural. One manual judgement gate (TC-13) for NFR4.3 defender-framing, acknowledged in d-plan.
- **Pass-condition semantics**: every TC pass condition specifies partial-match vs. exact-line and substring-vs-regex explicitly (carrying forward the Task 149 retrospective lesson — "TC pass conditions should specify partial-match vs. exact-line semantics").

## Test Environment
- Repository working tree on `discovery/150-session-hygiene-guidance-from-past-deviations` after f-exec completes (Steps 1–6 of d-implementation-plan executed).
- Validate baseline file at `/tmp/-home-matt-repo-coding-with-files-task-150/validate-baseline.txt` written by f-exec Step 1 (per `.cwf/docs/conventions/tmp-paths.md`).
- POSIX shell with `grep`, `wc`, `git`, `diff` available.

## Coverage Targets
- **100% requirement coverage**: every FR / NFR / AC from b-requirements-plan has at least one TC.
- **100% validation-gate coverage**: every Step 5 + Step 6 gate in d-implementation-plan has a corresponding TC.

## Test Cases

### TC-1 — Line budget (NFR2.1)
- **Given**: f-exec produced `.cwf/docs/conventions/session-hygiene.md`.
- **When**: `wc -l .cwf/docs/conventions/session-hygiene.md`.
- **Then**: line count ≤ 60. Pass condition: integer parsed from the first column is ≤ 60.

### TC-2 — `/clear` triggering conditions count (FR1.AC1.1)
- **Given**: produced doc.
- **When**: extract the section between `## When to /clear` and the next `## ` heading; count lines starting with `- ` or `* ` (markdown bullets at column 0).
- **Then**: bullet count ≥ 3. Pass condition: `grep -cE '^[-*] ' <section-extract>` ≥ 3.

### TC-3 — `/clear` conditions cite audit patterns (FR1.AC1.2)
- **Given**: same section extract as TC-2.
- **When**: count bullets that contain a reference matching `P[1-5]` (the audit-table pattern IDs).
- **Then**: ≥ 2 of the ≥ 3 bullets cite a P-number. Pass condition: `grep -cE 'P[1-5]' <section-extract>` ≥ 2.

### TC-4 — `/compact` vs auto-compaction distinction (FR2.AC2.1)
- **Given**: produced doc.
- **When**: grep for both `/compact` and one of {`auto-compact`, `auto compaction`, `auto-compaction`} in the §"When to /compact" section.
- **Then**: both terms present AND under separate bullet/sub-heading. Pass condition (mechanical): `grep -cE '/compact' <section-extract>` ≥ 1 AND `grep -ciE 'auto[ -]compact' <section-extract>` ≥ 1. (Distinct-bullet check is a manual visual triage if the regex passes.)

### TC-5 — Preservation list includes "standing security rules" (FR2.AC2.2)
- **Given**: produced doc.
- **When**: search §"When to /compact" preservation list for the literal substring `standing security rules` (case-insensitive).
- **Then**: ≥ 1 match. Pass condition: `grep -ciF 'standing security rules' .cwf/docs/conventions/session-hygiene.md` ≥ 1. AND total preservation-list bullets ≥ 3 (mechanical: bullet count under the preservation sub-block).

### TC-6 — Memory salience guidance (FR3.AC3.1, FR3.AC3.2)
- **Given**: produced doc.
- **When**: search §"Session boundaries" for substrings `MEMORY.md` (case-sensitive) AND one of {`session start`, `re-read`, `read at start`} (case-insensitive) AND one of {`correction`, `confirm-then-write`, `update if`} (case-insensitive).
- **Then**: all three present. Pass condition: three `grep` invocations each return ≥ 1 match.

### TC-7 — Workflow-state re-derivation from disk (FR3.AC3.3)
- **Given**: produced doc.
- **When**: search §"Session boundaries" for the substring `re-derive` (case-insensitive) AND one of {`on-disk`, `a-task-plan.md through j-retrospective.md`, `Status fields`} (case-insensitive).
- **Then**: both present. Pass condition: two `grep` invocations each return ≥ 1 match.

### TC-8 — Exactly one new file under `.cwf/docs/conventions/` (FR4.AC4.1)
- **Given**: f-exec completed on the task branch.
- **When**: `git diff --name-status main...HEAD -- .cwf/docs/conventions/`.
- **Then**: output contains exactly one line, starting with `A` (added), naming `session-hygiene.md`. Pass condition: line count = 1 AND first field = `A` AND path basename = `session-hygiene.md`.

### TC-9 — CLAUDE.md `## Conventions` consumer present (FR4.AC4.2, AC4.3)
- **Given**: `CLAUDE.md` modified by f-exec Step 3.
- **When**: `grep -nF 'session-hygiene.md' CLAUDE.md`.
- **Then**: ≥ 1 match. Pass condition: `grep -cF 'session-hygiene.md' CLAUDE.md` ≥ 1. Additionally verify the match line uses bare-relative-path syntax (no `[[X]]`) — `grep -F 'session-hygiene.md' CLAUDE.md | grep -cE '\[\[' ` MUST equal 0.

### TC-10 — `[[X]]` syntax restricted to MEMORY.md slugs (AC4.3)
- **Given**: produced doc.
- **When**: `grep -nE '\[\[[a-z_]+\]\]' .cwf/docs/conventions/session-hygiene.md`.
- **Then**: any matches MUST be MEMORY.md slug references (e.g. `feedback_no_heredocs`) — committed-CWF docs MUST use bare relative paths. Pass condition: if zero matches, PASS. If matches exist, manual triage required — each match MUST be in a `feedback_*` / `project_*` / known-private-memory slug form. Documented as manual triage in g-exec.

### TC-11 — NFR4.1 inline "surface, never smooth" principle
- **Given**: produced doc.
- **When**: search §3 for both `surface` (case-insensitive) AND one of {`never smooth`, `do not smooth`, `don't smooth`} (case-insensitive).
- **Then**: both present in §3. Pass condition: `grep -ciF 'surface' <section-3-extract>` ≥ 1 AND `grep -ciE 'never smooth|don.t smooth|do not smooth' <section-3-extract>` ≥ 1.

### TC-12 — NFR4.2 anti-pattern enumeration is defender-framed
- **Given**: produced doc.
- **When**:
  1. `grep -cE 'recompute-hashes|validate --fix|validate --ignore' .cwf/docs/conventions/session-hygiene.md` — must be ≥ 1 (anti-patterns enumerated in-doc).
  2. `grep -inE '/clear\s+.*(escape|bypass|skip|reset|drop|forget|start fresh)' .cwf/docs/conventions/session-hygiene.md` — first-filter regex.
  3. `grep -inE 'compact.*(drop|forget|skip|escape|bypass).*(security|rule)' .cwf/docs/conventions/session-hygiene.md` — first-filter regex.
- **Then**: (1) ≥ 1. (2) and (3) matches MUST appear ONLY in "Do not propose" / anti-pattern defender-framed bullets — manual triage of any match. Pass condition: gate (1) mechanical; gates (2)/(3) PASS if zero matches OR matches confined to defender-framed bullets (triaged in g-exec).

### TC-13 — NFR4.3 defender framing (manual judgement gate)
- **Given**: produced doc.
- **When**: reviewer reads the whole doc with NFR4.3 in mind.
- **Then**: every sentence describing the P2 failure mode is phrased defender-side (what to preserve, when to act) — none constitutes a recipe (how to induce rule loss). Pass condition: reviewer attests PASS in g-exec with one-line justification. Acknowledged judgement-gate per d-plan Step 6.

### TC-14 — BACKLOG entry retired and CHANGELOG updated (process)
- **Given**: f-exec Step 4 ran `backlog-manager retire`.
- **When**:
  1. `grep -cF 'Add Session Hygiene Guidance to CWF Documentation' BACKLOG.md` — MUST be 0 (entry removed).
  2. `grep -cF 'Add Session Hygiene Guidance to CWF Documentation' CHANGELOG.md` — MUST be ≥ 1 (entry appended under Task 150).
  3. `.cwf/scripts/command-helpers/backlog-manager validate` — exit code 0.
- **Then**: all three pass.

### TC-15 — `cwf-manage validate` no new `[SECURITY]` lines (Step 5.5)
- **Given**: validate baseline captured by f-exec Step 1 at `/tmp/-home-matt-repo-coding-with-files-task-150/validate-baseline.txt`.
- **When**: `.cwf/scripts/command-helpers/cwf-manage validate 2>&1 | diff - /tmp/-home-matt-repo-coding-with-files-task-150/validate-baseline.txt`.
- **Then**: diff has no `<` or `>` lines containing `[SECURITY]` introduced by Task 150 changes. Pass condition: `diff` output filtered for `[SECURITY]` shows no NEW `<` lines (additions on the post-edit side).

### TC-16 — Self-reference sanity (low-stakes)
- **Given**: produced doc.
- **When**: `grep -cF 'session-hygiene.md' .cwf/docs/conventions/session-hygiene.md`.
- **Then**: 0 self-references (the doc does not recursively cite its own filename). Pass condition: count = 0. Informational; not a release blocker.

## Test Failure Handling
- **TC-1, TC-2, TC-9, TC-14.3, TC-15**: mechanical gate failure ⇒ return to f-exec to fix the source/edit. Do not patch tests.
- **TC-13**: judgement-gate failure ⇒ rephrase the offending sentences in §3 and re-run TC-12 + TC-13.
- **TC-12 (gate 2/3) triage failure**: same as TC-13 — rephrase, do not silence.

## Non-Functional Tests
- **Performance**: N/A (documentation only).
- **Security**: covered by TC-11, TC-12, TC-13, TC-15.
- **Usability**: line-budget (TC-1) and declarative-framing structural shape implicitly verified by TC-2 / TC-4 / TC-5 / TC-6 / TC-7 (each TC asserts a structural pattern derived from the declarative framing).
- **Reliability**: N/A.

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2? No.
- [ ] **Complexity**: 3+ distinct concerns? No.
- [ ] **Risk**: High-risk isolation? No.
- [ ] **Independence**: Parts separable? No.

**Decomposition decision**: No subtasks.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 150
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
