# Reconcile cwf-project.json with validator schema - Implementation Plan
**Task**: 196 (chore)

## Task Reference
- **Task ID**: internal-196
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/196-reconcile-cwf-project-json-with-validator-schema
- **Template Version**: 2.1

## Goal
Rewrite the shipped `cwf-project.json` template (and the `cwf-init` prose that describes it) to the documented schema shape — required + sandbox blocks retained, vestigial keys removed, pass-through key names aligned to `CWF-PROJECT-SPEC.md` and the dog-fooded live config.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Verified Pre-conditions (from planning sweep)
- **Neither artefact is hash-tracked**: `.cwf/templates/cwf-project.json.template` and `.claude/skills/cwf-init/SKILL.md` are absent from `.cwf/security/script-hashes.json` (file-integrity globs cover `.claude/commands/cwf-*.md` and `.cwf/scripts/command-helpers/cwf-*` only). **No sha256 refresh in this task.**
- **Every removed key is dead**: symbol-deletion sweep over `.cwf/lib`, `.cwf/scripts`, `.claude/skills` found zero readers of `cwf-version` (the config key — the `cwf-version-*` *scripts* are unrelated), `_cwf-version-note`, `title`, `team`, `task-management`, `project`, `task-reference-format`, `branch-name-max-length`, `auto-generate-branch-suggestions`.
- **Minimal config is runtime-safe**: omitted pass-through keys have code-side defaults or no readers — `workflow.status-values` falls back to `CWF::TaskState::%DEFAULT_STATUS_MAP` (TaskState.pm:276-277); `directory-structure`/`integration` have zero readers; the `task-tracking` config key has zero readers (all `task-tracking` grep hits are the Task-32 slug string). The current template already omits these and fresh installs work.

## Files to Modify
### Primary Changes
- `.cwf/templates/cwf-project.json.template` — full rewrite to the target shape below.
- `.claude/skills/cwf-init/SKILL.md` — step 2 prose: "task management (github)" → "task tracking"; phrase project-name/branch wording to match the produced keys.

### Supporting Changes
- `t/cwf-project-template.t` — extend the existing guard test with validator-conformance and vestigial-key assertions (see Test Coverage).

## Target Template (after)
```json
{
  "project-name": "Example Project",
  "description": "Project configuration template for the CWF system",
  "source-management": {
    "branch-naming-convention": "{task-type}/{task-id}-{description-slug}"
  },
  "supported-task-types": ["feature", "bugfix", "hotfix", "chore", "discovery"],
  "task-tracking": {
    "system": "github-issues",
    "base-url": "https://github.com/OWNER/REPO/issues",
    "id-format": "issues-{{number}}",
    "fallback": {
      "description": "For tasks without GitHub issues yet",
      "id-format": "internal-{{number}}",
      "migration-notes": "Replace internal-N with issues-N when GitHub issue created"
    }
  },
  "_sandbox-note": "CWF-managed Claude Code sandboxing — off by default. See .cwf/docs/sandboxing.md before enabling.",
  "sandbox": {
    "enabled": false,
    "fail-if-unavailable": true,
    "credential-deny-list": ["~/.ssh", "~/.aws"],
    "violation-logging": false,
    "planning-write-guard": "off"
  }
}
```

### Reviewer call-outs (changes from current template, flagged for plan review)
- **Removed** (all dead): `cwf-version`, `_cwf-version-note`, `title`, `team`, the options-style `templates` block, and `project`→`project-name` / `task-management`→`task-tracking` renames.
- **Fixed placeholder**: `branch-naming-convention` `{task-description}` → `{description-slug}` (matches spec example and live config).
- **`source-management` pruned to `branch-naming-convention` only** — dropped undocumented `type`/`url` to match the dog-fooded shape (only the required sub-key is documented).
- **`task-tracking` block mirrors the live config verbatim**, swapping only the repo for an `OWNER/REPO` placeholder — no third literal variant authored (per plan-review improvements finding).
- **Key-inclusion rule** (resolves the "why keep some pass-through keys and not others" question): a key earns a place in the template only if it is **either** validator-relevant (required/optional-validated) **or** human-edited config a fresh user would reasonably fill in (`task-tracking`). Zero-reader keys that are neither — `directory-structure`, `integration`, `workflow` — stay omitted. An annotation (`_…`) key survives only when it annotates a *live, security-relevant* block.
- **`_sandbox-note` kept under that rule** — it annotates the live `sandbox` block and points a fresh user to a real doc before enabling a security-sensitive feature; `_cwf-version-note` is removed because it annotated a dead field. The security reviewer flagged retention as mildly positive. (Still open to dropping for strict live-config parity if the user prefers at review.)
- **Optional `versioning`/`wf_step_config` omitted** — per plan-time decision (CWF-dev-specific; consumers opt in).

## Implementation Steps
### Step 1: Rewrite the template
- [ ] Replace `.cwf/templates/cwf-project.json.template` contents with the Target Template above. (JSON validity is asserted by TC-1 / Step 3.)

### Step 2: Sync the init prose
- [ ] Edit `.claude/skills/cwf-init/SKILL.md` step 2: change "Set default task management (github) and branch conventions" to reference task **tracking** and the `branch-naming-convention`; keep "Use project name from git remote or directory name" (now feeding `project-name`).

### Step 3: Extend the guard test
- [ ] Add `use lib "$FindBin::Bin/../.cwf/lib"; use CWF::Validate::Config qw(validate_config_hash);` to `t/cwf-project-template.t`.
- [ ] New assertion: decoded template → `validate_config_hash` returns **0** violations.
- [ ] New assertion: vestigial keys absent — `cwf-version`, `_cwf-version-note`, `title`, `team`, `task-management`, `project` (TC-2's `version` check stays).
- [ ] New assertion: documented names present — `project-name`, `task-tracking`; and `source-management.branch-naming-convention` contains `{description-slug}`.
- [ ] **Rewrite the stale TC-2 comment (lines 30-31).** Task 188 left a comment stating `cwf-version` is "intentionally retained and deliberately NOT asserted." Task 196 removes `cwf-version` *from the template* (spec-alignment) and now asserts its absence, so that comment must be updated to record the reversal — and to note that the *live config's* `cwf-version`/`security.version-tracking` retirement is a separate, out-of-scope Low backlog item. Do not leave a comment that contradicts the new assertion.

### Step 4: Validate
- [ ] `prove t/cwf-project-template.t` green.
- [ ] `prove t/validate-config.t` green (unchanged — no validator edit).
- [ ] Full `prove t/` green (no regressions).

## Code Changes
### Before (template, abridged)
```json
{ "title": "...", "cwf-version": "v0.2.1", "_cwf-version-note": "...",
  "project": { "name": "...", "description": "..." },
  "source-management": { "type": "github", "url": "...", "branch-naming-convention": "{task-type}/{task-id}-{task-description}" },
  "task-management": { "type": "github", "url": "...", "task-id-template": "...", "examples": {...} },
  "supported-task-types": [...], "team": {...},
  "_sandbox-note": "...", "sandbox": {...},
  "templates": { "task-reference-format": "standard", "branch-name-max-length": 50, "auto-generate-branch-suggestions": true } }
```
### After
See **Target Template** above.

## Test Coverage
**See e-testing-plan.md for complete test plan.** Summary: extend `t/cwf-project-template.t` (validator-conformance + vestigial-key + documented-name assertions); regression-guard via full `prove t/`.

## Validation Criteria
**See e-testing-plan.md.** Done when: template validates clean through `CWF::Validate::Config`, carries no vestigial keys, uses documented pass-through names, init prose matches, and the suite is green.

**Caveat (per plan-review robustness finding)**: the `validate_config_hash`-returns-zero check is a *weak* signal on its own — the validator inspects only the two required keys + the optional `versioning`/`wf_step_config`/`sandbox` blocks and ignores unknown keys, so almost any object with the two required keys passes. The real guard against vestigial keys and wrong pass-through names is the *explicit* key-presence/absence assertions in Step 3, not the validator pass. Both are required.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Every planned step executed without deviation (see `f-implementation-exec.md`). The pre-deletion reference sweep confirmed no first-run code path read the vestigial keys, and surfaced the inert `.cwf/utils/*.md` stale docs as a logged follow-up candidate. Neither edited artefact is hash-tracked, so no sha256 refresh applied — as predicted at plan time.

## Lessons Learned
A symbol-deletion reference sweep is the right safety check for any vestigial-removal chore, and its by-product (finding adjacent stale references) is as valuable as the primary check. See `j-retrospective.md`.
