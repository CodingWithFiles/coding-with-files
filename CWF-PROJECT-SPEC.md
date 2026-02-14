# CWF Project Configuration Specification

## Goal

Define the complete schema and usage specifications for the `cwf-project.json` configuration file that enables CWF system integration with project toolchains.

## File Location

The `cwf-project.json` file must be located at:
```
<git-root>/implementation-guide/cwf-project.json
```

## Schema Definition

### Root Object

```json
{
  "title": "string",
  "version": "string", 
  "cwf-version": "string",
  "project": { ... },
  "source-management": { ... },
  "task-management": { ... },
  "supported-task-types": [ ... ],
  "team": { ... },
  "templates": { ... }
}
```

### Field Specifications

#### `title` (required)
- **Type**: String
- **Purpose**: Human-readable project configuration title
- **Example**: `"Coding with Files Project Configuration"`

#### `version` (required)
- **Type**: String (semver)
- **Purpose**: Version of this specific project's configuration
- **Example**: `"1.0.0"`

#### `cwf-version` (required)
- **Type**: String (semver)
- **Purpose**: CWF system version this configuration targets
- **Example**: `"0.1.0"`
- **Usage**: Tells Claude Code which CWF features are available

#### `project` (required)
```json
{
  "name": "string",
  "description": "string"
}
```
- **`name`**: Project display name
- **`description`**: Brief project description

#### `source-management` (required)
```json
{
  "type": "github|gitlab|bitbucket|other",
  "url": "string",
  "branch-naming-convention": "string"
}
```
- **`type`**: Source control platform identifier
- **`url`**: Base URL for repository
- **`branch-naming-convention`**: Template for branch naming (supports `{task-type}`, `{task-id}`, `{task-description}`)

#### `task-management` (required)
```json
{
  "type": "github|jira|monday|linear|other",
  "url": "string", 
  "task-id-template": "string",
  "examples": { ... }
}
```
- **`type`**: Task management system identifier
- **`url`**: Base URL for task system
- **`task-id-template`**: Regex pattern for valid task IDs
- **`examples`**: Object with example task IDs for different task types

##### Task ID Template Patterns
- **GitHub**: `"#[::digit::]{1,}"`
- **Jira**: `"[::upper::]{2,10}-[::digit::]{1,}"`
- **Linear**: `"[::upper::]{2,5}-[::digit::]{1,}"`
- **Monday.com**: `"PULSE-[::digit::]{1,}"`

#### `supported-task-types` (required)
```json
["feature", "bugfix", "hotfix", "chore", "docs", "refactor", "test"]
```
- **Type**: Array of strings
- **Purpose**: Task types this project supports
- **Standard Types**: `feature`, `bugfix`, `hotfix`, `chore`
- **Optional Types**: `docs`, `refactor`, `test`, `style`, `ci`, `build`

#### `team` (optional)
```json
{
  "default-assignee": "string",
  "reviewers": ["string", ...]
}
```
- **`default-assignee`**: Default task assignee username/email
- **`reviewers`**: Array of reviewer usernames/emails

#### `templates` (optional)
```json
{
  "task-reference-format": "standard|custom",
  "branch-name-max-length": "number",
  "auto-generate-branch-suggestions": "boolean"
}
```
- **`task-reference-format`**: Task Reference section format preference
- **`branch-name-max-length`**: Maximum characters for generated branch names
- **`auto-generate-branch-suggestions`**: Whether to suggest branch names

## Configuration Examples

### GitHub + GitHub Issues
```json
{
  "title": "Coding with Files Project Configuration",
  "version": "1.0.0",
  "cwf-version": "0.1.0",
  "project": {
    "name": "My Project",
    "description": "Project using GitHub for everything"
  },
  "source-management": {
    "type": "github",
    "url": "https://github.com/company/project",
    "branch-naming-convention": "{task-type}/{task-id}-{task-description}"
  },
  "task-management": {
    "type": "github",
    "url": "https://github.com/company/project/issues",
    "task-id-template": "#[::digit::]{1,}",
    "examples": {
      "issue": "#123",
      "pull-request": "#456"
    }
  },
  "supported-task-types": ["feature", "bugfix", "hotfix", "chore"]
}
```

### GitLab + Jira
```json
{
  "title": "Enterprise Project Configuration", 
  "version": "1.0.0",
  "cwf-version": "0.1.0",
  "project": {
    "name": "E-commerce Platform",
    "description": "Main customer-facing platform"
  },
  "source-management": {
    "type": "gitlab",
    "url": "https://gitlab.company.com/ecommerce/platform",
    "branch-naming-convention": "{task-type}/{task-id}-{task-description}"
  },
  "task-management": {
    "type": "jira",
    "url": "https://company.atlassian.net/browse",
    "task-id-template": "[::upper::]{2,10}-[::digit::]{1,}",
    "examples": {
      "story": "ECOM-1234",
      "bug": "ECOM-5678", 
      "epic": "ECOM-100"
    }
  },
  "supported-task-types": ["feature", "bugfix", "hotfix", "chore", "docs"],
  "team": {
    "default-assignee": "dev-team@company.com",
    "reviewers": ["senior-dev@company.com", "tech-lead@company.com"]
  },
  "templates": {
    "task-reference-format": "standard",
    "branch-name-max-length": 50,
    "auto-generate-branch-suggestions": true
  }
}
```

## Usage in CWF Commands

### `/cwf-init`
- Creates initial `cwf-project.json` with template values
- Prompts user to configure task management and source control settings

### `/cwf-new-task`
- Reads `task-id-template` to validate provided task IDs
- Uses `branch-naming-convention` to suggest branch names
- Constructs task URLs using `task-management.url` + task ID
- Validates task type against `supported-task-types`

### Task Reference Generation
Uses configuration to populate Task Reference sections:
```markdown
## Task Reference
- **Task ID**: JIRA-1234
- **Task URL**: https://company.atlassian.net/browse/JIRA-1234
- **Parent Task**: JIRA-1200 - User Management System
- **Branch**: feature/JIRA-1234-user-authentication
```

## Validation Rules

1. **Required Fields**: `title`, `version`, `cwf-version`, `project`, `source-management`, `task-management`, `supported-task-types`
2. **Version Format**: Must follow semantic versioning (e.g., "1.0.0")
3. **URL Format**: Must be valid HTTP/HTTPS URLs
4. **Task Types**: Must include at least `["feature", "bugfix", "hotfix"]`
5. **Task ID Template**: Must be valid regex pattern
6. **Branch Convention**: Must include `{task-type}` placeholder

## Integration Benefits

✅ **Tool Agnostic**: Works with any task management and source control combination  
✅ **URL Generation**: Automatic task and PR URL construction  
✅ **Validation**: Task ID format validation against project standards  
✅ **Team Standards**: Consistent configuration across team members  
✅ **Extensible**: Easy to add new platforms and task types