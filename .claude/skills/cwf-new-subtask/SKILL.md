---
name: cwf-new-subtask
description: Create sub-implementation task within existing task (v2.0)
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Bash
---

## Scope & Boundaries

**This step**: Create a subtask within an existing parent task.
**Not this step**: Planning, design, or implementation of the subtask.

## Context

**Task arguments**: {arguments}

**First**: Run `.cwf/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

**Mandatory context** (run these before proceeding):
- Run `.cwf/scripts/command-helpers/context-manager hierarchy <parent-path>` using the Bash tool to resolve parent task directory and verify it exists.
- Run `.cwf/scripts/command-helpers/context-manager inheritance <parent-path>` using the Bash tool to load parent context (structural map for scope constraints).

## Workflow

**Parse arguments**: `<parent-path> <num> [<type>] "description"`
- parent-path: Parent task number (e.g., "1", "1.1")
- num: Subtask number (e.g., "1.1", "1.1.1")
- type: feature|bugfix|hotfix|chore|discovery (optional — see Type Inference)
- description: Brief subtask description

**Disambiguation rule**: if the token between `<num>` and the quoted
description matches a value in `cwf-project.json:supported-task-types`,
treat it as `<type>` and proceed with the existing 4-arg flow (no
inference). Otherwise `<type>` is treated as omitted and Type Inference
runs. To use a bare type-name word as the description, provide `<type>`
explicitly.

**Examples**:
- `/cwf-new-subtask 1 1.1 chore "Setup database schema"` (explicit type)
- `/cwf-new-subtask 1 1.2 "Refactor auth helpers"` (type inferred)

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

### 1. Resolve Parent Directory
- Use `context-manager hierarchy <parent-path>` output to find parent
- Verify parent exists, extract metadata

### 2. Load Parent Context
- Use `context-manager inheritance <parent-path>` output for structural map
- Review parent goals, requirements, design to inform subtask

### 3. Validate and Create Subtask
- Verify `num` follows hierarchical pattern from parent
- Check subtask doesn't already exist
- Slug: pass `--description` raw to the script (same handling as `/cwf-new-task` — script slugifies and rejects descriptions whose slug exceeds 50 chars with `[CWF] ERROR:`)
- Subtask directory is nested inside parent (e.g. task 48.1 → `implementation-guide/48-feature-parent/48.1-bugfix-slug/`)
- Verify you are on the intended base branch before running — the recorded
  **Baseline Commit** is resolved by `task-workflow create` to whatever `HEAD`
  is at invocation time. To pin a specific non-HEAD baseline, pass
  `--baseline-commit=<40-char-sha>` explicitly; otherwise omit the flag.
- Copy templates via `task-workflow create` with `--destination` pointing inside parent dir
- Set `{{parentTask}}` to parent task number

### 4. Provision the Scratch Directory
Create this subtask's scratch leaf. It reuses the **same per-project parent**
as every other task in this repo, with its own `task-<subnum>/` leaf. Use the
canonical derivation snippet in `.cwf/docs/conventions/tmp-paths.md` (do not
hand-roll a `${repo_root//\//-}` one-liner — it drops worktree-safety). With
`num` set to this subtask's full decimal `<num>` (e.g. `48.1`):

```bash
base="${TMPDIR:-/tmp}"; base="${base%/}"
repo_root=$(cd "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")" && pwd)
scratch="${base}/cwf${repo_root//\//-}/task-${num}"
mkdir -m 0700 -p "$scratch" && echo "scratch: $scratch" || echo "WARNING: could not create $scratch (will be created on first use)"
```

There is **no `git checkout -b`** in this skill — the subtask stays on the
parent branch — so provisioning follows subtask creation directly.
**Non-fatal**: a failed `mkdir` must NOT block subtask creation; do not print
the path as if it exists on failure.

### 5. Provide Next Steps
- Subtask directory, parent link, structural map shown
- Scratch dir provisioned (or noted as deferred to first use) — surface the path
- Next action: `/cwf-task-plan <num>`

## Success Criteria
- [ ] Parent task resolved and context loaded
- [ ] Arguments parsed and validated
- [ ] Subtask directory created with template files
- [ ] Scratch dir provisioned (non-fatal) and path surfaced
- [ ] Next steps suggested
