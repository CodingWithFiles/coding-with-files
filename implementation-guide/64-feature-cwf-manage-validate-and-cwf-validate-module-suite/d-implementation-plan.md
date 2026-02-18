# cwf-manage validate and CWF::Validate module suite - Implementation Plan
**Task**: 64 (feature)

## Task Reference
- **Task ID**: internal-64
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/64-cwf-manage-validate-and-cwf-validate-module-suite
- **Template Version**: 2.1

## Goal
Implement four `CWF::Validate::*` modules, `cwf-manage validate`, and post-skill guard integration per c-design-plan.md.

## Files to Create/Modify

| File | Action |
|------|--------|
| `.cwf/lib/CWF/Validate/Config.pm` | Create |
| `.cwf/lib/CWF/Validate/Workflow.pm` | Create |
| `.cwf/lib/CWF/Validate/Consistency.pm` | Create |
| `.cwf/lib/CWF/Validate/Security.pm` | Create |
| `.cwf/scripts/cwf-manage` | Add `validate` subcommand |
| `.cwf/security/script-hashes.json` | Add entries for 4 new modules |
| `.cwf/docs/skills/checkpoint-commit.md` | Add step 4 (post-commit validate) |
| `.cwf-skills/cwf-security-check/SKILL.md` | Delegate to `CWF::Validate::Security` |

## Implementation Steps

### Step 1: CWF::Validate::Config

Create `.cwf/lib/CWF/Validate/Config.pm`:

```perl
package CWF::Validate::Config;
use strict;
use warnings;
use Exporter 'import';
use JSON::PP;
our @EXPORT_OK = qw(validate validate_config_hash);

# validate($git_root) — discovers config file, returns @violations
# validate_config_hash($hashref, $file_path) — validates already-loaded config
```

Checks (D3):
- `supported-task-types` exists and is an arrayref
- `source-management` exists and is a hashref
- `source-management`→`branch-naming-convention` exists and is non-empty string

Config file path: `$git_root/implementation-guide/cwf-project.json` — return empty list (no violations) if file doesn't exist yet (pre-init state).

Violation format: `{ file => $path, field => $field, actual => $actual, expected => $expected, fix => $fix }`

### Step 2: CWF::Validate::Workflow

Create `.cwf/lib/CWF/Validate/Workflow.pm`:

```perl
package CWF::Validate::Workflow;
use strict;
use warnings;
use Exporter 'import';
use CWF::MarkdownParser qw(extract_status);
our @EXPORT_OK = qw(validate);
```

Checks (D4):
- For each `.md` file under `$git_root/implementation-guide/*/`:
  - `## Status` section is present
  - Status value is in the allowed set: `Backlog|In Progress|Implemented|Testing|Finished|Blocked|Skipped|Cancelled`

Use `CWF::MarkdownParser::extract_status()` for extraction. If it returns `"Unknown"`, flag as missing/invalid status.

### Step 3: CWF::Validate::Consistency

Create `.cwf/lib/CWF/Validate/Consistency.pm`:

```perl
package CWF::Validate::Consistency;
use strict;
use warnings;
use Exporter 'import';
use CWF::MarkdownParser qw(extract_status);
our @EXPORT_OK = qw(validate);
```

Checks (D5):
- Directory name prefix matches `**Task**:` field — extract task num from dirname (first token before `-`), compare to `**Task**: NN` in each workflow file
- Git branch matches `**Branch**:` field — only for task directories that contain at least one file with status not in `Finished|Skipped|Cancelled`

Get current branch via: `git rev-parse --abbrev-ref HEAD`

### Step 4: CWF::Validate::Security

Create `.cwf/lib/CWF/Validate/Security.pm`:

```perl
package CWF::Validate::Security;
use strict;
use warnings;
use Exporter 'import';
use Digest::SHA qw(sha256_hex);
use JSON::PP;
our @EXPORT_OK = qw(validate);
```

Checks (D6):
- Read `.cwf/security/script-hashes.json`
- For each entry under `scripts` and `lib` keys:
  - File exists at `$git_root/$entry->{path}`
  - Permissions: `(stat($file))[2] & 07777` ≥ `0500`
  - SHA256 of file contents matches `$entry->{sha256}`

Use `Digest::SHA::sha256_hex(slurp($file))` — no shell subprocess.

### Step 5: cwf-manage validate subcommand

Add to `.cwf/scripts/cwf-manage`:

```perl
use lib "$FindBin::Bin/../lib";
use CWF::Validate::Config     qw(validate);
use CWF::Validate::Workflow   qw(validate);
use CWF::Validate::Consistency qw(validate);
use CWF::Validate::Security   qw(validate);
```

Add to dispatch table:
```perl
'validate' => sub { cmd_validate($git_root) },
```

`cmd_validate($git_root)`:
- Call all four `validate($git_root)` functions
- Collect into flat `@all_violations`
- If empty: print "[CWF] validate: OK\n", exit 0
- Otherwise: print each violation formatted, exit 1

Violation output format:
```
[VALIDATE] <category>  <file>
           Field:    <field>
           Actual:   <actual>
           Expected: <expected>
           Fix:      <fix>
```

Update `cmd_help()` to list `validate` command.

### Step 6: Update cwf-security-check skill

Update `.cwf-skills/cwf-security-check/SKILL.md` to call:
```bash
.cwf/scripts/cwf-manage validate
```
rather than manually reading the JSON and running sha256sum. The skill's user-facing description and output remain the same.

### Step 7: Update checkpoint-commit.md

Add step 4 to `.cwf/docs/skills/checkpoint-commit.md`:
```
4. **Validate** (post-commit guard):
   .cwf/scripts/cwf-manage validate
   If violations are reported, fix them before proceeding to the next skill.
```

### Step 8: Security hash updates

- Add entries for all 4 new `.pm` files to `.cwf/security/script-hashes.json` under a new `"lib"` section (or existing one if present)
- Update cwf-manage hash (file changed)
- `permissions` for `.pm` files: `"0644"`

### Step 9: perlcritic --stern on all new/modified files

Run against all four new modules and the updated `cwf-manage`. Fix any violations before committing.

## Validation Criteria
- [ ] `cwf-manage validate` exits 0 on clean repo
- [ ] `cwf-manage validate` exits 1 and prints all violations on broken repo
- [ ] Each violation message includes file, field, actual, expected, fix
- [ ] `perl -c` passes on all four new modules
- [ ] `perlcritic --stern` passes on all four new modules and cwf-manage
- [ ] `/cwf-security-check` still works (delegates to Security module)
- [ ] `checkpoint-commit.md` contains step 4

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 64
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned deliverables met. See j-retrospective.md for full variance analysis.

## Lessons Learned
See j-retrospective.md Key Learnings section.
