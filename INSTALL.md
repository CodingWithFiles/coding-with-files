# Installing CWF

This guide covers how to install Coding with Files (CWF) into your own repository.

## Quick Install (Script)

The install script automates the full setup. It works for both humans and agents with zero interaction.

```bash
curl -fsSL https://raw.githubusercontent.com/mattkeenan/coding-with-files/main/scripts/install.bash | bash
```

Override defaults with environment variables:

```bash
# Use file copy instead of git subtree
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
| `CWF_METHOD` | `subtree` | `subtree`, `copy` |
| `CWF_REF` | `latest` | Tag, branch, commit SHA, or `latest` |
| `CWF_SOURCE` | GitHub URL | Any git URL or `file://` path |
| `CWF_FORCE` | (unset) | `1` to overwrite existing install |

For the download-then-inspect approach:

```bash
curl -fsSL <url> -o /tmp/cwf-install.bash
less /tmp/cwf-install.bash   # review the script
CWF_REF=v2.0.0 bash /tmp/cwf-install.bash
```

After install, use the management script for ongoing operations:

```bash
.cwf/scripts/cwf-manage status          # show installed version
.cwf/scripts/cwf-manage list-releases   # list available versions
.cwf/scripts/cwf-manage update          # update to latest
.cwf/scripts/cwf-manage update v2.1.0   # update to specific version
.cwf/scripts/cwf-manage rollback v2.0.0 # revert to previous version
```

## Manual Install

Three methods are available for manual installation. All are first-class and fully supported.

| Method | Best for | Upstream sync | Upgrade path |
|--------|----------|---------------|--------------|
| **Git subtree** | Repos that want automatic upstream updates | Yes | `git subtree pull` |
| **File copy** | Static installs, air-gapped environments, controlled upgrades | No | Re-copy from newer release |

## Prerequisites

- **Git** 1.7+ (for subtree support)
- **Perl** 5.20+ (helper scripts)
- **Bash** 4+ (helper scripts)
- **Claude Code** (for slash commands / skills)

Check your versions:

```bash
git --version
perl -v | head -2
bash --version | head -1
```

## Method 1: Git Subtree

Git subtree embeds CWF into your repo with a link back to the upstream source. This uses two subtree splits from the single CWF repo — one for the core system (`.cwf/`) and one for the skills (`.cwf-skills/`). Skills are then symlinked into `.claude/skills/` so they coexist with any skills you already have.

### Install

```bash
# Clone the CWF repo locally (if you haven't already)
git clone <cwf-repository-url> /tmp/cwf-source
cd /tmp/cwf-source

# Create split branches for the two directory trees
git subtree split --prefix=.cwf -b cwf-core
git subtree split --prefix=.claude/skills -b cwf-skills

# Switch to your project repo
cd /path/to/your/repo

# Add both subtrees (.cwf-skills/ is a staging prefix)
git subtree add --prefix=.cwf /tmp/cwf-source cwf-core --squash
git subtree add --prefix=.cwf-skills /tmp/cwf-source cwf-skills --squash

# Create symlinks from .cwf-skills/ into .claude/skills/
mkdir -p .claude/skills
for d in .cwf-skills/cwf-*/; do
    ln -s "../../.cwf-skills/$(basename "$d")" ".claude/skills/$(basename "$d")"
done
```

This installs:
- `.cwf/` — scripts, templates, documentation, Perl libraries, security hashes
- `.cwf-skills/cwf-*` — 18 skill definitions (one SKILL.md each)
- `.claude/skills/cwf-*` — symlinks to `.cwf-skills/cwf-*`

### Update

```bash
# From the CWF source clone, update the split branches
cd /tmp/cwf-source
git pull
git subtree split --prefix=.cwf -b cwf-core --rejoin
git subtree split --prefix=.claude/skills -b cwf-skills --rejoin

# Switch to your project repo and pull updates
cd /path/to/your/repo
git subtree pull --prefix=.cwf /tmp/cwf-source cwf-core --squash -m "Update CWF core"
git subtree pull --prefix=.cwf-skills /tmp/cwf-source cwf-skills --squash -m "Update CWF skills"

# Recreate symlinks (handles skill renames across versions)
rm -f .claude/skills/cwf-*  # remove old symlinks only
mkdir -p .claude/skills
for d in .cwf-skills/cwf-*/; do
    ln -s "../../.cwf-skills/$(basename "$d")" ".claude/skills/$(basename "$d")"
done
```

### Remove

```bash
git rm -r .cwf .cwf-skills
rm -f .claude/skills/cwf-*  # remove symlinks
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

### 3. Optional: Enable Unicode support

Add `PERL5OPT` to your Claude Code settings (`~/.claude/settings.json`):

```json
{
  "env": {
    "PERL5OPT": "-CDSL"
  }
}
```

This enables Unicode handling in Perl helper scripts. Without it, scripts will issue warnings but continue to work.

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

# Check Perl modules load
perl -I.cwf/lib -MCWF::Common -e 'print "OK\n"'
```

All four commands should succeed without errors. If `context-manager location` prints your git root path, CWF is installed correctly.

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

Set `PERL5OPT="-CDSL"` as described in Post-Install Setup step 3. These warnings are cosmetic and don't affect functionality.
