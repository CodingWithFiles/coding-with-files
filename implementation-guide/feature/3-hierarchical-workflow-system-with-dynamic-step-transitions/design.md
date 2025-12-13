# Hierarchical Workflow System with Dynamic Step Transitions - Design

## Task Reference
- **Task ID**: internal-3
- **Type**: Feature
- **Status**: Not Started

## Architecture Overview

This design implements a hierarchical task management system with infinite nesting, structured workflow steps, and intelligent state transitions. See `/home/matt/repo/code-implementation-guide/scratchpad.md` for complete design rationale.

**Key Architectural Patterns**:
- **Central Template Pool** (FR15): Single source of truth with symlinks for DRY and consistency
- **Progressive Disclosure** (FR12, FR14): Commands reference documentation instead of duplicating content
- **LLM-in-the-Loop** (FR8): Helper scripts automate deterministic tasks, LLM provides intelligence
- **Status-Driven Transitions** (FR2.4): Standardized status markers enable dynamic workflow decisions
- **Content Guidance** (FR11): Clear focus/avoid guidelines for each workflow step
- **Template Versioning** (FR15.5): Parseable version field for backward compatibility
- **Backward Compatibility** (FR9): Both old and new formats supported indefinitely

## Core Components

### 1. Directory Structure

**New Format**: `<num>-<type>-<slug>/`

```
implementation-guide/
├── 1-feature-real-time-collaboration/
│   ├── a-plan.md
│   ├── b-requirements.md
│   ├── c-design.md
│   ├── d-implementation.md
│   ├── e-testing.md
│   ├── f-rollout.md
│   ├── g-maintenance.md
│   ├── h-retrospective.md
│   └── 1.1-feature-websocket-messaging/
│       ├── a-plan.md
│       └── 1.1.1-chore-connection-pool/
│           └── d-implementation.md
└── 2-chore-update-dependencies/
    └── a-plan.md
```

**Key Design Decisions**:
- Flat top-level (no `feature/`, `bugfix/` directories)
- Type embedded in name for visibility
- Decimal numbering shows hierarchy instantly
- Lettered workflow files prevent conflicts with numbered subtasks

### 2. Workflow Files (Lettered)

**Eight standardised steps** (optional, create as needed):

| File | Purpose | When to Use |
|------|---------|-------------|
| `a-plan.md` | Goals, milestones, estimates | All tasks |
| `b-requirements.md` | Functional/non-functional specs | Features, complex changes |
| `c-design.md` | Architecture, API contracts | Features, architectural changes |
| `d-implementation.md` | Code implementation | All tasks |
| `e-testing.md` | Test strategy, execution | All tasks |
| `f-rollout.md` | Deployment, validation | Production changes |
| `g-maintenance.md` | Operational procedures | Long-lived features |
| `h-retrospective.md` | Lessons learned | All completed tasks |

**Status Markers** (FR2.4):
Each workflow file includes standardised status markers enabling dynamic workflow transitions:
- Minimum types: `Backlog`, `To-Do`, `In Progress`, `Implemented`, `Testing`, `Finished`
- Format: `## Status: <status-type>` or `**Status**: <status-type>`
- Parseable by helper scripts and workflow commands
- Additional project-specific status types permitted

### 3. Command Architecture

#### Task Creation Commands

**`/cig-new-task <num> <type> "description"`** (FR3, FR11, FR12)

**⚠️ Breaking Change**: Old signature `<task-type> [task-id] <description>` → New signature `<num> <type> "description"`

**Functionality**:
- Creates: `implementation-guide/<num>-<type>-<slug>/`
- Populates templates based on type from central pool (via symlinks - see Template Selection below)
- Adds task reference section with Template Version field (2.0 for new format)
- Includes workflow file content guidance (focus/avoid for each file type)
- References workflow system documentation
- Suggests git branch
- **UI Enhancement**: Command frontmatter includes `argument-hint` field showing new signature

**`/cig-subtask <parent-path> <num> <type> "description"`** (FR3, FR12)
- Resolves parent directory using hierarchy-resolver.sh
- Creates: `<parent>/<num>-<type>-<slug>/`
- Inherits context from parent
- Validates hierarchical numbering
- **Progressive Disclosure**: References `.claude/commands/cig-new-task.md` for shared details
- Does not duplicate template population logic or content guidance
- **UI Enhancement**: Command frontmatter includes `argument-hint` field showing hierarchical signature

#### Workflow Commands (8 new)

Each command follows this pattern:

```bash
/cig-<step> <task-path>
```

**Command Structure** (FR4, FR11, FR14):
1. Resolve task directory from path using helper scripts
2. Load parent context structural map (if exists) via context-inheritance.pl
3. Present context summary with navigable links and status markers
4. LLM decides which parent sections to read in detail using Read tool
5. Reference relevant workflow step documentation from `.cig/docs/workflow/`
6. Execute step-specific workflow with focus/avoid guidelines
7. Check decomposition signals (universal decomposition)
8. Suggest next steps with reasoning (dynamic workflow transitions)

**Implementation**: `.claude/commands/cig-<step>.md`
**UI Enhancement**: Each command has `argument-hint` frontmatter field

**Content Guidance Example** (FR11.5):

Each workflow command provides focus/avoid guidance. Example for `/cig-plan`:

```markdown
## Workflow Step: a-plan.md

**Focus** (what belongs here):
- Goals and success criteria
- Milestones and timeline estimates
- Risk assessment and mitigation strategies
- High-level approach and constraints
- Dependencies and assumptions

**Avoid** (what belongs elsewhere):
- Detailed requirements (→ b-requirements.md)
- Architecture diagrams or API specs (→ c-design.md)
- Code snippets or implementation details (→ d-implementation.md)
- Test plans (→ e-testing.md)
```

#### Template Selection by Task Type (FR15.6-15.7)

**Selection Mechanism**: Template selection is determined by which symlinks exist in each task type directory. Task creation commands copy all templates for which symlinks are present.

**Symlink Configuration Specification**:

Different task types have different symlinks to reflect their workflow needs:

| Task Type | Symlinks Present | Rationale |
|-----------|------------------|-----------|
| **feature** | All 8 (a-h) | Features require full workflow: planning, requirements, design, implementation, testing, rollout, maintenance, retrospective |
| **bugfix** | a, c, d, e, h | Bugs need: plan (reproduction), design (root cause), implementation, testing, retrospective. Skip requirements (already defined) and rollout (typically hotfix process) |
| **hotfix** | a, d, e, f, h | Critical fixes: plan (minimal), implementation, testing, rollout (emergency deploy), retrospective. Skip requirements/design (no time), skip maintenance (emergency) |
| **chore** | a, d, e, h | Maintenance tasks: plan, implementation, testing, retrospective. Skip requirements/design (technical not user-facing), skip rollout/maintenance (not production features) |

**Implementation Details**:
- `.cig/templates/feature/` contains symlinks to all 8 pool templates
- `.cig/templates/bugfix/` contains symlinks to 5 pool templates (a, c, d, e, h)
- `.cig/templates/hotfix/` contains symlinks to 5 pool templates (a, d, e, f, h)
- `.cig/templates/chore/` contains symlinks to 4 pool templates (a, d, e, h)
- Task creation commands copy templates based on which symlinks exist
- Workflow documentation (`.cig/docs/workflow/`) explains rationale for each task type's template selection

**Validation**: Testing phase verifies symlink configuration matches specification (see AC3.5).

#### Extract Command Refactoring (FR8.6-8.9)

**`/cig-extract <task-path> <section-name>`**

**New Architecture**:
- Task-based paths instead of file paths: `/cig-extract 1/1.1 goal`
- Helper script integration with LLM intelligence
- Backward compatibility with full file paths during migration

**Data Flow**:
1. **Helper Scripts** (automation layer):
   - `hierarchy-resolver.sh` resolves task path → full directory path
   - `format-detector.sh` determines old vs new format
   - Map section name to correct file (e.g., "goal" → a-plan.md or plan.md)
2. **LLM** (intelligence layer):
   - Receives helper script output
   - Extracts section content from resolved file
   - Detects corrupted/badly edited files
   - Provides meaningful error messages and recovery suggestions
   - Diagnoses structural issues in task files

**Section Name Mapping**:
- Deterministic mapping based on template structure
- Common sections: goal, requirements, design, implementation, testing, rollout, maintenance, retrospective
- Case-insensitive matching for user convenience
- Works with both old and new formats

**Design Rationale**: Keeps LLM in the loop for intelligent error handling while automating deterministic path resolution.

#### Status Command (FR8.1-8.5)

**`/cig-status [<task-path>]`**

**Functionality**:
- No path: Shows tree view of all tasks in `implementation-guide/`
- With path: Shows specified task and all descendants

**Visual Output** (Markdown tree):
```
implementation-guide/
├── 1-feature-real-time-collaboration (50% - Implemented) ⚙️
│   ├── 1.1-feature-websocket-messaging (25% - In Progress) ⚙️
│   │   └── 1.1.1-chore-connection-pool (100% - Finished) ✓
│   └── 1.2-bugfix-connection-timeout (0% - Backlog) ○
├── 2-chore-update-dependencies (75% - Testing) ⚙️
└── 3-feature-hierarchical-workflow (25% - In Progress) ⚙️
```

**Status Indicators**:
- `✓` - Finished (100%)
- `⚙️` - In Progress (25%, 50%, 75%)
- `○` - Not Started (0% - Backlog or To-Do)

**Data Flow**:
1. Resolve task path using `hierarchy-resolver.sh` (if path provided)
2. Call `status-aggregator.sh <task-path>` to get progress data
3. Parse markdown output from status-aggregator.sh
4. Add visual tree structure with indentation
5. Add status indicators based on progress percentage
6. Display to user

**Tree Rendering Logic**:
- Each hierarchy level indented by 2 spaces and tree characters (`├──`, `└──`)
- Task format: `<num>-<type>-<slug> (<progress>% - <status>) <indicator>`
- Alphabetical sort within each level (natural numeric sort)
- Maximum depth: Unlimited (follows actual task structure)

**Design Rationale**: Delegates progress calculation to `status-aggregator.sh` helper script, focuses command logic on presentation and tree rendering.

### 4. Context Inheritance System

**Helper Script**: `.cig/scripts/command-helpers/context-inheritance.pl`

**Functionality**:
```bash
context-inheritance.pl <task-path>
```

**Purpose**: Provides **structural map** of parent task context with **navigable links** and **status markers**, enabling token-efficient context discovery where LLM decides what details to read.

**Workflow Files Extracted**:
- `a-plan.md` (or `plan.md` for old format)
- `b-requirements.md` (or `requirements.md` for old format)
- `c-design.md` (or `design.md` for old format)
- `d-implementation.md` (or `implementation.md` for old format)

**Outputs** (markdown with headers, line ranges, status markers):
```markdown
## Parent Context

### Parent: 1.1-feature-websocket-messaging

**a-plan.md** [Status: Finished] (`implementation-guide/1.1-feature-websocket-messaging/a-plan.md`):
- Goal (L10-25, Read: offset=10 limit=15)
- Success Criteria (L27-45, Read: offset=27 limit=18)
- Milestones (L47-68, Read: offset=47 limit=21)

**b-requirements.md** [Status: Finished] (`implementation-guide/1.1-feature-websocket-messaging/b-requirements.md`):
- FR1: Connection Pooling (L12-34, Read: offset=12 limit=22)
- FR2: Message Queuing (L36-58, Read: offset=36 limit=22)

**c-design.md** [Status: In Progress] (`implementation-guide/1.1-feature-websocket-messaging/c-design.md`):
- Architecture Overview (L15-42, Read: offset=15 limit=27)

### Grandparent: 1-feature-real-time-collaboration

**a-plan.md** [Status: Finished] (`implementation-guide/1-feature-real-time-collaboration/a-plan.md`):
- Goal (L10-28, Read: offset=10 limit=18)
- Success Criteria (L30-52, Read: offset=30 limit=22)
```

**Key Benefits**:
- **Token efficiency**: ~50-100 tokens per parent vs 500-1000 for full files
- **LLM agency**: Structural map lets LLM decide what to read in detail
- **Status awareness**: Completion state indicates reliability of parent context
- **Direct navigation**: Read parameters (offset/limit) provided for each section

### 5. Universal Decomposition System

**Signals** (implemented in each workflow command):

1. **Time**: >1 week for step, >1 month for subtask
2. **People**: >2 people needed
3. **Complexity**: 3+ distinct concerns
4. **Risk**: High risk requiring isolation
5. **Independence**: Parts can work separately

**Pattern** (in command prompts):
```markdown
## Decomposition Check

After initial analysis, check these signals:
- [ ] Time: Would this step take >1 week?
- [ ] People: Would >2 people work on different parts?
- [ ] Complexity: Are there 3+ distinct concerns?
- [ ] Risk: Does this require isolated validation?
- [ ] Independence: Can parts be worked on separately?

IF 2+ signals true:
  SUGGEST: Create subtasks before proceeding
  PROVIDE: Specific subtask breakdown
  ASK: User choice (decompose vs continue)
```

### 6. Dynamic Workflow Transitions

**State Machine** (implemented in each workflow command):

```
After completing step X:
1. Analyse outcome
2. Determine next state
3. Suggest primary path
4. Offer alternatives
5. Explain reasoning
```

**Example** (in `/cig-testing` command):

```markdown
## After Testing

Analyse test results and suggest next steps:

IF all tests pass:
  IF needs deployment:
    → Primary: /cig-rollout <task>
  ELSE:
    → Primary: /cig-retrospective <task>

ELSE IF tests fail (simple bug):
  → Primary: /cig-implementation <task>
  → Reason: Standard debugging

ELSE IF tests fail (design flaw):
  → Primary: /cig-design <task>
  → Reason: Architecture needs rethinking

ELSE IF tests fail (complex bug):
  → Primary: /cig-subtask <parent> <num> bugfix "..."
  → Alternative: Continue in current task
```

### 7. Backward Compatibility

**Detection Logic**:

```bash
# In each command
if [[ -f "$task_dir/a-plan.md" ]]; then
  format="new"
  files=("a-plan" "b-requirements" "c-design" "d-implementation"
         "e-testing" "f-rollout" "g-maintenance" "h-retrospective")
else
  format="old"
  files=("plan" "requirements" "design" "implementation"
         "testing" "rollout" "maintenance")
fi
```

**Support Matrix**:

| Operation | Old Format | New Format |
|-----------|------------|------------|
| Read tasks | ✓ | ✓ |
| Create tasks | ✓ (legacy mode) | ✓ |
| Status display | ✓ | ✓ |
| Extraction | ✓ | ✓ |
| Subtasks | ✗ | ✓ |

## File Structure

### Workflow Templates (FR15)

**Central Pool Architecture** - Single source of truth with symlinks:

**Pool Location**: `.cig/templates/pool/`

```
.cig/templates/pool/
├── a-plan.md.template
├── b-requirements.md.template
├── c-design.md.template
├── d-implementation.md.template
├── e-testing.md.template
├── f-rollout.md.template
├── g-maintenance.md.template
└── h-retrospective.md.template
```

**Symlink Structure** (DRY + Consistency):

```
.cig/templates/
├── pool/                          # Central templates
│   └── a-plan.md.template         # Single source of truth
├── feature/
│   └── a-plan.md.template → ../pool/a-plan.md.template  # Symlink
├── bugfix/
│   └── a-plan.md.template → ../pool/a-plan.md.template  # Symlink
├── hotfix/
│   └── a-plan.md.template → ../pool/a-plan.md.template  # Symlink
└── chore/
    └── a-plan.md.template → ../pool/a-plan.md.template  # Symlink
```

**Template Content** (each template):
- Task Reference section with metadata fields
- **Template Version** field (format: `**Template Version**: X.Y`)
  - New hierarchical workflow templates: version 2.0
  - Old format templates: version 1.0 (default if field missing)
  - Parseable by helper scripts via: `grep "^\- \*\*Template Version\*\*:" <file>`
- Step-specific structure appropriate for that workflow step
- Guidance comments explaining what belongs in each section
- Status marker section with standardised status types
- Status tracking checkboxes where appropriate

**Template Benefits**:
- **DRY**: Update once in pool, affects all task types
- **Consistency**: All task types use identical templates for each step
- **Maintainability**: Clear separation between content (pool) and usage (symlinks)
- **Progressive Disclosure**: References to workflow documentation instead of inline duplication

**Template Foundation** (FR15.2.1):
- Based on existing templates in `.cig/templates/<type>/`
- Adapts existing structure to new format requirements
- Preserves proven patterns and sections
- New requirements override existing content where conflicts exist

### Workflow Documentation (FR14)

**Location**: `.cig/docs/workflow/`

**Purpose**: Explains why and how the hierarchical workflow system works (NOT templates)

```
.cig/docs/workflow/
├── workflow-overview.md       # System overview and principles
├── workflow-steps.md          # Detailed step-by-step guide
└── decomposition-guide.md     # When and how to create subtasks
```

**Documentation Content**:
- Purpose of each workflow step (a-plan through h-retrospective)
- When to use each workflow step
- Focus/Avoid guidelines for each step
- Universal decomposition principle and "too big" signals
- Dynamic workflow transitions (non-linear flow)
- Hierarchical task structure rationale

**Documentation Format**:
- Concise and LLM-friendly (~100-300 words per workflow step)
- Clear enough for LLM to follow workflow commands
- Brief enough to avoid wasting token context
- Referenced by task creation and workflow commands (progressive disclosure)

### Commands

**Location**: `.claude/commands/`

```
.claude/commands/
├── cig-new-task.md (updated)
├── cig-subtask.md (new)
├── cig-plan.md (new)
├── cig-requirements.md (new)
├── cig-design.md (new)
├── cig-implementation.md (new)
├── cig-testing.md (new)
├── cig-rollout.md (new)
├── cig-maintenance.md (new)
├── cig-retrospective.md (new)
├── cig-status.md (updated)
└── cig-extract.md (updated)
```

### Helper Scripts (FR13)

**Location**: `.cig/scripts/command-helpers/`

```
.cig/scripts/command-helpers/
├── context-inheritance.pl (new - Perl for text processing)
├── hierarchy-resolver.sh (new)
├── format-detector.sh (new)
├── status-aggregator.sh (new)
└── template-version-parser.sh (new)
```

**Script Requirements**:
- **Permissions**: Minimum 0500 (u+rx - readable and executable by owner)
- **Verification**: SHA256 hashes verified via `/cig-security-check`
- **Self-Documenting**: Header comments with purpose, usage, version
- **Template Version Parsing** (FR13.9):
  - Scripts parse `**Template Version**` field from task files when needed
  - Pattern: `grep "^\- \*\*Template Version\*\*:" <file>`
  - Default to version 1.0 if field is missing (backward compatibility)

## Data Flow

### Creating Hierarchical Task

```
User: /cig-subtask 1 1.1 feature "WebSocket messaging"
  ↓
Command resolves: 1 → implementation-guide/1-feature-real-time-collaboration/
  ↓
Creates: implementation-guide/1-feature-real-time-collaboration/1.1-feature-websocket-messaging/
  ↓
Copies templates: a-plan.md, b-requirements.md, etc.
  ↓
Populates task reference with parent context
  ↓
Suggests: /cig-plan 1/1.1 to start planning
```

### Workflow Execution with Context

```
User: /cig-requirements 1/1.1/1.1.1
  ↓
Resolve path: 1/1.1/1.1.1 → .../1.1.1-chore-connection-pool/
  ↓
Read parent context:
  - 1/a-plan.md, 1/b-requirements.md, 1/c-design.md
  - 1/1.1/a-plan.md, 1/1.1/b-requirements.md
  - 1/1.1/1.1.1/a-plan.md
  ↓
Present context summary to Claude
  ↓
Execute requirements gathering
  ↓
Check decomposition signals
  ↓
Suggest next step based on outcome
```

## API Contracts

### Helper Script: context-inheritance.pl

**Implementation**: Perl-based script for efficient text processing and header extraction

**Input**:
```bash
context-inheritance.pl "<task-path>"
```
Example: `context-inheritance.pl "1/1.1/1.1.1"`

**Purpose**: Provide **structural map** of parent task context with **navigable links**, letting the LLM decide what details to read.

**Algorithm**:
1. Recursive upward search from task directory to project root
2. Find parent task directories (pattern: `<num>-<type>-<slug>/`)
3. For each parent, find workflow files deterministically:
   - New format: `a-plan.md`, `b-requirements.md`, `c-design.md`, `d-implementation.md`
   - Old format: `plan.md`, `requirements.md`, `design.md`, `implementation.md`
4. Extract document structure via `grep -n '^#+ ' file.md` to get headers with line numbers
5. Calculate section boundaries:
   - Start: The header line itself
   - End: Line before next header of same/higher level, or EOF
6. Parse status markers from each file:
   - Patterns: `## Status: <status-type>` or `**Status**: <status-type>`
   - Default to "Unknown" if no status marker found
7. Output markdown with file paths, status, headers, line ranges, and Read tool parameters

**Output** (markdown to stdout):
```markdown
## Parent Context

### Parent: 1.1-feature-websocket-messaging

**a-plan.md** [Status: Finished] (`implementation-guide/1.1-feature-websocket-messaging/a-plan.md`):
- Goal (L10-25, Read: offset=10 limit=15)
- Success Criteria (L27-45, Read: offset=27 limit=18)
- Milestones (L47-68, Read: offset=47 limit=21)

**b-requirements.md** [Status: Finished] (`implementation-guide/1.1-feature-websocket-messaging/b-requirements.md`):
- FR1: Connection Pooling (L12-34, Read: offset=12 limit=22)
- FR2: Message Queuing (L36-58, Read: offset=36 limit=22)
- NFR1: Performance (L60-78, Read: offset=60 limit=18)

**c-design.md** [Status: In Progress] (`implementation-guide/1.1-feature-websocket-messaging/c-design.md`):
- Architecture Overview (L15-42, Read: offset=15 limit=27)
- Component Design (L44-89, Read: offset=44 limit=45)

**d-implementation.md** [Status: Not Started] (`implementation-guide/1.1-feature-websocket-messaging/d-implementation.md`):
- Files to Modify (L15-35, Read: offset=15 limit=20)

### Grandparent: 1-feature-real-time-collaboration

**a-plan.md** [Status: Finished] (`implementation-guide/1-feature-real-time-collaboration/a-plan.md`):
- Goal (L10-28, Read: offset=10 limit=18)
- Success Criteria (L30-52, Read: offset=30 limit=22)

**b-requirements.md** [Status: Finished] (`implementation-guide/1-feature-real-time-collaboration/b-requirements.md`):
- FR1: Real-time Updates (L15-45, Read: offset=15 limit=30)
- FR2: User Presence (L47-68, Read: offset=47 limit=21)
```

**Benefits**:
- **Token efficient**: Only headers (~50-100 tokens per parent vs 500-1000 tokens full file)
- **LLM agency**: LLM sees structure, decides what to Read in detail
- **Precise navigation**: offset/limit parameters work directly with Read tool
- **Deterministic discovery**: Script reliably finds all parents
- **Flexible**: LLM can read 1 section or all sections as needed
- **Context awareness**: Status markers indicate completion state of parent work
- **Reduced surprises**: LLM knows what's done vs planned, avoiding implementation confusion

**Status Parsing Logic** (Perl):
```perl
# Parse status from workflow file
# Patterns from FR2.4: `## Status: <status-type>` or `**Status**: <status-type>`
sub parse_status {
    my ($file_path) = @_;
    open(my $fh, '<', $file_path) or return "Unknown";

    while (my $line = <$fh>) {
        # Match: ## Status: Finished  OR  **Status**: Finished
        if ($line =~ /^##\s+Status:\s+(.+)$/i ||
            $line =~ /\*\*Status\*\*:\s+(.+)$/i) {
            close($fh);
            return trim($1);
        }
    }
    close($fh);
    return "Unknown";  # No status marker found
}
```

**Header Level Parsing** (Perl):
```perl
# Parse markdown headers and calculate section boundaries
sub extract_sections {
    my ($file_path) = @_;
    my @sections;
    my @lines = `grep -n '^#+ ' "$file_path"`;

    for (my $i = 0; $i < @lines; $i++) {
        my ($line_num, $header) = split(/:/, $lines[$i], 2);
        my ($level) = ($header =~ /^(#+)/);
        my $level_count = length($level);

        # Calculate end line (before next same/higher level header or EOF)
        my $end_line;
        if ($i < $#lines) {
            my ($next_line) = split(/:/, $lines[$i+1]);
            $end_line = $next_line - 1;
        } else {
            $end_line = get_file_line_count($file_path);
        }

        my $limit = $end_line - $line_num;
        push @sections, {
            header => trim($header),
            start => $line_num,
            end => $end_line,
            offset => $line_num,
            limit => $limit
        };
    }

    return @sections;
}
```

**Exit codes**:
- 0: Success
- 1: Invalid task path
- 2: Task not found
- 3: No parent tasks found (top-level task)

**Design Rationale**:
- **Perl over Bash**: Better text processing, regex, and data structures for this parsing task
- **Headers not content**: Structural map lets LLM decide what to read in detail
- **Status markers**: Critical context about completion state of parent work
- **Line ranges**: Direct integration with Read tool's offset/limit parameters
- **LLM-in-the-loop pattern**: Script automates discovery/extraction, LLM provides intelligence

### Helper Script: hierarchy-resolver.sh

**Input**:
```bash
hierarchy-resolver.sh "1/1.1"
```

**Output** (JSON to stdout):
```json
{
  "full_path": "implementation-guide/1-feature-real-time-collaboration/1.1-feature-websocket-messaging",
  "format": "new",
  "task_num": "1.1",
  "task_type": "feature",
  "task_slug": "websocket-messaging",
  "parent_path": "implementation-guide/1-feature-real-time-collaboration",
  "depth": 2
}
```

### Helper Script: format-detector.sh

**Input**:
```bash
format-detector.sh "<task-directory>" "<workflow-file>"
```

**Purpose**: Version comparison and upgrade assistant for workflow files.

**Output** (LLM-parseable markdown to stdout):
```markdown
## Workflow File Version Check

**File**: implementation-guide/1-feature-task/a-plan.md
**Current Version**: 1.0
**Expected Version**: 2.0 (per format-detector.sh v1.2.3)

### Missing Required Fields
- **Template Version** (required in Task Reference section)
- **Branch** (required in Task Reference section)

### Analysis
This task/sub-task workflow file is from an earlier version of CIG.

**Question**: Do you want to:
- Upgrade it to the current version (2.0)?
- Leave it as a historical artefact?
- Partially upgrade (add only critical missing fields)?

Please advise how you would like to proceed.
```

**Version Detection Logic**:
1. Parse `**Template Version**` field from workflow file
   - Pattern: `grep "^\- \*\*Template Version\*\*:" <file>`
   - Default to 1.0 if field missing (backward compatibility)
2. Compare against expected version embedded in script itself
   - Script updated when CIG is upgraded
   - Script knows current template version (e.g., 2.0)
3. Parse template structure from workflow file
4. Compare against expected fields for current version
5. List missing REQUIRED fields only (not optional fields)

**Field Comparison**:
- Script contains definition of required fields per version
- Version 1.0 required fields: Task ID, Type, Status
- Version 2.0 required fields: Task ID, Type, Status, Template Version, Branch
- Only report missing required fields for target version

**Open-Ended Question Design**:
- Final section presents options without prescribing an answer
- LLM interprets output and asks user for decision
- Supports multiple upgrade paths: full upgrade, partial upgrade, no upgrade
- Preserves user agency in version management

**Exit codes**:
- 0: Success (version check complete)
- 1: Invalid task directory
- 2: Workflow file not found
- 3: Cannot parse template version

**Edge Cases**:
- File has no version field: Assume 1.0
- File has invalid version field: Report as parsing error (exit 3)
- Multiple workflow files in directory: Check each file separately
- Mixed versions across files: Report per-file (normal scenario)

**Design Rationale**: Facilitates gradual upgrades without forcing breaking changes. Users can maintain historical tasks in old format while creating new tasks in new format.

### Helper Script: status-aggregator.sh

**Input**:
```bash
status-aggregator.sh ["<task-path>"]   # Optional, defaults to all tasks
```

**Output** (Markdown to stdout):
```markdown
1-feature-real-time-collaboration (50% - Implemented)
  1.1-feature-websocket-messaging (25% - In Progress)
    1.1.1-chore-connection-pool (100% - Finished)
2-bugfix-authentication-error (75% - Testing)
3-chore-update-dependencies (0% - Backlog)
```

**Progress Calculation Algorithm**:

**Status to Percentage Mapping**:
- `Backlog` = 0%
- `To-Do` = 0%
- `In Progress` = 25%
- `Implemented` = 50%
- `Testing` = 75%
- `Finished` = 100%

**Single Task Progress Formula**:
```
task_progress = MAX(
  IF(MAX(all_workflow_file_statuses) >= 25%) THEN 25% ELSE 0%,
  MIN(all_workflow_file_statuses)
)
```

**Explanation**:
- Once ANY workflow file reaches "In Progress" (25%) or beyond, task shows at least 25%
- Actual progress is capped by the LEAST complete workflow file
- Ensures task can't show "Finished" unless ALL workflow files are finished

**Edge Cases**:
- Task with no workflow files: Treated as Backlog (0%)
- Workflow file with no status marker: Treated as Backlog (0%)
- Workflow file doesn't exist: Ignored (not counted in calculation)

**Parent Task Aggregation** (Future Enhancement):
```
parent_display_progress = MAX(
  parent's own task_progress,
  MAX(all children's display_progress)
)
```
Note: Initial implementation calculates only parent's own progress. Child aggregation to be added in future iteration.

**Exit codes**:
- 0: Success
- 1: Invalid path
- 2: Task not found
- 3: No tasks found (when no path specified)

## Security Considerations

- All helper scripts: Minimum 0500 permissions (u+rx - readable and executable by owner)
- SHA256 verification in security check for all helper scripts
- No dynamic code execution
- Validate all path inputs (prevent traversal)
- Git-based version tracking
- Self-documenting headers in scripts aid security audits

## Migration Strategy

**Handled in subtask 3.1 during rollout phase**

See scratchpad.md lines 697-998 for complete migration plan.

**Key points**:
- Use `git mv` for directory and file renames
- Single pure rename commit (git tracks history)
- Separate validation commit
- Separate documentation commit

## Integration Points

### Git Integration
- Branch naming: `feature/3-hierarchical-workflow-system-with-dynamic-step-transitions`
- Commit messages: Include task reference
- History preservation via `git mv`

### Claude Code Integration
- Slash commands in `.claude/commands/`
- Command frontmatter with `argument-hint` fields for UI guidance
- Helper scripts callable from commands
- Markdown output for Claude to process
- Progressive disclosure through command references

### Configuration Integration
- Task types from `cig-project.json`
- Templates from `.cig/templates/pool/` (central pool with task type symlinks)
- Workflow documentation from `.cig/docs/workflow/`
- Security verification via `/cig-security-check` (SHA256 for helper scripts)

## Performance Considerations

- Context inheritance: Cache parent reads (future optimization)
- Status display: Stream output for large hierarchies
- Path resolution: Use hash lookups for depth >5
- Template copying: Minimal file I/O

## Testing Strategy

See `e-testing.md` for detailed test plan.

**Key test scenarios**:
1. Create tasks at 5 levels deep
2. Execute all workflow commands with argument-hint fields
3. Verify context inheritance accuracy with template version parsing
4. Test backward compatibility (old vs new formats)
5. Validate migration preserves history
6. Stress test with 100+ tasks
7. Test template pool and symlink structure
8. Verify status marker parsing and dynamic transitions
9. Test `/cig-extract` with task-based paths
10. Validate helper script permissions and SHA256 verification
11. Test LLM-in-the-loop error handling and recovery
12. Verify workflow documentation references (progressive disclosure)

## Rollback Plan

If critical issues discovered:
1. Revert migration commit
2. Restore old structure from git
3. Disable new commands
4. Document issues for fix

## Future Enhancements (Out of Scope)

- Visual task dependency graphs
- Automated workflow orchestration
- Task templates beyond workflow steps
- Real-time collaboration
- Web UI
