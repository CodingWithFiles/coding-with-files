# Sync docs and README with current CWF state - Plan
**Task**: 232 (chore)

## Task Reference
- **Task ID**: internal-232
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/232-sync-docs-and-readme-with-current-cwf-state
- **Baseline Commit**: e5e87b4b22e6197ff70a99b41c0da4e8a99b7962
- **Template Version**: 2.1

## Goal
Bring the user- and maintainer-facing documentation back into agreement with the CWF
implementation that ships today, so the repo presents a coherent, accurate picture — the
same recurring sync last done at Task 189 (v1.1.189), now ~42 tasks of drift later
(current state is v1.1.231).

**Why (intent):** Documentation drifts as tasks land; ~42 tasks (190–231) have added
skills, helper scripts, conventions, and behaviour since the last sync, so counts,
command lists, version-example strings, and architecture descriptions in the headline docs
now lag reality. The repo is being prepared for public release (Task 231 scrubbed private
data as the other half of that prep), and a public reader/adopter must see docs that match
what the code actually does.

**Explicit request:** "Sync docs and README with current CWF state" — bring the docs and
README into line with the current implementation (v1.1.232 being the next task number).

<!-- The goal is owner-owned. Do not unilaterally narrow or widen it. Surface any
     scope change (either direction) or goal/why tension to the owner as a decision. -->

## Success Criteria
<!-- Criteria must be outcome-shaped (observable results), never named after a
     not-yet-chosen mechanism. -->
- [ ] Every `/cwf-*` command named in README.md, COMMANDS.md and CLAUDE.md maps to an
      actual skill in `.claude/skills/`; no documented command is missing or invented, and
      every skill's documented syntax matches its real interface.
- [ ] Every quantitative claim in the docs (skill count, helper-script count, workflow-step
      count, template set, test totals) matches reality at the time of writing, verified by
      recount during exec rather than copied from existing prose.
- [ ] No stale system-version assertion remains; any version-format string is either
      current-era or clearly labelled as an illustrative example.
- [ ] DESIGN.md, CWF-PROJECT-SPEC.md and CLAUDE.md describe the architecture that ships
      today (current helper-script naming, lettered a–j phase files, security model), with
      no reference to removed or renamed features.
- [ ] A grep sweep of the shipped docs plus a freshly generated task's artefacts surface
      no stale counts or version strings (output-level smoke test, per the rebrand lesson).

## Original Estimate
**Effort**: ~1 day
**Complexity**: Low–Medium (breadth across many docs, but each edit is low-risk text)
**Dependencies**: None external. Relies on current skill/script/template/phase state as
ground truth (audit performed during the implementation-plan phase).

## Major Milestones
1. **Inventory locked**: ground-truth counts (23 skills, 27 helper scripts, 10 phase docs,
   template set) and the full file-by-file drift list confirmed and recorded in
   d-implementation-plan.
2. **High-impact corrections**: README, COMMANDS.md command set/syntax, CLAUDE.md
   system-state claims and counts corrected.
3. **Architecture docs**: DESIGN.md / CWF-PROJECT-SPEC.md updated to current naming, phase
   model and version-example era.
4. **Housekeeping**: root `scratchpad.md` disposition resolved; cross-doc references
   validated; any deeper consolidation deferred to BACKLOG rather than done here.
5. **Verification**: grep sweep + generated-artefact smoke test clean.

## Risk Assessment
### High Priority Risks
- **Re-introducing new stale numbers**: hand-copying counts (e.g. "27 scripts") risks
  being wrong tomorrow and wrong on the next audit.
  - **Mitigation**: recount programmatically during exec; prefer descriptive phrasing over
    brittle exact counts where a count adds no value; record each count's basis.

### Medium Priority Risks
- **Scope creep into rewriting architecture**: DESIGN.md / CWF-PROJECT-SPEC.md may be
  substantially behind, tempting a full rewrite.
  - **Mitigation**: scope is *sync to current reality*, not redesign — correct claims and
    names, do not re-architect; larger rewrites go to BACKLOG.
- **CLAUDE.md is an instruction file, not just prose**: careless edits could change agent
  behaviour.
  - **Mitigation**: limit CLAUDE.md edits to the factual Project-Status/architecture claims
    that are wrong; leave conventions/rules untouched.
- **docs/ vs .cwf/docs/ authority**: which is canonical is a convention question, not a
  pure sync fix.
  - **Mitigation**: fix references against the documented split (developer docs in `docs/`,
    shipped docs in `.cwf/docs/`); defer any file-moving consolidation to BACKLOG.

## Dependencies
- Ground-truth state of `.claude/skills/`, `.cwf/scripts/command-helpers/`,
  `.cwf/templates/pool/`, `.cwf/docs/workflow/workflow-steps/`, and the current version.

## Constraints
- Documentation-only change set; no behavioural code edits expected (so no hashed-script
  or `script-hashes.json` changes anticipated — flag as a stop if one proves necessary).
- British spelling in prose; no superlatives; no personal names in committed docs; "CwF"
  in prose (paths/namespaces keep their casing).
- Must itself go through the full CWF chore workflow (dog-fooding).

## Open Decisions
- **Scope breadth**: which docs are in-scope — the headline set (README, COMMANDS,
  CLAUDE, DESIGN, CWF-PROJECT-SPEC, INSTALL), or also the installed `.cwf/docs/` workflow
  and convention docs? Direction: headline + architecture docs (as Task 189); confirm at d.
- **Root `scratchpad.md`**: Task 189 intended to remove it as vestigial, yet it is still
  present — remove, gitignore, or keep? Resolve at d after checking whether it is tracked.
- **Version-example policy**: relabel illustrative version strings as "illustrative", or
  refresh them to the current era — pick one convention and apply it uniformly.
- **Count brittleness**: exact recounted numbers vs descriptive phrasing where a count adds
  no durable value — per-claim call at d.

## Decomposition Check
- [ ] **Time**: >1 week? No — roughly a day.
- [ ] **People**: >2 people? No — single maintainer.
- [x] **Complexity**: 3+ distinct concerns? Arguably (count fixes, command-syntax fixes,
      architecture-doc fixes, housekeeping) — but all are the same *kind* of work (text
      edits to docs) under one reviewer.
- [ ] **Risk**: High-risk components needing isolation? No.
- [x] **Independence**: Parts separable? Per-doc, yes — but weak evidence; the docs share
      counts/version facts cheaper to fix coherently in one pass.

**Decision**: Two weak signals present, both typical of a cohesive single-reviewer doc
sync. Keep as **one task**; structure the implementation plan by document so the work stays
legible. Spin DESIGN.md/consolidation work out to a subtask or BACKLOG only if it turns out
to need real redesign rather than a sync.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Completed as planned — headline-doc sync, 4 docs edited (CLAUDE.md, DESIGN.md, README.md,
CWF-PROJECT-SPEC.md); COMMANDS.md/INSTALL.md audited clean. All success criteria met; see
j-retrospective.md.

## Lessons Learned
The "23 skills" estimate here was a miscount (counted 2 loose `.md` fragments as commands);
reconciled to 21 dirs / 20 commands at d. Recount programmatically at exec, never copy prose.
