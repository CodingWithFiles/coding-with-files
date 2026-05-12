# Intent-CTA skill descriptions with reference docs - Retrospective
**Task**: 134 (chore)

## Task Reference
- **Task ID**: internal-134
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/134-intent-cta-skill-descriptions-with-reference-docs
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-12

## Executive Summary
- **Duration**: 1 session (estimated: 0.5 days; on-target for a one-sitting chore).
- **Scope**: As planned. One convention doc, one reference-doc instance,
  one frontmatter rewrite, one follow-up backlog entry. Rollout to other
  skills explicitly deferred.
- **Outcome**: Success. The `cwf-backlog-manager` description now
  pattern-matches the very query that originally missed ("what's in the
  backlog") and the convention is in place for future skills.

## Variance Analysis

### Time and Effort
- **Estimated**: 0.5 days (a-task-plan.md § Original Estimate).
- **Actual**: ~1 session, within the estimate. Bulk of time was spent on
  the d-implementation-plan review (4-subagent map/reduce) and the
  mid-exec YAML quoting fix.
- **Variance**: None of note. The plan-review and YAML-validity steps
  added a small but worthwhile overhead.

### Scope Changes
- **Additions**: D6 (YAML validity / mandatory quoting) was added during
  the exec phase after `YAML::XS` rejected the unquoted form. This is
  a tightening of an existing decision, not new scope — but it materially
  changed the final SKILL.md syntax and was folded back into the plan.
- **Removals**: None.
- **Impact**: Negligible on timeline; positive on correctness. Strict
  parsers now accept the description, not just the lenient harness parser.

### Quality Metrics
- **Tests**: 12/12 functional and 4/4 non-functional pass. Existing
  `prove t/` suite green (441 tests).
- **Defects**: One mid-exec defect found by my own verification: unquoted
  YAML form failed `YAML::XS`. Caught before commit; fixed in the same
  implementation commit. Zero defects shipped.
- **Coverage**: Every success criterion in a-task-plan has at least one
  test case. Docs-only task — line/branch coverage not applicable.

## What Went Well

- **The 4-subagent d-plan review caught the YAML issue preemptively.**
  The robustness reviewer flagged "the proposed description will break
  YAML parsing" with a remediation suggestion. The empirical failure
  during exec confirmed the warning was correct. The review took ~30
  seconds of wall-clock time and saved a guaranteed re-do.

- **Choosing to validate the YAML through a real parser, not just the
  harness, was the right call.** The harness is lenient and would have
  silently accepted the unquoted form. `YAML::XS` (libyaml) is the
  strictest commonly-available parser and matches what CI tooling and
  external tooling are likely to use.

- **Scoping to one skill + a convention doc, with a follow-up backlog
  entry for the rollout, was the right shape.** The convention can be
  validated on one worked instance before being rolled to ~20 skills.
  Doing the rollout in the same task would have been irreversible.

- **The intent-CTA shape itself is empirically better.** The new
  description contains the literal string "what's in the backlog" — the
  exact phrasing the original miss used. An LLM scanning the system
  prompt now has a direct token-match.

## What Could Be Improved

- **The security-review subagent prompt does not enforce sentinel-first
  output.** Both invocations (f-phase and g-phase) produced substantively
  clean reviews but failed to lead with `findings:` / `no findings:` /
  `error:`. The three-tier classification rule classified them as `error`
  (f-phase) and `findings` (g-phase, numbered-list fallback fired on the
  file enumeration), neither of which reflected the actual review state.
  The prompt template needs a stronger constraint and the classifier
  could use a "last-line `no findings.`" fallback for the substance-clear
  case. Filed as a follow-up.

- **`backlog-manager add --body-file=` rejects absolute paths.** I had
  written the body to `/tmp/cwf-task-134/follow-up-body.txt` to avoid
  inline shell-quoting, but the helper's path allowlist excluded `/tmp`.
  Fell back to inline `--body=` which worked. Worth a small UX
  improvement to either accept `/tmp/<task>/` paths or document the
  restriction. Not severe enough to warrant a new task on its own;
  recorded here.

- **The d-implementation-plan was amended mid-exec.** This is fine in
  principle (D6 was a small, well-bounded change) but the amendment
  bundled with the implementation commit (`ef9a623`) means the
  archaeology on main (post-squash) won't show the plan-vs-exec drift.
  The checkpoints branch preserves the order. Not a problem in this
  case; flag for awareness on bigger tasks.

## Key Learnings

### Technical Insights

- **Frontmatter `description` values containing `Examples: "..."` MUST
  be explicitly quoted to be portable.** Unquoted plain scalars with
  colon-space + embedded double quotes parse leniently in the Claude
  Code harness but fail under `YAML::XS`/libyaml with "mapping values
  are not allowed in this context". Use double-quoted YAML with `\"`
  for internal double quotes (or single-quoted with `''` doubled).
  This is now codified in the convention doc.

- **Progressive disclosure for skill selection has three layers, not
  two.** (1) Frontmatter `description` — system-prompt cost, intent-CTA
  shape, ≤30 words. (2) Reference doc (`.cwf/docs/skills/reference/<name>.md`)
  — loaded only on demand by the user/agent, decision-aid only, ≤30
  lines. (3) `SKILL.md` body — loaded by the Skill tool harness when
  invoked, full operational detail. Mixing layers 2 and 3 (referencing
  SKILL.md from the reference doc) defeats the harness controls.

- **The security-review subagent treats numbered lists structurally.**
  Any numbered list in the response body triggers the `findings`
  classification under the fallback rule, even if the list is just
  enumerating reviewed files. Prompt authors must instruct the subagent
  to avoid numbered prose entirely unless reporting actual findings.

### Process Learnings

- **The map/reduce plan review with 4 parallel subagents is high
  leverage for low cost.** It caught one real bug (YAML quoting), one
  internal inconsistency (filename `skill-reference-doc-convention.md`
  vs `skill-reference-convention.md`), and one constraint-tightening
  improvement (D5 hardcoded-examples rule). Wall-clock time was ~30
  seconds.

- **The "commit before security review" sequencing is a workflow
  papercut.** `security-review-changeset` anchors at `anchor..HEAD` —
  i.e., committed history only — so to give the subagent a non-empty
  diff I had to commit implementation work *before* the f-checkpoint
  commit. The f-checkpoint then only contains f-implementation-exec.md.
  This is functionally correct but breaks the pattern of "one
  checkpoint = one phase". Acceptable for now; documented in the
  deviations section of f-implementation-exec.md.

### Risk Mitigation Strategies

- **Quote example phrasings in skill descriptions.** The robustness
  reviewer's flag was correct: never trust lenient parsers as
  representative of all consumers.

- **Author-curated, hardcoded examples only.** The convention codifies
  that example phrasings in `description` and reference docs MUST NOT
  derive from user-controlled sources (BACKLOG titles, branch names,
  etc.). This was the security reviewer's framing in the d-plan review
  and we adopted it as a rule.

## Recommendations

### Process Improvements

- Tighten the security-review subagent prompt to enforce sentinel-first
  output. Also add a "last-line `no findings.`" fallback rule to the
  classifier so substance-clear cases are not misclassified by a
  decorative numbered list. (Filed in BACKLOG.)

- Consider documenting the "commit-before-security-review" sequencing
  in the cwf-implementation-exec skill or in
  `.cwf/docs/skills/security-review.md`, so future task authors are not
  surprised. Could also be addressed by extending
  `security-review-changeset` to optionally include the working tree
  (`--include-worktree`).

### Tool and Technique Recommendations

- Adopt the intent-CTA description shape across the remaining skills
  (Low priority; already on BACKLOG).

- Consider a pre-commit lint or `cwf-manage validate` extension that
  parses every `.claude/skills/*/SKILL.md` through `YAML::XS` to catch
  description-quoting regressions automatically. Out of scope here.

### Future Work

- Tracked in BACKLOG: "Roll intent-CTA description convention to
  remaining skills" (Low).
- New (added below): "Enforce sentinel-first output in security-review
  subagent prompt" (Low).

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-12
**Sign-off**: chore/134 task branch retrospective

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: a-task-plan.md, d-implementation-plan.md, e-testing-plan.md
- Execution: f-implementation-exec.md, g-testing-exec.md
- Commits: `2549426` (a), `0b3c18b` (d), `237819a` (e), `ef9a623`
  (implementation), `662b898` (f-checkpoint), `264afce` (g-checkpoint).
  Final squashed commit replaces these on main; checkpoints branch
  preserves the full sequence.
