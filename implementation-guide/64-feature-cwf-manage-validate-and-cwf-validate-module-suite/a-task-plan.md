# cwf-manage validate and CWF::Validate module suite - Task Plan
**Task**: 64 (feature)

## Task Reference
- **Task ID**: internal-64
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/64-cwf-manage-validate-and-cwf-validate-module-suite
- **Template Version**: 2.1

## Goal
Add a `cwf-manage validate` subcommand backed by a `CWF::Validate` module suite that validates all deterministic fields across config and workflow files, provides actionable error messages, and integrates as a post-skill guard into the workflow preamble.

## Success Criteria
- [ ] `cwf-manage validate` exits 0 on a clean repo, non-zero with a full violation list on a broken one
- [ ] Error messages name the file, field, and expected value so an agent can fix the problem without additional investigation
- [ ] `CWF::Validate::Config`, `CWF::Validate::Workflow`, `CWF::Validate::Consistency`, `CWF::Validate::Security` are independent modules callable individually
- [ ] Workflow preamble calls `cwf-manage validate` after each checkpoint commit (post-skill guard)
- [ ] `perlcritic --stern` passes on all new modules and the updated `cwf-manage`

## Major Milestones
1. **Module architecture** — define the four `CWF::Validate::*` modules and their public APIs
2. **CWF::Validate::Config** — `cwf-project.json` schema validation with actionable messages
3. **CWF::Validate::Workflow** — workflow step file field validation (status values, next-action, template version)
4. **CWF::Validate::Consistency** — cross-file consistency checks (task num vs dirname, branch vs git)
5. **CWF::Validate::Security** — consolidate existing security check logic
6. **cwf-manage validate** — thin wrapper calling all four modules
7. **Workflow preamble integration** — add post-skill guard to checkpoint commit step

## Risks
- **Existing security check logic duplication**: `/cwf-security-check` skill and `cwf-manage` both touch hashes. `CWF::Validate::Security` must consolidate without breaking either.
- **Workflow file format variations**: v1.0, v2.0, and v2.1 files coexist. Validators must not reject valid older formats.
- **Post-skill guard noise**: If validation is too strict it will fire on every skill and create friction. Validators must only flag genuine problems, not warn on optional fields.
- **Module load cost**: Four new modules add preamble startup overhead. Keep modules lean, load lazily where possible.

## Constraints
- All new Perl modules under `.cwf/lib/CWF/Validate/`
- No CPAN dependencies beyond what is already used in the codebase
- Error messages must include: file path, field name, expected value/format, and a suggested fix
- `cwf-manage validate` must report ALL violations before exiting, not just the first

## Decomposition Check
- 7 milestones, each independently testable — proceed as single task with clear milestone boundaries
- Subtasks only if a milestone reveals unexpected complexity mid-session

## Estimated Effort
- **Sessions**: 2-3
- **Complexity**: Medium-High (refactoring existing security logic + new modules + preamble integration)

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan 64
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned deliverables met. See j-retrospective.md for full variance analysis.

## Lessons Learned
See j-retrospective.md Key Learnings section.
