# Harden Install Script with Pre-Flight Checks and Simplify Bootstrap - Implementation Plan
**Task**: 75 (bugfix)

## Task Reference
- **Task ID**: internal-75
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/75-harden-install-script-preflight-checks
- **Template Version**: 2.1

## Goal
Three targeted edits: guard clause in `install.bash`, bootstrap update in `README.md`,
bootstrap update in `INSTALL.md`. Plus security hash update for `install.bash`.

## Files to Modify
- `scripts/install.bash` — add initial-commit guard to `check_prerequisites()`
- `README.md` — replace 4-line sparse-checkout block with `git archive` one-liner
- `INSTALL.md` — same replacement + relabel section heading
- `.cwf/security/script-hashes.json` — update SHA256 for `install.bash`

## Implementation Steps

### Step 1: Add initial-commit guard to `install.bash`
- [ ] Insert after the "Must be at git root" block (after line 62), before the
  "Check for existing install" block (line 64):
  ```bash
  # Subtree method requires at least one commit
  if [[ "$CWF_METHOD" == "subtree" ]]; then
      if ! git rev-parse HEAD >/dev/null 2>&1; then
          die "Repository has no commits. Create an initial commit before installing CWF (subtree method requires at least one commit)."
      fi
  fi
  ```

### Step 2: Update README.md bootstrap block
- [ ] Replace the `### Quick Install (Any Git Host)` section (lines 54-65):

  **Before**:
  ```
  ### Quick Install (Any Git Host)

  ```bash
  git clone --depth 1 --filter=blob:none --sparse <cwf-repo-url> /tmp/cwf-bootstrap
  git -C /tmp/cwf-bootstrap sparse-checkout set scripts
  CWF_SOURCE=<cwf-repo-url> bash /tmp/cwf-bootstrap/scripts/install.bash
  rm -rf /tmp/cwf-bootstrap
  ```

  This fetches only the install script (~few KB) via sparse checkout, then runs it. Works with any git host (GitHub, GitLab, Gitea, etc.).
  ```

  **After**:
  ```
  ### Quick Install

  **GitHub**:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/mattkeenan/coding-with-files/main/scripts/install.bash | bash
  ```

  **GitLab, Gitea, Forgejo, self-hosted**:
  ```bash
  git archive --remote=<cwf-repo-url> HEAD scripts/install.bash | tar -xO | bash
  ```
  ```

### Step 3: Update INSTALL.md bootstrap block
- [ ] Replace the `### Any Git Host (Sparse Checkout)` section (lines 9-18) with a
  two-block layout matching README, and relabel the `### GitHub (curl one-liner)`
  section to `### GitHub`:

  **Before** (lines 9-24):
  ```
  ### Any Git Host (Sparse Checkout)

  Works with any git host — GitHub, GitLab, Gitea, self-hosted, etc. Fetches only the install script (~few KB) rather than the full repository.

  ```bash
  git clone --depth 1 --filter=blob:none --sparse <cwf-repo-url> /tmp/cwf-bootstrap
  git -C /tmp/cwf-bootstrap sparse-checkout set scripts
  CWF_SOURCE=<cwf-repo-url> bash /tmp/cwf-bootstrap/scripts/install.bash
  rm -rf /tmp/cwf-bootstrap
  ```

  ### GitHub (curl one-liner)

  ```bash
  curl -fsSL https://raw.githubusercontent.com/mattkeenan/coding-with-files/main/scripts/install.bash | bash
  ```
  ```

  **After**:
  ```
  ### GitHub

  ```bash
  curl -fsSL https://raw.githubusercontent.com/mattkeenan/coding-with-files/main/scripts/install.bash | bash
  ```

  ### GitLab, Gitea, Forgejo, self-hosted

  ```bash
  git archive --remote=<cwf-repo-url> HEAD scripts/install.bash | tar -xO | bash
  ```
  ```

### Step 4: Update security hash
- [ ] Run `sha256sum scripts/install.bash`
- [ ] Update `install.bash` entry in `.cwf/security/script-hashes.json`
- [ ] Run `.cwf/scripts/cwf-manage validate` — must pass clean

## Validation Criteria
- `install.bash` exits with clear error on repo with no commits (subtree method)
- `install.bash` proceeds normally when repo has commits (subtree method)
- `install.bash` proceeds normally with no commits when `CWF_METHOD=copy`
- README.md and INSTALL.md show clean one-liner blocks
- `cwf-manage validate` passes

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 75
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Steps 1-3 executed as planned. Step 4 (hash update) was N/A — `install.bash` is not
tracked in `script-hashes.json`. Plan should have verified tracking status upfront.

## Lessons Learned
When planning hash update steps, grep `script-hashes.json` first to confirm the file
is actually tracked before adding the step.
