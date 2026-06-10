# Reviewer agents prefer tools over Bash - Retrospective
**Task**: 186 (chore)

## Task Reference
- **Task ID**: internal-186
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/186-reviewer-agents-prefer-tools-over-bash
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-10

## Executive Summary
- **Duration**: ~1 day across two sessions (planning a/d/e in a prior session with the full plan-review panel; exec f→j this session after a user review gate). On estimate (<1 day, Low).
- **Scope**: Grew once during planning — the latent `allowed-tools:`→`tools:` frontmatter bug was folded in (at the user's instruction), turning a guidance-only chore into guidance + a real grant correction. Final scope: 5 agent grants + 3 guidance/posture docs + 6 hash refreshes + CHANGELOG.
- **Outcome**: Success for the in-session deliverable. The five reviewers now declare a defined `tools: Read, Grep, Glob, LSP, Bash` grant (replacing silent all-tools inheritance), with guidance strongly steering them to Read/Grep/Glob/LSP and the markdown-reader skill over raw Bash. Final acceptance (TC-8/9/10) awaits a fresh session because agent defs are session-cached.

## Variance Analysis
### Time and Effort
- **Estimated**: <1 day total (Low complexity).
- **Actual**: Planning (a/d/e) ~half a session incl. plan-review panel + two user decision points; exec (f/g/j) ~one session. Roughly on estimate despite the scope fold-in, because the fold-in added edit sites, not new design.
- **Variance**: ~0%. The added grant-fix work was offset by the change being mechanical (one line × 5 files) once the design was settled.

### Scope Changes
- **Additions**:
  - **`allowed-tools:`→`tools:` grant fix** — folded in after discovering the key is silently ignored on subagents (skills schema, not subagent schema), so reviewers were inheriting ALL tools. Promoted the chore from cosmetic to a real security tightening.
  - **`security-review.md` posture update + FR4(c) note** — required because the doc asserted "No Bash", which the keep-Bash decision contradicted.
- **Removals / deferrals**:
  - **TC-8/9/10 (fresh-session acceptance)** — deferred by necessity (agent-def session cache), recorded in g-testing-exec.md, not descoped.
- **Impact**: The fold-in is what made the task worth doing well; without it the guidance would have steered toward tools the agents were already (accidentally) able to use, and the real defect would have persisted.

### Quality Metrics
- **Test coverage**: TC-1..TC-7 in-session 7/7 PASS; every changed file has ≥1 asserting check; critical path (grant on all five agents) 100%.
- **Defect rate**: 0 defects found in testing. `cwf-manage validate` clean throughout.
- **Security**: both exec-phase reviews (f and g) returned `no findings`; the Bash grant is disclosed and named against FR4(c).
- **Regression**: full suite 706 tests green (Files=61).

## What Went Well
- **The plan-review panel caught the real shape early.** Folding the grant fix into the guidance chore (rather than shipping aspirational guidance) came out of treating the `allowed-tools:` discovery as in-scope, not a separate ticket.
- **Surface-don't-smooth held under tension.** The keep-Bash decision could have quietly left "No Bash" in the docs; instead the posture and the FR4(c) residual threat were written out explicitly, and the security reviewer confirmed the disclosure.
- **Mechanical edits, verified mechanically.** Identical line-4 across five files → one Edit each, then a single grep asserting exactly five exact grant lines with no Edit/Write.
- **Hash refresh stayed in-commit.** Pre-verified `git log 6659c1c..HEAD` empty, refreshed all six sha256 in the same f-phase commit; no drift reached retrospective.

## What Could Be Improved
- **The markdown-reader assumption cost a detour.** It was first assumed to be a discrete grantable tool, then found to be a Bash-run user Skill — which inverted the whole "remove Bash" premise. Risk 4 anticipated this ("may not exist as a discrete tool"), but the resolution still needed a user decision mid-flight. Earlier tool-inventory confirmation would have framed the keep-Bash design from the start.
- **fix-security expectation was stale.** The plan budgeted for clamping an owner-write bit on the 0444 files; the harness already restores recorded perms on write, so it was a no-op. Harmless, but the plan carried a step that reality had removed.
- **Checkpoint-commit arg form.** The helper takes the task *number*, not the task *path* — a first attempt with the path failed. The doc's `{task-path}` label vs its `102` example is mismatched.

## Key Learnings
### Technical Insights
- **`allowed-tools:` is the Skills frontmatter schema; subagents honour `tools:`.** Using the wrong key on a subagent is silent — no error, no warning — and the failure mode is *more* permissive (all-tools), not less. Worth a lint.
- **markdown-reader needs a Bash grant.** It is a Perl script invoked via the shell, not a built-in tool; "prefer markdown-reader" and "remove Bash" are mutually exclusive for these agents.
- **Skill access can't be narrowed in frontmatter.** Per-skill scoping (`Skill(name)`) is a settings-permissions construct; `skills:` only controls preloading. Restricting reviewers to *only* markdown-reader would need settings, not the agent file.

### Process Learnings
- **Session-caching is a first-class test-planning constraint.** TC-8/9/10 were correctly written as fresh-session-only from the start, so no in-session result was misread as acceptance. The pre-existing `feedback_agent_def_session_cache` memory paid off.
- **A user review gate between plan and exec works.** Stopping after a/d/e for the keep-Bash decision avoided building the wrong design (the first plan recommended dropping LSP).

### Risk Mitigation Strategies
- **Risk 1 (session cache)** materialised exactly as predicted and was handled by deferral, not by guessing from a stale registry.
- **Risk 3 (removing Bash breaks a reviewer)** inverted: the resolution was to *keep* Bash, because the requested markdown-reader preference depends on it. The per-agent procedure audit confirmed no agent shells out today, but the skill requirement decided the grant.

## Recommendations
### Process Improvements
- Confirm the concrete tool inventory (built-in vs Skill vs script) before writing guidance that names tools — it determines whether a grant can be narrowed.
- Fix the checkpoint-commit doc example/label mismatch (`{task-path}` vs the `102` number) so the first invocation doesn't fail.

### Tool and Technique Recommendations
- Consider a `validate` lint that flags `allowed-tools:` in `.claude/agents/*.md` (wrong schema → silent all-tools). This task fixed the instances; a guard would stop regressions.

### Future Work
- **Fresh-session acceptance (TC-8/9/10)** — run in a new session on this branch before the task is considered fully verified: registry shows the exact five-tool grant excluding Edit/Write; a plan reviewer reaches markdown-reader; the changeset reviewer still emits a parseable `cwf-review` block.
- **Possible Bash narrowing follow-up** — if the markdown-reader dependency is later removed or replaced by a built-in, revisit dropping Bash from the grant (or scope Skill access via settings-permissions). Recorded in `security-review.md` and the CHANGELOG.

## Status
**Status**: Finished
**Next Action**: Task complete (pending fresh-session TC-8/9/10)
**Blockers**: None identified
**Completion Date**: 2026-06-10
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md`, `d-implementation-plan.md`, `e-testing-plan.md`
- Execution: `f-implementation-exec.md` (security review: no findings), `g-testing-exec.md` (TC-1..7 PASS, security review: no findings)
- Commits: `918648d` (f), `6621db9` (g); checkpoints branch created at retrospective.
- CHANGELOG: Task 186 entry.
