# re-align Perl-script conventions to Task-27 form - Retrospective
**Task**: 139 (bugfix)

## Task Reference
- **Task ID**: internal-139
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/139-re-align-perl-script-conventions-to-task-27-form
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-15

## Executive Summary
- **Duration**: ~half a day across one session, against the planned 1-day estimate. On-target.
- **Scope**: Implemented as planned, with three small scope additions surfaced during the final-grep audit (`Common.pm` warning text, `cwf-init` SKILL.md template, `t/common.t` fixture) — all in-flight within the task. One pre-existing test (`t/backlog-manager-argv-utf8.t`) had to be re-pinned to the new contract.
- **Outcome**: Success. All 6 success criteria from `a-task-plan.md` met. Full test suite (463 tests) passes. Final repo-wide grep for `perl-git-paths` and `-CDSL\b` returns zero hits outside frozen scope.

## Variance Analysis

### Time and Effort
- **Estimated**: 1 day total. No phase-level breakdown estimated upfront.
- **Actual**: ~half a day across planning + exec.
- **Variance**: Under-budget. The scope was well-bounded by the backlog entry, and the four-milestone sequencing held without need for redesign.

### Scope Changes
- **Additions**:
  - `Common.pm` `check_perl5opt` warning message: still recommended `-CDSL` (without `A`). Surfaced by the final `-CDSL\b` grep; updated to `-CDSLA`. Required an extra hash regen for that module.
  - `.claude/skills/cwf-init/SKILL.md:149`: installed-skill template recommended `-CDSL`. Updated.
  - `t/common.t:31`: test fixture set `PERL5OPT='-CDSL'`. Updated to `-CDSLA` for narrative consistency (the test's regex matches either value, but the literal is now aligned with the convention).
  - `t/backlog-manager-argv-utf8.t`: had to be re-pinned. Task 137's regression cover proved the shebang was the contract by deleting `PERL5OPT` from the child env. Task 139 moves the contract to `PERL5OPT`, so the helper was renamed `run_bm_shebang_only` → `run_bm_with_perl5opt` and now sets `PERL5OPT=-CDSLA` in the child env. Same assertions.
- **Removals**: None.
- **Impact**: Negligible on timeline; small positive on completeness — the final-grep audit caught surfaces that the design-phase plan had not enumerated.

### Quality Metrics
- **Test Coverage**: `t/validate-perl-conventions.t` 17 subtests (10 fixture flips + 5 unchanged + 2 new TC-U9/U10). Every validator rule branch exercised by at least one positive and one negative subtest.
- **Defect Rate**: zero defects found during testing exec (after the within-phase fixes for the two transient failures documented in `g-testing-exec.md`).
- **Performance**: no measurable change. The new shebang rule adds one regex per file; negligible against File::Find traversal cost.

## What Went Well
- **Validate-first gate between shebang revert and hash regen** (design Decision 5) caught nothing wrong, but the explicit pre-condition made the hash splice low-risk by construction — exactly 12 expected mismatches, no surprise entries.
- **Reframing the validator change as "tightening" rather than "inversion"** (incorporated from plan-review feedback) kept the diff small and the surface visible. Net: ~25 lines of code change in `PerlConventions.pm`.
- **Positive-form shebang check** (instead of trying to reject every `-C*` variant via regex) sidestepped the regex-edge-case concerns flagged by three of the four plan-review subagents.
- **Final repo-wide grep as an explicit acceptance gate** (Decision 6) caught three live `-CDSL` references that the design surface list had missed. Without that gate, the convention drift would have re-asserted itself the next time someone followed the installed-skill template or read the warning message.

## What Could Be Improved
- **Security-review helper has a commit-ordering quirk**. `security-review-changeset` diffs `anchor..HEAD`, so when run from the f-implementation-exec skill before any commit lands, it sees zero. The skill's "empty changeset → no findings" fallback then silently skips the actual review. I recorded the implementation-phase review as `error` and provided a manual per-category analysis, but this is a real workflow papercut. (Backlog entry filed.)
- **The design plan listed four inbound-reference surfaces; the final grep found three more**. Not a process failure — that's exactly what the final-grep gate is for — but a hint that "design-time enumeration" alone is insufficient for any real audit. Always pair it with a recipe-based final check.
- **Re-pinning `t/backlog-manager-argv-utf8.t`** was foreseeable but not planned for. Task 137's test was explicitly built around "shebang is the contract"; any task moving that contract elsewhere would have to update it. Worth a mental rule: when you change the *mechanism* of a fix, audit any tests that pin that mechanism.

## Key Learnings

### Technical Insights
- **`env perl` + `PERL5OPT=-CDSLA` decouples three concerns** that hardcoded shebangs conflate: source pragma (`use utf8;`), I/O encoding (`-CDSL`), and `@ARGV` encoding (`-A`). Moving the runtime flags to an env var means a user-level convention change is one env edit, not 30+ shebang edits. This is the original Task-27 framing, restored.
- **The "too late for `-CDSLA`" failure mode is real**: when `PERL5OPT` already supplies some `-C` flags and the shebang tries to add `A`, perl rejects the post-init addition. The combination of env var + shebang flags is therefore strictly worse than env var alone.
- **Hash-regen via `sha256sum` + manual splice is tedious by design**. The `cwf-manage fix-security` command deliberately does *not* regenerate SHAs (it only repairs permissions when SHA still matches); this preserves the surface-don't-smooth invariant. Anyone building a hash-regen tool needs to consciously preserve that.

### Process Learnings
- **Four parallel plan-review subagents per planning phase** caught the validator-scope ambiguity that was buried in three of my own plan documents. Without that step, I would have implemented an ambiguous rule and discovered the ambiguity at test time.
- **The validate-first gate idiom generalises**: any time you have a deterministic transformation (here: 11 mechanical edits) followed by a non-deterministic step (here: hash regen against transformed bytes), inserting `validate` in between gives you a free integrity check that doesn't depend on the transformation being perfect.
- **POSITIVE-form rules beat NEGATIVE regex rules** when the spec is "must look like X". A positive form fails fast and unambiguously on the *first byte* that doesn't match; a negative regex has to enumerate every disallowed variant and is brittle to edge cases (e.g., whitespace handling).

### Risk Mitigation Strategies
- **Surface-don't-smooth**: the manual hash splice felt tedious; the temptation to write a one-shot regen script was real. Not yielding to it preserved the property that a future review can spot a smoothed-out tampering signal. The friction is the feature.
- **Live vs frozen scope policy** (design Decision 6) made the two-tier inbound-reference audit tractable. `implementation-guide/` and `### Retired Backlog Items` are immutable history; everything else is live. This rule is worth standardising for future tasks that touch cross-cutting strings.

## Recommendations

### Process Improvements
- **Add the final-grep acceptance gate to convention rebrands** as a standing step. Three of the seven live surfaces were not enumerated at design time — the gate caught them.
- **When a task changes the mechanism of a previous fix**, search the test files for code that pins the *mechanism* (not just the *outcome*) of the prior fix and plan to update them. The `run_bm_shebang_only` helper named what it was pinning; not all such helpers do.
- **Document the commit-first ordering for security-review-changeset**, or change the helper to diff working tree against the anchor. Either is a small change; right now the skill's "no findings: empty changeset" path silently skips a real review when called mid-uncommitted-work.

### Tool and Technique Recommendations
- **Pre-splice hash review** (write all 12 computed hashes to a temp file, compare against current `script-hashes.json` for expected set, *then* splice) is a worth-adopting habit for any future multi-file hash regen.
- **Plan-review subagents in parallel for all three plan types** (requirements, design, implementation) — used for design and implementation in this task; design caught the validator-scope ambiguity that became Decision 3's positive-form pivot.

### Future Work
- **`security-review-changeset` helper ordering quirk** — backlog entry.
- **`check_perl5opt` warning could be tightened** to specifically recommend `-CDSLA` (today it accepts any `-C` form silently). Possible future task if users continue hitting the Task-137 mojibake despite the doc updates.
- The "Split `validate_path_allowlist` into write/read/temp variants" backlog item (Very High) is the second structural defect surfaced by Task 137 and is independent of this task — it remains open.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-15
**Sign-off**: the maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Branch: `bugfix/139-re-align-perl-script-conventions-to-task-27-form`
- Phase commits:
  - `44d3ae1` — task plan
  - `598dd78` — design plan (post-subagent review)
  - `dcbd352` — implementation plan (post-subagent review, positive-form rule pivot)
  - `f073aa2` — testing plan
  - `0420a14` — implementation exec
  - `d028f77` — testing exec (security-review subagent: no findings)
- Baseline commit: `4630568` (Task 138)
