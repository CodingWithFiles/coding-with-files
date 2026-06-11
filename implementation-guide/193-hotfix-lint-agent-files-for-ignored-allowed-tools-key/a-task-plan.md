# Lint agent files for ignored allowed-tools key - Plan
**Task**: 193 (hotfix)

## Task Reference
- **Task ID**: internal-193
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/193-lint-agent-files-for-ignored-allowed-tools-key
- **Baseline Commit**: 5702f4213f9f33abc9fb763837d94265e31aeb9f
- **Template Version**: 2.1

## Goal
Add a `cwf-manage validate` check that flags any CWF agent file carrying an
`allowed-tools:` frontmatter key — a key Claude Code silently ignores in agent
definitions (the correct key is `tools:`), so a misnamed key leaves the agent
with *all* tools instead of the intended restricted set.

## Problem Statement
Claude Code agent frontmatter (`.claude/agents/*.md`) gates tool access via the
`tools:` key. Skills/slash-commands use `allowed-tools:`. The two are easy to
confuse. If an agent file uses `allowed-tools:`, Claude Code ignores it and the
agent receives the **full** tool set — a privilege-escalation footgun that fails
**open** and silently (no parse error, no warning). The four read-only
`cwf-plan-reviewer-*` agents and the `cwf-security-reviewer-changeset` agent all
rely on a correct `tools:` restriction; a future edit slipping to `allowed-tools:`
would silently un-restrict them.

All five current agent files use `tools:` correctly, so this is a **preventative
guard**, not a live-bug fix. No existing agent file changes.

## Success Criteria
- [ ] `cwf-manage validate` emits a violation for any `.cwf-agents`/`.claude/agents`
      `cwf-*.md` file whose frontmatter contains an `allowed-tools:` key, naming the
      file and the correct key (`tools:`); exits non-zero.
- [ ] `cwf-manage validate` stays green on the current tree (all five agents use
      `tools:`), proving zero false positives on the real corpus.
- [ ] A regression test under `t/` covers both the positive (bad key flagged) and
      negative (clean tree passes) cases without mutating the repo's real agent files.
- [ ] New validator obeys CWF Perl conventions (shebang, `use utf8;`, core-only) and
      passes `CWF::Validate::PerlConventions`; any new file's perms/hashes are recorded
      in `script-hashes.json` in the same commit.

## Original Estimate
**Effort**: ~0.5 day
**Complexity**: Low
**Dependencies**: Existing `CWF::Validate::*` aggregation in `cwf-manage` (cmd_validate).

## Major Milestones
1. **Validator module**: `CWF::Validate::Agents` scanning agent files for the
   silently-ignored key, returning the standard violation hashref shape.
2. **Wire-in**: registered in `cwf-manage` `cmd_validate` alongside the other validators.
3. **Test + integrity**: `t/` regression test green; hashes/perms recorded.

## Risk Assessment
### High Priority Risks
- **Wrong/incomplete scan target**: agents are real files at `.claude/agents/` in this
  dev repo but at `.cwf-agents/` (with `.claude/agents/` symlinks) in a consuming
  project. Scanning the wrong path → validator is a silent no-op in one context.
  - **Mitigation**: pin the canonical target in `d-`; `.claude/agents/cwf-*.md`
    resolves to the real file in both contexts (symlink-followed when installed). Test
    must assert the validator actually inspected a file, not vacuously passed.

### Medium Priority Risks
- **Frontmatter parsing brittleness**: naive `grep allowed-tools` could match the
  substring inside body prose or a commented line.
  - **Mitigation**: restrict the match to the leading `---`…`---` YAML frontmatter
    block and to a key at line-start; cover in tests.
- **Scope creep vs the literal request**: `effort:` already appears on
  `cwf-security-reviewer-changeset.md` and other unknown keys are *also* silently
  ignored — tempting to generalise to "lint all unrecognised agent keys".
  - **Mitigation**: hold scope to the requested `allowed-tools:` key for this hotfix;
    surface the generalisation as an explicit **open decision** for the review gate (see below).

## Open Decisions (for review gate)
1. **Scope**: lint only `allowed-tools:` (literal request, recommended for a hotfix),
   or generalise to *any* silently-ignored/unknown agent frontmatter key (catches
   `effort:` and future typos, but needs an authoritative allow-list of valid keys —
   `name`, `description`, `tools`, `model` — which is a moving target)? **Recommend:
   scope to `allowed-tools:` now; file a backlog item for the general key-allowlist linter.**
2. **Home**: a `CWF::Validate::Agents` module under `cwf-manage validate` (recommended —
   matches the existing validator pattern, runs at install/update and on demand) vs a
   PreToolUse write-guard hook (heavier, blocks at edit time). **Recommend: validator module.**

## Dependencies
- `cwf-manage` `cmd_validate` aggregation point and the `CWF::Validate::*` contract
  (violation hashref: `category`, `file`, `field`, `actual`, `expected`, `fix`).

## Constraints
- POSIX/core-Perl only; British prose; no personal names in shipped docs.
- New/edited `.cwf` files: record perms + sha256 in `.cwf/security/script-hashes.json`
  in the same commit ([[hash-updates]]).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: >1 week? No — ~0.5 day.
- [x] **People**: >2 people? No.
- [x] **Complexity**: 3+ distinct concerns? No — one validator + wire-in + test.
- [x] **Risk**: High-risk components needing isolation? No.
- [x] **Independence**: Separable parts? No.

**Conclusion**: 0 signals triggered — no decomposition; proceed as a single hotfix.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Delivered as planned in ~0.5 day. All four success criteria met; both Open Decisions
resolved as recommended (scope to `allowed-tools:`; validator module). Full analysis in
j-retrospective.md.

## Lessons Learned
The "wrong scan target" high risk was mitigated by a single-target resolver and *proven*
non-vacuous by TC-4 (asserts the `.cwf-agents/` branch actually inspected a file). See
j-retrospective.md for the full set.
