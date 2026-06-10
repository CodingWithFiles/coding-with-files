# Retire vestigial cwf-project.json version field - Implementation Plan
**Task**: 188 (chore)

## Task Reference
- **Task ID**: internal-188
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/188-retire-vestigial-cwf-projectjson-version-field
- **Template Version**: 2.1

## Goal
Delete the vestigial top-level `version` field (and the orphaned note that documents it) from the shipped template and this repo's config, plus a regression guard.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Scope (resolved at review): strictly narrow
Review chose the **strictly-narrow** scope: retire the top-level `version` field and its documenting note only.

Verified unread (no `$config->{...}` reader anywhere; every `cwf-version*` grep hit is a *script* name, not the field):

| Line | Template | Live config | Reader? | This task? |
|------|----------|-------------|---------|------------|
| `version` | yes (L3) | yes (L102) | none | **remove** |
| `_version-note` | yes (L4) | no | none (annotates `version`) | **remove** (dangling comment once `version` is gone) |
| `cwf-version` | yes (L5) | no | none | **deferred** → follow-up |
| `_cwf-version-note` | yes (L6) | no | none (annotates `cwf-version`) | **deferred** → follow-up |

`cwf-version`/`_cwf-version-note` and `security.version-tracking` are the identical vestigial pattern but are explicitly **out of scope** for this task. File a backlog follow-up at rollout/retrospective: "Retire remaining vestigial version fields (`cwf-version`/`_cwf-version-note` in template; `security.version-tracking`)."

## Files to Modify
### Primary Changes
- `.cwf/templates/cwf-project.json.template` — delete `version` (L3) + `_version-note` (L4). Leave `cwf-version` (L5) + `_cwf-version-note` (L6) in place (deferred). Comma-safety: L2 `title` precedes and L5 `cwf-version` follows, both with trailing commas; removing L3–L4 leaves valid JSON.
- `implementation-guide/cwf-project.json` — delete the top-level `version` line (L102; sits between `templates` and `versioning`, trailing comma — clean removal).
- `CWF-PROJECT-SPEC.md` — **added at exec time** (Step 1 baseline discovery): the spec declared `version` a **required** field in 5 places (root-object schema L21, the `#### version (required)` field-spec block L39–42, both config examples L129/L157, and the Validation Rules → Required Fields list L215). Retiring the field while its own authoritative spec still lists it as required would ship the exact spec/implementation drift this task removes. All five edits are `version`-only (no `cwf-version` touched), so the change stays strictly-narrow. Not hash-tracked — no hash refresh.

### Supporting Changes
- `t/cwf-project-template.t` — **new** minimal test: read the shipped template, `decode_json` inside an `eval` and assert **no error** (a malformed/unparseable template is a hard test failure, not a silent skip), then assert `!exists $j->{version}`. No existing test parses the template, so this is a new test category and its home. Mirror a sibling `t/*.t` for harness conventions: `use strict; use warnings; use utf8;`, `Test::More`, `done_testing`, `FindBin` for the repo-relative path. Keep it lean — assert `version` absence only; do **not** assert on `cwf-version` (still present, deferred) nor on `_*-note` keys.

### Explicitly NOT modified
- No `.cwf/security/script-hashes.json` / `.cwf/install-manifest.json` change — neither file tracks the template or the live config (verified). No hash refresh.
- No `CWF::Validate::Config` change — it neither requires nor rejects the key.

## Implementation Steps
### Step 1: Baseline
- [ ] Re-confirm zero readers exhaustively: repo-wide `git grep` for the **bare key strings** (`'version'`, `"version"`, `cwf-version`, `_version-note`, `_cwf-version-note`) across all file types — not only the `$config->{version}` deref form (a reader could use a variable key or `exists`). Confirm every hit is unrelated (`versioning.*`, template-version markers, the `cwf-version-*` script names). Also confirm `install.bash` / `cwf-apply-artefacts` / `cwf-init` do not regenerate a `version` key.
- [ ] `cwf-manage validate` clean before edits.

### Step 2: Remove the field
- [ ] Edit `.cwf/templates/cwf-project.json.template`: remove L3–L4 (`version`, `_version-note`). Leave L5–L6 (`cwf-version`, `_cwf-version-note`) untouched.
- [ ] Edit `implementation-guide/cwf-project.json`: remove the top-level `version` line.

### Step 3: Guard test
- [ ] Add `t/cwf-project-template.t` (mirroring a sibling test's conventions): `eval { decode_json }`-assert-no-error so a malformed template fails loudly, then assert absence of the retired key(s).

### Step 4: Validation
- [ ] `prove -lr t/cwf-project-template.t` green.
- [ ] Full `prove -lr t/` green (no regressions — especially `validate-config.t`, which must still pass with the key gone).
- [ ] `cwf-manage validate` clean.

## Code Changes
### `.cwf/templates/cwf-project.json.template` — before (L1–L7)
```json
{
  "title": "Coding with Files Project Configuration",
  "version": "v0.2.1",
  "_version-note": "Use git describe --tags --always format for version tracking",
  "cwf-version": "v0.2.1",
  "_cwf-version-note": "Should match your project version for consistency",
  "project": {
```
### After (narrow scope — `cwf-version` retained)
```json
{
  "title": "Coding with Files Project Configuration",
  "cwf-version": "v0.2.1",
  "_cwf-version-note": "Should match your project version for consistency",
  "project": {
```
### `implementation-guide/cwf-project.json` — remove the single line
```json
  "version" : "v0.2.1",
```

## Test Coverage
**See e-testing-plan.md.** Summary: one new guard test (`t/cwf-project-template.t`) asserting the retired key(s) are absent + template still valid JSON; full-suite regression to prove nothing read the field.

## Validation Criteria
**See e-testing-plan.md.** Gate: guard test passes, full suite green, `cwf-manage validate` clean — all with the field removed.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Decomposition Check
0 signals — delete a contiguous line run + one guard test. No decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
