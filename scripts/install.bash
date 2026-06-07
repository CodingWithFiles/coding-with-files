#!/usr/bin/env bash
#
# CWF Bootstrap Install Script
# Installs Coding with Files (CWF) into the current git repository.
#
# Usage:
#   curl -fsSL <url> | bash                              # defaults (read-tree)
#   curl -fsSL <url> | CWF_METHOD=copy bash              # file-copy fallback
#   curl -fsSL <url> | CWF_REF=v2.0.0 bash              # specific version
#   curl -fsSL <url> | CWF_SOURCE=file:///path bash      # custom source
#
# Environment variables:
#   CWF_METHOD   read-tree (default, merge-free) or copy (fallback).
#                subtree is deprecated and refused — it forces merge commits.
#   CWF_REF      latest (default), tag, branch, or commit SHA
#   CWF_SOURCE   CWF repo URL (default: GitHub)
#   CWF_FORCE    set to 1 to overwrite existing install
#
set -euo pipefail

# --- Configuration -----------------------------------------------------------

readonly CWF_METHOD="${CWF_METHOD:-read-tree}"
readonly CWF_REF="${CWF_REF:-latest}"
readonly CWF_SOURCE="${CWF_SOURCE:-https://github.com/CodingWithFiles/coding-with-files.git}"
readonly CWF_FORCE="${CWF_FORCE:-0}"

# Single source-of-truth list of (source-subpath:dest) laydown pairs. The
# symlink-escape guard, install_copy, and install_read_tree all iterate this
# SAME list, so a new source cannot be added without also being guarded. The
# source elements are BARE subpaths (no clone-dir prefix): copy and the guard
# prepend "$clone_dir/"; read-tree resolves them as "FETCH_HEAD:<src>".
readonly CWF_PAIRS=( ".cwf:.cwf" ".claude/skills:.cwf-skills" \
                     ".claude/rules:.cwf-rules" ".claude/agents:.cwf-agents" )

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

    # Validate method. subtree is deprecated and refused: it forces a merge
    # commit into the consumer's history. read-tree (default) is merge-free;
    # copy is the fallback for environments where read-tree cannot run.
    if [[ "$CWF_METHOD" == "subtree" ]]; then
        die "CWF_METHOD=subtree is deprecated: it forces merge commits into your history. Use 'read-tree' (default) or 'copy' if read-tree cannot run."
    elif [[ "$CWF_METHOD" != "read-tree" && "$CWF_METHOD" != "copy" ]]; then
        die "Invalid CWF_METHOD: $CWF_METHOD (must be 'read-tree' or 'copy')"
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

install_read_tree() {
    local clone_dir="$1"
    local ref="$2"

    log "Installing via read-tree method..."

    # Checkout the resolved ref in the clone so the scanned filesystem and the
    # subsequently-fetched tree are the same object.
    git -C "$clone_dir" checkout --quiet "$ref"

    # Build the present source roots from the shared pair list (same filter as
    # install_copy: a source dir absent from this release is simply skipped).
    local p src dest tree
    local -a roots=()
    for p in "${CWF_PAIRS[@]}"; do
        src="$clone_dir/${p%%:*}"
        [[ -d "$src" ]] && roots+=("$src")
    done

    # Refuse out-of-tree symlinks in the source BEFORE any change to the
    # consumer tree (fail-closed; same guard install_copy runs before cp -r).
    local guard="$clone_dir/.cwf/scripts/command-helpers/cwf-check-tree-symlinks"
    [[ -x "$guard" ]] || die "symlink-escape guard missing from source tree ($guard); cannot safely install"
    "$guard" "${roots[@]}" || die "refusing to install: source tree contains an out-of-tree symlink"

    # Bring source objects into the consumer object store. The clone is local
    # (no network), so this is a cheap object copy. Fetch the clone's HEAD
    # (just checked out to $ref above): HEAD is always advertised, so this
    # works whether $ref arrived as a tag, branch, or raw SHA — a raw SHA not
    # at a ref tip is not fetchable by name on the local transport.
    git fetch --no-tags "$clone_dir" HEAD >/dev/null || die "git fetch from clone failed"

    # Clear all four dest prefixes (index + worktree) FIRST, unconditionally:
    # read-tree --prefix refuses to overlay an existing prefix, so the clear is
    # not CWF_FORCE-gated. --ignore-unmatch makes it a no-op on a fresh repo.
    # Fail-closed (&&) so a partial clear cannot silently precede read-tree.
    # Clearing all four before reading any keeps a mid-laydown failure recoverable.
    for p in "${CWF_PAIRS[@]}"; do
        dest="${p##*:}"
        git rm -r --cached --quiet --ignore-unmatch -- "$dest" >/dev/null \
            && rm -rf -- "$dest" || die "failed to clear prefix $dest before laydown"
    done

    # Read each mapped source subtree into the index at its dest prefix. Use the
    # FETCHED object (FETCH_HEAD), never a re-resolved moving tip.
    for p in "${CWF_PAIRS[@]}"; do
        src="${p%%:*}"
        dest="${p##*:}"
        [[ -d "$clone_dir/$src" ]] || continue
        tree="$(git rev-parse "FETCH_HEAD:$src")" || die "no source subtree $src"
        git read-tree --prefix="$dest/" "$tree" || die "read-tree failed for $dest"
    done

    # Materialise ONLY the four laid-down prefixes into the worktree, NUL-safe
    # (no shell word-split/glob). NOT `-a`: the fresh-install path has no
    # clean-tree precondition, so `-a` could overwrite unrelated dirty files.
    git ls-files -z -- .cwf .cwf-skills .cwf-rules .cwf-agents \
        | git checkout-index -f -z --stdin || die "checkout-index materialise failed"

    log "Laid down .cwf/, .cwf-skills/, .cwf-rules/, .cwf-agents/ (staged, not committed)"
}

install_copy() {
    local clone_dir="$1"
    local ref="$2"

    log "Installing via copy method..."

    # Checkout the resolved ref
    git -C "$clone_dir" checkout --quiet "$ref"

    # Iterate the file-level CWF_PAIRS single source of truth (shared with the
    # symlink-escape guard and install_read_tree) so a new source cannot be
    # added without also being guarded.
    local p src
    local roots=()
    for p in "${CWF_PAIRS[@]}"; do
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
    for p in "${CWF_PAIRS[@]}"; do
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
    resolved_sha="$(git -C "$TMPDIR_CWF/cwf-source" rev-parse "${resolved_ref}^{commit}")"

    # Install
    case "$CWF_METHOD" in
        read-tree) install_read_tree "$TMPDIR_CWF/cwf-source" "$resolved_ref" ;;
        copy)      install_copy "$TMPDIR_CWF/cwf-source" "$resolved_ref" ;;
    esac

    # Post-install
    post_install "$resolved_ref" "$resolved_sha"

    log ""
    log "CWF $resolved_ref installed successfully (method: $CWF_METHOD)"
    log "Next: run /cwf-init in Claude Code to generate project config"
}

main "$@"
