# install manifest baselines disagree with subtree - Implementation Plan
**Task**: 167 (bugfix)

## Task Reference
- **Task ID**: internal-167
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/167-install-manifest-baselines-disagree-with-subtree
- **Template Version**: 2.1

## Goal
Execute the design's D1+D2+D3 in a single commit on the bugfix branch, refresh four `script-hashes.json` sha256s in-commit, and demonstrate that the new `t/installmanifest-integrity.t` fails on HEAD (pre-fix) and passes post-fix.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit explains "why"

The test-first variant works here: `t/installmanifest-integrity.t` is genuinely fail-on-HEAD (INV-2 violated by the live `rules-inject` entry with dest under `.cwf/`).

## Design-Plan Refinements (carried forward into implementation)

Surface inconsistencies the d-plan review found in the c-plan; carried forward here as implementation-binding clarifications rather than recycling the design phase.

### Refinement 1 — Verified Assumption 6 tightening
The design said "all four test files preserved unchanged" — true for **fixtures** (each uses synthetic manifests), but TC-RI-1 in `t/cwf-apply-artefacts.t:186-187` asserts the special-case log message format from `_install_file`'s `if ($id eq 'rules-inject')` branch. Removing that branch (D2#3) makes `_install_file` produce the generic `"$id: installed $dest_rel"` format. **TC-RI-1's regex assertion must be updated in the same commit.** Folded into Step 6.

### Refinement 2 — SKILL.md scope expansion (3 edits, not 1)
The design's D2#14 mentioned only line 93. Three line edits are actually needed:
- **Line 93** (bullet list of files): remove the `.cwf/rules-inject.txt` bullet.
- **Line 99** (PreToolUse hook description): currently reads "command … reads the file *written here*". After D1+D2 the file is no longer written by apply-artefacts; it ships via the subtree. Reword to "reads the file shipped in the `.cwf/` subtree" so the maintenance procedure stays accurate.
- **Line 170** (Success Criteria checklist): currently lists `rules-inject` among artefacts applied by `cwf-apply-artefacts --bootstrap-init`. This becomes false post-fix; remove `rules-inject` from the parenthesised enumeration.

Lines 116 (the literal `cat .cwf/rules-inject.txt` hook command) and 102-103 (exit-code handling) stay unchanged — the hook still reads the subtree-shipped file. **SKILL.md is not hash-tracked**, so all three edits land without a hash refresh.

### Refinement 3 — INV-2 widened across artefact kinds
The design framed INV-2 as "no `kind: file` artefact may have `dest` starting with `.cwf/`". The actual bug class — dual-distribution of an artefact whose target lives inside the subtree — is independent of the `kind`. Widen INV-2 to: **for every artefact, if it has a `dest` or `container` field, neither may begin with `.cwf/`**. This catches the architectural rule precisely for all current kinds (`file`, `tree`, `embedded-block`, `line-additive`, `regenerate-symlinks`).

### Refinement 4 — INV-2 needs an empty-array guard
A future commit that empties the `artefacts` array would silently pass INV-2 (loop body never executes). Add `cmp_ok(scalar @{ $manifest->{artefacts} }, '>=', 1, 'manifest has at least one artefact')` as a sanity floor.

### Refinement 5 — `read_file_raw` is not a core Perl symbol
The design's INV-1 sketch used `read_file_raw`. That helper lives in `CWF::ArtefactHelpers` (a `.pm` available only on script lib path) and is not directly importable from a `.t` file via the existing test pattern. Use the existing-test idiom verbatim:
```perl
sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "$path: $!";
    local $/;
    return scalar <$fh>;
}
```
Same idiom appears in `t/cwf-claude-settings-merge.t` and `t/cwf-apply-artefacts.t`.

## Files to Modify

### Functional changes
| # | File | Edit kind |
|---|---|---|
| 1 | `.cwf/install-manifest.json` | Delete `rules-inject` artefact object (no other entry's trailing comma changes — the previous entry `gitignore-entries` keeps its comma; the next entry `cwf-rules-bundle` keeps its leading position) |
| 2 | `.cwf/templates/install/rules-inject.txt` | `git rm` (0-byte placeholder) |
| 3 | `.cwf/scripts/command-helpers/cwf-apply-artefacts` | Remove `@INVENTORY` row; remove dead `_install_file` branch; remove allowlist entry; remove 3 stale doc/comment mentions |
| 4 | `.cwf/scripts/cwf-manage` | Remove `.cwf/rules-inject.txt` from banner comment |
| 5 | `.cwf/lib/CWF/Validate/Security.pm` | Remove `.cwf/rules-inject.txt` from `@ALLOWED_DEST_PREFIXES` |
| 6 | `.claude/skills/cwf-init/SKILL.md` | 3 edits (lines 93, 99, 170 per Refinement 2) |
| 7 | `t/cwf-apply-artefacts.t` | TC-RI-1 regex update (per Refinement 1) |
| 8 | `t/installmanifest-integrity.t` | **NEW** — INV-1 + INV-2 (per Refinements 3-5) |

### Hash-tracking reconciliation
| # | File | Edit kind |
|---|---|---|
| 9 | `.cwf/security/script-hashes.json` | Delete `data."rules-inject-template"` entry; refresh 4 sha256s (files 1, 3, 4, 5 above) |

## Implementation Steps

### Step 1 — Pre-flight

- [ ] Confirm on branch `bugfix/167-…`, clean tree, HEAD at c-phase checkpoint `509d6d3`.
- [ ] Per-file pre-refresh `git log` verification ([[hash-updates]]): for each of the four hashed files about to be edited, confirm the currently-recorded sha256 in `script-hashes.json` matches a SHA visible in that file's git history (no out-of-band tampering).
- [ ] **Validate ordering guard**: do not run `cwf-manage validate` between Step 3 and Step 8 — every intermediate state has mismatched hashes by design. Run it only at Step 9 (after all edits and the hash refresh).
- [ ] **Failure-recovery guard**: if any later step produces unexpected test failures, do not commit. Investigate, document in `f-implementation-exec.md` as a deviation, and resume only after reconciliation.

### Step 2 — Restore working perms on the two executable scripts

Per [[feedback-hashed-script-working-perms]] SCOPE:
- [ ] `chmod 0700 .cwf/scripts/command-helpers/cwf-apply-artefacts .cwf/scripts/cwf-manage`

The other edited files use Edit/Write tool atomic replacement, which handles read-only modes inline — no chmod needed for `.json`, `.pm`, `.md`. `install-manifest.json` and `script-hashes.json` stay at their recorded 0444 mode through the edit (Write replaces atomically).

### Step 3 — Write the regression test (Test first)

- [ ] Create `t/installmanifest-integrity.t`. Header:
  ```perl
  #!/usr/bin/env perl
  use strict;
  use warnings;
  use utf8;
  use FindBin;
  use File::Spec;
  use Test::More;
  use Digest::SHA qw(sha256_hex);
  use JSON::PP;
  ```
  (All core modules per [[feedback-perl-core-only]].)
- [ ] Repo root: `my $REPO = File::Spec->rel2abs("$FindBin::Bin/..");`
- [ ] Inline `slurp_raw` helper per Refinement 5.
- [ ] Load manifest (pin idiom to match `t/cwf-claude-settings-merge.t`):
  ```perl
  my $manifest = decode_json(slurp_raw("$REPO/.cwf/install-manifest.json"));
  ```
- [ ] **Manifest-trust comment** (per security review advisory): inline note that `source` paths are read raw from a hash-tracked manifest, and the test assumes the manifest is integrity-checked separately. Discourages future maintainers from cargo-culting this pattern into untrusted contexts.
- [ ] **Sanity floor** (Refinement 4): `cmp_ok(scalar @{ $manifest->{artefacts} }, '>=', 1, 'manifest has at least one artefact');`
- [ ] **INV-1 (source agreement)**: for each artefact with both `source` and `sha256` defined (covers `kind: file` and `kind: embedded-block` uniformly), assert `sha256_hex(slurp_raw("$REPO/$source"))` equals the recorded `sha256`. For `kind: tree`, iterate `files{*}` similarly: `sha256_hex(slurp_raw("$REPO/$source/$rel"))` equals the recorded per-file SHA. Skip `kind: line-additive` and `kind: regenerate-symlinks` (no source SHA).
- [ ] **INV-2 (anti-recurrence schema rule, Refinement 3)**: for each artefact, if `dest` is defined, assert `$artefact->{dest} !~ m{\A\.cwf/}` (with task-specific failure message naming the id). If `container` is defined, same check. Both apply because different `kind`s use different field names for "where it goes on disk".
- [ ] `done_testing`.
- [ ] **Fail-on-HEAD verification** (must happen here, before any source edit):
  - Run `prove -v t/installmanifest-integrity.t`.
  - Confirm INV-2 fails on the `rules-inject` entry.
  - Capture failure output to `/tmp/-home-matt-repo-coding-with-files-task-167/test-fail-pre-fix.txt` as the reproducer artefact.
  - If the test passes on HEAD, something is wrong — investigate before continuing.

### Step 4 — Apply D1: remove `rules-inject` artefact entry

- [ ] Edit `.cwf/install-manifest.json`: delete the 7-line `rules-inject` object (the `{ … },` block). The previous entry (`gitignore-entries`) keeps its trailing comma. The following entry (`cwf-rules-bundle`) is unchanged. **No other comma adjustments.**
- [ ] **Re-run `prove -v t/installmanifest-integrity.t`**: INV-1 still passes (other artefacts' source SHAs unchanged). INV-2 now passes (no `dest` or `container` under `.cwf/`).

### Step 5 — Apply D2#6: delete the empty template file

- [ ] `sleep 1 && git rm .cwf/templates/install/rules-inject.txt`

### Step 6 — Apply D2 edits to `cwf-apply-artefacts` and TC-RI-1

All Edit-tool operations on `.cwf/scripts/command-helpers/cwf-apply-artefacts`:

- [ ] **D2#2** — remove `@INVENTORY` row (lines 85-86, exact `old_string`):
  ```perl
      { id => 'rules-inject',          strategy => 'replace',
        baseline_source => 'install-manifest' },
  ```
- [ ] **D2#3** — replace dead `_install_file` branch (lines 420-424, exact `old_string`):
  ```perl
      if ($id eq 'rules-inject') {
          log_info(".cwf/rules-inject.txt updated (was $old_sha, now $new_sha)");
      } else {
          log_info("$id: installed $dest_rel");
      }
  ```
  with:
  ```perl
      log_info("$id: installed $dest_rel");
  ```
- [ ] **D2#4** — remove `'.cwf/rules-inject.txt',` line from `@ALLOWED_DEST_PREFIXES` (line 67).
- [ ] **D2#11a** — file-header docblock (line 4): remove `.cwf/rules-inject.txt,` from the comma list.
- [ ] **D2#11b** — usage docstring (line 117): remove `.cwf/rules-inject.txt,` from the comma list.
- [ ] **D2#12** — inline comment (line 207): change `# "CLAUDE.md" / ".gitignore" / ".cwf/rules-inject.txt" are exact, allow them.` to `# "CLAUDE.md" / ".gitignore" are exact, allow them.`

Then on `.cwf/scripts/command-helpers/cwf-apply-artefacts.t` (Refinement 1, folded into D2#3):

- [ ] **TC-RI-1 assertion update** (`t/cwf-apply-artefacts.t:186-187`): change
  ```perl
      like($err, qr{rules-inject\.txt updated \(was , now },
           'audit log line written');
  ```
  to:
  ```perl
      like($err, qr{rules-inject: installed \.cwf/rules-inject\.txt},
           'audit log line written');
  ```
- [ ] **Verify**: `prove -v t/cwf-apply-artefacts.t` — green.

### Step 7 — Apply D2#13: `cwf-manage` banner comment

- [ ] Edit `.cwf/scripts/cwf-manage` lines 491-492 (use the unique two-line `old_string`):
  ```
      # D7/D9: apply non-script artefacts (.cwf-rules/, .gitignore, CLAUDE.md
      # preamble, .cwf/rules-inject.txt, .claude/rules/ symlinks).
  ```
  becomes:
  ```
      # D7/D9: apply non-script artefacts (.cwf-rules/, .gitignore, CLAUDE.md
      # preamble, .claude/rules/ symlinks).
  ```

### Step 8 — Apply remaining edits

- [ ] **D2#5** — `.cwf/lib/CWF/Validate/Security.pm:43`: remove the `'.cwf/rules-inject.txt',` line from `@ALLOWED_DEST_PREFIXES`.
- [ ] **D2#14 (Refinement 2)** — `.claude/skills/cwf-init/SKILL.md`:
  - Line 93: remove the `- `.cwf/rules-inject.txt`` bullet.
  - Line 99: reword the PreToolUse hook description. Replace `reads the file written here.` with `reads the file shipped in the .cwf/ subtree.`
  - Line 170: remove `rules-inject, ` from the Success Criteria parenthesised list.

### Step 9 — Refresh `script-hashes.json` and validate

- [ ] Compute new sha256s of the four edited hash-tracked files:
  ```
  sha256sum .cwf/install-manifest.json \
            .cwf/scripts/command-helpers/cwf-apply-artefacts \
            .cwf/scripts/cwf-manage \
            .cwf/lib/CWF/Validate/Security.pm
  ```
- [ ] Edit `.cwf/security/script-hashes.json`:
  - Delete `data."rules-inject-template"` entry (lines 36-40).
  - Update `data."install-manifest".sha256` to the new value.
  - Update `lib."CWF::Validate::Security".sha256` to the new value.
  - Update `scripts."cwf-apply-artefacts".sha256` to the new value.
  - Update `scripts."cwf-manage".sha256` to the new value.
- [ ] **Validate now** (the guard from Step 1 is lifted): `.cwf/scripts/cwf-manage validate` → expect `[CWF] validate: OK`.

### Step 10 — Final verification

- [ ] `prove -v t/installmanifest-integrity.t` — green (INV-1 + sanity floor + INV-2 all pass).
- [ ] `prove -v t/cwf-apply-artefacts.t t/cwf-manage-update.t t/cwf-manage-update-end-to-end.t t/install-bash-reinstall.t` — green.
- [ ] `prove -r t/` — full sweep green.
- [ ] **No stray rules-inject references in non-test code**:
  ```
  git grep -nE 'rules-inject' -- ':!t/' ':!implementation-guide/' \
                                    ':!CHANGELOG.md' ':!BACKLOG.md'
  ```
  Expected matches after the fix: only the legitimate references in SKILL.md line 116 (hook command), the file `.cwf/rules-inject.txt` itself, and possibly Task 99/158 retrospectives (historical). Any other live mention indicates a missed cleanup site.

### Step 11 — Hand off to f-implementation-exec

The above 10 steps are the execution checklist for `/cwf-implementation-exec`. That phase performs the edits and the checkpoint commit; no commit happens during d-implementation-plan.

## Reproducer Scope Decision

The end-to-end reproducer (simulate v1.1.155 → post-fix update non-interactively, assert `.cwf/rules-inject.txt` survives populated) is **hard-deferred to `e-testing-plan.md`** as a documented TC. Reason: the helper has its own dedicated test files (`t/install-bash-reinstall.t`, `t/cwf-manage-update-end-to-end.t`) where this fits naturally; running it ad-hoc in f-exec adds throwaway-repo plumbing for one assertion. The e-plan decides whether to extend an existing TC or add a new one.

## Code Changes

### Before (`install-manifest.json:15-21`)
```json
    {
      "id": "rules-inject",
      "kind": "file",
      "source": ".cwf/templates/install/rules-inject.txt",
      "dest": ".cwf/rules-inject.txt",
      "sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    },
```

### After
(entry removed in full; surrounding commas unchanged)

### Before (`cwf-apply-artefacts:420-424`)
```perl
    if ($id eq 'rules-inject') {
        log_info(".cwf/rules-inject.txt updated (was $old_sha, now $new_sha)");
    } else {
        log_info("$id: installed $dest_rel");
    }
```

### After
```perl
    log_info("$id: installed $dest_rel");
```

### Before (`t/cwf-apply-artefacts.t:186-187`)
```perl
    like($err, qr{rules-inject\.txt updated \(was , now },
         'audit log line written');
```

### After
```perl
    like($err, qr{rules-inject: installed \.cwf/rules-inject\.txt},
         'audit log line written');
```

## Test Coverage
**See e-testing-plan.md for complete test plan** — binding §Validation bullets to concrete subtests, including the end-to-end reproducer.

This implementation plan introduces:
- **New**: `t/installmanifest-integrity.t` — sanity floor + INV-1 (existence + SHA match for `source`/`files`/`embedded-block` artefacts) + INV-2 (no artefact `dest` or `container` under `.cwf/`).
- **Updated**: `t/cwf-apply-artefacts.t` TC-RI-1 — assertion regex tracks generic log format.

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

Implementation-plan-internal checks (must pass before invoking `/cwf-testing-plan`):
- [ ] All 10 implementation steps executed in order, no out-of-order validate runs.
- [ ] `cwf-manage validate` clean after Step 9.
- [ ] `prove -r t/` green after Step 9.
- [ ] The 4 hash refreshes in Step 9 are byte-for-byte the sha256s of the post-edit files (cross-verified by re-running `sha256sum`).
- [ ] No stray `rules-inject` references in non-test code (Step 10 grep).

## Scope Completion
All design D1+D2+D3 items (14 cleanup sites + 1 new test + 1 test assertion update + 4 hash refreshes + 1 entry delete) are in scope. The BACKLOG follow-up (`reclassify rules-inject as consumer-owned`) remains separate.

## Hash-Tracked File Disclosure ([[hash-updates]])
Edited in this task; sha256 in `.cwf/security/script-hashes.json` refreshed in same commit:
1. `.cwf/install-manifest.json` (`data."install-manifest"`)
2. `.cwf/scripts/command-helpers/cwf-apply-artefacts` (`scripts."cwf-apply-artefacts"`)
3. `.cwf/scripts/cwf-manage` (`scripts."cwf-manage"`)
4. `.cwf/lib/CWF/Validate/Security.pm` (`lib."CWF::Validate::Security"`)

Additionally:
- `.cwf/templates/install/rules-inject.txt` **deleted**; `data."rules-inject-template"` entry **removed** from `script-hashes.json` in the same commit.
- `.cwf/security/script-hashes.json` is itself the source of truth; self-edits land here.

## Decomposition Check
- [x] **Time**: <0.5 day → no.
- [x] **People**: solo → no.
- [x] **Complexity**: 10 sequential mechanical steps, one commit → no.
- [x] **Risk**: single revert recovers → no.
- [x] **Independence**: edits must land together per D5 → no.

**Verdict**: 0/5. No subtasks.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 167
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
