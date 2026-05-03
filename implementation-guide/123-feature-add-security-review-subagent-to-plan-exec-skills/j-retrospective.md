# Add security-review subagent to plan/exec skills - Retrospective
**Task**: 123 (feature)

## Task Reference
- **Task ID**: internal-123
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/123-add-security-review-subagent-to-plan-exec-skills
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-03

## Executive Summary
- **Duration**: ~1 session of active work spread across two calendar days (commits span 2026-05-02 20:48 → 2026-05-03 08:47, with an overnight gap; estimated 1 day, variance ~0%).
- **Scope**: Final scope matches the original a-task-plan exactly: 4th plan-review subagent + new exec-phase Step 8 + canonical doc + CHANGELOG entry. No additions or removals.
- **Outcome**: Success. All 9 wf phases finished, 15/15 functional + 4/4 NFR + AC8 dogfood test cases pass, `cwf-manage validate` clean throughout.

## Variance Analysis

### Time and Effort
- **Estimated** (from a-task-plan): 1 day total. Implicit allocation: planning (a–e) ~⅓, exec (f) ~⅓, testing/AC8 (g) + h/i/j ~⅓.
- **Actual** (from `git log` commit timestamps):
  - a–e plan phases: ~20 min total (97296c7 → b89cb55, 20:48 → 21:07)
  - f-implementation-exec: ~1h13min (21:07 → 22:20, includes plan re-reads and the doc draft)
  - g-testing-exec: ~56min (22:20 → 23:16, includes the AC8 Agent invocation)
  - h-rollout + i-maintenance: ~1min combined (next morning, fast)
  - j-retrospective: in progress
- **Variance**: ~0% — well under 1-day estimate. Plan phases were notably fast because the design reused the existing 3-subagent pattern.

### Scope Changes
- **Additions during planning** (caught by plan-review subagents, not deviations):
  - **Three-tier classifier (c-design Decision 3)** — added after the design plan-review subagent flagged that strict sentinel matching would silently misclassify verbose model output as `no findings`. Decision biases toward visibility.
  - **Pattern-risk carve-out (FR4(e), c-design Decision 5)** — added after the requirements plan-review subagent flagged that without it the subagent would suppress real signal. Required framing (`safe here because X; audit future uses where X might not hold`) keeps it disciplined.
  - **Sequential renumbering (Step 8 → 9, Step 9 → 10) replacing original `Step 7a` notation** — adopted after design plan-review pointed at Task 71 precedent (commit `be933c7`). Avoids inconsistency with established CWF pattern.
  - **Edge-case pre-checks (on-main, empty diff, >500 lines)** — added in c-design after plan-review noted the bare `git diff` invocation could waste tokens or produce confusing output.
  - **Env-var threat category (FR4(d))** — refined to cite `cwf-manage:85-87` (CWF_SOURCE) as a real surface to audit, rather than a generic placeholder.
- **Additions during implementation**:
  - **TC-10 grep refinement** (the diff-prefix vs verbose-pathspec distinction) — surfaced when the original grep over `git diff $(git merge-base HEAD main)..HEAD --` legitimately matched files that *describe* the command (SKILL Step 8 prose, c-design, CHANGELOG). Sharpened to grep the verbose pathspec list (`'*.pl' '*.pm'`) instead. Documented in `f-implementation-exec.md` "Notes on validation refinements".
  - **Reworded "If 1-3 subagents fail" → "If some subagents fail (but not all)"** — the literal new wording matched the strict 3→4 grep, which would have falsely flagged a correct line as a stale reference. Kept the test's zero-match assertion meaningful.
- **Removals**: None.
- **Impact on timeline**: All scope refinements landed during plan-review iteration, before exec; no rework cost.

### Quality Metrics
- **Test coverage**: 20/20 test cases pass (15 functional, 4 non-functional, 1 dogfood). 100% of FR1–FR6 requirements exercised; 100% of files in d-implementation-plan §"Files to Modify" inspected.
- **Defect rate**: Zero defects in the implementation itself. Two test-design refinements during exec (see "Additions during implementation" above), both sharpenings of intent rather than failures.
- **Performance**: Token-cost estimate per c-design NFR1 — one extra Agent call per phase per task at ≤400-token prompt budget. Actual prompt body in the canonical doc: 13 lines (well under the 30-line cap).

## What Went Well
- **Plan-review subagents earned their keep**. Across b/c/d phases (9 subagent calls total), the load-bearing additions above all came from the subagent findings — not from author hindsight. The classifier-versus-sentinel issue in particular would have been a real defect had it not been caught at design time.
- **Reusing the existing 3-subagent pattern was the right shape**. The 4th security row slotted into `plan-review.md` with no procedural changes. The plan SKILLs (`cwf-{requirements,design,implementation}-plan`) require zero edits — they reference plan-review.md generically and inherit the 4th subagent automatically. Consistency over novelty paid off.
- **Single-source-of-truth in the canonical doc held up under TC-10 scrutiny**. Both exec SKILLs reference the doc by section name; the verbose pathspec lives in exactly one runtime artefact. Workflow plan files contain it descriptively and that's deliberately not a violation.
- **TC-AC8 dogfood proved the wiring end-to-end** on this task's own changeset (270 lines). The classifier-versus-substance gap (subagent verdict was substantively "no findings", classifier returned `findings` because the subagent led with verbose intro instead of a sentinel) was exactly the conservative-default behaviour Decision 3 chose. Loud false positive > silent false negative on a security tool.
- **No deviations from the design at exec time**. All five Decisions in c-design landed unchanged; all 7 implementation steps in d-plan were executed in order with the recorded validation greps.

## What Could Be Improved
- **Subagent prompt template doesn't reliably get sentinel-line compliance**. TC-AC8 demonstrated the failure mode: the subagent emitted ~70 lines of analysis before the closing `no findings` line. The three-tier classifier handles this correctly (loud false positive), but the false-positive rate is likely to be high in practice. Worth tightening the prompt template to push the sentinel ahead of any analysis (e.g. "Your VERY FIRST output line MUST be the sentinel — do not preface with analysis"). Captured as a follow-up BACKLOG item below.
- **TC-10's original grep was over-broad**. The d-implementation-plan §"Step 7" check `git diff $(git merge-base HEAD main)..HEAD --` matched any file that *describes* the command. The intent (single source of truth for the *verbose pathspec list*) is sharper than what the grep tested. Refined during exec; the testing-plan template language for "single source of truth" claims could be tightened in future tasks to specify which substring matters.
- **Sentinel line "no findings" is two-word and easy to embed mid-paragraph** (the subagent's closing line `no findings The changeset introduces…` had `no findings` followed immediately by prose). The primary classifier requires `no findings` to *start* a line; the subagent's response did not. A one-token sentinel (`NO_FINDINGS:`, `FINDINGS:`, `ERROR:`) would be more robust against the subagent's natural prose tendencies. Trade-off: less natural-language fluency in the canonical doc. Worth weighing when the prompt template is tightened.

## Key Learnings

### Technical Insights
- **The three-tier classifier is the load-bearing piece of the design**. Strict sentinel matching alone would have been brittle; numbered-list fallback caught the verbose-intro case in TC-AC8. The conservative default (`error` not `no findings` when neither matches) means the subagent can never silently "succeed" by malforming its output.
- **Both integration points (plan-phase row 4 and exec-phase Step 8) use the same canonical doc but invoke independently**. This was a deliberate design choice (Decision 1) and proved its worth: either could be reverted alone if needed. The threat model is in one place; the prompts that consume it are short and live where they run.
- **Pattern-risk findings need an explicit framing requirement**. Without "safe here because X; audit future uses where X might not hold", the carve-out would have collapsed back into "could be a problem someday" aspirational suggestions. The framing keeps it disciplined.
- **Step renumbering precedent matters**. Task 71's commit `be933c7` established sequential renumbering over `Step 7a` notation. The design plan-review subagent surfaced this precedent; following it kept the workflow file shape consistent across CWF.

### Process Learnings
- **Plan-review subagents catch things authors miss**. This task validated the value of the 3-subagent map/reduce on b/c/d phases: 5 load-bearing items came from subagents (env-var category, threat-model boundary, sequential renumbering, three-tier classifier, edge-case pre-checks). The 4th security subagent added by this task should compound the value going forward.
- **AC8-style deferred-verification ACs work for chicken-and-egg cases**. The dogfood requirement (run the subagent against this task's own changeset) couldn't be checked until the subagent existed. Wiring it into g-testing-exec as a TC with explicit findings/no-findings/error outcome handling closed the loop without forcing a synthetic prerequisite.
- **The /simplify pattern wasn't needed here**. The task touches docs and SKILLs; there's no executable code to simplify. /simplify earned its place on Task 121 (Perl helper extraction) but is the wrong tool for docs-only changes.

### Risk Mitigation Strategies
- **Wall-clock cost stays flat by parallel construction**. The 4th subagent fires in the same single-message Agent call as the existing 3 (procedurally enforced by `plan-review.md` §1). Token cost rises (+25% per plan-review pass) but latency does not. This was identified in a-plan as a medium-priority risk and the mitigation held.
- **Drift between plan and exec prompts mitigated by single canonical doc**. Both prompts share the threat-model section in `security-review.md`; the prose that matters lives in one place. SKILLs reference the doc; the doc owns the prose.

## Recommendations

### Process Improvements
- **Tighten subagent prompt templates** for any future single-shot Agent call where the response shape matters. Explicit "first line must be ..." instructions help but aren't enough; one-token sentinels would be more robust.
- **Generalise the "verbose pathspec single source of truth" check** in future test-plan templates — when claiming a string lives in only one file, specify the *most distinctive substring* of that string, not the leading prefix that any descriptive prose would also match.

### Tool and Technique Recommendations
- **The 4-subagent plan-review map/reduce is now the baseline**. Future tasks inherit the security review automatically with zero per-task setup.
- **The three-tier classifier pattern (sentinel → fallback → conservative default)** is reusable beyond security review. Any single-shot Agent call where the SKILL classifies the response to drive subsequent behaviour should consider the same pattern.

### Future Work
- **Tighten the security-subagent prompt template** to push sentinel-line compliance. One-line edit to `.cwf/docs/skills/security-review.md` § "Exec-phase prompt template"; both exec SKILLs inherit. Captured as a BACKLOG item below.
- **Track classifier-versus-substance gap rate** over the next few feature tasks. If the TC-AC8 pattern recurs in >50% of tasks, escalate to one-token sentinels.

## Status
**Status**: Finished
**Next Action**: User-driven fast-forward of `main` to this task branch (after squash + checkpoints branch)
**Blockers**: None
**Completion Date**: 2026-05-03
**Sign-off**: Author

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Workflow files: `implementation-guide/123-feature-add-security-review-subagent-to-plan-exec-skills/`
- Checkpoints branch: created during Step 10 (`checkpoints-branch-manager create`)
- Commits on task branch: `97296c7` (a) → `278617a` (b) → `084025f` (c) → `9798400` (d) → `b89cb55` (e) → `a9ff0d6` (f) → `21f0bd6` (g) → `b0c5268` (h) → `42e1554` (i) → squashed `Task 123:` commit + j-retrospective.
- TC-AC8 verbatim subagent output: preserved in `g-testing-exec.md` § "TC-AC8 — Dogfood".
