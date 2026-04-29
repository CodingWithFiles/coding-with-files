# Reject Overlong Task Slugs - Requirements
**Task**: 119 (feature)

## Task Reference
- **Task ID**: internal-119
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/119-reject-overlong-task-slugs
- **Template Version**: 2.1

## Goal
Define what `/cwf-new-task` and `/cwf-new-subtask` must do when a user-supplied task description would slugify to more than the 50-character limit.

## Functional Requirements

### Core behaviour

- **FR1 — Reject overlong slugs at task creation**: The slug-generation path used by `/cwf-new-task` and `/cwf-new-subtask` must reject any description whose slugified form exceeds 50 characters. The validation lives in the underlying script (the same script the skill calls) — not in the skill — so that direct script invocation, `--destination=` overrides, and any future caller all hit the same rejection. On rejection: the task directory must not be created, the task branch must not be checked out, and no template files must be written.
  - **AC1.1**: Given a description that slugifies to > 50 characters, the script exits with non-zero status and no files or directories are created under `implementation-guide/`
  - **AC1.2**: Given a description that slugifies to exactly 50 characters, the task is created normally
  - **AC1.3**: Given a description that slugifies to < 50 characters, the task is created normally (no behaviour change from today)
  - **AC1.4**: For subtasks (e.g. `48.1.2`), the limit applies per slug component, not to the total nested path. A subtask whose own description slugifies to ≤ 50 chars is created normally regardless of parent path length
  - **AC1.5**: When the script is invoked with `--destination=...` directly (skipping `construct_destination`), the slug component of the destination basename is still validated against the 50-char limit; an overlong destination basename is rejected the same way as an overlong description

- **FR2 — Error message**: On rejection, the script writes a single error to STDERR that the user can act on without reading source code. The error includes (1) the offending slug or a reference to "task description"; (2) the slug's actual length in characters; (3) the 50-character limit; (4) a recovery instruction telling the user to use a shorter description. The error is prefixed `[CWF] ERROR:` to match the existing `cwf-manage` `die_msg` convention.

- **FR3 — Single source of truth for the limit**: The literal value `50` appears in exactly one place in the codebase.
  - **AC3.1**: `grep -rn "\b50\b"` across `.cwf/scripts/command-helpers/`, `.cwf/lib/`, and `.claude/skills/cwf-new-task/`, `.claude/skills/cwf-new-subtask/` returns the limit value in at most one location (the script's named constant)

- **FR4 — Skill must not pre-truncate**: The SKILL.md guidance for `/cwf-new-task` and `/cwf-new-subtask` must instruct the LLM not to truncate the description before calling the script. The script owns the rejection.
  - **AC4.1**: `/cwf-new-task "..."` with an overlong description produces the script's `[CWF] ERROR:` error visible to the user, not a silently-shortened slug
  - **AC4.2**: SKILL.md no longer contains the text "truncate 50 chars" (or equivalent instruction to the LLM to truncate)

- **FR5 — No retroactive validation**: Existing tasks already on disk with previously-truncated slugs must continue to work unchanged.
  - **AC5.1**: `/cwf-task-plan`, `/cwf-status`, `/cwf-extract`, and other skills that operate on existing tasks succeed on tasks with slugs ≥ 50 characters that were created before this fix (smoke-test outcome)
  - **AC5.2**: No CWF script runs the new validation against existing `implementation-guide/` directories; the validation fires only when creating new tasks (implementation constraint)

### User Stories

- **As a** CWF user **I want** task creation to fail loudly when my description is too long **so that** my branch name and directory name match what I typed instead of being silently truncated mid-word
- **As a** CWF user **I want** the error to tell me what to change **so that** I can immediately retry with a shorter description without reading source code

## Non-Functional Requirements

### Performance (NFR1)
- The length check is one comparison per task creation; no measurable performance impact. Not a quality gate for this task.

### Usability (NFR2)
- The error message must be self-explanatory: a user who has never read CWF source code must understand both what failed and what to do next from the error alone
- The error must point to the input the user controls (the description / slug), not to internal CWF concepts (e.g. "buffer size" would fail)
- Failure must be atomic: validation runs **before** any filesystem writes (directory creation, template copying, etc.). Either the task is fully created (directory + branch + templates) or nothing is. No partial state on disk after a rejection.

### Maintainability (NFR3)
- The limit value must be a named constant in the script (not a magic number embedded in `substr` or a regex)
- The validation logic must be unit-testable in isolation (per the test patterns established in Tasks 115 and 116)

### Security (NFR4)
- N/A — input is a user-typed task description on a local CLI; no auth surface, no external input

### Reliability (NFR5)
- The validation must be deterministic: the same description always produces the same outcome (pass or fail) on any environment
- Exit code on rejection must be non-zero so calling shells and the `/cwf-new-task` skill can detect failure programmatically

## Constraints
- Limit value is fixed at 50 characters in this task. Design phase confirms placement (named constant in the script). Any future change to the limit, or making it configurable, is out of scope here.
- Character-counting semantics (codepoints vs bytes vs graphemes): out of scope at requirements level — design will lock in Perl `length`/`substr` semantics (codepoints) consistently with the existing `generate_slug` function
- Breaking change: users with overly long descriptions will see a new error where previously they got a (silently truncated) success. Must land with a CHANGELOG entry that explains the change and the recovery
- This task itself uses a deliberately short description (`reject-overlong-task-slugs`) to dogfood the new constraint
- No filesystem-level limits are at issue; the 50 is stylistic, not technical

## Decomposition Check
- [ ] **Time**: <1 day → no decomposition
- [ ] **People**: 1 person → no decomposition
- [ ] **Complexity**: 2 small concerns → no decomposition
- [ ] **Risk**: low → no decomposition
- [ ] **Independence**: unitary → no decomposition

No signals triggered.

## Acceptance Criteria (rolled up)
- [ ] AC1: All FR1.x — overlong rejected (incl. `--destination=` bypass and per-component subtask limit); exact-limit and under-limit accepted
- [ ] AC2: FR2 — error message includes offending slug, actual length, 50-char limit, and recovery instruction; written to STDERR with `[CWF] ERROR:` prefix
- [ ] AC3: FR3.x — literal `50` appears in exactly one source-of-truth location
- [ ] AC4: FR4.x — skill no longer instructs the LLM to truncate; script-side error is visible to the user
- [ ] AC5: FR5.x — existing tasks unaffected by the change (skill smoke-test + no validation on existing dirs)

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 119
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 5 FRs and the named NFRs delivered: FR1 (rejection at all surfaces — TC-3/4/9/11), FR2 (error message contents — TC-7), FR3 (single source of truth — TC-13 grep), FR4 (skill no longer pre-truncates — TC-14 grep), FR5 (existing tasks unaffected — TC-15 status-aggregator on tasks 100, 115). NFR-1 atomicity verified by TC-8 (tempdir unchanged after rejection); NFR-3 testability satisfied by the 8-case unit test file using the established `*main::die_msg` override pattern.

## Lessons Learned
See j-retrospective.md.
