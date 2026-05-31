# Adapt CWF to new Claude Code harness - Implementation Plan
**Task**: 172 (discovery)

## Task Reference
- **Task ID**: internal-172
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/172-adapt-cwf-to-new-claude-code-harness
- **Template Version**: 2.1

## Goal
Produce the assessment document (the §1–§7 structure from c-design-plan.md) in
`f-implementation-exec.md`, populated from real evidence, with `g-testing-exec.md`
holding the AC verification. "Implementation" here = writing the findings, not code.

## Workflow
Evidence → fixed-field rows → tradeoff matrix → recommendations → AC check.

## Files to Modify
### Primary Changes
- `implementation-guide/172-.../f-implementation-exec.md` — the §1–§7 assessment
  (the deliverable). All FR1–FR5 findings land here as the Decision-4 schemas.
- `implementation-guide/172-.../g-testing-exec.md` — AC1–AC8 verification table
  (written in the g-testing-exec phase, spec'd in e-testing-plan.md).

### Supporting Changes
- **None.** No code, no scripts, no `script-hashes.json`, no symlinks. This is a
  Markdown-only deliverable (design Constraints). If the assessment turns out to
  need a CWF edit, that is a **follow-up task**, not this one.

### Evidence inputs (read-only)
- `/var/tmp/dircachefilehash.log` — the user-supplied terminal backlog (1.4 MB,
  ~72k lines); the FR4 permission-prompt source. **Mine, do not dump** (see Step 3).
- The `dircachefilehash` Task 6 transcript captured in-conversation — FR1/FR2/FR3
  evidence.
- This repo's `.cwf` / `.claude` tree — to resolve the call-site sets and
  cross-reference MEMORY.md.

## Implementation Steps
### Step 1: Setup & environment stamp (§1)
- [ ] Re-read c-design-plan.md Decisions 1–7 and the b-plan ACs.
- [ ] Capture the version stamp for §1: CC client version + `claude-opus-4-8` model
      id. Source the client version from the runtime/announcement; if not
      determinable, mark the `cc_version` field `pending` (NFR5) rather than guess.
      This stamp is referenced by every finding (NFR3). **Note**: a `pending`
      `cc_version` does **not** put an FR1 row in violation of AC1 — AC1 constrains
      `evidence_ref` (which must be present), not the version field.

### Step 2: Harness-change catalogue (§2 / FR1)
- [ ] One `CatalogueEntry` row per change. Minimum coverage: git-worktree handling,
      model self-checking / dependency-reaction, the "workflow" keyword reservation.
- [ ] Worktree-handling row records the **guarded `EnterWorktree`/`ExitWorktree`**
      primitive (Decision 7) as the changed behaviour, with the cheap-safe repro
      (Step 6) as evidence. **Degradation**: if those tools aren't granted in this
      session (they are deferred tools — fallback is likely), the row cites the
      transcript + Decision-7 reasoning and is flagged as reasoning-not-first-hand,
      never silently downgraded to an unevidenced claim (AC7).
- [ ] Model-self-checking row carries a real `mitigation` (FR1 mandatory for that
      row) — e.g. the anchor incident's "trusted remembered gosec rule semantics
      over tool output" pattern and its CWF mitigation.

### Step 3: Permission-prompt inventory (§5 / FR4) — mine the backlog
- [ ] Extract only the permission-prompt regions from `/var/tmp/dircachefilehash.log`
      — `grep -n` for the prompt markers (e.g. "Do you want to proceed", "permission",
      "Allow", tool-use approval banners) and read **just those line windows** with
      Read offset/limit. Never read the whole 72k-line file into context.
- [ ] **Redact on extraction, not just at row-write (AC8 + security finding)**: the
      log is a raw terminal backlog that may hold real session secrets. Any matched
      window read into context must be treated as secret-bearing; scrub
      credentials/tokens/env-var values **before** synthesising — an un-redacted
      secret must not transit conversation context (and thus this session's
      transcript), let alone a row. Set `redacted: true` on every row sourced this way.
- [ ] One `PromptEntry` per distinct triggering command shape; set `friction` H/M/L
      (ordinal OK), `memory_xref` against MEMORY.md, `status` new|known.
- [ ] Flag `security_relevant: true` on any whose remediation would add a
      `.claude/settings.local.json` allowlist entry (FR4 ⇒ NFR4).

### Step 4: Data-loss root-cause map (§3 / FR2)
- [ ] One `LossMechanism` row per mechanism (a)–(d) from the anchor transcript;
      `evidence_ref` cites the transcript (never `pending` — AC2).
- [ ] Populate `intersecting_call_sites` for (b) from the **verified** grep
      `grep -rln "rev-parse --show-toplevel" .cwf .claude` (13 files) — see the
      c-design "FR2(b) call-site note" for the full rationale (load-bearing site:
      `task-workflow.d/delete`, the self-worktree guard inside the deletion flow).
      Note: b-requirements FR2(b)'s "one live call site" wording is the
      **superseded** framing; the 13-site set is authoritative.
- [ ] `intersecting_convention` for (b) = `feedback_no_cd_git_rev_parse.md` +
      `tmp-paths.md`; for (c)/(d) note any related convention or `none`.
- [ ] Each row: precondition, exposing CWF step, ≥1 `mitigation` + `tradeoff_note`.

### Step 5: Keyword-collision assessment (§4 / FR3)
- [ ] `CollisionSite` rows: wf step files, `workflow-manager`, the `cwf-*-plan`
      "workflow skills", CLAUDE.md/skills prose, `.cwf/docs/glossary.md`.
- [ ] Record the observed behaviour change (the system-reminder steering toward the
      multi-agent Workflow tool — witnessed on this very task as in-session
      evidence, NFR-dogfooding).
- [ ] ≥3 `CollisionOption` rows spanning guard → wording → rename, each with blast
      radius; **none pre-selected** (AC3).

### Step 6: Cheap-and-safe reproduction (feeds §2/§3, Decision 3)
- [ ] Demonstrate mechanism (b) read-only: prefer `EnterWorktree` then
      `git rev-parse --show-toplevel` (observe it returns the worktree path), then
      `ExitWorktree(action: remove)`. Use a throwaway branch with **no real
      uncommitted work**. If tool grants are unavailable, fall back to raw
      `git worktree add`/`remove` on a scratch path — still no `--force`, no real work.
- [ ] **To actually exercise the guard's refusal** (else "guard exists" is asserted,
      not observed — AC7): inside the *disposable* worktree, create a throwaway dirty
      file (no real work at risk), then call `ExitWorktree(action: remove)` and record
      whether it refuses without `discard_changes`. If the guarded tool isn't granted,
      mark the refusal behaviour transcript-sourced/`pending` rather than implying it
      was observed first-hand.
- [ ] **Forbidden** (NFR1/NFR4): re-running mechanism (c)/(d) destructively against
      any real work.

### Step 7: Tradeoff matrix & recommendations (§6 / FR5, Decision 6)
- [ ] Score each candidate mitigation on safety_delta × momentum_delta; flag any
      negative-safety option.
- [ ] One `Recommendation` per action: `tradeoff_line`, `target_surface`, `priority`,
      `proposed_task(type+scope)`. The "use guarded worktree tools" recommendation
      (Decision 7) is evaluated here as a likely top-ranked item.
- [ ] Apply the AC6 gate: every destructive-op recommendation carries the explicit
      "surface, never smooth" tradeoff (cite `feedback_surface_security_dont_smooth.md`).

### Step 8: Remediation decomposition (§7 / FR5)
- [ ] Project the §6 `proposed_task` fields into a follow-up-task list (type, surface,
      one-line scope). §7 must introduce **no task that isn't already carried by a §6
      `Recommendation.proposed_task`** (one source of truth). Do **not** create the
      tasks (scope boundary).

### Step 9: Security review + checkpoint
- [ ] Run the exec-phase security review (Step 8 of the f-skill); changeset is
      Markdown-only so expect an empty/no-findings changeset, but run it.
- [ ] Checkpoint-commit `f-implementation-exec.md`.

## Code Changes
None — Markdown-only deliverable. (No before/after code blocks apply.)

## Test Coverage
**See e-testing-plan.md** — verification is AC1–AC8 structural checks on the §1–§7
document, not a unit-test suite.

## Validation Criteria
**See e-testing-plan.md.** Headline: every AC maps to a structural check on a
schema field or section; AC6 (safety gate) and AC8 (redaction) are pass/fail gates.

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
All 9 steps executed. Step 3 (backlog mining) required an unplanned de-escaping pass —
the backlog was a raw VT capture, not readable text; handled with a read-only stripper +
`LC_ALL=C`/`grep -a`. Step 6 reproduced mechanism (b) first-hand in a throwaway repo.
Redaction-on-extraction (Step 3) found no secrets to remove (gosec-triage session).

## Lessons Learned
The "mine, do not dump" instruction was essential — the 72k-line backlog was windowed by
prompt markers, never read whole. A reusable "mining a raw terminal capture" note (strip
ANSI, `LC_ALL=C`, `grep -a`) would save the next discovery task the same detour.
