# readme-updates - Plan
**Task**: 91 (bugfix)

## Task Reference
- **Task ID**: internal-91
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/91-readme-updates
- **Template Version**: 2.1

## Goal
Update README.md to reflect the v1.0.90 release state: correct repo URL, v2.1
workflow commands and format, accurate task-type phase tables, new semver convention,
and a direct GitHub issues link.

## User Instructions (verbatim scope)
1. **Install URL** — change to `CodingWithFiles/coding-with-files`
2. **Project Status** — leave beta warning as-is (v1 is still beta)
3. **Workflow commands** — update for v2.1; add `/cwf-implementation-exec` and
   `/cwf-testing-exec`; remove all v2.0 references (deprecated)
4. **Task types** — update phase counts; note multiple workflows per type;
   give a feature task example
5. **Version information** — update to `v{major}.{minor}.{task_num}` convention;
   mention `cwf-manage list-releases`
6. **Support section** — link directly to GitHub issues

## Success Criteria
- [ ] Install URL points to `CodingWithFiles/coding-with-files`
- [ ] All 10 v2.1 workflow commands listed; no v2.0-only language remains
- [ ] Task type section shows correct v2.1 phase files with feature example
- [ ] Version section reflects Task 89 convention and `cwf-manage list-releases`
- [ ] Support section links to `https://github.com/CodingWithFiles/coding-with-files/issues`
- [ ] `cwf-manage validate` passes (no script/template changes, trivially true)

## Milestones
1. Targeted README edits applied (5 change areas)
2. Grep confirms no remaining `mattkeenan/coding-with-files` or `v2.0` references
3. Commit and validate

## Risks
- **Low**: v2.1 phase file list for each task type — confirm from template-copier output
  rather than guessing

## Decomposition Check
- [ ] No — single file, well-scoped, <1 hour

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 91
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 5 success criteria met. A 6th unplanned edit was applied (Features section v2.0 heading)
discovered during TC-3 grep check. All 10 TCs pass.

## Lessons Learned
Run "should be absent" greps at design time to enumerate all change sites before writing the design plan.
