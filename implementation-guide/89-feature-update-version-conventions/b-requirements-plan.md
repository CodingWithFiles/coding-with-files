# Update version conventions - Requirements
**Task**: 89 (feature)

## Task Reference
- **Task ID**: internal-89
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/89-update-version-conventions
- **Template Version**: 2.1

## Goal
Define what the versioning convention must specify, and what `cwf-manage list-releases` must show, to satisfy both the developer (who controls releases) and users (who need a clear upgrade signal).

## Functional Requirements

### FR1 — Version convention documentation
The project `CLAUDE.md` must contain a `## Versioning` section that specifies:
- The version format: `v{major}.{minor}.{task_num}`
- **major**: incremented for breaking changes (wf file format changes, removal of installed features, install incompatibilities)
- **minor**: incremented for new user-visible features (new skills, new workflow phases, new helper scripts)
- **patch = task_num**: the task number of the most recently completed task at time of tagging (never manually set)
- That tagging a release and pushing it are **human-only actions** — models must not tag, push to remote, or suggest merging to main
- That the convention is internal to CWF development and must not be referenced from any installed file

**Acceptance**: Section is present, contains all five bullet points above, and includes an explicit "human-only" statement.

### FR2 — Convention isolation
No file under `.cwf/` (docs, templates, scripts, skills) and no file that ships to users (`install.bash`, `CHANGELOG.md` excerpt, etc.) may reference the versioning convention section.

**Acceptance**: `grep -r "Versioning" .cwf/` returns no matches after implementation.

### FR3 — `cwf-manage list-releases` default filtered view
Given current installed version `v{M}.{m}.{N}`, the default output must show exactly:
1. The latest available patch on the same minor: highest `v{M}.{m}.X` where X > N (omitted if none exists)
2. The latest available patch for each higher minor within the same major: highest `v{M}.{m+1}.X`, `v{M}.{m+2}.X`, … (omitted if none exist)
3. The latest available patch for each higher major: highest `v{M+1}.X.Y`, `v{M+2}.X.Y`, … (omitted if none exist)
4. The installed version, always shown with `(installed)` marker
5. A footer line: `Run 'cwf-manage list-releases --all' to see all releases.` (omitted if no tags were hidden)

**Acceptance**: Output matches this specification for all edge cases (see NFR1).

### FR4 — `cwf-manage list-releases --all`
With `--all` flag, shows every available tag sorted descending (current behaviour), with `(installed)` marker. No footer line.

**Acceptance**: `--all` output is identical to current behaviour for a repo with tags.

### FR5 — Graceful handling when no tags exist
If the remote has no `v*` tags, both default and `--all` modes emit the existing `die_msg("No version tags found")` error. No change required.

**Acceptance**: Existing error path preserved.

## User Stories

- **As a CWF developer**, I want a documented version convention in `CLAUDE.md` so that I know exactly when to bump major vs minor and what the patch number means, without needing to remember it
- **As a CWF developer**, I want the convention to be invisible to users so that they are not confused by internal development process details
- **As a CWF user**, I want `cwf-manage list-releases` to show me "the one version I should probably upgrade to" without scrolling through 50 tags so that upgrading is a single informed decision
- **As a CWF user**, I want `--all` available when I need the full picture

## Non-Functional Requirements

### Performance (NFR1)
- Edge cases the filter must handle correctly:
  - Current version is the latest overall → show only `(installed)`, no footer
  - Current version is latest on its minor but older minors/majors exist → show nothing (older versions are not shown)
  - No higher minor exists within the major → skip that category silently
  - No higher major exists → skip that category silently
  - Multiple higher minors exist → show one line per minor (latest patch each)
  - Multiple higher majors exist → show one line per major (latest patch each)
- Response time: same order as current (single `git ls-remote` call, local filtering)

### Usability (NFR2)
- Output is readable without `--all`; a user should be able to decide whether to upgrade from the default view alone
- Installed version always visible in default view (anchor point)

### Maintainability (NFR3)
- Filter logic is a standalone sub in `cwf-manage` that can be unit-tested with a constructed tag list (no network call needed for tests)
- Uses existing `version_cmp` sub — no new comparison logic

### Security (NFR4)
- No new network calls beyond the existing `git ls-remote`
- `--all` flag validated; unknown flags emit usage error (existing behaviour)

### Reliability (NFR5)
- If `git ls-remote` fails, existing `die_msg` error path unchanged
- Filter must not die on malformed tags (non-semver tags silently skipped, as today)

## Constraints
- Perl only — no new CPAN dependencies
- Must not change the `--all` behaviour (backward compatible)
- Convention doc lives in `CLAUDE.md` only — not in any `.cwf/` file

## Decomposition Check
- [ ] **Time**: No
- [ ] **People**: No
- [ ] **Complexity**: No
- [ ] **Risk**: No
- [ ] **Independence**: N/A

No decomposition needed.

## Acceptance Criteria
- [ ] AC1: `CLAUDE.md` `## Versioning` section present with all required content (FR1)
- [ ] AC2: `grep -r "Versioning" .cwf/` returns no matches (FR2)
- [ ] AC3: Default `list-releases` output matches FR3 for all 6 edge cases in NFR1
- [ ] AC4: `list-releases --all` output unchanged from current behaviour (FR4)
- [ ] AC5: `cwf-manage validate` passes

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 89
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 5 acceptance criteria met. grep -r "Versioning" .cwf/ returns no matches.
cwf-manage validate passes. All 6 NFR1 edge cases covered in unit tests.

## Lessons Learned
The strict v-prefix requirement in parse_semver (v\d+.\d+.\d+ only) was correctly
specified here; the implementation plan's code had a subtle bug that the tests caught.
