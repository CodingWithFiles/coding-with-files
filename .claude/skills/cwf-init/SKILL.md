---
name: cwf-init
description: Initialise CWF system with project configuration
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Bash
---

## Scope & Boundaries

**This step**: Initialise the CWF system for a project — create directories, configuration, and documentation.
**Not this step**: Creating tasks (use `/cwf-new-task`), configuring settings (use `/cwf-config`).

## Context

**First**: Run `.cwf/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

**Mandatory context** (run before proceeding):
- Run `ls -la implementation-guide/ 2>/dev/null || echo "No implementation-guide found"` using the Bash tool to check if CWF is already initialised.

## Workflow

### 1. Create Directory Structure
- `implementation-guide/` at git root

### 1a. Verify and Repair CWF Install

CWF helper scripts may be missing execute permissions if `.cwf/` was copied via a method that does not preserve modes (e.g. `cp` without `-p`, an extracted archive, or a non-`install.bash` workflow). This step deterministically repairs fixable permission deltas (where the file's sha256 still matches what `script-hashes.json` records) and refuses to proceed if any file is missing or tampered.

Run, using the Bash tool. The first block reads `cwf-manage`'s recorded permission from `.cwf/security/script-hashes.json` (the source of truth — no magic numbers) and chmods the entry-point to that exact value, in case `.cwf/` was copied without preserving modes. The second command then runs `cwf-manage fix-security`, which reads the same JSON to repair every other tracked file's permissions:

```bash
PERMS=$(perl -MJSON::PP -e '
    open my $f, "<", ".cwf/security/script-hashes.json" or die "cannot read script-hashes.json: $!";
    local $/;
    my $j = JSON::PP::decode_json(<$f>);
    close $f;
    print $j->{scripts}{"cwf-manage"}{permissions} or die "no permissions recorded for cwf-manage";
')
chmod "$PERMS" .cwf/scripts/cwf-manage
.cwf/scripts/cwf-manage fix-security
```

- If exit code is 0, continue to step 2.
- If exit code is non-zero, **abort `/cwf-init`**: relay the subcommand's stdout/stderr to the user verbatim, then append a single line: `[CWF] /cwf-init aborted: run 'cwf-manage update' or reinstall, then re-run /cwf-init.` Do not proceed to step 2.

### 2. Generate Project Configuration
- Create `implementation-guide/cwf-project.json` from template
- Use project name from git remote or directory name
- Set default task management (github) and branch conventions

### 3. Create Navigation
- Generate `implementation-guide/README.md` with navigation index
- Include command reference and project overview

### 4. Update CLAUDE.md
- The CWF preamble is owned by the `claude-md-preamble` artefact (applied in step 6b-apply below). Step 6b-apply wraps the preamble in HTML-comment sentinels so future updates can replace it precisely:
  ```markdown
  <!-- CWF-PREAMBLE-START -->
  > **CWF (Coding with Files) is installed in this project.**
  > - Invoke CWF workflow steps using the `Skill` tool (e.g. `Skill("cwf-task-plan")`). Do not manually read or follow SKILL.md instructions directly.
  > - All workflow steps are mandatory. If a step is genuinely inapplicable, mark it `Skipped` via the workflow process — do not silently omit it.
  <!-- CWF-PREAMBLE-END -->
  ```
- Content **between** the sentinels is owned by CWF and will be overwritten on update. User notes belong outside the markers.
- This step is now a no-op at the LLM level — the apply helper handles it. Continue to step 5.

### 5. Configure .gitignore
- The `.gitignore` entries (`.cwf/task-stack`, `.cwf/.update.lock`) are owned by the `gitignore-entries` artefact and applied by step 6b-apply below. No manual action needed at this step.

### 6. Register Skill Permissions
- List available CWF skills: `ls .claude/skills/cwf-*/`
- Show the user the list of `Skill(cwf-<name>)` entries that will be added to `.claude/settings.json`
- **Ask user to confirm** before writing any file
- Read existing `.claude/settings.json` if present; use `{"permissions":{"allow":[]}}` if absent
- Add each missing `Skill(cwf-<name>)` entry to `permissions.allow` — skip any already present
- Write back valid JSON to `.claude/settings.json`
- **Note**: This is the project-level `.claude/settings.json` (at git root). CWF-required env vars (`PERL5OPT`) are merged into the same file by step 6d.

### 6b-apply. Apply CWF Artefacts (Bootstrap)

Run, using the Bash tool, from the git root:

```bash
# Worktree-safe: resolve the MAIN tree, not a linked worktree (Task 173).
# cwf-apply-artefacts has no internal root fallback — the argument is load-bearing.
GIT_ROOT="$(cd "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")" && pwd)"
.cwf/scripts/command-helpers/cwf-apply-artefacts "$GIT_ROOT" "$GIT_ROOT" --bootstrap-init
```

This installs (or refreshes) every non-script artefact CWF ships:
- `.gitignore` entries (`.cwf/task-stack`, `.cwf/.update.lock`)
- `.cwf-rules/cwf-*.md` (rule bundle)
- CLAUDE.md preamble (wrapped in sentinels per step 4)
- `.claude/rules/cwf-*.md` symlinks → `.cwf-rules/`

**Hard ordering**: this step MUST run before step 6d. Step 6d registers the
rules-inject `UserPromptSubmit` hook whose command
(`cat .cwf/rules-inject.txt 2>/dev/null || true`) reads the file shipped in the
`.cwf/` subtree. Future SKILL.md edits must preserve this ordering.

- If exit code 0: continue.
- If non-zero: relay stderr to the user verbatim and append `[CWF] /cwf-init aborted: cwf-apply-artefacts failed; resolve the error above and re-run /cwf-init.` Do not proceed.

### 6c. Rule Re-Injection Hook (registered by step 6d)

No manual JSON edit here. The rules-inject `UserPromptSubmit` hook
(`cat .cwf/rules-inject.txt 2>/dev/null || true`) is registered automatically by
`cwf-claude-settings-merge` in step 6d, in the correct group-wrapper shape, and
that step also migrates away the legacy dead `PreToolUse`/`UserPromptSubmit`
entry from earlier installs. (Step 6b must run first so `.cwf/rules-inject.txt`
is in place — see the hard-ordering note above.)

### 6d. Register Bash Allowlist, Hooks, and the Rule Re-Injection Hook

Walk `.cwf/security/script-hashes.json` and add a `Bash(...)` allowlist entry per top-level CWF helper plus `hooks.Stop[]` entries for every CWF Stop hook. This step also registers the fixed rules-inject `UserPromptSubmit` hook (step 6c) and migrates away any legacy dead `PreToolUse`/`UserPromptSubmit` entry. Without this, a fresh install prompts for permission on every helper invocation and ships without the CWF safety hooks. The helper is idempotent — safe to re-run after `cwf-manage update` adds new helpers.

Run, using the Bash tool:

```bash
.cwf/scripts/command-helpers/cwf-claude-settings-merge
```

- If exit code is 0, continue. Relay the helper's stdout summary verbatim. `[CWF] WARN:` lines on stderr (e.g. a manifest entry references a file that is not on disk) are logged and tolerated — partial coverage is acceptable.
- If exit code is non-zero **or** stderr contains any `[CWF] ERROR:` line, **abort `/cwf-init`**: relay stdout/stderr to the user verbatim and append: `[CWF] /cwf-init aborted: cwf-claude-settings-merge failed; resolve the error above and re-run /cwf-init.` Do not proceed.

### 7. PERL5OPT (no user action)
- `env.PERL5OPT=-CDSLA` is merged into the project-level `.claude/settings.json`
  automatically by step 6d (`cwf-claude-settings-merge`) and committed by step 8.
  No manual edit of your global user settings is needed — keeping the setting
  project-scoped avoids clashes between multiple CWF installs on one machine.
- This enables Unicode handling (including `@ARGV` decoding) in Perl helper
  scripts. Restart Claude Code after init so the session picks up the new env var.

### 8. Commit Init Output
- Stage all files created or modified by init:
  ```bash
  git add implementation-guide/ .gitignore CLAUDE.md .claude/settings.json .claude/rules/
  ```
- Create the init commit now:
  ```bash
  git commit -m "Initialise CWF project configuration"
  ```
- Follow the project's commit conventions (see `docs/conventions/commit-messages.md` if present)
- **Do not begin task work until this commit is made**

**Success**: Complete CWF system ready for `/cwf-new-task` usage

## Success Criteria
- [ ] Git root confirmed
- [ ] Directory structure created
- [ ] Install integrity verified via `cwf-manage fix-security` (exit 0)
- [ ] Project configuration generated
- [ ] Navigation index created
- [ ] Skill permissions registered in `.claude/settings.json` (with user confirmation)
- [ ] CWF artefacts applied via `cwf-apply-artefacts --bootstrap-init` (gitignore entries, .cwf-rules/, CLAUDE.md preamble, .claude/rules/ symlinks)
- [ ] Rule re-injection hook configured in `.claude/settings.json`
- [ ] Bash allowlist + Stop hooks registered via `cwf-claude-settings-merge`
- [ ] PERL5OPT merged into project `.claude/settings.json` via `cwf-claude-settings-merge` (step 6d)
- [ ] Init commit created (mandatory — do not begin task work without it)
