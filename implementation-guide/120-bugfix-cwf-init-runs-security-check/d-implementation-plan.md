# cwf-init runs security check - Implementation Plan
**Task**: 120 (bugfix)

## Task Reference
- **Task ID**: internal-120
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/120-cwf-init-runs-security-check
- **Template Version**: 2.1

## Goal
Execute the design from `c-design-plan.md`: add a deterministic `cwf-manage fix-security` subcommand that repairs fixable permission violations (sha256 matches) and refuses to act on unfixable ones (missing/tampered); refresh the `cwf-manage` hash; insert SKILL step `1a` that calls the subcommand and aborts init on non-zero exit.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary Changes
- `.cwf/scripts/cwf-manage` — add `cmd_fix_security` subroutine, register `'fix-security'` in the dispatch table (`%dispatch` at line 458), add help-text line in `cmd_help` (around line 430). Approx. 50 new lines.
- `.claude/skills/cwf-init/SKILL.md` — insert new section `### 1a. Verify and Repair CWF Install` between current section 1 (line 25-26) and section 2 (line 28). Add one new line to the Success Criteria checklist.

### Supporting Changes
- `.cwf/security/script-hashes.json` — refresh `cwf-manage`'s `sha256` after the script change (path and `permissions` fields unchanged).
- `t/cwf-manage-fix-security.t` (**new**) — unit/integration test for the subcommand. Exercises every algorithm branch from Design Decision 2's table.

### Out of scope (deliberate)
- `--dry-run` flag on the new subcommand — useful but bugfix scope says minimum-viable
- Auto-running `fix-security` from `cwf-manage update` — `update` already does its own chmod (`cwf-manage:350`); reconciling the two is a separate cleanup
- INSTALL.md changes — `chmod u+rx` instructions remain valid for the install path
- Existing tasks/branches with unusual perms — fix-security only operates on files listed in `script-hashes.json`

## Implementation Steps

### Step 1: Setup and pattern review
- [ ] Re-read `cwf-manage` dispatch (`.cwf/scripts/cwf-manage:454-475`) and `cmd_validate` (line 391) for sub-style and exit conventions
- [ ] Re-read `CWF::Validate::Security::validate` (`.cwf/lib/CWF/Validate/Security.pm`) — fix-security parses the same `script-hashes.json` directly to derive its repairs (no shared module needed; the two should agree by construction since they read identical data)
- [ ] Re-read `t/template-copier-slug-validation.t` for the established `prove`/Test::More test layout and `tempdir(CLEANUP => 1)` fixture pattern
- [ ] Confirm `cwf-manage` is in `script-hashes.json` (already verified during planning; entry will need refreshing in Step 4)
- [ ] Record the baseline `prove t/` pass count before any changes

### Step 2: Write the regression test first (TDD)
- [ ] Create `t/cwf-manage-fix-security.t`
- [ ] Test setup pattern: `system("cp -r .cwf $tmp/.cwf")` from the repo root, then mutate the fixture per test case before invoking `perl -I$tmp/.cwf/lib $tmp/.cwf/scripts/cwf-manage fix-security` (cwd = `$tmp`). Captures stdout, stderr, and exit code.
- [ ] Test cases (one per row of Design Decision 2's classification table):
  - **TC-test-1 (clean install — no-op)**: Fixture pristine. Run fix-security. Assert exit 0, no `chmod` lines in stdout (or "repaired 0 file(s)"), validate passes.
  - **TC-test-2 (perms stripped, sha intact — repair)**: `chmod 0644` on every `.cwf/scripts/` file. Pre-check: validate fails with `permissions` violations. Run fix-security. Assert exit 0, stdout names each repaired file with its target perms, post-call validate passes (perms restored to recorded values).
  - **TC-test-3 (sha mismatch — refuse, no chmod)**: Append a byte to `.cwf/scripts/cwf-manage`, then `chmod 0644` it. Run fix-security. Assert exit 1, stdout/stderr mentions `sha256` and the tampered path, output contains the recovery hint substring `git pull` *and* `cwf-manage update`, the file's perms remain `0644` after the call (no chmod attempted), and the file content is still tampered (no content changes).
  - **TC-test-4 (missing file — refuse)**: Delete `.cwf/scripts/command-helpers/context-manager`. Strip perms on a different file (e.g. `cwf-manage` to `0644`) to confirm best-effort fix. Run fix-security. Assert exit 1, output mentions `existence` and the missing path, output contains recovery hint substrings `git pull` and `cwf-manage update`, the *other* file *is* repaired (best-effort), exit is still 1 because of the missing entry.
  - **TC-test-5 (mixed — repair fixable, refuse unfixable)**: Strip perms on file A and tamper file B. Run fix-security. Assert exit 1, output shows A repaired and B flagged unfixable with recovery hint, A's perms now correct, B's perms unchanged.
  - **TC-test-6 (unparseable hashes file — exit 1 immediately)**: Overwrite `script-hashes.json` with `not-json`. Run fix-security. Assert exit 1, stderr names the hashes file and the parse error, output contains recovery hint substrings `git pull` and `cwf-manage update`, no chmods applied.
  - **TC-test-7 (idempotency)**: Run TC-test-2's setup → fix-security → fix-security a second time. Assert second call is a no-op (exit 0, no repair lines).
- [ ] Run the test — must fail initially (subcommand doesn't exist; will report "Unknown command: fix-security")

### Step 3: Implement `cmd_fix_security` in `cwf-manage`
- [ ] Open `.cwf/scripts/cwf-manage`
- [ ] Add a new sub `cmd_fix_security($git_root)` near `cmd_validate` (after the existing `cmd_validate` block ending around line 410). Algorithm:
  1. Resolve `$hashes_path = "$git_root/.cwf/security/script-hashes.json"`. If missing or unparseable, print `[CWF] ERROR: ...` to stderr and `exit 1`.
  2. Walk every entry the same way `Validate::Security::validate` does (re-use `_looks_like_file_map` semantics — either copy the small helper or read it from the validator module; the simpler choice is to inline the section/entry walk here, since it's about 15 lines).
  3. For each entry: stat the file. If missing, push to `@unfixable` with reason `existence`. Else compute sha256 (re-use `Digest::SHA::sha256_hex` with `<:raw`, identical to the validator). If sha mismatches, push to `@unfixable` with reason `sha256`. Else if `permissions` is recorded and `(actual & expected) != expected`, `chmod oct($expected), $file or push @unfixable` and append to `@repaired`.
  4. Print one line per `@repaired` entry: `[CWF] fix-security: chmod $perms $relpath`.
  5. After the loop, run the existing `cmd_validate($git_root)` semantics — actually, simpler: call `CWF::Validate::Security::validate($git_root)` directly and inspect for any remaining violations. If empty and `@unfixable` is empty, print summary `[CWF] fix-security: repaired N file(s); validate: OK` and `return`.
  6. Otherwise print, for each unfixable entry: a header `[CWF] fix-security: UNFIXABLE — $relpath`, then `field`, `actual`, `expected` lines (mirror the validator's format), then a **Recovery:** line keyed by `field`:
     - `sha256` → `Recovery: file content has drifted from the recorded hash. Restore from upstream: 'git pull' (in a CWF source checkout) or 'cwf-manage update' (in an installed project).`
     - `existence` → `Recovery: tracked file is missing. Restore from upstream: 'git pull' (CWF source) or 'cwf-manage update' (installed project).`
     - `file` / `json` (the hashes file itself) → `Recovery: 'script-hashes.json' is missing or unparseable. Restore from upstream: 'git pull' or 'cwf-manage update'.`
     After printing all unfixable entries, `exit 1`. (The bare `validate` subcommand's developer-oriented "update the hash" message stays intact in `Validate::Security`.)
- [ ] Register dispatch in `%dispatch` (line 458): `'fix-security' => sub { cmd_fix_security($git_root) },`
- [ ] Add help text line to `cmd_help` after the `validate` line (around line 430):
  ```
    fix-security     Repair fixable integrity violations (perms when sha256 matches);
                     exit non-zero on tampering or missing files
  ```

### Step 4: Refresh the script hash
- [ ] Compute new sha256:
  ```bash
  sha256sum .cwf/scripts/cwf-manage | awk '{print $1}'
  ```
- [ ] Edit `.cwf/security/script-hashes.json`: replace the old hex string in the `cwf-manage` entry with the new one. Path and `permissions` fields stay the same.
- [ ] Run `.cwf/scripts/cwf-manage validate` — must report `OK`. (Bootstrap: at this point `cwf-manage` is updated *and* its hash entry matches.)

### Step 5: Edit the SKILL.md
- [ ] Open `.claude/skills/cwf-init/SKILL.md`
- [ ] Insert immediately after line 27 (the `- implementation-guide/ at git root` bullet) and before line 28 (`### 2. Generate Project Configuration`). New section content:
  - Heading: `### 1a. Verify and Repair CWF Install`
  - Intro paragraph: "CWF helper scripts may be missing execute permissions if `.cwf/` was copied via a method that does not preserve modes (e.g. `cp` without `-p`, an extracted archive, or a non-`install.bash` workflow). This step deterministically repairs fixable permission deltas (where the file's sha256 still matches what `script-hashes.json` records) and refuses to proceed if any file is missing or tampered."
  - Followed by: "Run, using the Bash tool:" then a bash fence containing one command:
    - `perl -I.cwf/lib .cwf/scripts/cwf-manage fix-security`
  - Followed by:
    - "If exit code is 0, continue to step 2."
    - "If exit code is non-zero, **abort `/cwf-init`**: relay the subcommand's stdout/stderr to the user verbatim, then append a single line: `[CWF] /cwf-init aborted: run \`cwf-manage update\` or reinstall, then re-run /cwf-init.` Do not proceed to step 2."
- [ ] Add to the Success Criteria checklist (insert after `- [ ] Directory structure created`): `- [ ] Install integrity verified via \`cwf-manage fix-security\` (exit 0)`

### Step 6: Run tests + global validation
- [ ] `prove t/cwf-manage-fix-security.t` — all TC-test-* pass
- [ ] `prove t/` — no new failures vs the baseline recorded in Step 1
- [ ] `.cwf/scripts/cwf-manage validate` — `OK`
- [ ] `.cwf/scripts/cwf-manage fix-security` — `OK` on the development repo (no-op, since perms here are correct)

### Step 7: Manual smoke verification (deferred to g-testing-exec)
End-to-end SKILL exec is LLM-driven. g-testing-exec will:
- Strip perms in a scratch checkout (`find .cwf/scripts -type f -exec chmod 0644 {} \;`), run `/cwf-init`, confirm step `1a` invokes fix-security, perms restored, init proceeds
- Tamper a script in the scratch checkout, run `/cwf-init`, confirm abort with relayed output and no further state mutation

## Code Changes (excerpts)

### Before (`cwf-manage` line 425-431, 458-465)
```perl
Commands:
  status           Show installed CWF version, method, and source
  list-releases [--all]    List available tagged releases from the CWF remote
  update [ref]     Update to a specific ref (default: latest tag)
  rollback <ref>   Revert to a previous version
  validate         Validate config and workflow files; exit non-zero on violations
  help             Show this help message
...
my %dispatch = (
    'status'        => sub { cmd_status($git_root) },
    'list-releases' => sub { my $all = grep { $_ eq '--all' } @ARGV; cmd_list_releases($git_root, $all) },
    'update'        => sub { cmd_update($git_root, shift @ARGV) },
    'rollback'      => sub { cmd_rollback($git_root, shift @ARGV) },
    'validate'      => sub { cmd_validate($git_root) },
    'help'          => sub { cmd_help() },
);
```

### After (illustrative — final wording in implementation)
```perl
Commands:
  status           Show installed CWF version, method, and source
  list-releases [--all]    List available tagged releases from the CWF remote
  update [ref]     Update to a specific ref (default: latest tag)
  rollback <ref>   Revert to a previous version
  validate         Validate config and workflow files; exit non-zero on violations
  fix-security     Repair fixable integrity violations (perms when sha256 matches);
                   exit non-zero on tampering or missing files
  help             Show this help message
...
my %dispatch = (
    'status'        => sub { cmd_status($git_root) },
    'list-releases' => sub { my $all = grep { $_ eq '--all' } @ARGV; cmd_list_releases($git_root, $all) },
    'update'        => sub { cmd_update($git_root, shift @ARGV) },
    'rollback'      => sub { cmd_rollback($git_root, shift @ARGV) },
    'validate'      => sub { cmd_validate($git_root) },
    'fix-security'  => sub { cmd_fix_security($git_root) },
    'help'          => sub { cmd_help() },
);
```

## Test Coverage
**See e-testing-plan.md for the full test plan.** Implementation-side: `t/cwf-manage-fix-security.t` covers TC-test-1 through TC-test-7. The e-testing-plan adds the manual SKILL-level smoke (TC-4/5/6 there) and the `/cwf-init` regression around step ordering.

## Validation Criteria
- All TC-test-* pass under `prove t/cwf-manage-fix-security.t`
- `prove t/` shows no new failures vs baseline
- `cwf-manage validate` returns `OK` after the hash refresh
- `cwf-manage fix-security` is a no-op on the development repo (exit 0, no chmods)
- New SKILL step `1a` invokes `cwf-manage fix-security` and abort-relays on non-zero exit
- Help text lists `fix-security` between `validate` and `help`

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferred items must be approved by the user, documented in Actual Results, and tracked as a follow-up BACKLOG item.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 120
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
