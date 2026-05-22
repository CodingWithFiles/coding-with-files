# fix cwf-manage-fix-security test fixture - Plan
**Task**: 154 (bugfix)

## Task Reference
- **Task ID**: internal-154
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/154-fix-cwf-manage-fix-security-test-fixture
- **Baseline Commit**: d06ff854f077c620b394f3ae77eb107e3fbfcad8
- **Template Version**: 2.1

## Goal
Make `t/cwf-manage-fix-security.t`'s `build_fixture` provision every path the hash manifest tracks (not just `.cwf/`), so the clean-install/repair/idempotency cases stop reporting the manifest's `.claude/agents/*` entries as missing files.

## Problem Statement
`build_fixture` (`t/cwf-manage-fix-security.t:52`) copies only `$REPO_ROOT/.cwf` into the fixture, but `.cwf/security/script-hashes.json` also tracks 5 `.claude/agents/*.md` paths. `cmd_validate`/`cmd_fix_security` join each manifest `path` to the fixture git root (`cwf-manage:743`), so those 5 files resolve to missing → `existence` violations. This makes:
- **TC-1** (clean install → no-op, exit 0) fail — sees 5 missing files.
- **TC-2** (post-repair `validate` passes) fail — `validate` never clears.
- **TC-7** (idempotency, exit 0) fail — same root cause.

TC-3/4/5/6 expect exit 1 already (tamper/missing/unparseable), so the spurious missing-file violations are masked there. Reproduced identically at baseline `b5b8739` — pre-existing, not introduced by Task 153.

## Success Criteria
- [ ] `build_fixture` provisions all manifest-tracked paths outside `.cwf/` (the `.claude/agents/*` entries), not just `.cwf/`.
- [ ] `prove t/cwf-manage-fix-security.t` is fully green (all 7 subtests pass), TC-1/2/7 included.
- [ ] The fix derives the extra paths from the manifest (or a single declared list), so adding a new non-`.cwf/` tracked path does not silently re-break the clean-install cases.
- [ ] No production code changed — fix is confined to the test (`t/`); `prove t/` stays green overall and `cwf-manage validate` on the real repo is unaffected.

## Original Estimate
**Effort**: <0.5 day
**Complexity**: Low
**Dependencies**: None (test-only change; no hashed files touched)

## Major Milestones
1. **Reproduce**: Confirm TC-1/2/7 red on the current branch for the documented reason.
2. **Fix fixture**: Extend `build_fixture` to copy manifest-tracked non-`.cwf/` paths.
3. **Green**: All 7 subtests pass; full `prove t/` regression clean.

## Risk Assessment
### Medium Priority Risks
- **Risk 1**: Hard-coding `.claude/agents/` re-breaks the moment a future task tracks a new non-`.cwf/` path (e.g. `.claude/hooks/*`). Impact: silent regression of the same class of bug.
  - **Mitigation**: Prefer deriving the path set from the manifest itself (parse `script-hashes.json`, copy any tracked path whose first segment is not `.cwf`). Decide mechanism in design (c).

### Low Priority Risks
- **Risk 2**: `cp -rp` of `.claude/` wholesale would drag in machine-specific/un-tracked files (e.g. `settings.local.json`) and bloat the fixture.
  - **Mitigation**: Copy only manifest-referenced paths, mirroring the existing perm-preserving `cp -rp` approach per-file/dir.

## Dependencies
- None. Self-contained test fix.

## Constraints
- Test-only: do not modify `cwf-manage`, `CWF::Validate::*`, or any hashed file — that would change the integrity surface and is out of scope.
- Core Perl only; `#!/usr/bin/env perl`; preserve the perm-preserving `cp -rp` rationale already documented at `build_fixture` (line 54-56).
- POSIX, system Perl. No new test dependencies.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No.
- [ ] **People**: Does this need >2 people working on different parts? No.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — one function in one test file.
- [ ] **Risk**: Are there high-risk components that need isolation? No.
- [ ] **Independence**: Can parts be worked on separately? No.

**Verdict**: No decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 4 success criteria met. `build_fixture` provisions every non-`.cwf/` manifest path (derived from the manifest, not hard-coded); `prove t/cwf-manage-fix-security.t` 8/8 (TC-1/2/7 red→green, new TC-8 drift pin); `prove t/` 500 pass; `cwf-manage validate` unaffected (no production/hashed change). On estimate (<0.5 day).

## Lessons Learned
Binding the fixture's copy set to the manifest (the same source of truth the tool reads) is what makes the fix durable — see j-retrospective.md.
