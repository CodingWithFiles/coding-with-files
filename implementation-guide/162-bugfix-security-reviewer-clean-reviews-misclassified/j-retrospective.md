# security-reviewer clean reviews misclassified - Retrospective
**Task**: 162 (bugfix)

## Task Reference
- **Task ID**: internal-162
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/162-security-reviewer-clean-reviews-misclassified
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-24

## Executive Summary
- **Duration**: single session (estimate: 1–2 days, Medium complexity). On/under estimate.
- **Scope**: Full D1–D4 as the user chose option (C) at the design gate — deterministic verdict container + single-parser classifier + exec rewiring (D1–D3) **and** the SubagentStop backstop with its `cwf-claude-settings-merge` event/matcher extension (D4). No descope.
- **Outcome**: Success. The misclassification is fixed at the parser level (the acceptance gate is fully green); the backstop and its plumbing landed with backward-compat preserved. One caveat: positive end-to-end evidence with the *live* agent is deferred to a fresh session (agent definitions are session-cached).

## Variance Analysis
### Time and Effort
- **Estimated**: 1–2 days (Medium). Phase-level estimates were not broken out in a-task-plan.
- **Actual**: one continuous session across a–j. Planning (a,c,d,e) was the larger share — the map/reduce plan reviews materially reshaped D4. Implementation (f) was mechanical once the plans were firm; testing (g) was fast because tests were authored alongside the code in f.
- **Variance**: within estimate. The front-loaded plan-review investment (4 reviewers × design + implementation) is the reason exec had near-zero rework.

### Scope Changes
- **Additions**: none beyond the option-(C) decision already recorded in c-design-plan.
- **Removals**: none. D4 was retained despite guarding a zero-attested failure mode, per the user's explicit choice; D1–D3 were sequenced first so the core fix is independently coherent.
- **Impact**: the combined changeset (982 lines) exceeded the 500-line security-review cap, as the plan predicted — handled via the manual threat-category walkthrough.

### Quality Metrics
- **Test Coverage**: classifier 18 (TC-C1–C14), hook 18 (TC-H1–H7), merge helper +5 (TC-M1–M5) with TC-U1/U3 retained as backward-compat guards. Full suite **574 tests, all pass** (was 569 pre-task). `cwf-manage validate` clean across 4 hash touches.
- **Defect Rate**: zero rework in exec. One self-inflicted test break (perms) found and fixed within the phase; one Perl compile-warning silenced.
- **Performance**: n/a (line-oriented parsers over a single message).

## What Went Well
- **Plan review caught the load-bearing design error before any code.** The pre-exec reviews had already corrected the false "D4 reuses the existing settings-merge path" premise; exec proceeded against an accurate footprint (merge-helper extension required), so there were no mid-implementation surprises.
- **The single-parser design held.** Making `security-review-classify` the one authority — consumed by both exec SKILLs *and* the hook (as a subprocess, not a reimplementation) — meant the contract is defined and tested in exactly one place.
- **Backward-compat was provable, not asserted.** Factoring `find_or_make_group` kept the matcher-less Stop path byte-identical; the retained TC-U1/U3 plus a real-repo `--dry-run` confirmed the existing Stop group is untouched while SubagentStop registers as its own matchered group.
- **"Surface, never smooth" upheld end-to-end.** The classifier defaults every malformed/duplicate/block-less case to `error`; the hook fails open and blocks only on an affirmative clean `error`; the task's own over-cap review was recorded as `error` + manual walkthrough, never downgraded.

## What Could Be Improved
- **Working-tree permissions tripped the suite.** Setting edited scripts to the literal recorded `0500` (a *minimum*, not an exact value) broke `install-bash-reinstall.t` TC-5, which `cp -rp`s the repo and overwrites the merge helper. Lost a cycle diagnosing a "No tests run / exit 255" crash. Now captured as a feedback memory.
- **Live corroboration can't run in the editing session.** The running session loads agent definitions at start, so the live subagent exercised the *old* contract; the positive end-to-end check is deferred. Worth knowing before reaching for a live test as proof of an agent-definition change.

## Key Learnings
### Technical Insights
- A trailing fenced block parsed position-independently is the right shape for a reasoning model's verdict — the model reasons first and concludes last, so demanding a line-1 sentinel fought the grain (and regressed historically). Match the format to how the model actually writes.
- A SubagentStop guard must be affirmative-only and fail-open: block solely when a cleanly-run classifier returns `error` and it is not a re-emit loop; allow on every failure mode. This makes the backstop incapable of trapping the subagent or stalling the workflow.
- Reusing the classifier as a *subprocess* from the hook (shell-free `exec { $prog } $prog` over a self-managed pipe, `POSIX::_exit` in the child) preserves the single-authority guarantee without duplicating parse logic.

### Process Learnings
- The manifest `permissions` field is a floor (`actual & min == min`), and the dev convention keeps scripts at `0700`. After editing a hashed script: `chmod u+w` → edit → `chmod 0700` → refresh sha256 → validate. (Memory: feedback-hashed-script-working-perms.)
- Agent-definition edits are not live in the running session. Defer live corroboration to a fresh session and label it as such; don't read cached old-format output as a defect. (Memory: feedback-agent-def-session-cache.)
- Making new untracked files visible to the security-review changeset requires `git add -N` (intent-to-add) before running `security-review-changeset` — otherwise the most security-sensitive new files are silently absent from the review.

### Risk Mitigation Strategies
- Sequencing D1–D3 before D4 meant the core fix was committable on its own had the plumbing turned hairy — de-risked the larger scope.
- Synthetic fixtures (not the historical corpus, which predates the format) as the deterministic gate sidestepped the false premise that old recorded blocks could validate the new parser.

## Recommendations
### Process Improvements
- When a task edits an agent/skill definition, add an explicit rollout note that end-to-end verification needs a fresh session — and capture the positive evidence there.
- On any task that edits hash-tracked scripts, restore `0700` (not `0500`) as the working-tree perm before committing.

### Tool and Technique Recommendations
- The `git add -N` step before `security-review-changeset` should be standard practice for any task that adds new security-relevant files; consider noting it in the exec SKILL Step 8.

### Future Work
- **Fresh-session end-to-end corroboration** of the new `cwf-review` container: re-run the subagent on a bucket-B changeset (e.g. Tasks 140/142/143/158) in a new session and confirm clean reviews classify `no findings` via the helper, and that the SubagentStop guard fires when a block is absent. (Follow-up backlog item.)

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-24
**Sign-off**: Task 162 (CWF maintainer)

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: a-task-plan.md, c-design-plan.md, d-implementation-plan.md, e-testing-plan.md
- Execution: f-implementation-exec.md (incl. manual threat-category walkthrough), g-testing-exec.md
- Checkpoint commits preserved on the task's checkpoints branch (see Step 10)
- Tests: t/security-review-classify.t, t/subagentstop-security-verdict-guard.t, t/cwf-claude-settings-merge.t
