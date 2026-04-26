# Add retrospective version bump and tag settings with versioning helper script - Retrospective
**Task**: 114 (feature)

## Task Reference
- **Task ID**: internal-114
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/114-add-retrospective-version-bump-and-tag-settings-w
- **Template Version**: 2.1
- **Retrospective Date**: 2026-04-26

## Executive Summary
- **Duration**: 1 session (estimated: 1-2 days, on the lower end)
- **Scope**: Delivered as planned (FR1-FR7, AC1-AC7) plus a self-applied `/simplify` cleanup pass and an in-task fix to `retrospective-extras.md` step numbering after the SKILL.md renumber
- **Outcome**: Versioning subsystem operational; CwF eats its own dog food (this task's retrospective is the first to invoke `cwf-version-bump` for real)

## Variance Analysis

### Time and Effort
- **Estimated**: 1-2 days (a-task-plan.md)
- **Actual**: 1 session (under estimate)
- **Variance**: -50% to -75% — partly because plan-review subagents caught design issues early (saving rework), partly because the codebase patterns were well-established (CWF::Common, CWF::Validate::Config, helper-script Perl skeleton), so most of the work was filling in shaped templates

### Scope Changes
- **Additions**: 
  - `/simplify` cleanup pass (one extra commit) — extracted `find_git_root` to `CWF::Common`, threaded `$cfg` through `bump_to`/`tag_at`, flattened Validate::Config helpers, removed two restating comments
  - Mid-retrospective fix to `retrospective-extras.md` step-number labels — direct consequence of the SKILL.md renumbering this task introduced; caught only on actually running the retrospective skill
- **Removals**: 
  - TC-V13 (forced write-failure test) descoped — covered structurally by `File::Temp::DIR` + atomic-rename pattern; testing it requires lower-level FS manipulation that adds harness complexity for marginal value
  - TC-V12 (rename-hook) ended up as a graceful SKIP rather than hard assertion — same-dir behaviour is implicitly verified by TC-V11 succeeding
- **Impact**: None on the task's stated criteria; the cleanup pass strictly improved the result

### Quality Metrics
- **Test Coverage**: 33 new test assertions (196 → 229 total); 100% of `CWF::Versioning` public API and helper-script exit-code/stdout contracts covered
- **Defect Rate**: 0 defects found in testing (g-testing-exec); 1 caught only at retrospective execution (the doc step-number rot) — fixed in-task
- **Performance**: `cwf-version-next --task-num=114` 27ms (NFR1 budget: <500ms; 18× under)

## What Went Well

- **Plan-review subagents caught real issues across all three phases**:
  - Requirements review: surfaced the human-only-tag confusion (CwF-internal vs externally-imposed), the Perl `-CDSL` requirement, and the test-case ownership ambiguity
  - Design review: caught the existing `parse_semver`/`version_cmp` in `cwf-manage` that justified the module extraction; flagged that the optional `--task-num` was a silent-failure trap (made required)
  - Implementation review: flagged Getopt::Long as out-of-codebase-style; flagged `CWFTest::Fixtures` as the wrong fit; flagged numeric-coercion contract as worth pinning explicitly
- **`/simplify` review still found four real things** even after the three plan reviews — the layered approach (plan reviews + post-impl review) is paying for itself
- **Eating own dog food worked**: this very retrospective ran `cwf-version-bump` for the first time and bumped `versioning.last_released` to `v1.0.114`. The new SKILL.md sequence (write j-retro → bump → squash → tag) was exercised end-to-end
- **Codebase patterns were ready**: `CWF::Common` was the right home for `find_git_root` and the semver utilities; `CWF::Validate::Config` had the exact extension shape needed; helper-script Perl skeleton from `cwf-set-status` made the three new scripts mechanical to write

## What Could Be Improved

- **Cross-doc step-number rot**: `retrospective-extras.md` had section labels ("Step 9", "Step 10", "Step 11") tied to `SKILL.md`'s numbering. When SKILL.md renumbered, the extras file silently drifted. The d-implementation-plan Step 9 grep audit only looked for cross-references *to* the skill, not for *internal* docs that mirror its numbering. **Fix**: when renumbering a skill, also `grep` its own `.cwf/docs/skills/*-extras.md` for "Step N" labels — caught in this task by actually running the retrospective, but should be in the audit
- **First-bump JSON normalisation diff was large**: per design KD9 (one-time formatting noise), but the actual diff in `cwf-project.json` was bigger than expected because the manual edit in Step 6 wasn't pre-canonicalised. The plan said "format the manual edit canonically" but didn't enforce it — easy to miss in execution
- **Workflow has no built-in "verify SKILL.md edits don't orphan section anchors"**: I changed step numbers in the cwf-retrospective skill. The extras file's anchors (`#changelogmd-and-backlogmd-update`, `#checkpoints-branch-and-squash`) survived, but only because they're slug-anchors not number-anchors. Worth a follow-up gotcha

## Key Learnings

### Technical Insights
- **`File::Temp->new(DIR => dirname($target))`** is the cleanest way to enforce same-filesystem atomic rename — no need for manual tempfile naming
- **Numeric coercion via `+0` matters in `parse_semver`** — `cwf-manage`'s `filter_releases` does numeric comparisons; without `+0` the extracted version components arrive as strings and `<=>` comparisons silently break. The regression test (`t/cwf-manage-list-releases.t` passing unchanged) was the canary
- **Threading `$cfg` through `bump_to`/`tag_at` matters even at single-call scale** — not for performance (file is 4KB) but for testability: a test fixture can pass a hand-built `$cfg` without staging a real `cwf-project.json`
- **JSON pretty-print canonicalisation is a one-way door**: once a file is normalised, all subsequent diffs are value-only — but the first diff is loud. Pre-canonicalise the manual edit to keep the first commit readable

### Process Learnings
- **Plan reviews compound**: each phase's review finds different categories of issues. Requirements review found scope/policy questions; design review found pattern-reuse opportunities; implementation review found convention deviations; `/simplify` post-impl review found the duplications I created in the three thin scripts
- **The dog-food principle catches doc rot**: `retrospective-extras.md` step-number rot was invisible until running the retrospective. There's no static check for "doc references match the skill they extend" — only execution exposes it
- **Plan-review skip-rejection works**: I rejected several findings (constants for status strings, arg-parser extraction, `format_error` in scripts) with explicit rationale. None of those rejections came back to bite during implementation or testing. The "explain *why* you skip" discipline is healthy

### Risk Mitigation Strategies
- **Schema additions strictly additive**: backwards-compat for existing `cwf-project.json` files was zero-risk because absent fields fall back to documented defaults. Validation rules only fire on present-but-malformed values
- **CwF defaults match CwF policy**: `bump_version: true`, `tag_version: false` codifies the human-only-tag rule from CLAUDE.md without making external adopters inherit it. The defaults are CwF's policy; adopters can flip either flag

## Recommendations

### Process Improvements
- **Add to skill-renumber audit**: when changing step numbers in any `*/SKILL.md`, also grep the corresponding `.cwf/docs/skills/*-extras.md` for "Step N" labels and fix
- **Add to canonical-JSON-edit gotcha**: when manually editing a file that an atomic-write helper will canonicalise, format the manual edit in the same canonical shape to avoid noisy first-write diffs

### Tool and Technique Recommendations
- **The 3-agent map/reduce review at every plan phase is worth its compute cost** — confirmed for the third time in a row (Tasks 110, 111, 113 all benefitted). No reason to weaken or skip
- **`/simplify` after major implementations**: a ~5-minute cleanup pass found 4 actionable items here, all fixed in <10 minutes. High ROI

### Future Work (proposed BACKLOG additions)
- **Skill cross-reference linter** (chore, low priority): a small script that, given a `*/SKILL.md`, greps the corresponding `*-extras.md` for "Step N" labels and warns if any number doesn't appear in the SKILL.md's step list
- **Pluggable versioning schemes** (feature, low priority): the design's `versioning` block is shaped to accept a future `scheme` field (calver, monotonic, etc.) without breaking existing projects. Build when a real second-scheme need arrives, not before
- **`CWF::Common::write_json_atomic`** (chore, very low priority): if a second helper needs to mutate `cwf-project.json` in the future, factor the tmp+rename+canonical-encode pattern out of `CWF::Versioning::bump_to`. Rule of three not yet met — defer

## Status
**Status**: Finished
**Next Action**: Suggest merge to user (do not execute)
**Blockers**: None identified
**Completion Date**: 2026-04-26
**Sign-off**: Matt Keenan / Claude Opus 4.7

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Plan: `a-task-plan.md` through `e-testing-plan.md` (in this directory)
- Execution: `f-implementation-exec.md`, `g-testing-exec.md`
- Rollout/maintenance: `h-rollout.md`, `i-maintenance.md`
- Code: `.cwf/lib/CWF/Versioning.pm`, `.cwf/lib/CWF/Common.pm` (extended), three `cwf-version-*` scripts under `.cwf/scripts/command-helpers/`, `.cwf/lib/CWF/Validate/Config.pm` (extended)
- Docs: `.cwf/docs/workflow/versioning-standard.md`
- Skill integration: `.claude/skills/cwf-retrospective/SKILL.md` (Steps 9 + 11 added), `.cwf/docs/skills/retrospective-extras.md` (step-number labels updated in this phase)
- Tests: `t/versioning.t`, `t/cwf-version-{next,bump,tag}.t`, `t/common.t`, `t/validate-config.t` (extensions)
