# Split workflow-steps into per-anchor docs - Testing Plan
**Task**: 176 (chore)

## Task Reference
- **Task ID**: internal-176
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/176-split-workflow-steps-into-per-anchor-docs
- **Template Version**: 2.1

## Goal
Verify the split is content-preserving, the 8 skill references resolve to real files,
no reference dangles, and the system still validates — i.e. the `sed`-free single-`Read`
property holds.

## Test Strategy
This is a documentation/reference refactor: no code paths change. Verification is by
content diffing, link resolution, and the existing test/validate suite (regression).
"Coverage" = every new file and every changed reference is checked.

## Test Cases (Given/When/Then)

### TC-1: All 10 per-anchor files exist
- **Given**: the split is implemented
- **When**: listing `.cwf/docs/workflow/workflow-steps/`
- **Then**: exactly the 10 mapped files exist (planning, requirements, design,
  implementation-planning, implementation-execution, testing-planning,
  testing-execution, rollout, maintenance, retrospective).

### TC-2: Content-preserving (no prose drift)
- **Given**: each new file vs its original H2 section in the baseline `workflow-steps.md`
- **When**: diffing the body (ignoring the promoted `#` heading, the added up-link line, and dropped `---`)
- **Then**: the section body is byte-identical — no sentence added, dropped, or reworded.

### TC-3: Each anchor doc has the up-link
- **Given**: each of the 10 files
- **When**: reading the top
- **Then**: it contains `[Workflow Steps](../workflow-steps.md)` exactly once, near the title.

### TC-4: Skill references resolve to real files (the core fix)
- **Given**: the 8 updated SKILL.md references
- **When**: extracting each `workflow-steps/...md` path and testing it on disk
- **Then**: every path exists; none contains a `#` anchor; the file Read returns only that phase's guidance (no over-read, no shell needed).

### TC-5: No dangling references repo-wide
- **Given**: the whole tracked tree excluding `implementation-guide/`, `BACKLOG.md`, `CHANGELOG.md`
- **When**: `git grep` for `workflow-steps.md#<removed-anchor>` (planning, requirements, design, implementation, testing, rollout, maintenance, retrospective)
- **Then**: zero matches.

### TC-6: status-values references intact (D2)
- **Given**: the rewritten `workflow-steps.md`
- **When**: checking the 12 `#status-values` referrers + the `#status-values` anchor target
- **Then**: the `Status Values` section (and `### Valid Status Values` anchor) still exists in `workflow-steps.md`; all 12 referrers are unchanged and resolve.

### TC-7: ToC links are complete and valid
- **Given**: the rewritten `workflow-steps.md`
- **When**: extracting every relative link to `workflow-steps/*.md`
- **Then**: all 10 files are linked, and every link target exists on disk.

### TC-8: Regression — validate + test suite
- **Given**: the full change staged/committed
- **When**: running `.cwf/scripts/cwf-manage validate` and the relevant `t/*.t` (esp. `t/installmanifest-integrity.t`)
- **Then**: all pass — the new docs subdir does not break manifest integrity or permissions.

## Test Environment
- Local repo; `git`, `git grep`, `diff`, and the project `t/` harness. No DB, no network.

## Validation Criteria
- [ ] TC-1..TC-8 all pass
- [ ] `git grep` dangling-anchor sweep returns zero
- [ ] `cwf-manage validate` OK
- [ ] Output-level check: open one skill's target file and confirm a single `Read` yields complete phase guidance

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
TC-1..TC-8 all PASS (recorded in g-testing-exec.md). The content-preservation case (TC-2) was the highest-value test — it caught nothing because the move was clean, but it converted "copied carefully" into a verifiable assertion.

## Lessons Learned
TC-2's checker must pin the baseline commit, not `HEAD`: a re-run against the moved `HEAD` produced a false red. The test plan should have specified the baseline SHA as the comparison anchor explicitly.
