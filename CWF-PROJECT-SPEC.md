# CWF Project Configuration Specification

## Goal

Define the schema for the `cwf-project.json` configuration file that adapts the CWF
system to a project's task types, branch conventions, and versioning.

This document distinguishes two kinds of keys:

- **Validated keys** — checked by `CWF::Validate::Config` (`.cwf/lib/CWF/Validate/Config.pm`)
  and enforced on every `cwf-manage validate` run. A malformed validated key fails the
  integrity gate.
- **Pass-through keys** — conventionally present in a project config and read by various
  helpers, but **not** checked by the validator. Their shape is by convention only; the
  validator neither requires nor rejects them.

The validator is the single source of truth for what is enforced. If this document and
`CWF::Validate::Config` ever disagree, the code wins.

## File Location

```
<git-root>/implementation-guide/cwf-project.json
```

A project with no config file is a valid pre-init state — the validator treats an absent
file as "nothing to check", not an error.

## Validated Keys

### `supported-task-types` (required)
- **Type**: Array of strings.
- **Rule**: Must be present, must be a JSON array, and must **equal the canonical set**
  exactly — no unknown types, no missing types. The canonical set is derived from
  `CWF::WorkflowFiles::V21::supported_types()`, currently:
  `feature`, `bugfix`, `hotfix`, `chore`, `discovery`.
- **Why exact-match**: each type maps to a fixed workflow-file set (see
  `%WORKFLOW_FILES`), so an unrecognised type has no template set and a missing type
  would silently disable a workflow.

### `source-management` (required)
- **Type**: Object.
- **Rule**: Must be present and be a JSON object containing a non-empty
  `branch-naming-convention` string.
- **`branch-naming-convention`**: branch-name pattern. Placeholders such as
  `{task-type}`, `{task-id}`, and `{description-slug}` are substituted when a branch
  name is suggested. Example: `"{task-type}/{task-id}-{description-slug}"`.

### `versioning` (optional)
- **Type**: Object. Absent ⇒ no check.
- **`major_minor`** (optional): string matching `/^v\d+\.\d+$/`, e.g. `"v1.1"`.
- **`last_released`** (optional): string matching `/^v\d+\.\d+\.\d+$/`, e.g. `"v1.1.232"`.
- Either sub-key may be present independently; each is validated only if present.

### `wf_step_config` (optional)
- **Type**: Object keyed by workflow-step name. Absent ⇒ no check.
- **Rule**: Each step value must be an object whose every value is a boolean
  (`true`/`false`). Used to toggle per-step behaviour, e.g.:
  ```json
  "wf_step_config": {
    "retrospective": { "bump_version": true, "tag_version": false }
  }
  ```

### `sandbox` (optional)
- **Type**: Object. Absent ⇒ no check.
- **`enabled`**, **`fail-if-unavailable`**, **`violation-logging`** (optional): each must
  be a boolean if present.
- **`credential-deny-list`** (optional): array of path strings (e.g. `["~/.ssh", "~/.aws"]`).
  An absent list with `enabled: true` is valid.
- **`planning-write-guard`** (optional): enum, one of `off`, `observe`, `enforce`
  (the allowed set is `CWF::PlanningGuard::PLANNING_GUARD_VALUES`). Absent ⇒ `off`.

## Pass-through Keys (not validated)

These keys appear in the dog-fooded `implementation-guide/cwf-project.json` and are read
by individual helpers, but `CWF::Validate::Config` does **not** check their presence or
shape. Treat the structures below as convention, not contract — do not assume the
validator will catch a mistake in them.

- **`project-name`** / **`description`**: human-readable identification.
- **`task-tracking`**: task-system integration — `system`, `base-url`, `id-format`, and a
  `fallback` block for tasks without an external issue (e.g. `internal-{{number}}`).
- **`directory-structure`**: `base-path` (`implementation-guide`), `max-depth`, and the
  task-directory `pattern`.
- **`integration`**: tool paths (e.g. `claude-code.autoload-config`).
- **`security`**: `canonical-source` for the install/verify origin, `file-integrity`
  globs, `review.max-lines-exclude-paths`, and `version-tracking`. (Hash enforcement
  itself lives in `.cwf/security/script-hashes.json`, not here.) The
  `review.max-lines-exclude-paths` default ships **seeded** in
  `cwf-project.json.template` (generic test/generated/vendored/doc-only globs) for
  new projects. `review.max-lines` is **not** template-seeded — the built-in cap
  default (1000) lives in `security-review-changeset`; set the key only to diverge.
- **`workflow`**: `required-sections` and the `status-values` map used by status
  aggregation.
- **`templates`**: a legacy per-type filename map. The active template source is
  `%WORKFLOW_FILES` in `CWF::WorkflowFiles::V21`; this block is vestigial.

## Minimal Valid Configuration

The smallest config that passes `cwf-manage validate`:

```json
{
  "supported-task-types": ["feature", "bugfix", "hotfix", "chore", "discovery"],
  "source-management": {
    "branch-naming-convention": "{task-type}/{task-id}-{description-slug}"
  }
}
```

## Configuration With Optional Validated Blocks

```json
{
  "supported-task-types": ["feature", "bugfix", "hotfix", "chore", "discovery"],
  "source-management": {
    "branch-naming-convention": "{task-type}/{task-id}-{description-slug}"
  },
  "versioning": {
    "major_minor": "v1.1",
    "last_released": "v1.1.232"
  },
  "wf_step_config": {
    "retrospective": { "bump_version": true, "tag_version": false }
  },
  "sandbox": {
    "enabled": false,
    "fail-if-unavailable": true,
    "violation-logging": false,
    "credential-deny-list": ["~/.ssh", "~/.aws"],
    "planning-write-guard": "off"
  }
}
```

## Usage in CWF Commands

### `/cwf-init`
- Creates an initial `cwf-project.json` for the project.

### `/cwf-new-task`
- Validates the requested task type against `supported-task-types`.
- Uses `source-management.branch-naming-convention` to suggest the branch name.

### `cwf-manage validate`
- Runs `CWF::Validate::Config` against the validated keys above and reports any
  violation with a `field`, `actual`, `expected`, and `fix` line.

## Validation Summary

1. **Required**: `supported-task-types` (exact canonical set) and
   `source-management.branch-naming-convention` (non-empty string).
2. **Optional, validated when present**: `versioning` (`major_minor` `/^v\d+\.\d+$/`,
   `last_released` `/^v\d+\.\d+\.\d+$/`), `wf_step_config` (per-step boolean flags),
   `sandbox` (boolean switches, string deny-list, `planning-write-guard` enum).
3. **Everything else** is pass-through: read by helpers, not checked here.
