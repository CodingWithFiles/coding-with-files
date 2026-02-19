# Re-Execution Guidance

When a user asks you to re-run an exec skill on a phase that has already been
executed (e.g. after fixing a bug found during testing, or after the plan was
revised), follow this guidance.

## Detection

This is a re-execution (Pass 2+) if either of the following is true:

- The exec file (`f-implementation-exec.md` or `g-testing-exec.md`) has non-template
  content in its Actual Results section (i.e. not `*To be filled upon completion*`)
- The exec file Status is not "Backlog"

If neither is true, this is a first execution (Pass 1) — proceed normally.

## Core Rule: Work Forward, Never Backward

**Do NOT**:
- `git reset` or `git revert` prior checkpoint commits
- Amend prior checkpoint commits
- Rewrite the exec file from scratch, erasing prior pass results

**Do**:
- Pick up from the current state of the codebase and exec file
- Treat prior results as an audit trail — leave them intact

## Commit Naming

Prefix all commits for this pass with `Task {N}: Pass {P}:`:

```
Task 76: Pass 2: Fix edge case in re-execution detection
```

Where `{P}` is the current pass number (2, 3, …). The checkpoint commit at the
end of the phase follows the same naming:

```
Task 76: Pass 2: Complete implementation execution
```

## Doc Handling

Append a new section to the exec file rather than overwriting it:

```markdown
## Pass 2 Results

### Step 1: …
- **Planned**: …
- **Actual**: …
```

Update the Status field and Next Action at the bottom of the file to reflect
the current pass outcome.

## What Is NOT a Blocker

Old exec file results from a prior pass are **never a blocker** by themselves.
The only true blockers are:

- The plan file (`d-implementation-plan.md` / `e-testing-plan.md`) is missing
  or corrupt
- The plan has changed so fundamentally that prior results describe a completely
  different implementation (in which case, document the incompatibility and
  proceed with Pass 2 from Step 1)

Do not stall or return to planning solely because the exec file has prior content.
