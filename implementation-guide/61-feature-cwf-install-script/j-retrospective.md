# CWF install script and release management - Retrospective
**Task**: 61 (feature)

## Task Reference
- **Task ID**: internal-61
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/61-cwf-install-script
- **Template Version**: 2.1
- **Retrospective Date**: 2026-02-16

## Executive Summary
- **Duration**: 2 sessions (estimated: 1-2 sessions, variance: on target)
- **Scope**: Original scope plus a full process rework (b→g) after testing exposed a design flaw. Final deliverables match original success criteria.
- **Outcome**: All 6 success criteria met. Bootstrap script and management script fully functional with 28/28 tests passing.

## Variance Analysis
### Time and Effort
- **Estimated**: 1-2 sessions across all phases
- **Actual**: 2 sessions
  - Session 1: Planning (a), requirements (b), design (c), implementation plan (d), testing plan (e), implementation exec (f), testing exec (g) — pass 1. Testing revealed `.claude/skills/` clobbering bug. Process rework: requirements (b), design (c), implementation plan (d), testing plan (e) — pass 2.
  - Session 2: Implementation exec (f) pass 2, testing exec (g) pass 2, perlcritic cleanup, retrospective (j).
- **Variance**: Within estimate. The rework was absorbed because the structured process made each phase fast on the second pass — requirements and design changes were targeted, not from-scratch.

### Scope Changes
- **Additions**:
  - `.cwf-skills/` staging prefix with symlinks (replaced direct `.claude/skills/` subtree prefix). This was the major scope change, driven by the requirement to preserve existing consumer skills.
  - Perlcritic stern compliance (explicit `return` statements, dispatch table).
- **Removals**:
  - Release tagging (Step 5 of implementation) — deferred to post-merge, as planned.
- **Impact**: The staging prefix change touched all workflow files (b through g) but did not extend the timeline because the rework was systematic.

### Quality Metrics
- **Test Coverage**: 28/28 test cases pass (100%)
- **Defect Rate**: Pass 1: 5 bugs found during testing. Pass 2: 0 bugs found — the structured rework eliminated all issues before testing.
- **Perlcritic**: Clean at severity 4 (stern). 14 remaining violations at severity 3 (harsh) — backtick operators, regex `/x` flags — logged in BACKLOG as very low priority.

## What Went Well
- **Structured rework process**: Going through b→g again (rather than ad-hoc patching) caught every file that needed updating. Zero bugs in pass 2 vs five in pass 1.
- **User-driven design insight**: The `.cwf-skills/` staging prefix was identified by the user during testing review. This is exactly the kind of real-world constraint that testing should surface.
- **Two-language design**: Bash for bootstrap (curl|bash convention), Perl for management (consistent with CWF helpers) was clean and appropriate.
- **Test environment reuse**: Bare clone with test tags worked well for both passes.

## What Could Be Improved
- **Pass 1 requirements missed the constraint**: The requirement to preserve existing `.claude/skills/` was implied in the constraints but contradicted by FR2's design (using `.claude/skills/` as a subtree prefix). The requirements phase should have caught this inconsistency.
- **Process rework overhead**: While the rework was fast, it required updating 6 workflow files. A more thorough requirements analysis could have avoided it entirely.

## Key Learnings
### Technical Insights
- `git subtree add --prefix=X` requires the prefix directory to NOT exist beforehand — no `mkdir -p` before subtree add.
- Force reinstall needs both `git rm` (tracked files) AND unconditional `rm -rf` (untracked files). The `||` fallback pattern (`git rm ... || rm -rf ...`) is insufficient because `git rm` can "succeed" while leaving untracked files.
- Branch refs in a clone exist as `origin/<branch>`, not local `<branch>`. Ref resolution must fall back to `origin/$ref`.
- Relative symlinks (`../../.cwf-skills/cwf-*`) are portable and work correctly from `.claude/skills/`.
- `IPC::Open3` is core Perl (since 5.000) but adds significant verbosity for simple command captures. Backticks are pragmatic for read-only git commands.

### Process Learnings
- The CWF workflow process (b→g) pays for itself when a rework is needed — each phase is fast because the template structure guides what to update.
- User review during testing is valuable — the staging prefix insight came from the user examining TC-6 results.
- Perlcritic should be run during implementation, not as an afterthought. Consider adding it to the testing plan template.

### Risk Mitigation Strategies
- The "curl | bash security perception" risk (rated Low) was mitigated by documenting the download-then-inspect alternative. No issues.
- The "agent compatibility" risk (rated Medium) was validated by the `[CWF]`-prefixed stderr output with no ANSI codes.

## Recommendations
### Process Improvements
- **Add perlcritic to testing plans**: For tasks that modify Perl scripts, include perlcritic at target severity level as a test case.
- **Cross-reference constraints against FRs**: During requirements, explicitly verify each constraint is not contradicted by any FR.

### Tool and Technique Recommendations
- **Bare clone + test tags**: Effective pattern for testing install scripts. Reusable for future install/upgrade testing.

### Future Work
- **Perlcritic level 3 compliance**: Replace backtick operators with `IPC::Open3`, add `/x` to regexes. Very low priority. (Added to BACKLOG.)
- **Release tagging**: Create first semver tag on main after merge. Required for `CWF_REF=latest` to work in production.
- **Agent end-to-end test**: Run the full install + `/cwf-init` + first task workflow with an agent to validate FR6/AC6.

## Status
**Status**: Finished
**Next Action**: Merge to main
**Blockers**: None
**Completion Date**: 2026-02-16

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Branch: `feature/61-cwf-install-script`
- Key files: `scripts/install.bash`, `.cwf/scripts/cwf-manage`, `INSTALL.md`
- Test results: `g-testing-exec.md` (28/28 PASS)
- Workflow files: `a-task-plan.md` through `j-retrospective.md`
