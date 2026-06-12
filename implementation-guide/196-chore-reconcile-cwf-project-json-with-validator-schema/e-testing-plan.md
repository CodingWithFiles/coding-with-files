# Reconcile cwf-project.json with validator schema - Testing Plan
**Task**: 196 (chore)

## Task Reference
- **Task ID**: internal-196
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/196-reconcile-cwf-project-json-with-validator-schema
- **Template Version**: 2.1

## Goal
Verify the rewritten template validates clean against `CWF::Validate::Config`, carries no vestigial keys, uses the documented pass-through names, and that nothing else in the suite regresses.

## Test Strategy
### Test Levels
- **Unit / file-guard**: extend `t/cwf-project-template.t` — the existing guard over the shipped template. All new assertions live here; no new test file (reuse).
- **Regression**: full `prove t/` to confirm the template rewrite and the `cwf-init` prose edit break nothing (the init skill is exercised indirectly only — no init-specific automated test exists, so the prose edit is verified by inspection).
- **Manual inspection**: read the rewritten template against `CWF-PROJECT-SPEC.md`; confirm `cwf-init` SKILL.md step 2 wording matches the produced keys.

### Test Coverage Targets
- Every key-shape claim in the d-plan success criteria has a corresponding assertion (validator-clean, vestigial-absent, documented-names-present, placeholder-fixed).
- No regression: `prove t/` exit 0, same or higher test count than baseline.

## Test Cases
### Functional Test Cases (all in `t/cwf-project-template.t`)
- **TC-1 (existing, retained)**: template parses as valid JSON.
  - **Given**: shipped `.cwf/templates/cwf-project.json.template`.
  - **When**: slurped raw and `decode_json`'d.
  - **Then**: no parse error.
- **TC-2 (existing, retained)**: retired top-level `version` field absent.
  - **Given**: decoded template.
  - **When**: check `exists $cfg->{version}`.
  - **Then**: false. (Comment rewritten — see TC-6 note; `cwf-version` is now *also* asserted absent by TC-4, reversing the Task-188 carve-out for the template.)
- **TC-3 (new): validator-conformance.**
  - **Given**: decoded template.
  - **When**: `validate_config_hash($cfg, $template)`.
  - **Then**: returns **0** violations. (Weak signal on its own — see d-plan caveat — but a necessary floor.)
- **TC-4 (new): vestigial keys absent.**
  - **Given**: decoded template.
  - **When**: check each of `cwf-version`, `_cwf-version-note`, `title`, `team`, `task-management`, `project`.
  - **Then**: none exist as a top-level key.
- **TC-5 (new): documented pass-through names present + placeholder fixed.**
  - **Given**: decoded template.
  - **When**: check `project-name` and `task-tracking` exist; check `source-management.branch-naming-convention`.
  - **Then**: both keys present; the branch convention string contains `{description-slug}` (not `{task-description}`).
- **TC-6 (process, not an assertion): stale comment rewritten.**
  - **Given**: `t/cwf-project-template.t` after edit.
  - **When**: read lines around the old TC-2 carve-out.
  - **Then**: the "`cwf-version` … deliberately NOT asserted" comment is gone/rewritten so it no longer contradicts TC-4. Verified by inspection during exec.

### Regression / Non-Functional Test Cases
- **TC-R1**: `prove t/validate-config.t` green — the validator is unchanged; this confirms no accidental coupling.
- **TC-R2**: full `prove t/` green, exit 0 — no other test couples to the removed template keys.
- **Security**: covered by the plan-review security pass — the `sandbox` block (the only security-relevant payload) is retained verbatim with fail-safe defaults (`enabled:false`, `fail-if-unavailable:true`, `planning-write-guard:"off"`). No new automated security test needed; TC-3 confirms the block still validates.
- **Performance / usability / reliability**: not applicable (static config template).

## Test Environment
### Setup Requirements
- In-repo Perl test harness (`prove`, `Test::More`, `JSON::PP`, `FindBin`) — all core modules, already used by the existing test.
- `CWF::Validate::Config` reachable via `use lib "$FindBin::Bin/../.cwf/lib"`.
- No test database, no network, no external services.

### Automation
- `prove t/cwf-project-template.t` for the focused guard; `prove t/` for regression.
- Runs in the existing suite; no new CI wiring.

## Validation Criteria
- [ ] TC-1..TC-5 pass in `t/cwf-project-template.t`.
- [ ] TC-6 confirmed by inspection (no self-contradictory comment remains).
- [ ] TC-R1, TC-R2 green (full suite, exit 0).
- [ ] `cwf-init` SKILL.md step 2 prose matches the produced key names (manual).
- [ ] Rewritten template reads clean against `CWF-PROJECT-SPEC.md` (manual).

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned test cases (TC-1..TC-6, plus regression TC-R1/TC-R2) executed and passed (see `g-testing-exec.md`). The plan's instinct to assert presence/absence of specific keys alongside the validator-clean check proved essential: a validator-clean assertion alone would have passed against the old, wrong shape.

## Lessons Learned
"Validates" and "matches the documented shape" are independent properties — schema-conformance tests must assert specific key presence/absence, not just zero violations. See `j-retrospective.md`.
