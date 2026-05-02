# cwf-init runs security check - Design
**Task**: 120 (bugfix)

## Task Reference
- **Task ID**: internal-120
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/120-cwf-init-runs-security-check
- **Template Version**: 2.1

## Goal
Make `/cwf-init` self-healing for the most common install footgun — missing execute bits on `.cwf/scripts/` after a non-`install.bash` copy — and surface remaining integrity issues (missing files, hash mismatches) loudly before the init commit. Do this *deterministically* via a new `cwf-manage fix-security` subcommand rather than LLM-orchestrated shell.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### Decision 1: Add a deterministic `cwf-manage fix-security` subcommand
- **Rationale**: `script-hashes.json` already records, per file, the expected `permissions` and `sha256`. The validator already detects every kind of violation. The repair is mechanically derivable: if a file's content matches its expected sha256, then a permissions delta can be safely fixed by `chmod $expected_perms $file` — no judgement required. Lifting this into a subcommand keeps the algorithm inside Perl (testable, version-controlled, hash-tracked) and removes the LLM from the integrity loop.
- **Alternative rejected**: a blanket `chmod 0755` orchestrated from the SKILL. That works but (a) requires the LLM to issue and interpret shell commands correctly every time, (b) overshoots the recorded minimum (sets g+rx, o+rx on files recorded as `0500`/`0700`), and (c) papers over partial information by chmod-ing files we don't actually know are intact.
- **Trade-off**: Slightly larger diff (~50 lines of Perl in `cwf-manage` + one new dispatch entry + a hash refresh) vs. the rejected alternative's ~10-line SKILL.md edit. The deterministic version is auditable and self-tested, which is worth the extra surface for a security-adjacent operation.

### Decision 2: Algorithm — fix viable, refuse unviable, never paper over tampering
For each entry in `.cwf/security/script-hashes.json`:

| File state                                     | Action                                          |
|-----------------------------------------------|-------------------------------------------------|
| Missing                                       | Collect as unfixable; do nothing                |
| Present, sha256 matches, perms OK             | No-op                                           |
| Present, sha256 matches, perms < expected     | `chmod $expected_perms $file`; log the fix     |
| Present, sha256 mismatch                      | Collect as unfixable; do nothing (no chmod)    |
| Hashes file missing or unparseable            | Exit 1 immediately; cannot proceed              |

After the per-file pass, re-run `cwf-manage validate`:
- Validate exit 0 → fix-security exit 0
- Validate exit 1 → fix-security exit 1 (the unfixable issues remain visible)

- **Why not chmod a file with sha mismatch**: a content mismatch is a tamper signal; "fixing" perms on a file we can't verify content-wise would mask the tamper.
- **Why best-effort fix even when there are unfixable entries**: a partially-corrupted install should still get the fixable parts repaired, with the unfixable ones surfaced loud and clear. Failing fast at the first unfixable would obscure the full picture.

### Decision 3: Use the validator's recorded `permissions` value as the chmod target — exact, not minimum
- **Approach**: For a given entry, `chmod oct($entry->{permissions}), $file` (e.g. `chmod 0500` for entries recorded as `"0500"`). This sets the exact recorded perms, satisfying the validator's `(actual & expected) == expected` minimum check tightly.
- **Rationale**: The validator records the *intended* perms (which `cwf-manage update` sets via blanket `chmod 0755`, but other future installers might respect). Using the exact recorded value means fix-security and the install path converge on the same end state, with no surprise bits set.
- **Note**: This means fix-security may produce a stricter end state than the current `cwf-manage update` blanket `chmod 0755`. That's fine — both pass validate; the recorded perms are the source of truth.

### Decision 4: `/cwf-init` step `1a` becomes a single subcommand call
- **SKILL step 1a content**: one Bash invocation —
  ```
  perl -I.cwf/lib .cwf/scripts/cwf-manage fix-security
  ```
- Exit 0 → continue with init.
- Exit 1 → abort init, relay the subcommand's stdout/stderr verbatim, append the line `[CWF] /cwf-init aborted: run \`cwf-manage update\` or reinstall, then re-run /cwf-init.`
- **Rationale**: All algorithmic logic lives in Perl; the SKILL is reduced to call-and-check, which is the right division of responsibility.

### Decision 5: Placement — new step `1a`, after directory setup, before any further state mutation
- Insert between existing step 1 (Create Directory Structure) and step 2 (Generate Project Configuration). Sub-numbering matches the existing `6/6b/6c` convention. Aborting before step 2 means CLAUDE.md, `.claude/settings.json`, and the init commit are not touched on a corrupt install.

### Decision 6: Output format
- On success: a single summary line, e.g. `[CWF] fix-security: repaired 3 file(s); validate: OK` (or `repaired 0 file(s)` if no-op).
- On failure: list each fix applied (if any), then a per-unfixable-entry block with `field`, `actual`, `expected`, and a **recovery hint** tailored to the field type, then exit 1. Hints:
  - `sha256` — `Recovery: file content has drifted from the recorded hash. Restore the file from upstream: \`git pull\` (in a CWF source checkout) or \`cwf-manage update\` (in an installed project).`
  - `existence` — `Recovery: tracked file is missing. Restore from upstream: \`git pull\` (CWF source) or \`cwf-manage update\` (installed project).`
  - `file` / `json` (hashes file itself broken) — `Recovery: \`script-hashes.json\` is missing or unparseable. Restore from upstream: \`git pull\` or \`cwf-manage update\`.`
  - The bare `validate` subcommand keeps its existing developer-oriented `fix` string ("update the hash in $HASHES_FILE with: sha256sum $file") because in the dev workflow an intentional script change *should* be followed by a hash refresh. fix-security is the user-facing surface and gets the user-facing hint.
- **Why both `git pull` and `cwf-manage update`**: CWF is dogfooded — the source repo is where dev happens (so `git pull` is right) and installed projects use `cwf-manage update`. Listing both lets the same hint serve both audiences without fix-security needing to detect which environment it's running in.

## System Design

### Component Overview
- **`cwf-manage` (modified)** — gains a `fix-security` subcommand; help text and dispatch updated. Approx. 50 lines of new Perl, factored into a single sub.
- **`CWF::Validate::Security` (unchanged)** — still the source of truth for what counts as a violation. fix-security parses `script-hashes.json` directly (same data) so the two never disagree.
- **`/cwf-init` SKILL.md (modified)** — gains a new step `1a` that invokes the subcommand and branches on exit code.
- **`.cwf/security/script-hashes.json` (refreshed)** — `cwf-manage`'s hash entry updated after the script change.

### Data Flow
1. User runs `/cwf-init`.
2. SKILL step 1 creates `implementation-guide/`.
3. SKILL step 1a runs `perl -I.cwf/lib .cwf/scripts/cwf-manage fix-security`:
   - Subcommand reads `script-hashes.json`, classifies each entry, applies safe chmods, re-runs validate, exits 0 or 1.
4. If exit 0, init proceeds through steps 2–8; if exit 1, init aborts with relayed output.

### Affected Files
- `.cwf/scripts/cwf-manage` — new subroutine `cmd_fix_security`, new dispatch entry `'fix-security'`, help-text addition
- `.cwf/security/script-hashes.json` — refresh `cwf-manage` entry's sha256
- `.claude/skills/cwf-init/SKILL.md` — new step `1a` and matching success-criterion line
- `t/cwf-manage-fix-security.t` — new test file exercising the subcommand directly

## Interface Design

### New subcommand
```
cwf-manage fix-security
```
- No arguments. No flags initially (a `--dry-run` could be added later but is out of scope here — bugfix discipline).
- Stdout: progress lines for each repair applied, plus the final validate output / summary.
- Stderr: error messages for unparseable hashes file, etc.
- Exit codes: 0 on success (validate passes after repair), 1 on any unrecoverable violation or unrepairable state.

Help-text addition (in `cmd_help`):
```
fix-security     Repair fixable integrity violations (perms when sha256 matches);
                 exit non-zero on tampering or missing files
```

### `/cwf-init` step `1a`
Single Bash invocation; pass-through on success, abort+relay on failure. No new prompts to the user, no clarification questions. The subcommand's output speaks for itself.

## Constraints
- Bugfix scope — change is bounded to one new subcommand, one SKILL edit, and the necessary hash refresh
- Must remain idempotent (re-running `/cwf-init` or `cwf-manage fix-security` is a no-op when state is already correct)
- Must not chmod outside the files explicitly listed in `script-hashes.json`
- Must not "fix" a file whose sha256 doesn't match its recorded value, under any circumstances

## Decomposition Check
- [ ] **Time**: ~1 day, one Perl subcommand + one test file + one SKILL edit + hash refresh
- [ ] **People**: 1 person
- [ ] **Complexity**: 1 concern (deterministic repair-or-fail of the recorded inventory)
- [ ] **Risk**: Low — algorithm is data-driven, tested in isolation; no LLM judgement involved
- [ ] **Independence**: Single integration point (the SKILL step calls the subcommand)

No decomposition needed.

## Validation
- [x] `CWF::Validate::Security` already covers existence + permissions + SHA256 (`.cwf/lib/CWF/Validate/Security.pm:29-122`) and exposes per-file `permissions`/`sha256` from `script-hashes.json`
- [x] `cwf-manage` dispatch table is the right insertion point (`.cwf/scripts/cwf-manage:458-465`)
- [x] `cwf-manage` is hash-tracked (`script-hashes.json` carries an entry for it) — the hash will need refreshing after the script change, same as Task 119 did for `template-copier-v2.1`
- [x] `/cwf-init` does not currently invoke any integrity check (`.claude/skills/cwf-init/SKILL.md:1-140`)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 120
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
