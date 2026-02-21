# enforce single canonical task type list across CWF modules - Implementation Plan
**Task**: 81 (bugfix)

## Task Reference
- **Task ID**: internal-81
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/81-enforce-single-canonical-task-type-list
- **Template Version**: 2.1

## Goal
Implement the canonical type list export and bidirectional validation.

## Files to Modify
### Primary Changes
- `.cwf/lib/CWF/WorkflowFiles/V21.pm` — add `supported_types()` export
- `.cwf/lib/CWF/Validate/Config.pm` — add bidirectional validation using `supported_types()`
- `.cwf/templates/cwf-project.json.template` — remove ghost types, add discovery

### Test Updates (required — existing tests use partial lists that will now fail)
- `t/workflowfiles-v21.t` — add `supported_types()` test cases
- `t/validate-config.t` — update 3 subtests that use `['feature']` / `['feature','bugfix']`
  to use the full canonical list; add new subtests for unknown/missing type violations

### Supporting Changes
- `.cwf/security/script-hashes.json` — update SHA256 for both modified `.pm` files
- `.cwf/docs/workflow/decomposition-guide.md` — add discovery to task type summary (line 81)

## Implementation Steps

### Step 1: Add `supported_types()` to `CWF::WorkflowFiles::V21`

Add after the existing `get_workflow_files()` sub, before `1;`:

```perl
=head2 supported_types()

Return the canonical list of supported task types.
Derived from %WORKFLOW_FILES keys — single source of truth.

Returns:
  Sorted list of type name strings

=cut

sub supported_types {
    return sort keys %WORKFLOW_FILES;
}
```

Add `supported_types` to `@EXPORT_OK` (need to add `use Exporter` and `@EXPORT_OK`):

```perl
use Exporter 'import';
our @EXPORT_OK = qw(get_workflow_files supported_types);
```

### Step 2: Update `CWF::Validate::Config` — bidirectional validation

Add `use CWF::WorkflowFiles::V21 qw(supported_types);` after the existing `use` lines.

Replace the existing `supported-task-types` validation block (lines 56-73) with:

```perl
    # Check supported-task-types: must exist and be an arrayref
    if (!exists $config->{'supported-task-types'}) {
        my $canonical = join('","', supported_types());
        push @violations, _violation(
            $file,
            'supported-task-types',
            '(missing)',
            'array of task type strings',
            'Add "supported-task-types": ["' . $canonical . '"] to ' . $file,
        );
    } elsif (ref $config->{'supported-task-types'} ne 'ARRAY') {
        push @violations, _violation(
            $file,
            'supported-task-types',
            ref($config->{'supported-task-types'}) || 'scalar',
            'array (JSON array)',
            'Change supported-task-types to a JSON array',
        );
    } else {
        my %canonical = map { $_ => 1 } supported_types();
        my %project   = map { $_ => 1 } @{ $config->{'supported-task-types'} };

        # Check 1: unknown types in project (project → canonical)
        my @unknown = sort grep { !$canonical{$_} } keys %project;
        if (@unknown) {
            push @violations, _violation(
                $file,
                'supported-task-types',
                'unknown types: ' . join(', ', @unknown),
                'only canonical types: ' . join(', ', supported_types()),
                'Remove unknown types from supported-task-types in ' . $file,
            );
        }

        # Check 2: missing canonical types in project (canonical → project)
        my @missing = sort grep { !$project{$_} } keys %canonical;
        if (@missing) {
            push @violations, _violation(
                $file,
                'supported-task-types',
                'missing types: ' . join(', ', @missing),
                'all canonical types: ' . join(', ', supported_types()),
                'Add missing types to supported-task-types in ' . $file . ': ' . join(', ', @missing),
            );
        }
    }
```

### Step 3: Fix `cwf-project.json.template`

Replace the `supported-task-types` array:
```json
  "supported-task-types": [
    "feature",
    "bugfix",
    "hotfix",
    "chore",
    "discovery"
  ],
```

### Step 4: Update tests

**`t/workflowfiles-v21.t`** — add after the existing subtests:
```perl
subtest 'supported_types() - returns canonical list' => sub {
    plan tests => 3;
    use CWF::WorkflowFiles::V21 qw(supported_types);
    my @types = supported_types();
    ok(@types == 5, 'returns 5 types');
    ok((grep { $_ eq 'discovery' } @types), 'includes discovery');
    ok((grep { $_ eq 'feature'   } @types), 'includes feature');
};

subtest 'supported_types() - derived from WORKFLOW_FILES keys' => sub {
    plan tests => 1;
    use CWF::WorkflowFiles::V21 qw(supported_types);
    my @types = sort supported_types();
    my @keys  = sort keys %CWF::WorkflowFiles::V21::WORKFLOW_FILES;
    is(join(',', @types), join(',', @keys), 'supported_types matches WORKFLOW_FILES keys');
};
```

**`t/validate-config.t`** — three existing subtests use partial type lists and will now
produce violations. Update them to use the full canonical list:
- Line 23: `['feature', 'bugfix']` → `['feature','bugfix','hotfix','chore','discovery']`
- Line 44: `['feature']` → `['feature','bugfix','hotfix','chore','discovery']`
- Line 103 (JSON string): `["feature"]` → `["feature","bugfix","hotfix","chore","discovery"]`

Add new subtests:
```perl
subtest 'validate_config_hash() - unknown task type is a violation' => sub {
    plan tests => 2;
    my $config = {
        'supported-task-types' => ['feature','bugfix','hotfix','chore','discovery','docs'],
        'source-management' => { 'branch-naming-convention' => 'x' },
    };
    my @v = validate_config_hash($config, '/fake/cwf-project.json');
    ok(@v > 0, 'returns violation');
    ok((grep { $_->{actual} =~ /unknown.*docs/ } @v), 'violation mentions docs as unknown');
};

subtest 'validate_config_hash() - missing canonical type is a violation' => sub {
    plan tests => 2;
    my $config = {
        'supported-task-types' => ['feature','bugfix','hotfix','chore'],
        'source-management' => { 'branch-naming-convention' => 'x' },
    };
    my @v = validate_config_hash($config, '/fake/cwf-project.json');
    ok(@v > 0, 'returns violation');
    ok((grep { $_->{actual} =~ /missing.*discovery/ } @v), 'violation mentions missing discovery');
};
```

### Step 5: Update SHA256 hashes

```bash
sha256sum .cwf/lib/CWF/WorkflowFiles/V21.pm .cwf/lib/CWF/Validate/Config.pm
```
Update `.cwf/security/script-hashes.json` for both files.

### Step 6: Fix `decomposition-guide.md` doc reference

Line 81: `feature: 8 files, bugfix: 5 files, hotfix: 5 files, chore: 4 files`
→ `feature: 10 files, bugfix: 7 files, hotfix: 7 files, chore: 6 files, discovery: 8 files`

(Also update the counts — they reflect v2.0 counts, not v2.1 which has more files.)

## Scope Completion
All 6 steps are required and interdependent. SHA256 update is mandatory after
modifying the `.pm` files.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 81
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 6 steps executed as planned. One extra hash recompute for `Validate::Config` after
idiomatic Perl rewrite (postfix `if`, iterate original arrays not hash keys).

## Lessons Learned
`sort supported_types()` is a Perl parsing trap — `supported_types` is read as a named
comparator. Use `for my $type (supported_types())` to iterate, or assign to a variable
first. Postfix `if` with `push` is more idiomatic than wrapping in a block.
