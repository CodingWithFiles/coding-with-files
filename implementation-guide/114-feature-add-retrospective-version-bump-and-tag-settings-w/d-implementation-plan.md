# Add retrospective version bump and tag settings with versioning helper script - Implementation Plan
**Task**: 114 (feature)

## Task Reference
- **Task ID**: internal-114
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/114-add-retrospective-version-bump-and-tag-settings-w
- **Template Version**: 2.1

## Goal
Build the retrospective-phase versioning subsystem per the design: a `CWF::Versioning` module, three helper scripts, schema-validation extension, retrospective skill renumbering, and `version.yml` cleanup.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary Changes (new files)
- `.cwf/lib/CWF/Versioning.pm` — new module; version-with-config logic only: `next_version`, `current_version`, `bump_to`, `tag_at`, `read_config`, `wf_step_setting`
- `.cwf/scripts/command-helpers/cwf-version-next` — new ~20-line Perl wrapper; prints next version
- `.cwf/scripts/command-helpers/cwf-version-bump` — new ~25-line Perl wrapper; writes `versioning.last_released`
- `.cwf/scripts/command-helpers/cwf-version-tag` — new ~25-line Perl wrapper; creates annotated git tag
- `.cwf/docs/workflow/versioning-standard.md` — new doc describing semver scheme, ownership boundaries, and config fields

### Primary Changes (modifications)
- `.cwf/lib/CWF/Common.pm` — add pure semver utilities `parse_semver` and `version_cmp` (extracted from `cwf-manage`). These are general-purpose helpers used by both `cwf-manage` and the new `CWF::Versioning` module — better placed in the existing utility module than a versioning-specific one.
- `.cwf/scripts/cwf-manage` — replace inlined `parse_semver` and `version_cmp` (lines 166–189) with `use CWF::Common qw(parse_semver version_cmp)`; **must preserve numeric coercion** (`$p[0]+0, $p[1]+0, $p[2]+0`) — `cwf-manage-list-releases.t` will catch any drift
- `.cwf/lib/CWF/Validate/Config.pm` — add validation rules for optional `versioning` object (require `major_minor` matches `/^v\d+\.\d+$/` if present; allow optional `last_released` matching `/^v\d+\.\d+\.\d+$/`) and optional `wf_step_config` object (must be hash-of-hash-of-boolean)
- `.claude/skills/cwf-retrospective/SKILL.md` — renumber Steps 9–10 to 10–12; insert new Step 9 (bump) and Step 11 (tag); update Success Criteria to mention version actions

### Supporting Changes
- `implementation-guide/cwf-project.json` — add `versioning: { major_minor: "v1.0" }` and `wf_step_config: { retrospective: { bump_version: true, tag_version: false } }` blocks (CwF's own configuration)
- `version.yml` — rebrand `CIG` → `CwF`; rewrite to point at `cwf-project.json` as source of truth
- `.cwf/security/script-hashes.json` — register the three new scripts with their SHA256 hashes and `0500` permissions (or whatever `cwf-manage validate` enforces)

### Test Files (planning here; details in e-testing-plan.md)
- `t/versioning.t` — new; unit tests for `CWF::Versioning`
- `t/cwf-version-next.t`, `t/cwf-version-bump.t`, `t/cwf-version-tag.t` — new; integration tests using `t/lib/CWFTest/Fixtures.pm`
- `t/validate-config.t` — extend to cover the two new optional blocks
- `t/cwf-manage-list-releases.t` — verify still green after the parse_semver/version_cmp extraction (no test changes expected; this is the regression check)

## Implementation Steps

Order chosen so that each step lands a coherent, testable slice. Checkpoint commit after each numbered step.

### Step 1: Extract pure semver utilities to CWF::Common (no behaviour change)
- [ ] Add `parse_semver` and `version_cmp` to `.cwf/lib/CWF/Common.pm`; add to `@EXPORT_OK`. **Preserve the numeric-coercion return shape exactly** (`return @p ? ($p[0]+0, $p[1]+0, $p[2]+0) : ()`) — `cwf-manage`'s comparisons depend on numeric scalars.
- [ ] Update `cwf-manage` to `use CWF::Common qw(parse_semver version_cmp)`; delete the local `sub`s
- [ ] Run `prove t/cwf-manage-list-releases.t` — must pass unchanged (this is the regression check for the coercion contract)
- [ ] Extend `t/common.t` with cases for `parse_semver` (valid, missing v-prefix, missing patch, non-numeric) and `version_cmp` (equal, less, greater, mixed-length)

### Step 2: Versioning module — config and computation
- [ ] Create `.cwf/lib/CWF/Versioning.pm` with package boilerplate matching `CWF::TaskState`
- [ ] Add `read_config()` — opens `implementation-guide/cwf-project.json`, decodes JSON via `JSON::PP`. Returns hashref. Dies with field-naming error on missing config / missing major_minor / malformed major_minor (FR7)
- [ ] Add `wf_step_setting($step, $key, $default)` — returns `$cfg->{wf_step_config}{$step}{$key} // $default`
- [ ] Add `next_version(task_num => N)` — composes `major_minor + "." + N`
- [ ] Add `current_version()` — returns `versioning.last_released` from config, or `undef`
- [ ] Create `t/versioning.t` with cases: missing config (dies with path), missing major_minor (dies with field name), malformed major_minor (dies), defaults applied to wf_step_setting, next_version composition correctness, current_version absent vs present

### Step 3: Module — bump and tag operations
- [ ] Add `bump_to($version)` — atomic write of `cwf-project.json` via tmp + rename. **The temp file must be in the same directory as the target** (e.g., `implementation-guide/.cwf-project.json.tmp.$$`) so `rename()` is same-filesystem and atomic. Use `JSON::PP->new->pretty->indent_length(2)->canonical->encode($hash)`. Respects `wf_step_setting('retrospective','bump_version', 1)`; returns `{status, message}` hashref per design.
- [ ] Add `tag_at($version, message => $msg)` — checks main-branch (`git rev-parse --abbrev-ref HEAD` against config'd main, default `main`); refuses on existing tag; runs `git tag -a $version -m $msg`; respects `wf_step_setting('retrospective','tag_version', 0)`; returns `{status, message}` hashref
- [ ] Extend `t/versioning.t` with: bump skipped when flag false; bump idempotent; bump writes valid JSON; bump tmp file is same-dir; tag refuses off-main; tag refuses on existing tag; tag skipped when flag false

### Step 4: Three helper scripts
- [ ] Create `cwf-version-next`, `cwf-version-bump`, `cwf-version-tag` — each ~20-25 lines, `#!/usr/bin/env perl`, **inline `--task-num=N` parsing** (matching `cwf-set-status` style — no `Getopt::Long`; loop `@ARGV` with a `=` regex). For `cwf-version-tag` also accept `--message=STR`. Call into `CWF::Versioning`, print `{status}: {message}` per the CLI spec, exit 0/1 per design
- [ ] Keep scripts at `0700` during development (writable by owner) — defer `chmod 0500` to Step 10
- [ ] Create `t/cwf-version-next.t`, `t/cwf-version-bump.t`, `t/cwf-version-tag.t` — **inline tempdir + fixture-config** (matching `t/cwf-set-status.t` style; do NOT pull in `CWFTest::Fixtures.pm` — that's for full task-directory tests). Invoke scripts via `system`/backticks; assert stdout/stderr/exit
- [ ] **Manually** compute SHA256 for each new script (`sha256sum .cwf/scripts/command-helpers/cwf-version-*`) and add entries to `.cwf/security/script-hashes.json`. There is no auto-registration; `cwf-manage validate` only verifies hashes match — missing entries cause validation failure.
- [ ] Run `cwf-manage validate` — must pass

### Step 5: Schema validation extension
- [ ] Extend `CWF::Validate::Config::validate_config_hash` with rules from KD5
- [ ] Extend `t/validate-config.t` with new subtests: optional blocks absent (valid); valid present; malformed major_minor (violation); wf_step_config wrong shape (violation); non-boolean values (violation)

### Step 6: CwF self-configuration
- [ ] Add `versioning` and `wf_step_config` blocks to `implementation-guide/cwf-project.json`. **Format the manual edit canonically** (2-space indent, sorted keys within the new blocks) so the first `cwf-version-bump` run produces a value-only diff, not a formatting-noise diff
- [ ] Run `cwf-manage validate` — confirms the schema accepts our own settings
- [ ] Run `cwf-version-next --task-num=114` end-to-end — should print `v1.0.114`

### Step 7: version.yml rebrand and rewrite
- [ ] **First**, grep the codebase for `version.yml` consumers: `grep -rn 'version\.yml' --include='*.pm' --include='*.pl' --include='*.t' --include='*.md' --include='cwf-*' .`. If matches found outside of `version.yml` itself and this task's docs, **stop and update them as part of this step**; do not proceed assuming "none expected"
- [ ] Replace `CIG` with `CwF` throughout `version.yml`; remove `git-based-versioning: true`; replace with a short paragraph stating the new source-of-truth (`implementation-guide/cwf-project.json` → `versioning.major_minor` and `versioning.last_released`)

### Step 8: Documentation
- [ ] Write `.cwf/docs/workflow/versioning-standard.md`: scheme (semver), ownership (`major_minor` HITL, `last_released` script-owned), bump rules (when to bump major/minor by hand), config field reference, helper-script index, retrospective integration sequence (bump → squash → tag), formatting-normalisation note
- [ ] Reference the doc from each helper script's `--help`

### Step 9: Retrospective skill integration
- [ ] **First**, audit cross-references to the existing step numbering: `grep -rn -E "(cwf-retrospective.*step|step [0-9].*retrospective)" --include='*.md' --include='*.pm' .`. If any docs reference "Step 9" or "Step 10" of the retrospective skill by number, update them in this step too
- [ ] Edit `.claude/skills/cwf-retrospective/SKILL.md`:
  - Insert new Step 9: invoke `cwf-version-bump --task-num={current_task_num}` and report status; clarify that the resulting `cwf-project.json` change is staged with `j-retrospective.md`
  - Renumber existing Step 9 (squash) → Step 10
  - Insert new Step 11: invoke `cwf-version-tag --task-num={current_task_num} --message="Task {current_task_num}"` after squash; report status
  - Renumber existing Step 10 (suggest merge) → Step 12
  - Update Success Criteria checklist to include version-bump invocation
- [ ] Verify the skill renders correctly by running it on a future retrospective (cannot self-test — this task's retrospective will exercise it)

### Step 10: Final validation
- [ ] `chmod 0500` on all three new helper scripts (deferred from Step 4)
- [ ] Recompute SHA256 if any script content changed since Step 4; update `script-hashes.json` if needed
- [ ] `prove t/` — all tests pass
- [ ] `cwf-manage validate` — clean
- [ ] `cwf-version-next --task-num=114` — prints `v1.0.114`
- [ ] `cwf-version-bump --task-num=114` — verify it writes `last_released` correctly; inspect cwf-project.json formatting (should be canonical with no extraneous diff)
- [ ] No leftover `CIG` strings in `version.yml`: `grep -i 'cig' version.yml` returns empty

## Code Changes

### Before — `cwf-manage` lines 166-189
```perl
sub version_cmp {
    my ($a, $b) = @_;
    (my $va = $a) =~ s/^v//;
    (my $vb = $b) =~ s/^v//;
    my @pa = split /\./, $va;
    my @pb = split /\./, $vb;
    my $len = @pa > @pb ? scalar @pa : scalar @pb;
    for my $i (0 .. $len - 1) {
        my $na = $pa[$i] // 0;
        my $nb = $pb[$i] // 0;
        my $cmp = $na <=> $nb;
        return $cmp if $cmp;
    }
    return 0;
}

sub parse_semver {
    my ($tag) = @_;
    my @p = ($tag =~ /^v(\d+)\.(\d+)\.(\d+)$/);
    return @p ? ($p[0]+0, $p[1]+0, $p[2]+0) : ();
}
```

### After — `cwf-manage` (top of file)
```perl
use CWF::Common qw(parse_semver version_cmp);
# (sub definitions removed; CWF::Common is the single source of truth)
```

### New — script wrapper template (cwf-version-next)
```perl
#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use CWF::Versioning qw(next_version);

my $PROG = 'cwf-version-next';
my $task_num;
for (@ARGV) {
    if (/^--task-num=(\d+)$/) { $task_num = $1 + 0; next }
    warn "$PROG: unknown argument: $_\n"; exit 1;
}
unless (defined $task_num && $task_num > 0) {
    warn "Usage: $PROG --task-num=N (positive integer)\n";
    exit 1;
}

my $next = eval { next_version(task_num => $task_num) };
if ($@) { warn "$PROG: $@"; exit 1 }

print "$next\n";
exit 0;
```

(`cwf-version-bump` and `cwf-version-tag` follow the same shape, calling `bump_to`/`tag_at` and printing the returned `{status}: {message}`. Inline `@ARGV` parsing matches the codebase style — see `cwf-set-status`, `cwf-checkpoint-commit`.)

## Test Coverage
**e-testing-plan.md owns the comprehensive test matrix.** This file lists test additions inline with the steps that motivate them so the implementation flow is traceable; the testing-plan is the canonical authority on coverage and edge cases. If the two ever drift, `e-testing-plan.md` wins.

Summary:
- `CWF::Common`: extended `t/common.t` (Step 1) — semver parse and compare
- `CWF::Versioning`: new `t/versioning.t` (Steps 2-3) — config reading, computation, bump, tag, all error paths
- Helper scripts: new `t/cwf-version-{next,bump,tag}.t` (Step 4) — CLI integration
- Schema validation: extended `t/validate-config.t` (Step 5) — new optional blocks
- Regression: `t/cwf-manage-list-releases.t` (Step 1) — coercion contract preserved
- End-to-end smoke (Step 10): `cwf-version-next --task-num=114` against CwF's own config

## Validation Criteria
**See e-testing-plan.md for full criteria.** Implementation is complete when:
- All ten steps above are checked off
- `prove t/` passes (no regressions, new test files green)
- `cwf-manage validate` clean
- `cwf-version-next --task-num=114` prints `v1.0.114`
- `cwf-project.json` has the new blocks and validates
- `version.yml` is CIG-free and points to cwf-project.json
- Retrospective skill includes Steps 9 and 11 with version-helper invocations

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

This task explicitly bundles: schema, scripts, module, retrospective integration, and `version.yml` rebrand. All of these must land in this task — the `version.yml` rebrand was confirmed in scope when we discussed creating this task. No deferral expected.

If a deferral becomes necessary:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 114
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 10 steps executed in order. The `/simplify` cleanup pass after Step 10 was a bonus — three review agents found four real items (find_git_root extraction, $cfg threading, Validate::Config flattening, comment trimming), all applied.

## Lessons Learned
Listing test cases inline with implementation steps (rather than only in e-testing-plan.md) gave good test-driven momentum — wrote each test alongside the code it covers.
