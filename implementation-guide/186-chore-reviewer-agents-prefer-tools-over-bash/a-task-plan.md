# Reviewer agents prefer tools over Bash - Plan
**Task**: 186 (chore)

## Task Reference
- **Task ID**: internal-186
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/186-reviewer-agents-prefer-tools-over-bash
- **Baseline Commit**: 6659c1cca72ef033d92546fcd9d42a0f4d817dd9
- **Template Version**: 2.1

## Goal
Make the five CWF review/security subagents genuinely prefer specialised
read-only tools (Read/Grep/Glob, LSP, markdown reading) over Bash — by
sharpening the shared tool-tier guidance to name those tools, and by
correcting the ignored `allowed-tools:` frontmatter key to the honoured
`tools:` key so the read-only restriction actually takes effect.

## Success Criteria
- [ ] The shared-rules tool-tier preference
  (`.cwf/docs/skills/cwf-agent-shared-rules.md`) explicitly names the
  specialised read tools available to subagents (LSP confirmed; any
  markdown-reading tool that actually exists) as preferred over their
  Bash equivalents, in "strong preference" language.
- [ ] All five agent files use `tools:` (not the ignored `allowed-tools:`)
  so the harness honours the restriction — verified in a fresh session by
  the agent registry no longer reporting "All tools" for these agents.
- [ ] Each agent's `tools:` grant *includes* every specialised tool the
  guidance tells it to prefer (so the preference is actionable, not
  aspirational) and excludes Bash unless a concrete read-only need is
  recorded.
- [ ] The fuller rubric (`.cwf/docs/conventions/subagent-tool-selection.md`)
  is consistent with the sharpened tier list (no contradiction).
- [ ] Integrity intact: no `cwf-manage validate` regression; changes
  smoke-tested in a fresh session (agent-def edits are session-cached).

## Original Estimate
**Effort**: <1 day
**Complexity**: Low
**Dependencies**: Confirmation of which specialised read tools are actually
available to subagents (LSP confirmed this session; markdown-reader TBD).

## Major Milestones
1. **Audit**: Enumerate the specialised read-only tools actually available
   to subagents, and confirm per-agent that none needs Bash for its
   documented procedure.
2. **Guidance**: Sharpen `cwf-agent-shared-rules.md` (and align the fuller
   rubric) to name specialised tools with strong-preference framing.
3. **Grant fix**: Replace `allowed-tools:` with `tools:` in all five agent
   files, with a grant that includes the preferred specialised tools.
4. **Verify**: Fresh-session smoke test (registry shows restricted tools;
   a sample review still works) + `cwf-manage validate`.

## Risk Assessment
### High Priority Risks
- **Risk 1 — Agent-def edits are session-cached**: The `tools:` change
  cannot be live-tested in this session; a stale registry could be
  misread as success or failure.
  - **Mitigation**: Verify only in a fresh session; treat this session's
    registry output as the *pre-change* baseline, not the result.
- **Risk 2 — Aspirational guidance**: Telling reviewers to prefer LSP/
  markdown tools while the `tools:` grant omits them makes the guidance
  unusable and is worse than the status quo.
  - **Mitigation**: Criterion 3 — grant and guidance are edited together;
    only name tools that are both available and granted.

### Medium Priority Risks
- **Risk 3 — Removing Bash breaks a reviewer**: A reviewer that genuinely
  shells out would silently lose capability.
  - **Mitigation**: Per-agent procedure audit (Milestone 1); the documented
    procedures use Read/Grep/Glob only, but confirm before removing Bash.
- **Risk 4 — "markdown reader" may not exist as a discrete tool**: The
  example tool may not be a real grantable tool.
  - **Mitigation**: Name only tools confirmed available; frame markdown
    reading generically if no discrete tool exists. Resolve in
    implementation-plan, do not assume.

## Dependencies
- Authoritative tool inventory for subagents (which specialised read tools
  exist and are grantable). LSP confirmed; others to verify at plan time.
- No external/team dependencies.

## Constraints
- Edit-via-skill rule does not apply to `.claude/agents/*.md` (not wf step
  files); standard Edit/Write is appropriate for those.
- Surface-don't-smooth: the `allowed-tools:` bug is a real silent defect;
  fix it openly, do not paper over with guidance alone.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No.
- [ ] **People**: Does this need >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — one concern (reviewer tool
  preference + grant correction), two edit sites that move together.
- [ ] **Risk**: High-risk components needing isolation? No.
- [ ] **Independence**: Can parts be worked on separately? No benefit;
  guidance and grant must change together to avoid aspirational state.

**Decision**: No decomposition. 0 signals triggered.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Delivered on estimate (<1 day, Low). Scope grew once: the `allowed-tools:`→`tools:`
grant fix was folded in, turning a guidance chore into guidance + a real security
tightening. All success criteria met in-session except the fresh-session-only ones
(registry verification), which are deferred to TC-8/9/10. See `j-retrospective.md`.

## Lessons Learned
The decomposition call (no subtasks) held — guidance and grant had to move together
to avoid aspirational state, exactly as the Independence signal predicted. Full
learnings in `j-retrospective.md`.
