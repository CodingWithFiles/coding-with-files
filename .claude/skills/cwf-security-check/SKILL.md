---
name: cwf-security-check
description: Verify file integrity and sources for CWF system
user-invocable: true
allowed-tools:
  - Bash
---

## Scope & Boundaries

**This step**: Verify integrity and security of CWF system files.
**Not this step**: Fixing issues (report only), modifying CWF system, or running workflows.

## Context

**Task arguments**: {arguments}

**First**: Run `.cwf/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

## Workflow

**Parse arguments**: `[verify|report]`
- verify: Full integrity verification (default)
- report: Same as verify

### 1. Run the deterministic validator

```bash
.cwf/scripts/cwf-manage validate
```

This checks:
- **Config**: `cwf-project.json` has required fields (`supported-task-types`, `source-management`)
- **Workflow**: Every `.md` file under `implementation-guide/` has a `## Status` section with a valid status value
- **Consistency**: Task number in dirname matches `**Task**:` field; active task branch matches current git branch
- **Security**: Each file in `.cwf/security/script-hashes.json` exists, has correct permissions (if recorded), and SHA256 matches

### 2. Report results

- If `cwf-manage validate` exits 0: report **OK**
- If it exits 1: show violations as-is — each violation includes file, field, actual value, expected value, and a fix action

## Success Criteria
- [ ] `cwf-manage validate` run successfully
- [ ] Violations reported (if any) with actionable fix instructions
