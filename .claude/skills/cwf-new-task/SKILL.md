---
name: cwf-new-task
description: Create categorised implementation guide (v2.0 - hierarchical)
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Bash
---

## Scope & Boundaries

**This step**: Create a new task directory with template files and git branch.
**Not this step**: Planning, design, or implementation — those are separate workflow phases.

## Context

**Task arguments**: {arguments}

**First**: Run `.cwf/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

## Workflow

**Parse arguments**: `<num> [<type>] "description"`
- num: Task number in decimal notation (1, 1.1, 1.1.1, etc.)
- type: feature|bugfix|hotfix|chore|discovery (optional — see Type Inference)
- description: Brief task description (will be slugified)

**Disambiguation rule**: if a token between `<num>` and the quoted
description matches a value in `cwf-project.json:supported-task-types`,
treat it as `<type>` and proceed with the existing 3-arg flow (no
inference). Otherwise `<type>` is treated as omitted and Type Inference
runs. To use a bare type-name word as the description, provide `<type>`
explicitly.

**Examples**:
- `/cwf-new-task 1 feature "Add user authentication"` (explicit type)
- `/cwf-new-task 1.1 chore "Setup database schema"` (explicit type)
- `/cwf-new-task 2 "Migrate Bash helpers to Perl"` (type inferred)

### Type Inference (only when `<type>` is omitted)

When `<type>` is not supplied, infer it before validation:

1. Read the rubric at the literal path
   `.cwf/docs/skills/task-type-inference.md` using the Read tool.
2. Apply the rubric's Discriminating Questions to the description to
   produce an inferred step set `S`, always including the
   always-required steps the rubric names.
3. For each candidate type `T` listed in the rubric's Canonical Step
   Sets table, compute the symmetric-difference distance
   `|S Δ C_T|` between `S` and the canonical step set `C_T` of `T`.
4. If exactly one type has distance `0`, use it silently as the
   resolved `<type>` and continue to step 1 of the normal flow.
   Otherwise show the rubric's Ambiguity Prompt Format with the top
   candidates, let the user pick, and use the picked type. Cancel
   (no directory, no branch) on any non-numeric or out-of-range
   response.

If the rubric file is unreadable, or the minimum distance across all
candidate types is `>= 3`, refuse the 2-arg form and tell the user to
rerun with explicit `<type>`. No directory creation, no branch
checkout in either failure path.

### 1. Validate Arguments
- Verify `num` is valid decimal notation (numbers and dots only)
- Verify `type` is in supported-task-types from `cwf-project.json`
  (either supplied explicitly or resolved by Type Inference above)
- Verify `description` is provided

### 2. Generate Slug and Directory Path
- Slug: pass `--description` raw to the script; the script slugifies (lowercase, spaces to hyphens, remove special chars) and rejects overlong descriptions (>50 chars) with `[CWF] ERROR:`. Do not pre-truncate.
- Top-level: `implementation-guide/<num>-<type>-<slug>/`
- Subtask: nested inside parent directory (e.g. task 48.1 → `implementation-guide/48-feature-parent/48.1-bugfix-slug/`)

### 3. Copy Template Files

Verify you are on the intended base branch (typically the trunk) before running — the
recorded **Baseline Commit** is whatever `HEAD` points to at this moment, and the
security-review-changeset helper uses it as the anchor for diffing. Detached HEAD or
branching off another task's branch is allowed but the user owns that decision.

```bash
.cwf/scripts/command-helpers/task-workflow create \
  --task-type="{type}" --destination="{task-dir}" \
  --task-num="{num}" --description="{description}"
```
Creates directory automatically, copies templates, substitutes variables (including
`{{baselineCommit}}` in `a-task-plan.md`, resolved to current HEAD by the helper),
sets permissions. To pin a specific non-HEAD baseline, pass
`--baseline-commit=<40-char-sha>` explicitly.

### 4. Create Git Branch
```bash
git checkout -b "<type>/<num>-<slug>"
```

### 5. Provide Next Steps
- Directory created, files listed, branch checked out
- Next action: `/cwf-task-plan <num>`

## Success Criteria
- [ ] Arguments parsed and validated
- [ ] Task directory created with template files
- [ ] Git branch created and checked out
- [ ] Next steps suggested
