# retire bootstraps missing CHANGELOG task entry - Requirements
**Task**: 147 (feature)

## Task Reference
- **Task ID**: internal-147
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/147-retire-bootstraps-missing-changelog-task-entry
- **Template Version**: 2.1

## Goal
Specify what `backlog-manager retire` must do when CHANGELOG has no entry for `--task=N`, so the helper fulfils its stated purpose (mechanically move an item from BACKLOG to CHANGELOG) without preconditions it does not enforce itself.

## Problem Statement
Today, `cmd_retire` calls `find_changelog_entry_by_task_num` and refuses to proceed if no `## Task N: ...` heading exists. CHANGELOG entries are normally written by `/cwf-retrospective` near the end of a task, so any mid-task `retire` invocation fails. The destination heading the helper is asked to *populate* is required to *pre-exist*, which contradicts the helper's purpose.

## Functional Requirements

### Core Behaviour
- **FR1**: When `retire --task=N` finds no `## Task N:` entry in CHANGELOG, it MUST create one before appending the retired-item block, instead of erring. The existing-entry path remains unchanged (no-regression).
- **FR2**: The bootstrapped entry MUST contain, at minimum: a `## Task N: <title>` heading, `### Status: <placeholder>` metadata, `### Impact: <placeholder>` metadata, and a `### Retired Backlog Items` subsection ready to receive blocks. The Status/Impact placeholders MUST be strings that read sensibly to a human inspecting the CHANGELOG mid-task ("In Progress" and "To be summarised at retrospective." or equivalent prose — exact values pinned during design). Placeholders exist only to satisfy the validator's CHANGELOG-002 required-keys check (`CWF::Backlog.pm:441-447`); retrospective overwrites them with authoritative content.
- **FR3**: Bootstrapped entries MUST be additively replaceable by `/cwf-retrospective` — i.e. retrospective can overwrite Status/Duration/Impact/Notable/Changes/title without first having to delete or restructure the stub, and without producing validator errors mid-overwrite.

### Title Derivation
- **FR4**: The bootstrapped entry's title MUST be derived deterministically from the on-disk task directory `implementation-guide/N-<type>-<slug>/`. Same N + same on-disk state → same title, every invocation. The `<type>` token MUST NOT appear in the derived title (matches existing CHANGELOG corpus convention — see `CHANGELOG.md:5,135,161,...`). The title MUST be non-empty, MUST NOT contain `:` or newlines (would break the `^## Task[ \t]+(\d+):` parser at `CWF::Backlog.pm:223`), and MUST be ASCII-printable or valid UTF-8.
- **FR5**: If zero directories match `implementation-guide/N-*-*/` for the requested `N`, `retire` MUST error and write nothing — no authoritative source for the title exists.
- **FR6**: If more than one directory matches `implementation-guide/N-*-*/` for the requested `N` (a corner case present only for legacy task 1 in the current corpus; not expected for tasks 2 onward), `retire` MUST error and write nothing. The user's workaround is to manually create the CHANGELOG entry first; this preserves correctness without inventing CLI surface for a one-occurrence corner case.
- **FR7**: Bootstrapped title quality is explicitly secondary to determinism. Slug-derived titles will be lossy compared to maintainer-authored prose (case-folded, hyphenated, truncated at 50 chars by `task-workflow create`'s slug rule); retrospective remains the authoritative source of the final title.

### CLI Surface
- **FR8**: No new flags, no renamed flags, no changed flag semantics. Today's failing invocations succeed after the fix; today's succeeding invocations remain succeeding and produce equivalent output. The existing `--note` flag continues to apply to the first block in a bootstrapped entry exactly as it does today for blocks appended to an existing entry.

### User Stories
- **As a** CWF user retiring a backlog item mid-task, **I want** `retire` to handle the missing CHANGELOG entry itself, **so that** I am not forced to hand-craft an entry or defer the retire to retrospective time.
- **As the maintainer of `/cwf-retrospective`**, **I want** bootstrapped entries to be additively replaceable, **so that** the retrospective phase does not need bootstrap-aware branching.

## Non-Functional Requirements

### Atomicity (NFR1)
- Bootstrap-then-append MUST preserve the existing failure-recovery property: if the process dies between CHANGELOG write and BACKLOG write, the recovered state must be safely re-runnable (today's invariant — see `backlog-manager:467-469` comment). Specifically, the CHANGELOG MUST be written exactly once per `retire` invocation (single in-memory mutation of the parsed tree, single `atomic_write_text`); a partial write must not leave a heading-only stub with no retired block while BACKLOG is also mutated. Recovery on re-run relies on `find_changelog_entry_by_task_num` (`CWF::Backlog.pm:583`) locating the bootstrapped entry via its `task_num` field, and the existing dedup path (`backlog-manager:471-474`) skipping the re-write.

### Validation (NFR2)
- `backlog-manager validate` MUST pass after every successful retire — bootstrap path or existing-entry path. Measurable: invoke validator post-retire and check exit code 0. The bootstrapped entry (with placeholder Status/Impact per FR2) MUST not trigger CHANGELOG-002 missing-required-key errors.

### Round-trip (NFR3)
- `parse(serialise(bootstrapped_entry)) == bootstrapped_entry`. Measurable: byte-identical serialisation after parse-then-write of a CHANGELOG containing only bootstrapped entries.

### Security (NFR4)
- Bootstrap MUST NOT widen the existing attack surface: symlink defence at `backlog-manager:444-445` MUST remain in force; the existing `--task` integer-validation gate (`backlog-manager:428-429`) MUST still run before any filesystem access; title derivation MUST NOT interpolate any string into shell, MUST NOT permit `..` path traversal during directory lookup, and MUST treat slug characters as data (not shell tokens) at every stage. Design MUST confirm the bootstrap path does not introduce a second TOCTOU window beyond the one already documented at line 441-443.

## Constraints
- Must not regress the existing dedup behaviour: a retire whose block is already present under the entry remains a no-op for the CHANGELOG write (`backlog-manager:471-474`).
- No changes to `CHANGELOG.md` schema in a way that invalidates already-present entries (additive validator relaxation is permitted only if FR2's placeholder approach proves insufficient — preferred path is placeholders, not schema change).
- The bootstrapped entry's position in CHANGELOG MUST preserve the existing descending-task-number ordering convention (exact insertion strategy pinned in design — anchor under the H1, ordered by task num).
- No new helper script files; the change lives inside `backlog-manager` and `CWF::Backlog`. Existing task-num-to-directory resolution at `CWF::TaskContextInference.pm:560` (`_get_task_dir`) SHOULD be reused or promoted to a shared module rather than re-implemented; the design phase decides which.

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — one helper, one parser invariant, one title-derivation rule.
- [ ] **Risk**: High-risk components? No.
- [ ] **Independence**: Separable parts? No.

No decomposition signals triggered.

## Acceptance Criteria
- [ ] **AC1 (FR1)**: With CHANGELOG containing no `## Task N:`, `retire --id=<slug> --task=N` exits 0 and the CHANGELOG now contains a `## Task N: <title>` entry with placeholder Status/Impact metadata and a `### Retired Backlog Items` subsection containing the block for `<slug>`.
- [ ] **AC2 (no-regression)**: With CHANGELOG already containing `## Task N: <title>` and full retrospective metadata, retire produces a CHANGELOG diff that touches only the inside of that entry's `### Retired Backlog Items` subsection (no metadata changes, no other entries reordered).
- [ ] **AC3 (NFR3, FR1)**: After AC1, a second `retire --id=<other-slug> --task=N` succeeds, takes the existing-entry path, and the resulting CHANGELOG round-trips through `parse → serialise` byte-identically.
- [ ] **AC4 (NFR2)**: After AC1 and AC3, `backlog-manager validate` exits 0; no CHANGELOG-002 (missing-required-key) errors against the bootstrapped entry.
- [ ] **AC5 (FR4, FR5, FR6)**: With `implementation-guide/N-<type>-<slug>/` present and uniquely matched, bootstrap derives the same title on repeated calls. With zero matches, retire errors and writes nothing. With multiple matches (replicate the legacy task-1 condition: create extra dirs with the same N), retire errors and writes nothing.
- [ ] **AC6 (FR8)**: Help output (`backlog-manager retire --help`) is unchanged; no flags added, removed, or relabelled. `--note=<text>` applied during bootstrap appears under the first block of the bootstrapped entry identically to how it appears today under an existing entry.
- [ ] **AC7 (NFR1)**: Inject a controlled failure between the bootstrap-CHANGELOG-write and the BACKLOG-write by exercising the helper at a function-call seam (no real crash needed — call the constituent helpers directly to simulate the half-written state, then re-invoke `retire` and assert success + dedup). Result: no duplicate blocks, BACKLOG correctly updated on re-run.
- [ ] **AC8 (NFR4)**: A symlinked `CHANGELOG.md` still causes retire to refuse (existing guard preserved). A `--task` value that is non-integer still fails before any filesystem read. A task directory whose `<slug>` contains shell metacharacters (`;`, `$`, backtick, newline; created in a tmp test fixture) does not cause shell execution, command injection, or path escape; bootstrap either accepts the slug as inert data (subject to FR4's title constraints) or errors cleanly.
- [ ] **AC9 (FR3)**: Starting from a CHANGELOG containing only a bootstrapped Task-N stub (per AC1), apply a representative retrospective-style edit (overwrite Status/Impact, insert Notable + Changes subsections, replace the title) and confirm `validate` exits 0 throughout and after the edit. Note: this AC does NOT require byte-identical output vs from-scratch retrospective; semantic validity is the bar.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 147
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
