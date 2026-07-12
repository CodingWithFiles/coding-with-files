# R3 shell-hygiene convention and allowlist seed - Requirements
**Task**: 227 (feature)

## Task Reference
- **Task ID**: internal-227
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/227-r3-shell-hygiene-convention-and-allowlist-seed
- **Template Version**: 2.1

## Goal
Specify the two remaining R3 deliverables — a shipped shell-hygiene **convention doc**
and a read-only **Bash allowlist seed** at `cwf-init` — such that a new CwF-using project
inherits both without re-deriving the rules, extending (not duplicating) the existing
`cwf-claude-settings-merge` allowlist path, and never widening the envelope past read-only.

## Reuse baseline (established by review — not green-field)
The Bash allowlist is **already** seeded at `cwf-init` step 6d by
`.cwf/scripts/command-helpers/cwf-claude-settings-merge`: it merges `Bash(<path>:*)`
entries for every `.cwf/` command-helper into `.claude/settings.json` → `permissions.allow`,
idempotently, additively (a `%seen` guard preserves existing entries), symlink-safely, and
**never** touches the harness-owned `settings.local.json`. Therefore:
- FR4's "`.cwf/` helper invocations" half **already ships** — the new work is the curated
  **read-only generic-command** corpus (e.g. `git status`, `git log`, `git diff`, `ls`,
  `grep`) plus its safety gate.
- The settings target (`.claude/settings.json` `permissions.allow`) and entry syntax
  (`Bash(<cmd>:*)` / `Bash(<cmd>)`) are **already decided** by that helper — reuse them.
- Task 220's `tool-check-seed` is **not** the reuse target: it is a deny-regex blocklist
  writing `settings.local.json` (the file FR7 forbids) — a different mechanism.

## Functional Requirements
### Core Features
- **FR1 — Shell-hygiene convention doc.** A single Markdown doc ships under
  `.cwf/docs/conventions/` consolidating the **generalisable** shell-interaction rules,
  each with a one-line rationale, stating principles (not tool-specific regexes).
  - AC: doc exists at `.cwf/docs/conventions/<name>.md`; lists the curated rules (FR6);
    each has a rationale.
- **FR2 — Single-source, no duplication.** The doc **references**, not restates, rules
  already owned by shipped (`.cwf/`) surfaces: the subagent tool-tier rubric
  (`.cwf/docs/conventions/subagent-tool-selection.md`), the "Blocking bash anti-patterns"
  table (`.cwf/docs/skills/cwf-agent-shared-rules.md`), the tool-check enforcement surface
  (Task 220), and `tmp-paths.md`. It adds only rules not already documented (heredoc/inline-
  script avoidance, `chmod && execute` over `perl script`, no `perl -c`/`bash -n` pre-check,
  scratch-file discipline for one-offs). It must **not** link the maintainer-only `docs/`
  tree (`perl.md`, `git-path-output.md`) — those are not installed into user projects.
  - AC: no rule text copied verbatim; overlapping topics linked; no `docs/`-tree link.
- **FR3 — Runtime discoverability, injection-safe.** The doc is referenced from at least one
  shipped runtime surface an agent already reads (e.g. `cwf-agent-shared-rules.md`). The
  reference is static CWF-authored text and interpolates no user-supplied string (task slug,
  args), so it cannot become a prompt-injection carrier.
  - AC: at least one committed reference resolves to the new doc's path; the reference
    contains no templated user input.
- **FR4 — Read-only generic-command allowlist seed at `cwf-init`.** Extend the existing
  `cwf-claude-settings-merge` allowlist path (no second writer) so `permissions.allow` also
  receives a curated set of **read-only** generic commands, in addition to the `.cwf/`
  helpers it already seeds.
  - AC: after seeding, `permissions.allow` contains the curated read-only entries; they land
    in `.claude/settings.json` via the existing merge path.
- **FR5 — Curated read-only corpus, enumerated with justification.** The seeded generic
  command set is explicitly listed, each entry paired with a one-line read-only
  justification. This list is the closed set FR6's gate validates against.
  - AC: an enumerated corpus exists (design/doc) with a per-entry read-only rationale.
- **FR6 — Fail-closed safety gate (closed-set membership, not verb blocklist).** An automated
  check proves every seeded generic entry is a member of the FR5 closed set **and** cannot
  cause mutation, arbitrary child execution, or network I/O — including via flags/subcommands
  (`git commit`/`push`, `find -exec`/`-delete`, `xargs`, `sed -i`, `perl -e`/`-i`, redirection
  to file). Because the harness honours command **prefixes**, entries must be specific enough
  (command+subcommand, e.g. `git status`, never bare `git`) that no prefix admits a
  mutating/exec/network form.
  - AC: a test asserts closed-set membership and rejects a deliberately-planted unsafe entry;
    no entry is a bare command whose prefix admits an unsafe subcommand.
- **FR7 — Rule curation decision (generalisable vs maintainer-personal).** Record, with a
  one-line rationale each, which candidate *doc* rules ship as universal convention and which
  are excluded as maintainer-personal taste or CWF-development-only. Corpus: the
  `feedback_no_*` / shell-hygiene MEMORY entries and the anti-pattern set.
  - AC: an include/exclude table exists with a rationale each; clearly-personal items excluded.
- **FR8 — Additive, reversible, safe-on-malformed.** Seeding preserves all pre-existing
  `permissions.allow` entries and order; a project that declines is byte-for-byte unchanged;
  re-running is convergent (no duplicates); a crash mid-write leaves a well-formed file; and a
  **pre-existing malformed** `.claude/settings.json` is refused/warned, never clobbered. The
  written file is parse-validated (well-formed JSON, entries match the read-only schema)
  before the seed is considered applied.
  - AC: pre-existing entries survive; opt-out leaves the file unchanged; re-run adds no
    duplicates; an invalid pre-existing settings file is not overwritten.

### User Stories
- **As a** maintainer starting a new CwF project **I want** the shell-hygiene rules shipped
  as convention **so that** I don't re-derive them prompt-by-prompt across sessions.
- **As an** agent in a freshly-inited project **I want** known-safe read-only commands
  pre-allowed **so that** routine inspection doesn't stall on permission prompts.
- **As a** security-conscious owner **I want** the seed read-only, additive, and fail-closed
  **so that** enabling it never silently widens what a mutating command may do.

## Non-Functional Requirements
- **NFR1 (Performance):** seeding runs only at `cwf-init`/opt-in time; no hook hot-path cost.
- **NFR2 (Usability):** the convention reads as project-neutral guidance, scannable in one
  sitting; the seed's default posture and opt-out are a single documented, inspectable action.
- **NFR3 (Security):** the safety property of FR6 is the backbone — fail-closed, enforced by
  test not convention. (Reuse/writer-safety are stated once in FR4/FR8, not repeated here.)

## Constraints
- **Location split (CLAUDE.md):** the doc binds all CwF users → `.cwf/docs/conventions/`,
  never the maintainer-only `docs/conventions/`.
- **Hash discipline:** any hashed `.cwf/` script edited refreshes `script-hashes.json` in the
  same commit.
- **Scope:** the Task-206 path-injection hook (R3's original part 3) is out of scope
  (addressed by Task 224/R7); this task is the doc + the read-only allowlist extension only.

## Open Decisions (resolve in design — R4 discipline)
- **D1 (default posture + opt-out):** Is the read-only seed **on-by-default** at `cwf-init` or
  opt-in, and how does a project decline? FR8's "byte-for-byte unchanged when declined" is only
  testable once this is fixed. *(Genuinely open.)*
- **D2 (doc scope):** Is the new doc **main-loop-scoped** (cross-referencing the subagent
  rubric) or does it **supersede/generalise** `subagent-tool-selection.md`? Requirements assume
  add-and-link; design confirms.
- **D3 (code home):** Extend `cwf-claude-settings-merge` directly vs a curated static list it
  reads — both land in the same settings target; design picks the cleaner seam.
- *(Resolved by review — no longer open: settings target = `.claude/settings.json`
  `permissions.allow`; entry syntax = `Bash(<cmd>:*)`/`Bash(<cmd>)`.)*

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — doc + seed.
- [ ] **Risk**: high-risk components needing isolation? The seed's permission-widening is
      contained by FR6's fail-closed gate; not isolation-worthy.
- [x] **Independence**: doc and seed are separable but small and context-shared → 1 signal,
      no decomposition.

## Acceptance Criteria (cross-cutting; per-FR ACs above are authoritative)
- [ ] AC1: Convention doc shipped + referenced from a runtime surface, no `docs/`-tree links (FR1/FR2/FR3).
- [ ] AC2: `cwf-init` seeds a curated read-only corpus into `.claude/settings.json` via the existing merge path (FR4/FR5).
- [ ] AC3: Fail-closed gate rejects a planted unsafe entry and any prefix-unsafe bare command (FR6).
- [ ] AC4: Seed is additive/reversible/idempotent and safe on a malformed pre-existing settings file (FR8).

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All functional and non-functional requirements satisfied: the seed is read-only-only (no
mutating verb), additive/reversible, and byte-for-byte skippable; the doc curates generalisable
rules with the maintainer-personal exclusions recorded. Verified by `t/cwf-claude-settings-merge.t`
(TC-RO1..RO5) and the static doc/anchor checks.

## Lessons Learned
The read-only *admission criterion* (read-only for the whole `:*` glob space, or pinned exact)
proved the load-bearing requirement — it is what forced the `git branch --show-current` exact
pin over the unsafe `git branch:*` prefix.
