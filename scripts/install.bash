#!/usr/bin/env bash
#
# CWF Bootstrap Install Script
# Installs Coding with Files (CWF) into the current git repository.
#
# Usage:
#   curl -fsSL <url> | bash                              # defaults
#   curl -fsSL <url> | CWF_METHOD=copy bash              # file copy
#   curl -fsSL <url> | CWF_REF=v2.0.0 bash              # specific version
#   curl -fsSL <url> | CWF_SOURCE=file:///path bash      # custom source
#
# Environment variables:
#   CWF_METHOD   subtree (default) or copy
#   CWF_REF      latest (default), tag, branch, or commit SHA
#   CWF_SOURCE   CWF repo URL (default: GitHub)
#   CWF_FORCE    set to 1 to overwrite existing install
#
set -euo pipefail

# --- Configuration -----------------------------------------------------------

readonly CWF_METHOD="${CWF_METHOD:-subtree}"
readonly CWF_REF="${CWF_REF:-latest}"
readonly CWF_SOURCE="${CWF_SOURCE:-https://github.com/CodingWithFiles/coding-with-files.git}"
readonly CWF_FORCE="${CWF_FORCE:-0}"

# --- Helpers ------------------------------------------------------------------

log() { echo "[CWF] $*" >&2; }
die() { echo "[CWF] ERROR: $*" >&2; exit 1; }

TMPDIR_CWF=""
cleanup() {
    if [[ -n "$TMPDIR_CWF" && -d "$TMPDIR_CWF" ]]; then
        rm -rf "$TMPDIR_CWF"
    fi
}
trap cleanup EXIT

# --- Prerequisite checks ------------------------------------------------------

check_prerequisites() {
    # Must have git
    command -v git >/dev/null 2>&1 || die "git is not installed"

    # Must have bash 4+
    if (( BASH_VERSINFO[0] < 4 )); then
        die "Bash 4+ required (found ${BASH_VERSION})"
    fi

    # Must be inside a git repo
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "[CWF] ERROR: Not inside a git repository" >&2
        exit 2
    fi

    # Must be at git root
    local git_root
    git_root="$(git rev-parse --show-toplevel)"
    if [[ "$PWD" != "$git_root" ]]; then
        die "Must run from git root ($git_root), not $PWD"
    fi

    # Subtree method requires at least one commit in the target repo
    if [[ "$CWF_METHOD" == "subtree" ]]; then
        if ! git rev-parse HEAD >/dev/null 2>&1; then
            die "Repository has no commits. Create an initial commit before installing CWF (subtree method requires at least one commit)."
        fi
    fi

    # Check for existing install
    if [[ -d ".cwf" && "$CWF_FORCE" != "1" ]]; then
        echo "[CWF] ERROR: CWF is already installed (.cwf/ exists). Set CWF_FORCE=1 to overwrite." >&2
        exit 3
    fi

    # Validate method
    if [[ "$CWF_METHOD" != "subtree" && "$CWF_METHOD" != "copy" ]]; then
        die "Invalid CWF_METHOD: $CWF_METHOD (must be 'subtree' or 'copy')"
    fi
}

# --- Ref resolution -----------------------------------------------------------

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

    # Validate the ref exists (check local, then origin remote)
    if git -C "$clone_dir" rev-parse --verify "$ref" >/dev/null 2>&1; then
        echo "$ref"
        return
    fi

    if git -C "$clone_dir" rev-parse --verify "origin/$ref" >/dev/null 2>&1; then
        echo "origin/$ref"
        return
    fi

    die "Invalid ref: $ref — not found in source repo"
}

# --- Symlink creation ---------------------------------------------------------

create_cwf_symlinks() {
    local source_dir="$1"   # e.g. .cwf-skills or .cwf-rules
    local target_dir="$2"   # e.g. .claude/skills or .claude/rules
    local glob="$3"         # e.g. "cwf-*" or "cwf-*.md"
    local test_flag="$4"    # e.g. "-d" or "-f"
    local label="$5"        # e.g. "skill" or "rule"

    mkdir -p "$target_dir"

    # Remove stale CWF symlinks (handles renames across versions)
    for link in "$target_dir"/$glob; do
        [[ -L "$link" ]] && rm "$link"
    done

    # Create relative symlinks
    local count=0
    for item in "$source_dir"/$glob; do
        if test "$test_flag" "$item"; then
            local name target
            name="$(basename "$item")"
            target="$target_dir/$name"
            # Conflict-check (ported from cwf-manage create_agent_symlinks): a
            # regular file at the cwf-* path blocks the install rather than
            # being silently overwritten. cwf-* is CWF's namespace.
            if [[ -e "$target" && ! -L "$target" ]]; then
                die "Regular file $target blocks CWF $label install; remove it or rename your custom $label"
            fi
            ln -s "../../$source_dir/$name" "$target"
            count=$((count + 1))
        fi
    done

    log "Created $count $label symlinks in $target_dir/"
}

# --- Install methods ----------------------------------------------------------

install_subtree() {
    local clone_dir="$1"
    local ref="$2"

    log "Installing via subtree method..."

    # Checkout the resolved ref
    git -C "$clone_dir" checkout --quiet "$ref"

    # Create split branches
    log "Creating subtree splits..."
    git -C "$clone_dir" subtree split --prefix=.cwf -b cwf-core >/dev/null
    git -C "$clone_dir" subtree split --prefix=.claude/skills -b cwf-skills >/dev/null
    git -C "$clone_dir" subtree split --prefix=.claude/rules -b cwf-rules >/dev/null
    git -C "$clone_dir" subtree split --prefix=.claude/agents -b cwf-agents >/dev/null

    # Remove existing if force
    if [[ "$CWF_FORCE" == "1" ]]; then
        # Commit only the dirs actually removed from the index. A hardcoded
        # pathspec naming an absent dir (e.g. .cwf-agents on a pre-agents copy
        # install) makes `git commit` fail wholesale, leaving the other staged
        # deletions in the index and breaking the subtree adds below.
        local -a removed=()
        for dir in .cwf .cwf-skills .cwf-rules .cwf-agents; do
            [[ -d "$dir" ]] || continue
            if git rm -rf --quiet "$dir"; then
                removed+=("$dir")
            elif git ls-files --error-unmatch "$dir" >/dev/null 2>&1; then
                die "git rm failed for tracked $dir"
            fi
            rm -rf "$dir"
        done
        if (( ${#removed[@]} > 0 )); then
            git commit -m "CWF: remove existing install for reinstall" --quiet \
                -- "${removed[@]}" || die "failed to commit removal of existing CWF install"
        fi
    fi

    # Add all subtrees
    log "Adding .cwf/ (subtree split 1/3)..."
    git subtree add --prefix=.cwf "$clone_dir" cwf-core --squash -m "Add CWF core ($ref)"

    log "Adding .cwf-skills/ (subtree split 2/3)..."
    git subtree add --prefix=.cwf-skills "$clone_dir" cwf-skills --squash -m "Add CWF skills ($ref)"

    log "Adding .cwf-rules/ (subtree split 3/4)..."
    git subtree add --prefix=.cwf-rules "$clone_dir" cwf-rules --squash -m "Add CWF rules ($ref)"

    log "Adding .cwf-agents/ (subtree split 4/4)..."
    git subtree add --prefix=.cwf-agents "$clone_dir" cwf-agents --squash -m "Add CWF agents ($ref)"
}

install_copy() {
    local clone_dir="$1"
    local ref="$2"

    log "Installing via copy method..."

    # Checkout the resolved ref
    git -C "$clone_dir" checkout --quiet "$ref"

    # Single source-of-truth list of (source-subpath:dest) copy pairs. The
    # symlink-escape guard and the cp -r loop below iterate this SAME list, so
    # a new copy source cannot be added without also being guarded.
    local pairs=( ".cwf:.cwf" ".claude/skills:.cwf-skills" \
                  ".claude/rules:.cwf-rules" ".claude/agents:.cwf-agents" )
    local p src
    local roots=()
    for p in "${pairs[@]}"; do
        src="$clone_dir/${p%%:*}"
        [[ -d "$src" ]] && roots+=("$src")
    done

    # Refuse out-of-tree symlinks in the source BEFORE any destructive removal
    # or copy (fail-closed; a post-copy check is too late — cp -r copies an
    # escaping symlink verbatim). The guard runs from the target-version clone.
    local guard="$clone_dir/.cwf/scripts/command-helpers/cwf-check-tree-symlinks"
    [[ -x "$guard" ]] || die "symlink-escape guard missing from source tree ($guard); cannot safely copy"
    "$guard" "${roots[@]}" || die "refusing to install: source tree contains an out-of-tree symlink"

    # Remove existing if force
    if [[ "$CWF_FORCE" == "1" ]]; then
        rm -rf .cwf .cwf-skills .cwf-rules .cwf-agents
    fi

    # Copy each present source to its staging dest
    for p in "${pairs[@]}"; do
        src="$clone_dir/${p%%:*}"
        [[ -d "$src" ]] && { cp -r "$src" "${p##*:}"; log "Copied ${p##*:}/"; }
    done

    # Fix permissions
    find .cwf/scripts -type f -exec chmod u+rx {} \;
    log "Fixed script permissions"
}

# --- Post-install setup -------------------------------------------------------

post_install() {
    local ref="$1"
    local resolved_sha="$2"

    # Create skill, rule, and agent symlinks
    create_cwf_symlinks .cwf-skills .claude/skills "cwf-*"    -d skill
    create_cwf_symlinks .cwf-rules  .claude/rules  "cwf-*.md" -f rule
    create_cwf_symlinks .cwf-agents .claude/agents "cwf-*.md" -f agent

    # Merge .claude/settings.json (PERL5OPT + Bash allowlist + Stop hooks).
    # install.bash is otherwise laydown-only; this mirrors cwf-manage's
    # run_settings_merge so a raw `CWF_FORCE=1 bash install.bash` migration —
    # which has no /cwf-init or `cwf-manage update` completion caller — still
    # lands these entries. The `-x` guard tolerates installs predating the
    # helper; a non-zero exit aborts before the version write below (never
    # record a version the install did not fully reach). The helper is
    # idempotent, so a later /cwf-init re-run is a harmless no-op.
    local merge_helper=".cwf/scripts/command-helpers/cwf-claude-settings-merge"
    if [[ -x "$merge_helper" ]]; then
        "$merge_helper" || die "cwf-claude-settings-merge failed; .claude/settings.json may be partially updated"
    fi

    # Write version file
    cat > .cwf/version <<VEOF
cwf_version=$ref
cwf_method=$CWF_METHOD
cwf_ref=$ref
cwf_sha=$resolved_sha
cwf_installed=$(date -u +%Y-%m-%dT%H:%M:%SZ)
cwf_source=$CWF_SOURCE
VEOF
    log "Post-install: wrote .cwf/version"
}

# --- Main ---------------------------------------------------------------------

main() {
    log "CWF Bootstrap Installer"
    log "Method: $CWF_METHOD | Ref: $CWF_REF | Source: $CWF_SOURCE"

    check_prerequisites

    # Clone source to temp dir
    TMPDIR_CWF="$(mktemp -d)"
    log "Cloning CWF source..."
    git clone --quiet "$CWF_SOURCE" "$TMPDIR_CWF/cwf-source"

    # Resolve ref
    local resolved_ref
    resolved_ref="$(resolve_ref "$TMPDIR_CWF/cwf-source" "$CWF_REF")"

    # Get the SHA for the version file
    local resolved_sha
    resolved_sha="$(git -C "$TMPDIR_CWF/cwf-source" rev-parse "$resolved_ref")"

    # Install
    case "$CWF_METHOD" in
        subtree) install_subtree "$TMPDIR_CWF/cwf-source" "$resolved_ref" ;;
        copy)    install_copy "$TMPDIR_CWF/cwf-source" "$resolved_ref" ;;
    esac

    # Post-install
    post_install "$resolved_ref" "$resolved_sha"

    log ""
    log "CWF $resolved_ref installed successfully (method: $CWF_METHOD)"
    log "Next: run /cwf-init in Claude Code to generate project config"
}

main "$@"
