# Template Reference Linter for Pre-Commit Hook - Implementation Execution
**Task**: 165 (chore)

## Task Reference
- **Task ID**: internal-165
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/165-template-reference-linter-for-pre-commit-hook
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [ ] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [ ] Verify all prerequisites met
- [ ] Execute implementation steps sequentially
- [ ] Update "Actual Results" for each step
- [ ] Document any deviations from plan
- [ ] Update status to "Implemented" when complete

## Implementation Steps (from d-implementation-plan.md)

### Step 1: Baseline confirmation
- **Planned**: Re-run the scoped scan to confirm the 4 D6 hits are the fix target.
- **Actual**: Confirmed exactly 4 (V21.pm:19-20, workflow-steps.md:272,319) with BACKLOG/CHANGELOG excluded.

### Step 2: Core module `CWF::Validate::TemplateRefs`
- **Planned**: KNOWN set from pool + V21 + V20 + migration map; anchored scan; fail-closed minimum; violation hashrefs.
- **Actual**: Created `.cwf/lib/CWF/Validate/TemplateRefs.pm` with `validate($git_root)` returning `{category,file,field,actual,expected,fix}` hashrefs (sibling contract). KNOWN derived at runtime; pool via `opendir` (avoids glob whitespace edge); `workflow_file_mappings()` arrayref dereferenced; empty-`old` entry guarded; fail-closed `die` asserts `a-task-plan.md`/`f-implementation-exec.md`/`e-testing.md`. Scan uses list-form `git ls-files -z` with `:!implementation-guide :!BACKLOG.md :!CHANGELOG.md`; raw read (POD/comments included, so the V21 orphans are catchable).
- **Deviations**: None from the revised plan.

### Step 3: Test `t/validate-template-refs.t`
- **Planned**: TC-1…TC-7 + fail-closed.
- **Actual**: 10 subtests (TC-1..TC-7, TC-6b implementation-guide exclusion, KNOWN-minimum, real-repo integration). Fixtures are `git init`+`git add` temp repos (ls-files needs only the index, no commit/identity). `.t` extension is out of scope, so fixture literals do not self-trip.

### Step 4: Wire-in + orphan fixes
- **Planned**: register in cwf-manage; fix V21.pm POD + workflow-steps.md; refresh hashes.
- **Actual**: Added `use` + `@all_violations` entry in `cwf-manage`. Fixed V21.pm POD (`e-implementation-exec.md`→`f-implementation-exec.md`, `f-testing-plan.md`→`e-testing-plan.md`) and workflow-steps.md (v2.0 testing is `e-testing.md`, not `f-testing-plan.md`; removed incorrect "moved from f position"). Refreshed `script-hashes.json`: new entry for `TemplateRefs.pm`, updated `cwf-manage` and `V21.pm` (computed via `sha256sum`).

### Step 5: Validation
- **Actual**: `prove t/validate-template-refs.t` → 10/10. `cwf-manage validate` → OK (new check self-scans clean once tracked). Full `prove t/` → 52 files, 610 tests, all pass. Perms unchanged (cwf-manage 0700; .pm modules 0600 like siblings).

## Blockers Encountered

None.

## Deferral Check
Before marking status=Finished, verify:
- [ ] All steps from d-implementation-plan.md executed
- [ ] All success criteria from a-task-plan.md met
- [ ] All requirements from b-requirements-plan.md addressed (if applicable)
- [ ] All design guidance in c-design-plan.md followed (if applicable)
- [ ] No planned work deferred without user approval
- [ ] If work deferred: Follow-up task created and linked

**If deferral required**: Get user approval, document rationale, create follow-up task.

## Security Review

**State**: no findings

## Security review — Task 165, implementation phase

Reviewed the full changeset against the five threat categories. Trust boundary: the sole input to `validate()` is `$git_root` (git-canonical, from `git rev-parse --show-toplevel`), never user free-text.

- **(a) Bash injection**: only external command is list-form `open '-|','git','-C',$git_root,'ls-files','-z','--',...` — no shell, no `system($string)`/backticks/qx. Clean.
- **(b) Git output without -z**: `ls-files -z` + `local $/="\0"` + chomp NUL + skip empty; `_slurp` `<:raw` with `next unless defined`. Content split on `\n` is intentional line-numbering, not path parsing. Correct.
- **(c) Prompt injection**: N/A — deterministic linter, output to terminal via printf, not LLM context; fields constrained by the `[a-j]-[a-z][a-z-]*\.md` grammar.
- **(d) Env-var handling**: reads no env vars; read-only module (opendir/open '<'/ls-files); nothing mutates state.
- **(e) Patterns**: `-C $git_root` safe (git-canonical, not user-influenced) — defensive note for hypothetical future callers; fail-closed `die` on under-populated KNOWN is a positive property ("surface, never smooth").

Other files: V21.pm POD-text-only; cwf-manage two-line wiring (sibling contract); test-only `.t`. No actionable security concerns.

```cwf-review
state: no findings
summary: Read-only linter, git-canonical trust boundary, list-form spawn + -z git paths, fails closed; (e) notes are defensive only.
```

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] No planned work deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
