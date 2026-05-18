# Versioning Standard

CwF projects use [Semantic Versioning](https://semver.org/) of the form
`v{major}.{minor}.{patch}`. The standard ships with a deterministic helper
script triplet that runs in the retrospective phase of each task, gated by
per-project configuration in `cwf-project.json`.

## Ownership

| Field | Owner | Where |
|-------|-------|-------|
| `major.minor` | **Human** | `cwf-project.json` → `versioning.major_minor` |
| `patch`       | **Helper script** | derived from the task number passed to the script |
| `last_released` | **Helper script** | `cwf-project.json` → `versioning.last_released` |

Humans bump `major_minor` deliberately (breaking changes → major; new
user-visible features → minor). Scripts only ever write `last_released`;
they never modify `major_minor`.

## Configuration

`implementation-guide/cwf-project.json`:

```json
{
  "versioning": {
    "major_minor": "v1.0",
    "last_released": "v1.0.113"
  },
  "wf_step_config": {
    "retrospective": {
      "bump_version": true,
      "tag_version":  false
    }
  }
}
```

| Field | Required | Default | Effect |
|-------|----------|---------|--------|
| `versioning.major_minor` | yes (if any version action runs) | none — error | Base for `next`/`bump`/`tag` computation |
| `versioning.last_released` | no | absent | Last version written by `cwf-version-bump` |
| `wf_step_config.retrospective.bump_version` | no | `true` | Whether `cwf-version-bump` writes `last_released` |
| `wf_step_config.retrospective.tag_version` | no | `false` | Whether `cwf-version-tag` creates a git tag |

`major_minor` must match `/^v\d+\.\d+$/`. `last_released` must match
`/^v\d+\.\d+\.\d+$/`. The schema validator
(`.cwf/lib/CWF/Validate/Config.pm`) enforces both — `cwf-manage validate`
catches malformed entries.

## Helper Scripts

All three live under `.cwf/scripts/command-helpers/`. Each takes
`--task-num=N` as a required positive integer; the retrospective skill
passes the current task number explicitly so the result is unambiguous.

| Script | Purpose | Honours flag | Side-effects |
|--------|---------|--------------|--------------|
| `cwf-version-next` | Print `{major_minor}.{N}` | none | None — read-only |
| `cwf-version-bump` | Write `last_released` | `bump_version` | Atomic update of `cwf-project.json` |
| `cwf-version-tag`  | Create annotated git tag | `tag_version` | `git tag -a` on the main branch only; refuses on existing tag |

Output contracts and exit codes are documented in
`implementation-guide/114-feature-add-retrospective-version-bump-and-tag-settings-w/c-design-plan.md`
under "Interface Design".

## Retrospective Phase Sequence

The `cwf-retrospective` skill invokes the helpers in this order:

1. Write `j-retrospective.md`
2. **`cwf-version-bump --task-num={current_task_num}`** — mutates `cwf-project.json` (or no-op if disabled / idempotent)
3. Stage both `j-retrospective.md` and `cwf-project.json`; checkpoint commit
4. Squash the task's checkpoint commits into the final commit on the checkpoints branch
5. **`cwf-version-tag --task-num={current_task_num} --message="Task {N}"`** — tags the squashed commit (or no-op if disabled)
6. Suggest the merge to the parent (parent task branch for subtasks; trunk for top-level tasks) — human action

`bump` runs **before** the squash so the `last_released` change is part of
the final commit. `tag` runs **after** the squash so the tag points at the
final commit, not a transient pre-squash one.

## JSON Formatting

`cwf-version-bump` writes `cwf-project.json` via canonical pretty-print
(`JSON::PP->new->pretty->indent_length(2)->canonical`). The first bump on
a project may produce a one-time formatting diff alongside the value
change; subsequent bumps produce value-only diffs.

## Idempotency

`cwf-version-bump` compares the would-be next version with `last_released`.
If they match, the script reports `already at v{X}` and exits 0 without
writing. Re-running the retrospective for the same task is safe.

If a human edits `major_minor` between two retrospective runs for the same
task, the second bump will write a fresh `last_released` under the new
`major_minor`. This is by design — humans changing `major_minor` is a
deliberate semver event.

## Why Tag Defaults to False

CwF itself sets `tag_version: false` because tagging, pushing tags, and
creating GitHub releases are CwF-internal human-only actions (see
`CLAUDE.md`). External CwF adopters should set `tag_version: true` (and
make sure `cwf-version-tag` runs on their main branch) if they want
automatic tagging at retrospective time.

## See Also

- `.cwf/lib/CWF/Versioning.pm` — module API
- `.cwf/lib/CWF/Common.pm` — `parse_semver`, `version_cmp` utilities
- `.cwf/lib/CWF/Validate/Config.pm` — schema validation rules
- `.claude/skills/cwf-retrospective/SKILL.md` — workflow integration
