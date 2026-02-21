# fix install script latest tag resolution and local dev UX - Implementation Plan
**Task**: 80 (bugfix)

## Task Reference
- **Task ID**: internal-80
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/80-fix-install-latest-and-env-handling
- **Template Version**: 2.1

## Goal
Fix `scripts/install.bash` so `file://` sources default to `HEAD`, and document
the local dev install path in `INSTALL.md`.

## Files to Modify
### Primary Changes
- `scripts/install.bash` — add `file://` detection in `resolve_ref()` and log message
- `INSTALL.md` — add "Installing from a local clone" section

## Implementation Steps

### Step 1: Fix `scripts/install.bash`

In `resolve_ref()` (line 85), before the `latest` branch, add a `file://` detection
block that overrides `CWF_REF` to `HEAD` when the source is a local path:

#### Before (lines 85-98):
```bash
resolve_ref() {
    local clone_dir="$1"
    local ref="$2"

    if [[ "$ref" == "latest" ]]; then
        local latest
        latest="$(git -C "$clone_dir" tag -l 'v*' --sort=-version:refname | head -1)"
        if [[ -z "$latest" ]]; then
            die "No version tags found in source repo. Use CWF_REF=main (or a branch name) instead."
        fi
        log "Resolved 'latest' to $latest"
        echo "$latest"
        return
    fi
```

#### After:
```bash
resolve_ref() {
    local clone_dir="$1"
    local ref="$2"

    if [[ "$ref" == "latest" && "$CWF_SOURCE" == file://* ]]; then
        log "file:// source detected — defaulting CWF_REF to HEAD"
        echo "HEAD"
        return
    fi

    if [[ "$ref" == "latest" ]]; then
        local latest
        latest="$(git -C "$clone_dir" tag -l 'v*' --sort=-version:refname | head -1)"
        if [[ -z "$latest" ]]; then
            die "No version tags found in source repo. Use CWF_REF=main (or a branch name) instead."
        fi
        log "Resolved 'latest' to $latest"
        echo "$latest"
        return
    fi
```

Note: `$CWF_SOURCE` is set as `readonly` at the top of the script (line 24), so it is
available in `resolve_ref()` without needing to be passed as an argument.

### Step 2: Update `INSTALL.md`

After the env vars reference table (after line 42), add a "Installing from a local clone"
subsection:

```markdown
### Installing from a local clone

If you have a local clone of the CWF repository (e.g. for development or air-gapped
environments), use a `file://` URL as the source:

```bash
git archive --remote=file:///path/to/coding-with-files HEAD scripts/install.bash \
  | tar -xO > /tmp/cwf-install.bash
CWF_SOURCE=file:///path/to/coding-with-files bash /tmp/cwf-install.bash
```

When `CWF_SOURCE` is a `file://` URL, `CWF_REF` defaults to `HEAD` rather than
the latest release tag. This ensures you install the current state of the repository
rather than a potentially outdated tagged release. To install a specific tag from a
local clone, set `CWF_REF` explicitly:

```bash
CWF_SOURCE=file:///path/to/coding-with-files CWF_REF=v0.2.1 bash /tmp/cwf-install.bash
```
```

### Step 3: Verify

```bash
# Should output "file:// source detected — defaulting CWF_REF to HEAD" and succeed
git archive --remote=file:///home/matt/repo/coding-with-files HEAD scripts/install.bash \
  | tar -xO > /tmp/cwf-install.bash
cd /tmp/cwf-test-repo && git init && git commit --allow-empty -m "init"
CWF_SOURCE=file:///home/matt/repo/coding-with-files bash /tmp/cwf-install.bash

# Remote source should still use latest tag (no regression)
# (tested manually by inspection — not run since no network access needed for plan)
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
Both changes are small and must ship together — the script fix is the bugfix,
the docs update explains the new behaviour.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 80
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Both changes applied exactly as planned. The file:// guard is a 4-line addition
to resolve_ref(). INSTALL.md section is 16 lines. No deviations.

## Lessons Learned
Having the exact before/after code diff in the implementation plan made execution
a direct copy-paste operation with zero ambiguity.
