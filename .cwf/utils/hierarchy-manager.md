# CWF Hierarchy Manager

## Purpose
Manage hierarchical task numbering and directory structure (2.1.3 format).

## Numbering System
- **Major tasks**: 1, 2, 3, etc. (`implementation-guide/feature/1-user-auth/`)
- **Minor tasks**: 1.1, 1.2, etc. (`implementation-guide/feature/1-user-auth/1.1-user-model/`)
- **Micro tasks**: 1.1.1, 1.1.2, etc. (`implementation-guide/feature/1-user-auth/1.1-user-model/1.1.1-database-schema/`)

## Directory Scanning Strategy
1. **Prefer searching over scanning** for context efficiency
2. **If scanning needed**: Use breadth-first approach
   - Scan document files before detailed content
   - Preserve context by avoiding deep file reads initially

## Next Number Generation
```bash
# Find highest number at current level
find implementation-guide/{category} -maxdepth 1 -name '[0-9]*' | \
  sed 's/.*\/\([0-9]*\)-.*/\1/' | sort -n | tail -1
```

## Subtask Creation
- **Filesystem sync**: Numbering must match directory hierarchy
- **Subtasks location**: Always in subdirectories of parent task
- **Example**: Task 2.1.3 → `2-main/2.1-sub/2.1.3-micro/`

## Status Aggregation  
- Parse `## Current Status` sections from all levels
- Calculate completion percentages
- Bubble up status to parent tasks

## Error Handling
**Error**: Invalid hierarchy level specified
**Cause**: Attempting to create 2.1.3 when 2.1 doesn't exist
**Solution**: Create parent tasks first in proper order
**Example**: Create 2-main, then 2.1-sub, then 2.1.3-micro
**Uncertainty**: When parent task structure unclear, show existing hierarchy and ask for clarification