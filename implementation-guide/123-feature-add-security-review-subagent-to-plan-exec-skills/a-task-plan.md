# Add security-review subagent to plan/exec skills - Plan
**Task**: 123 (feature)

## Task Reference
- **Task ID**: internal-123
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/123-add-security-review-subagent-to-plan-exec-skills
- **Template Version**: 2.1

## Goal
Bake a security-review subagent into both the plan-review map/reduce (currently improvements/misalignment/robustness) and the implementation-exec / testing-exec phases, so security concerns get flagged at design time *and* against the actual code, not as a post-hoc afterthought.

## Success Criteria
- [ ] `.cwf/docs/skills/plan-review.md` extended from 3 to 4 subagents (add **security**); criteria-lookup table covers all three plan types (requirements, design, implementation)
- [ ] `.claude/skills/cwf-implementation-exec/SKILL.md` and `.claude/skills/cwf-testing-exec/SKILL.md` invoke a security-review subagent against the just-implemented code, using a single shared prompt template (canonical doc — no copy-paste between the two skills)
- [ ] Security subagent prompt is grounded in CWF's actual threat model (bash injection in skill scripts, Perl helpers handling untrusted git output, file permissions on `.cwf/scripts/`, hash-tracked file integrity, prompt injection via task descriptions) — not generic OWASP boilerplate
- [ ] Falsy-positive rate kept low by scoping each subagent to read-only tools and asking for *actionable* findings only (matches existing plan-review subagent style)
- [ ] No regression in existing 3-subagent map/reduce; new subagent added in parallel, not serial, to keep wall-clock cost flat
- [ ] BACKLOG.md "Add Security Verification to Testing Workflow" entry remains open and is not affected (separate concern: deterministic `cwf-manage validate` check)

## Original Estimate
**Effort**: 1 day
**Complexity**: Medium — touches 5 SKILL.md files and 1 doc; new subagent prompt design needs iteration
**Dependencies**: None (`/security-review` built-in command exists but is user-invoked, not callable from a subagent — designs that need an in-skill audit must use a custom subagent prompt rather than chaining the built-in)

## Major Milestones
1. **Survey existing security surfaces in CWF**: enumerate the categories of risk that actually show up in CWF code (not generic web-app risks). Produces the threat checklist the subagent prompt is built around.
2. **Extend plan-review.md to 4 subagents**: add the security row to the criteria-lookup table for all three plan types, update the procedure header from "3 parallel subagents" to "4 parallel subagents".
3. **Design the exec-phase security-review prompt**: shared between f-implementation-exec and g-testing-exec, written to a new doc (e.g. `.cwf/docs/skills/security-review.md`), referenced from both SKILL.md files via a one-line step.
4. **Wire and validate**: update three plan-review-using SKILL.md files (b, c, d) and two exec SKILL.md files (f, g); run `cwf-manage validate`; smoke-test by hand-running the security subagent against task 123's own implementation.

## Risk Assessment
### High Priority Risks
- **Risk: Security subagent produces noise, not signal**: generic OWASP-style prompts on a Perl/bash codebase return findings like "consider using HTTPS" that don't apply, training future operators to ignore the subagent.
  - **Mitigation**: Write the prompt around CWF's actual threat surface (Step 1 above). Cap the subagent to "actionable findings; if none, say so briefly" — same discipline the existing 3 subagents use. Empty reports are valid.

### Medium Priority Risks
- **Risk: Wall-clock cost climbs from 3 → 4 parallel calls**: parallel calls already exhaust most of the latency budget; a 4th subagent on the same critical path adds ~zero latency *if* parallel, but doubles tokens-per-review.
  - **Mitigation**: Parallel by construction (single-message map). Token cost is the real lever — keep the security prompt tight (target ≤300 tokens per call) and scoped to read-only tools.
- **Risk: Drift between plan-review security prompt and exec-review security prompt**: two prompts that solve almost the same problem will diverge over time and confuse maintenance.
  - **Mitigation**: One canonical doc (`.cwf/docs/skills/security-review.md`); plan-review.md and the two exec SKILLs reference the same prompt template, parameterised by phase (plan vs exec).
- **Risk: Subagent reads files outside its scope and inflates context**: a security review tempts "let me grep the whole repo for credentials" patterns.
  - **Mitigation**: Subagent scoped to the changeset (plan file in plan-review; just-modified files in exec-review). Same `Read/Grep/Glob` allowlist as existing plan-review subagents.

### Low Priority Risks
- **Risk: Confusion with the built-in `/security-review` command**: there's already a user-invocable `/security-review` skill that audits a whole branch. A new in-workflow subagent shares the name.
  - **Mitigation**: Name the doc and prompt after their *role*, not the user-facing command — e.g. `plan-security-review` and `exec-security-review` subagent roles, both documented in `security-review.md`. Cross-reference the built-in `/security-review` command at the top of the doc as the broader, branch-level alternative.

## Dependencies
- None blocking. Existing `.cwf/docs/skills/plan-review.md` is the integration point; existing 3-subagent map/reduce is the proven pattern to extend.

## Constraints
- New subagent must use only Read/Grep/Glob (matches existing plan-review constraint per `.cwf/docs/conventions/subagent-tool-selection.md`)
- British spelling in new prose
- Avoid `find`/`sed` in any prescribed shell snippets per session-level feedback
- Single canonical prompt doc — no copy-paste between SKILL files
- Must not introduce a new dependency on the built-in `/security-review` command (it's user-invoked, not callable from a subagent)

## Decomposition Check
- [ ] **Time**: ~1 day; doesn't trigger
- [ ] **People**: Single author; doesn't trigger
- [ ] **Complexity**: Touches 5 SKILL files and 1 doc, but they're all variations on one pattern. Doesn't trigger 3+ distinct concerns.
- [ ] **Risk**: Medium-priority risks all mitigable in-task. Doesn't trigger.
- [ ] **Independence**: Plan-review extension and exec-review addition could in principle be split, but they share the security prompt and threat model — splitting forces duplication of the survey work in Step 1. Better as one task.

No decomposition. One feature task.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan 123
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Estimate of 1 day held (~0% variance). Final shape matches the original 4-milestone plan exactly; no scope additions or removals at the task-plan level. Risk mitigations all held: noise-vs-signal kept low by the FR4 CWF-grounded threat model; wall-clock cost flat by parallel construction; no drift between plan-phase and exec-phase prompts thanks to the single canonical doc.

## Lessons Learned
Reusing the 3-subagent plan-review pattern was the right shape — the 4th security row slotted in with no procedural changes and the plan SKILLs needed zero edits.
