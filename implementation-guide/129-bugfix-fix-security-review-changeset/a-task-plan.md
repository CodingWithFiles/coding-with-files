# Fix security-review changeset construction - Plan
**Task**: 129 (bugfix)

## Task Reference
- **Task ID**: internal-129
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/129-fix-security-review-changeset
- **Template Version**: 2.1

## Goal
Make the exec-phase security-review subagent's changeset construction (a) classify files by content rather than extension, (b) avoid hardcoding this repo's language stack so CWF consumers are also covered, and (c) use a per-task baseline anchor that does not over-include earlier unmerged work or assume `main` is the trunk.

## Success Criteria
- [ ] A file with no extension but a `#!/usr/bin/perl` (or `#!/bin/bash`, etc.) shebang under a security-relevant directory is included in the review changeset, and a non-script binary in the same directory is excluded.
- [ ] The pathspec/discovery mechanism contains no hardcoded language extensions for non-CWF-internals (`*.py`, `*.go`, `*.rb`, `*.js` etc. work in a consumer repo without CWF-side edits) — verified by a synthetic-consumer-repo test case.
- [ ] The diff anchor returns the same line count for Task N's review whether or not Task N-1's branch is merged to main — verified by a regression test that constructs a synthetic repo with an unmerged predecessor branch.
- [ ] `.cwf/docs/skills/security-review.md` is the single source of truth for the changeset construction; `cwf-implementation-exec/SKILL.md` and `cwf-testing-exec/SKILL.md` reference it without duplicating the pathspec or anchor logic.
- [ ] Running this task's own g-testing-exec security review produces a changeset whose line count is bounded by *this task's* delta, not by the cumulative delta from the merge-base of `main`.

## Original Estimate
**Effort**: 1-2 days
**Complexity**: Medium — three independent failure modes that interact; the anchor change in particular has subtle ramifications for FF-only / squash / rebase consumers.
**Dependencies**: None hard. Soft: this task's own g-testing-exec is the first dogfood opportunity for the new changeset construction.

## Major Milestones
1. **Discovery / decision**: Pick the diff anchor strategy (per-task baseline ref written by `cwf-new-task` vs. previous wf step's checkpoint commit vs. task branch's first commit). Settle the content-classification mechanism (shebang sniff vs. `file --mime-type` vs. hybrid). Settle where the security-relevant directory set comes from (config file vs. computed from install layout).
2. **Implementation**: Extract the changeset-construction logic into a single helper (likely a Perl script under `.cwf/scripts/command-helpers/`) so the two exec SKILLs and the security-review doc all call it. Update the doc and SKILLs to reference it. Add the per-task baseline-ref write in `cwf-new-task` if that's the chosen anchor.
3. **Regression test**: Synthetic-repo test covering all three failure modes (extensionless script, non-CWF-stack file, unmerged predecessor). Wire into existing test infrastructure.
4. **Dogfood**: Run task 129's own g-testing-exec under the new changeset construction; confirm line-count is bounded and content classification works on this very change.

## Risk Assessment
### High Priority Risks
- **Risk 1**: Anchor strategy choice is reversible only at cost. If we pick "previous wf step's checkpoint commit" and a consumer doesn't use checkpoints branches, the anchor is undefined. If we pick "task branch's first commit", users who rebase onto main mid-task lose the anchor.
  - **Mitigation**: Decision belongs in c-design-plan with explicit consumer-policy enumeration. Prefer a per-task baseline ref written at `cwf-new-task` time and stored in `.git/refs/cwf/task-<num>-base` or in the task directory — survives rebase, doesn't depend on `main` existing.
- **Risk 2**: Content classification (shebang/`file --mime-type`) is slow if applied to every file in a large repo. Subagent runs already feel slow; making the discovery step measurably slower will push users back to disabling the gate.
  - **Mitigation**: Restrict content classification to files *changed in the diff window* — discovery runs against the diff output, not the whole tree.

### Medium Priority Risks
- **Risk 3**: The security-relevant directory set, if computed from install layout, leaks CWF-internals knowledge into the consumer's classification. A consumer's `src/` should also be covered, but CWF doesn't know it exists.
  - **Mitigation**: Hybrid — CWF-internal directories computed from install layout; consumer-side directories declared in `.cwf/security/review-paths.json` (or similar) with a sensible default ("everything in the diff that classifies as a script").
- **Risk 4**: Changing the diff anchor changes the line count, which affects whether existing tasks pass the 500-line cap. A retroactive change could make recently-completed task reviews look smaller (fine) or break the historical comparison the cap was justified against (covered by separate backlog item, but interacts).
  - **Mitigation**: Note interaction in c-design-plan; do not change the cap value here.

## Dependencies
- None blocking.
- Interacts with (does not depend on) the open backlog item "Quantitatively justify the security-review subagent line-count cap" — that task should be done *after* this one so the cap is justified against the correctly-scoped diff.

## Constraints
- Single-source-of-truth rule: the pathspec/anchor logic must live in exactly one place (`.cwf/docs/skills/security-review.md` referencing one helper script). The two exec SKILLs may reference but not duplicate.
- Must work in CWF-consumer repos with arbitrary language stacks; must not assume `main` exists or is the trunk.
- Must not regress existing checkpoint commit / squash workflow.
- POSIX-only; Perl + `git ... -z` per `docs/conventions/perl-git-paths.md`.

## Decomposition Check
- [ ] **Time**: Will this take >1 week? — No, scoped to ~1-2 days.
- [ ] **People**: Does this need >2 people? — No.
- [x] **Complexity**: 3+ distinct concerns? — Yes (extension→content classification, hardcoded-stack→discoverable directory set, merge-base anchor→per-task baseline). All three live in the same single helper, so decomposing into separate tasks would force multiple round-trips through the same file. Resolved as one task.
- [ ] **Risk**: High-risk components needing isolation? — Anchor choice is the riskiest piece; isolated by being a c-design-plan decision before implementation.
- [ ] **Independence**: Can parts be worked on separately? — Technically yes, but they share a target (the changeset-construction helper) and a regression test; splitting is churn.

**Decision**: Single task. The three issues compound and share a fix-site; the backlog entry already groups them; regression test covers them as a single matrix.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five success criteria met. Helper at `.cwf/scripts/command-helpers/security-review-changeset` covers the three BACKLOG axes; SSOT consolidated in `.cwf/docs/skills/security-review.md`; 13/13 new subtests PASS; 338/338 full regression PASS. f-phase smoke run on this branch reported `reviewed 8 files, 593 lines, anchor=9ac3f96` (success criterion 5 — diff bounded by this task's delta, anchored at `main` tip via fallback).

## Lessons Learned
Anchor strategy choice (Risk 1) was the riskiest decision. c-design originally proposed a custom git-ref namespace; user pushback during plan review pivoted to the markdown-field approach in `a-task-plan.md`. Cheaper than git-refs and self-documenting. Lesson: when a design reaches into `.git/`, ask whether the data could live in a regular file instead.
