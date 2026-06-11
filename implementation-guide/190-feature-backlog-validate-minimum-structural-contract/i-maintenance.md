# backlog validate minimum structural contract - Maintenance
**Task**: 190 (feature)

## Task Reference
- **Task ID**: internal-190
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/190-backlog-validate-minimum-structural-contract
- **Template Version**: 2.1

## Goal
Record the ongoing-maintenance surface for the `BACKLOG-000` structural contract.

## Applicability
CWF is a file-based developer tool with no runtime service, so the uptime /
alerting / scaling / on-call sections of the template do not apply and are
omitted. What follows is the genuine maintenance surface this feature introduces.

## Maintenance Surface
### Invariants to preserve
- **No verbatim echo (FR4(c)/NFR4)**: the `BACKLOG-000` message must keep
  interpolating only the fixed-enum `$kind` and an integer line number, never the
  offending line text. `TC-7` in `t/backlog-tree-validate.t` is the regression
  guard — any change to the message that begins citing file content fails it, and
  must instead apply NFR2 control-char-stripping/length-bounding. This invariant
  extends to the KD5 CHANGELOG reuse of the exported predicate.
- **Fence-map coupling**: `backlog_structure_errors` reads the parser-cached
  `_source_lines`/`_source_fence` via `_file_lines_and_fence`. The accepted
  boundaries (`TC-8` fenced-heading, `TC-9` unterminated-leading-fence) are
  pinned so a future change to `_build_fence_map` cannot silently shift the
  contract. If fence semantics change, re-run those cases.
- **Hash integrity**: `CWF::Backlog.pm` and `backlog-manager` are hash-tracked.
  Any later edit refreshes its `script-hashes.json` entry in the same commit
  (per `.cwf/docs/conventions/hash-updates.md`); `cwf-manage validate` is the check.

### Known issues / boundaries (documented, not defects)
- Unterminated leading ``` fence masks following foreign content to EOF.
- Pure-prose foreign preamble, and foreign content placed after a genuine entry,
  are not detected.
- Both are fail-open edges of a defensive check (no new capability granted),
  documented in `cwf-backlog-manager.md` and tracked by the Low-priority
  *accepted-boundary gaps* backlog item filed at rollout.

### Scheduled follow-ups (in BACKLOG)
- **KD5 CHANGELOG parity** (Medium) — extend the contract to `CHANGELOG.md`.
- **Accepted-boundary gaps** (Low) — tighten the two fail-open edges above.

## Troubleshooting
- **Symptom**: a conformant `BACKLOG.md` is rejected with `BACKLOG-000`.
  - **Diagnosis**: run `backlog-manager validate --all`; the message names the
    offending line number and kind. Check whether the line is a genuine preamble
    heading/list (expected refusal) or a parser/fence-map regression.
  - **Resolution**: if a false positive, capture the input as a new TC before
    adjusting the predicate; if genuine foreign structure, fix the file (one
    leading `# ` title + prose only, before the first `## Task:`/`## Bug:` entry).
- **Symptom**: `cwf-manage validate` fails for an sha256 reason on either file.
  - **Resolution**: surface it, never smooth it — confirm the working tree matches
    the reviewed change; a legitimate edit refreshes the hash in the same commit.

## Success Criteria
- [x] Maintenance surface captured (invariants, boundaries, follow-ups)
- [x] Troubleshooting entries for the two realistic failure modes
- [x] No runtime monitoring applicable (no service) — explicitly scoped out

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
No code change at this phase. Maintenance surface documented; the two ongoing
follow-ups are filed in BACKLOG (KD5 parity, accepted-boundary gaps).

## Lessons Learned
*To be captured during retrospective*
