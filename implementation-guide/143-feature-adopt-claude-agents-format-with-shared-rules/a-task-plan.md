# Adopt .claude/agents format with shared rules - Plan
**Task**: 143 (feature)

## Task Reference
- **Task ID**: internal-143
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/143-adopt-claude-agents-format-with-shared-rules
- **Baseline Commit**: 2b0d524856700d83870355905e45f8552c4775d0
- **Template Version**: 2.1

## Goal
Move CWF's plan-review, exec-review, and security-review subagents from inline-prompt-with-`subagent_type="Explore"` invocations to first-class `.claude/agents/{name}.md` definitions, with a single shared-rules surface that codifies the tool-use guardrails (e.g. "no `find … -exec grep …`; use Grep/ripgrep") so each new rule is added once and inherited by every agent.

## Success Criteria
- [ ] At least three CWF subagent roles (plan-reviewer, exec-reviewer, security-reviewer) are defined as `.claude/agents/{name}.md` files and invoked via `subagent_type=<name>` (no more `subagent_type="Explore"` + inline-prompt for these roles).
- [ ] A single shared-rules source exists and is referenced (not duplicated) by every CWF agent definition; adding a new rule requires one edit.
- [ ] The "blocking permission-prompt" anti-patterns currently leaking into subagent runs (`find -exec grep`, `find -exec cat`, `cat | grep`, `sed -n 'X,Yp'`) are explicitly named in the shared rules and demonstrably suppressed in at least one end-to-end run.
- [ ] Plan-review and exec-phase security-review continue to function (same outputs, same sentinel-line contract) after migration — no regression in the existing skills' contracts.
- [ ] `cwf-manage validate` passes on the new files (hashes recorded, permissions correct).

## Original Estimate
**Effort**: 2-3 days
**Complexity**: Medium
**Dependencies**:
- Existing prompt templates in `.cwf/docs/skills/plan-review.md` and `.cwf/docs/skills/security-review.md`
- Existing tool-selection convention in `.cwf/docs/conventions/subagent-tool-selection.md`
- Claude Code's `.claude/agents/{name}.md` format (frontmatter schema, allowed-tools list, system prompt)

## Major Milestones
1. **Inventory**: Enumerate every current CWF subagent invocation, the role it plays, and the tool grant it needs.
2. **Shared-rules surface defined**: Single source of truth for cross-agent guardrails (tool-tier preference, anti-patterns, output contracts) chosen and located.
3. **Agent definitions created**: One `.claude/agents/{name}.md` per role, each referencing the shared-rules surface.
4. **Skill call-sites migrated**: Plan-review and exec-review skills updated to invoke `subagent_type=<role>` instead of `Explore`+inline prompt.
5. **Integrity recorded**: Hashes registered, `cwf-manage validate` passes, smoke-tested end-to-end on this task's own plan files.

## Risk Assessment
### High Priority Risks
- **Risk: Silent contract drift**: Moving prompts from `.cwf/docs/skills/*.md` into `.claude/agents/*.md` could change subagent output format (e.g. sentinel-line behaviour), breaking the existing exec-phase classifier rules.
  - **Mitigation**: Migrate prompt text verbatim where possible; add a smoke test that runs each agent and greps for the expected sentinel patterns before declaring the migration done.
- **Risk: Shared-rules surface becomes a dumping ground**: If "shared rules" expands without a clear inclusion bar, agents inherit guidance irrelevant to their role and prompt quality degrades.
  - **Mitigation**: Define inclusion criteria up front in the requirements phase (the rule must apply to ≥2 agent roles AND have a recorded prior incident or convention doc). Borderline rules stay role-local.

### Medium Priority Risks
- **Risk: `.claude/agents/` format changes upstream**: Claude Code's custom-agent schema is relatively new; an upstream change could invalidate the frontmatter we write.
  - **Mitigation**: Keep frontmatter minimal; pin documented fields only; treat any future schema break as a separate maintenance task.
- **Risk: Tool-grant under-restriction**: Granting a subagent more tools than its role requires (e.g. Bash where Read+Grep+Glob suffices) re-opens the `find -exec` permission-prompt surface this task is meant to close.
  - **Mitigation**: Each agent definition declares the minimal tool list; the requirements phase locks "no Bash unless the role's prompt template requires it" as an explicit FR.

## Dependencies
- No external service or team dependencies; entirely internal to CWF.
- Implementation depends on Claude Code's existing `.claude/agents/` discovery (no upstream change required).

## Constraints
- Must preserve the existing sentinel-line contract for the security-review exec phase (`findings:` / `no findings` / `error:`); downstream classifier in `cwf-{implementation,testing}-exec` SKILLs depends on it.
- Must keep plan-review's map/reduce shape (4 parallel calls per plan); changing the fan-out is out of scope for this task.
- POSIX/macOS system-Perl portability rules still apply to any helper scripts touched.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? — No, scoped to 2-3 days.
- [ ] **People**: Does this need >2 people working on different parts? — No, single-maintainer task.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? — Borderline: (1) agent definitions, (2) shared-rules surface, (3) skill call-site migration. Tightly coupled; splitting would create coordination overhead larger than the work itself.
- [ ] **Risk**: Are there high-risk components that need isolation? — No, contract-preservation is the main risk and is mitigated by smoke-testing, not decomposition.
- [ ] **Independence**: Can parts be worked on separately? — Not cleanly; the shared-rules surface is a prerequisite for the agent definitions, which are a prerequisite for skill migration.

**Conclusion**: 0 firm signals (1 borderline). Proceed as a single task.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
