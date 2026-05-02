# Drop perl -I prefix from script invocations - Implementation Plan
**Task**: 121 (chore)

## Task Reference
- **Task ID**: internal-121
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/121-drop-perl-i-prefix-from-script-invocations
- **Template Version**: 2.1

## Goal
Switch every active `perl -I.cwf/lib <script>` invocation to idiomatic Unix shebang invocation. The single bootstrap exception — `/cwf-init` step 1a, where `.cwf/scripts/cwf-manage` may have been copied without exec bits — uses `chmod u+x` then direct invocation, not `perl -I`.

## Workflow
Patterns first → minimal edits → verify with grep + validate + prove → commit explains "why"

## Files to Modify

### Primary Changes (4 files, all active sites)

| File | Line(s) | Change |
|------|---------|--------|
| `.claude/skills/cwf-init/SKILL.md` | 32–36 | Replace prose + code fence: bootstrap via `chmod u+x` then direct exec; explanatory paragraph notes `.cwf/` may have been copied without exec bits, so chmod is required to start the bootstrap (after which `cwf-manage fix-security` repairs every other file's perms per `script-hashes.json`). |
| `.claude/skills/cwf-security-check/SKILL.md` | 28–30 | Replace `perl -I.cwf/lib .cwf/scripts/cwf-manage validate` with `.cwf/scripts/cwf-manage validate`. |
| `INSTALL.md` | 281–282 | **Remove both lines** (the `# Check Perl modules load` comment and the `perl -I -MCWF::Common -e ...` line). The `.cwf/scripts/command-helpers/context-manager location` invocation immediately above it already exercises `CWF::Common` loading via `FindBin` (verified at `context-manager.d/location:5-6`), making this line redundant. |
| `t/cwf-manage-fix-security.t` | 36–57 | Replace the `perl -I.cwf/lib …` invocations in `run_fix_security`/`run_validate` with direct `.cwf/scripts/cwf-manage <subcmd>` calls; add an idempotent `_ensure_cwf_manage_executable($tmp)` helper that chmods the entry-point to `0500` when user-x is missing (mirroring `/cwf-init` step 1a). The helper is called from `run_fix_security` and `run_validate` before exec. Comment block at lines 40–42 updated to explain the new bootstrap-via-chmod approach. |

### Files explicitly NOT modified
- `.cwf/scripts/cwf-manage` and any other tracked Perl files — no library or code logic changes; this is pure invocation cleanup.
- `.cwf/security/script-hashes.json` — none of the touched files are hash-tracked. Confirmed: manifest covers `.cwf/lib/**` and `.cwf/scripts/**` only (37 entries).
- `implementation-guide/**`, `CHANGELOG.md`, `BACKLOG.md` — historical records.

## Implementation Steps

### Step 1: Confirm baseline
- [ ] Record `prove t/` baseline (expect 253 pass).
- [ ] Run `.cwf/scripts/cwf-manage validate` → expect `[CWF] validate: OK`.
- [ ] Re-run inventory grep — expect exactly 4 active hits (cwf-init, cwf-security-check, INSTALL.md, t/cwf-manage-fix-security.t × 2 lines).

### Step 2: Update `.claude/skills/cwf-security-check/SKILL.md`
- [ ] Edit line 29: `perl -I.cwf/lib .cwf/scripts/cwf-manage validate` → `.cwf/scripts/cwf-manage validate`.
- [ ] No other change to the skill.

### Step 3: Update `INSTALL.md`
- [ ] Delete lines 281–282 (the comment `# Check Perl modules load` and the `perl -I -MCWF::Common -e ...` line). The blank-separated bash blocks above and below remain.
- [ ] Update line 285: `All four commands should succeed without errors.` → `All three commands should succeed without errors.` (the four "Check ..." groups become three after removing the Perl-modules-load group).

### Step 4: Update `.claude/skills/cwf-init/SKILL.md`
Replace lines 32–36 with:

```markdown
Run, using the Bash tool. The first block reads `cwf-manage`'s recorded permissions from `.cwf/security/script-hashes.json` (the source of truth — no magic numbers) and chmods the entry-point to that exact value, in case `.cwf/` was copied without preserving modes (e.g. `cp` without `-p`). The second command then runs `cwf-manage fix-security`, which reads the same JSON to repair every other tracked file's permissions:

​```bash
PERMS=$(perl -MJSON::PP -e '
    open my $f, "<", ".cwf/security/script-hashes.json" or die "cannot read script-hashes.json: $!";
    local $/;
    my $j = JSON::PP::decode_json(<$f>);
    close $f;
    print $j->{scripts}{"cwf-manage"}{permissions} or die "no permissions recorded for cwf-manage";
')
chmod "$PERMS" .cwf/scripts/cwf-manage
.cwf/scripts/cwf-manage fix-security
​```
```

- [ ] Step 1a's exit-code branching (lines 38–39) stays unchanged: exit 0 → continue, non-zero → relay + abort.

**Rationale for the inline `perl -MJSON::PP -e`**: this is a one-shot JSON parse, not an `-I.cwf/lib <script>` substitute. JSON::PP is a Perl 5.14+ core module (no extra dep). The alternative — hardcoding `chmod 0700 .cwf/scripts/cwf-manage` or using symbolic `chmod u+x` — would either reintroduce a magic number (drifts if recorded perms change) or only set the minimum-exec bits (leaves cwf-manage with permissions that satisfy the validator's bitwise minimum but don't match recorded values exactly).

### Step 5: Update `t/cwf-manage-fix-security.t`

#### 5a. Add JSON-driven helpers (no magic numbers)
- [ ] Add `use Fcntl qw(:mode);` and `use JSON::PP qw(decode_json);` near the existing `use` block at the top of the file.
- [ ] Add the `_read_recorded_perms` helper that reads the JSON and returns the recorded permission for a given entry as an octal integer:
  ```perl
  # Reads the recorded `permissions` value for an entry from script-hashes.json
  # and returns it as an octal integer (e.g. "0700" → 0700). Source of truth
  # for every chmod and assertion in this test — no magic numbers.
  sub _read_recorded_perms {
      my ($tmp, $entry_name) = @_;
      my $hashes = "$tmp/.cwf/security/script-hashes.json";
      open my $fh, '<', $hashes or die "$hashes: $!";
      local $/;
      my $json = decode_json(<$fh>);
      close $fh;
      my $perms = $json->{scripts}{$entry_name}{permissions}
          or die "no permissions recorded for $entry_name";
      return oct($perms);
  }
  ```
- [ ] Add the `_ensure_cwf_manage_executable` helper, which mirrors `/cwf-init` step 1a's bootstrap. Idempotent — skips if user-x is already set:
  ```perl
  # Bootstrap: ensure cwf-manage is executable before we exec it directly.
  # Mirrors /cwf-init step 1a — chmod to recorded perms (read from JSON, no
  # magic numbers). Idempotent; skips when user-x is already set.
  sub _ensure_cwf_manage_executable {
      my ($tmp) = @_;
      my $cwf_manage = "$tmp/.cwf/scripts/cwf-manage";
      my $current = (stat($cwf_manage))[2] & 07777;
      return if $current & S_IXUSR;
      chmod _read_recorded_perms($tmp, 'cwf-manage'), $cwf_manage
          or die "chmod $cwf_manage: $!";
  }
  ```

#### 5b. Replace invocation scaffolding
- [ ] Replace `run_fix_security`'s body (lines 36–47):
  ```perl
  sub run_fix_security {
      my ($tmp) = @_;
      _ensure_cwf_manage_executable($tmp);
      my $cwd = getcwd();
      chdir $tmp or die "chdir $tmp: $!";
      my $output = `.cwf/scripts/cwf-manage fix-security 2>&1`;
      my $rc = $? >> 8;
      chdir $cwd or die "chdir back: $!";
      return ($rc, $output);
  }
  ```
- [ ] Replace `run_validate` similarly (lines 49–57): direct `.cwf/scripts/cwf-manage validate` invocation, with the same `_ensure_cwf_manage_executable` call.

#### 5c. Update assertions to derive expected perms from JSON
- [ ] **TC-2 (line 117)**: replace literal `0700`:
  ```perl
  is(file_perms($cwf_manage), _read_recorded_perms($tmp, 'cwf-manage'),
     "cwf-manage perms restored to recorded value (not blanket 0755)");
  ```

#### 5d. Redirect TC-4/TC-5 chmod targets away from `cwf-manage`
With the bootstrap helper now setting `cwf-manage`'s perms to recorded **before** fix-security runs, any test that originally chmod-stripped `cwf-manage` would no longer exercise fix-security's chmod path on it (the helper would already have set it correctly). Redirect those tests to a non-bootstrap script so fix-security still has chmod work to do:

- [ ] **TC-4 (lines 142–157)**: change `$other` from `cwf-manage` to `command-helpers/cwf-version-tag`:
  ```perl
  my $other = "$tmp/.cwf/scripts/command-helpers/cwf-version-tag";
  chmod 0644, $other;
  ```
  Update the assertion to derive expected perms from JSON:
  ```perl
  is(file_perms($other), _read_recorded_perms($tmp, 'cwf-version-tag'),
     'other file repaired (best-effort fix despite unfixable peer)');
  ```

- [ ] **TC-5 (lines 162–177)**: change `$fileA` from `cwf-manage` to `command-helpers/cwf-version-tag`. Update the regex `qr{cwf-manage}` to `qr{cwf-version-tag}` and the assertion:
  ```perl
  my $fileA = "$tmp/.cwf/scripts/command-helpers/cwf-version-tag";
  chmod 0644, $fileA;
  ...
  like($out, qr{cwf-version-tag}, 'output mentions repaired A');
  ...
  is(file_perms($fileA), _read_recorded_perms($tmp, 'cwf-version-tag'), 'fixable A repaired');
  ```

The `chmod 0644` literal in `strip_perms_recursive` and the TC-4/5 setup remains as-is — it represents an *intentionally stripped* state (no exec, no group/other bits), not a recorded value. It's a fixture-mutation constant, not a magic number that's drifted from the JSON source of truth.

### Step 6: Verify
- [ ] `grep -rn "perl -I.cwf/lib" .claude/ INSTALL.md README.md CLAUDE.md docs/ .cwf/docs/ .cwf/templates/ .cwf/scripts/ .cwf/lib/ t/` → expect **zero hits**.
- [ ] `.cwf/scripts/cwf-manage validate` → `[CWF] validate: OK`.
- [ ] `prove t/cwf-manage-fix-security.t` → all 7 subtests pass.
- [ ] `prove t/` → 253 passes (no regressions).

### Step 7: Documentation
- [ ] Update `f-implementation-exec.md` with diff snippets per file, grep before/after, validate output, prove summary.

## Reused Patterns
- `FindBin` + `use lib "$FindBin::Bin/../lib"` in `cwf-manage` (line 25–26) and `context-manager.d/location` (line 4–5) — the reason `perl -I.cwf/lib` is redundant for direct invocation.
- The `chmod u+x` bootstrap mirrors a pattern broadly familiar from any Unix install script.

## Test Coverage
**See e-testing-plan.md.** No new tests; existing 7-case `cwf-manage-fix-security.t` continues to cover the algorithm — its scaffolding (`run_fix_security`/`run_validate` + new helper) is updated to use direct invocation, but every TC's assertions remain the same.

## Validation Criteria
**See e-testing-plan.md and Step 6 above.** Two gates:
1. Grep returns zero `perl -I.cwf/lib` hits in active code.
2. Full `prove t/` passes (no semantic regression in tests).

## Scope Completion
All four success criteria from `a-task-plan.md` must be met before marking Finished. No deferrals planned.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 121
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
