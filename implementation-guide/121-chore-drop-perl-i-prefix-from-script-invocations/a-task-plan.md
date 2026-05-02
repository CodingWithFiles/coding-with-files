# Drop perl -I prefix from script invocations - Plan
**Task**: 121 (chore)

## Task Reference
- **Task ID**: internal-121
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/121-drop-perl-i-prefix-from-script-invocations
- **Template Version**: 2.1

## Goal
Eliminate `perl -I.cwf/lib <script>` from active CWF source, skills, docs, and tests, relying on Unix-idiomatic shebang semantics (`#!/usr/bin/perl -CDSL` + `FindBin`/`use lib`) for every post-install invocation. The single bootstrap exception — `/cwf-init` step 1a, where exec bits may be missing on a freshly-copied `.cwf/` — uses idiomatic `chmod u+x` then direct invocation, not `perl -I`.

## Background
After Task 120 added a `perl -I.cwf/lib .cwf/scripts/cwf-manage fix-security` line to `/cwf-init`'s SKILL.md, the user noticed the same anti-idiomatic phrasing repeated across older skills and docs. The right Unix model is "chmod +x; exec" — relying on the kernel + shebang + `FindBin` to do the right thing. `perl -I` invocations exist only as Windows-style "you can't just go executing scripts" accommodations; `cwf-manage` already uses `FindBin` + `use lib "$FindBin::Bin/../lib"` (line 25-26), so `-I.cwf/lib` is redundant whenever the script is executable.

## Success Criteria
- [ ] `grep -rn "perl -I.cwf/lib" .claude/ INSTALL.md README.md CLAUDE.md docs/ .cwf/docs/ .cwf/templates/ .cwf/scripts/ .cwf/lib/ t/` returns **zero hits** in active source. (Hits inside `implementation-guide/`, `CHANGELOG.md`, `BACKLOG.md` are historical and remain untouched.)
- [ ] `/cwf-init` step 1a uses `chmod u+x .cwf/scripts/cwf-manage && .cwf/scripts/cwf-manage fix-security` — bootstrap via chmod, not via `perl -I`.
- [ ] All other invocation sites (skills, docs, tests) use direct shebang invocation (e.g. `.cwf/scripts/cwf-manage validate`).
- [ ] `.cwf/scripts/cwf-manage validate` exits 0.
- [ ] `prove t/` shows 253/253 tests pass (test file edited; assertion semantics preserved).

## Original Estimate
**Effort**: 0.5 days
**Complexity**: Low
**Dependencies**: Task 120 already on main (`0d2f16c`).

## Major Milestones
1. **Inventory locked** — repo-wide grep confirmed 4 active hits across 4 files: `cwf-init/SKILL.md`, `cwf-security-check/SKILL.md`, `INSTALL.md`, `t/cwf-manage-fix-security.t`.
2. **Three direct-invocation sites updated** — security-check skill, INSTALL.md (line removed as redundant), test fixture.
3. **One bootstrap site reshaped** — `/cwf-init` step 1a switches from `perl -I` to `chmod u+x; exec`, with surrounding prose explaining why chmod is the bootstrap.
4. **Verification** — grep clean, validate clean, full test suite green.

## Risk Assessment

### Medium Priority Risks
- **Risk 1**: Test fixture currently strips exec bits from every file in `.cwf/scripts/` to verify fix-security repairs them. Moving to direct invocation requires re-introducing the user-x bit on `cwf-manage` before exec'ing it. Using a hardcoded chmod value risks drifting from the recorded permission in `script-hashes.json`.
  - **Mitigation**: All chmod values come from `script-hashes.json` (no magic numbers). The test helper reads the recorded `permissions` value via `JSON::PP::decode_json` and chmods to that exact value; TC-4 and TC-5 redirect their chmod-stripped target from `cwf-manage` to `command-helpers/cwf-version-tag` so fix-security's chmod path is still exercised on a non-bootstrap script. The single `0644` literal in `strip_perms_recursive` and TC-4/5 setup is an *intentionally stripped* state (no exec, no group/other bits), not a recorded value — it stays as a fixture-mutation constant.

### Low Priority Risks
- **Risk 2**: `cwf-manage`'s shebang `#!/usr/bin/perl -CDSL` requires `/usr/bin/perl`. On systems where Perl lives elsewhere (some BSDs, fresh macOS without Xcode), the bootstrap fails.
  - **Mitigation**: Pre-existing assumption — `perl -I.cwf/lib` had the same dependency. No regression; out of scope to address.

- **Risk 3**: `INSTALL.md`'s `perl -I.cwf/lib -MCWF::Common -e 'print "OK\n"'` line is a perl module-loadability sanity check, not a script invocation. Removing it leaves the install verification one check shorter.
  - **Mitigation**: The line immediately before it (`.cwf/scripts/command-helpers/context-manager location`) already exercises `CWF::Common` loading via `FindBin` (verified at `context-manager.d/location:5-6`). The `-MCWF::Common` line is redundant and can be removed cleanly.

## Dependencies
- Task 120 on main — done.

## Constraints
- Historical files (`implementation-guide/**`, `CHANGELOG.md`, `BACKLOG.md`) are off-limits — they record what shipped.
- No behaviour changes to `cwf-manage` or any tracked Perl module — pure invocation-style cleanup.

## Decomposition Check
- [x] **Time**: 0.5 days, well under 1 week
- [x] **People**: 1 person
- [x] **Complexity**: 1 concern — invocation-style cleanup with one bootstrap exception
- [x] **Risk**: Low — no library/code logic changes
- [x] **Independence**: Single coherent change set

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 121
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
