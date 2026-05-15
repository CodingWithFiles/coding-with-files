# backlog-manager double-encodes non-ASCII @ARGV - Implementation Plan
**Task**: 137 (bugfix)

## Task Reference
- **Task ID**: internal-137
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/137-backlog-manager-double-encodes-non-ascii-argv
- **Template Version**: 2.1

## Goal
Apply the design from c-design-plan.md: extend the shebang convention `-CDSL` → `-CDSLA`, update the validator and ancillary docs atomically.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Shebangs (11 files, mechanical)
Replace the first line `#!/usr/bin/perl -CDSL` with `#!/usr/bin/perl -CDSLA` in each:
- `.cwf/scripts/cwf-manage`
- `.cwf/scripts/command-helpers/backlog-manager`
- `.cwf/scripts/command-helpers/context-inheritance-v2.0`
- `.cwf/scripts/command-helpers/context-inheritance-v2.1`
- `.cwf/scripts/command-helpers/cwf-apply-artefacts`
- `.cwf/scripts/command-helpers/security-review-changeset`
- `.cwf/scripts/command-helpers/status-aggregator-v2.0`
- `.cwf/scripts/command-helpers/status-aggregator-v2.1`
- `.cwf/scripts/command-helpers/template-copier-v2.0`
- `.cwf/scripts/command-helpers/template-copier-v2.1`
- `.cwf/scripts/hooks/stop-uncommitted-changes-warning`

### Validator
- `.cwf/lib/CWF/Validate/PerlConventions.pm`
  - Line 13: `PERL5OPT=-CDSL` → `PERL5OPT=-CDSLA` (file-header comment).
  - Lines 17–18: shebang rule description string `'#!/usr/bin/perl -CDSL'` → `'#!/usr/bin/perl -CDSLA'`.
  - Line 93: error message mentions `PERL5OPT=-CDSL` → `-CDSLA`.
  - Line 111: `ne '#!/usr/bin/perl -CDSL'` → `ne '#!/usr/bin/perl -CDSLA'`.
  - Line 114: violation's `expected` field `'#!/usr/bin/perl -CDSL'` → `'#!/usr/bin/perl -CDSLA'`.
  - Line 115: error-message string `'#!/usr/bin/perl -CDSL'` → `'#!/usr/bin/perl -CDSLA'`.

### Convention doc
- `docs/conventions/perl-git-paths.md`
  - Lines 10–11: replace the "Shebang" bullet per Decision 4 (explain `D`/`S`/`L`/`A`, name Task 137).
  - Line 45: `-CDSL` → `-CDSLA` in the rationale paragraph.
  - Line 59: `-CDSL` → `-CDSLA` in the Enforcement paragraph.

### Init skill
- `.claude/skills/cwf-init/SKILL.md:149`: `"PERL5OPT": "-CDSL"` → `"PERL5OPT": "-CDSLA"`.

### Common warning
- `.cwf/lib/CWF/Common.pm:23`: `"PERL5OPT": "-CDSL"` → `"PERL5OPT": "-CDSLA"`. Logic unchanged.

### Hashes (regenerated, not hand-edited)
- `.cwf/security/script-hashes.json`: recompute SHA256 entries for every file modified above (11 shebangs + `PerlConventions.pm` + `Common.pm`). Compute with `sha256sum` (per the verifier/producer-diversity convention).

## Implementation Steps

### Step 1: Pre-flight audit (FM-1 confirmation gate)
The design-phase plan-review subagents already greped all 11 scripts for the FM-1 audit patterns and found no problematic uses (no `unpack` on `@ARGV` data, no `:raw` opens of argv-derived paths, no byte-counting `length` on argv data, no pre-existing `decode_utf8` calls at script top). The `length()`/`:raw`/`open` hits in the 11 scripts are all against hardcoded paths or already-deserialised data, not raw `@ARGV`.

- [ ] Re-run the consolidated grep as a confirmation gate: `grep -nE 'unpack|:raw|Encode::decode_utf8' <11 scripts>` returns no argv-related hits. Record `confirmation_pass: yes` in `f-implementation-exec.md`. If anything new appears, STOP and re-open design.

### Step 2: Apply shebang changes
- [ ] Single-line Edit on each of the 11 scripts: `#!/usr/bin/perl -CDSL` → `#!/usr/bin/perl -CDSLA`.
- [ ] Quick spot-check after each: run the script with no args to confirm it still loads and produces its usual usage message (not a perl parse error).

### Step 3: Apply validator update
- [ ] Edit `PerlConventions.pm` at lines 13, 17–18, 93, 111, 114, 115. All six sites in one Edit operation set.

### Step 4: Apply ancillary updates
- [ ] `docs/conventions/perl-git-paths.md`: rewrite the Shebang bullet (lines 10–11) per Decision 4; update lines 45 and 59.
- [ ] `.claude/skills/cwf-init/SKILL.md:149`: one string replacement.
- [ ] `.cwf/lib/CWF/Common.pm:23`: one string replacement.

### Step 5: Regenerate hashes
- [ ] **Producer**: `sha256sum` from coreutils (NOT `Digest::SHA` from Perl). This preserves the verifier/producer implementation-diversity property — `CWF::Validate::Security` verifies with Perl's `Digest::SHA::sha256_hex`; the producer must be a different implementation.
- [ ] For each modified file under `.cwf/`, run `sha256sum <path>` and splice the new hex into the existing entry in `.cwf/security/script-hashes.json` via the Edit tool. Do NOT invoke any auto-reconciliation tool (no `recompute-hashes`, no `cwf-manage fix-security` for hash drift — fix-security only handles permissions). Per the "surface security issues, never smooth them" memory, hash mismatches must be re-recorded deliberately, not papered over.

### Step 6: Local verification
- [ ] `.cwf/scripts/cwf-manage validate` — must exit 0. Verifies new shebangs, validator accepts them, and all hashes match.
- [ ] `prove -r t/` — full test suite green.
- [ ] Post-edit anchor grep: `grep -rln '^#!/usr/bin/perl -CDSL$' .cwf/` (anchored `$`) returns zero results. This catches any shebang missed in Step 2.

The byte-level encoding round-trip check is implemented as a formal test case in `e-testing-plan.md` (writes via a Perl `File::Temp` fixture, never touches the live `BACKLOG.md`, runs under `prove`). No manual scratch-file smoke test in this phase.

## Test Coverage
Detailed test plan is in `e-testing-plan.md` (next phase). Implementation-phase verification is limited to: pre-existing test suite still passes; one manual smoke test of the bug being fixed; `cwf-manage validate` clean.

## Validation Criteria
- [ ] All 11 shebangs read `#!/usr/bin/perl -CDSLA`.
- [ ] `PerlConventions.pm` accepts new shebang and rejects old (regression test in `e-testing-plan.md`).
- [ ] Convention doc accurately describes `-CDSLA` semantics — no stale claim that `-CDSL` decodes `@ARGV`.
- [ ] `cwf-init` SKILL.md and `Common.pm` warning text both recommend `-CDSLA`.
- [ ] `script-hashes.json` is consistent with the on-disk files — `cwf-manage validate` reports `OK`.
- [ ] Existing test suite green (no regressions).
- [ ] Byte-level encoding round-trip check is delivered as a `prove`-driven test case (specified in `e-testing-plan.md`).

## Risks During Implementation
- **R1**: Edit by hand misses a shebang in one of the 11. **Mitigation**: post-edit `grep -rln "^#!/usr/bin/perl -CDSL$" .cwf/` (anchored `$`) must return zero results.
- **R2**: Hash recompute uses a wrong algorithm or ordering. **Mitigation**: `cwf-manage validate` is the gate. The script-hashes.json schema is well-known and Task 135 just exercised it.
- **R3**: A grandfathered or excluded file is accidentally edited. **Mitigation**: the file list is finite and enumerated above; the grandfathered `stop-stale-status-detector` (uses `env perl`) is not in the list.

## Decomposition Check
Single change set, single commit target. No decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
- 11 production-script shebangs updated to `-CDSLA`; PerlConventions.pm literal updated; 7 test fixtures in `t/validate-perl-conventions.t` updated in lockstep; 12 sha256 hashes regenerated via `sha256sum` (verifier-diversity preserved).
- Doc-update steps from the original plan (perl-git-paths.md, SKILL.md, INSTALL.md, Common.pm warn-string, security-review.md, validator messages, header comments) were *all deferred* mid-execution. See `f-implementation-exec.md` § "Scope (minimal, post-discovery)" and the Very-High backlog item "Re-align Perl-Script Convention to Task-27 Form and Anchor in CLAUDE.md".

## Lessons Learned
- The d-plan was written for the originally-discovered scope; once exec discovered the wider convention drift, descoping was handled by re-scoping in `f-implementation-exec.md` rather than by rewriting d-plan history. This leaves a deliberate, named gap between d-plan and shipped reality — acceptable, but a future reader needs to read f-plan to see the actual shipped scope.
- Test fixtures coupled to the validator literal (`t/validate-perl-conventions.t` shebangs) are properly part of the "minimum work" set, not optional. d-plan missed them; e-plan caught them under "Additional Implementation Surface Discovered During Test Planning". Worth scanning d-plans for *implementation surface that only shows up when you write tests for the change*.
