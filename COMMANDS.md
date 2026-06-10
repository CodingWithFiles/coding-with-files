# CWF Command Reference

A reference for the Coding with Files (CWF) commands. Commands prefixed with `/` are
Claude Code skills under `.claude/skills/cwf-*`; `cwf-manage` is a shell script invoked
directly. For a one-line overview see the **Commands** section of `README.md`; for the
config schema see `CWF-PROJECT-SPEC.md`.

Tasks live under `implementation-guide/<num>-<type>-<slug>/`, numbered with decimal
notation for nesting (`1`, `1.1`, `1.1.1`). Each task runs a subset of the ten lettered
workflow phases `a`–`j`, every phase split into a planning step and a separate execution
step where applicable.

## Core Commands

### `/cwf-init`
Initialise CWF in the current project: create `implementation-guide/`, generate
`implementation-guide/cwf-project.json`, and wire up project configuration.

### `/cwf-new-task <num> [<type>] "description"`
Create a new top-level task directory with the template file set for its type, then
create and check out the task branch. `<type>` is one of `feature`, `bugfix`, `hotfix`,
`chore`, `discovery`; when omitted it is inferred from the description.

```
/cwf-new-task 1 feature "Add user authentication"
/cwf-new-task 2 "Migrate Bash helpers to Perl"     # type inferred
```

### `/cwf-new-subtask <parent-path> <num> [<type>] "description"`
Create a nested subtask inside an existing task, inheriting parent context via
structural maps. The subtask directory nests under the parent (e.g. task `1.1` →
`implementation-guide/1-feature-parent/1.1-bugfix-slug/`).

### `/cwf-delete-task <task-path> [--force]`
Delete the most-recently-created task (the reverse of `/cwf-new-task`). Refuses to
delete a task that is not the most recent, has already been merged, or has subtasks.

### `/cwf-status [task-path]`
Show progress across the implementation-guide hierarchy, aggregating per-phase status
into completion percentages. With a path, scopes to that task and its subtasks.

### `/cwf-current-task`
Manage the current-task stack (`.cwf/task-stack`) for context tracking — push, pop,
list, or clear. Stack operations use file locking; do not edit `.cwf/task-stack`
directly.

### `/cwf-extract <task-path> <section-name>`
Extract a named section (e.g. `"Goal"`, `"Success Criteria"`, `"Actual Results"`) from a
task's workflow files without loading the whole document.

## Workflow Phase Commands

Run these in order for a task; each operates on the matching `<letter>-*.md` file. Plan
phases come first, then their execution counterparts.

| Command | Phase file | Purpose |
|---------|-----------|---------|
| `/cwf-task-plan <task-path>` | `a-task-plan.md` | Goals, success criteria, milestones, risks, decomposition |
| `/cwf-requirements-plan <task-path>` | `b-requirements-plan.md` | Functional/non-functional requirements, acceptance criteria |
| `/cwf-design-plan <task-path>` | `c-design-plan.md` | Architecture, components, interfaces |
| `/cwf-implementation-plan <task-path>` | `d-implementation-plan.md` | Files to change, steps, validation criteria |
| `/cwf-implementation-exec <task-path>` | `f-implementation-exec.md` | Write the code; record actual results |
| `/cwf-testing-plan <task-path>` | `e-testing-plan.md` | Test strategy, test cases |
| `/cwf-testing-exec <task-path>` | `g-testing-exec.md` | Run the verifications, record results |
| `/cwf-rollout <task-path>` | `h-rollout.md` | Deployment, monitoring, rollback plan |
| `/cwf-maintenance <task-path>` | `i-maintenance.md` | Ongoing support and optimisation |
| `/cwf-retrospective <task-path>` | `j-retrospective.md` | Variance tracking, lessons learned |

Invoke a phase skill with the task number, e.g. `/cwf-task-plan 1` or
`/cwf-implementation-exec 1.1`.

## Utility Commands

### `/cwf-config [init|list|reset]`
Configure CWF paths and settings.

### `/cwf-security-check [verify|report]`
Verify file integrity and source provenance: compares helper-script SHA256 hashes
against `.cwf/security/script-hashes.json` and the canonical source. `verify` performs a
full check; `report` summarises current status.

### `/cwf-backlog-manager`
Show or manipulate the project backlog and changelog — `list`, `add`, `modify`,
`retire`, `validate`, `normalise` — via `.cwf/scripts/command-helpers/backlog-manager`.
Do not edit `BACKLOG.md` / `CHANGELOG.md` directly; the helper enforces the format.

## Installation Management (`cwf-manage`)

`cwf-manage` is a script, run as `.cwf/scripts/cwf-manage <command>`, that manages the
installed CWF version:

| Command | Purpose |
|---------|---------|
| `status` | Show installed version, method, and source |
| `list-releases [--all]` | List available tagged releases from the CWF remote |
| `update [ref]` | Update to a ref (default: latest tag) |
| `rollback <ref>` | Revert to a previous version |
| `validate` | Validate config and workflow files; non-zero exit on violations |
| `fix-security [--dry-run]` | Restore expected permissions **only when the recorded sha256 still matches**; exits non-zero on tampering. Not a way to clear a warning |
| `help` | Show usage |

## Typical Progression

1. **Set up**: `/cwf-init`
2. **Create a task**: `/cwf-new-task 1 feature "major feature"`
3. **Decompose** (if the decomposition signals fire): `/cwf-new-subtask 1-feature-major-feature 1.1 "first component"`
4. **Work the phases** in order: `/cwf-task-plan 1` → `/cwf-requirements-plan 1` → … → `/cwf-retrospective 1`
5. **Track progress**: `/cwf-status` and `/cwf-extract` as needed
