# Add installation instructions - Retrospective
**Task**: 60 (chore)

## Task Reference
- **Task ID**: internal-60
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/60-add-installation-instructions
- **Template Version**: 2.1
- **Retrospective Date**: 2026-02-15

## Executive Summary
- **Duration**: 1 session (~2 hours including external testing)
- **Scope**: Expanded from original — external testing revealed the subtree nesting issue, leading to a rewrite of the subtree method. Four backlog items added.
- **Outcome**: INSTALL.md shipped with both methods documented and tested. This is an intentionally incomplete implementation — Task 61 will add the install script and release management tooling.

## Variance Analysis
### Scope Changes
- **Additions**:
  - Two-split subtree approach (discovered via external testing that single-prefix subtree causes `.cwf/.cwf/` nesting)
  - Explicit permission fix step for file copy method
  - Four BACKLOG items from testing findings
- **Removals / Deferred to Task 61**:
  - `curl | bash` install script
  - Tag-based release management
  - Automated update/rollback tooling

### Quality Metrics
- **Test Coverage**: 11/11 test cases pass
- **External Validation**: Both install methods tested against a real external repo
- **Defects Found**: 0 in INSTALL.md itself; 3 pre-existing issues logged to BACKLOG

## What Went Well
- External repo testing caught the `.cwf/.cwf/` nesting issue before shipping — would have been a poor first experience for users
- `git subtree split` two-prefix approach verified with a concrete test (`/tmp/cwf-subtree-test`) — both install and update confirmed working
- The symlink approach for skills (from the first external test) informed the final two-split design
- Backlog items captured promptly as issues were found, not deferred to memory

## What Could Be Improved
- Initial INSTALL.md shipped with a broken subtree method (single-prefix) — external testing was essential to catch this. The testing plan only validated paths and syntax, not the actual install flow.
- Should have tested the subtree approach in a scratch repo before writing the docs
- The task was scoped as a chore but the external testing and subtree redesign pushed it closer to feature complexity

## Key Learnings
### Technical Insights
- `git subtree split` runs entirely consumer-side — no maintainer publishing needed
- Two subtree splits from one repo into one target works cleanly (verified)
- `cp -r` normalises permissions; git clone preserves them — important distinction for install docs
- CWF's distributable files span two directory trees (`.cwf/` and `.claude/skills/cwf-*/`), which complicates single-prefix subtree installs

### Process Learnings
- External repo testing is essential for installation documentation — desk-checking paths and syntax is not sufficient
- Agent-initiated skill invocation works identically to user-initiated — validated during external testing

## Recommendations
### Future Work (Task 61)
- `install.bash` script: `curl | bash` bootstrap that automates both install methods
- Tag-based release management with update/rollback support
- This should be a full feature task (requirements, design) given the scope

### BACKLOG Items Added
1. **Audit /cwf-init for obsolete category subdirectories** (chore, medium)
2. **template-copier-v2.1 undef warnings** (bugfix, high)
3. **/cwf-init should run security check and fix permissions** (bugfix, low)
4. **Add status update helper script** (feature, low)

## Status
**Status**: Finished
**Next Action**: Checkpoints branch and squash
**Blockers**: None
**Completion Date**: 2026-02-15

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- INSTALL.md — installation guide (repo root)
- README.md — updated Installation section
- BACKLOG.md — 4 items added
- `/tmp/cwf-subtree-test` — subtree two-split verification
