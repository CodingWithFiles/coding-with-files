# unify sandbox and non-sandbox scratch path - Implementation Plan
**Task**: 229 (feature)

## Task Reference
- **Task ID**: internal-229
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/229-unify-sandbox-non-sandbox-scratch-path
- **Template Version**: 2.1

## Goal
Implement the EUID-derived scratch base per c-design-plan: `scratch_parent` returns
`/tmp/claude-$>/cwf<dashed-root>` with no `$TMPDIR` read; retire the probe; guard the new
intermediate; give all `scratch_dir` callers a uniform fail-closed hint; rewrite the
convention doc. Refresh hashes for the four hashed scripts in the same commit.

**Design refinement (from reading the callers)**: c-design D3 proposed `scratch_dir`
return the attempted path in slot 1 on failure. But `security-review-changeset:287` and
`plan-mechanical-check:119` branch on `unless (defined $scratch)` — returning a defined
path on failure would skip their error branch. So instead **keep `scratch_dir`'s
`(undef, $kind)` contract unchanged** and centralise the diagnostic in a new
`scratch_fail_hint($kind)` helper that references `$SCRATCH_BASE`; each caller appends it.
Same observable outcome (uniform, cause-naming hint), no contract trap. This plan is
authoritative for exec; c-design's D3/Interface still describe the abandoned slot-1
contract — reconcile that wording at rollout (h).

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cwf/lib/CWF/Common.pm` *(hashed)* —
  - rename `$SANDBOX_TMP_PROBE` → `$SCRATCH_BASE`, default `"/tmp/claude-$>"` with a
    `# $> = effective UID` comment; **rewrite the two now-stale header comments**: the
    `scratch_parent` block (≈87-104, describes the deleted env/probe branches) and the
    `scratch_dir` block (≈124-135, describes a *one*-level guard);
  - rewrite `scratch_parent`: drop the `$ENV{TMPDIR}` read, the `$SANDBOX_TMP_PROBE`
    `lstat` branch, the `$base` variable and `s{/+$}{}` trailing-slash strip; after the
    `not_a_repo` guard, `return ("$SCRATCH_BASE/cwf$dashed", undef)`;
  - extend `scratch_dir` to the **two-level** guard by iterating
    `for my $dir ($SCRATCH_BASE, $parent)` and running the **full existing triad per
    level in order**: `mkdir($dir, 0700) unless -d $dir` → `-l $dir` ⇒ `symlink_parent`
    → `-d $dir` ⇒ `mkdir_failed`. The base level's triad **must complete before** the
    parent `mkdir` (else the parent mkdir would follow a symlinked base — the security
    finding). `(undef, $kind)` contract unchanged; leaf still `mkdir … or return
    (undef,'mkdir_failed')`;
  - add `scratch_fail_hint($kind)` (exported): a static cause-naming sentence for
    `mkdir_failed` (base `$SCRATCH_BASE` not writable — custom TMPDIR / non-Linux sandbox)
    **and** for `symlink_parent` (a planted symlink at the scratch base/parent); `''`
    otherwise. Callers compose it **before the terminal `\n`** and omit it (no stray
    line/space) when it is `''`.
- `.cwf/scripts/command-helpers/best-practice-resolve` *(hashed)* — replace
  `scratch_out_path`'s inline `$ENV{TMPDIR}` base + mkdir/guard with a `scratch_dir($num)`
  call (list-context assign), map `$kind` to the existing warn+`exit 1` **plus**
  `scratch_fail_hint`, then append the `best-practice-context-<phase>.out` leaf; import
  `scratch_dir`, `scratch_fail_hint`. **Also fix the two stale `${TMPDIR:-/tmp}`
  path-form doc-strings in this same file** (header comment line 36, `print_usage` output
  line 174) to the EUID form.
- `.cwf/scripts/command-helpers/security-review-changeset` *(hashed)* — append
  `scratch_fail_hint($kind)` to the `scratch unavailable` warn (line 288); import the
  helper; fix the three stale `${TMPDIR:-/tmp}` path-form references (comment header ~65,
  body comment ~282, `print_usage` output ~398) to the EUID form.
- `.cwf/scripts/command-helpers/plan-mechanical-check` *(hashed)* — append
  `scratch_fail_hint($kind)` to the `cannot resolve scratch dir` warn (line 120); import
  the helper.

### Supporting Changes
- `.cwf/docs/conventions/tmp-paths.md` — rewrite Convention/Derivation snippet/Sandbox-
  alignment for the EUID base (drop `${TMPDIR:-/tmp}` and probe wording); update worked
  and permission-allowlist examples; add the two-level guard to § Threat model; record the
  macOS known-limitation.
- `t/scratch.t` — test-seam sweep (`local $ENV{TMPDIR}` → `local
  $CWF::Common::SCRATCH_BASE`), drop TC-9/TC-10 (probe), add EUID/poison-`$TMPDIR`/
  intermediate-guard/hint cases. **Detailed in e-testing-plan.**
- `.cwf/security/script-hashes.json` *(hashed manifest)* — refresh sha256 for the **four**
  modified hashed scripts in this same commit.

- **Deletes**: $SANDBOX_TMP_PROBE

**Superseded backlog item**: the active `BACKLOG.md` entry proposing a
`CWF::Common::tmp_base()` helper (to DRY the `${TMPDIR:-/tmp}` idiom across four sites)
is largely mooted — this task removes that idiom from `scratch_parent` and the callers,
leaving only the out-of-scope `pretooluse-bash-tool-check`. Retire/trim that entry at
rollout (h). (Historical references — CHANGELOG, Task-215 impl-guide docs — are not
rewritten.)

## Implementation Steps
### Step 1: Setup
- [ ] On the task branch; re-read c-design-plan Key Decisions D1–D5 and this file.
- [ ] `grep -rn 'SANDBOX_TMP_PROBE' .cwf t` to enumerate every reference before renaming.

### Step 2: Core library (`CWF::Common.pm`)
- [ ] Rename the package scalar and its doc-comment; add the `$>` annotation.
- [ ] Rewrite `scratch_parent` to the pure `"$SCRATCH_BASE/cwf$dashed"` form; delete the
      inert `$base`/trailing-slash/`$ENV{TMPDIR}`/probe code.
- [ ] Extend `scratch_dir` two-level guard (intermediate + parent), race-tolerant ordering.
- [ ] Add `scratch_fail_hint`; add it to `@EXPORT_OK`.

### Step 3: Callers
- [ ] `best-practice-resolve`: delegate `scratch_out_path` to `scratch_dir`; map errors +
      hint; delete inline derivation.
- [ ] `security-review-changeset`: add hint; fix the three stale path-form strings.
- [ ] `plan-mechanical-check`: add hint.

### Step 4: Doc + tests
- [ ] Rewrite `tmp-paths.md` (see Supporting Changes).
- [ ] Rework `t/scratch.t` per e-testing-plan; `prove -r t/` green.

### Step 5: Hashes + validation
- [ ] Refresh `script-hashes.json` for the four scripts (same commit); restore working
      perms to the **recorded** values (per hashed-script perms rule).
- [ ] `cwf-manage validate` clean; smoke-test an output artefact (run `best-practice-resolve`
      and confirm the `.out` lands under `/tmp/claude-$>/cwf<dashed-root>/task-229/`).

## Code Changes
### Before — `scratch_parent` (Common.pm:105-122)
```perl
sub scratch_parent {
    my ($root) = @_;
    $root = find_git_root() unless defined $root && length $root;
    return (undef, 'not_a_repo') unless defined $root && length $root;
    (my $dashed = $root) =~ s{/}{-}g;
    my $base;
    if (defined $ENV{TMPDIR} && length $ENV{TMPDIR}) { $base = $ENV{TMPDIR}; }
    elsif (length $SANDBOX_TMP_PROBE && !-l $SANDBOX_TMP_PROBE && -d _ && -w _) {
        $base = $SANDBOX_TMP_PROBE;
    } else { $base = '/tmp'; }
    $base =~ s{/+$}{};
    return ("$base/cwf${dashed}", undef);
}
```
### After
```perl
our $SCRATCH_BASE = "/tmp/claude-$>";   # $> = effective UID; the sandbox's per-uid
                                        # writable session temp (Linux/WSL2)
sub scratch_parent {
    my ($root) = @_;
    $root = find_git_root() unless defined $root && length $root;
    return (undef, 'not_a_repo') unless defined $root && length $root;
    (my $dashed = $root) =~ s{/}{-}g;
    return ("$SCRATCH_BASE/cwf${dashed}", undef);   # $TMPDIR not read (mode-invariant)
}
```

## Test Coverage
**See e-testing-plan.md for complete test plan** (EUID base, poison-`$TMPDIR` invariance,
two-level intermediate symlink guard, `scratch_fail_hint`, delegated `scratch_out_path`).

## Validation Criteria
**See e-testing-plan.md.** Gate: `prove -r t/` green, `cwf-manage validate` clean, and an
output-artefact smoke test confirming the `.out` path form.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Executed as planned across the four hashed files. The one refinement over c-design (the
`scratch_fail_hint` helper in place of D3's return-shape change) was decided here and carried
cleanly into exec.

## Lessons Learned
Deferring the diagnostic *mechanism* from design to implementation planning let the plan pick
the lower-coupling option (a helper) once the caller shapes were concrete.
