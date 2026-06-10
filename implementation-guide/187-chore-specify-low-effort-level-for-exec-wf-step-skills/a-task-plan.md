# Specify low effort level for exec wf step skills - Plan
**Task**: 187 (chore)

## Task Reference
- **Task ID**: internal-187
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/187-specify-low-effort-level-for-exec-wf-step-skills
- **Baseline Commit**: 2e2e21a3593004edd95ef19aa8c59320309a3489
- **Template Version**: 2.1

## Goal
Add `effort: low` to the frontmatter of the two exec-phase skills so the mechanical
execution steps run Opus 4.8 at reduced reasoning effort, since the upstream
planning/requirements/design/implementation-plan phases have already done the hard thinking.

## Success Criteria
- [ ] `cwf-implementation-exec/SKILL.md` frontmatter carries `effort: low` (no `model:` key)
- [ ] `cwf-testing-exec/SKILL.md` frontmatter carries `effort: low` (no `model:` key)
- [ ] `cwf-security-reviewer-changeset.md` frontmatter carries `effort: high`, with its
      `sha256` entry in `.cwf/security/script-hashes.json` refreshed in the same commit
      (the agent is hash-tracked) — so the FR4(a–e) security review is never run at low effort
- [ ] `effort` is the correct documented SKILL.md frontmatter key and the chosen value
      is one of the documented options (`low|medium|high|xhigh|max`)
- [ ] No other exec/plan skills are altered; planning-phase skills remain unchanged

## Original Estimate
**Effort**: <0.5 day
**Complexity**: Low
**Dependencies**: None blocking; Claude Code frontmatter `effort` support (already verified against docs)

## Major Milestones
1. **Confirm mechanism & blast radius**: `effort` is a real SKILL.md key (verified, docs);
   decision taken — the security-review subagent pins its own `effort: high`.
2. **Apply frontmatter**: add `effort: low` to both exec skills; add `effort: high` to the
   `cwf-security-reviewer-changeset` agent and refresh its `sha256` in the same commit.
3. **Verify**: confirm frontmatter parses, skills still invoke, `cwf-manage validate` passes,
   and the security review is not silently downgraded.

## Risk Assessment
### High Priority Risks
- **Risk 1 — Security review silently downgraded**: Both exec skills spawn the hash-tracked
  `cwf-security-reviewer-changeset` subagent, which sets no `effort` of its own. If a
  subagent inherits the skill's lowered session effort, the FR4(a–e) security review would
  run at `low` — exactly the step we least want degraded.
  - **Mitigation (decided)**: Pin the reviewer agent's own `effort: high` so it is insulated
    from the exec skills' lowered effort regardless of inheritance behaviour, and refresh its
    `sha256` in the same commit per `.cwf/docs/conventions/hash-updates.md`.

### Medium Priority Risks
- **Risk 2 — First use of `effort`/`model` frontmatter in the repo**: No existing skill or
  agent sets these keys, so there is no in-repo precedent or convention.
  - **Mitigation**: Keep the change minimal and self-evident; avoid introducing a new
    documented convention in this chore unless design shows it is needed. Add a one-line
    comment/rationale only if it aids the next reader.
- **Risk 3 — Quality regression on execution steps**: `low` effort could under-serve genuinely
  non-mechanical exec work (deviation handling, re-execution, debugging a failing test).
  - **Mitigation**: This is a reversible one-line knob; testing phase sanity-checks a real
    exec run. Revisit value (`low` vs `medium`) if execution quality visibly suffers.

## Dependencies
- Claude Code SKILL.md `effort` frontmatter support — verified against
  https://code.claude.com/docs/en/skills.md (key `effort`, values `low|medium|high|xhigh|max`,
  overrides session effort, inherits when unset).
- Project `settings.json` pins `claude-opus-4-8`, so `effort: low` alone means "Opus 4.8 at low".

## Constraints
- Touch only the two exec skills (and, conditionally, the reviewer agent) — no change to
  planning-phase skills.
- Editing the hash-tracked reviewer agent, if done, requires a same-commit `sha256` refresh.
- No `model:` key — effort applies to the session-pinned model by design.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — under half a day.
- [ ] **People**: Does this need >2 people working on different parts? No.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — one knob, one subagent question.
- [ ] **Risk**: Are there high-risk components that need isolation? No — single reversible edit.
- [ ] **Independence**: Can parts be worked on separately? No.

No decomposition signals triggered — proceed as a single task.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five success criteria met: `effort: low` on both exec skills (no `model:`), `effort: high`
on the reviewer agent with same-commit sha256 refresh, documented key/value confirmed, no other
skills altered. See f-implementation-exec.md and g-testing-exec.md.

## Lessons Learned
The plan's top risk (security review downgraded by inherited low effort) was retired by a
user decision to pin the reviewer at `high` — defensive pinning beats relying on uncertain
inheritance. Full reflection in j-retrospective.md.
