# Fix template-copier undef warnings for unresolved variables - Design
**Task**: 63 (bugfix)

## Task Reference
- **Task ID**: internal-63
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/63-fix-template-copier-undef-warnings
- **Template Version**: 2.1

## Goal
Design the fix for undef warnings in template-copier-v2.1's variable computation and substitution. Also add a sparse-checkout bootstrap sequence to README/INSTALL.md so agents can install CWF from just a git URL.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### D1: Guard with Defined-Or, Not Suppression
- **Decision**: Use `// ''` (defined-or empty string) for all potentially undef values rather than `no warnings 'uninitialized'` or `eval` blocks.
- **Rationale**: `// ''` is idiomatic Perl, makes intent explicit, and leaves blank fields visible in templates (user can fill them in during task plan). Warning suppression would mask legitimate bugs.
- **Trade-offs**: Blank fields instead of placeholder text like `{{branchName}}`. Acceptable — blank is visible and the task plan step is designed to fill in metadata.

### D2: Guard at Point of Use, Not Point of Computation
- **Decision**: Guard undef in two locations:
  1. `compute_variables()` line 352: `$pattern // ''` when reading config
  2. `substitute_variables()` line 384: `$value // ''` in the substitution loop
- **Rationale**: Guarding at point of use is defensive — even if a new variable is added later and is undef, the substitution won't warn. Guarding only at computation would require updating every new variable.
- **Trade-offs**: Two small changes vs one. Both are trivial.

### D3: No Branch Pre-Creation
- **Decision**: Do NOT change `/cwf-new-task` to create the branch before template copy. The branch name is computed from config pattern — it doesn't need the branch to exist.
- **Rationale**: The BACKLOG entry suggested this as an option, but the real problem is that `$pattern` is undef when config is missing, not that the branch doesn't exist. The branch name is computed, not read from git.
- **Trade-offs**: None — this is a non-change.

### D4: Sparse-Checkout Bootstrap for Agent Install
- **Decision**: Add a bootstrap sequence to README.md and INSTALL.md that uses sparse checkout to fetch only `scripts/` before running the install script. This solves the chicken-and-egg problem: agents can't read INSTALL.md without cloning first, and the full repo is 5M+ (growing).
- **Bootstrap sequence**:
  ```bash
  git clone --depth 1 --filter=blob:none --sparse <url> /tmp/cwf-bootstrap
  git -C /tmp/cwf-bootstrap sparse-checkout set scripts
  CWF_SOURCE=<url> bash /tmp/cwf-bootstrap/scripts/install.bash
  rm -rf /tmp/cwf-bootstrap
  ```
- **Rationale**: Sparse checkout with `--filter=blob:none` fetches only the `scripts/` directory, avoiding the full 5M+ repo download. The install script then does its own full clone internally for the subtree splits. The README is the discovery point — every git forge renders it, and it's the first thing an agent or human sees.
- **Trade-offs**: Four commands vs the single `curl | bash` line. Acceptable — this works with any git host (not just GitHub), and agents can handle multi-line commands. The `curl | bash` path remains for GitHub users who want a one-liner.

## Affected Code

Two locations in `.cwf/scripts/command-helpers/template-copier-v2.1`:

1. **`compute_variables()`** (line 352): `$pattern` from config can be undef
2. **`substitute_variables()`** (line 384): `$value` from vars hash can be undef

## Constraints
- Must not change template-copier-v2.0 (only v2.1 affected)
- Core Perl only
- Security hash update required after modification

## Decomposition Check
- [x] **Time**: No
- [x] **People**: No
- [x] **Complexity**: No
- [x] **Risk**: No
- [x] **Independence**: No

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 63
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Design followed as planned. D4 (sparse-checkout bootstrap) was added mid-session after external agent install testing revealed the chicken-and-egg problem.

## Lessons Learned
Design should be stable before the testing plan is written. Expanding design mid-session required cascading updates to implementation and testing plans.
