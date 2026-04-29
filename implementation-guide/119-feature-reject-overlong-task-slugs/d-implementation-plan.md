# Reject Overlong Task Slugs - Implementation Plan
**Task**: 119 (feature)

## Task Reference
- **Task ID**: internal-119
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/119-reject-overlong-task-slugs
- **Template Version**: 2.1

## Goal
Execute the design from `c-design-plan.md`: add slug-length validation in `template-copier-v2.1` (script-level, fail-fast, no filesystem writes on rejection); remove silent truncation from `generate_slug`; update the two SKILL.md files to stop instructing the LLM to pre-truncate; add unit tests; refresh script hash.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit explains "why"

## Files to Modify
### Primary Changes
- `.cwf/scripts/command-helpers/template-copier-v2.1` — Five edits in the existing file:
  1. `die_msg` helper added after the `use` block (~line 39).
  2. `use constant SLUG_MAX_LEN => 50;` immediately after `die_msg`.
  3. New slug-length validation block in `parse_parameters` after the required-param loop (~line 81), before the `unless (exists $params{destination}) { ... construct_destination(...) }` block.
  4. `generate_slug` simplified: remove `substr($description, 0, 50)` (line 168); also strip leading/trailing hyphens (`s/^-+|-+$//g`) so `"---foo---"` → `"foo"` rather than `"-foo-"`. Returns the full normalised slug.
  5. **Refactor**: wrap the existing 8-line top-level execution block (`my %params = parse_parameters(@ARGV); ... exit 0;`) in `sub main { ... }` and replace the trailing `exit 0;` with `main() unless caller();`. This lets the test file `do`-load the script without triggering full task creation. (Required for the test pattern to work — `do` would otherwise call `parse_parameters(@ARGV)` with empty `@ARGV` and die on the required-param check before tests run.)
- `.claude/skills/cwf-new-task/SKILL.md` — Rewrite line 39 from "Slug: lowercase, spaces to hyphens, remove special chars, truncate 50 chars" to remove the truncate clause; add a brief note that the script enforces a 50-char limit and will reject overlong descriptions with `[CWF] ERROR:`. Also clarify Step 2 so the LLM passes `--description` raw to `task-workflow create` (no LLM-side slug construction); the script constructs the destination.
- `.claude/skills/cwf-new-subtask/SKILL.md` — Mirror the cwf-new-task SKILL.md change at line 45 ("Generate slug (same algorithm as `/cwf-new-task`)"). Update so it states the script does the slug generation and length validation, not the LLM.

### Supporting Changes
- `.cwf/security/script-hashes.json` — Update the `template-copier-v2.1` entry's `sha256` to the new hash after the script change. The path and permissions fields are unchanged.
- `t/template-copier-slug-validation.t` (**new**) — Unit-test file using the `*main::die_msg` symbol-table override pattern from `t/cwf-manage-check-clean-tree.t` and `t/cwf-manage-resolve-source.t`.

### Out of scope (deliberate)
- `.cwf/scripts/command-helpers/template-copier-v2.0` — not wired through `task-workflow.d/create` (verified: only v2.1 is exec'd). Leaving it alone keeps the diff focused.
- Migrating other `print STDERR "Error: ..." + exit N` blocks in `template-copier-v2.1` to `die_msg` — boy-scout would balloon the diff and dilute review focus. Captured as future work in retrospective.
- Existing tasks on disk with truncated slugs — no retroactive rename (per FR5).

## Implementation Steps

### Step 1: Setup and pattern review
- [ ] Read `t/cwf-manage-check-clean-tree.t` to confirm the `*main::die_msg = sub { die "..." }` override pattern and `eval { ... }` failure-catching idiom
- [ ] Re-read the design doc's pseudocode (c-design-plan.md "Interface — script changes summary") and confirm the insertion points against the current line numbers in `template-copier-v2.1` (in case anything shifted since planning)
- [ ] Confirm `.cwf/security/script-hashes.json` entry for `template-copier-v2.1` (line 45-49) is the only place the script's hash is recorded

### Step 2: Write the unit test first (TDD)
- [ ] Create `t/template-copier-slug-validation.t` based on `t/cwf-manage-check-clean-tree.t` skeleton. Setup pattern:
  - `do "$script_dir/.cwf/scripts/command-helpers/template-copier-v2.1"` to load the script. The `main() unless caller();` guard from Step 3 means top-level execution is skipped.
  - After load, override `*main::die_msg = sub { die "[CWF] ERROR: @_\n" }` so failure paths become catchable via `eval`.
- [ ] Test cases (each invokes `main::parse_parameters(...)` with explicit args inside an `eval`, then asserts on `$@`):
  - **TC-test-1 (under limit)**: slug 49 chars — no die
  - **TC-test-2 (at limit)**: slug exactly 50 chars — no die
  - **TC-test-3 (just over)**: slug 51 chars — die matching `/Task slug '.+' is 51 characters; limit is 50/`
  - **TC-test-4 (well over)**: 100-char description — die
  - **TC-test-5 (empty after normalising)**: description = `"!!!"` — die matching `/empty slug/i`
  - **TC-test-6 (leading/trailing hyphens)**: description = `"---valid-content---"` — passes after generate_slug strips outer hyphens; the resulting slug is `"valid-content"` (length 13)
  - **TC-test-7 (error message contents)**: assert the overlong-error string includes the actual length, the literal `50`, and a recovery substring like `"briefer"` or `"Use a"`
  - **TC-test-8 (atomicity — no fs writes)**: in a fresh `tempdir(CLEANUP => 1)`, snapshot the directory listing, run `parse_parameters` with an overlong description (wrapped in `eval`), then assert the directory listing is unchanged. Equivalent assertion: `make_path` is never called on rejection.
- [ ] Run the test: it must fail (script doesn't yet have the validation or the `caller()` guard)

### Step 3: Implement the script change
- [ ] Open `.cwf/scripts/command-helpers/template-copier-v2.1`
- [ ] Insert after the `use` block (after line 38):
  ```perl

  sub die_msg {
      print STDERR "[CWF] ERROR: @_\n";
      exit 1;
  }

  use constant SLUG_MAX_LEN => 50;
  ```
- [ ] Inside `parse_parameters`, after the required-param check loop (after the `for my $required (...)` block, before the `unless (exists $params{destination})` block), insert:
  ```perl
  # Validate slug length — must run before destination construction
  # so no filesystem writes happen on rejection.
  my $slug = generate_slug($params{description});
  my $slug_len = length($slug);
  if ($slug_len == 0) {
      die_msg("Task description '$params{description}' produces an empty slug after normalising. "
            . "Use a description that contains at least one alphanumeric character.");
  }
  if ($slug_len > SLUG_MAX_LEN) {
      my $limit = SLUG_MAX_LEN;
      die_msg("Task slug '$slug' is $slug_len characters; limit is $limit. "
            . "Use a briefer task description (try fewer or shorter words).");
  }
  ```
- [ ] In `generate_slug`: remove the truncation `substr($description, 0, 50)` at line 168, and add a leading/trailing hyphen strip after the consecutive-hyphen collapse:
  ```perl
  # Collapse consecutive hyphens
  $description =~ s/-+/-/g;

  # Strip leading/trailing hyphens (so "---foo---" → "foo", not "-foo-")
  $description =~ s/^-+//;
  $description =~ s/-+$//;

  return $description;
  ```
- [ ] Wrap the existing top-level execution block (the 8 lines starting `# Main execution` through `exit 0;` at the bottom of the file) in a `main` sub and add a caller guard:
  ```perl
  sub main {
      my %params = parse_parameters(@ARGV);
      my $templates_dir = find_templates_directory();
      my $config = validate_task_type($params{task_type});
      my @templates = discover_templates($templates_dir, $params{task_type});
      my %variables = compute_variables(\%params);
      my ($created, $overwritten) = copy_templates(\@templates, $params{destination}, \%variables, $templates_dir, $params{task_type});
      output_results(\%params, $created, $overwritten);
      return;
  }

  main() unless caller();
  ```

### Step 4: Refresh the script hash
- [ ] Compute new sha256:
  ```bash
  sha256sum .cwf/scripts/command-helpers/template-copier-v2.1 | awk '{print $1}'
  ```
  (`sha256sum` reads in binary mode by default, matching the `<:raw` mode in `CWF::Validate::Security::_sha256` line 105.)
- [ ] Update `.cwf/security/script-hashes.json` line 47 — replace the old hex string in the `template-copier-v2.1` entry with the new one. Use `Edit` tool for precision (path and permissions fields stay the same).
- [ ] Run `.cwf/scripts/cwf-manage validate` — must report `OK`. If it reports a hash mismatch, the script was modified between the hash computation and the JSON update; recompute and retry.

### Step 5: Update the skill docs
- [ ] Edit `.claude/skills/cwf-new-task/SKILL.md` line 39:
  - **Before**: `- Slug: lowercase, spaces to hyphens, remove special chars, truncate 50 chars`
  - **After**: `- Slug: pass --description raw to the script; the script slugifies (lowercase, spaces to hyphens, remove special chars) and rejects overlong descriptions (>50 chars) with [CWF] ERROR. Do not pre-truncate.`
- [ ] Edit `.claude/skills/cwf-new-subtask/SKILL.md` line 45:
  - **Before**: `- Generate slug (same algorithm as /cwf-new-task)`
  - **After**: `- Slug: pass --description raw to the script (same handling as /cwf-new-task — script slugifies and rejects >50 chars).`
- [ ] Confirm by grep: no remaining occurrence of "truncate 50 chars" or "truncate 50" in `.claude/skills/cwf-new-task/` or `.claude/skills/cwf-new-subtask/`

### Step 6: Run tests + validation
- [ ] Run the test file: `prove t/template-copier-slug-validation.t`
- [ ] Run the existing test suite: `prove t/` — must show no new failures vs the baseline before this task (currently 238 passing per Task 116's CHANGELOG entry; verify baseline first)
- [ ] Run `.cwf/scripts/cwf-manage validate` — must report `OK`

### Step 7: Manual smoke test
- [ ] In a scratch git checkout (or by careful CLI invocation), run:
  ```
  /cwf-new-task 999 chore "this description is deliberately way too long for a slug and should be rejected outright"
  ```
- [ ] Confirm the user sees a `[CWF] ERROR:` message on STDERR; no directory created under `implementation-guide/`; non-zero exit; no git branch created

## Code Changes (excerpts)

### Before (`template-copier-v2.1` line 36–38, 41, 81–86, 168)
```perl
use Cwd qw(abs_path);
use CWF::TaskPath qw(validate get_parent resolve_num);
use CWF::WorkflowFiles qw(load_config);

sub parse_parameters {
    ...
    }

    # Construct destination if not provided
    unless (exists $params{destination}) {
        $params{destination} = construct_destination(\%params);
    }
    ...
sub generate_slug {
    ...
    return substr($description, 0, 50);
}
```

### After (illustrative — final wording in implementation)
```perl
use Cwd qw(abs_path);
use CWF::TaskPath qw(validate get_parent resolve_num);
use CWF::WorkflowFiles qw(load_config);

sub die_msg {
    print STDERR "[CWF] ERROR: @_\n";
    exit 1;
}

use constant SLUG_MAX_LEN => 50;

sub parse_parameters {
    ...
    }

    # Validate slug length before destination construction (atomic failure).
    my $slug = generate_slug($params{description});
    my $slug_len = length($slug);
    die_msg("Task description '$params{description}' produces an empty slug after normalising. "
          . "Use a description that contains at least one alphanumeric character.") if $slug_len == 0;
    if ($slug_len > SLUG_MAX_LEN) {
        my $limit = SLUG_MAX_LEN;
        die_msg("Task slug '$slug' is $slug_len characters; limit is $limit. "
              . "Use a briefer task description (try fewer or shorter words).");
    }

    # Construct destination if not provided
    unless (exists $params{destination}) {
        $params{destination} = construct_destination(\%params);
    }
    ...
sub generate_slug {
    ...
    return $description;
}
```

## Test Coverage
**See e-testing-plan.md for the full test plan.** Implementation-side tests (this phase): the unit-test file `t/template-copier-slug-validation.t` covers TC-test-1 through TC-test-8 above. The e-testing-plan adds skill-level smoke tests, hash-refresh validation, and FR5 regression (existing tasks unaffected).

## Validation Criteria
- All TC-test-* unit tests pass
- `prove t/` shows no new failures vs baseline
- `cwf-manage validate` returns `OK`
- Manual smoke test (Step 7) shows `[CWF] ERROR:` on STDERR, exit non-zero, no filesystem writes
- Grep confirms no remaining "truncate 50 chars" / "truncate 50" instructions in the SKILL.md files
- FR3 / AC3.1 verification: `grep -rn "SLUG_MAX_LEN" .cwf/scripts/ .cwf/lib/ .claude/skills/cwf-new-task/ .claude/skills/cwf-new-subtask/` returns the constant in exactly one location (the script's `use constant` declaration). The literal `50` may appear elsewhere for unrelated reasons (status weights, comments) — what matters is that the slug-limit value lives behind a single named constant
- Skills no longer instruct the LLM to pre-truncate; updated SKILL.md guidance directs the LLM to pass `--description` raw

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferred items must be approved by the user, documented in Actual Results, and tracked as a follow-up BACKLOG item.

## Notes (post plan-review)
- **Critical fix from Robustness review**: the script's bottom 8 lines run on `do`-load with empty `@ARGV`, which would die on the required-param check before tests start. Solution adopted: refactor to `sub main { ... } main() unless caller();` (Step 3 final bullet).
- **Generate_slug now strips leading/trailing hyphens** (Improvements F3). Previously a description like `"---foo---"` would slugify to `"-foo-"`; now it produces `"foo"`. Test case TC-test-6 covers this.
- **FR3 verification refined** (Misalignment F1): grep for `SLUG_MAX_LEN` not the literal `50` (which appears in unrelated status-weight constants and comments). The constant name is the actual single-source-of-truth check.
- **Hash refresh procedure made explicit** (Misalignment F2): Step 4 now includes the `sha256sum` command, since CWF has no automated hash-refresh helper.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 119
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All seven steps executed in order. Step 7 (manual skill-level smoke test) was deferred to g-testing-exec where the equivalent end-to-end coverage was added via direct `task-workflow create` invocation (TC-11/TC-12) — same dispatcher the skill uses, no LLM-loop dependency. The /simplify pass after exec found two minor smells (redundant `$limit` local; redundant `generate_slug` call) that the plan's pseudocode pre-committed to; both fixed in commit 78a16a5.

## Lessons Learned
See j-retrospective.md.
