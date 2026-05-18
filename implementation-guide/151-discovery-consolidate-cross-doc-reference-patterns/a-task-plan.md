# Consolidate Cross-Doc Reference Patterns - Plan
**Task**: 151 (discovery)

## Task Reference
- **Task ID**: internal-151
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/151-consolidate-cross-doc-reference-patterns
- **Baseline Commit**: eecb9133b0f716932e57f3ae07cfec0d5822082e
- **Template Version**: 2.1

## Goal
Audit cross-document reference patterns across CWF templates, skills, helpers, and docs, then document a single canonical style guide with worked-example rules for each context.

## Success Criteria
- [ ] Audit artefact enumerates every distinct reference pattern observed (bold-text, markdown link, HTML comment, plain path, `path:line`, `[[memory-slug]]`, anchor-link, etc.) with concrete occurrence counts per pattern.
- [ ] Patterns categorised by audience (LLM-facing vs human-facing) and locality (intra-task vs intra-repo vs external).
- [ ] Canonical style guide committed at `docs/conventions/cross-doc-references.md` (CWF-dev) with a one-line "use X when Y" rule per category and at least one good/bad example per rule.
- [ ] Style guide cross-linked from `CLAUDE.md` Conventions section (alongside commit-messages, design-alignment, perl, git-path-output).
- [ ] Migration scope quantified: explicit count of references that diverge from the new standard, with a per-file breakdown — does NOT include doing the migration; if the count is non-trivial a BACKLOG entry is filed for it.

## Original Estimate
**Effort**: 1-2 days
**Complexity**: Medium
**Dependencies**: None — pure documentation/audit work, no helper-script or template changes required by this task.

## Major Milestones
1. **Audit complete**: Mechanical sweep of `.cwf/`, `implementation-guide/`, `docs/`, `CLAUDE.md`, `.claude/`, root `*.md` files yields a tabulated pattern inventory.
2. **Categorisation agreed**: Audience × locality matrix populated; ambiguous cases flagged for design-phase decision.
3. **Style guide written**: `docs/conventions/cross-doc-references.md` published with rules and examples; `CLAUDE.md` updated; if non-trivial divergence count, migration BACKLOG entry filed.

## Risk Assessment
### High Priority Risks
- **Scope creep into migration**: The temptation to "fix references while we're in there" turns a 1-2 day discovery into a multi-day refactor touching every wf file.
  - **Mitigation**: Hard stop at "documented standard + counted divergence". Any rewriting of existing references is out of scope; if the count warrants it, file a separate BACKLOG entry.
- **Standard conflicts with existing conventions**: The Templates' `**See e-testing.md...**` pattern is load-bearing for LLM attention; replacing it wholesale could regress wf-step skill behaviour.
  - **Mitigation**: Treat existing patterns as evidence of working LLM-facing conventions. The audit must explain *why* each pattern exists before proposing a replacement; "we found it inconsistent" is not sufficient justification.

### Medium Priority Risks
- **Two `docs/conventions/` trees confuse the audit**: Repo has both `docs/conventions/` (CWF-dev internal) and `.cwf/docs/conventions/` (shipped to installs). Reference rules likely differ between the two.
  - **Mitigation**: Treat the two trees as separate audience scopes and produce rules for each. Document the distinction explicitly in the style guide.
- **Findings invalidate "progressive disclosure" assumption**: Audit may reveal that current patterns are *already* well-chosen, and the BACKLOG entry's premise was wrong.
  - **Mitigation**: Accept this as a valid outcome. A discovery task that concludes "no change needed, here is why" is a successful task; the BACKLOG entry retires with a note explaining the conclusion.

## Dependencies
- Read-access to all CWF files. No external dependencies.

## Constraints
- Documentation-only task. No changes to helper scripts, templates, or skills.
- Must not alter LLM-facing patterns mid-discovery; any proposed change is recorded as a recommendation, not applied.
- Output style guide lives under `docs/conventions/` (CWF-dev internal, per CLAUDE.md `## Versioning` rule about installed files).

## Decomposition Check
- [ ] **Time**: 1-2 days, well under 1 week. No decomposition trigger.
- [ ] **People**: Single-person audit. No decomposition trigger.
- [ ] **Complexity**: Two concerns (audit + style guide write-up) but tightly coupled. No decomposition trigger.
- [ ] **Risk**: Risks are scoping-related, not isolation-related. No decomposition trigger.
- [ ] **Independence**: Audit feeds style guide; not separable. No decomposition trigger.

**Decomposition verdict**: 0/5 signals triggered — proceed as a single task.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
