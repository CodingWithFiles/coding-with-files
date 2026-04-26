# Add retrospective version bump and tag settings with versioning helper script - Maintenance
**Task**: 114 (feature)

## Task Reference
- **Task ID**: internal-114
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/114-add-retrospective-version-bump-and-tag-settings-w
- **Template Version**: 2.1

## Goal
Capture the small ongoing-maintenance surface for the versioning subsystem: where state lives, what can rot, and the runbook for the few failure modes that are realistic.

## Active Maintenance Requirements

This is developer tooling, not a service. There is nothing to monitor at runtime. Maintenance reduces to:

- **Schema drift watch**: if `cwf-project.json` is hand-edited (e.g., a human bumps `versioning.major_minor`), the next `cwf-version-bump` will write a fresh `last_released` under the new base — by design. No action needed unless the human edit was a mistake.
- **Test-suite green**: `prove t/` should remain 229+ green. `t/versioning.t`, the three `t/cwf-version-*.t` files, and the `t/validate-config.t` extensions are the canaries. A regression in any of these is the signal.
- **Hash freshness**: any future edit to `.cwf/lib/CWF/Versioning.pm`, `.cwf/lib/CWF/Common.pm`, or any of the three `cwf-version-*` scripts requires updating `.cwf/security/script-hashes.json` (the existing post-commit `cwf-manage validate` enforces this).

No daily/weekly/monthly cadence; maintenance is reactive.

## Common Issues — Runbook

### Issue 1: `versioning.major_minor missing in <path>`
- **Symptom**: `cwf-version-next` or `cwf-version-bump` exits 1 with this message during retrospective
- **Diagnosis**: The project's `implementation-guide/cwf-project.json` has no `versioning.major_minor` field
- **Resolution**: Add `"versioning": { "major_minor": "vX.Y" }` to the file. Pick `X.Y` per semver — usually `v1.0` for a new project, or whatever the project's last released major.minor was

### Issue 2: `versioning.major_minor malformed in <path>: "..."`
- **Symptom**: Same scripts exit 1; message names the bad value
- **Diagnosis**: The field is present but doesn't match `/^v\d+\.\d+$/` (e.g., `1.0`, `v1`, `v1.0.0`)
- **Resolution**: Edit the field to the correct shape (e.g., `v1.0`)

### Issue 3: `cwf-version-tag` reports `not on main branch`
- **Symptom**: Retrospective Step 11 returns this error
- **Diagnosis**: `tag_version: true` is set, but the script ran on a feature/checkpoints branch rather than `main`
- **Resolution**: Either (a) merge to main first then run the tag manually, or (b) for CwF itself, leave `tag_version: false` (the default) — tagging is human-only per CLAUDE.md

### Issue 4: `cwf-version-tag` reports `tag vX.Y.Z already exists`
- **Symptom**: Tag step refuses on retrospective re-run
- **Diagnosis**: A tag for this version was created in a previous run
- **Resolution**: This is the intended behaviour — refuses overwrite. If the existing tag is wrong, the human must `git tag -d vX.Y.Z` deliberately before re-running

### Issue 5: `cwf-manage validate` fails after editing a script
- **Symptom**: Hash mismatch in `script-hashes.json`
- **Diagnosis**: The script content changed but the SHA256 in the registry didn't get updated
- **Resolution**: `sha256sum <script>` and update `.cwf/security/script-hashes.json`

### Issue 6: `cwf-project.json` formatting churn after manual edits
- **Symptom**: First `cwf-version-bump` after a manual edit produces a large diff (re-alphabetisation + value change)
- **Diagnosis**: The file was edited in non-canonical form; `cwf-version-bump` writes canonical pretty-print
- **Resolution**: Expected and one-time; subsequent bumps are value-only diffs. To pre-empt, format manual edits with `JSON::PP->new->pretty->indent_length(2)->canonical->encode($cfg)` before saving

## When to Revisit

Open a follow-up task if any of the following becomes true:

- A second versioning scheme (e.g., calver, monotonic build numbers) is needed → adds a `versioning.scheme` field and a dispatch table in `CWF::Versioning`
- A second wf-step setting block is added (e.g., `wf_step_config.implementation-exec.run_static_analysis`) and the validation logic in `CWF::Validate::Config` starts to feel templated → factor `_validate_wf_step_config_block` to dispatch to per-step rule registries
- Atomic-write needs to be re-used (e.g., a future helper that mutates `cwf-project.json`) → extract the tmp+rename pattern from `CWF::Versioning::bump_to` into `CWF::Common::write_json_atomic`
- A non-CwF project adopts CwF and needs `tag_version: true` with non-main branches (e.g., `release/*`) → extend `tag_at` to allow a regex pattern for valid branches

## Documentation Pointers

- `.cwf/docs/workflow/versioning-standard.md` — user-facing standard
- `.cwf/lib/CWF/Versioning.pm` — module API and POD
- `.claude/skills/cwf-retrospective/SKILL.md` Steps 9 and 11 — invocation context

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 114
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Maintenance plan reduced to a runbook. No SLA, no monitoring, no schedule — appropriate for the developer-tool execution model.

## Lessons Learned
A "common issues runbook" with concrete error messages (Symptom / Diagnosis / Resolution) is more useful than the template's generic monitoring/alerting/SLA structure. Same observation as the rollout phase — backlog for lighter templates.
