---
name: cwf-security-check
description: Verify file integrity and sources for CWF system
user-invocable: true
allowed-tools:
  - Read
  - Bash
---

## Scope & Boundaries

**This step**: Verify integrity and security of CWF system files.
**Not this step**: Fixing issues (report only), modifying CWF system, or running workflows.

## Context

**Task arguments**: {arguments}

**First**: Run `.cwf/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

**Mandatory context** (run before verification):
- Run `.cwf/scripts/command-helpers/cwf-load-project-config` using the Bash tool to load project configuration and security settings.
- Run `find .claude/skills -name "SKILL.md" -type f 2>/dev/null || echo "No CIG skills found"` using the Bash tool to enumerate CIG skills.
- Run `find .cwf/scripts/command-helpers -name "cig-*" -type f 2>/dev/null || echo "No v1.0 helper scripts found"` using the Bash tool to enumerate v1.0 helper scripts.
- Run `find .cwf/scripts/command-helpers -name "*.sh" -o -name "*.pl" -type f 2>/dev/null || echo "No v2.0 helper scripts found"` using the Bash tool to enumerate v2.0 helper scripts.

## Workflow

**Parse arguments**: `[verify|report]`
- verify: Full integrity verification against canonical source
- report: Summary report of current file status

### 1. Load Security Config
From `cwf-project.json` security section or `.cwf/security/script-hashes.json`

### 2. Verify Helper Scripts
- Check permissions (u+rx, at least 0500)
- Calculate SHA256, compare against `.cwf/security/script-hashes.json`

### 3. Verify Legacy Scripts
- cig-load-autoload-config, cig-load-project-config, cig-load-existing-tasks, cig-find-task-numbering-structure, cig-load-status-sections

### 4. Verify CIG Skills
- Check version indicators, validate against `security.file-integrity` patterns

### 5. Generate Report
- File-by-file status, permission checks, hash verification, version mismatches

**Verification Methods**:
- Local: `git ls-tree {ref} -- {path}`
- Remote: GitHub API contents endpoint with SHA comparison
- Fallback: Local git verification if remote unavailable

**Report Format**: Per-file status line with pass/fail indicator, version, SHA256, source. Summary with totals and action items for failures.

## Success Criteria
- [ ] Project config and file lists loaded
- [ ] Helper scripts verified (permissions + hashes)
- [ ] CIG skills verified
- [ ] Report generated with pass/fail status
