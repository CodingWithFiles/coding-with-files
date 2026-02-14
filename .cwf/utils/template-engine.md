# CWF Template Engine

## Purpose
Generate implementation guide documents from templates with variable substitution.

## Template Variable Syntax
Use `{{variable}}` format for substitution:
- `{{taskId}}` - Task ID (e.g., JIRA-1234, #567)
- `{{taskUrl}}` - Generated URL from task-management config
- `{{parentTask}}` - Parent task reference for subtasks
- `{{branchName}}` - Suggested git branch name
- `{{projectName}}` - From cwf-project.json
- `{{taskType}}` - feature|bugfix|hotfix|chore
- `{{description}}` - Human-readable task description

## Task Reference Template
```markdown
## Task Reference
- **Task ID**: {{taskId}}
- **Task URL**: {{taskUrl}}
- **Parent Task**: {{parentTask}}
- **Branch**: {{branchName}}
```

## Universal Tracking Sections
Include in all templates:
- `## Original Estimate` - Initial planning estimates
- `## Goal` - Single sentence objective  
- `## Success Criteria` - Measurable outcomes
- `## Current Status` - Progress tracking
- `## Actual Results` - Post-completion actuals
- `## Lessons Learned` - Key insights and variances

## File Naming Convention
- Prefer lowercase filenames (e.g., `plan.md`, `requirements.md`)
- Exception: Language-specific requirements (e.g., `README.md`, `Makefile`)

## Document Linking
Reference sections for grep/sed compatibility:
- Format: "See design.md 'Architecture Overview' section"
- Enables: `awk '/^## Architecture Overview/{p=1; print; next} p && /^## [^#]/{p=0} p' design.md`