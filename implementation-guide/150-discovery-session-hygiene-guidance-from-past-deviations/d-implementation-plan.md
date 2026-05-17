# Session hygiene guidance from past deviations - Implementation Plan
**Task**: 150 (discovery)

## Task Reference
- **Task ID**: internal-150
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/150-session-hygiene-guidance-from-past-deviations
- **Template Version**: 2.1

## Goal
Detail the concrete edits to land the design from c-design-plan, with exact paths, anchors, and validation gates.

## Hashed-Path Disclosure (per hash-updates.md plan-time rule)
`grep -c session-hygiene .cwf/security/script-hashes.json` → 0. No path touched by this implementation appears in `script-hashes.json`. **No hash refresh required**.

## Files to Modify

### Primary
| Path | Change | Anchor / Edit shape |
|------|--------|---------------------|
| `.cwf/docs/conventions/session-hygiene.md` | **NEW** | Created via Write tool with the 4-section + tail shape from c-design-plan §D3 |
| `CLAUDE.md` | MODIFIED | Edit inserts one bullet immediately after the `**Hash Updates**` block (final-bullet anchor: `What NOT to build: any surface that silences ...`) |
| `BACKLOG.md` | MODIFIED | Retire entry "Add Session Hygiene Guidance to CWF Documentation" via `backlog-manager retire`. Helper handles BACKLOG removal + CHANGELOG append atomically — do not hand-edit |

### Supporting
| Path | Change | Reason |
|------|--------|--------|
| `CHANGELOG.md` | MODIFIED (by helper) | `backlog-manager retire` writes a `#### Add Session Hygiene Guidance to CWF Documentation` block under the Task 150 `### Retired Backlog Items` subsection. No hand-edit |

## Implementation Steps (numbered, sequential)

### Step 1 — Pre-flight baselines
- `git status -s` shows a clean working tree on the task branch.
- `grep -c "What NOT to build: any surface that silences" CLAUDE.md` MUST equal `1` (Step 3 Edit-anchor uniqueness; Robustness F1).
- Capture validate baseline for Step 5.5 diff:

      mkdir -m 0700 -p /tmp/-home-matt-repo-coding-with-files-task-150
      .cwf/scripts/command-helpers/cwf-manage validate \
        > /tmp/-home-matt-repo-coding-with-files-task-150/validate-baseline.txt 2>&1 \
        || true

  (Per `.cwf/docs/conventions/tmp-paths.md`, namespaced scratch dir.)

### Step 2 — Write the new convention doc
Using the Write tool, create `.cwf/docs/conventions/session-hygiene.md` with this skeleton:

    # Session Hygiene

    ## Convention
    <one paragraph: rule + brief why; ~6 lines>

    ## When to /clear
    <bullet list, ≥3 conditions, ≥2 cite audit-table P-numbers, declarative `when X → do Y`; ~10 lines>

    ## When to /compact + what to preserve
    <sub-blocks:
      (a) /compact vs auto-compact distinction (one line each);
      (b) Preservation list with ≥3 named categories INCLUDING "standing security rules from CLAUDE.md `## Critical Rules` and MEMORY.md";
      (c) "Do not propose" sub-bullet enumerating NFR4.2 anti-patterns (recompute-hashes, validate --fix, validate --ignore, /clear-as-gate-bypass, compaction-induced rule drop) in defender-framed phrasing;
      (d) inline "surface, never smooth" principle paragraph (NFR4.1) with cross-reference to .cwf/docs/conventions/hash-updates.md `## What NOT to build (principle, not enumeration)`;
    ~16 lines>

    ## Session boundaries: memory + workflow-state on resume
    <sub-blocks:
      (a) Memory salience: read MEMORY.md at session start; on correction, confirm-then-write/update;
      (b) Workflow-state on resume: re-derive from on-disk a-task-plan.md through j-retrospective.md Status fields; do not trust the resumed conversation's claim about "current step";
    ~10 lines>

    ## See also
    - .cwf/docs/workflow/stop-hooks-framework.md — Stop-hook semantics including /clear, /compact, resume
    - .cwf/docs/conventions/hash-updates.md `## What NOT to build (principle, not enumeration)` — sibling residence of the "surface, never smooth" principle
    - MEMORY.md "Recurring Process Errors" — workflow-process residue category
    - CLAUDE.md `## Critical Rules` — standing rules referenced in the preservation list
    <~2 lines>

### Step 3 — Add CLAUDE.md `## Conventions` bullet
Edit tool, anchor on the literal final-bullet of the Hash Updates block.

**old_string** (unique today per Step 1 check):

    - What NOT to build: any surface that silences `cwf-manage validate` without surfacing first

**new_string**:

    - What NOT to build: any surface that silences `cwf-manage validate` without surfacing first

    **Session Hygiene**: When to `/clear`, when to `/compact` and what to preserve, how to keep memory salient across sessions, and how to re-derive workflow state on resume. See `.cwf/docs/conventions/session-hygiene.md` for:
    - Triggering conditions for `/clear` and `/compact` (vs auto-compaction)
    - Preservation list explicitly including standing security rules from CLAUDE.md `## Critical Rules` and MEMORY.md
    - Inline "surface, never smooth" principle covering `/clear`-as-gate-bypass and compaction-induced rule drop
    - On session-resume: re-derive current wf step from on-disk task files, not from the resumed conversation

### Step 4 — Retire BACKLOG entry

    .cwf/scripts/command-helpers/backlog-manager retire \
      --exact-title="Add Session Hygiene Guidance to CWF Documentation" \
      --task=150 \
      --note="Implemented as discovery task with evidence-based deviation audit (P1–P5 in b-requirements). Doc placed under .cwf/docs/conventions/ (installed-tier); single CLAUDE.md ## Conventions consumer per AC4.2(a)."

**Fallback (Robustness F5)**: if `retire` exits non-zero (typically title mismatch), run `backlog-manager list --all-items | grep -i 'session hygiene'` to retrieve the exact title and retry; **never** hand-edit BACKLOG.md or CHANGELOG.md.

### Step 5 — Mechanical validation (gates)
1. `wc -l .cwf/docs/conventions/session-hygiene.md` → MUST be ≤ 60 (NFR2.1).
2. `grep -c "session-hygiene.md" CLAUDE.md` → MUST be ≥ 1 (AC4.2).
3. `grep -nE 'recompute-hashes|validate --fix|validate --ignore' .cwf/docs/conventions/session-hygiene.md` — matches MUST appear, but ONLY inside the "Do not propose" defender-framed bullet (NFR4.2 — presence-as-labelled-anti-pattern is correct; presence-as-recommendation is incorrect). Triage the matches at Step 6.
4. `.cwf/scripts/command-helpers/backlog-manager validate` → exit 0 (helper-format check post-retire).
5. `.cwf/scripts/command-helpers/cwf-manage validate 2>&1 | diff - /tmp/-home-matt-repo-coding-with-files-task-150/validate-baseline.txt` → no NEW `[SECURITY]` lines vs baseline.

### Step 6 — Defender-framing review (NFR4.3) — manual judgement gate
Reader-side pass on the new doc with NFR4.3 in mind: every sentence describing the P2 failure mode must be phrased from the defender's side (what to preserve, when to act) — not as a recipe (how to induce rule loss).

**First-filter regex** (Robustness F6, low-cost; manual review remains the actual gate):

    grep -inE '/clear\s+.*(escape|bypass|skip|reset|drop|forget|start fresh)' \
      .cwf/docs/conventions/session-hygiene.md
    grep -inE 'compact.*(drop|forget|skip|escape|bypass).*(security|rule)' \
      .cwf/docs/conventions/session-hygiene.md

Any matches → manual triage required. Matches inside "Do not propose" / "anti-pattern" bullets are fine; matches in advice-prose are not. Triage the Step 5.3 matches under the same rule.

### Checkpoint commit
Out of scope for this plan — the f-exec skill (Step 9 of `cwf-implementation-exec`) owns the checkpoint commit invocation.

## Test Coverage
| Requirement | Test (full TC bodies in e-testing-plan) |
|-------------|------------------------------------------|
| FR1.AC1.1 — ≥3 `/clear` conditions | Count bullets in §"When to `/clear`" |
| FR1.AC1.2 — ≥2/3 cite audit patterns | Grep for `P[1-5]` references in §"When to `/clear`" |
| FR2.AC2.1 — `/compact` vs auto distinction | Substring presence + separate bullets |
| FR2.AC2.2 — preservation list ≥3 categories incl. standing security rules | Bullet count + literal-string "standing security rules" |
| FR3.AC3.1, AC3.2 — memory salience | Substring presence in §4 sub-block (a) |
| FR3.AC3.3 — re-derive wf state from disk | Substring presence in §4 sub-block (b) |
| FR4.AC4.1 — exactly one new file | `git diff --name-status main…HEAD` shows one `A` under `.cwf/docs/conventions/` |
| FR4.AC4.2 — CLAUDE.md consumer | Step 5.2 grep |
| FR4.AC4.3 — bare-path syntax | `grep -nE '\[\[[a-z]' .cwf/docs/conventions/session-hygiene.md` matches MUST resolve to MEMORY.md-slug references only (manual triage) |
| FR4.AC4.6 — survives `/compact` | Structurally verified (D2 mechanism). No empirical test this task; flag as outstanding follow-on observation in j-retrospective (Robustness F7) |
| NFR2.1 — line budget | Step 5.1 |
| NFR4.1 — inline principle | Substring presence of "surface" + "never smooth" (or equivalent) in §3 |
| NFR4.2 — anti-pattern enumeration in defender frame | Step 5.3 + Step 6 triage |
| NFR4.3 — defender framing | Step 6 manual review |

## Validation Criteria (rollup)
- [ ] All 5 Step-5 mechanical gates pass.
- [ ] Step-6 manual review attests "no recipe phrasing".
- [ ] `git status -s` post-edits shows: one new `.cwf/docs/conventions/session-hygiene.md`; modified `CLAUDE.md`, `BACKLOG.md`, `CHANGELOG.md`; nothing else.

## Constraints (from a/b/c plans)
- ≤60 lines (NFR2.1)
- No new code, no skill behaviour changes
- Bare relative paths for committed-CWF cross-references; `[[slug]]` permitted only for MEMORY.md slugs
- British spelling
- **Reversibility (Robustness F8)**: all changes are file-level. `git checkout CLAUDE.md BACKLOG.md CHANGELOG.md` + `rm .cwf/docs/conventions/session-hygiene.md` fully undoes f-exec.

## Decomposition Check
- [ ] **Time**: >1 week? No (≤ 1 hour exec).
- [ ] **People**: >2? No.
- [ ] **Complexity**: 3+ distinct concerns? No.
- [ ] **Risk**: High-risk isolation? No.
- [ ] **Independence**: Parts separable? No.

**Decomposition decision**: No subtasks.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 150
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
