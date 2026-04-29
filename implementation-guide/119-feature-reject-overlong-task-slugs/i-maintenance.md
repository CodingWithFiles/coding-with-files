# Reject overlong task slugs - Maintenance
**Task**: 119 (feature)

## Task Reference
- **Task ID**: internal-119
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/119-reject-overlong-task-slugs
- **Template Version**: 2.1

## Active Maintenance Requirements

**Scheduled maintenance**: NONE — single-comparison validation in a CLI helper, no state, no logs, no external dependencies. Fires only at task-creation time.

**Reactive maintenance**:
- **IF** a user reports a valid description being rejected wrongly → **THEN** check `generate_slug` in `template-copier-v2.1` for unintended changes; verify the slug against the rules (lowercase, `[a-z0-9 -]` only, ` +` → `-`, `-+` → `-`, leading/trailing `-` stripped). Most likely cause: a regex regression. Reproduce with `t/template-copier-slug-validation.t`.
- **IF** the rejection stops firing for overlong descriptions → **THEN** confirm `parse_parameters` still calls `generate_slug` and the `length($slug) > SLUG_MAX_LEN` guard (line 97) is intact, and confirm the script's hash in `.cwf/security/script-hashes.json` matches the on-disk file (mismatch indicates a non-canonical edit path or a caller using a stale copy).
- **IF** `cwf-manage validate` reports a hash mismatch on `template-copier-v2.1` → **THEN** recompute via `sha256sum .cwf/scripts/command-helpers/template-copier-v2.1` and update `script-hashes.json` line 47.
- **IF** the existing `print STDERR "Error: ..." + exit 1` blocks elsewhere in `parse_parameters` are migrated to `die_msg` (boy-scout audit; tracked as future work) → **THEN** that audit task can also extract `die_msg` to a shared `CWF::Common` module shared with `cwf-manage`. Both refactors are out of scope for Task 119.

**Deprecation trigger**: If CWF changes the slug rules (limit value, allowed characters, normalisation), update `SLUG_MAX_LEN` and `generate_slug` together; the test file `t/template-copier-slug-validation.t` will catch divergence between behaviour and the documented contract.

## Known Co-Behaviour
- The validation runs *before* `construct_destination`, so any caller that passes `--destination` directly without `--description` would skip the check. Per c-design-plan.md Decision 6 this is a non-issue: `--description` is a required parameter (enforced by the existing required-param loop earlier in `parse_parameters`), so reaching the validation without a description is impossible.
- `compute_variables` (later in the script) re-derives the slug from the destination basename via regex extraction, which is independent of `generate_slug`. That path is unchanged by this task and continues to support pre-truncated destinations gracefully.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 119
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**
