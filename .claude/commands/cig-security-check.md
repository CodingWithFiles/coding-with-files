---
description: Verify file integrity and sources for CIG system
argument-hint: [verify|report]
allowed-tools: Read, Bash(.cig/scripts/command-helpers/cig-load-project-config), Bash(git:*), Bash(curl:*), Bash(sha256sum:*), Bash(find:*), Bash(echo:*)
---

## Context
- Project config: !`.cig/scripts/command-helpers/cig-load-project-config`
- CIG commands: !`find .claude/commands -name "cig-*.md" -type f 2>/dev/null || echo "No CIG commands found"`
- Helper scripts (v1.0): !`find .cig/scripts/command-helpers -name "cig-*" -type f 2>/dev/null || echo "No v1.0 helper scripts found"`
- Helper scripts (v2.0): !`find .cig/scripts/command-helpers -name "*.sh" -o -name "*.pl" -type f 2>/dev/null || echo "No v2.0 helper scripts found"`

## Your task
Verify security and integrity of CIG system files: **$ARGUMENTS**

**Parse arguments**: `[verify|report]`
- verify: Perform full integrity verification against canonical source
- report: Generate summary report of current file status

**Steps**:
1. **Load security configuration** from `cig-project.json` security section or `.cig/security/script-hashes.json`
2. **Verify v2.0 helper scripts** (priority check):
   - hierarchy-resolver.sh
   - format-detector.sh
   - status-aggregator.sh
   - template-version-parser.sh
   - context-inheritance.pl
   - Check permissions: Must have u+rx (at least 0500)
   - Calculate SHA256 hash of each script file
   - Compare with expected hashes from `.cig/security/script-hashes.json`
3. **Verify v1.0 helper scripts** (legacy):
   - cig-load-autoload-config
   - cig-load-project-config
   - cig-load-existing-tasks
   - cig-find-task-numbering-structure
   - cig-load-status-sections
   - Same permission and hash verification
4. **Verify CIG commands**:
   - Check command files for version indicators
   - Validate against configured patterns in security.file-integrity section
5. **Generate integrity report**:
   - File-by-file verification status
   - Permission verification (u+rx minimum)
   - Version mismatches or discrepancies
   - Missing frontmatter or source information
   - Hash verification against stored hashes

**Verification Process**:
- **Local Git**: Use `git ls-tree {ref} -- {path}` for local repository verification
- **GitHub API**: Use `curl -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/{owner}/{repo}/contents/{path}?ref={ref}"` for remote verification
- **SHA Extraction**: Parse JSON response to extract `sha` field for comparison

**Security Report Format**:
```
CIG Security Verification Report
================================

HELPER SCRIPTS:
✅ .cig/scripts/command-helpers/cig-load-autoload-config
   Version: 1.0.0 (matches config)
   SHA256: 3b7a8f9c2d1e6f4a5b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c (verified against remote)
   Source: https://github.com/OWNER/REPO (trusted)

❌ .cig/scripts/command-helpers/cig-load-project-config  
   Version: 1.0.0 (matches config)
   SHA256: 4c8b9a0d2e1f6a5a6b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3d (MISMATCH - expected: 5d9c0e1f3a2b8c6a7c0d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5e)
   Source: https://github.com/OWNER/REPO (trusted)

CIG COMMANDS:
✅ .claude/commands/cig-new-task.md
   Pattern match: .claude/commands/cig-*.md ✓
   
SUMMARY:
- Total files checked: 8
- Verified: 7
- Failed verification: 1
- Action required: Update cig-load-project-config script
```

**Error Handling**:
- **Error**: Cannot access remote repository for verification
- **Cause**: Network issues or repository configuration problems  
- **Solution**: Fall back to local git verification if available
- **Example**: Use `git ls-tree main -- .cig/scripts/command-helpers/cig-load-autoload-config`
- **Uncertainty**: If security config missing, prompt user to configure canonical source

**Success**: Complete security verification with actionable recommendations for any integrity issues found