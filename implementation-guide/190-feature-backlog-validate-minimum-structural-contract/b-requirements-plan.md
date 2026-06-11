# backlog validate minimum structural contract - Requirements
**Task**: 190 (feature)

## Task Reference
- **Task ID**: internal-190
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/190-backlog-validate-minimum-structural-contract
- **Template Version**: 2.1

## Goal
Specify what it means for `backlog-manager validate` to assert a **minimum structural
contract** — the AST elements the read/mutate paths depend on — so that a clean validate
result is a reliable signal of manageability, and define how that contract is verified
without rejecting flexible, valid content.

## Problem Context (grounding)
`validate_backlog_tree` (`.cwf/lib/CWF/Backlog.pm`) only walks `$tree->{entries}`. The parser
recognises a backlog entry **only** by `^## (Task|Bug): <title>`; any other content falls into
`$tree->{intro}` and is never validated. A foreign-but-well-formed-markdown `BACKLOG.md` parses
to **zero entries**, so every entry-level rule passes vacuously and `validate` reports success
while `list` shows "0 items". Separately, the mutation subcommands (`cmd_add`, `cmd_modify`,
`cmd_delete`, `cmd_retire`) call `parse_backlog_tree` but **never** `validate_backlog_tree`, so
no write is currently gated on structural conformance.

## Functional Requirements
### Core Features
- **FR1 — Structural contract assertion**: `validate` MUST assert that `BACKLOG.md` conforms to a
  minimum structural contract (the AST elements the manager relies on). On non-conformance it MUST
  emit a dedicated structural error (new rule, e.g. `BACKLOG-000` class) and exit non-zero.
  The *defining elements* of the contract (what counts as conformant) are to be specified as a
  concrete, deterministic predicate in `c-design-plan.md`; that predicate MUST yield an unambiguous
  pass/fail on every corpus member named in FR4 so AC1/AC2 are independently verifiable.
  *AC*: a foreign, well-formed-markdown `BACKLOG.md` (no recognised skeleton) fails `validate` with
  the structural rule, not a vacuous success.
- **FR2 — Empty-vs-foreign discrimination**: The contract MUST distinguish a *legitimately empty*
  backlog (conforms to the skeleton, zero entries) from a *foreign* file (does not conform).
  "Zero entries" alone MUST NOT be the failure signal. Note the three-way collision the predicate
  must resolve: a **foreign** file, a **legitimately empty/header-only** file, and a **legacy
  `**Field**:`** file can *all* parse to zero `entries` (the legacy case lands in `body_raw`); the
  contract MUST sort these to fail / pass / convertible respectively (see FR4).
  *AC*: a header-only / empty-but-conformant backlog validates clean; the foreign file fails.
- **FR3 — Mutation gating**: `add`/`modify`/`delete`/`retire` MUST refuse to write when the
  structural contract is not met, exit non-zero with an actionable message, and leave the file
  byte-unchanged. For `retire` (which touches both `BACKLOG.md` and `CHANGELOG.md`) the structural
  failure MUST abort *before any* write to *either* file — the byte-unchanged guarantee is two-file.
  *AC*: `add` against a foreign `BACKLOG.md` exits non-zero and does not modify the file; a refused
  `retire` modifies neither file.
- **FR4 — Flexibility / non-regression**: The contract constrains only what the manager depends on;
  prose and additions *outside* the required skeleton MUST remain valid. The new structural rule
  MUST NOT reclassify a legacy `**Field**:` file as "foreign": legacy files stay convertible by the
  operator-invoked `normalise` exactly as today (there is no automatic refusal/routing of legacy
  files in the mutation paths — do not assume one exists).
  *AC*: the live `BACKLOG.md` and every existing `t/` fixture validate exactly as before; a legacy
  `**Field**:` file is accepted by the structural rule (then convertible via `normalise`), not
  rejected as foreign.
- **FR5 — CHANGELOG parity decision (design open question)**: Design MUST decide and record whether
  `CHANGELOG.md` needs equivalent minimum-structure treatment beyond the existing `CHANGELOG-001`
  header assertion. If parity is scoped out, the residual risk (a foreign `CHANGELOG.md` passing
  `validate`) MUST be recorded as a backlog item rather than silently dropped.
  *AC*: decision — and, if scoped out, the backlog follow-up — documented in `c-design-plan.md`.

### User Stories
- **As a** new CWF adopter with a pre-existing `BACKLOG.md`, **I want** `validate` to tell me my
  file is not in CWF's manageable shape, **so that** I don't get a false "0 items / no problem" and
  silently lose my backlog on the next write.
- **As a** CWF maintainer, **I want** mutations to refuse on a non-conforming file, **so that**
  `add`/`retire` never corrupt or silently no-op against foreign content.

## Non-Functional Requirements
### Performance (NFR1)
- No measurable regression to `validate`/mutation latency. (The check operating on the
  already-parsed tree — no second file read, no extra fence rebuild — is the expected design
  realisation, settled in `c-design-plan.md`.)

### Usability (NFR2)
- The structural error MUST be actionable: name the *expected* skeleton and point to the format
  (`CWF-PROJECT-SPEC.md`), so an adopter knows to add the expected structure. The message MUST be
  static expected-structure text and MUST NOT echo back foreign file content verbatim; if the
  design cites the offending line, it MUST be length-bounded and control-char-stripped on the same
  basis as `_check_heading_control` (avoids an FR4(c) injection surface into operator/LLM context).
  `normalise` MUST only be suggested for the *legacy `**Field**:`* case — it does not convert
  arbitrary foreign content.

### Maintainability (NFR3)
- The contract MUST be defined in one place in `CWF::Backlog` and reused by both `validate` and the
  mutation gate (single source of truth — no divergent re-implementation per subcommand).

### Security (NFR4)
- No new input-trust surface: the file is treated as data, never executed. Existing `GLOBAL-*`
  checks (BOM, CRLF, control characters) MUST NOT be weakened. The structural rule MUST NOT make
  validate pass on input it previously failed.

### Reliability (NFR5)
- Mutation refusal MUST occur before any write (the write path is already atomic), so a rejected
  mutation cannot leave a partial file. (Zero-false-positive corpus coverage is asserted once under
  FR4/AC4.)

## Constraints
- Perl **core-only**, POSIX (project conventions).
- Contract must remain **flexible** — only the manager-relied-upon skeleton is mandatory.
- No regression to the `normalise` legacy-conversion path or the existing `GLOBAL-*`/`BACKLOG-00x`
  rules.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: >1 week? — No (~1 day)
- [ ] **People**: >2 people? — No
- [ ] **Complexity**: 3+ distinct concerns? — No (validator rule + shared mutation gate + tests)
- [ ] **Risk**: high-risk components needing isolation? — No
- [ ] **Independence**: separable parts? — No

**Outcome**: 0 signals — single task.

## Acceptance Criteria
- [ ] AC1 (FR1): foreign well-formed `BACKLOG.md` fails `validate` with the new structural rule and a non-zero exit.
- [ ] AC2 (FR2): empty-but-conformant backlog validates clean; discrimination is not based on entry count alone.
- [ ] AC3 (FR1/FR2/FR4): the three zero-entry inputs sort correctly — foreign → structural **fail**; empty/header-only conformant → **clean**; legacy `**Field**:` → **accepted** (convertible via `normalise`), not rejected as foreign.
- [ ] AC4 (FR4): live `BACKLOG.md` and all existing `t/` fixtures validate exactly as before (zero false positives on the known-good corpus).
- [ ] AC5 (FR4/NFR5): the documented-canonical empty backlog skeleton (and any bootstrap-emitted `BACKLOG.md`) validates clean under the structural rule — a freshly-set-up CWF project does not fail `validate` on day one.
- [ ] AC6 (FR3): each mutation subcommand refuses on a non-conforming file and leaves it byte-unchanged; a refused `retire` modifies neither `BACKLOG.md` nor `CHANGELOG.md`.
- [ ] AC7 (NFR2): the structural error message names the expected skeleton and the format reference, uses static text (no verbatim echo of foreign content), and only suggests `normalise` for the legacy case.
- [ ] AC8 (FR5): CHANGELOG parity decision (and any residual-risk backlog follow-up) recorded in design.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
