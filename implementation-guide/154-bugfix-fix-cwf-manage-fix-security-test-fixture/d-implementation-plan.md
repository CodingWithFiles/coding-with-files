# fix cwf-manage-fix-security test fixture - Implementation Plan
**Task**: 154 (bugfix)

## Task Reference
- **Task ID**: internal-154
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/154-fix-cwf-manage-fix-security-test-fixture
- **Template Version**: 2.1

## Goal
Concrete edit list: add `_provision_extra_manifest_paths($tmp)` to `t/cwf-manage-fix-security.t` and call it from `build_fixture`, so the fixture provisions every manifest-tracked path outside `.cwf/`.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `t/cwf-manage-fix-security.t` (NOT hashed) — add the helper `_provision_extra_manifest_paths($tmp)` (place it just before `build_fixture`, alongside the other `_`-prefixed fixture helpers at lines 25-47); add a single call to it inside `build_fixture` after `git init`.

### Supporting Changes
- None. No production code, no hashed file, no hash refresh, no doc change. `decode_json` is already imported (line 18).

## Implementation Steps

### Step 1 — Add the helper (before `build_fixture`, after `_ensure_cwf_manage_executable` at line 47)
```perl
# _provision_extra_manifest_paths($tmp)
# build_fixture copies .cwf/ wholesale (the cwf-manage runtime tree), but the
# hash manifest also tracks paths *outside* .cwf/ (currently .claude/agents/*.md).
# cmd_validate/cmd_fix_security resolve every manifest path against the fixture
# git root ("$git_root/$rel"), so those files must exist there too or they read
# as missing. Copy each manifest-tracked path whose top segment is not ".cwf".
#
# Read $REPO_ROOT's manifest (byte-identical to the copy just made under $tmp;
# reading $REPO_ROOT keeps this independent of copy ordering — do NOT "align" it
# with _read_recorded_perms's $tmp read). Manifest paths are repo-controlled,
# integrity-tracked, repo-relative strings (no "..", no absolute) — the same
# trust cmd_fix_security places in them at cwf-manage:743. cp -p preserves perms
# (umask-independence) and yields byte-identical content, so the fixture
# satisfies the existence / SHA256 / perm-floor checks.
sub _provision_extra_manifest_paths {
    my ($tmp) = @_;
    my $manifest = "$REPO_ROOT/.cwf/security/script-hashes.json";
    open my $fh, '<', $manifest or die "$manifest: $!";
    local $/;
    my $data = decode_json(<$fh>);
    close $fh;

    for my $section (sort keys %$data) {
        my $entries = $data->{$section};
        next unless ref $entries eq 'HASH';          # skip scalar sections (version, last_updated)
        for my $name (sort keys %$entries) {
            my $entry = $entries->{$name};
            next unless ref $entry eq 'HASH' && exists $entry->{path};
            my $rel = $entry->{path};
            next if $rel =~ m{^\.cwf/};               # .cwf/ already copied wholesale
            # Fail closed: $rel is integrity-tracked + repo-relative today; guard
            # anyway so a future/untrusted manifest can't escape $tmp via the cp.
            die "refusing unsafe manifest path: $rel"
                if $rel =~ m{(?:^/|(?:^|/)\.\.(?:/|$))};
            my $src = "$REPO_ROOT/$rel";
            my $dst = "$tmp/$rel";
            (my $dir = $dst) =~ s{/[^/]+$}{};
            my $mrc = system("mkdir", "-p", $dir);
            die "mkdir -p $dir failed (rc=$mrc)" if $mrc != 0;
            my $crc = system("cp", "-p", $src, $dst);
            die "cp -p $rel into fixture failed (rc=$crc)" if $crc != 0;
        }
    }
}
```
Notes:
- The per-entry `ref eq 'HASH' && exists $entry->{path}` guard is the simpler equivalent of `cmd_fix_security`'s two-pass file-map detection (`cwf-manage:729-740`): scalar sections are skipped by the outer `ref $entries eq 'HASH'`, non-file entries by the inner guard. Same set of paths, less code.
- `(my $dir = $dst) =~ s{/[^/]+$}{}` strips the filename to get the parent dir without mutating `$dst`.
- The fail-closed `..`/absolute guard is intentionally *stricter* than the production callsite (`cwf-manage:743` does no such check). That asymmetry is deliberate: the production tool trusts its own integrity-tracked manifest, while the test helper fails loud if that trust is ever violated. One line; does not claim production should match.

**Trade-off considered (plan review):** a one-line `cp -rp $REPO_ROOT/.claude/agents $tmp/.claude/agents` would be shorter, but it hard-codes `.claude/agents` — the moment a future task tracks a path under a different root (e.g. `.claude/hooks/x`), the fixture silently omits it and the clean-install cases re-break. That silent re-break is the exact bug class this task exists to kill (success criterion 3 / Risk 1). Deriving the copy set from the manifest is therefore chosen deliberately over the shorter hard-coded copy; the ~15 lines buy the future-proofing the task is scoped to deliver. A wholesale `cp -rp .claude` is separately rejected (Decision 2) — it drags machine-specific/untracked siblings (`settings.local.json`, skills, hooks) into the fixture.

### Step 2 — Wire into `build_fixture` (after the `git init` line, line 59)
```perl
    system("git", "-C", $tmp, "init", "-q") == 0 or die "git init failed";
    _provision_extra_manifest_paths($tmp);
    return $tmp;
```
(Leave the existing `cp -rp .cwf` and `git -C $tmp init` exactly as-is — Decision 3.)

### Step 3 — Verify (do not change the existing test cases) — treated as a gate, not a formality
- `prove t/cwf-manage-fix-security.t` → all 7 subtests green (TC-1/2/7 now pass; TC-3/4/5/6 must stay green — confirm by running, since provisioning the agents changes *why* those exit-1 cases reach their assertions).
- `prove t/` → full suite green (no regression; `t/cwf-claude-settings-merge.t` has its own `build_fixture` and is untouched).
- `cwf-manage validate` on the real repo → still OK (no production/manifest change).

## Code Changes
### Before (`build_fixture`, lines 57-60)
```perl
    my $rc = system("cp", "-rp", "$REPO_ROOT/.cwf", "$tmp/.cwf");
    die "cp .cwf failed (rc=$rc)" if $rc != 0;
    system("git", "-C", $tmp, "init", "-q") == 0 or die "git init failed";
    return $tmp;
```
### After
```perl
    my $rc = system("cp", "-rp", "$REPO_ROOT/.cwf", "$tmp/.cwf");
    die "cp .cwf failed (rc=$rc)" if $rc != 0;
    system("git", "-C", $tmp, "init", "-q") == 0 or die "git init failed";
    _provision_extra_manifest_paths($tmp);
    return $tmp;
```
(plus the new `_provision_extra_manifest_paths` sub above `build_fixture`.)

## Test Coverage
The existing **TC-1/2/7** are the regression tests for this fix — they go from red to green. No existing test-case logic changes. The testing plan (e) **will add** one **direct** assertion that the fixture contains the manifest's non-`.cwf/` files (the 5 `.claude/agents/*.md`) with perms satisfying their recorded floor — endorsed by plan review as the right pin on the helper, independent of TC-1's broader "validate passes" check, and the honest guard against future manifest drift. **See e-testing-plan.md for the complete test plan.**

## Validation Criteria
- [ ] Helper added before `build_fixture`; single call wired in after `git init`.
- [ ] `prove t/cwf-manage-fix-security.t` fully green (7/7).
- [ ] `prove t/` green (no regression).
- [ ] No hashed file touched; `cwf-manage validate` clean.
- **See e-testing-plan.md for validation criteria and test results.**

## Decomposition Check
One helper + one call site in one test file. Time <0.5d, 1 concern, no risk isolation, not separable. **Verdict**: No decomposition.

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
Implementation plan complete; 4 plan-review subagents run, findings folded in:
- **Improvements** argued for a one-line `cp -rp .claude/agents` over the manifest-walk helper. Kept the helper (success criterion 3 / the task's whole reason for existing) but added an explicit trade-off note rather than leaving the choice implicit.
- **Robustness + Security** both noted the unguarded `$rel` join. Added a fail-closed `die` on `..`/absolute paths (stricter than production by design) and clarified the comment to "integrity-tracked". Robustness's "run, don't assume TC-3/4/5/6 stay green" folded into Step 3 as an explicit gate.
- **Misalignment**: confirmed no existing util reinvented, shell-out idiom is file-local-consistent, and single-callsite helper matches the existing `_`-prefixed fixture-helper pattern. No change.
- Firmed up the direct fixture-provisioning assertion (e-plan) from "may add" to "will add" — endorsed by 3 reviewers as the right drift pin.

## Lessons Learned
The improvements-vs-robustness tension (fewer lines vs future-proof + guarded) resolved cleanly by anchoring on the task's stated success criterion. Full learnings in `j-retrospective.md`.
