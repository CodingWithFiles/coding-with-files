# Document Dead Code Audit Methodology - Implementation Plan
**Task**: 148 (chore)

## Task Reference
- **Task ID**: internal-148
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/148-document-dead-code-audit-methodology
- **Template Version**: 2.1

## Goal
Land a language-agnostic dead-code-audit methodology doc that ships with CWF, a thin Perl/POSIX recipe sibling that does not ship (CWF-dev internal), and the two integration points (`cwf-plan-reviewer-misalignment` agent, `i-maintenance` template) that connect the methodology to the shift-left and shift-right surfaces. Settle the design decisions that the chore step set deferred from b/c phases inline below.

## Amendments to a-task-plan
*(Surfaced from plan review; the chore step set has no formal "design phase" to record them in.)*
- **A1 — Canonical doc location**: a-task-plan SC2 placed it at `.cwf/docs/maintenance/dead-code-audit-checklist.md`. Amended to `.cwf/docs/dead-code-audit.md` (top-level under `.cwf/docs/`). Rationale: doc spans plan-time + maintenance-time surfaces — top-level signals cross-cutting; `.cwf/docs/maintenance/` subdir doesn't currently exist.
- **A2 — Misalignment-agent path**: a-task-plan SC3 wrote `.cwf/agents/cwf-plan-reviewer-misalignment.md` (stale). Correct path is `.claude/agents/cwf-plan-reviewer-misalignment.md` (per Task 143 move to `.claude/agents/` format).
- **A3 — Agent line budget**: Reconciled to single value `< 55 lines` (matches a-plan SC3 phrasing). Current file is 37 lines; +3 = 40, well within.

## Design Decisions Deferred From b/c

### Decision D1: Doc split — two files, not one with addenda
**Choice**: Two files.
- `.cwf/docs/dead-code-audit.md` — canonical, language-agnostic. Ships.
- `docs/dead-code-audit-perl.md` — Perl/POSIX recipes. Does **not** ship. Flat, ~20-line page; **no category mirroring**, just the recipes themselves.

**Rejected alternative**: Single file with addenda sections (CWF-dev recipes ship to non-Perl consumers as noise) OR parallel structures mirroring the canonical's category list (drift trap).

**Drift mitigation**: Recipes doc opens with a one-line deferral statement: *"Perl/POSIX applied recipes; principles in `.cwf/docs/dead-code-audit.md`. If anything below contradicts the canonical doc, the canonical doc wins."* Recipes never restate principles, only operationalise.

### Decision D2: Canonical doc top-level under `.cwf/docs/`
See amendment A1 above. Location: `.cwf/docs/dead-code-audit.md`. Sibling to `glossary.md` and `migration.md` (other cross-cutting top-level docs).

### Decision D3: Caller categories — 6, not 8
Reviewer feedback collapsed two pairs:
1. **Static direct calls** (same module, named function call).
2. **Static cross-module calls** (imported/required from another module). *Grep scope must include non-source filetypes: config, CI YAML, Dockerfile, Makefile.*
3. **Same-file private callers** (helper called only from one site in the same file) — the Task 51 `workflow_file_mappings()` class.
4. **Reflective / runtime callers** (dispatch table, `eval`/`exec`, dynamic method resolution, `getattr`/Symbol, Perl `&{$name}`) — grep on the *string* form of the symbol.
5. **Tests-only callers** (referenced only from test files) — judgement call: legitimate fixtures vs. tests that exist solely to keep dead code alive.
6. **Advertised external surface** — declared in POD, `__all__`, `exports`, package metadata, a public README, a shipping manifest (e.g. `MANIFEST`, `script-hashes.json`), or an advertised plugin/hook extension point. *Never dead even with no internal callers.*

Each category in the doc gets: definition, why it matters, cross-language example, what to grep/inspect.

### Decision D4: Misalignment-agent reference *deepens* existing bullets — does not replace
**Choice**: Insert one Procedure step (between current 2 and 3) that says: *"For `design` and `implementation` plan_types, also consult `.cwf/docs/dead-code-audit.md` § Plan-time heuristics. The heuristics are a deepening of this agent's existing 'design' and 'implementation' bullets (lines 28-33) — same concern, sharper checklist."*

Canonical doc grows a § Plan-time heuristics section: 4-6 declarative criteria (e.g. *"Flag if the new abstraction has only one callsite — Rule of Three not met"*). **Declarative phrasing required** (Security reviewer S1): heuristics are criteria to evaluate the plan against, not instructions the agent executes. This keeps the trust boundary clean if the doc is ever modified through a less-trusted path.

### Decision D5: i-maintenance integration — one bullet appended to Preventive Maintenance
**Choice**: Append (last bullet) to `.cwf/templates/pool/i-maintenance.md.template` `### Preventive Maintenance` list:
> - Dead-code audit (see `.cwf/docs/dead-code-audit.md`) — periodic sweep using documented methodology.

Append (not insert mid-list) for diff determinism. Applies to future tasks only; existing instantiated `i-maintenance.md` files are not retroactively updated.

### Decision D6: Self-test (success criterion 5)
- **Fixture recovery**: First read Task 51's `j-retrospective.md` Recommendations section — the false-positive callers should be documented there (the entry's whole purpose). Only fall back to git archaeology if the retrospective lacks the detail. Archaeology recipe (avoiding `--all`, which surfaces checkpoints-branch noise per this repo's history model): `git log main --oneline -S 'workflow_file_mappings' --diff-filter=D` → `git show <commit>^:path/to/file` to read the pre-removal state. **Record the exact commit SHA in the g-testing-exec fixture record so the self-test is reproducible.**
- **False-positive pass condition**: Applying the doc's caller-category checklist to each historically-flagged-but-not-dead function must surface at least one real caller for each. (i.e. the methodology, applied honestly, would have stopped Task 51's removal.)
- **Positive control**: Pick **one currently-removed function whose name string still appears elsewhere in the tree** (POD, comments, a similarly-named symbol). The methodology must distinguish *appearance* from *caller-ness* and correctly flag it as dead. Record both the function and the appearance site in the fixture.
- **Symmetric refinement bound**: If either direction fails (false-positive misses or positive-control mis-flags), **at most 3 refinement attempts** to the relevant category text (per CLAUDE.md "3-strikes" rule). After 3 failures, stop, document the failure modes in `g-testing-exec.md`, and reassess at the user level — do not silently overfit. Each refinement attempt records what changed and why.

## Files to Modify
### Primary Changes
- `.cwf/docs/dead-code-audit.md` — **NEW**. Sections: Principle (shift-left framing, "absence of static calls ≠ dead"), When to audit (plan-review + maintenance, naming the misalignment agent and i-maintenance template), Caller categories (D3's 6), Plan-time heuristics (4-6 declarative items per D4), Maintenance-time recipe (general loop), Verdict template.
- `docs/dead-code-audit-perl.md` — **NEW**. ~20 lines. Deferral preamble (D1), then BACKLOG.md:241-245's 5-bullet recipe verbatim, then 2-3 CWF-specific addenda (POD `=head2`, `script-hashes.json` membership as a shipping signal, `cwf-manage update` consumer impact). **Inline note**: symbol names in recipes are operator-supplied at audit time, not interpolated from any automated source (Security S2). Use list-form invocations in any worked example.
- `.claude/agents/cwf-plan-reviewer-misalignment.md` — **MODIFY**. Insert one Procedure step (D4). Target diff: +3 lines.
- `.cwf/templates/pool/i-maintenance.md.template` — **MODIFY**. Append one bullet (D5). Target diff: +1 line.

### Supporting Changes
None. The four new doc paths are not in `.cwf/security/script-hashes.json` and don't need hash coverage to match existing convention (verified: only `cwf-agent-shared-rules.md` is tracked in `.cwf/docs/`; templates other than `install/` are not tracked).

### Verdict Template (per I5, matches BACKLOG.md:245)

```
| Function | File:lines | Per-category findings | Verdict | Recommendation |
```

## Implementation Steps
### Step 1: Recover Task 51 false-positive context (fixture)
- [ ] Read `implementation-guide/51-*/j-retrospective.md` (find the directory via `ls implementation-guide/ | grep '^51-'`) and extract the documented false-positive callers for `workflow_file_mappings()` and `format_error()`.
- [ ] If the retrospective lacks the caller detail, fall back to: `git log main --oneline -S 'workflow_file_mappings' --diff-filter=D` to find the removal commit, then `git show <commit>^:path` to read the prior state. Record the commit SHA.
- [ ] Pick the positive-control function per D6 (name string still appears elsewhere). Record function + appearance site.

### Step 2: Write `.cwf/docs/dead-code-audit.md`
- [ ] **Principle**: 2-3 short paragraphs. Dead code = no live callers across all caller categories. Absence of static calls ≠ dead. Cheapest dead code is dead code never written. Audit is recurring hygiene, not one-off.
- [ ] **When to audit**: shift-left (link `.claude/agents/cwf-plan-reviewer-misalignment.md`) + shift-right (link `.cwf/templates/pool/i-maintenance.md.template`, specifically the Preventive Maintenance bullet).
- [ ] **Caller categories**: D3's 6 items, each with definition / why-it-matters / cross-language example / what-to-grep.
- [ ] **Plan-time heuristics**: 4-6 declarative criteria for misalignment-reviewer consumption (per D4 + Security S1). Examples: *"Flag if the new abstraction has only one callsite — Rule of Three not met."*, *"Flag if a config knob is introduced with no documented operator."*
- [ ] **Maintenance-time recipe**: candidate list → category checklist → verdict per function → structured report.
- [ ] **Verdict template**: the 5-column table from §Verdict Template above.

### Step 3: Write `docs/dead-code-audit-perl.md`
- [ ] Deferral preamble (D1 wording verbatim, one line).
- [ ] BACKLOG.md:241-245's 5 bullets as the recipe core. List-form invocations.
- [ ] CWF-specific addenda: POD `=head2` declaration check; `script-hashes.json` membership as advertised-surface signal (D3 cat 6); `cwf-manage update` propagation when removing a tracked file.
- [ ] Inline note on operator-supplied symbols (Security S2).

### Step 4: Wire misalignment-reviewer reference
- [ ] Edit `.claude/agents/cwf-plan-reviewer-misalignment.md`. Insert step 2a after current step 2 per D4 wording. Use declarative framing (Security S1).
- [ ] **Post-edit guard** (Robustness R8): `grep -F '.cwf/docs/dead-code-audit.md' .claude/agents/cwf-plan-reviewer-misalignment.md` returns ≥1 line, and the referenced file exists.
- [ ] `wc -l .claude/agents/cwf-plan-reviewer-misalignment.md` < 55 (A3).

### Step 5: Wire i-maintenance template reference
- [ ] Edit `.cwf/templates/pool/i-maintenance.md.template`. Append one bullet at end of `### Preventive Maintenance` (D5).
- [ ] **Post-edit guard** (R8): `grep -F '.cwf/docs/dead-code-audit.md' .cwf/templates/pool/i-maintenance.md.template` returns ≥1 line.

### Step 6: Self-test (records into g-testing-exec.md)
- [ ] Apply canonical doc's caller-category checklist to Step 1's two false-positive fixtures. False-positive pass condition per D6.
- [ ] Apply to positive-control fixture. Positive-control pass condition per D6.
- [ ] If either fails: refinement loop bounded at 3 attempts per D6. Each attempt logged.

### Step 7: Validation
- [ ] `cwf-manage validate` clean. Claim is "no regression on tracked files" (the new docs are not tracked, per Supporting Changes note).
- [ ] `wc -l .claude/agents/cwf-plan-reviewer-misalignment.md` < 55.
- [ ] Markdown link integrity (Robustness R6): `grep -nE '\]\(#' .cwf/docs/dead-code-audit.md docs/dead-code-audit-perl.md` — for each anchor, verify a matching `## ` or `### ` heading exists in the target file. Cross-file links: confirm each `.md` path referenced from either doc resolves to an existing file.

## Code Changes
N/A — docs and two-line reference wiring only.

## Test Coverage
**See e-testing-plan.md.** Self-test against Task 51 fixtures + positive control + link integrity + agent line budget.

## Validation Criteria
**See e-testing-plan.md.** Pass = self-test passes both directions within ≤3 refinements per direction AND `cwf-manage validate` clean AND both integration points resolve to existing sections AND agent under 55 lines.

## Scope Completion
Scope is bounded by the four file targets above. Do **not**:
- Run the comprehensive audit (separate backlog item, depends on this task).
- Modify `cwf-manage` to emit dead-code warnings (auto-flagging conflicts with `[[feedback_surface_security_dont_smooth]]`-adjacent reasoning).
- Add automated dead-code detection scripts (separate task if ever justified).
- Touch already-instantiated `i-maintenance.md` files in past tasks (retroactive update out of scope).
- Extend recipes doc with category mirroring (D1 mitigation).

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 148
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
