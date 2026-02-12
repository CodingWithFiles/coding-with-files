---
description: Verify file integrity and sources for CIG system
argument-hint: [verify|report]
allowed-tools: Read, Bash(git rev-parse:*), Bash(.cig/scripts/command-helpers/cig-load-project-config), Bash(.cig/scripts/command-helpers/*:*), Bash(git:*), Bash(curl:*), Bash(sha256sum:*), Bash(find:*), Bash(echo:*)
---

## Context
- Project config: !`.cig/scripts/command-helpers/cig-load-project-config`
- CIG commands: !`find .claude/commands -name "cig-*.md" -type f 2>/dev/null || echo "No CIG commands found"`
- Helper scripts (v1.0): !`find .cig/scripts/command-helpers -name "cig-*" -type f 2>/dev/null || echo "No v1.0 helper scripts found"`
- Helper scripts (v2.0): !`find .cig/scripts/command-helpers -name "*.sh" -o -name "*.pl" -type f 2>/dev/null || echo "No v2.0 helper scripts found"`

## Your task
Verify security and integrity of CIG system files: **{arguments}**

!{bash}
.cig/scripts/command-helpers/context-manager location

**Parse arguments**: `[verify|report]`
- verify: Full integrity verification against canonical source
- report: Summary report of current file status

**Steps**:
1. **Load security config** from `cig-project.json` security section or `.cig/security/script-hashes.json`
2. **Verify helper scripts**: Check permissions (u+rx, at least 0500), calculate SHA256, compare against `.cig/security/script-hashes.json`
3. **Verify v1.0 legacy scripts**: cig-load-autoload-config, cig-load-project-config, cig-load-existing-tasks, cig-find-task-numbering-structure, cig-load-status-sections
4. **Verify CIG commands**: Check version indicators, validate against `security.file-integrity` patterns
5. **Generate report**: File-by-file status, permission checks, hash verification, version mismatches

**Verification Methods**:
- Local: `git ls-tree {ref} -- {path}`
- Remote: GitHub API contents endpoint with SHA comparison
- Fallback: Local git verification if remote unavailable

**Report Format**: Per-file status line with pass/fail indicator, version, SHA256, source. Summary with totals and action items for failures.