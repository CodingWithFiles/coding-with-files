# audit perl helpers vs perl-git-paths conventions - Implementation Plan
**Task**: 124 (chore)

## Task Reference
- **Task ID**: internal-124
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/124-audit-perl-helpers-vs-perl-git-paths-conventions
- **Template Version**: 2.1

## Goal
Bring all Perl files under `.cwf/scripts/` and `.cwf/lib/CWF/` into compliance with `docs/conventions/perl-git-paths.md`, and add a `CWF::Validate::PerlConventions` module wired into `cwf-manage validate` so future drift is detected on every checkpoint commit (validate runs from `cwf-checkpoint-commit:53`).

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Audit Findings (already completed)

A scan of `.cwf/scripts/` and `.cwf/lib/CWF/` produced the table below. **Total non-conformant: 9 files (8 modules + 1 script).**

### Conformant (no change needed)
- `.cwf/scripts/cwf-manage` (shebang + `use utf8;` + git call uses `-z`)
- `.cwf/scripts/hooks/stop-uncommitted-changes-warning` (already conformant)
- All other helpers under `command-helpers/` and `*.d/` subdirectories: no git path consumption, no non-ASCII source.

### Non-conformant — missing `use utf8;` despite non-ASCII source

| File | Non-ASCII lines |
|---|---|
| `.cwf/lib/CWF/TaskContextInference.pm` | 1 |
| `.cwf/lib/CWF/TaskPath.pm` | 1 |
| `.cwf/lib/CWF/MarkdownParser.pm` | 1 |
| `.cwf/lib/CWF/TaskState.pm` | 6 |
| `.cwf/lib/CWF/Versioning.pm` | 3 |
| `.cwf/lib/CWF/Validate/Security.pm` | 1 |
| `.cwf/lib/CWF/Validate/Config.pm` | 1 |
| `.cwf/lib/CWF/WorkflowFiles/V21.pm` | 1 |
| `.cwf/scripts/migrations/migrate-v2.1-file-order` | 10 |

Risk class: same as Task 115 (em-dash mojibake under `PERL5OPT=-CDSL`).

### Grandfathered (documented exception, no change)
- `.cwf/scripts/hooks/stop-stale-status-detector` — env shebang + `git diff` without `-z`. Already documented in `docs/conventions/perl-git-paths.md#pre-convention-scripts`. Modelled in the new validate module as a hard-coded allowlist entry (see Architectural Decision below).

## Architectural Decision: validate module, not standalone test

The original BACKLOG framing offered "a `cwf-manage validate` soft check **or** a `prove t/perl-conventions.t` style test". The plan picks the validate-module path because:

- All existing source-quality checks live in `CWF::Validate::*` (Config, Workflow, Consistency, Security) and are orchestrated from `cmd_validate` in `cwf-manage`.
- `cwf-manage validate` runs after every checkpoint commit (`cwf-checkpoint-commit:53`), giving every workflow phase drift protection — a stand-alone `prove` test only protects developers who run the full suite.
- `CWF::Validate::*` modules already define a violation-record idiom (returning hashrefs that `cwf-manage` formats) that this check fits into without inventing new infrastructure.

### Allowlist over opt-out comment

A `# perl-git-paths-skip` marker was considered but rejected: a future caller could attach the marker to a script that legitimately consumes git paths and the convention check would silently exempt it. Instead, the new module encodes the grandfathered exception as a small constant array (`our @GRANDFATHERED = ('.cwf/scripts/hooks/stop-stale-status-detector')`). Adding to the allowlist requires editing source — visible in code review and easier to audit.

## Files to Modify

### Primary changes (add `use utf8;` after `use strict; use warnings;`)
- `.cwf/lib/CWF/TaskContextInference.pm`
- `.cwf/lib/CWF/TaskPath.pm`
- `.cwf/lib/CWF/MarkdownParser.pm`
- `.cwf/lib/CWF/TaskState.pm`
- `.cwf/lib/CWF/Versioning.pm`
- `.cwf/lib/CWF/Validate/Security.pm`
- `.cwf/lib/CWF/Validate/Config.pm`
- `.cwf/lib/CWF/WorkflowFiles/V21.pm`
- `.cwf/scripts/migrations/migrate-v2.1-file-order`

### New files
- `.cwf/lib/CWF/Validate/PerlConventions.pm` — convention check module.
- `t/validate-perl-conventions.t` — Test::More unit test for the module (mirrors `t/validate-security.t`).

### Wiring changes
- `.cwf/scripts/cwf-manage` — `cmd_validate` (line ~398) gains a `CWF::Validate::PerlConventions::validate($git_root)` call alongside the existing four validate modules.
- `.cwf/security/script-hashes.json` — register the new `PerlConventions.pm` module; refresh sha256 + permissions for every modified file (see Step 4 for the manual procedure).

### Supporting changes
- `docs/conventions/perl-git-paths.md` — update "Existing usage" to reflect post-audit state; under "Pre-convention scripts", add a sentence pointing to `cwf-manage validate` as the active drift check (augment, do not overwrite).
- `BACKLOG.md` — remove the closed item.

## Implementation Steps

### Step 1: Test first — `t/validate-perl-conventions.t`
- [ ] Mirror `t/validate-security.t`'s structure: `use strict; use warnings; use Test::More; use FindBin; use lib "$FindBin::Bin/../.cwf/lib";`.
- [ ] Build a temporary fixture tree containing: (a) a module with non-ASCII + `use utf8;` (passes), (b) a module with non-ASCII without `use utf8;` (fails source-pragma assertion), (c) a script capturing `git status` without `-z` (fails git-z assertion), (d) a script capturing `git status` with `-z` (passes), (e) a script with the same pattern but in a POD block (passes — POD is excluded).
- [ ] Drive `CWF::Validate::PerlConventions::validate($fixture_root)` and assert returned violation records match expectations.
- [ ] Run the test; it fails (red) until Step 2 lands.

### Step 2: Implement the module
- [ ] Create `.cwf/lib/CWF/Validate/PerlConventions.pm` exporting `validate($git_root)`.
- [ ] **Discovery**: walk `.cwf/scripts/` and `.cwf/lib/CWF/` via `File::Find` (no shell composition; same idiom as `CWF::Validate::Security`). Filter to files whose first line matches `/\A#!.*perl/` or whose body contains `^package CWF::/m`.
- [ ] **Source-pragma check (modules + scripts)**: strip POD (`/^=\w+.*?^=cut/ms`) and `#` comments; if any remaining byte exceeds `0x7F`, the file must contain `^use utf8;` on a non-comment line.
- [ ] **Git output-capture check (scripts only)**: detect captured git invocations with regex over non-POD/non-comment source: matches `qx{git\s+(status|diff|ls-files|diff-tree|diff-index)\b[^}]*}`, backticks `` `git ...` ``, and `open\s*\(?\s*[^,]+,\s*['"]-\|['"]\s*,\s*(?:'git'|"git")\s*,\s*(?:'-C'|"-C"\s*,\s*\$?[\w_]+\s*,\s*)?(?:'(status|diff|ls-files|diff-tree|diff-index)')`. The matched invocation must contain `-z` as a separate token. (Plain `system('git', 'log', '--', $path)` and similar — paths as **arguments**, no captured output — are out of scope per the convention doc, which addresses path *output* only.)
- [ ] **Shebang check (scripts only)**: any script that fires the git output-capture rule must have shebang `#!/usr/bin/perl -CDSL`.
- [ ] **Allowlist**: `our @GRANDFATHERED = ('.cwf/scripts/hooks/stop-stale-status-detector');` — files in this list skip the git output-capture and shebang assertions, but **not** the source-pragma assertion.
- [ ] **Violation format**: return arrayref of `{ rel => $rel, field => 'use_utf8' | 'git_z' | 'shebang', actual => ..., expected => ... }`, matching the shape `cmd_validate` already formats.
- [ ] Re-run `t/validate-perl-conventions.t`; confirm green.

### Step 3: Wire into `cwf-manage validate`
- [ ] In `cwf-manage` `cmd_validate`, after the existing four `Validate::*` calls, add `CWF::Validate::PerlConventions::validate($git_root)`.
- [ ] Run `prove -r t/`; confirm full suite green.
- [ ] Run `.cwf/scripts/cwf-manage validate`; expect output to flag the 9 non-conformant files (red — by design, fixed in Step 4).

### Step 4: Bring the 9 non-conformant files into compliance
- [ ] Add `use utf8;` to each of the 9 files listed under "Primary changes" — placed after `use strict; use warnings;` (or after the `package` line + `use strict; use warnings;` for modules), matching the order used in `cwf-manage:16-18`.
- [ ] Run `prove -r t/` to confirm no regressions from the source-encoding change.
- [ ] **Refresh hashes manually — maintainer-only, in this upstream source repo**. The CWF integrity model treats `script-hashes.json` as a one-way fingerprint of an audited upstream release. End-user installations *never* recompute or re-bless hashes; they only ever receive new hashes atomically via `cwf-manage update` from upstream. Locally re-blessing would let any human or agent silently authorise arbitrary script changes, defeating the control. Because Task 124 is executing inside the upstream source repo, the maintainer updates the JSON here:
  - `cwf-manage fix-security` is irrelevant for this — it only repairs permissions when the SHA already matches; it does not recompute SHAs.
  - For each of the 9 modified files plus the new `PerlConventions.pm`, compute `sha256sum <path>` and update its entry in `.cwf/security/script-hashes.json`. Permissions are unchanged.
  - Add a new entry for `PerlConventions.pm` (path + sha256 + permissions `0444`, mirroring the other `CWF::Validate::*` modules).
  - Update the top-level `last_updated` field.
- [ ] Run `.cwf/scripts/cwf-manage validate`; expect `OK` (no sha256 violations, no PerlConventions violations).

### Step 5: Update documentation and remove BACKLOG entry
- [ ] In `docs/conventions/perl-git-paths.md`:
  - Update "Existing usage" to list all helpers/modules now declaring `use utf8;`.
  - Under "Pre-convention scripts", add: "Drift is checked at every `cwf-manage validate` (and therefore at every workflow checkpoint commit) by `CWF::Validate::PerlConventions`; the grandfathered exception above is encoded in that module's `@GRANDFATHERED` allowlist."
- [ ] Remove the "Audit Perl helpers..." item from `BACKLOG.md`.

### Step 6: End-to-end validation
- [ ] `prove -r t/` — full suite green, including the new `t/validate-perl-conventions.t`.
- [ ] `cwf-manage validate` — clean.
- [ ] **Negative test (planted breakage)**: temporarily remove `use utf8;` from one module → `cwf-manage validate` fails with a clear `PerlConventions` violation citing the file → restore.
- [ ] Manual smoke tests of runtime behaviour (so the source-encoding change doesn't regress production paths):
  - `.cwf/scripts/migrations/migrate-v2.1-file-order --help` (or its dry-run equivalent if `--help` is absent).
  - `.cwf/scripts/cwf-manage status` (touches `Versioning.pm`).
  - Trigger the stale-status hook flow and the uncommitted-changes hook flow.
  - Run `cwf-status 124` (touches `TaskState.pm`, `MarkdownParser.pm`, `TaskContextInference.pm`).

## Code Changes

### Pattern: adding `use utf8;` to a module
```perl
package CWF::TaskState;

use strict;
use warnings;
use utf8;          # added — source contains non-ASCII literals (em-dashes etc.)
use Encode qw(decode);
```

### Pattern: validate-module skeleton
```perl
package CWF::Validate::PerlConventions;
use strict;
use warnings;
use utf8;
use File::Find ();

our @GRANDFATHERED = ('.cwf/scripts/hooks/stop-stale-status-detector');
my %GRANDFATHERED  = map { $_ => 1 } @GRANDFATHERED;

sub validate {
    my ($git_root) = @_;
    my @violations;
    File::Find::find(sub {
        return unless -f $_;
        my $rel = File::Spec->abs2rel($File::Find::name, $git_root);
        return unless $rel =~ m{^\.cwf/(scripts|lib/CWF)/};
        # ... source-pragma, git-z, shebang assertions ...
    }, "$git_root/.cwf/scripts", "$git_root/.cwf/lib/CWF");
    return \@violations;
}

1;
```

## Test Coverage
**See e-testing-plan.md for complete test plan.**

Headline: `t/validate-perl-conventions.t` is the unit test (fixture-driven). End-to-end coverage comes from the existing `cwf-manage validate` integration test surface, which now includes the new check by virtue of Step 3's wiring.

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results.**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Out-of-scope temptations to resist:
- Refactoring `stop-stale-status-detector` "while we're here" — the convention doc explicitly grandfathers it.
- Adding any end-user-facing `cwf-manage refresh-hashes` (or equivalent) subcommand. Out of scope here **and out of scope permanently**: exposing hash regeneration to installed projects would let any caller silently re-bless modified scripts, breaking the integrity model. Hash updates remain a maintainer-only operation in the upstream source repo.

If a deferral becomes necessary, follow the standard scope-completion procedure (user approval, follow-up task).

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
