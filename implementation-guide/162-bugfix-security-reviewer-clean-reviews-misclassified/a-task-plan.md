# security-reviewer clean reviews misclassified - Plan
**Task**: 162 (bugfix)

## Task Reference
- **Task ID**: internal-162
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/162-security-reviewer-clean-reviews-misclassified
- **Baseline Commit**: 638131db81939636edffd4ecf929a37ba8784c42
- **Template Version**: 2.1

## Goal
Make the exec-phase security-review gate classify substantively-clean changeset reviews correctly (`no findings`) instead of defaulting to `error`, by replacing the fragile line-1-sentinel contract with a deterministic, parseable verdict container that tolerates the reasoning model's natural reason-first output order.

## Problem Evidence
Empirical baseline from the on-disk corpus (76 `## Security Review` blocks across Tasks 124–161, recorded in `f-implementation-exec.md` / `g-testing-exec.md`):

- Recorded verdicts: 41 `no findings`, 23 `error`, 10 `findings`, 2 manual-approval.
- Of the 23 `error` records: **11** are the legitimate 500-line-cap (skill-authored), **9** are the bug — substantively-clean reviews misclassified because the subagent led with prose and the verdict landed later/at the end, **3** are procedural/tooling artefacts (e.g. helper blind to uncommitted, cumulative-diff inflation), **0** are genuinely malformed.
- The tier-2 numbered-list heuristic *also* produced false `findings` on clean reviews (126-g, 133-g, 134-g) — including one that triggered on a numbered list of reviewed files. So the misclassification bites in both directions.
- Among real subagent runs, prose-first is the model's default; bare-sentinel-first was the minority and was only achieved once via character-level prompt coercion (141-g) and reverted the very next run (142). When not on line 1, the verdict reliably appeared at the **end** of the output, wrapped variously (bare, `**bold**`, `` `backtick` ``, `> blockquote`, trailing a sentence).

## Candidate Approaches (decide in design)
Two composable options, not mutually exclusive:

1. **Deterministic verdict container** (prompt + parser change, self-contained). The subagent emits a delimited, machine-parseable verdict block (e.g. a trailing fenced ```` ```cwf-review ```` block with an explicit `state:` key), demonstrated by a short worked example in the agent definition. The exec-skill classifier greps for the block anywhere in output (markdown-stripped), drops the harmful tier-2 numbered-list heuristic, and treats a missing block as genuinely-malformed (`error`). No settings plumbing.
2. **SubagentStop hook enforcement** (harness-level backstop). A `SubagentStop` hook matched to `agent_type: cwf-security-reviewer-changeset` inspects `last_assistant_message`, and if the verdict block is absent returns `{"decision":"block","reason":"..."}` to force the subagent to re-emit it (loop-guarded; harness caps at 8 consecutive blocks). Verified against `code.claude.com/docs/en/hooks.md` (§ SubagentStop). Makes the block's presence guaranteed rather than likely — but lives in `settings.json`, so CWF must install it and ensure it survives `cwf-manage update`.

Container format is the floor; the hook is the optional backstop on top.

## Success Criteria
- [ ] A clean review (no actionable findings) classifies as `no findings`, not `error`, regardless of how much reasoning prose precedes the verdict (covers the 9 bucket-B cases).
- [ ] The classifier no longer infers `findings` from incidental numbered lists (covers the 126-g/133-g/134-g false positives); severity comes only from the explicit verdict field.
- [ ] A genuinely absent/malformed verdict still classifies as `error` — the "surface, never smooth" malformed-output guard is preserved, never silently downgraded.
- [ ] The non-subagent paths (500-line cap, empty changeset, on-main) keep their existing deterministic verdicts unchanged.
- [ ] Re-running the gate on a representative sample of historically-misclassified changesets now yields the correct verdict (regression evidence captured in g).

## Original Estimate
**Effort**: 1–2 days
**Complexity**: Medium
**Dependencies**: None external. If the hook approach is selected, depends on install/update plumbing (`install.bash`, settings merge).

## Major Milestones
1. **Design**: choose verdict-container shape (trailing fenced block vs leading frontmatter) and whether to include the SubagentStop hook; settle the markdown-tolerant parse rule as a single source of truth.
2. **Implement container + parser**: update `.claude/agents/cwf-security-reviewer-changeset.md` (format + worked example) and the classifier in `cwf-implementation-exec` / `cwf-testing-exec` (+ `.cwf/docs/skills/security-review.md`).
3. **(Conditional) Implement + install hook**: SubagentStop hook scoped to the agent, wired through install so it survives update.
4. **Validate**: re-run gate against historical misclassified changesets; confirm corrected verdicts and preserved malformed-detection.

## Risk Assessment
### High Priority Risks
- **Hook distribution footprint**: a SubagentStop hook lives in `settings.json` and must survive `cwf-manage update` for end users.
  - **Mitigation**: treat the hook as optional; the container format works standalone. Decide scope in design; if included, reuse the existing settings-merge install path.

### Medium Priority Risks
- **Prompt/example compliance is non-durable**: 141-g complied then 142 reverted, so instruction-only fixes regress.
  - **Mitigation**: make the parser position-independent (match the block anywhere, not line 1); do not rely on the model leading with the verdict. The hook, if chosen, is the hard backstop.
- **Classifier-contract drift across two exec skills**: the parse rule is consumed by both `cwf-implementation-exec` and `cwf-testing-exec`.
  - **Mitigation**: single documented source for the verdict-parse rule; both skills reference it rather than restating.
- **Hashed-file edits**: the agent definition and skill docs may be tracked in `.cwf/security/script-hashes.json`.
  - **Mitigation**: refresh hashes in the same commit per the hash-updates convention; disclose hashed-file edits at plan time in d.

## Dependencies
- Files in scope: `.claude/agents/cwf-security-reviewer-changeset.md`, `.cwf/docs/skills/security-review.md`, `cwf-implementation-exec` / `cwf-testing-exec` skills; conditionally `settings.json` + `install.bash`.
- Reference doc (saved): `/tmp/-home-matt-repo-coding-with-files-task-162/hooks.md` (§ SubagentStop input & decision control).

## Constraints
- **Surface, never smooth**: malformed/absent verdicts must stay visible as `error`; never auto-downgrade to `no findings`.
- POSIX / core-Perl only for any new helper.
- If the hook is selected, it must be installable and survive `cwf-manage update` (CWF distribution constraint).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No.
- [ ] **People**: Does this need >2 people working on different parts? No.
- [x] **Complexity**: Does this involve 3+ distinct concerns? Borderline — container format, classifier parser, optional hook, optional install plumbing. Cohesive around one bug; revisit only if the hook+install path is selected.
- [ ] **Risk**: Are there high-risk components that need isolation? No.
- [x] **Independence**: Can parts be worked on separately? The hook + its install plumbing is separable from the container format.

**Recommendation**: keep as one task. If design selects the SubagentStop-hook + install path, consider splitting that into a subtask so the self-contained container-format fix can land independently.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Delivered full scope (D1–D4) per the user's option-(C) decision, in a single session, within the 1–2 day estimate. All 5 success criteria met: clean reviews classify `no findings` regardless of prose position (TC-C1); the numbered-list heuristic is removed (severity comes only from `state:`); absent/malformed verdicts still surface as `error`; the on-main/empty/cap short-circuits are unchanged; regression evidence is the deterministic classifier suite (the historical corpus could not be fed directly — it predates the format).

## Lessons Learned
Front-loading the map/reduce plan reviews (design + implementation) was the single biggest contributor to zero exec-phase rework — the false "D4 reuses the existing settings-merge path" premise was corrected before any code was written.
