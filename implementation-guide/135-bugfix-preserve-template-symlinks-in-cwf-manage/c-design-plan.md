# Preserve template symlinks in cwf-manage - Design
**Task**: 135 (bugfix)

## Task Reference
- **Task ID**: internal-135
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/135-preserve-template-symlinks-in-cwf-manage
- **Template Version**: 2.1

## Goal
Two narrow changes to `.cwf/scripts/cwf-manage`: (1) make `copy_tree` preserve symlinks instead of dereferencing them, fixing `update_copy`; (2) add a new validator module `CWF::Validate::Templates` that asserts the structural invariant "every `.cwf/templates/{bugfix,chore,discovery,feature,hotfix}/*.template` entry is a symlink whose target resolves inside `.cwf/templates/pool/`". Wire the new validator into `cmd_validate`.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Existing-Code Reuse
Before designing any new component, the following are confirmed present and reused:
- `File::Find::find` — already used in `copy_tree` and `update_copy` (chmod pass) at `.cwf/scripts/cwf-manage:434,465`. The fix lives inside the existing `find` callback in `copy_tree`.
- Perl built-ins `lstat`, `symlink`, `readlink`, `-l`, `-d`, `-f` — no new dependencies.
- `CWF::WorkflowFiles::V21::supported_types` — canonical task-type source (`bugfix`, `chore`, `discovery`, `feature`, `hotfix`). Already consumed by `CWF::Validate::Config`. The new validator imports and calls it; no direct `cwf-project.json` read, no `glob`-derived list.
- `CWF::Validate::*` module shape — five existing modules each export `validate($git_root)` returning a list of violation hashrefs with keys `{category, file, field, actual, expected, fix}` where `category` is uppercase (`CONFIG`, `CONSISTENCY`, `CONVENTIONS`, `SECURITY`, `WORKFLOW`). The new `CWF::Validate::Templates` follows the same shape and uses `category => 'TEMPLATES'`; `cmd_validate` in cwf-manage adds one more line to the `@all_violations` array.
- Violation reporting in `cmd_validate` at `.cwf/scripts/cwf-manage:506-534` — printf format is reused unchanged.

No new utility modules, no new schema fields in `.cwf/security/script-hashes.json`, no new top-level commands.

## Key Decisions

### Decision 1: Where to fix the symlink-dereferencing bug
- **Decision**: Patch `copy_tree` (`.cwf/scripts/cwf-manage:434`). Open the callback with an explicit `lstat($_)`, then test `-l _` before the `-d _` / file branches; on a symlink, validate the target (Decision 1a below) and call `symlink($link, $target) or die_msg(...)`.
- **Rationale**: Single point of fix — `copy_tree` is the only routine in this file that walks a source tree. Affects both calls (`copy_tree(.cwf)` and `copy_tree(.claude/skills)`), which is correct: any symlink encountered should be preserved verbatim, the templates dir is just the most visible case.
- **Trade-offs**:
  - **+** One change, narrow blast radius, easy to revert.
  - **−** Other parts of the source tree might contain symlinks we have not surveyed. Mitigation: enumerate `git ls-files -s | awk '$1=="120000"'` in the implementation phase and confirm the universe of preserved symlinks is intentional. From a quick check, `.cwf/templates/{bugfix,chore,discovery,feature,hotfix}/*.template` are the only ones expected.
  - **Ordering and stat-cache discipline**: Robustness review flagged that the Perl `_` stat-cache can be stale if a prior `-d`/`-f` test populated it from a different file. The fix is to start the callback with an explicit `lstat($_)` so `_` always reflects the current entry's lstat result; then `-l _`, `-d _`, and `-f _` all consult the same cache. `File::Find` defaults to `follow => 0`, so the callback receives the link path itself — `-l` works.

### Decision 1a: Constrain symlink targets during copy (security)
- **Decision**: In the new symlink branch, reject any link whose `readlink()` value is either (i) an absolute path, or (ii) contains a `..` segment that would escape the source-tree prefix when resolved relative to the link's directory. `die_msg("refusing to copy escaping symlink ...")` and abort the update.
- **Rationale**: The security review (Finding 1) noted that recreating an upstream symlink verbatim is a vector for writing arbitrary in-tree references to out-of-tree paths (`../../../../etc/...`, `/etc/...`). The CWF upstream is first-party but the integrity check belongs at the copy boundary, not after-the-fact in the validator (which is post-write).
- **Trade-offs**:
  - **+** Defence in depth: even a compromised upstream cannot plant an escape via this code path. Fail-loud, no silent fallback.
  - **−** Mildly restrictive — but no legitimate symlink in `.cwf/` currently uses absolute or escaping targets (`.cwf/templates/*/` → `../pool/<name>`; `.claude/skills/cwf-*` symlinks are created later by `create_skill_symlinks` and are not in `copy_tree`'s walk). Audit during implementation will confirm.

### Decision 2: Where to put the new validator
- **Decision**: New module `CWF::Validate::Templates` at `.cwf/lib/CWF/Validate/Templates.pm`. Exports `validate($git_root)`. Returns the standard violation list. Add to `cmd_validate`'s `@all_violations` aggregation.
- **Rationale**: Consistent with existing pattern (one validator module per concern: Config, Workflow, Consistency, Security, PerlConventions). The check is structural, not hash-based, so folding it into `Validate::Security` would conflate two different invariants (content hash vs. file-type expectation) and require carving a new section into `script-hashes.json`.
- **Trade-offs**:
  - **+** Reuses an established shape. Unit-testable in isolation. No JSON schema change. Easy to remove the file and one line in `cmd_validate` to revert.
  - **−** Sixth validator module to load. Negligible — these are pure-Perl and small.

### Decision 3: What the new validator checks
- **Invariant**: For each task type *T* ∈ {bugfix, chore, discovery, feature, hotfix} and each entry *E* in `.cwf/templates/*T*/`:
  1. *E* MUST be a symlink (`-l`).
  2. `readlink(E)` MUST resolve to an existing path inside `.cwf/templates/pool/`.
  3. The resolved basename MUST match `E`'s basename (e.g. `feature/a-task-plan.md.template` → `pool/a-task-plan.md.template`).
- **Not in scope**: `.cwf/templates/pool/` itself (those are regular files by design); `.cwf/templates/install/` (regular files, already tracked by `script-hashes.json`); `.cwf/templates/cwf-project.json.template` (regular file).
- **Rationale for the three-part check** (Improvements review suggested simplifying to two; rejected): (1) catches the bug at hand (symlink became regular file); (2) catches a broken or dangling symlink; (3) catches a symlink that points to the wrong pool entry — a hand-edit failure mode that does not surface in (1) or (2). Each is a different failure mode and each gets a distinct `field` value so the user sees which check failed. The cost of (3) is ~5 lines and one `basename` comparison.
- **Read-only and TOCTOU**: The validator only calls `lstat` and `readlink`; it does not act on the target. There is no TOCTOU window — a racing replacement between check and report changes only the wording of the next report, not the world.
- **Trade-offs**:
  - **+** Doesn't depend on content hashes, so a malicious or accidental same-content regular-file substitute still fails the type check.
  - **−** Module is ~80 lines instead of ~40. Acceptable — testable as a unit and aligned with sibling validator size.
- **Truth source for task-type list**: `CWF::WorkflowFiles::V21::supported_types()` — already used by `CWF::Validate::Config`. No `glob`-derived enumeration (which would silently include or exclude directories whenever the templates layout changes), no direct `cwf-project.json` read (the canonical accessor exists for a reason).

### Decision 4: Recovery path for already-broken installations
- **Decision**: Once Decision 1 is in place, re-running `cwf-manage update` on a broken install heals it automatically (the new copy_tree preserves symlinks from upstream). The new validator surfaces the breakage; the existing update command is the fix. No new "cwf-manage fix-templates" subcommand.
- **Rationale**: Simplest possible recovery. Avoids growing the CLI for a one-shot heal that `update` already handles correctly.
- **Trade-offs**:
  - **+** No new command. Discoverable: `validate` fails → message points to `cwf-manage update`.
  - **−** Users who can't or won't run `update` again have no in-place repair. Acceptable — manual `ln -sf` is documented in the violation's `fix` field if needed.

### Decision 5: Reuse of the violation reporting style
- **Decision**: Each violation emitted by `CWF::Validate::Templates` populates:
  - `category` → `"TEMPLATES"` (uppercase, matching sibling validators)
  - `file` → relative path of the broken entry (e.g. `.cwf/templates/feature/a-task-plan.md.template`)
  - `field` → one of `type` (regular file, expected symlink), `target` (dangling), `pool-name` (wrong basename inside pool/)
  - `actual` → observed state (e.g. `"regular file"`, `"dangling: ../pool/nonexistent"`, `"../pool/c-design-plan.md.template"`)
  - `expected` → expected state (e.g. `"symlink to ../pool/a-task-plan.md.template"`)
  - `fix` → user-facing recovery hint (e.g. `"Re-run 'cwf-manage update' to restore symlinks, or 'ln -sf ../pool/<name> .cwf/templates/<type>/<name>'."`)
- **Rationale**: Uniform with the existing `cmd_validate` printf loop (line 522-530). No formatting code added.
- **`cwf-manage fix-security` interaction**: `fix-security` only operates on entries listed in `script-hashes.json`; the new `TEMPLATES` violations are not in that manifest and will not appear in `fix-security` output. This is by design — symlink restoration is the job of `cwf-manage update`, which the recovery hint already names.

## System Design

### Component Overview
- **`copy_tree` (modified)**: Existing helper in `.cwf/scripts/cwf-manage`. Add a symlink branch to the `File::Find` callback that runs *before* the `-d`/file branches.
- **`CWF::Validate::Templates` (new)**: New module exposing `validate($git_root)`. Reads `cwf-project.json` for the supported task types, walks `.cwf/templates/<T>/` for each, performs the three-part check, returns violations.
- **`cmd_validate` (modified)**: One-line change — add `CWF::Validate::Templates::validate($git_root)` to the `@all_violations` aggregation.

### Data Flow
```
cwf-manage update <ref>
    └─ update_copy
        └─ copy_tree(src, dst)                              ← FIXED
            └─ find(callback)
                ├─ lstat($_)                                [explicit, primes _ cache]
                ├─ -l _ ? → assert relative & non-escaping  [new, security gate]
                │         → symlink($link, $target)
                ├─ -d _ ? → make_path($target)
                └─  else → copy($_, $target)

cwf-manage validate
    └─ cmd_validate
        ├─ Config::validate
        ├─ Workflow::validate
        ├─ Consistency::validate
        ├─ Security::validate
        ├─ Security::validate_install_manifest
        ├─ PerlConventions::validate
        └─ Templates::validate          ← NEW
            └─ for each task-type T in cwf-project.json:supported-task-types
                └─ for each entry E in .cwf/templates/T/
                    ├─ -l E ? else violation{field:type}
                    ├─ -e readlink(E) ? else violation{field:target}
                    └─ basename matches ? else violation{field:pool-name}
```

## Interface Design

### `CWF::Validate::Templates`
```perl
package CWF::Validate::Templates;
use strict; use warnings; use utf8;
use Exporter 'import';
our @EXPORT_OK = qw(validate);

# validate($git_root) -> list of violation hashrefs
#
# Each violation:
#   {
#     category => 'templates',
#     file     => $rel_path,           # e.g. '.cwf/templates/feature/a-task-plan.md.template'
#     field    => 'type'|'target'|'pool-name',
#     actual   => $observed,
#     expected => $expected,
#     fix      => $hint,
#   }
sub validate { ... }

1;
```

No public types beyond the violation hash already used by sibling validators. No new config keys. No new JSON schemas.

### `copy_tree` (patched in place)
Pseudocode (only the changed shape; full diff goes in `d-implementation-plan.md`):
```perl
find(sub {
    my $rel = $File::Find::name; $rel =~ s/^\Q$src\E//;
    my $target = "$dst$rel";
    lstat($_);                                                # NEW: prime _ cache
    if (-l _) {                                               # NEW: symlink branch first
        my $link = readlink($_)
            // die_msg("readlink failed on $_: $!");
        die_msg("refusing absolute symlink target: $_ -> $link")
            if $link =~ m{^/};                                # security: no absolute
        die_msg("refusing escaping symlink target: $_ -> $link")
            if _resolves_outside_src($_, $link, $src);        # security: no .. escape
        symlink($link, $target)
            or die_msg("Failed to create symlink $target -> $link: $!");
    } elsif (-d _) {
        make_path($target) unless -d $target;
    } else {
        copy($_, $target) or die_msg("Failed to copy $_ to $target: $!");
    }
}, $src);
```
The explicit `lstat($_)` primes the `_` cache so subsequent `-l _`, `-d _`, `-f _` tests are all consistent against the *symlink itself*, not the target. `_resolves_outside_src` is a small local helper (or inline check) using `File::Spec->rel2abs` + a prefix test against `$src`.

### `chmod 0755` pass at line 465 (out-of-scope note)
The `find(sub { chmod 0755, $_ if -f }, ...)` pass at `.cwf/scripts/cwf-manage:465` is guarded by `-f`, which is false for symlinks, so it is unaffected by this change. No edit needed. Noted here because the robustness review correctly flagged it as a latent hazard for any future change that drops the `-f` guard — `chmod` on a symlink follows the link on most systems.

## Constraints
- **POSIX-only project**: `symlink()` must succeed; fail-loud-not-fall-back if it returns 0.
- **No CLI surface change**: subcommand names and exit codes unchanged on the happy path. `cmd_validate` gains a new failure case (exit 1 with violations) only when the new invariant is broken.
- **No schema migration**: `.cwf/security/script-hashes.json` and `.cwf/install-manifest.json` formats unchanged. The new validator is self-contained.
- **Truth source for task-type list**: `CWF::WorkflowFiles::V21::supported_types()` (already exported, already consumed by `Validate::Config`).

## Threat Model Alignment
Per `.cwf/docs/skills/security-review.md` FR4(a-e), each category is addressed or scoped out:
- **(a) Bash injection**: No shell invocation in either change. `symlink`, `readlink`, `lstat` are Perl built-ins; `copy_tree` already uses no `system`/backticks in this function.
- **(b) Perl/git-output newline splitting**: Validator consumes `readdir`/`readlink` output (single strings, no newline-split git output). No `git ... -z` change needed.
- **(c) Prompt injection**: No LLM context flows through this code path; pure file-system operations.
- **(d) Unsafe env-var handling**: No new env vars; `CWF_SOURCE` (pre-existing) is read elsewhere and is unaffected.
- **(e) Pattern-based / symlink escape**: Addressed by Decision 1a — `copy_tree` refuses absolute targets and refuses targets that resolve outside `$src`. Defence at the write boundary, not after-the-fact in the validator.

## Decomposition Check
- [x] **Time**: >1 week? **No** — two small changes in one file plus one new ~80-line module.
- [x] **People**: >2 people? **No**.
- [x] **Complexity**: 3+ distinct concerns? **No** — copy correctness and a structural validator; same domain.
- [x] **Risk**: High-risk components needing isolation? **No** — bounded changes, no migration.
- [x] **Independence**: Parts workable separately? **Borderline** (could split into 135.1 update fix / 135.2 validator) but they share the same test fixture (a broken templates dir), and one without the other leaves a known gap. Keep as one task — agreed in the plan phase.

**Decision**: No decomposition.

## Validation
- [ ] Design reviewed by 4 plan-review subagents (Improvements, Misalignment, Robustness, Security) — to follow in this skill execution.
- [ ] Integration points verified: `cwf-manage` line numbers and `CWF::Validate::*` shape confirmed by reading the current code at HEAD.
- [ ] Truth source for task-types: confirmed `cwf-project.json:supported-task-types` exists.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 135
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
