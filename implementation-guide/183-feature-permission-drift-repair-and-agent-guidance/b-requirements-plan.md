# Permission-drift repair and agent guidance - Requirements
**Task**: 183 (feature)

## Task Reference
- **Task ID**: internal-183
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/183-permission-drift-repair-and-agent-guidance
- **Template Version**: 2.1

## Goal
Specify what CWF must provide so permission drift against recorded ceilings is repaired
promptly (a one-time sweep plus a standing agent rule), without weakening the
"surface, never smooth" guarantee for sha256/content tampering.

## Functional Requirements
### Core Features
- **FR1 (repair sweep)**: Every file whose working-tree permissions exceed its recorded
  ceiling in `.cwf/security/script-hashes.json` is clamped to the recorded value using the
  existing `cwf-manage fix-security` (clear excess bits, never raise). The three Task-173
  scripts are included if still drifted. No new repair engine is built.
  - **Note (current state)**: at planning time `fix-security --dry-run` already reports `0`
    files (the planning-phase clamp of two Task-182 files + Task-174's earlier clamp of the
    Task-173 three cleared the residual). FR1 is therefore close to a no-op today; the
    mechanism is genuinely exercised by FR6's induce-drift→fix procedure, which design and
    testing should treat as the centrepiece rather than the sweep.
  - **AC1**: `cwf-manage fix-security --dry-run` **exits 0** with `0` files to repair, and
    `cwf-manage validate` reports no permission violation tree-wide. (Exit 0 — not merely a
    "0 repaired" count — so a coexisting sha256 `UNFIXABLE` entry cannot read as success.)
- **FR2 (fix-on-sight rule)**: A standing, discoverable rule instructs agents to repair
  permission drift the moment they observe it (e.g. when a checkpoint/`validate` run surfaces
  it) by running `cwf-manage fix-security`, instead of deferring it as "out of scope" or a
  "separate backlog item". The rule lands in an **installed, agent-discoverable CWF artefact**
  (a convention doc under `.cwf/docs/conventions/`, optionally surfaced via `.claude/rules/`),
  with the project `CLAUDE.md ## Conventions` pointer entry referencing it as the other
  conventions do. The exact path(s) are pinned in design — the rule must NOT be placed only in
  a section that does not exist in any committed/installed file (the user-global
  `~/.claude/CLAUDE.md ## Critical Rules` is out of scope: not checked in, not installable).
  The rule contains ≥1 concrete negative example drawn from the real failure mode
  (Task 174 deferred clamp; the Task-182 `cwf-claude-settings-merge` defer-as-out-of-scope).
  - **AC2**: a grep of the design-pinned, in-repo path(s) finds the rule; it names
    `cwf-manage fix-security`, rejects the defer-as-out-of-scope response, and gives ≥1 example.
- **FR3 (safe/unsafe boundary + persistence semantics)**: The guidance states unambiguously:
  - **permission clamping** is the only auto-repairable integrity violation; **sha256/content
    drift** is NOT auto-repairable and MUST be surfaced per `hash-updates.md` "what NOT to
    build" (no "recompute the hash to clear validate" instruction); and
  - permission drift is a working-tree property git does not record (tracked modes are
    `100755`/`100644`), so the repair is a working-tree action — not a committable diff — and
    leaves `git status` clean. It must not promise a git-committed fix. Persistence semantics
    cross-reference `hash-updates.md` ("recorded permissions are a ceiling") rather than
    re-deriving them.
  - **AC3**: the guidance contains the explicit perm-vs-sha256 distinction, cross-references
    `hash-updates.md`, states the working-tree-only / no-committable-diff nature, and contains
    no instruction to recompute a hash to clear `validate`.
- **FR4 (no new silencing surface)**: No tool, flag, or mode is added whose effect is to
  silence `cwf-manage validate` output without first surfacing it (reaffirms hash-updates
  "what NOT to build"). The only repair path remains the existing clamp-only `fix-security`.
  - **AC4**: no new `cwf-manage` subcommand/flag is introduced.
- **FR5 (backlog subsumed)**: The "Restore Task-173 permission drift on three helper scripts"
  BACKLOG item is retired as superseded by this task via `backlog-manager retire`.
  - **AC5**: the item no longer appears in `backlog-manager list`; it is recorded under Task
    183's `### Retired Backlog Items` block in CHANGELOG (the form `retire` actually writes —
    design reconciles this with any per-task `## Task 183` section).
- **FR6 (demonstrated)**: A repeatable, documented procedure shows the rule works: starting
  from a clean tree, induce drift via `chmod 0700` on a recorded-`0500` tracked script,
  confirm `validate` flags it, apply `cwf-manage fix-security`, and confirm `validate: OK` with
  `git status` clean (no diff — tying back to FR3's working-tree-only claim).
  - **AC6**: the procedure is documented in the task's testing files and reproduces
    drift → `validate` flags → `fix-security` → `validate: OK` + clean `git status`.

### User Stories
- **As an** agent mid-task, **I want** an unambiguous standing rule that permission drift is
  mine to fix now via one command, **so that** I stop rationalising it as out-of-scope and
  leaving a security-relevant bit set.
- **As a** CWF maintainer, **I want** the auto-repair boundary drawn at clamping only,
  **so that** "fix permissions promptly" can never be misread as "recompute hashes to make
  validate quiet".

## Non-Functional Requirements
### Performance (NFR1)
- Negligible: the repair is an on-demand `chmod` sweep over the recorded set; no measurable
  effect on workflow phase timing. No new per-commit cost beyond the existing checkpoint
  `validate`.

### Usability (NFR2)
- The rule is actionable: it quotes the exact command (`cwf-manage fix-security`), matching the
  remediation string `validate`/`fix-security` already print, so an agent that sees the
  violation sees the same fix it is told to run.
  - **AC (folded into AC2)**: the command string in the rule is byte-identical to the command
    the tools' remediation/output lines name.

### Maintainability (NFR3)
- Single source of truth for the perm-repair rule; other locations cross-reference it per
  `cross-doc-references.md` rather than duplicating prose. British spelling; no superlatives.

### Security (NFR4)
- Auto-repair is limited to clamping (`actual & recorded`) — it can only remove bits, never
  add them. sha256/content drift is never auto-absorbed. This boundary (FR3/FR4) is the
  security core of the task.

### Reliability (NFR5)
- `fix-security` is idempotent: re-running on a clean tree repairs `0` files and leaves
  `validate` OK. The rule therefore cannot loop or oscillate.

## Constraints
- Reuse `cwf-manage validate` / `fix-security`; no new repair engine (FR1/FR4).
- **Hash-refresh disclosure (forward to design)**: design MUST resolve which artefacts the
  guidance touches. If it lands in a hash-tracked artefact (`.claude/rules/`, `.claude/agents/`),
  refresh its `sha256` in the same commit and list `.cwf/security/script-hashes.json` as a
  Supporting Change per `hash-updates.md` plan-time disclosure; chmod edited scripts back to
  recorded. A project-root `CLAUDE.md` and `.cwf/docs/conventions/*.md` are NOT hash-tracked —
  if the rule lands only there, no refresh is needed, but that must be a stated decision.
- MUST NOT add any surface that silences `validate` without surfacing (hash-updates).
- CWF self-hosted workflow (eats its own dogfood).

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No (repair sweep + guidance, coupled).
- [ ] **Risk**: isolable high-risk component? No (R1 is a wording boundary).
- [ ] **Independence**: separable for gain? No.

**Decision**: no decomposition (unchanged from a-task-plan).

## Acceptance Criteria
- [ ] AC1 (FR1): `fix-security --dry-run` exits 0 with 0 files; `validate` no perm violation tree-wide.
- [ ] AC2 (FR2/NFR2): standing rule present at design-pinned in-repo path(s); quotes `cwf-manage fix-security` byte-identically, rejects defer-as-out-of-scope, ≥1 example.
- [ ] AC3 (FR3): explicit perm-vs-sha256 boundary + `hash-updates.md` cross-reference; working-tree-only/no-committable-diff stated; no "recompute hash" instruction.
- [ ] AC4 (FR4): no new validate-silencing surface added.
- [ ] AC5 (FR5): Task-173 backlog item retired to CHANGELOG (Retired Backlog Items) under Task 183.
- [ ] AC6 (FR6): drift → `validate` flags → `fix-security` → `validate: OK` + clean `git status`, documented and reproducible.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
