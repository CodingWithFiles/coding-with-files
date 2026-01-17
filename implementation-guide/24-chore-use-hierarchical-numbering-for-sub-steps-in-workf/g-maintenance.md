# Use Hierarchical Numbering for Sub-steps in Workflow Templates - Maintenance

## Task Reference
- **Task ID**: internal-24
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/24-use-hierarchical-numbering-for-sub-steps-in-workf
- **Template Version**: 2.0

## Goal
Maintain consistency and clarity of hierarchical numbering in CIG workflow command files through ongoing validation and documentation updates.

## Monitoring Requirements

### Documentation Health Metrics

**Manual Review Triggers**:
- New workflow command files added to `.claude/commands/`
- Existing workflow command files modified
- User reports of numbering confusion
- Quarterly documentation audits

**Validation Checks** (run periodically):
```bash
# Check all workflow files use numbered list format for main steps
grep -E '^\s*[0-9]+\. \*\*' .claude/commands/cig-*.md | wc -l

# Verify no markdown headers remain (should return no results)
grep -E '^###\s+Step [0-9]+:' .claude/commands/cig-*.md

# Verify hierarchical sub-steps in cig-retrospective.md
grep -E '^\s*[0-9]+\.[0-9]+\. \*\*' .claude/commands/cig-retrospective.md | wc -l
```

**Expected Values**:
- Numbered list steps: Variable (depends on file, typically 8-10 per file)
- Markdown headers: 0 (none expected)
- Hierarchical sub-steps: 12 (in cig-retrospective.md only)

### Alerting Rules

**Critical**: Not applicable (documentation doesn't have runtime alerts)

**Warning Indicators** (passive observation):
- User reports numbering is confusing
- New workflow files don't follow numbering convention
- Modified workflow files introduce markdown header format

**Response Procedures**:
- Review reported file
- Run validation checks
- Apply hierarchical numbering pattern if needed
- Reference Task 24 implementation as canonical example

## Maintenance Tasks

### Quarterly (Every 3 Months)

**Documentation Audit**:
- Run all 3 validation checks listed in Monitoring Requirements
- Review any new workflow command files added since last audit
- Verify consistency across all 8 core workflow files
- Check for any user-reported numbering issues

**Actions**:
```bash
# Run validation suite
for cmd in "grep -E '^\s*[0-9]+\. \*\*' .claude/commands/cig-*.md | wc -l" \
           "grep -E '^###\s+Step [0-9]+:' .claude/commands/cig-*.md" \
           "grep -E '^\s*[0-9]+\.[0-9]+\. \*\*' .claude/commands/cig-retrospective.md | wc -l"; do
    eval "$cmd"
done

# Review git log for workflow file changes
git log --oneline --since="3 months ago" -- .claude/commands/cig-*.md
```

**Expected Duration**: 15-30 minutes

### As-Needed (Event-Driven)

**New Workflow File Added**:
- Review new file's step numbering format
- Ensure follows `N. **Step Name**:` pattern
- Verify sub-steps (if any) use `N.M. **Sub-step Name**:` pattern
- Add to validation suite if it becomes a core workflow file

**Workflow File Modified**:
- Run validation checks on modified file
- Ensure changes preserve numbering consistency
- Review diff to catch any markdown header introduction

**User Report of Confusion**:
- Investigate specific file and section mentioned
- Run validation checks
- Determine if numbering pattern violated
- Fix if needed, or clarify documentation if pattern is correct

## Incident Response

### Common Issues and Resolutions

**Issue 1: New workflow file uses markdown headers instead of numbered lists**

**Symptoms**:
- Validation check `grep -E '^###\s+Step [0-9]+:' .claude/commands/cig-*.md` returns results
- New file inconsistent with existing 8 workflow files

**Resolution**:
1. Identify file with markdown headers
2. Convert each `### Step N: Name` to `N. **Name**:` format
3. Add blank line after each main step header
4. Run validation checks to confirm fix
5. Reference `.claude/commands/cig-plan.md` lines 30-100 as canonical example

**Recovery Time**: 5-10 minutes

---

**Issue 2: Sub-steps restart numbering at "1." within parent steps**

**Symptoms**:
- Multiple occurrences of `1. **` in a single workflow file
- Ambiguity when referencing sub-steps (e.g., "See step 1" could mean multiple things)

**Resolution**:
1. Identify parent step containing sub-steps
2. Convert sub-step numbering from `1., 2., 3.` to `N.1., N.2., N.3.` (where N is parent step number)
3. Update any cross-references to use hierarchical notation
4. Run validation to ensure only one `1. **` exists (top-level Step 1)
5. Reference `.claude/commands/cig-retrospective.md` lines 42-159 as canonical example

**Recovery Time**: 10-15 minutes per file

---

**Issue 3: Modified workflow file breaks numbering consistency**

**Symptoms**:
- Git diff shows changes to step numbering format
- Validation checks fail or return unexpected counts
- Mix of markdown headers and numbered lists in same file

**Resolution**:
1. Review git diff to identify problematic changes
2. Determine if change was intentional or accidental
3. If accidental: revert to numbered list format
4. If intentional: discuss with team to understand rationale
5. Run validation suite to confirm consistency restored

**Recovery Time**: 5-20 minutes depending on extent of changes

### Escalation Procedures

**Level 1 - Self-Service** (Documentation user):
- Review Task 24 implementation files for canonical examples
- Run validation checks locally
- Reference cig-plan.md and cig-retrospective.md for patterns

**Level 2 - Maintainer Review** (CIG system maintainer):
- Investigate reported inconsistencies
- Apply fixes following Task 24 patterns
- Update documentation if pattern needs clarification

**Level 3 - Design Discussion** (CIG system architect):
- Discuss if numbering pattern needs modification
- Evaluate alternative numbering schemes if current pattern has limitations
- Create new task for substantial numbering system changes

## Performance Optimisation

**Not Applicable**: Documentation files are small (~10KB each) and loaded at Claude Code startup. No performance optimisation needed.

**Scalability Considerations**:
- If workflow command count grows beyond 20 files, consider automated validation in CI/CD
- If numbering pattern becomes complex, consider documentation generator tool
- Current manual validation sufficient for 8 core workflow files

## Documentation

### Runbooks

**Runbook: Validate Workflow Numbering Consistency**

```bash
#!/bin/bash
# Validate all workflow files follow hierarchical numbering pattern

echo "=== Checking numbered list format ==="
echo "Expected: Each file should have multiple numbered steps"
grep -E '^\s*[0-9]+\. \*\*' .claude/commands/cig-*.md | wc -l

echo ""
echo "=== Checking for markdown headers (should be 0) ==="
echo "Expected: No results (0 markdown headers)"
grep -E '^###\s+Step [0-9]+:' .claude/commands/cig-*.md || echo "✓ No markdown headers found"

echo ""
echo "=== Checking hierarchical sub-steps ==="
echo "Expected: 12 hierarchical sub-steps in cig-retrospective.md"
grep -E '^\s*[0-9]+\.[0-9]+\. \*\*' .claude/commands/cig-retrospective.md | wc -l

echo ""
echo "=== Validation Complete ==="
```

**Usage**: Run quarterly or after workflow file modifications

---

**Runbook: Fix Workflow File with Markdown Headers**

```bash
#!/bin/bash
# Convert markdown headers to numbered list format
# Usage: ./fix-headers.sh <workflow-file>

FILE="$1"

if [ -z "$FILE" ]; then
    echo "Usage: $0 <workflow-file>"
    exit 1
fi

echo "Converting markdown headers in $FILE..."

# Backup original
cp "$FILE" "$FILE.backup"

# Convert ### Step N: Name to N. **Name**:
# This is a template - actual conversion requires manual review
# Use Edit tool in Claude Code for precise control

echo "Manual conversion required:"
echo "1. Find: ### Step N: Name"
echo "2. Replace: N. **Name**:"
echo "3. Add blank line after each main step"
echo "4. Reference Task 24 for canonical examples"
```

**Usage**: Follow manual process when markdown headers detected

### Knowledge Base

**Reference Documentation**:
- **Canonical Examples**:
  - Main step format: `.claude/commands/cig-plan.md` lines 30-100
  - Hierarchical sub-steps: `.claude/commands/cig-retrospective.md` lines 42-159
- **Task 24 Implementation**: `implementation-guide/24-chore-use-hierarchical-numbering-for-sub-steps-in-workf/d-implementation.md`
- **Task 24 Testing**: `implementation-guide/24-chore-use-hierarchical-numbering-for-sub-steps-in-workf/e-testing.md`

**Numbering Patterns**:
- **Main steps**: `N. **Step Name**:` (e.g., `1. **Resolve Task Directory**:`)
- **Sub-steps**: `N.M. **Sub-step Name**:` (e.g., `2.1. **Check current branch**:`)
- **Nested lists**: Decomposition signals within Step 7 use `1., 2., 3.` (contained context, non-ambiguous)

**Design Rationale**:
- Hierarchical numbering eliminates ambiguity when referencing sub-steps
- Consistent format across all 8 workflow files improves usability
- Numbered list format renders consistently in markdown viewers
- Pattern scales to arbitrary nesting depth (N.M.P.Q if needed)

## Success Criteria

### Monitoring Success
- [x] Validation checks defined (3 checks in bash script)
- [x] Alert/response procedures documented (3 common issues)
- [x] Expected metric values specified

### Maintenance Success
- [x] Quarterly audit procedure defined
- [x] Event-driven maintenance tasks specified
- [x] Validation suite automated in bash script

### Documentation Success
- [x] Runbooks created (2 runbooks: validation, header fix)
- [x] Knowledge base established (canonical examples, patterns, rationale)
- [x] Escalation procedures defined (3 levels)

### Incident Response Success
- [x] Common issues documented (3 issues with symptoms and resolutions)
- [x] Recovery times estimated (5-20 minutes depending on issue)
- [x] Troubleshooting guides provided

## Status
**Status**: Finished
**Next Action**: Proceed to retrospective phase with `/cig-retrospective 24`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
