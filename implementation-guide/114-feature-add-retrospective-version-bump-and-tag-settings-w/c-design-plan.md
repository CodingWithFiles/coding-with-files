# Add retrospective version bump and tag settings with versioning helper script - Design
**Task**: 114 (feature)

## Task Reference
- **Task ID**: internal-114
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/114-add-retrospective-version-bump-and-tag-settings-w
- **Template Version**: 2.1

## Goal
Define the architecture and interface contracts for a deterministic, configurable retrospective-phase versioning subsystem.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### KD1 — Three thin scripts over one with subcommands
- **Decision**: Three separate helper scripts (`cwf-version-next`, `cwf-version-bump`, `cwf-version-tag`) rather than one script with subcommands.
- **Rationale**: Each script is <40 lines and has a single, named effect. `ls .cwf/scripts/command-helpers/` makes the API self-evident. Mixed precedent in the codebase (some helpers are subcommand-dispatchers like `task-workflow`, others single-purpose like `cwf-set-status`); for behaviour this small the dispatcher overhead isn't justified.
- **Trade-offs**: Three files instead of one; shared logic must go in a module (see KD2). Acceptable.

### KD2 — Shared logic in `CWF::Versioning` Perl module (extracted from `cwf-manage`)
- **Decision**: New module `.cwf/lib/CWF/Versioning.pm` exporting: `parse_semver()`, `version_cmp()`, `next_version()`, `current_version()`, `bump_to($version)`, `tag_at($version)`, `read_config()`, `wf_step_setting($step, $key, $default)`. The first two functions are extracted from existing code in `.cwf/scripts/cwf-manage` (currently inlined as `parse_semver` and `version_cmp` around lines 166–195) and `cwf-manage` is refactored to import them.
- **Rationale**: Rule-of-three is already met across `cwf-manage` + the three new scripts. Extracting eliminates duplication on day one. Naming follows the existing action-oriented convention (`CWF::TaskState`, `CWF::WorkflowFiles`, `CWF::Validate::*`).
- **Trade-offs**: One module + a small `cwf-manage` refactor. Behaviour-preserving; covered by the existing `cwf-manage` tests.

### KD3 — `cwf-project.json` is the single source of truth
- **Decision**: Both the wf-step config (`wf_step_config.retrospective.{bump_version,tag_version}`) and the HITL major.minor field (`versioning.major_minor`) live in `implementation-guide/cwf-project.json`. `version.yml` is reduced to a one-line pointer.
- **Rationale**: One file to edit. Consistent with where other project settings live. `version.yml` becoming descriptive-only (not source-of-truth) eliminates a future drift class.
- **Trade-offs**: Existing `version.yml` consumers must be audited and updated. Audit scope is small (grep shows only the file itself; no scripts read it).

### KD4 — Patch number is supplied by the caller via required `--task-num=N`
- **Decision**: All three scripts take `--task-num=N` as a **required** argument. Patch derivation from filesystem scanning is rejected as the primary mechanism — it would silently miscount during in-flight tasks. The retrospective skill, which knows the task it is running for, passes `--task-num={current_task_num}` explicitly.
- **Rationale**: Matches the v2.0 versioning convention in `CLAUDE.md` ("patch = task_num … of the most recently completed task at time of tagging"), and removes the silent-failure mode. Callers always supply the number; scripts never guess.
- **Trade-offs**: One required CLI argument per call. Trivial in practice; the skill always has the number.

### KD5 — Settings validation extends `CWF::Validate::Config`
- **Decision**: Add new schema rules to `.cwf/lib/CWF/Validate/Config.pm`:
  - `versioning` (optional object); if present must contain `major_minor` matching `/^v\d+\.\d+$/`
  - `wf_step_config` (optional object); if present must be an object whose values are objects of `key → boolean`
- **Rationale**: One place handles all schema validation. `cwf-manage validate` (which we already run as a post-commit guard) automatically picks up the new rules.
- **Trade-offs**: None — strict superset of current behaviour; absent fields remain valid.

### KD6 — `cwf-version-bump` writes `last_released` field, not `versioning.major_minor`
- **Decision**: `cwf-version-bump` does NOT modify `versioning.major_minor` (HITL-owned). Instead it writes (or updates) `versioning.last_released: "v{major}.{minor}.{patch}"` in the same `cwf-project.json` block. Idempotency check: if `last_released == next_version`, no-op.
- **Rationale**: Keeps the human/script ownership boundary crisp — humans edit `major_minor`, the script writes only `last_released`. Works in both `tag_version: true` and `tag_version: false` modes (so we don't need to fall back to `git describe`, which would be unreliable when no tag exists).
- **Trade-offs**: Two related fields in the same block instead of one. Acceptable.
- **Caveat (documented)**: If a human edits `major_minor` between two retrospective runs for the same task, idempotency does not hold for that task — the next bump will write a fresh `last_released` under the new `major_minor`. This is by design (humans own `major_minor`, and changing it is a deliberate semver bump) and is documented in the versioning standard doc.

### KD7 — Tag is annotated, on-main-only, never forced, never pushed
- **Decision**: `cwf-version-tag` (a) refuses to run unless `HEAD` is on the project's main branch (read from `cwf-project.json` if configured, else default to `main`); (b) runs `git tag -a <version> -m "<message>"`; (c) refuses if tag exists (`git tag -l <version>` non-empty); (d) never invokes `git push`.
- **Rationale**: Tagging on a feature branch produces a tag pointing at a commit that the squash workflow (see KD8) is about to rewrite, leaving the tag dangling. Pushing tags is a separate human decision (per CLAUDE.md). Refusing on existing tag prevents silent overwrite.
- **Trade-offs**: External adopters who want lightweight tags or non-main tagging must adapt — out of scope. The skill ordering (KD8) ensures the script is called at the right moment.

### KD8 — Bump runs pre-squash, tag runs post-squash, both inside retrospective
- **Decision**: Within the retrospective skill, the order is: (1) write `j-retrospective.md`, (2) run `cwf-version-bump` (mutates `cwf-project.json`), (3) commit those two files together as the j-phase checkpoint, (4) run the existing squash-to-checkpoints workflow (which collapses all phase commits into one final commit on the checkpoints branch), (5) run `cwf-version-tag` (which now points at the squashed commit on the checkpoints branch, ready for the human's `git merge --ff-only main` to bring tag and commit to main together).
- **Rationale**: Putting bump before squash means the `last_released` change ends up in the squashed commit, not as a stray tail commit. Putting tag after squash means the tag points at the final commit that will end up on main, not a transient pre-squash commit. CwF's own configuration (`tag_version: false`) makes step 5 a no-op message; for external adopters it produces the correct tag.
- **Trade-offs**: The skill becomes longer (renumbering required, see Component Overview). The squash workflow is unchanged.

### KD9 — JSON write normalises formatting; documented one-time cost
- **Decision**: `cwf-version-bump` writes `cwf-project.json` via `JSON::PP->new->pretty->canonical->encode($hash)` (2-space indent, sorted keys), atomic-rename, no in-place patching. The existing file's whitespace and key order will be normalised on the first bump.
- **Rationale**: In-place key replacement (regex or JSON-Patch-style) is fragile and error-prone for deeply-nested objects. Canonical pretty-print is deterministic — once normalised, subsequent bumps produce zero-diff formatting noise. The file is currently ~100 lines of structured JSON; one-time normalisation diff is reviewable.
- **Trade-offs**: First bump produces a larger-than-strictly-necessary diff (formatting + the actual value change). Acceptable; documented in the script's `--help` and the versioning standard doc.

## System Design

### Component Overview
- **`CWF::Versioning`** (new module, `.cwf/lib/CWF/Versioning.pm`): pure logic. Reads `cwf-project.json`, parses semver, computes next version, performs bump and tag operations. Hosts the `parse_semver` and `version_cmp` functions extracted from `cwf-manage`. No direct CLI.
- **`cwf-version-next`** (new script): prints next version. Read-only. Required: `--task-num=N`.
- **`cwf-version-bump`** (new script): writes `versioning.last_released` if `wf_step_config.retrospective.bump_version` is true. Atomic write (tmp + rename) with canonical pretty-print. Required: `--task-num=N`.
- **`cwf-version-tag`** (new script): creates annotated git tag if `wf_step_config.retrospective.tag_version` is true. Refuses unless on main and tag does not already exist. Required: `--task-num=N`. Optional: `--message=STR`.
- **`cwf-manage`** (modified): refactored to import `parse_semver` and `version_cmp` from `CWF::Versioning` rather than defining them locally. Behaviour-preserving.
- **`CWF::Validate::Config`** (extended): adds rules for `versioning` and `wf_step_config` objects.
- **`cwf-retrospective` skill** (modified, SKILL.md): step list grows from 10 to 12. Insertion points:
  - **Step 9 (NEW) — Version bump**: invoke `cwf-version-bump --task-num={task_num}` after CHANGELOG/BACKLOG (Step 8). The cwf-project.json mutation is staged as part of the j-phase checkpoint commit.
  - **Step 10 (was 9) — Squash to checkpoints**: unchanged.
  - **Step 11 (NEW) — Version tag**: invoke `cwf-version-tag --task-num={task_num} --message="Task {task_num}"` after squash. CwF's config makes this a skip; external adopters with `tag_version: true` get the tag.
  - **Step 12 (was 10) — Suggest merge**: unchanged.
- **`version.yml`** (modified): rebranded (CIG → CwF); reduced to a brief description noting `cwf-project.json` is the source of truth for `versioning.major_minor` and `versioning.last_released`.

### Data Flow

```
retrospective skill
    │
    ├── cwf-version-next --task-num=N           → prints "v1.0.N"
    │       └── CWF::Version::next_version()
    │               ├── read_config()           → reads versioning.major_minor
    │               └── max task num            → derives patch
    │
    ├── cwf-version-bump --task-num=N           → updates cwf-project.json (or no-op)
    │       └── CWF::Version::bump_to(v1.0.N)
    │               ├── wf_step_setting('retrospective','bump_version', true)
    │               ├── if false: print "skipped (config)" exit 0
    │               ├── if last_released == v1.0.N: print "already at v1.0.N" exit 0
    │               └── atomic write (tmp + rename)
    │
    └── cwf-version-tag --task-num=N            → creates tag (or no-op)
            └── CWF::Version::tag_at(v1.0.N)
                    ├── wf_step_setting('retrospective','tag_version', false)
                    ├── if false: print "skipped (config)" exit 0
                    ├── if tag exists: warn + exit 1
                    └── git tag -a v1.0.N -m "<message>"
```

## Interface Design

### CLI

```
cwf-version-next --task-num=N
    Stdout:  "v1.0.N\n"
    Stderr:  errors only
    Exit:    0 success
             1 missing/invalid versioning.major_minor, or missing cwf-project.json,
               or missing/invalid --task-num

cwf-version-bump --task-num=N
    Stdout:  "bumped: v1.0.N"             (wrote last_released)
           | "skipped: bump_version=false" (config disables)
           | "already at v1.0.N"           (idempotent)
    Exit:    0 in all three cases above
             1 missing major_minor / missing config / write failure / bad args

cwf-version-tag --task-num=N [--message=STR]
    Stdout:  "tagged: v1.0.N"             (created annotated tag)
           | "skipped: tag_version=false"  (config disables)
    Exit:    0 on success or skip
             1 not on main branch / existing tag / missing major_minor /
               git failure / bad args
```

Pre-conditions checked uniformly:
- `cwf-project.json` exists at `implementation-guide/cwf-project.json` (else exit 1, "config not found at <path>")
- `versioning.major_minor` present and matches `/^v\d+\.\d+$/` (else exit 1, "versioning.major_minor missing or malformed in <path>")
- `--task-num` is a positive integer (else exit 1, "--task-num=N required, got <value>")

### Data Model — `cwf-project.json` additions

```json
{
  "versioning": {
    "major_minor": "v1.0",
    "last_released": "v1.0.113"
  },
  "wf_step_config": {
    "retrospective": {
      "bump_version": true,
      "tag_version": false
    }
  }
}
```

Defaults when keys absent:
- `versioning.major_minor` — required if any retrospective version action runs; missing → exit 1 with field-naming error
- `versioning.last_released` — absent on first bump; treated as "no prior release"
- `wf_step_config.retrospective.bump_version` — `true`
- `wf_step_config.retrospective.tag_version` — `false`

### Module API — `CWF::Versioning`

```perl
use CWF::Versioning qw(parse_semver version_cmp
                       next_version current_version
                       bump_to tag_at
                       read_config wf_step_setting);

my ($maj,$min,$pat) = parse_semver('v1.0.113');               # (1,0,113) or () on failure
my $ord             = version_cmp('v1.0.113','v1.0.97');      # +1 / 0 / -1
my $cfg             = read_config();                          # hashref; dies on missing/invalid
my $bump_on         = wf_step_setting('retrospective','bump_version', 1);  # 1|0
my $next            = next_version(task_num => 114);          # "v1.0.114"
my $cur             = current_version();                      # "v1.0.113" or undef
my $r               = bump_to('v1.0.114');                    # {status=>'bumped'|'skipped'|'idempotent', message=>...}
my $r               = tag_at('v1.0.114', message => 'Task 114');  # {status=>'tagged'|'skipped'|'error', message=>...}
```

## Constraints
- Perl, `JSON::PP`, no new CPAN deps
- Atomic file writes (tmp + rename) for any `cwf-project.json` mutation
- `cwf-manage validate` must remain green
- Helper scripts: `0500` permissions, SHA256-tracked, registered in `.cwf/security/script-hashes.json`

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: >1 week? No (1-2 days)
- [ ] **People**: >2 people? No
- [x] **Complexity**: 3+ concerns? Yes (module, scripts, validation, skill, config rebrand) — but isolated by module boundary
- [ ] **Risk**: High-risk components needing isolation? No
- [ ] **Independence**: Parts independently workable? Sequential

**Decision**: One task; module-based decomposition keeps complexity local.

## Validation
- [x] Design review completed (3-subagent map/reduce); applied: required `--task-num`, semver extraction from cwf-manage into `CWF::Versioning`, JSON formatting normalisation policy, on-main-only tagging, bump-pre-squash / tag-post-squash ordering, skill step renumbering
- [x] Architecture aligned with existing patterns (`CWF::TaskState`, `CWF::Validate::Config`, `cwf-manage` semver parsing now shared)
- [x] Integration points verified (j-retrospective skill insertion points, cwf-manage validate, cwf-project.json schema location)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 114
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
KD1-KD9 implemented as designed, with one tweak from the `/simplify` pass: the pure semver utilities (`parse_semver`, `version_cmp`) ended up in `CWF::Common` rather than `CWF::Versioning`, since they're general-purpose. Version-with-config logic stayed in `CWF::Versioning` per the design.

## Lessons Learned
KD8 (bump-pre-squash, tag-post-squash) was the right call — the j-retrospective step ordering enforces it via the SKILL.md step list. Without that explicit ordering, it would have been easy to put bump+tag both before the squash and end up with dangling tags after the squash rewrites commits.
