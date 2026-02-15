# Installing CWF

This guide covers how to install Coding with Files (CWF) into your own repository. There are two methods — both are first-class and fully supported.

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

Git subtree embeds CWF into your repo with a link back to the upstream source. This uses two subtree splits from the single CWF repo — one for the core system (`.cwf/`) and one for the skills (`.claude/skills/`).

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

# Add both subtrees
git subtree add --prefix=.cwf /tmp/cwf-source cwf-core --squash
git subtree add --prefix=.claude/skills /tmp/cwf-source cwf-skills --squash
```

This installs:
- `.cwf/` — scripts, templates, documentation, Perl libraries, security hashes
- `.claude/skills/cwf-*` — 18 skill definitions (one SKILL.md each)

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
git subtree pull --prefix=.claude/skills /tmp/cwf-source cwf-skills --squash -m "Update CWF skills"
```

### Remove

```bash
git rm -r .cwf .claude/skills/cwf-*
git commit -m "Remove CWF"
```

## Method 2: File Copy

Copy the CWF files directly into your repo. This gives you full control over when and how you upgrade.

### Install

```bash
# From the CWF source repository, copy the two directory trees:

# 1. Core system (scripts, templates, docs, libraries)
cp -r <cwf-source-path>/.cwf .cwf

# 2. Claude Code skills (slash commands)
mkdir -p .claude/skills
cp -r <cwf-source-path>/.claude/skills/cwf-* .claude/skills/
```

This copies:
- `.cwf/` — scripts, templates, documentation, Perl libraries, security hashes (~70 files)
- `.claude/skills/cwf-*` — 18 skill definitions (one SKILL.md each)

### Fix permissions

File copy may not preserve execute permissions. Run this after copying:

```bash
find .cwf/scripts -type f -exec chmod u+rx {} \;
```

### Update

To upgrade to a newer CWF release, repeat the copy from the newer source:

```bash
# Replace .cwf/ with the newer version
rm -rf .cwf
cp -r <cwf-source-path>/.cwf .cwf

# Replace skills with the newer versions
rm -rf .claude/skills/cwf-*
cp -r <cwf-source-path>/.claude/skills/cwf-* .claude/skills/

# Fix permissions
find .cwf/scripts -type f -exec chmod u+rx {} \;
```

Review the CWF CHANGELOG for breaking changes before upgrading.

### Remove

```bash
rm -rf .cwf .claude/skills/cwf-*
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

# Check skills are installed
ls .claude/skills/cwf-init/SKILL.md

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
