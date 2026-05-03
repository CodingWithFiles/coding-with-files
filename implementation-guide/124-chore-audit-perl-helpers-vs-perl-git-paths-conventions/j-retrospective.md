# audit perl helpers vs perl-git-paths conventions - Retrospective
**Task**: 124 (chore)

## Task Reference
- **Task ID**: internal-124
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/124-audit-perl-helpers-vs-perl-git-paths-conventions
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-03

## Executive Summary
- **Duration**: 1 session of active work (estimated: 1–2 days; variance ~0%).
- **Scope**: Original `use utf8;` audit covered 9 files; final scope grew to 41 after the source-pragma rule was widened mid-exec from "only when non-ASCII appears in code literals" to unconditional. Plus one new validator module (`CWF::Validate::PerlConventions`), one new unit test (14 subtests), and a hard-coded grandfathered allowlist for `stop-stale-status-detector`.
- **Outcome**: Success. Convention drift is now caught on every checkpoint commit (`cwf-manage validate` runs at `cwf-checkpoint-commit:53`). Full suite 28 files / 267 tests green. One BACKLOG item closed, one new High-priority follow-up opened (integrity-surface expansion).

## Variance Analysis

### Time and Effort
- **Estimated**: 1–2 days (chore — mechanical audit + small fixes + one new check).
- **Actual**: 1 session.
- **Variance**: Within estimate, even with the mid-exec rule widening (3 files → 41).

### Scope Changes
- **Additions**:
  - **Source-pragma rule widened to unconditional** — user direction during f-exec. Drove +38 mechanical edits on top of the originally-planned 3 (originally 9 by byte-grep, narrowed to 3 by code-vs-POD distinction, then re-broadened to "every Perl file under `.cwf/`"). Captured as memory `feedback_always_use_utf8.md`.
  - **Two extra unit subtests (TC-U4c, TC-U4d)** — security-review subagent flagged that the open-pipe regex required parens, missing the bareword form `open my $fh, '-|', 'git', ...`. Regex tightened (terminate at `;` rather than requiring `)`); both forms locked in by tests.
- **Removals**: None — no work descoped.
- **Impact**: Net +1 module, +14-subtest test file, +41 `use utf8;` insertions, hash-manifest refresh for 34 entries plus one new entry. No effect on timeline.

### Quality Metrics
- **Test Coverage**: every assertion in `CWF::Validate::PerlConventions::validate()` has a red/green pair (`use_utf8`, `git_z`, `shebang`, POD exclusion, argument-paths exclusion, allowlist, non-Perl skip).
- **Defect Rate**: one finding from security review (bareword open form) — fixed in-task with regression tests, not deferred.
- **Performance**: not applicable — validate runs in well under a second on the full repo.

## What Went Well
- **Validator-module path was the right call over a stand-alone test**. Picking `CWF::Validate::PerlConventions` (wired into `cwf-manage validate`) over a `prove`-only test means every checkpoint commit catches drift, not just developers who happen to run the suite. The d-plan made this trade-off explicit and it paid off immediately on the planted-breakage smoke (TC-I3).
- **Hard-coded allowlist resisted comment-marker bypass**. TC-NF2 confirmed the design choice: a `# perl-git-paths-skip:` comment on a non-allowlisted script does not silence the check. Allowlist edits are visible in code review; comment markers wouldn't be.
- **Security review's pattern-risk finding was actionable, not theoretical**. The bareword `open` form is uncommon but legal Perl. Fixing it during f (rather than deferring) cost ~1 regex tweak + 2 subtests, and removed a future-trap.
- **Probe scripts at `/tmp/task-124/`** (after the no-heredocs correction) gave clear, reproducible evidence for TC-I4 and TC-NF2 — both required exercising `@GRANDFATHERED` semantics, hard to do as one-liners.

## What Could Be Improved
- **Initial audit conflated "non-ASCII bytes anywhere" with "non-ASCII in code"**. The byte-grep returned 9 files; once the new validator's POD/comment stripping was applied, only 3 had code-level non-ASCII. The plan had to be revised mid-exec. Had the audit been done with the validator's own logic from the start, the 9 → 3 transition wouldn't have happened. **Lesson**: when a task is auditing convention compliance, write the validator first and run it; don't pre-audit with a coarser tool.
- **The security-model correction was a planning omission**. The d-plan originally framed hash refresh as a routine `cwf-manage fix-security` step — wrong on two counts: fix-security only repairs perms, and end-user hash recompute is a permanent out-of-scope item (it would let any caller bless arbitrary script changes). The user surfaced both points in one correction. **Lesson**: any plan touching `script-hashes.json` needs to be explicit about *which side of the trust boundary* the change happens on (upstream maintainer vs. installed end user).
- **Personal-name leak in d-plan**. The first draft of the hash-refresh step named the maintainer ("Matt updates the JSON here"). Workflow-step docs are committed source — names rot, roles don't. Now codified as `feedback_no_name_in_wf_docs.md`.
- **First hash-refresh attempt used `perl -e` inline in Bash**. User flagged this against the existing no-heredocs / no-inline-script preference. Switched to `/tmp/task-124/refresh-hashes.pl` written via the Write tool, run as a file. Memory `feedback_no_heredocs.md` was updated to generalise from "no heredocs in commits" to "no inline scripts of any kind in Bash".

## Key Learnings

### Technical Insights
- **Convention checks belong inside `CWF::Validate::*`, not in `t/`-only tests**, when the goal is to catch drift on every workflow phase. The validate-after-checkpoint hook (`cwf-checkpoint-commit:53`) is the single most useful enforcement surface in CWF; new convention checks should default to landing there.
- **POD-stripping is non-optional for any source-level convention check**. POD examples that demonstrate anti-patterns are routine and must not produce false positives. The `s/^=\w+.*?^=cut\s*$//msg` idiom from this task's validator is reusable.
- **Open-pipe regex must terminate at `;` not `)`**. Bareword `open my $fh, '-|', 'git', ...` (no parens, no assignment) is legal Perl. Any future regex that matches `open` invocations must use `;|\z` as terminator.
- **`script-hashes.json` integrity surface is partial**. Currently covers `.cwf/lib/CWF/*.pm`, `.cwf/scripts/cwf-manage`, and a handful of named helpers, but **not** `.cwf/scripts/command-helpers/{context-manager,task-workflow,workflow-manager}` + their `*.d/` subdirs, nor `.cwf/scripts/hooks/`. They received `use utf8;` for convention compliance but tampering on them won't be detected. Tracked as a High-priority follow-up.

### Process Learnings
- **Mid-task rule widening is acceptable when the user explicitly directs it.** The 3 → 41 file-count expansion looked like scope creep but was actually scope clarification — the underlying rule was always meant to be unconditional; the implementation was over-narrow. Saving the rule as memory (`feedback_always_use_utf8.md`) ensures future tasks default to the right reading.
- **Security review's 500-line cap matters more than expected**. The full f-phase changeset was 778 lines (mostly mechanical `+use utf8;` insertions); the cap forced manual narrowing to a 250-line module+wiring subset (the actual judgement surface). The narrowing was the right call — the bulk was zero-judgement edits — but the *recording* of why the narrowing was acceptable needs to live in the wf step file, which it now does.
- **`g-testing-exec` Security Review block was an `error`, not `findings` or `no findings`**. The g-phase added no new judgement surface (only test execution), so re-running the subagent over the same 778-line diff would have been redundant. Recording `error: changeset exceeds 500-line review cap; …` with a pointer to the f-phase narrowed review is the correct disposition — but it's worth confirming this is the established pattern for "no new content this phase".

### Risk Mitigation Strategies
- **Per-script commits weren't necessary** — the `use utf8;` change is byte-level neutral (no behavioural effect on ASCII-only sources), so the original mitigation ("stage one script per commit so any regression is bisectable") was over-engineered. The bulk insertion was the right pragmatic call. The `prove -r t/` post-edit run validated this.
- **Allowlist over comment-marker** prevented an entire class of bypass. Worth applying to any future opt-out mechanism.

## Recommendations

### Process Improvements
- **For convention audits, write the validator first**. The validator's own logic *is* the audit; a pre-audit with byte-grep / find / shell is just a less-rigorous version of the same check.
- **`script-hashes.json` plan-text checklist**: any task whose plan touches `script-hashes.json` should call out (a) maintainer-side vs. end-user-side and (b) that hash regeneration is permanently out-of-scope for end users. Could be a one-line addendum to the implementation-plan template.

### Tool and Technique Recommendations
- **Reuse `CWF::Validate::*` violation-record idiom** (`{ category, file, field, actual, expected, fix }`) for any new check. `cmd_validate` already formats it; sticking to the shape avoids new infrastructure.
- **Write probe scripts to `/tmp/<task>/` via Write, not as Bash one-liners**. The two probe scripts in this task (`probe-grandfathered.pl`, `probe-no-comment-bypass.pl`) are reproducible artefacts that documented exactly what was tested; an inline `perl -e` would have evaporated.

### Future Work
- **High-priority follow-up — expand integrity surface** (added to BACKLOG.md as Task 124 follow-up): register `script-hashes.json` entries for `.cwf/scripts/command-helpers/{context-manager,task-workflow,workflow-manager}` + their `*.d/` subdirs and `.cwf/scripts/hooks/`. Without this, the convention check on these files is real but the bytewise-tamper check is absent — partial coverage.
- **Possible follow-up — scope `cwf-manage validate` to skip the source-pragma check on POD-only files**. Not needed yet; current rule is unconditional and the cost is one `use utf8;` line per file. Defer until/unless a Perl-file-without-source-pragma-by-design legitimately appears.

## Status
**Status**: Finished
**Next Action**: Suggest merge to user (do not execute)
**Blockers**: None identified
**Completion Date**: 2026-05-03
**Sign-off**: Task complete; convention drift now enforced at every checkpoint commit.

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Workflow files: `implementation-guide/124-chore-audit-perl-helpers-vs-perl-git-paths-conventions/{a,d,e,f,g,j}-*.md`
- New validator: `.cwf/lib/CWF/Validate/PerlConventions.pm`
- New unit test: `t/validate-perl-conventions.t` (14 subtests)
- Probe scripts: `/tmp/task-124/probe-grandfathered.pl`, `/tmp/task-124/probe-no-comment-bypass.pl`
- Memories created: `feedback_always_use_utf8.md`, `feedback_no_name_in_wf_docs.md`, `feedback_commit_backlog_changes.md`; updated: `feedback_no_heredocs.md`
- Convention doc: `docs/conventions/perl-git-paths.md` (now points to validator as drift check)
