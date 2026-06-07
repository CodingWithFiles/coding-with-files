# Installing CWF

This guide covers how to install Coding with Files (CWF) into your own repository.

## Quick Install (Script)

The install script automates the full setup. It works for both humans and agents with zero interaction.

### GitHub

```bash
curl -fsSL https://raw.githubusercontent.com/CodingWithFiles/coding-with-files/main/scripts/install.bash | bash
```

### GitLab, Gitea, Forgejo, self-hosted

```bash
git archive --remote=<cwf-repo-url> HEAD scripts/install.bash | tar -xO | bash
```

Override defaults with environment variables:

```bash
# Use file copy instead of the default read-tree laydown
curl -fsSL <url> | CWF_METHOD=copy bash

# Install a specific version
curl -fsSL <url> | CWF_REF=v2.0.0 bash

# Install from a local clone or mirror
curl -fsSL <url> | CWF_SOURCE=file:///path/to/cwf-repo bash

# Overwrite an existing install
curl -fsSL <url> | CWF_FORCE=1 bash
```

| Variable | Default | Values |
|----------|---------|--------|
| `CWF_METHOD` | `read-tree` | `read-tree`, `copy` (`subtree` is deprecated and refused) |
| `CWF_REF` | `latest` | Tag, branch, commit SHA, or `latest` |
| `CWF_SOURCE` | GitHub URL | Any git URL or `file://` path |
| `CWF_FORCE` | (unset) | `1` to overwrite existing install |

### Installing from a local clone

If you have a local clone of the CWF repository (e.g. for development or air-gapped
environments), use a `file://` URL as the source:

```bash
git archive --remote=file:///path/to/coding-with-files HEAD scripts/install.bash \
  | tar -xO > /tmp/cwf-install.bash
CWF_SOURCE=file:///path/to/coding-with-files bash /tmp/cwf-install.bash
```

When `CWF_SOURCE` is a `file://` URL, `CWF_REF` defaults to `HEAD` rather than the
latest release tag. This ensures you install the current state of the repository
rather than a potentially outdated tagged release. To install a specific tag from a
local clone, set `CWF_REF` explicitly:

```bash
CWF_SOURCE=file:///path/to/coding-with-files CWF_REF=v0.2.1 bash /tmp/cwf-install.bash
```

For the download-then-inspect approach:

```bash
curl -fsSL <url> -o /tmp/cwf-install.bash
less /tmp/cwf-install.bash   # review the script
CWF_REF=v2.0.0 bash /tmp/cwf-install.bash
```

**Important**: After install, restart Claude Code (or start a new conversation) for CWF skills to register. Then run `/cwf-init` to complete project setup.

After install, use the management script for ongoing operations:

```bash
.cwf/scripts/cwf-manage status          # show installed version
.cwf/scripts/cwf-manage list-releases   # list available versions
.cwf/scripts/cwf-manage update          # update to latest
.cwf/scripts/cwf-manage update v2.1.0   # update to specific version
.cwf/scripts/cwf-manage rollback v2.0.0 # revert to previous version
```

### Recovering an install stuck on an old `cwf-manage`

`cwf-manage update` is run by the *installed* (old) script, so a fix to the
updater only reaches installs made **after** that fix. An install predating a
given fix cannot benefit from it through `update` alone — the limitation is
forward-only. If `update` fails across a large version gap, recover by
re-running the bootstrap installer for the target version, which performs a
clean remove-then-add:

```bash
CWF_FORCE=1 CWF_REF=<tag> CWF_SOURCE=<source-url> bash install.bash
```

This is a one-time manual step; subsequent `update`s use the freshly-installed
(fixed) `cwf-manage`.

## Manual Install

Two methods are available for manual installation. **read-tree** is the default and
preferred method; **copy** is the fallback for environments where read-tree cannot run.

| Method | Best for | Merge-free | Upgrade path |
|--------|----------|------------|--------------|
| **Git read-tree** (default) | Any repo; keeps a linear history | Yes | Re-run the installer / `cwf-manage update` |
| **File copy** (fallback) | Air-gapped environments, or where `git read-tree` is unavailable | Yes | Re-copy from newer release |

> **`subtree` is deprecated and refused.** Earlier CWF releases laid the trees down with
> `git subtree add --squash`, which forces a merge commit into your history. The installer
> now refuses `CWF_METHOD=subtree`. If you have an existing subtree install, `cwf-manage
> update` migrates it onto read-tree automatically; run `cwf-manage check-merges` to see
> whether old subtree merge commits remain in your history.

## Prerequisites

- **Git** 1.7+
- **Perl** 5.20+ (helper scripts)
- **Bash** 4+ (helper scripts)
- **Claude Code** (for slash commands / skills)

Check your versions:

```bash
git --version
perl -v | head -2
bash --version | head -1
```

## Method 1: Git read-tree

`git read-tree` lays each CWF tree into your repo at a staging prefix using git's native
plumbing. Unlike `git subtree add --squash`, it creates **no merge commit** — the laydown
is staged into the index and you commit it as an ordinary single-parent commit, so your
history stays linear. The four trees map: `.cwf` → `.cwf/`, `.claude/skills` →
`.cwf-skills/`, `.claude/rules` → `.cwf-rules/`, `.claude/agents` → `.cwf-agents/`. The
staging prefixes are then symlinked into `.claude/` so CWF skills, rules, and agents
coexist with any you already have.

### Install

```bash
# Clone the CWF repo locally and check out the ref you want
git clone <cwf-repository-url> /tmp/cwf-source
cd /tmp/cwf-source && git checkout <tag-or-branch>

# Switch to your project repo
cd /path/to/your/repo

# Bring the CWF objects into your repo's object store (local, no network)
git fetch --no-tags /tmp/cwf-source HEAD

# Lay each tree at its staging prefix (read-tree refuses to overlay an existing
# prefix — if reinstalling, `git rm -r --cached <prefix>` first)
git read-tree --prefix=.cwf/        "$(git rev-parse FETCH_HEAD:.cwf)"
git read-tree --prefix=.cwf-skills/ "$(git rev-parse FETCH_HEAD:.claude/skills)"
git read-tree --prefix=.cwf-rules/  "$(git rev-parse FETCH_HEAD:.claude/rules)"
git read-tree --prefix=.cwf-agents/ "$(git rev-parse FETCH_HEAD:.claude/agents)"

# Materialise the staged trees into the working tree
git ls-files -z -- .cwf .cwf-skills .cwf-rules .cwf-agents | git checkout-index -f -z --stdin

# Create symlinks into .claude/ (skills, rules, agents)
mkdir -p .claude/skills .claude/rules .claude/agents
for d in .cwf-skills/cwf-*/;  do ln -s "../../.cwf-skills/$(basename "$d")"  ".claude/skills/$(basename "$d")"; done
for f in .cwf-rules/cwf-*.md;  do ln -s "../../.cwf-rules/$(basename "$f")"  ".claude/rules/$(basename "$f")";  done
for f in .cwf-agents/cwf-*.md; do ln -s "../../.cwf-agents/$(basename "$f")" ".claude/agents/$(basename "$f")"; done

# Commit — an ordinary single-parent commit, no merge
git commit -m "Add CWF"
```

This installs:
- `.cwf/` — scripts, templates, documentation, Perl libraries, security hashes
- `.cwf-skills/cwf-*`, `.cwf-rules/cwf-*.md`, `.cwf-agents/cwf-*.md` — skills, rules, agents
- `.claude/{skills,rules,agents}/cwf-*` — symlinks into the staging prefixes

### Update

Re-run the quick-install script, or use `cwf-manage update`. Both clear the staging
prefixes and re-lay the new trees with no merge commit. Review the CWF CHANGELOG for
breaking changes before upgrading.

### Remove

```bash
git rm -r .cwf .cwf-skills .cwf-rules .cwf-agents
rm -f .claude/skills/cwf-* .claude/rules/cwf-*.md .claude/agents/cwf-*.md  # remove symlinks
git commit -m "Remove CWF"
```

## Method 2: File Copy

Copy the CWF files directly into your repo. This gives you full control over when and how you upgrade.

### Install

```bash
# From the CWF source repository, copy the two directory trees:

# 1. Core system (scripts, templates, docs, libraries)
cp -r <cwf-source-path>/.cwf .cwf

# 2. Skills to staging prefix
cp -r <cwf-source-path>/.claude/skills .cwf-skills

# 3. Fix permissions
find .cwf/scripts -type f -exec chmod u+rx {} \;

# 4. Create symlinks into .claude/skills/
mkdir -p .claude/skills
for d in .cwf-skills/cwf-*/; do
    ln -s "../../.cwf-skills/$(basename "$d")" ".claude/skills/$(basename "$d")"
done
```

This copies:
- `.cwf/` — scripts, templates, documentation, Perl libraries, security hashes (~70 files)
- `.cwf-skills/cwf-*` — 18 skill definitions (one SKILL.md each)
- `.claude/skills/cwf-*` — symlinks to `.cwf-skills/cwf-*`

### Update

To upgrade to a newer CWF release, repeat the copy from the newer source:

```bash
# Replace .cwf/ and .cwf-skills/ with the newer version
rm -rf .cwf .cwf-skills
cp -r <cwf-source-path>/.cwf .cwf
cp -r <cwf-source-path>/.claude/skills .cwf-skills

# Fix permissions
find .cwf/scripts -type f -exec chmod u+rx {} \;

# Recreate symlinks
rm -f .claude/skills/cwf-*
mkdir -p .claude/skills
for d in .cwf-skills/cwf-*/; do
    ln -s "../../.cwf-skills/$(basename "$d")" ".claude/skills/$(basename "$d")"
done
```

Review the CWF CHANGELOG for breaking changes before upgrading.

### Remove

```bash
rm -rf .cwf .cwf-skills
rm -f .claude/skills/cwf-*  # remove symlinks
# Also remove implementation-guide/ if you no longer need task history
```

## Post-Install Setup

After installing with either method, complete these steps:

### 1. Initialise your project

Run the `/cwf-init` slash command in Claude Code. This creates:
- `implementation-guide/` directory structure
- `implementation-guide/cwf-project.json` project configuration
- Navigation index in `implementation-guide/README.md`

### 2. Configure .gitignore

Add the task stack file (user-specific workspace state) to your `.gitignore`:

```bash
echo '.cwf/task-stack' >> .gitignore
```

### 3. Unicode support (PERL5OPT)

CWF sets `env.PERL5OPT=-CDSLA` in your **project-level** `.claude/settings.json`
(at the git root) automatically: `/cwf-init` and `cwf-manage update` merge it via
`cwf-claude-settings-merge`, and it is committed with the project. Normally no
manual step is required — restart Claude Code after init so the session picks it
up.

If you are setting up without `/cwf-init`, add it to the project-level
`.claude/settings.json` yourself:

```json
{
  "env": {
    "PERL5OPT": "-CDSLA"
  }
}
```

Keep `PERL5OPT` in the project settings rather than your global user settings:
that scopes it per-repo so multiple CWF installs can't clash on a single global
value, and the project value overrides any global one. A value you set globally
under an earlier CWF version is harmless — the project value wins; removing it is
optional.

This enables Unicode handling in Perl helper scripts (STDIN/STDOUT/STDERR
plus `@ARGV` decoding). Without it, scripts will issue warnings, and any
non-ASCII characters passed on the command line will be misinterpreted as
Latin-1 — producing mojibake (e.g. `→` becomes `â†'`). The `A` flag is what
fixes `@ARGV` decoding; it can only be set via `PERL5OPT`, not via the
script shebang.

## Verification

After installation, verify everything is in place:

```bash
# Check .cwf directory exists with expected structure
ls .cwf/scripts/command-helpers/context-manager

# Check skills are installed (symlinks resolve)
ls -la .claude/skills/cwf-init  # should show symlink to ../../.cwf-skills/cwf-init
cat .claude/skills/cwf-init/SKILL.md

# Check helper scripts are executable
.cwf/scripts/command-helpers/context-manager location
```

All three commands should succeed without errors. If `context-manager location` prints your git root path, CWF is installed correctly.

## Troubleshooting

### Permission denied on helper scripts

CWF scripts require execute permission. Fix with:

```bash
find .cwf/scripts -type f -exec chmod u+rx {} \;
```

### Perl module not found

Ensure your working directory is the git root (where `.cwf/` lives). Helper scripts use `FindBin` to resolve paths relative to themselves.

### Skills not appearing in Claude Code

Skills must be in `.claude/skills/cwf-*/SKILL.md` relative to your git root. Verify the directory structure:

```bash
ls .claude/skills/cwf-*/SKILL.md | wc -l
# Should show 18
```

If skills still don't appear, restart Claude Code to pick up new skill definitions.

### Unicode warnings from Perl scripts

Set `PERL5OPT="-CDSLA"` as described in Post-Install Setup step 3. These warnings are cosmetic and don't affect functionality.
