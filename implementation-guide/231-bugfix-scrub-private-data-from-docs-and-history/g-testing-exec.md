# scrub private data from docs and history - Testing Execution
**Task**: 231 (bugfix)

## Task Reference
- **Task ID**: internal-231
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/231-scrub-private-data-from-docs-and-history
- **Template Version**: 2.1

## Goal
Execute TC-1..TC-12 (e-testing-plan) against a **fresh disposable clone**, never the live
repo. Prove the redaction is complete on all surfaces and that the gate itself can fail.

## Environment
A fresh `git clone --no-local` of the live repo under scratch `task-231/clone-test`,
rewritten by `scrub.sh` (1979 commits + 39 tags in ~3 s). All checks via `verify.sh` +
`g-tests.sh` (scratch). The clone is purged at the end of this phase.

## Results (TC-1..TC-12)

| TC | What | Result |
|----|------|--------|
| TC-1 | Negative control, Class A (gate fires) | **PASS** — planted distinctive name / username path (slash **and** dashified) / personal email made `verify.sh` fire and name **only** the plant; removing it restores PASS |
| TC-2 | Negative control, Class B (gate fires) | **PASS** — planted roster + synthetic tally line flagged |
| TC-3 | Kept address survives | **PASS** — `github@mattkeenan.net` present in HEAD + history, never flagged (see note on count) |
| TC-4 | Content scan clean (all commits) | **PASS** (after fixing one self-leak — see Finding G1) — zero matches across all 1979 commits' trees |
| TC-5 | Commit-message scan clean | **PASS** — 0 matches; the `<claude@…>` Co-developed-by trailers are gone |
| TC-6 | Annotated-tag-message scan clean | **PASS** — 30 `tag` bodies via `git cat-file tag`, 0 matches |
| TC-7 | Tag state preserved | **PASS** — 39 == 39 tag names identical pre/post; 30 annotated + 9 lightweight (re-pointed, none dropped, no manual re-creation) |
| TC-8 | Exit-code polarity across batches | **PASS** — leak planted, scanned oldest-first (`rev-list --all --reverse`) in 20-commit `xargs` batches over 1979 commits; the match in the final batch is still reported (output-capture is batch-position independent) |
| TC-9 | Ambiguous false positives survive | **PASS** — `mcp__lmm__`, `quality gate`, `LMM corpus` all present and unchanged |
| TC-10 | Integrity + suite | **validate OK** (see note); **suite**: `Files=78, Tests=1077`, one clone-only failure (see note) |
| TC-11 | Readability | **PASS** — roster keeps "6 projects (…)"; survey table keeps this repo (`coding-with-files`) + retained `lmm`; private projects → `<other-project>` |
| TC-12 | Scratch purge | **PASS** — the disposable clone is purged at end of g; the rules/scripts/inventories are retained (the owner needs them for the live runbook) and purged as the final runbook step after the push |

## Finding G1 — self-leak in f-exec (found by TC-4, fixed, re-verified)
The all-history content scan caught **one** residual: `f-implementation-exec.md` had
embedded a *made-up* Class-B tally string as a negative-control example. It matched the
leak pattern **and** was not covered by any redaction rule (the rules cover only the real
tally literals), so it would have survived the scrub and published as project-looking
data. This is the same class the security reviewer caught at f (raw example strings in a
committed doc). **Fix**: rewrote the negative-control description to name the plant
categories abstractly rather than embedding raw tokens (amended into the f checkpoint);
**re-scrubbed a fresh clone → content/message/tag scans all clean, zero residual**. The
lesson (describe, don't embed) is now noted in f-exec itself.

## Notes on TC-3 and TC-10
- **Kept-address count** is not a fixed number: `github@mattkeenan.net` occurrences vary
  as the task's own docs add/remove *mentions* of it (22 at f-plan time → 23 now). The
  scrub never touches it — the invariant is "present and byte-unmodified", which holds.
  `verify.sh`'s hard-coded pre-image is advisory; presence + zero-flag is the real gate.
- **validate**: on a raw clone the recorded `0500/0444` perms are not reproduced (git
  records only the exec bit → umask-derived `0700/0600`). `cwf-manage fix-security` clamps
  them → `validate: OK` with **zero sha256/content violations** — proving no hashed blob
  was altered. The live runbook includes this `fix-security` step.
- **suite**: the lone failure is `t/cwf-manage-fix-security.t` test 10, an artifact of
  running `fix-security` on the umask-fresh clone mid-session; it **passes on the live
  repo** and exercises `cwf-manage`, which the scrub never touches. Not a redaction
  regression. The runbook re-runs `prove -r t/` on the live post-rewrite tree.

## Coverage
All 12 planned test cases executed. All three categories (emails, paths incl. the
newly-found dashified form, names) × all three surfaces (content, commit messages,
annotated-tag messages) covered; negative controls prove the gate fails on a planted leak;
kept-address and ambiguous-name survival asserted.

### Ref-scope of the scan — all refs, not just `main`
The `git rev-list --all` content scan (TC-4) and the tag scan (TC-7) walk **all 432 refs**
in the clone — **235 task branches + 197 checkpoint branches**, not only `main`. On a
`--no-local` clone the source's local branches arrive as `refs/remotes/origin/*`, and
`git filter-repo` migrates every one to a local head and rewrites it in a single consistent
object map (a commit shared by `main` and a checkpoint branch gets the same new SHA on
both). Re-confirmed this session on a fresh clone: **433 remote-tracking refs → 432 local
heads** post-filter, and the checkpoint-branch tip plus **all-refs history scanned 0 leak
hits**, kept `github@` retained. So the checkpoint/task branches are verified clean by
construction, not just `main` — the whole-history pass covers them. (They are never pushed
to the public remote regardless — see f-exec Step 6.)

## Changeset Reviews
Two reviewers (security + best-practice) ran in parallel on the changeset (workflow docs;
0 production lines) in **two rounds**. Verdicts via `security-review-classify`.

**Round 1 (initial g)**: both no findings — every private token rule-covered or
intentionally retained (`github@mattkeenan.net`, `lmm`/`mcp__lmm__`, `coding-with-files`);
G1 self-leak class remediated (plants described, not embedded).

**Round 2 (this amendment — the "Ref-scope" note)**: both no findings. One process finding
surfaced and was handled:

### Security Review
**State**: no findings — the "Ref-scope" note embeds only the intended public
`github@mattkeenan.net`, describes plant categories abstractly (no self-leak), and the
432-ref coverage claim (235 task + 197 checkpoint) is arithmetically and logically sound
(filter-repo's single object map ⇒ the `rev-list --all` pass genuinely covers checkpoint
branches). Non-blocking (e): the self-covering property still relies on the live pass
running over the task-231 directory — audit any future variant that narrows the rewrite
surface. **Process finding**: `security-review-changeset --wf-step=testing-exec` captured
only the untracked `j-retrospective.md` and missed this tracked `g-testing-exec.md` change
(staged or unstaged) — a coverage gap on testing-exec *re-execution* (same family as Task
141). Worked around by assembling the real diff directly and re-reviewing (clean); logged
as a candidate follow-up bugfix.

### Best-Practice Review
**State**: no findings — docs-only changeset; the golang/perl/postgres code corpora are all
readable but have no applicable code artefact (the scrub tooling is correctly uncommitted).

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
See the TC table and Finding G1 above.

## Lessons Learned
- A verification gate that scans for a leak pattern will also flag the task's own
  *documentation* of that pattern — describe example plant strings, never embed them.
- git only records the exec bit, so recorded sub-modes (0500) always drift on a raw
  checkout; a history-rewrite runbook must include a `fix-security` step.
