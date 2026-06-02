# Split workflow-steps into per-anchor docs - Implementation Execution
**Task**: 176 (chore)

## Task Reference
- **Task ID**: internal-176
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/176-split-workflow-steps-into-per-anchor-docs
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status to "Finished" when complete

## Actual Results

### Step 1: Create the per-anchor docs
- **Planned**: Create `.cwf/docs/workflow/workflow-steps/` and write 10 `{name}.md` files (H1 + up-link + verbatim body).
- **Actual**: Directory created; all 10 files written: planning, requirements, design, implementation-planning, implementation-execution, testing-planning, testing-execution, rollout, maintenance, retrospective. Each has `# Heading`, the up-link `> Part of the [Workflow Steps](../workflow-steps.md) reference.`, and the section body verbatim.
- **Deviations**: None.

### Step 2: Re-point the 8 skill references
- **Planned**: Update each SKILL.md to the new plain path (no `#anchor`).
- **Actual**: All 8 updated — task-plan→planning, requirements-plan→requirements, design-plan→design, implementation-plan→implementation-planning, testing-plan→testing-planning, rollout→rollout, maintenance→maintenance, retrospective→retrospective. The two latent broken anchors (`#implementation`, `#testing`) are now correct file paths.
- **Deviations**: None.

### Step 3: Rewrite workflow-steps.md as a ToC
- **Planned**: Keep intro + Version Differences + Status Values (anchor intact); replace 10 phase sections with a linked `## Steps` index.
- **Actual**: Done. File reduced from 461 lines to a ToC: title, intro (with a pointer to read the single relevant phase file), Version Differences, Status Values (`### Valid Status Values` anchor preserved), and a `## Steps` list linking all 10 docs. Per D2, status-values stays inline — its 12 referrers are untouched.
- **Deviations**: None.

### Step 4: Verify (results recorded in g-testing-exec.md)
- **Planned**: content diff, dangling-anchor sweep, link resolution, validate + integrity test.
- **Actual**: All TC-1..TC-8 pass (10 files present; bodies verbatim substrings of the original; one up-link each; 8 skill refs resolve with no `#`; zero dangling phase-anchor refs; `#status-values` target + 12 referrers intact; 10 ToC links resolve; `cwf-manage validate` OK; `installmanifest-integrity.t` 6/6 ok). Full detail in g-testing-exec.md.
- **Deviations**: None.

## Blockers Encountered
None.

## Deferral Check
Before marking status=Finished, verify:
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [ ] All requirements from b-requirements-plan.md addressed (N/A — chore, no requirements phase)
- [ ] All design guidance in c-design-plan.md followed (N/A — chore; decisions recorded in d-implementation-plan.md)
- [x] No planned work deferred without user approval
- [x] If work deferred: none

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
Verified the packaging assumption by reading `install.bash` rather than trusting it — both install paths copy `.cwf/` recursively, so the new subdir ships with no manifest edit. Assumption confirmed, not presumed.

## Security Review

**State**: no findings

## Security review — implementation phase

This changeset is a pure documentation/reference refactor: it splits the monolithic `.cwf/docs/workflow/workflow-steps.md` into 10 per-phase files under `workflow-steps/`, repoints 8 SKILL Step-5 links from `workflow-steps.md#<anchor>` to `workflow-steps/<name>.md`, and adds an index list plus three CWF task documents. I verified the actual tree state rather than relying solely on the diff text, since the 10 new per-step files are untracked and absent from the supplied diff.

Reasoning across the threat categories:

- **(a) Bash injection / unsafe command construction** — No shell, no `system()`, no command construction anywhere in the changeset. Not applicable.
- **(b) Perl helpers consuming git/user output** — No Perl, no scripts, no git-output parsing touched. The 10 new files and the 8 edits are markdown only. Not applicable.
- **(c) Prompt injection via user-supplied strings** — The new per-step files are static reference prose pulled verbatim into LLM context by the Step-5 reads. They contain no `{arguments}` substitution token and no instruction-injection vectors beyond what the pre-existing monolithic doc already carried — the content is byte-relocated, not authored fresh. No new untrusted-string flow is introduced.
- **(d) Unsafe environment-variable handling** — No env vars, no `chmod`/`rm`/`open`/clone paths touched. Not applicable.
- **(e) Pattern-based risks** — None. This is inert documentation.

Refactor-correctness checks (a dangling live link is the only plausible defect class here): all 8 SKILL link targets resolve on disk; all 10 new files carry a resolving `../workflow-steps.md` up-link; the ToC lists 10 valid links; the `#status-values` anchor was retained so its 12 referrers still resolve. No hash-tracked scripts, permissions, or `script-hashes.json` entries are involved.

No security concerns.

```cwf-review
state: no findings
summary: Pure markdown doc-split refactor; no executable/script/env/injection surface; all repointed and retained links resolve.
```
