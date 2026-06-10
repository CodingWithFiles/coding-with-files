# Retire vestigial cwf-project.json version field - Retrospective
**Task**: 188 (chore)

## Task Reference
- **Task ID**: internal-188
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/188-retire-vestigial-cwf-projectjson-version-field
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-10

## Executive Summary
- **Duration**: ~single session (estimated ~0.25 day; broadly on estimate despite a mid-exec scope addition)
- **Scope**: Planned = retire top-level `version` from template + live config + guard test. Final = that **plus** `CWF-PROJECT-SPEC.md` (5 references), folded in at exec time after the baseline scan found the spec declared `version` *required*. Still strictly `version`-only.
- **Outcome**: Success. The second version claimant is gone from this repo and future installs; drift is now structurally impossible. `cwf-manage validate` clean; guard test locks the field out.

## Variance Analysis
### Time and Effort
- **Estimated**: ~0.25 day, Low complexity (planning + exec + testing only — chore skips b/c/h/i).
- **Actual**: Roughly on estimate. The deletion itself was trivial; the variance was investigative, not implementation — surfacing the spec dependency, and triaging pre-existing repo-state noise (perm drift, lagging statuses, fix-security TC-8) to prove none was caused by this change.
- **Variance**: Effort ≈ estimate; composition shifted from "edit" to "verify". Acceptable for a deletion whose whole risk is "did anything read this?".

### Scope Changes
- **Additions**:
  - `CWF-PROJECT-SPEC.md` edits (root-object schema, `#### version (required)` block, 2 config examples, Required-Fields list). Rationale: the spec is the authoritative contract; retiring the field while the spec still lists it as required would ship the exact spec/implementation drift the task removes. Surfaced to the user, approved ("fold spec into task").
- **Removals**: None beyond the deferred-by-design tail (`cwf-version`/`_cwf-version-note`, `security.version-tracking`) — out of scope from the outset.
- **Impact**: Small. Five mechanical, `version`-only doc edits; no behaviour, no new code, no hash records.

### Quality Metrics
- **Test Coverage**: New guard test `t/cwf-project-template.t` (parse-loudly + `version`-absent). No coverage-% target (deletion, not new logic).
- **Defect Rate**: Zero behavioural defects. One self-inflicted test-authoring bug during bring-up (UTF-8 decode layer vs `decode_json` byte input → "Wide character"), fixed immediately with a raw-byte slurp.
- **Performance**: N/A.

## What Went Well
- **The baseline reader-scan earned its keep.** The Step 1 bare-string sweep (broader than the impl-plan's code-reader grep) caught `CWF-PROJECT-SPEC.md` declaring `version` required — exactly the "hidden consumer the grep missed" medium risk from a-task-plan, in a benign documentation form. Caught before shipping drift.
- **Deviation handled by the book**: surfaced the discovery, asked rather than silently expanding the reviewed changeset, recorded it in `d-implementation-plan.md` as an exec-time addition.
- **Pre-existing failures triaged honestly**: stashed working changes to prove the two failing test files fail identically on baseline; fixed permission drift on sight; did not absorb or mask anything.
- **Security review**: both exec changesets → no findings; pure surface reduction.

## What Could Be Improved
- **The spec gap should have been caught at implementation-plan time, not exec time.** The plan's reader-verification was scoped to *code* readers (`$config->{version}`); it did not sweep documentation/spec files that assert the field's contract. Had the impl-plan grep been the broader bare-string scan from the outset, `CWF-PROJECT-SPEC.md` would have been in the reviewed file set and the deviation avoided.
- **Pre-existing repo noise cost triage time**: lagging `Planning` statuses on this task's own plan files, a stale agent-file permission, and the fix-security TC-8 floor/ceiling mismatch all surfaced through this task's `validate` runs though none belonged to it.

## Key Learnings
### Technical Insights
- **"Zero readers" must include the spec.** A field with no *code* reader can still be a *documented contract*. Retirement is only complete when the artefact that declares the field (here, `CWF-PROJECT-SPEC.md`) is updated too — otherwise you trade a data drift for a doc drift.
- **`decode_json` wants UTF-8 bytes, not decoded characters.** Slurp with `<:raw` and let `decode_json` decode; an `:encoding(UTF-8)` layer double-handles and throws "Wide character in subroutine entry".
- **CWF permission model is a ceiling, not a floor** (Task 170): `validate` accepts 0400 against a recorded 0444. A test asserting a 0444 *floor* (fix-security TC-8) contradicts that model — a latent test/model inconsistency.

### Process Learnings
- **Reader-verification grep belongs at plan time and should be bare-string, not deref-shaped.** Promote the exec-time Step 1 breadth into the implementation-plan's verification step for any "remove a field/symbol" task.
- **Transient `Planning` status trips whole-repo `validate`.** Marking completed phases `Finished` as they complete (not only at the retrospective sweep) keeps `validate` — and any test that shells out to it — clean mid-task.

### Risk Mitigation Strategies
- The a-task-plan Risk-1 mitigation ("re-run the reader grep") was the right instinct and is what caught the spec — it just fired one phase later than ideal. Pulling it forward to plan time is the actionable refinement.

## Recommendations
### Process Improvements
- For "retire a field/symbol" tasks, make the plan-time verification an explicit **bare-string, all-file-types** sweep (code + docs + specs + templates), and enumerate every artefact that *documents* the symbol in Files-to-Modify, not just the ones that *read* it.

### Tool and Technique Recommendations
- Keep the stash-and-rerun technique for distinguishing pre-existing failures from regressions; it gave a clean, defensible "not mine" verdict on fix-security TC-8.

### Future Work
1. **Retire remaining vestigial version fields** — `cwf-version`/`_cwf-version-note` in the template and `security.version-tracking` in the live config (the deferred narrow-scope tail).
2. **Reconcile fix-security TC-8 floor-vs-ceiling** — the test asserts agent `.md` files meet a 0444 floor while `cwf-manage validate` (ceiling model, Task 170) is content with 0400; the two disagree and the test fails on a clean tree.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-10
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Plan/exec artefacts: `a-task-plan.md`, `d-implementation-plan.md`, `e-testing-plan.md`, `f-implementation-exec.md`, `g-testing-exec.md` (this directory).
- Commits: `16424ba` (implementation-exec), `98b00e5` (testing-exec), plus the planning checkpoints.
- Security-review changesets/outputs: `/tmp/-home-matt-repo-coding-with-files-task-188/security-review-*-{implementation,testing}-exec.out`.
