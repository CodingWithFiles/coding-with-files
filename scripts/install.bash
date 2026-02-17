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
readonly CWF_SOURCE="${CWF_SOURCE:-https://github.com/mattkeenan/coding-with-files.git}"
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

create_skill_symlinks() {
    mkdir -p .claude/skills

    # Remove stale CWF symlinks (handles skill renames across versions)
    for link in .claude/skills/cwf-*; do
        if [[ -L "$link" ]]; then
            rm "$link"
        fi
    done

    # Create relative symlinks for each skill dir
    local count=0
    for skill_dir in .cwf-skills/cwf-*/; do
        if [[ -d "$skill_dir" ]]; then
            local name
            name="$(basename "$skill_dir")"
            ln -s "../../.cwf-skills/$name" ".claude/skills/$name"
            count=$((count + 1))
        fi
    done

    log "Created $count skill symlinks in .claude/skills/"
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

    # Remove existing if force
    if [[ "$CWF_FORCE" == "1" ]]; then
        if [[ -d ".cwf" ]]; then
            git rm -rf --quiet .cwf 2>/dev/null || true
            rm -rf .cwf
        fi
        if [[ -d ".cwf-skills" ]]; then
            git rm -rf --quiet .cwf-skills 2>/dev/null || true
            rm -rf .cwf-skills
        fi
        # Remove old symlinks
        for link in .claude/skills/cwf-*; do
            if [[ -L "$link" ]]; then
                rm "$link"
            fi
        done
        # Need a clean state for subtree add
        git commit --allow-empty -m "CWF: remove existing install for reinstall" --quiet 2>/dev/null || true
    fi

    # Add both subtrees
    log "Adding .cwf/ (subtree split 1/2)..."
    git subtree add --prefix=.cwf "$clone_dir" cwf-core --squash -m "Add CWF core ($ref)"

    log "Adding .cwf-skills/ (subtree split 2/2)..."
    git subtree add --prefix=.cwf-skills "$clone_dir" cwf-skills --squash -m "Add CWF skills ($ref)"
}

install_copy() {
    local clone_dir="$1"
    local ref="$2"

    log "Installing via copy method..."

    # Checkout the resolved ref
    git -C "$clone_dir" checkout --quiet "$ref"

    # Remove existing if force
    if [[ "$CWF_FORCE" == "1" ]]; then
        rm -rf .cwf .cwf-skills
        # Remove old symlinks
        for link in .claude/skills/cwf-*; do
            if [[ -L "$link" ]]; then
                rm "$link"
            fi
        done
    fi

    # Copy core
    cp -r "$clone_dir/.cwf" .cwf
    log "Copied .cwf/"

    # Copy skills to staging prefix
    cp -r "$clone_dir/.claude/skills" .cwf-skills
    log "Copied .cwf-skills/"

    # Fix permissions
    find .cwf/scripts -type f -exec chmod u+rx {} \;
    log "Fixed script permissions"
}

# --- Post-install setup -------------------------------------------------------

post_install() {
    local ref="$1"
    local resolved_sha="$2"

    # Create skill symlinks
    create_skill_symlinks

    # Create implementation-guide directory
    if [[ ! -d "implementation-guide" ]]; then
        mkdir -p implementation-guide
        log "Post-install: created implementation-guide/"
    fi

    # Update .gitignore
    if [[ ! -f ".gitignore" ]]; then
        echo '.cwf/task-stack' > .gitignore
        log "Post-install: created .gitignore with .cwf/task-stack"
    elif ! grep -q '^\\.cwf/task-stack$' .gitignore; then
        echo '.cwf/task-stack' >> .gitignore
        log "Post-install: added .cwf/task-stack to .gitignore"
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
