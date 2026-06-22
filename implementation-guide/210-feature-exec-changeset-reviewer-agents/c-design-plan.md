# exec-changeset reviewer agents - Design
**Task**: 210 (feature)

## Task Reference
- **Task ID**: internal-210
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/210-exec-changeset-reviewer-agents
- **Template Version**: 2.1

## Goal
Define architecture and design decisions for exec-changeset reviewer agents.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### D1 — Architecture: clone the existing `-changeset` reviewer pattern, port only the lens
- **Decision**: Each new reviewer is a near-copy of `cwf-security-reviewer-changeset`'s
  *structure* (input contract `{wf_step}`+`{changeset_file}`, single `cwf-review`
  verdict block, shared-rules reference) with the *lens* (what to look for) ported
  from the corresponding plan reviewer's **implementation** bullet. No new helper,
  no new classifier, no new changeset construction.
- **Rationale**: security/best-practice already established this exact pattern;
  following it gives consistency, reuses the entire deterministic substrate, and
  keeps each agent a single-responsibility lens.
- **Trade-offs**: three near-identical agent bodies (acceptable duplication — they
  differ in the one thing that must differ, the lens); rejected a single
  parameterised "mega-reviewer" because the agent framework keys behaviour on
  `subagent_type` name and per-lens verdicts must be recorded separately (FR3/FR7).

### D2 — Naming **[REQUIRES USER DECISION at plan review]**
- **Recommendation**: reuse the plan-reviewer lens tokens, exactly as the two
  existing changeset reviewers reuse theirs (`cwf-plan-reviewer-security` →
  `cwf-security-reviewer-changeset`):
  - `cwf-improvements-reviewer-changeset`  (the "reuse" lens)
  - `cwf-robustness-reviewer-changeset`    (the "reliability" lens)
  - `cwf-misalignment-reviewer-changeset`  (the "alignment" lens)
- **Rationale**: one vocabulary across plan + changeset variants; `grep improvements`
  finds both. This is the established precedent.
- **Alternative (user may prefer)**: friendlier user-facing tokens
  `cwf-reuse-/reliability-/alignment-reviewer-changeset`. Clearer to end users but
  breaks the plan↔changeset token symmetry. **Whichever is chosen sets both the
  agent name and the recorded `## … Review` section heading** — kept identical to
  avoid a split vocabulary. Downstream plans (d/e/f) assume the recommended tokens;
  a switch is a pure rename, no logic change.

### D3 — Tool grant: withhold `Bash`
- **Decision**: `tools: Read, Grep, Glob, LSP` (no Bash), matching
  `cwf-best-practice-reviewer-changeset`. Each agent body reproduces that file's
  explicit **"Bash is intentionally withheld … do not expect Bash; do not ask for
  it"** paragraph, so a lens agent never stalls or emits `error` for want of a tool
  it was deliberately denied.
- **Rationale**: the diff is untrusted input (FR4(c)); these lenses need only to
  read the `.out` changeset and grep/read the codebase for reuse/convention checks —
  all covered by Read/Grep/Glob/LSP. Withholding Bash is the narrower blast radius
  and the advisory-reviewer precedent. (The security reviewer keeps Bash because its
  threat-model checks need it; the lens reviewers do not.)

### D4 — Advisory, non-blocking (guard untouched)
- **Decision**: do not touch `subagentstop-security-verdict-guard`. Its
  `# cwf-hook-matcher: cwf-security-reviewer-changeset` directive is a one-name
  allowlist; the three new names simply never match, so their `findings`/`error`
  verdicts never block. Surface-don't-block, like best-practice.

### D5 — File mode & hashing
- **Decision**: record each new agent `.md` at `permissions: "0444"` with its sha256
  in `.cwf/security/script-hashes.json`, in the same commit (FR6). Confirmed against
  the existing `cwf-best-practice-reviewer-changeset.md` entry (`0444`).
- **For d to confirm**: whether `cwf-implementation-exec/SKILL.md` is itself
  hash-tracked — if so, editing Step 8 requires refreshing its sha256 in the same
  commit too (security obs / hash-updates convention).

## System Design

### Component Overview
- **Three new agent definitions** (`.claude/agents/cwf-<lens>-reviewer-changeset.md`):
  each reads the changeset, greps the codebase for related code, assesses it against
  its lens, and ends with one `cwf-review` block. Single responsibility per agent.
  The per-lens criteria live in the agent body (as for the plan reviewers).
- **No new doc.** The shared input contract, exec prompt template, and classifier
  reuse are already documented in `security-review.md` § "Exec-phase prompt template";
  Step 8 references it rather than duplicating into a third doc (improvements F1).
  The three `## … Review` section headings and `.out` filenames are declared in the
  Step 8 prose, where the security/best-practice recording already lives.
- **`cwf-implementation-exec` Step 8 (edited)**: the *only* skill change, but it is a
  **prose rewrite, not a pure additive MAP extension**. The stale framing must change:
  the heading `(Changeset Reviews — security + best-practice …)`, the "**Two**
  independent reviewers" sentence, the "(0, 1, or 2 calls)" count, and the
  "Classify + record" instruction that hardcodes the two `.out` filenames + section
  headings (misalignment #1/#2). The MAP grows to ≤5; the three lens agents gate on
  the **same** condition as the security agent and reuse the **same** `{changeset_file}`.
- **`cwf-testing-exec`**: untouched (FR4).

### Data Flow (implementation-exec Step 8)
1. **On-main short-circuit (degradation path)**: if on `main`, record **all five**
   sections as `no findings` (`no findings: on main`) and launch no agents. Going
   2→5, this branch must emit five sections, not two (robustness F2).
2. `security-review-changeset --wf-step=implementation-exec` runs **once** →
   `{changeset_file}` (single source of truth for the diff).
3. `best-practice-resolve --phase=implementation-exec` runs once → `{bp_context_file}`.
4. The three lens sections track the **same verdict-or-agent outcome as the security
   section** across every helper exit state (robustness F3), since they share the
   security changeset gate:
   - exit 0, count > 0 → launch the lens agent;
   - exit 0, count 0 → `no findings: empty changeset`, no agent;
   - exit 0 no parseable line / exit 2 cap / other non-zero → `error: …`, no agent.
   No lens section is ever silently absent.
5. MAP (one parallel message), each launched per its gate:
   - security — if changeset present
   - best-practice — if changeset present AND ≥1 bp match
   - improvements / robustness / misalignment — each if changeset present
     (input: `{wf_step}` + `{changeset_file}` only)
6. For **each** launched agent independently: write verbatim output → its **own**
   scratch `.out` → `security-review-classify < file` → append `## <Lens> Review`
   with `**State**:` line. The three new files are named on the existing scheme to
   avoid collision (robustness F1):
   - `improvements-review-output-implementation-exec.out`
   - `robustness-review-output-implementation-exec.out`
   - `misalignment-review-output-implementation-exec.out`
   Independent per-agent recording preserves FR7 (one error ≠ suppressed peers).

## Interface Design

### Agent frontmatter (each of the three)
```
---
name: cwf-<lens>-reviewer-changeset
description: Review an exec-phase CWF changeset for <lens> concerns. Ends with a machine-parseable cwf-review verdict block.
effort: high
tools: Read, Grep, Glob, LSP
---
```

### Agent inputs (shared contract — identical to security reviewer)
- `{wf_step}` — `"implementation-exec"` (the lens reviewers are never invoked from
  testing-exec).
- `{changeset_file}` — absolute `.out` path produced by `security-review-changeset`.

### Verdict block (shared contract — classified by `security-review-classify`)
```cwf-review
state: <no findings|findings|error>
summary: <optional one-line note>
```

### Per-lens focus (ported from each plan reviewer's *implementation* bullet, recast for a diff)
- **improvements (reuse)**: does the diff reuse existing code, or duplicate a helper
  / re-add something that exists? Could the same result ship with less new code?
- **robustness (reliability)**: does the diff handle errors and edge cases, follow
  correct > maintainable > performant ordering, and avoid fragile failure paths?
- **misalignment (alignment)**: does the diff use existing utilities/modules and
  match project conventions and abstractions rather than reinventing them?

## Constraints
- Verdict-block contract, `security-review-classify`, and `security-review-changeset`
  are fixed and reused — not modified (NFR3).
- Single changeset run feeds all reviewers (no per-reviewer diff construction).
- testing-exec Step 8 is not edited (FR4).
- British spelling; no individual names; hash refresh in-commit.

## Decomposition Check
0 signals — single cohesive change (three agents, one doc, one skill edit), same as
prior phases.

## Validation
- [ ] Plan-review map/reduce completed (design)
- [ ] D2 naming decision confirmed by user at plan review
- [ ] Integration point verified: only `cwf-implementation-exec` Step 8 changes

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: D2 (naming) pending user confirmation at plan review — non-blocking for
drafting d/e (rename-only if changed).

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
D1–D5 implemented as designed. D2 resolved to the plan-reviewer tokens
(improvements/robustness/misalignment) — no rename needed. D3 (Bash withheld) was
confirmed by the security reviewer as a net surface *reduction* vs the security
reviewer. D5: SKILL.md is not hash-tracked, so only the three agent `.md` files
needed hash refresh.

## Lessons Learned
Deciding guard scope in design (advisory → unguarded) turned FR5 into a one-line
verification (TC-5 + the live h run) rather than a debugging exercise.
