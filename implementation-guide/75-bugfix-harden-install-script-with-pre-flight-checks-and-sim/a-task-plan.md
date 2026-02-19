# Harden Install Script with Pre-Flight Checks and Simplify Bootstrap - Plan
**Task**: 75 (bugfix)

## Task Reference
- **Task ID**: internal-75
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/75-harden-install-script-preflight-checks
- **Template Version**: 2.1

## Goal
Add an initial-commit pre-flight check to `install.bash` and replace the 4-line
sparse-checkout bootstrap in README.md and INSTALL.md with cleaner one-liners.

## Root Cause / Background

Two issues identified during Task 63 external agent install testing:

1. **Missing initial-commit check**: `install_subtree()` calls `git subtree add`
   which requires at least one commit in the target repo. A freshly `git init`'d
   repo with no commits produces the cryptic error "working tree has modifications.
   Cannot add." The fix is a check in `check_prerequisites()` that detects zero
   commits and exits with a clear message.

2. **Verbose sparse-checkout bootstrap**: README.md and INSTALL.md use a 4-line
   sparse-checkout sequence to fetch the install script. This can be replaced with
   a single `git archive --remote=<url> <ref> -- scripts/install.bash | tar -xO | bash`
   one-liner that works for GitLab, Gitea, Forgejo, and self-hosted hosts. GitHub
   already has the `curl` one-liner. Result: two clean one-liners, one per host class.

## Success Criteria
- [ ] `install.bash` exits with a clear human-readable error when target repo has no commits
- [ ] Error message is emitted before any git operations are attempted
- [ ] README.md: 4-line sparse-checkout block replaced with `git archive` one-liner
- [ ] INSTALL.md: same replacement, with appropriate annotation about host support
- [ ] GitHub `curl` one-liner unchanged and still documented
- [ ] `cwf-manage validate` passes (install.bash is hash-tracked)

## Original Estimate
**Effort**: Trivial (<1 session)
**Complexity**: Low — one guard clause, two doc edits
**Dependencies**: None

## Major Milestones
1. **Pre-flight fix**: Add `git log` commit count check to `check_prerequisites()`
2. **Docs update**: Replace sparse-checkout block in README.md and INSTALL.md
3. **Hash update + validate**: Update SHA256 for `install.bash`

## Risk Assessment

### Low Priority Risks
- **`install.bash` is hash-tracked**: Must update `.cwf/security/script-hashes.json`
  after editing.
  - **Mitigation**: Run `sha256sum` and update JSON immediately after code edit.
- **`git archive --remote` GitHub limitation**: GitHub doesn't support this command.
  Must ensure docs clearly distinguish GitHub (curl) from other hosts (git archive).
  - **Mitigation**: Label each one-liner with its supported host class.

## Dependencies
- None

## Constraints
- `install.bash` is hash-tracked — must update `.cwf/security/script-hashes.json`

## Decomposition Check
- [ ] **Time**: No — trivial
- [ ] **People**: No
- [ ] **Complexity**: No — one guard clause, two doc files
- [ ] **Risk**: No
- [ ] **Independence**: No

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 75
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All three milestones delivered as planned. Guard clause added to `check_prerequisites()`,
bootstrap docs simplified to two one-liners. Security hash step was N/A (`install.bash`
not tracked). All success criteria met; 6/6 tests pass.

## Lessons Learned
Verify whether a file is hash-tracked before writing a hash-update step into the plan.
`install.bash` lives in `scripts/` and is intentionally outside the `.cwf/` hash registry.
