# Intent-CTA skill descriptions with reference docs - Plan
**Task**: 134 (chore)

## Task Reference
- **Task ID**: internal-134
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/134-intent-cta-skill-descriptions-with-reference-docs
- **Baseline Commit**: c2648b0b5f57e1220a214038d78bf87b30ca2409
- **Template Version**: 2.1

## Goal
Reshape the `cwf-backlog-manager` skill frontmatter `description` into an
intent-CTA that pattern-matches user phrasings, and establish a convention for
short per-skill reference docs that aid skill selection without inviting the
agent to execute skill instructions outside the Skill-tool harness.

## Success Criteria
- [ ] `cwf-backlog-manager` frontmatter `description` rewritten in intent-CTA form (names the domain "the backlog/changelog", includes 2-3 example user phrasings, ≤ 30 words)
- [ ] Convention doc exists at `.cwf/docs/skills/skill-reference-convention.md` defining: location (`.cwf/docs/skills/reference/<skill-name>.md`), shape (brief purpose paragraph + 3-5 example user phrasings + no operational instructions), size budget (≤ 30 lines per reference-doc instance), and the hardcoded/author-curated examples rule
- [ ] Reference doc exists at `.cwf/docs/skills/reference/cwf-backlog-manager.md` conforming to the convention
- [ ] No skill description in `.claude/skills/cwf-backlog-manager/SKILL.md` (or elsewhere added by this task) references `SKILL.md` paths directly — references point to the new convention-shaped doc
- [ ] Rollout of the new convention to other skills is explicitly out of scope and tracked as a follow-up backlog entry

## Original Estimate
**Effort**: 0.5 days
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. **Convention defined**: `.cwf/docs/skills/skill-reference-convention.md` written
2. **First instance**: `.cwf/docs/skills/reference/cwf-backlog-manager.md` written and `cwf-backlog-manager` frontmatter updated
3. **Follow-up filed**: backlog entry for rolling the convention to other skills

## Risk Assessment
### High Priority Risks
- **Convention is a one-way door**: every future skill will follow whatever
  shape we pick here. A wrong choice (wrong location, wrong content shape,
  wrong size budget) is expensive to undo.
  - **Mitigation**: Scope to ONE skill in this task. Defer rollout to a
    follow-up so the convention can be validated on the first instance
    before being applied at scale.

### Medium Priority Risks
- **Reference-doc bloat**: if the doc grows past a brief decision aid, it
  negates the progressive-disclosure benefit and starts to overlap SKILL.md.
  - **Mitigation**: Hard line budget (≤ 30 lines) enforced by the convention
    doc; lint-on-commit is out of scope but listed as a follow-up.
- **Frontmatter token cost**: skill frontmatter `description` is loaded into
  every session's system prompt. Adding example phrasings to every skill's
  description multiplies that cost.
  - **Mitigation**: Cap descriptions at ≤ 30 words. The convention names this
    cap explicitly so future skills inherit it.

## Dependencies
- None (single skill, two new docs, one frontmatter edit)

## Constraints
- Must not reference `SKILL.md` from anywhere the agent might Read+follow as
  plain instructions (defeats the Skill-tool harness controls).
- The convention doc and the first reference doc must both fit within their
  own ≤ 30-line budget (eat-our-own-dogfood).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: Will this take >1 week? **No** — half-day task
- [x] **People**: Does this need >2 people working on different parts? **No**
- [x] **Complexity**: Does this involve 3+ distinct concerns? **No** — single concern (skill-selection UX) with one convention + one instance
- [x] **Risk**: Are there high-risk components that need isolation? **No** — docs-only, fully reversible
- [x] **Independence**: Can parts be worked on separately? **No** — convention and first instance reinforce each other

No decomposition. Single chore-shaped task.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All success criteria met. Convention doc at `.cwf/docs/skills/skill-reference-convention.md`,
instance at `.cwf/docs/skills/reference/cwf-backlog-manager.md`, frontmatter rewritten
(double-quoted, 23 words), follow-up backlog entry filed at Low priority.

## Lessons Learned
Plan correctly identified the convention-is-a-one-way-door risk and scoped to one
worked instance. Mid-exec, D6 was tightened to mandate explicit YAML quoting after
strict-parser validation. See j-retrospective.md.
