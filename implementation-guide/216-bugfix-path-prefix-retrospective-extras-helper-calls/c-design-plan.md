# Path-prefix retrospective-extras helper calls - Design
**Task**: 216 (bugfix)

## Task Reference
- **Task ID**: internal-216
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/216-path-prefix-retrospective-extras-helper-calls
- **Template Version**: 2.1

## Goal
Define the exact edits that give every executed helper invocation in
`.cwf/docs/skills/retrospective-extras.md` the `.cwf/scripts/command-helpers/`
path prefix, and fix the scope boundary (executed commands vs prose pointers).

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### Prefix form
- **Decision**: Prefix each bare helper with the repo-relative path
  `.cwf/scripts/command-helpers/<name>` — the same form already used at
  `retrospective-extras.md:21` (`workflow-manager`) and throughout the
  retrospective `SKILL.md` (lines 24, 29, 31, 51, 55).
- **Rationale**: Consistency with the established convention; the agent runs the
  command verbatim from the git root (guaranteed by the preamble's
  `context-manager location` step) with no guess-then-search.
- **Trade-offs**: Slightly longer lines; none material for a doc.

### In-scope invocations (5)
Executed commands inside fenced/inline code — all get the prefix:
| Line | Current | Becomes |
|------|---------|---------|
| 91  | `checkpoints-branch-manager create` | `.cwf/scripts/command-helpers/checkpoints-branch-manager create` |
| 99  | `checkpoints-branch-manager show-history` | prefixed |
| 111 | `checkpoints-branch-manager verify` | prefixed |
| 122 | `context-manager hierarchy <task-path> --format=json` | prefixed |
| 127 | `context-manager hierarchy <parent_path> --format=json` | prefixed |

### Edit is line-scoped, not name-scoped
Prefix only the 5 enumerated lines. Do **not** blind-replace every helper token:
`workflow-manager` (line 21) and `.cwf/scripts/cwf-manage validate` (line 45) are
already correctly pathed and must not be double-prefixed.

### Out-of-scope (leave unchanged)
- Lines 86 / 118 — `cwf-version-bump` / `cwf-version-tag` are **prose name
  references** that explicitly defer to SKILL.md ("see SKILL.md"), which already
  carries their full paths. They are not invocations, so prefixing them would be
  over-reach and would read oddly as a full path dropped into a parenthetical
  aside.
- `git` / `sleep 1 && git` lines — not command-helpers.

## Constraints
- Single file: `.cwf/docs/skills/retrospective-extras.md`.
- Not tracked in `script-hashes.json` (doc, not script) → no hash refresh.
- No behaviour change to any script; wording/semantics of the steps unchanged.

## Decomposition Check
No signals triggered — single-file, single-concern doc edit (see a-task-plan).

## Validation
- [ ] Inverting check catches inline invocations too — `grep -nE '(checkpoints-branch-manager|context-manager)' retrospective-extras.md | grep -v 'command-helpers/'` returns nothing (every occurrence, fenced or inline, now carries the prefix). The earlier `^\s*`-anchored form was dropped: it never matched the inline `context-manager` at 122/127, so it could pass green with those unfixed.
- [ ] Lines 86/118 (`cwf-version-bump`/`cwf-version-tag`) name references still bare (pointer prose preserved)
- [ ] Lines 21/45 not double-prefixed
- [ ] `cwf-manage validate` clean

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Design implemented as specified; the inverting grep (adopted here after the reviewers caught the `^\s*`-anchored form's inline blind spot) proved correct in g-testing-exec.

## Lessons Learned
A validation check must be shown to fail on the pre-fix input, not merely pass on the fixed one — the anchored grep looked plausible but could not have caught unfixed inline invocations.
