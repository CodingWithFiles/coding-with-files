# Improve scripts to avoid false positives - Design

## Task Reference
- **Task ID**: internal-8
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/8-improve-scripts-to-avoid-false-positives
- **Template Version**: 2.0

## Goal
Design solution for: (a) fixing false positives in status extraction, and (b) eliminating code duplication (DRY).

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### Architecture Choice
- **Decision**: Shared library with proper Perl module structure (CIG::*)
- **Rationale**: Eliminates ~40% code duplication, centralises bug fixes, follows Perl conventions
- **Trade-offs**:
  - (+) Single source of truth for shared operations
  - (+) Proper module namespacing (CIG::MarkdownParser, etc.)
  - (+) Easy to test modules independently
  - (+) Scripts become thin wrappers (~50-100 lines)
  - (-) More files to manage
  - (-) Slightly more complex import paths

### Technology Stack
- **All Scripts**: Perl (full migration from Bash)
- **Shared Library**: `.cig/lib/CIG/*.pm`
- **No External Dependencies**: Core Perl only (no CPAN)

## System Design

### Directory Structure

```
.cig/
├── lib/
│   └── CIG/
│       ├── MarkdownParser.pm    [NEW] Status extraction with structure awareness
│       ├── TaskPath.pm          [NEW] Path normalisation, validation, resolution
│       └── WorkflowFiles.pm     [NEW] File lists, version detection, status mapping
├── scripts/
│   └── command-helpers/
│       ├── status-aggregator.pl   [REWRITE] Thin wrapper using lib
│       ├── hierarchy-resolver.pl  [REWRITE] Thin wrapper using lib
│       ├── format-detector.pl     [REWRITE] Thin wrapper using lib
│       └── context-inheritance.pl [REWRITE] Thin wrapper using lib
```

### Module Responsibilities

**CIG::MarkdownParser** - Markdown structure parsing
- `extract_status($file)` - Extract status from `## Status` section only
- State machine: tracks `in_code_block`, `in_status_section`
- Skips triple-backtick code blocks
- Warns on multiple status sections (uses first)

**CIG::TaskPath** - Task path operations
- `normalize($path)` - Convert `1/1.1` to `1.1`
- `validate($path)` - Check format `^[0-9]+(\.[0-9]+)*$`
- `build_glob($path)` - Build directory search pattern
- `resolve($path)` - Find task directory, return metadata
- `get_parent($path)` - Get parent task path
- `get_depth($path)` - Calculate nesting depth

**CIG::WorkflowFiles** - Workflow file operations
- `list($task_dir)` - List workflow files (v1.0 and v2.0)
- `get_template_version($file)` - Detect template version
- `status_to_percent($status)` - Convert status to percentage
- `load_config()` - Load from cig-project.json

### Data Flow

```
1. Command invocation (e.g., /cig-status 8)
   ↓
2. status-aggregator.pl
   ├── use CIG::TaskPath
   ├── use CIG::WorkflowFiles
   └── use CIG::MarkdownParser
   ↓
3. CIG::TaskPath::resolve($path) → task directory
   ↓
4. CIG::WorkflowFiles::list($dir) → workflow files
   ↓
5. For each file: CIG::MarkdownParser::extract_status($file)
   ↓
6. CIG::WorkflowFiles::status_to_percent($status) → percentage
   ↓
7. Aggregate and output
```

## Interface Design

### CIG::MarkdownParser API

```perl
package CIG::MarkdownParser;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(extract_status);

# Extract status from file, respecting markdown structure
# Returns: status string or "Unknown"
sub extract_status {
    my ($file_path) = @_;
    # State machine implementation
}

1;
```

### CIG::TaskPath API

```perl
package CIG::TaskPath;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(normalize validate build_glob resolve get_parent get_depth);

sub normalize { my ($path) = @_; $path =~ s/\//./g; return $path; }
sub validate  { my ($path) = @_; return $path =~ /^[0-9]+(\.[0-9]+)*$/; }
sub build_glob { ... }  # Build implementation-guide/1-*-*/1.1-*-* pattern
sub resolve { ... }     # Returns { path => ..., num => ..., type => ..., slug => ... }
sub get_parent { ... }  # Returns parent path or undef
sub get_depth { ... }   # Returns nesting level (1, 2, 3, ...)

1;
```

### CIG::WorkflowFiles API

```perl
package CIG::WorkflowFiles;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(list get_template_version status_to_percent load_config);

our %STATUS_MAP = (
    'Backlog' => 0, 'To-Do' => 0,
    'In Progress' => 25,
    'Implemented' => 50,
    'Testing' => 75,
    'Finished' => 100,
);

sub list { ... }                # Returns list of workflow files
sub get_template_version { ... } # Returns "1.0" or "2.0"
sub status_to_percent { ... }   # Lookup in %STATUS_MAP
sub load_config { ... }         # Load cig-project.json

1;
```

### Script Usage Pattern

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";

use CIG::TaskPath qw(resolve);
use CIG::WorkflowFiles qw(list status_to_percent);
use CIG::MarkdownParser qw(extract_status);

# Script-specific logic only (~50-100 lines)
```

### CLI Interfaces (unchanged)

All scripts maintain exact same CLI interfaces:

| Script | Interface | Output |
|--------|-----------|--------|
| `status-aggregator.pl` | `[task-path] [--format=json]` | Markdown tree or JSON |
| `hierarchy-resolver.pl` | `<task-path> [--format=json]` | Task metadata |
| `format-detector.pl` | `<task-dir> <file> [--format=json]` | Version info |
| `context-inheritance.pl` | `<task-path> [--format=json]` | Context map |

## Constraints

- **Backward Compatibility**: Support v1.0 and v2.0 formats
- **Output Compatibility**: Exact same output formats
- **Security**: chmod 500, update script-hashes.json
- **No External Dependencies**: Core Perl only

## Validation

- [x] Design review completed
- [x] Architecture approved (shared lib approach confirmed)
- [x] Code duplication analysis completed (~40% shared)
- [x] Module boundaries defined

## Status
**Status**: Finished
**Next Action**: Proceed to implementation phase
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
