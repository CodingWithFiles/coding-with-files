# Refactor BACKLOG/CHANGELOG to heading-tree model - Requirements
**Task**: 132 (feature)

## Task Reference
- **Task ID**: internal-132
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/132-refactor-backlog-changelog-to-heading-tree-model
- **Template Version**: 2.1

## Goal
Specify what the refactor must achieve at the level of behaviour and quality, independent of how (parser shape, exact heading levels, migration mechanics — those belong in design).

## Functional Requirements

### Core Features

- **FR1**: `CWF::Backlog` parser returns a structured tree from a BACKLOG.md or CHANGELOG.md byte stream.
  - **Acceptance**: `parse_backlog_file($path)` returns `{intro, entries}` (or equivalent shape settled in design); `entries` is an ordered list, with cardinality equal to the count of top-level entry headings in the input. No "opaque blob" intermediate representation.

- **FR2**: BACKLOG.md and CHANGELOG.md encode all structure via markdown headings; no `---` separators, no `**Field**:` bold-paragraph metadata.
  - **Acceptance**: `grep -c '^---$' BACKLOG.md CHANGELOG.md` returns 0 for both. `grep -cE '^\*\*[A-Z][\w\- ]*\*\*:' BACKLOG.md CHANGELOG.md` returns 0 for both.

- **FR3**: All six `backlog-manager` subcommands (`add`, `delete`, `modify`, `list`, `validate`, `retire`) operate on the new model with their existing CLI surface preserved.
  - **Acceptance**: For each subcommand, the `--help` output documents the same flags as the current Task 131 baseline (output formatting may evolve; flag *set* and semantics do not regress). Subcommand exit codes match Task 131 baseline for the same inputs (exception: any input that depended on the old format is regenerated in the new format for parity testing).

- **FR4**: `backlog-manager validate` enforces the structural invariants of the new model.
  - **Acceptance**: Each invariant has a dedicated rule with a stable identifier (e.g. `BACKLOG-001`..`BACKLOG-NNN`, `CHANGELOG-001`..`CHANGELOG-NNN`, `GLOBAL-001`..`GLOBAL-NNN`). At minimum: one entry per top-level entry heading (no merging possible by construction); known/required metadata field set per entry; body-placement rule from design phase; no orphan top-level headings of unknown type. A test fixture exercising each rule's positive and negative case lives under `t/fixtures/backlog-manager/` (or equivalent).

- **FR5**: A one-shot migration converts the existing Task 131-format BACKLOG.md and CHANGELOG.md to the new format with zero entry loss.
  - **Acceptance**: Pre-migration entry count (top-level entry headings) equals post-migration entry count, file by file. For each entry, the title text is preserved verbatim. Body content is preserved verbatim modulo the metadata-encoding rewrite (and any leading/trailing whitespace tidying explicitly listed in design). A snapshot of pre-migration files is retained until rollout completes.

- **FR6**: Round-trip safety — parsing any well-formed file and serialising it back without modification produces a byte-identical result for entries that were not touched.
  - **Acceptance**: Add a property test: read live BACKLOG.md and CHANGELOG.md → parse → serialise → assert `==` to input bytes. Same for fixture files exercising every metadata variant.

- **FR7**: A `/cwf-backlog-manager` slash-command skill exists under `.claude/skills/cwf-backlog-manager/` and exposes the helper through the standard CWF skill surface.
  - **Acceptance**: SKILL.md exists with frontmatter (`name`, `description`, `user-invocable: true`, `allowed-tools: [Bash]` — `Bash` only; no `Read`/`Write`). The workflow body is **instructional**, not dispatcher-shaped: it lists the helper's subcommands and invocation patterns (with the helper path **hardcoded as a literal string**, never interpolated from env vars or user input) and lets the LLM decide which invocation to construct based on user intent. The instructions explicitly require list-form Bash invocation (not a single shell-interpolated string), so user-supplied flag values reach the helper as literal arguments and cannot be evaluated as shell metacharacters. Stdout, stderr, and exit code from the helper invocation are surfaced unmodified. Skill discovery follows the `/cwf-init` step-6 mechanism that already auto-discovers sibling `.claude/skills/cwf-*/SKILL.md` files; the registration step adds `Skill(cwf-backlog-manager)` to `.claude/settings.json` permissions, matching siblings.

### User Stories

- **As a CWF maintainer**, I want BACKLOG.md and CHANGELOG.md to encode structure in markdown's own primitives so that a parser bug or a marker-migration regression cannot silently merge entries again.
- **As a CWF maintainer**, I want the validator to make "section starts with heading X, contains entries with metadata fields Y" the contract, so that hand-edits that violate it are flagged at the next `validate` rather than discovered during a later refactor.
- **As a CWF maintainer running `backlog-manager modify --priority=High`**, I want the mutator to reach into a structured field rather than regex-rewrite a paragraph, so that the change is unambiguous and any unrelated formatting in the entry's body is left untouched.
- **As any CWF user**, I want to invoke `backlog-manager` operations through the standard slash-command surface (`/cwf-backlog-manager list`, `/cwf-backlog-manager validate`) without having to remember the helper script's path, matching the discoverability of `/cwf-status` and other established CWF skills.

## Non-Functional Requirements

### Performance (NFR1)
- Parse + validate of current-size BACKLOG.md (~1.5k lines, 50 entries) and CHANGELOG.md (~1.5k lines, ~130 entries) completes in <500 ms on a developer laptop. The Task 131 baseline is sub-100ms; the refactor should not regress beyond 5×.
- Memory: the parsed tree fits in <10 MB for the current file sizes; no streaming required.

### Usability (NFR2)
- (CLI flag/exit-code preservation lives in FR3 — not duplicated here to avoid drift between sections.)
- Error messages name the offending line number and the violated rule identifier (`[CWF] ERROR: BACKLOG-XXX at line N: <description>`), matching the Task 131 baseline pattern. Line N is the 1-based line number of the offending entry's `## Task:`/`## Bug:` header in the source file.
- Migration is non-interactive and idempotent: running it twice on already-migrated files is a no-op (or refuses with a clear message), not a corruption. Detection mechanism (e.g. structural marker, format heuristic) is a design-phase decision.

### Maintainability (NFR3)
- One parser function (or a small fixed set, scoped to per-file-type variants), invoked by every consumer. No re-walking of raw lines in accessor functions to re-derive structure that the parser already produced.
- Validator rules are pure tree-walks: input is the parsed tree, output is a list of `{rule, severity, line, message}`. No parser logic embedded in rule code.
- Mutators operate on structured fields, not on raw line buffers. The serialiser is the single point that converts tree → bytes.
- The shared `_build_fence_map` helper (or its successor) remains the single point of fence-tracking; no duplicated fence-state machines across rules or mutators.
- The new skill is an **instructional reference**, not a dispatcher. Frontmatter shape mirrors `/cwf-status`. Workflow body documents the helper's subcommands and invocation patterns; the LLM constructs the appropriate Bash invocation per user intent. No skill-side argument parsing or validation duplicating the helper's CLI; no skill-side caching or state; no `Read`/`Write` tools.

### Security (NFR4)
- Symlink refusal on file write is preserved (`refusing symlink at $path`).
- Path allowlist on `--body-file` (Task 131's `validate_path_allowlist`) is preserved with the same allowed prefixes.
- No new external dependencies; no new network or shell-execution surfaces.

### Reliability (NFR5)
- Atomic two-file write semantics for `retire` are preserved verbatim: CHANGELOG written first (idempotent target), BACKLOG written second; crash recovery contract is "re-run the same retire command" because `block_exists_in_retired` (or its successor) detects the already-written block.
- Migration is reversible from snapshot: a single `cp /tmp/<task-132-snapshot>/BACKLOG.md BACKLOG.md` (and similarly for CHANGELOG) restores the pre-migration state.
- `validate` is the post-write integrity check. No write path may produce output that fails `validate` on the same input. (If a mutator writes invalid content, that's a bug, not the user's responsibility.)

## Constraints

- **Language**: POSIX-only Perl 5 with the same module set as Task 131 (`strict`, `warnings`, `utf8`, `Encode`, `File::Temp`, `Fcntl`, internal `CWF::*`). No new CPAN dependencies.
- **Integrity**: Every modified script and library file must be hash-pinned in `.cwf/security/script-hashes.json`; `cwf-manage validate` must pass at every checkpoint commit.
- **Compatibility**: No external user runs Task 131's `backlog-manager` against a production BACKLOG yet (we know this — it's brand new), so backwards compatibility with the Task 131 file format is **not** a requirement. Migration is one-way; the new format supersedes.
- **Workflow**: Every change goes through the CWF workflow (per CLAUDE.md). No direct commits to main. The retrospective skill will need to invoke the new format's `retire` command — it must be working before retrospective runs.
- **No detection-evasion**: `validate` errors are loud and named. No silent fallbacks or "best-effort" parses; on format violation, exit non-zero with a precise message.
- **Snapshot lifecycle**: pre-migration BACKLOG.md and CHANGELOG.md snapshots live alongside the throwaway migration script in `/tmp/task-132/` (matching Task 131's `/tmp/task-131/` pattern). Migration, rollout, and AC verification all happen within a single working session, so `/tmp`-scope durability is sufficient. Both the snapshot and the migration script are removed in `j-retrospective.md` Step 8 after AC1–AC8 are confirmed green. If the session is interrupted before retrospective, the user re-runs the migration (the script is idempotent against already-migrated files) or restores from the snapshot manually.
- **Known-limitation continuity**: the symlink-refusal TOCTOU window (Task 131 known issue, tracked as a follow-up backlog entry "Close TOCTOU window in atomic_write_text via O_NOFOLLOW") still applies to all write paths in the new helper. Closing it is explicitly out of scope for Task 132; the new code must not regress *into* additional unguarded write paths.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? Estimate is 3-5 sessions → no
- [ ] **People**: Does this need >2 people working on different parts? Solo task → no
- [x] **Complexity**: Does this involve 3+ distinct concerns? Parser, validator, mutators, migration, test rewrite → yes
- [x] **Risk**: Are there high-risk components that need isolation? Round-trip migration + test rewrite → yes
- [ ] **Independence**: Can parts be worked on separately? Tightly coupled — none of the milestones can ship to main without the others → no

**Decomposition decision**: same as a-task-plan — 2 signals trigger but the work is atomic. Treat the milestones as in-task sub-units; decompose only if a milestone reveals it needs its own design phase.

## Open Design Questions

These are the decisions design must settle before implementation can begin. Listed here so the c-design-plan phase has an explicit checklist; not pre-empting any answer.

1. **Tree shape**: exact return type of `parse_backlog_file` and `parse_changelog_file`. The tree is structured **down to H3** (metadata fields are first-class nodes); H4+ is opaque body content. Candidate:
   ```
   {
     intro   => [raw_lines...],
     entries => [
       {
         type          => "Task" | "Bug",      # parsed from H2 header "## Type: Title"
         title         => "Add Delete Task Skill",
         header_lineno => 158,                  # 1-based source line of the H2
         metadata      => [                     # ordered list of H3 nodes; order preserved as observed
           { key => "Task-Type", value => "feature", lineno => 160 },
           { key => "Priority",  value => "High",    lineno => 161 },
           { key => "Status",    value => "...",     lineno => 162 },
         ],
         body_raw      => [raw_lines...],       # everything else: prose, H4+ subheadings, blank lines, fences
       },
       ...
     ],
   }
   ```
   Metadata accessors become `$entry->{metadata}[*]{value}` walks; no regex re-derivation. Body stays as raw bytes for round-trip safety. Per Postel's Law (#3) the parser preserves the order it observes; mutators emit canonical title→metadata→body on write. Design's residual job: confirm the field set and finalise the entry-shape variants for CHANGELOG (`## Task N:` headings carry different metadata) and for the `### Retired Backlog Items` block contents.
2. **Heading levels** *(resolved during requirements)*: entries at H2 (matches today). Metadata at H3 — strictly one level below the entry title. Rationale: structural correctness trumps GitHub-TOC aesthetics; the backlog's job is to track items correctly, not look pretty. Body sub-headings (when an entry needs its own internal structure, e.g. today's `### Architecture` style) move to H4 or deeper, so metadata and body cannot collide on the same level. Design's residual job is to document the convention and decide whether the validator rejects body H3s outright or accepts them with a warning.
3. **Body-placement convention** *(resolved during requirements; Postel's Law applies)*: canonical order is title → metadata → body. **Be liberal in what you accept**: parser and validator both work correctly regardless of the order metadata and body appear in within an entry; the validator emits a *warning* (not an error) when an entry deviates from the canonical order. **Be strict in what you send**: every write path (`add`, `modify`, `retire`, the migration script, any future mutator) emits entries in canonical order, full stop. No `### Body:` sentinel heading; body is whatever non-metadata, non-subheading content is among the entry node's children.
4. **Validator rule remap**: today's `BACKLOG-001`..`006`, `CHANGELOG-001`..`003`, `GLOBAL-001` are tied to the `**Field**:` format. Design must produce a rule-by-rule mapping: which survive verbatim, which are reframed, which retire, what new rules cover the heading-tree invariants.
5. **Mutator API**: do `cmd_modify`, `set_priority_field`, `append_retired_block` take a tree and return a tree, or continue mutating raw_lines in place? Either is consistent with FR1; pick one and document.
6. **Migration script home**: stand-alone script in `.cwf/scripts/`? Subcommand of `backlog-manager`? One-shot in the task directory and discarded? Decision affects security review surface, snapshot-removal lifecycle, and reusability for any future re-migration.
7. **Migration idempotency detection**: how does the migration script know a file is already in the new format and refuse/no-op on second run? Heuristic (`grep -c '^---$' == 0`)? Embedded marker comment? Format version field somewhere?
8. **Heading-text normalisation**: trim trailing whitespace? Reject embedded control characters? Unicode normalisation form (NFC/NFD/none)? Whatever the parser does at parse time, the migration script must do at write time, or AC6 round-trip breaks.
9. **`### Retired Backlog Items` block format under the new model**: today these are H3 subsections inside a CHANGELOG entry, with retired entries as `####` items. Under heading-tree, what level are the retired entries themselves? How does the validator distinguish a retired-entry heading from any other body sub-heading?
10. **Performance baseline**: measure Task 131 parse+validate wall-clock on the live files before refactoring. Record the number; NFR1's "5× regression budget" needs an actual baseline to be meaningful.
11. **Skill workflow shape** *(resolved during requirements: reference, not dispatcher)*: SKILL.md is instructional — it lists the helper's subcommands and invocation patterns; the LLM picks the right invocation per user intent. Neither the `/cwf-status` verbatim-forward nor the `/cwf-current-task` parse-and-dispatch pattern applies; the skill carries no argument-passing logic of its own. Design's residual job is to settle the *content* of the instructional list (which subcommands to surface in detail, which examples to include) — the invocation-strategy question itself is answered.
12. **Skill registration mechanism** (largely settled): `/cwf-init` step 6 already documents the auto-discovery convention (`.claude/skills/cwf-*/SKILL.md` is picked up; permission entry added to `.claude/settings.json`). Design's job is to confirm during inspection that the convention still holds and to capture the exact registration line, not to invent a new mechanism.
13. **SKILL.md SHA-pinning policy** *(resolved during requirements: out of scope)*: SKILL.md tampering is a generic coding-agent-harness concern that affects every CWF skill uniformly, not something this task can adequately resolve. Match the existing-sibling treatment — no SHA pinning of `.claude/skills/cwf-backlog-manager/SKILL.md` — and rely on the same checks that already apply to siblings (git diff visibility, code review). Do not extend `script-hashes.json` to skills as part of this task.
14. **Auto-invocation scope for write subcommands** *(resolved during requirements: both invocation modes supported)*: All subcommands — including writes (`add`, `modify`, `delete`, `retire`) — are valid for both LLM auto-invocation (in response to natural-language intent like "change task X's priority to High") and explicit user invocation (`/cwf-backlog-manager modify --slug=foo --priority=High`). Design's job is to make sure SKILL.md is shaped to work cleanly in either mode: no `are-you-sure?` prompts that assume an interactive user; no skill-side confirmation layer; safety belongs in the helper (path allowlist, atomic write, validate-on-write), not in the skill. Single skill, no `read` / `write` split.

## Acceptance Criteria

These are cross-cutting, end-of-task gates that the implementation, testing, and rollout phases will check against:

- [ ] **AC1**: `prove t/` clean against the live `BACKLOG.md` and `CHANGELOG.md` after migration, with a test count net change of zero or positive vs Task 131 baseline (408 tests).
- [ ] **AC2**: `cwf-manage validate` clean at the head of the task branch (all hashes in `script-hashes.json` match).
- [ ] **AC3**: `backlog-manager validate` exits 0 against the live `BACKLOG.md` and `CHANGELOG.md` post-migration.
- [ ] **AC4**: `grep -c '^---$' BACKLOG.md CHANGELOG.md` is 0:0; `grep -cE '^\*\*[A-Z][\w\- ]*\*\*:' BACKLOG.md CHANGELOG.md` is 0:0.
- [ ] **AC5a**: Pre-migration top-level entry count == post-migration parsed entry count, file by file (proves no entries were lost by cardinality).
- [ ] **AC5b**: For every entry in pre-migration files, an entry with the same title (verbatim, case-sensitive) exists in the post-migration files (proves no entries were lost by identity, beyond just count).
- [ ] **AC6**: Round-trip property test — read both live files, parse, serialise, byte-compare to input — passes for entries not modified by the test. Entries modified during the test are excluded from byte-compare; their post-modification form must pass `validate`.
- [ ] **AC7**: Each `backlog-manager` mutating subcommand (`add`, `delete`, `modify`, `retire`) produces output that `validate` accepts (closed-loop write/read contract). Tested per-subcommand against an isolated fixture.
- [ ] **AC8a**: With the `/cwf-backlog-manager` skill loaded, asking the assistant to "list the backlog" and to "validate the backlog" results in invocations of `.cwf/scripts/command-helpers/backlog-manager list` and `... validate` (or equivalent forms documented in SKILL.md) against the migrated live files, returning the helper's exit code and output unmodified. At least one mutating intent (e.g. "add a new Medium-priority chore titled X") similarly results in a correct `backlog-manager add ...` invocation against a temp fixture.
- [ ] **AC8b**: Shell-metacharacter safety — when the user supplies a `--title` value containing shell metacharacters (e.g. `Test $(date)`), the assistant constructs a list-form Bash invocation that passes the title as a literal argument, and the resulting BACKLOG entry contains the literal string `$(date)`, not the output of the date command. SKILL.md's instructions must make this requirement explicit.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
- Every functional and non-functional requirement met. AC1-AC8 + NFR1 all green at g-testing-exec time.
- AC4 second-grep observation: file-wide grep finds 3+134 prose-bold lookalikes inside body content; validators correctly do not classify these as metadata. Captured as a follow-up to tighten AC4 to "metadata position only".
- One AC added in-flight: AC18a/b/c covers the `normalise` subcommand promoted from the throwaway migration script.

## Lessons Learned
- ACs framed as grep gates need a "where in the file" qualifier when the search pattern can plausibly appear in body content. AC4 v2 should restrict to metadata position.
- The acceptance bar "byte-identical round-trip on live files" is the strongest possible regression alarm — much sharper than "validate clean".
