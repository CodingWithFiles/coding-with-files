# Add retrospective version bump and tag settings with versioning helper script - Requirements
**Task**: 114 (feature)

## Task Reference
- **Task ID**: internal-114
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/114-add-retrospective-version-bump-and-tag-settings-w
- **Template Version**: 2.1

## Goal
Define functional and non-functional specifications for adding configurable retrospective-phase version bump and tag behaviour, backed by a deterministic helper script and a documented semver standard.

## Functional Requirements
### Core Features
- **FR1 — Hierarchical wf-step config schema**: `cwf-project.json` accepts an optional `wf_step_config` object. Within it, `retrospective.bump_version` (boolean) and `retrospective.tag_version` (boolean) control retrospective behaviour. Acceptance: schema documented; absent values default to `bump_version: true`, `tag_version: false`; any other type is a validation error with a clear message.
- **FR2 — Versioning standard documented**: A new section in `.cwf/docs/` defines the supported versioning scheme as semver (`v{major}.{minor}.{patch}`), states that `{major}.{minor}` is human-maintained, and that `{patch}` is derived from the most recently completed task number. Acceptance: doc exists and is referenced from the helper script's `--help` output.
- **FR3 — HITL `v{major}.{minor}` field**: `cwf-project.json` gains a `versioning.major_minor` field (e.g. `"v1.0"`) maintained by humans. Acceptance: field documented with rules for when to bump major vs minor; helper script reads it; missing field is an error with guidance.
- **FR4 — Versioning helper scripts**: Three new helper scripts following the existing verb-led naming convention in `.cwf/scripts/command-helpers/`:
  - `cwf-version-next` — read-only; prints the next version computed from `versioning.major_minor` + highest top-level task number in `implementation-guide/` (subtask suffixes like `114.1` are ignored for patch derivation)
  - `cwf-version-bump` — writes the new version to its source of truth iff `wf_step_config.retrospective.bump_version` is true; no-op with a clear message if false; idempotent (re-running for the same task number prints `"Already at v{X}"` and exits 0)
  - `cwf-version-tag` — creates an annotated git tag iff `wf_step_config.retrospective.tag_version` is true; no-op message if false; refuses to overwrite an existing tag
- **FR5 — Retrospective skill integration**: `j-retrospective` skill calls the three helper scripts in place of any inline bump/tag logic. Acceptance: skill no longer contains version-construction logic; it invokes the scripts and reports outcomes.
- **FR6 — CwF self-configuration and rebrand**: CwF's own `cwf-project.json` sets `bump_version: true`, `tag_version: false`, and `versioning.major_minor: "v1.0"`. `version.yml` is rebranded (`CIG`→`CwF`), retained as a small file documenting the versioning scheme in use, and explicitly notes that the source of truth for `v{major}.{minor}` is now `cwf-project.json`.
- **FR7 — Backward compatibility and exit-code semantics**: Projects with no `wf_step_config` and no `versioning.major_minor` continue to work for all non-retrospective phases. In retrospective:
  - If `bump_version: true` and `versioning.major_minor` missing → exit code 1 with a message naming the field and file
  - If `tag_version: true` and `versioning.major_minor` missing → exit code 0 with a stderr warning, skip tag
  - If both flags absent (no config) → defaults apply (`bump_version: true`, `tag_version: false`); same rules as above

### User Stories
- **As a** CwF maintainer **I want** the retrospective phase to bump `v{major}.{minor}.{patch}` automatically but never to tag **so that** I keep the tag-as-human-action rule from CLAUDE.md without having to remember it each task.
- **As an** external CwF adopter **I want** to opt into automatic git tagging at retrospective time **so that** my project's release artefacts are produced without an extra manual step.
- **As an** external CwF adopter with a different release process **I want** to opt out of both bump and tag **so that** CwF doesn't interfere with my tooling.
- **As a** developer reading the codebase **I want** version-bumping logic in one helper script, not duplicated across the retrospective skill **so that** behaviour is predictable and changes are localised.

## Non-Functional Requirements
### Performance (NFR1)
- Helper script runs in <1s on the CwF repo (no network calls; reads `cwf-project.json`, scans `implementation-guide/` for the highest task number, optionally writes one file or runs `git tag`).

### Usability (NFR2)
- `--help` text on each helper script names the supported versioning scheme, describes its subcommand, and links to the standards doc. The `--help` does not reference CwF-internal conventions (the human-only-tag rule stays in CLAUDE.md per its own self-instruction at L100).
- Error messages name the missing field and the file it should be in (e.g. `"versioning.major_minor missing in cwf-project.json — add e.g. \"v1.0\""`).
- Defaults match CwF's own settings (`bump_version: true`, `tag_version: false`).

### Maintainability (NFR3)
- Single helper script; no duplication of version logic in the retrospective skill.
- Settings reachable via documented JSON paths (`wf_step_config.retrospective.bump_version`).
- Versioning scheme is the only one supported initially, but the `versioning` block is shaped so a `scheme` field could be added later without breaking existing projects.

### Security (NFR4)
- Helper script must NEVER run `git push`, `git push --tags`, or any network-mutating command — only local file writes and local `git tag`.
- Helper script lives under `.cwf/scripts/command-helpers/` with the same `0500` permission and SHA256-tracked posture as other scripts.

### Reliability (NFR5)
- Atomic writes for `cwf-project.json` updates (write-tmp + rename) so a crash mid-bump does not corrupt the file.
- Tag creation uses `git tag <name>` (annotated, no force) and refuses to overwrite an existing tag.
- Idempotent: running `cwf-version bump` twice for the same task number is a no-op the second time, with a clear message.

## Constraints
- Must preserve the human-only-tag rule from `CLAUDE.md` for CwF's own retrospective.
- Must not break projects with no versioning config (retrospective should warn and continue, not fail).
- Initial scope: semver only. Pluggable schemes are out of scope.
- Helper scripts must be Perl (matching `.cwf/scripts/command-helpers/` conventions), use the `#!/usr/bin/perl -CDSL` shebang and `use utf8;`, and follow the `docs/conventions/perl-git-paths.md` guidance.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No
- [ ] **People**: Does this need >2 people working on different parts? No
- [x] **Complexity**: Does this involve 3+ distinct concerns? Yes (schema, helper script, retrospective integration, version.yml/doc cleanup) — but tightly coupled, see Plan
- [ ] **Risk**: Are there high-risk components that need isolation? No (mitigations in place)
- [ ] **Independence**: Can parts be worked on separately? Not meaningfully

**Decision**: Confirmed in Plan — single task.

## Acceptance Criteria
- [ ] AC1: `cwf-project.json` accepts `wf_step_config.retrospective.{bump_version,tag_version}` and `versioning.major_minor`; absent values yield documented defaults; non-boolean / malformed values produce a clear validation error
- [ ] AC2: Three helper scripts (`cwf-version-next`, `cwf-version-bump`, `cwf-version-tag`) exist with `--help`, respect config flags, and use `-CDSL` + `use utf8;` per Perl conventions
- [ ] AC3: `j-retrospective` skill invokes the helper scripts; no inline version logic remains
- [ ] AC4: CwF's own settings updated to `bump_version: true`, `tag_version: false`, `versioning.major_minor: "v1.0"`; `version.yml` rebranded (CIG → CwF) and points to `cwf-project.json` as source of truth
- [ ] AC5: Versioning standard documented under `.cwf/docs/` and referenced from each helper script's `--help`
- [ ] AC6: Edge cases handled: (a) fresh clone with no tags, (b) re-running bump for the same task is a no-op, (c) subtask numbers (e.g. `114.1`) are ignored when deriving patch, (d) missing fields produce the FR7 exit-code behaviour
- [ ] AC7: `cwf-manage validate` clean; retrospective phase exercised end-to-end on this task

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 114
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All FR1-FR7 and AC1-AC7 met. Plan-review subagent findings on the human-only-tag externalisation, Perl `-CDSL` requirement, and naming-convention alignment all incorporated.

## Lessons Learned
Splitting acceptance criteria from functional requirements helped — ACs became the test-plan input, FRs became the design-plan input. The exit-code semantics in FR7 saved a round-trip in design (clear error/warning split).
