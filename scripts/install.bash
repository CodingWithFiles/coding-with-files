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
            local name
            name="$(basename "$item")"
            ln -s "../../$source_dir/$name" "$target_dir/$name"
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
        for dir in .cwf .cwf-skills .cwf-rules .cwf-agents; do
            if [[ -d "$dir" ]]; then
                git rm -rf --quiet "$dir" 2>/dev/null || true
                rm -rf "$dir"
            fi
        done
        # Need a clean state for subtree add
        git commit --allow-empty -m "CWF: remove existing install for reinstall" --quiet 2>/dev/null || true
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

    # Remove existing if force
    if [[ "$CWF_FORCE" == "1" ]]; then
        rm -rf .cwf .cwf-skills .cwf-rules .cwf-agents
    fi

    # Copy core
    cp -r "$clone_dir/.cwf" .cwf
    log "Copied .cwf/"

    # Copy skills to staging prefix
    cp -r "$clone_dir/.claude/skills" .cwf-skills
    log "Copied .cwf-skills/"

    # Copy rules to staging prefix
    if [[ -d "$clone_dir/.claude/rules" ]]; then
        cp -r "$clone_dir/.claude/rules" .cwf-rules
        log "Copied .cwf-rules/"
    fi

    # Copy agents to staging prefix
    if [[ -d "$clone_dir/.claude/agents" ]]; then
        cp -r "$clone_dir/.claude/agents" .cwf-agents
        log "Copied .cwf-agents/"
    fi

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
