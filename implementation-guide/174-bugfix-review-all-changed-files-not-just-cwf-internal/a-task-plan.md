# review all changed files not just cwf-internal - Plan
**Task**: 174 (bugfix)

## Task Reference
- **Task ID**: internal-174
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/174-review-all-changed-files-not-just-cwf-internal
- **Baseline Commit**: c8868565322645ba0be4a15a9102f8f3be8764ac
- **Template Version**: 2.1

## Goal
Make the exec-phase security review cover **every** file in the task's git diff, removing the CWF-internal/shebang classifier that silently excludes consumer application code.

## Problem Statement
`security-review-changeset` classifies each changed file and emits to the
review subagent only those that are (a) under a hardcoded CWF-internal prefix
(`.cwf/`, `.claude/`) or (b) carry a script shebang from a fixed interpreter
list. Any other changed file — a consumer's `config.go`, `app.ts`, `Main.java`,
or any compiled-language source — is excluded by construction. For a project
that is not itself a pile of shell/Perl scripts, the gate emits
`reviewed 0 files` and the workflow reads that as a clean pass. The feature's
entire purpose — reviewing the code the user is shipping — is the one thing it
never does. This is a correctness defect in a shipped, user-facing gate, not a
documented limitation.

## Success Criteria
- [ ] The emitted changeset contains the full `git diff` (anchor → worktree) over **all** changed files, with no path/shebang/language classification.
- [ ] The `--max-lines` cap measures production-weighted lines only: added+deleted across all changed files **minus** paths matching `security.review.test-paths` globs.
- [ ] Test code is reviewed (appears in the emitted diff) but does **not** count toward the cap.
- [ ] A genuinely empty diff (no changed files) still yields exit 0, `reviewed 0 files`.
- [ ] The contract doc (`.cwf/docs/skills/security-review.md`) and the helper header are updated to describe review-all-files behaviour; the now-false "single source of truth for what counts as security-relevant" framing is corrected.
- [ ] **All** documents — internal or shipped — that describe the security review are swept so that none state or imply the review is scoped to CWF-internal code only. The design phase enumerates the full document set (grep sweep); no surviving text may frame the gate as CWF-internal-only.
- [ ] `script-hashes.json` refreshed for the edited helper in the same commit (per hash-updates convention).

## Original Estimate
**Effort**: <1 day
**Complexity**: Low (predominantly deletion + doc correction)
**Dependencies**: None

## Major Milestones
1. **Helper fix**: Remove the classifier; included set = all changed files; verify cap math runs over all files minus test-path excludes.
2. **Doc + header correction**: Update `security-review.md` and the helper's header comment to match.
3. **Tests + hash refresh**: Extend `t/security-review-changeset.t` for the all-files behaviour; refresh `script-hashes.json`.

## Risk Assessment
### High Priority Risks
- **Risk 1**: Larger changesets now reach the cap and exit 2 where they previously passed empty — surfacing as workflow "error" on tasks that touch lots of non-script code.
  - **Mitigation**: This is the correct, intended behaviour (the gate was previously blind). The `--max-lines=500` cap + `test-paths` exclusion already exist to manage volume; document that hitting the cap means "review manually / split the task", not "feature broken".

### Medium Priority Risks
- **Risk 2**: Removing `is_cwf_internal`/`looks_like_script` could orphan callers or tests that asserted the old classification.
  - **Mitigation**: Grep for all references to the deleted subs/constants before removal; update `t/security-review-changeset.t` cases that encoded the old filter.

## Dependencies
- None — self-contained change to one helper, its doc, and its test.

## Constraints
- Perl core-modules only; `use utf8;`; git path output via `-z`. (Existing helper already complies.)
- Hash refresh must land in the same commit as the helper edit (hash-updates convention).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — <1 day.
- [ ] **People**: Does this need >2 people working on different parts? No.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — one helper, its doc, its test.
- [ ] **Risk**: Are there high-risk components that need isolation? No.
- [ ] **Independence**: Can parts be worked on separately? No — helper/doc/test move together.

**Conclusion**: 0 signals triggered. No decomposition; proceed as a single task.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All seven success criteria met. The classifier was deleted (helper net −156 lines);
the cap measures production lines minus `max-lines-exclude-paths` globs; test/doc
code is reviewed but not counted; empty diff still yields exit 0 / `reviewed 0 files`;
docs swept of CWF-internal-only framing; hashes refreshed in-commit. Two unplanned
additions during exec: a config-key rename (`test-paths` → `max-lines-exclude-paths`,
with back-compat fallback) and reconciliation of two test files coupled to the deleted
`@CWF_INTERNAL_PREFIXES` symbol. Full suite 643 tests green; both exec security reviews
`no findings`. See j-retrospective.md for variance analysis.

## Lessons Learned
Estimate (<1 day, Low) ran over because the cap fired on the task's own changeset
(706 > 500), surfacing a config-key misnomer, and a deleted internal symbol was
referenced by tests outside the co-located file. Risk 1 (cap fires where empty passed)
and Risk 2 (orphaned references) both materialised — Risk 2's grep-before-removal
mitigation was scoped to source, not test assertions. See j-retrospective.md.
