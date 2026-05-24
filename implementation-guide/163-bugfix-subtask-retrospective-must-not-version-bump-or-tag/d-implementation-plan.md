# subtask retrospective must not version-bump or tag - Implementation Plan
**Task**: 163 (bugfix)

## Task Reference
- **Task ID**: internal-163
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/163-subtask-retrospective-must-not-version-bump-or-tag
- **Template Version**: 2.1

## Goal
Add a shared `is_subtask_num` predicate and route subtask task numbers to a clean skip in all three version helpers, per the approved design.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cwf/lib/CWF/Versioning.pm` — add and export `is_subtask_num`.
- `.cwf/scripts/command-helpers/cwf-version-bump` — import predicate; relax `--task-num` capture; skip subtasks.
- `.cwf/scripts/command-helpers/cwf-version-tag` — same.
- `.cwf/scripts/command-helpers/cwf-version-next` — same.

### Supporting Changes
- `.cwf/security/script-hashes.json` — refresh four `sha256` entries (`CWF::Versioning`, `cwf-version-bump`, `cwf-version-tag`, `cwf-version-next`) **in the same commit** (`docs/conventions/hash-updates.md`).
- `.cwf/docs/workflow/versioning-standard.md` — document the top-level-only policy.
- `.claude/skills/cwf-retrospective/SKILL.md` — one-line clarifier on Steps 9 & 11.
- `t/versioning.t`, `t/cwf-version-bump.t`, `t/cwf-version-tag.t`, `t/cwf-version-next.t` — new assertions (detail in e-testing-plan.md).

## Implementation Steps
### Step 1: Predicate in the module
- [ ] Add `is_subtask_num` to `@EXPORT_OK` in `CWF::Versioning.pm`.
- [ ] Define the sub near `next_version`.

### Step 2: Wire each helper
- [ ] `cwf-version-bump`: add `is_subtask_num` to the `use CWF::Versioning qw(...)` import; replace the `--task-num` arm.
- [ ] `cwf-version-tag`: same (keep the `--message` arm intact).
- [ ] `cwf-version-next`: same.
- [ ] Add a one-line subtask note to each `usage()`.

### Step 3: Tests (see e-testing-plan.md)
- [ ] `versioning.t`: `is_subtask_num` truth table with explicit malformed-false rows — `3.2`/`3.2.1` → true; `163`/`3.`/`.2`/`3..2`/`undef` → false (locks the predicate contract independently of the capture regex).
- [ ] Each helper `.t`: `--task-num=3.2` → exit 0 + `skipped:` line; `--task-num=3.` / `.2` / `3..2` → exit 1 `unknown argument`; integer path unchanged.
- [ ] Strong "no side effect" probe: invoke each helper with `--task-num=3.2` against an **absent/malformed** `cwf-project.json` and assert it still exits 0 with the skip line — proving the skip short-circuits before `read_config()`.
- [ ] `cwf-version-tag` skip case exercised **with** a `--message` arg present (`--task-num=3.2 --message=foo` and the reversed order), confirming no interaction.
- [ ] Run full `prove t/` — no regressions.

### Step 4: Docs
- [ ] `versioning-standard.md`: add "Top-level only" subsection; amend the "required positive integer" sentence.
- [ ] `SKILL.md`: clarifier on Steps 9/11 (no command change).

### Step 5: Integrity + perms
- [ ] `sha256sum` each of the four hashed paths; update entries in `script-hashes.json`.
- [ ] Restore script working perms to 0700 (`feedback_hashed_script_working_perms`); leave `Versioning.pm` mode as-is.
- [ ] `.cwf/scripts/cwf-manage validate` → clean (modulo the pre-existing, unrelated `cwf-security-reviewer-changeset.md` perms drift).

## Code Changes

### `CWF::Versioning.pm` — export list
```perl
our @EXPORT_OK = qw(
    read_config
    wf_step_setting
    next_version
    current_version
    bump_to
    tag_at
    config_path
    is_subtask_num
);
```

### `CWF::Versioning.pm` — new sub (place above `next_version`)
```perl
# True iff $n is a hierarchical subtask number (one or more dotted segments,
# e.g. "3.2", "3.2.1"). Top-level numbers ("163") are false. The version
# helpers use this to skip version actions for subtasks, which merge to a
# parent branch and release nothing. See versioning-standard.md.
sub is_subtask_num {
    my ($n) = @_;
    return (defined $n && $n =~ /^\d+(?:\.\d+)+$/) ? 1 : 0;
}
```

### Per-helper `--task-num` arm (bump / tag / next, identical shape)
Before:
```perl
    if (/^--task-num=(\d+)$/) { $task_num = $1 + 0; next }
```
After:
```perl
    if (/^--task-num=(\d+(?:\.\d+)*)$/) {
        my $n = $1;
        if (is_subtask_num($n)) {
            print "skipped: version actions apply to top-level tasks only (subtask $n)\n";
            exit 0;
        }
        $task_num = $n + 0;
        next;
    }
```
`is_subtask_num` is **appended** to each helper's existing import list (not a replacement):
- `cwf-version-bump`: `use CWF::Versioning qw(read_config next_version bump_to is_subtask_num);`
- `cwf-version-tag`: `use CWF::Versioning qw(read_config next_version tag_at is_subtask_num);`
- `cwf-version-next`: `use CWF::Versioning qw(next_version is_subtask_num);`

The `--task-num` arm Edit is applied **per file** — `cwf-version-tag` has an adjacent `--message` arm, so the surrounding context differs and a single shared replacement won't match.

The skip arm sits **before** the `--help` and catch-all arms, and exits inside the
`@ARGV` loop — ahead of any `read_config()`/`eval`. Malformed values (`3.`, `.2`,
`3..2`, non-numeric) do not match the relaxed capture and fall through to the
existing `unknown argument` error unchanged.

### `usage()` addition (each helper)
```
  A subtask number (e.g. 3.2) is a no-op: version actions apply to top-level tasks only.
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

All four hashed paths are refreshed in the implementation commit — no deferral to retrospective (`hash-updates.md`).

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Every step executed as planned with no deviations (detail in `f-implementation-exec.md`). The per-file `--task-num` edit was necessary as predicted — `cwf-version-tag`'s adjacent `--message` arm meant a single shared replacement would not match. All four `sha256` entries refreshed in the implementation commit; working perms restored to 0700.

## Lessons Learned
The plan's explicit "skip arm before `read_config()`/`eval`" instruction translated directly into a passing no-side-effect test (TC-2). Pinning the malformed-value edge cases (`3.`/`.2`/`3..2`) in the plan meant the exec phase had unambiguous acceptance. See `j-retrospective.md`.
