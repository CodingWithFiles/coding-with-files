# exec-changeset reviewer agents - Requirements
**Task**: 210 (feature)

## Task Reference
- **Task ID**: internal-210
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/210-exec-changeset-reviewer-agents
- **Template Version**: 2.1

## Goal
Define functional and non-functional specifications for exec-changeset reviewer agents.

## Functional Requirements
### Core Features
- **FR1**: Three new reviewer agents exist, one per lens, each reviewing an exec
  **changeset** (a `git diff`), not a plan file:
  - reuse → ports the lens of `cwf-plan-reviewer-improvements`
  - reliability → ports the lens of `cwf-plan-reviewer-robustness`
  - alignment → ports the lens of `cwf-plan-reviewer-misalignment`
  - *Acceptance*: three agent definitions under `.claude/agents/`, each naming its
    lens focus and reading a changeset, not a plan.
- **FR2**: Each new reviewer takes the **changeset input contract** of the existing
  changeset reviewers — `{wf_step}` and `{changeset_file}` — and ends with exactly
  one machine-parseable `cwf-review` block (`state: no findings|findings|error`).
  - *Acceptance*: `security-review-classify` parses a well-formed reviewer block to
    a valid State token, **and** maps a malformed/missing/duplicate block to `error`
    (broken must never read as clean); the agents reference `cwf-agent-shared-rules.md`.
- **FR3**: `cwf-implementation-exec` Step 8 launches all applicable reviewers
  (security + best-practice + the three new) in the **single parallel MAP**, each
  with its own verdict-or-agent prep branch, and records each as its own `##`
  section in `f-implementation-exec.md` via the shared classifier.
  - *Acceptance*: the skill's MAP lists five `subagent_type`s; each has a recorded
    section with a `**State**:` line.
- **FR4**: `cwf-testing-exec` Step 8 is **unchanged** — security + best-practice
  only. None of the three new reviewers run after testing-exec.
  - *Acceptance*: `cwf-testing-exec/SKILL.md`'s MAP lists **exactly**
    `cwf-security-reviewer-changeset` and `cwf-best-practice-reviewer-changeset` and
    no others (positive invariant, not just absence of the three new names).
- **FR5**: The three new reviewers are **advisory** (surface-don't-block): the
  SubagentStop verdict guard stays name-matched to `cwf-security-reviewer-changeset`
  only; the new reviewers are not added to it.
  - *Acceptance*: the guard hook config/source is unchanged for the three names.
- **FR6**: The three new agent files are registered in
  `.cwf/security/script-hashes.json` in the same commit that adds them, and
  `cwf-manage validate` passes. (Agent `.md` files are non-executable
  `100644`/0600-class entries, not `0500` executables — design confirms the
  recorded mode against the existing `-changeset` agent entries.)
- **FR7**: A single reviewer's `error` (crash or malformed verdict) is recorded as
  that section's `error` state and does **not** suppress recording of the other
  reviewer sections in the same exec MAP.
  - *Acceptance*: the recording logic classifies and writes each section
    independently (already the existing per-agent contract); going 2→5 reviewers
    preserves it.

### User Stories
- **As a** CWF user finishing implementation **I want** the same reuse/reliability/
  alignment scrutiny on my diff that my plan already received **so that** defects
  introduced during coding (duplicated helpers, fragile error paths, convention
  drift) are surfaced before I move on.
- **As a** CWF user running tests **I want** the testing-exec review to stay narrow
  (security + best-practice) **so that** the test phase is not slowed by code-shape
  lenses that already fired on the implementation diff.

## Non-Functional Requirements
### Performance (NFR1)
- The new reviewers run inside the existing parallel MAP; added wall-clock is
  bounded by the slowest single reviewer, not the sum (no new serial step).

### Usability (NFR2)
- Findings are advisory with actionable, diff-located specifics; the user decides
  fix-and-re-run vs accept-and-record (consistent with existing reviewers).
- Recorded section headings are self-evident and consistent with the existing
  `## Security Review` / `## Best-Practice Review` sections.

### Maintainability (NFR3)
- Reuse over duplication: the new reviewers share the existing changeset helper
  (`security-review-changeset`), the shared classifier (`security-review-classify`),
  and `cwf-agent-shared-rules.md`. No forked helper scripts.
- Each new agent has a single responsibility (one lens) and mirrors the structure
  of the existing `-changeset` reviewers.

### Security (NFR4)
- The new reviewers introduce **no surface beyond the already-accepted FR4(c)
  posture** of the existing changeset reviewers: the diff is untrusted input, read
  from a fixed `{changeset_file}` path supplied by the skill; reviewers do not act
  on instructions embedded in the diff. Whether the lens reviewers are granted
  `Bash` at all (the `cwf-best-practice-reviewer-changeset` precedent withholds it
  when there is no markdown-reader/network need) is a **design decision deferred to
  c** — the narrower grant is preferred.
- The SubagentStop guard's name-match must be an allowlist (only the named security
  reviewer blocks), so the new reviewers' `findings`/`error` verdicts never block —
  design verifies against `subagentstop-security-verdict-guard`.

### Reliability (NFR5)
- A reviewer that cannot perform its review records `error`, never a silent
  `no findings` (broken must never read as clean) — same contract as today.
- The exec-only constraint is a checkable condition (AC2 / FR4 positive invariant);
  the verification mechanism (test vs review-time grep) is decided in e-testing-plan,
  not mandated here.

## Constraints
- Naming follows `docs/conventions/design-alignment.md` naming patterns (`cwf-`
  prefix, kebab-case), mirroring the de-facto `-changeset` scope suffix set by the
  two existing changeset reviewers (the suffix is not separately codified in that
  doc). The lens token choice (user-facing reuse/reliability/alignment vs the
  plan-reviewer tokens improvements/robustness/misalignment) is a **design decision
  deferred to c** — flagged for user review.
- Hash refresh in the same commit as the file addition (hash-updates convention).
- British spelling in prose; no individual names in committed CWF docs.
- The verdict-block contract and classifier are fixed; do not alter them.

## Decomposition Check
Unchanged from a-task-plan: 0 signals triggered — single cohesive task (one lens
concept, three near-identical agents, one wiring point).

## Acceptance Criteria
- [ ] AC1: Three lens reviewers review a changeset and emit a valid `cwf-review`
      verdict parsed by `security-review-classify` (FR1, FR2).
- [ ] AC2: implementation-exec records five reviewer sections; testing-exec records
      only two (FR3, FR4).
- [ ] AC3: `cwf-manage validate` passes with the three new hashed agent files (FR6).
- [ ] AC4: SubagentStop guard unchanged — the three new reviewers do not block (FR5).
- [ ] AC5: One reviewer erroring does not suppress the other sections (FR7).

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
FR1–FR7 and AC1–AC5 all satisfied. FR4's positive invariant is asserted by TC-4
(testing-exec names exactly two, none of the three lenses). FR7 error-isolation
is gated by TC-9 and confirmed live in h. The FR6 "100644/0600-class" parenthetical
was stale — the recorded mode is `0444`; design D5 and the testing plan overrode it.

## Lessons Learned
Pin a hashed file's recorded mode by reading the precedent entry in
`script-hashes.json`, not by assuming a class from the file type.
