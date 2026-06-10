# Retire vestigial cwf-project.json version field - Testing Plan
**Task**: 188 (chore)

## Task Reference
- **Task ID**: internal-188
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/188-retire-vestigial-cwf-projectjson-version-field
- **Template Version**: 2.1

## Goal
Verify the retired field(s) are gone and stay gone, and that removal changed no behaviour.

## Test Strategy
### Test Levels
- **Guard test (new)**: `t/cwf-project-template.t` parses the shipped template and asserts the retired key(s) are absent — the anti-regression lock.
- **Regression (full suite)**: `prove -lr t/` proves nothing depended on the field (especially `validate-config.t`, `validate-templates.t`, the template-copier tests).
- **System**: `cwf-manage validate` runs clean with the field removed.

### Test Coverage Targets
- The single behavioural claim ("field is unread, removal is inert") is covered by the full suite staying green.
- The single durability claim ("field cannot silently return") is covered by the guard test.
- No coverage % target — this is a deletion, not new logic.

## Test Cases
### Functional Test Cases
- **TC-1 (guard: template parses)**: **Given** the shipped `.cwf/templates/cwf-project.json.template`. **When** `t/cwf-project-template.t` reads it and `decode_json`s inside an `eval`. **Then** no error is thrown (a malformed template fails the test loudly — not a silent skip).
- **TC-2 (guard: `version` absent)**: **Given** the parsed template hashref. **When** checked. **Then** `!exists $j->{version}` holds. *(Narrow scope: do NOT assert on `cwf-version` — it is intentionally retained.)*
- **TC-3 (validator regression)**: **Given** this repo's `implementation-guide/cwf-project.json` with the top-level `version` removed. **When** `cwf-manage validate` runs. **Then** it exits 0 (no new violation — the field was never required).
- **TC-4 (full-suite regression)**: **Given** the field removed from template + live config. **When** `prove -lr t/`. **Then** every test passes — demonstrating no reader/fixture depended on the field.

### Non-Functional Test Cases
- **Reliability**: TC-1 is the graceful-failure guarantee (parse error ⇒ loud test failure, never a false green).
- **Security**: change only *reduces* surface (deletes config data); no auth/network/integrity tests needed (template/live config are not hash-tracked).
- **Usability / Performance**: N/A — no user-facing behaviour or performance surface changes.

## Test Environment
### Setup Requirements
- Perl core + `Test::More`, `JSON::PP`, `FindBin` — all already used across `t/`. No new deps.
- The guard test reads the in-repo template at a `FindBin`-relative path; it mutates nothing.

### Automation
- `prove -lr t/cwf-project-template.t` (targeted) and `prove -lr t/` (full regression), plus `cwf-manage validate`. No CI changes.

## Validation Criteria
- [ ] TC-1, TC-2 pass in `t/cwf-project-template.t`.
- [ ] TC-3: `cwf-manage validate` exits 0.
- [ ] TC-4: full `prove -lr t/` green.

## Decomposition Check
0 signals — one guard test + regression run. No decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
