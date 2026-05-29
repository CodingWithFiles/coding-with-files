# security-review cap weights production over tests - Plan
**Task**: 168 (chore)

## Task Reference
- **Task ID**: internal-168
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/168-security-review-cap-weight-production-code
- **Baseline Commit**: bcf37b4ec0bb36592f0dbd62721e4d6c977098e7
- **Template Version**: 2.1

## Goal
Make the exec-phase 500-line security-review cap measure production/security-relevant
code rather than raw unified-diff lines, so a change that ships its own test suite is
not falsely capped.

## Success Criteria
- [ ] The cap decision is driven by a single count emitted by
  `security-review-changeset`, not a separate `wc -l` re-count in the two exec
  SKILL.md files (single source of truth = the helper).
- [ ] Test/scaffolding lines are weighted below production lines in that count, by a
  rule documented in `.cwf/docs/skills/security-review.md`.
- [ ] A reconstructed task-166-shaped changeset (~197 production + ~234 test lines)
  falls under the cap; a production-only diff above the cap still trips it.
- [ ] `security-review-classify` and the subagent prompt are unchanged; existing
  `t/security-review-changeset.t` still passes.

## Original Estimate
**Effort**: ~1 day
**Complexity**: Medium
**Dependencies**: None (self-contained in helper + two SKILL.md + one doc)

## Major Milestones
1. **Decide the rule** (impl-plan): how a line is classified production vs test, and
   whether the cap check moves into the helper or the helper just emits a weighted
   count the skills consume. See Open Questions.
2. **Implement**: weighted count in `security-review-changeset`; update both exec
   SKILL.md Step 8 to consume it; document the rule in `security-review.md`.
3. **Test + regress**: unit coverage for the weighting; a task-166-shaped regression
   proving the under/over-cap boundary; output-level smoke check.

## Risk Assessment
### High Priority Risks
- **Test-vs-production identification is repo-specific**: the helper ships to consumer
  repos. CWF tests live under `t/` and enter the changeset via shebang-sniff;
  production enters via CWF-internal-prefix. A consumer's production script also
  matches shebang-sniff, so "included via shebang" is not a safe proxy for "test".
  - **Mitigation** (resolved): the repo owns the truth, not the helper. Test paths
    come from a `security.review.test-paths` list in `cwf-project.json` (gitignore/git
    pathspec syntax), matched by git's own `:(glob,exclude)` engine. Default unset ⇒
    no discount ⇒ today's behaviour (no regression for any repo); CWF self-configures
    `t/**`; consumers declare their own. Unknown/unconfigured layouts count as
    production (cap stricter, never weaker). Cross-language suffix coverage
    (`*_test.go` etc.) works via glob but is not exhaustively pursued — documented,
    fails safe.

### Medium Priority Risks
- **Cap moves from SKILL.md into helper → contract spans 3 call sites**: two exec
  skills plus `security-review.md` describe the 500-line behaviour today.
  - **Mitigation**: emit one named field from the helper; update all call sites in
    this one task; output-level smoke test per the rebrand lesson.
- **Discounting test lines could let a large production change slip review**.
  - **Mitigation**: only test lines are discounted; production-only diffs are
    unaffected; success criterion 3 guards the over-cap boundary explicitly.

## Dependencies
- None external. Touches `security-review-changeset` (hashed script — hash refresh in
  same commit per the hash-updates convention), the two exec SKILL.md files, and
  `.cwf/docs/skills/security-review.md`.

## Constraints
- Perl core modules only; helper remains the single source of truth.
- **Out of scope**: whether 500 is the right limit. This task changes *what* the cap
  measures, not the threshold value.

## Open Questions (resolved during plan review — see d-implementation-plan)
1. **Test-line rule** — RESOLVED: consumer-declared `security.review.test-paths`
   (gitignore/git pathspec patterns) in `cwf-project.json`, matched by git's
   `:(glob,exclude)` engine (no Perl-side matcher, no ReDoS surface). Default unset.
2. **Cap location** — RESOLVED: helper measures + enforces via `--max-lines=N`
   (exit 2); SKILLs set the threshold (`--max-lines=500`) and branch on the exit code.
3. **Weighting shape** — RESOLVED: production lines = added+deleted (`git diff
   --numstat`) over included files minus the test-path excludes; test lines weight 0.

## Decomposition Check
- [ ] **Time**: >1 week? No (~1 day).
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — count logic + skill/doc wiring (~2).
- [ ] **Risk**: high-risk components needing isolation? No.
- [ ] **Independence**: separable parts? No.

No decomposition: 0 signals triggered.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 168
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All four success criteria met; no decomposition (0 signals, as predicted). See `j-retrospective.md`.

## Lessons Learned
Front-loading the contentious categorisation design into plan review (before exec) meant the build was right first time. See `j-retrospective.md` § Process Learnings.
