# exec-changeset reviewer agents - Implementation Plan
**Task**: 210 (feature)

## Task Reference
- **Task ID**: internal-210
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/210-exec-changeset-reviewer-agents
- **Template Version**: 2.1

## Goal
Implement exec-changeset reviewer agents following the approved design and requirements.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

> Names below use the **D2-recommended tokens** (`improvements`/`robustness`/
> `misalignment`). If the user picks the friendlier alternative at plan review, every
> occurrence is a pure rename — no step logic changes.

## Files to Modify
### Primary Changes (new)
- `.claude/agents/cwf-improvements-reviewer-changeset.md` — new (reuse lens)
- `.claude/agents/cwf-robustness-reviewer-changeset.md` — new (reliability lens)
- `.claude/agents/cwf-misalignment-reviewer-changeset.md` — new (alignment lens)

### Primary Changes (edit)
- `.claude/skills/cwf-implementation-exec/SKILL.md` — Step 8 prose rewrite (2→5
  reviewers). **Not hash-tracked** (confirmed: no SKILL.md in script-hashes.json),
  so no hash refresh for this file.

### Supporting Changes
- `.cwf/security/script-hashes.json` — three new entries (`permissions: "0444"`,
  sha256), same commit as the agent files (FR6).
- `CHANGELOG.md` / `BACKLOG.md` — changelog entry; retire any matching backlog item.
- `cwf-project.json` — version-stamp field (per the established per-task pattern).

> **Out of scope (deliberate, "best part is no part")**: no new doc, no helper
> change, no classifier change, no guard change, no `cwf-testing-exec` edit, no
> codifying the `-changeset` suffix in design-alignment.md.

## Implementation Steps
### Step 1: Author the three agent files
- [ ] For each lens, create `.claude/agents/cwf-<lens>-reviewer-changeset.md` by
      cloning the **structure** of `cwf-best-practice-reviewer-changeset.md` verbatim
      (it is the Bash-free precedent — clone it, **not** the security reviewer, so
      `Bash` is never inherited into frontmatter), changing only:
  - frontmatter `name` + `description` (per design Interface Design);
        `effort: high`, `tools: Read, Grep, Glob, LSP` (no `Bash`).
  - the H1 title (`# CWF <Lens> Reviewer — Changeset`).
  - the **Procedure**: drop **both** the `{bp_context_file}` Inputs bullet **and**
    its Procedure read-step (the "read the source list / enumerate a directory" step);
    replace that step with the lens's own instruction — read the changeset, **grep the
    codebase for related code**, assess against the lens (per design "Per-lens focus").
    (Robustness #5: leaving the `{bp_context_file}` read-step in place would make the
    agent `error` on an absent source list.)
- [ ] Keep **byte-identical**: the shared-rules pointer, the "Bash is intentionally
      withheld … do not expect Bash; do not ask for it" paragraph, the Inputs framing
      for `{wf_step}`/`{changeset_file}`, and the entire **Verdict block** section.
      Copying the verdict block verbatim is what guarantees a lens agent emitting prose
      with no/invalid block classifies as `error` (broken-reads-as-error, via
      `security-review-classify`) — it is coupled to Step 2's recording.
- [ ] **Note (improvements F1/F2)**: agent `.md` files have no include mechanism, so
      the shared body is *necessarily* copied — this matches the existing pattern (both
      shipped changeset agents inline the verdict block). Hoisting the verdict block
      into `cwf-agent-shared-rules.md` is declined for this task: it would either make
      the three new agents inconsistent with the two shipped ones, or force refactoring
      + re-hashing the shipped agents and editing the hash-tracked shared-rules doc —
      scope creep beyond "add three reviewers". Logged as a backlog candidate instead.

### Step 2: Rewrite Step 8 of cwf-implementation-exec/SKILL.md
Target structure (security + best-practice flow unchanged in mechanics; lens flow
added alongside):
- [ ] **Heading + preamble**: rename from "security + best-practice" / "**Two**
      independent reviewers" to cover five reviewers; the three lens reviewers are
      advisory like best-practice and share no state with the security guard.
- [ ] **On-main branch**: append **five** `no findings: on main` sections, not two
      (robustness F2).
- [ ] **Prep**: helper #1 (`security-review-changeset`) outcome now drives the
      security section **and** the three lens sections — they share its
      verdict-or-agent decision across every exit state (robustness F3): count>0 →
      launch; count 0 → `no findings: empty changeset`; no-parseable/cap/other →
      `error: …`. Helper #2 (`best-practice-resolve`) unchanged, gates only bp.
      The helper's stderr `warning:` line is noted **once** under `## Security Review`
      (it derives from one helper run) — not duplicated under the lens sections
      (robustness #1).
- [ ] **Invariant (robustness #2)**: *every one of the five sections is always
      emitted* — by the classifier when its agent launched, or by a direct
      verdict-or-agent record when it did not (on-main, empty, error). "Generalise the
      loop" must not be read as "only the launched agents get sections." No section is
      ever silently absent (FR7 / design Data Flow).
- [ ] **MAP**: extend the parallel call list from "(0, 1, or 2 calls)" to up to five —
      add `cwf-improvements-/robustness-/misalignment-reviewer-changeset`, each with
      `{wf_step}="implementation-exec"` and `{changeset_file}` (reference
      `security-review.md` § "Exec-phase prompt template" for the shared prompt shape).
- [ ] **Classify + record**: generalise the existing loop to all launched agents;
      add the three new section headings (`## Improvements Review` /
      `## Robustness Review` / `## Misalignment Review`) and `.out` filenames
      (`improvements-review-output-implementation-exec.out`, etc.). Each section is
      classified + recorded **independently** via `security-review-classify` (FR7).

### Step 3: Register hashes
- [ ] Add the three agent entries to `.cwf/security/script-hashes.json` (`0444` +
      sha256). Prefer `cwf-manage fix-security` / the repo's hash-refresh path over
      hand-editing; refresh in the **same commit** as the file additions.

### Step 4: Docs + version
- [ ] CHANGELOG entry; retire matching backlog item if present; version-stamp
      `cwf-project.json`.
- [ ] Add a BACKLOG candidate: "Hoist the shared `cwf-review` Verdict block into
      `cwf-agent-shared-rules.md` and de-dup the (now five) changeset reviewers"
      (improvements F2, deferred to keep this task scoped).

### Step 5: Validate
- [ ] `cwf-manage validate` → OK.
- [ ] Verify none of the three new frontmatters contain `Bash` (security: grep the
      `tools:` line of each new agent).
- [ ] Smoke per e-testing-plan (output-level):
  - happy path: a sample exec run records **five** `##` sections;
  - on-`main`: **five** `no findings: on main` sections (the 2→5 regression most
    likely to ship broken — robustness #4);
  - empty changeset: five `no findings: empty changeset` sections;
  - testing-exec still records exactly **two**.

## Test Coverage
**See e-testing-plan.md for complete test plan**

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
**Blockers**: D2 naming pending user confirmation (rename-only if changed)

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All steps executed (see f-implementation-exec.md). The Step-4 "version-stamp
`cwf-project.json`" and CHANGELOG entry were deferred to retrospective (j) to match
the established per-task pattern (`wf_step_config.retrospective.bump_version`); the
BACKLOG candidate was added in f.

## Lessons Learned
A "version-stamp" instruction in an implementation plan should be read as
retrospective-time for this repo — the release marker is bumped at j, not f.
