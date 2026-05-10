# Refactor BACKLOG/CHANGELOG to heading-tree model - Plan
**Task**: 132 (feature)

## Task Reference
- **Task ID**: internal-132
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/132-refactor-backlog-changelog-to-heading-tree-model
- **Baseline Commit**: 13215d6c514ba988305027c85136062b913c35d6
- **Template Version**: 2.1

## Goal
Replace the `---`-delimited section + `**Field**:` bold-paragraph metadata convention in BACKLOG.md and CHANGELOG.md with a uniform heading-based tree, parsed by CWF::Backlog, so structural invariants live in markdown's own primitives instead of in CWF-specific overlays. Ship a `/cwf-backlog-manager` slash-command skill in the same task so the helper is discoverable through the standard CWF skill surface from day one of the new format.

## Origin
Surfaced during the Task 131 dogfood pass: `backlog-manager list --all-items` reported 45 active entries while BACKLOG.md held 50 `## Task:`/`## Bug:` headings. Root cause: five entries silently merged into preceding sections because the Task 131 marker-migration removed `<!-- Completed: -->` lines that had been acting as *de facto* section terminators, and the parser splits exclusively on `^---$`. Discussion narrowed the underlying issue from "fix the splitter" to "the data model is the bug": flat opaque blobs split on a presentation-layer artefact (`---` HR rule), with metadata signalled by another presentation-layer artefact (bold paragraphs). Replacing both with markdown headings eliminates the class of bug.

## Success Criteria
- [ ] CWF::Backlog returns a structured tree (`{intro, entries => [...]}`) where each entry corresponds to one `## (Task|Bug):`/`## Task N:` heading, by construction — no opaque-blob middle layer
- [ ] BACKLOG.md and CHANGELOG.md contain zero `---` separators and zero `**Field**:` bold-paragraph metadata; metadata is encoded as `### Field: value` headings (or whichever exact form the design phase settles on)
- [ ] `backlog-manager` subcommands (`add`, `delete`, `modify`, `list`, `validate`, `retire`) operate on the new model with behaviour preserved (CLI surface unchanged where possible; output may change in shape)
- [ ] `backlog-manager validate` enforces structural invariants of the new model (one entry per top-level heading; valid metadata field set; body-placement rule from design phase)
- [ ] `prove t/` clean; `cwf-manage validate` clean; net regression count ≤ 0 vs Task 131 baseline (408 tests pre-refactor)
- [ ] `/cwf-backlog-manager <subcommand>` slash command works end-to-end against the live BACKLOG.md and CHANGELOG.md for at least the `list` and `validate` subcommands; SKILL.md follows the same pattern as `/cwf-status` (thin wrapper over the helper)

## Original Estimate
**Effort**: 3-5 sessions (skill addition adds ~0.25 session — small, mostly modelled on `/cwf-status`)
**Complexity**: High
**Dependencies**: Task 131 (`backlog-manager` + `CWF::Backlog` baseline); no external deps

## Major Milestones
1. **Parser & validator on the tree model**: `_parse_sections` replaced with `parse_to_tree`; rule set ported; old accessors (`entry_title`, `entry_metadata`, etc.) become tree-walks
2. **Mutators on the tree model**: `cmd_add`, `cmd_delete`, `cmd_modify`, `cmd_retire` operate on structured fields; serialiser round-trips entries verbatim
3. **Live-file migration**: BACKLOG.md and CHANGELOG.md mechanically migrated; validate clean post-migration; entry-by-entry diff against snapshot proves no content loss
4. **Test surface rewrite**: existing 408 tests updated/replaced to assert against tree shape; coverage parity confirmed; `prove t/` green
5. **`/cwf-backlog-manager` skill**: thin wrapper SKILL.md (modelled on `/cwf-status`) shipped under `.claude/skills/cwf-backlog-manager/`, registered, and exercised end-to-end via at least `/cwf-backlog-manager list` and `/cwf-backlog-manager validate` against the migrated live files

## Risk Assessment

### High Priority Risks
- **Round-trip data loss during live-file migration**: a single bug in the migration script can quietly drop entry content from BACKLOG.md or CHANGELOG.md. Markdown is forgiving — invalid output still renders, so casual review may not catch the loss.
  - **Mitigation**: snapshot both files at task start; programmatic diff (entry-by-entry, by title) of pre- and post-migration trees; dry-run `validate` before any commit; entry count assertion (pre-migration `## Task:`/`## Bug:` count == post-migration entry count)
- **Test surface rewrite shedding coverage**: ~408 tests assert against the flat-blob shape. Mass-rewriting risks dropping or weakening assertions in the process.
  - **Mitigation**: keep the original test files in a sidecar (e.g. `t/legacy-flat-blob.t.bak`) until the new tests demonstrably cover the same surface; per-rule coverage checklist before deleting the sidecar; subagent plan-review of the test rewrite specifically

### Medium Priority Risks
- **Body-placement convention regret**: choosing wrong between prose-before-metadata vs `### Body:` heading vs metadata-at-end-of-entry bakes into every entry; reversing later is migration work.
  - **Mitigation**: design phase explicitly enumerates all three options with reasoning; user reviews and signs off before implementation; note placement is *the* design decision of this task
- **Rendering / TOC blast on GitHub**: `### Field: value` headings appear in GitHub's right-hand TOC. With ~50 entries × ~3 metadata fields each, the TOC inflates by ~150 entries, drowning the actual entry titles.
  - **Mitigation**: render BACKLOG.md preview locally (`pandoc` or similar) before committing; flag the visual change explicitly in `h-rollout.md`; consider TOC-suppressing comment if GitHub honours one
- **Atomic-write semantics regression**: Task 131's two-file write contract (CHANGELOG first, BACKLOG second; dedup-on-retry crash recovery) must survive the refactor unchanged. Refactor risks subtle behavioural drift.
  - **Mitigation**: lift the existing atomic-write tests verbatim into the new test surface; treat them as a contract regression gate
- **Skill surface mismatch with established CWF patterns**: `/cwf-backlog-manager` could end up shaped differently from sibling skills (`/cwf-status`, `/cwf-current-task`) — wrong allowed-tools set, missing `user-invocable`, divergent argument-passing convention — surfacing as friction the first time someone tries to use it.
  - **Mitigation**: study `/cwf-status`'s SKILL.md frontmatter and `Mandatory context` block before writing the new skill; reuse the same shape; subagent plan-review of the SKILL.md specifically against the established skill conventions

## Dependencies
- **Task 131**: provides `backlog-manager` and `CWF::Backlog` as the baseline being refactored. Already merged to main.
- No external deps; no other in-flight tasks block this.

## Constraints
- POSIX-only Perl; no new CPAN dependencies (consistent with project rules)
- `cwf-manage validate` must pass at every checkpoint commit (`script-hashes.json` integrity)
- Atomic two-file write semantics for `retire` are non-negotiable
- Migration must be reversible from a snapshot (single-file `cp` restore)

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? Estimate is 3-5 sessions → no
- [ ] **People**: Does this need >2 people working on different parts? Solo task → no
- [x] **Complexity**: Does this involve 3+ distinct concerns? Parser, mutators, migration, test rewrite → yes
- [x] **Risk**: Are there high-risk components that need isolation? Round-trip migration + test rewrite → yes
- [ ] **Independence**: Can parts be worked on separately? Tightly coupled — can't ship parser without mutators (CLI breaks), can't ship migration without both (live files unparseable) → no

**Decomposition decision**: 2 signals triggered, but the work is inherently atomic — none of the format-refactor milestones can ship to main on its own without breaking the helper. The skill milestone (5) is technically separable, but folding it in costs ~0.25 session and means the skill ships against the new format from day one rather than against Task 131's format with a follow-up to retarget. Subtasks would add bookkeeping overhead without isolating risk. Treat the five milestones as de-facto sub-units within a single task; if any milestone reveals it needs its own design phase, decompose then via `/cwf-new-subtask`.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
- Duration: ~5 sessions (estimated 3-5; landed at upper end). Implementation exec overran by ~25-50% due to migration-script iteration and the unplanned `/simplify` pass.
- All five milestones delivered. One in-flight scope addition: first-class `backlog-manager normalise` subcommand for adopter migration.
- Quality outcome: 412 tests green vs 408 baseline; live BACKLOG/CHANGELOG round-trip byte-identical; perf 1.84-1.89× pre-refactor baseline (NFR1 budget was 5×); the missing-entries bug is structurally impossible by construction in the new model.

## Lessons Learned
- "The data model is the bug" was the right call here — a 5-session structural refactor beats a 1-day fragile splitter patch.
- Two of the high-priority risks (round-trip data loss; coverage shedding) were both real and both contained by the planned mitigations (snapshot + entry-by-entry diff; sidecar legacy tests until parity verified).
- The decomposition decision (treat the five milestones as de-facto sub-units of a single task) held — all five milestones were tightly coupled enough that subtask bookkeeping would have cost more than it saved.
