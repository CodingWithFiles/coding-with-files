# Adopt .claude/agents format with shared rules - Requirements
**Task**: 143 (feature)

## Task Reference
- **Task ID**: internal-143
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/143-adopt-claude-agents-format-with-shared-rules
- **Template Version**: 2.1

## Goal
Specify what the migrated subagent system must do (functional) and the qualities it must hold (non-functional) such that CWF's review subagents are first-class `.claude/agents/{name}.md` artefacts with a single shared-rules surface.

## Functional Requirements
### Core Features

- **FR1 (agent definitions)**: Every CWF review-subagent role currently launched via `subagent_type="Explore"` with an inline prompt MUST be defined as a `.claude/agents/{name}.md` file and invoked via `subagent_type=<name>`. The in-scope roles are: plan-reviewer (covering criteria columns: improvements, misalignment, robustness, security) and security-reviewer-changeset (exec phase). Whether plan-reviewer is one role parameterised by criteria or four separate roles is a design decision; AC1a/AC1b hold either way because they check for *absence* of the old shape and *presence* of an agent-file reference, not for a specific role count.
  - **AC1a**: `git grep 'subagent_type="Explore"'` across `.claude/skills/` and `.cwf/docs/skills/` returns zero matches for in-scope roles after migration.
  - **AC1b**: Every in-scope invocation site references a `subagent_type=<role>` where `<role>` resolves to a file under `.claude/agents/cwf-*.md` (per FR1a below).

- **FR1-namespace (`cwf-` prefix)**: Every CWF-installed agent file MUST be named `cwf-<role>.md` and live under `.claude/agents/`. The `cwf-` prefix mirrors the existing convention at `.cwf/scripts/cwf-manage:534,540` for skill symlinks; without it (a) CWF agents collide with user-defined or third-party agents sharing a name, and (b) the install/update path cannot safely clean up stale CWF agents without risking user files.
  - **AC1-namespace-files**: Every CWF-installed file under `.claude/agents/` matches the glob `cwf-*.md`.
  - **AC1-namespace-refs**: Every `subagent_type=<role>` reference written by this task names a role beginning with `cwf-`. SKILL-side role names MUST be string literals — never constructed from `{arguments}` or any user-derived value. (Security: closes the surface where a malicious `{arguments}` could redirect a SKILL to a non-CWF agent.)

- **FR1-install (install / update / cleanup lifecycle)**: `cwf-manage` MUST install and update CWF agent files in target repos. The exact installation mechanism (symlink-via-staging-dir as `.claude/skills/` uses today, or direct copy as `.claude/rules/` artefacts use) is a **design-phase decision** locked in `c-design-plan.md`, with the constraint that whichever mechanism is chosen MUST be verified to work with Claude Code's agent-discovery (some discovery paths follow symlinks; some require regular files). The lifecycle guarantees (not the mechanism) are mandatory: clean install materialises agents; update propagates renames/removals; uninstall removes them; non-CWF files under `.claude/agents/` are never touched.
  - **AC1-install**: A clean install of CWF into a scratch repo materialises every CWF agent file at the correct path. The Agent tool can invoke each `subagent_type=cwf-<role>` after install with no manual intervention. `cwf-manage validate` exits 0.
  - **AC1-update**: An update from a pre-task-143 CWF version to post-task-143 in a scratch repo materialises the new agent files (no orphaned old artefacts, no manual steps).
  - **AC1-cleanup-stale**: A subsequent update that renames or removes a CWF agent file removes the stale file from the target repo. Test scenario: (1) install CWF v1 with a `cwf-foo.md`; (2) create a user file `my-foo.md`; (3) update to a CWF version where `cwf-foo.md` is renamed to `cwf-bar.md`; (4) assert `cwf-foo.md` is gone, `cwf-bar.md` is present, `my-foo.md` is untouched.

- **FR2 (shared-rules surface)**: A single shared-rules source MUST exist at one well-known location and MUST be referenced (not copy-pasted) by every CWF agent definition that consumes it.
  - **AC2a**: Adding a new shared rule requires exactly one file edit (the shared source) and no edits to individual agent definitions.
  - **AC2b**: Each agent definition that consumes the shared rules contains a single link or include directive to the shared source rather than restating the rule text.
  - **AC2c**: The shared-rules source has an inclusion-bar paragraph stating the criteria a rule must meet to live there (applies to ≥2 roles AND has a prior incident or convention doc).

- **FR3 (named anti-patterns)**: The shared-rules surface MUST explicitly name the bash anti-patterns that currently **block** subagent runs via permission-prompts, and MUST point to the preferred built-in for each. The blocking set is: `find … -exec grep`, `find … -exec cat`, `cat … | grep`, `sed -n 'X,Yp'`. The non-blocking-but-suboptimal patterns (`find … -name 'pat'`, `head/tail -n` for line ranges) live in the broader rubric at `.cwf/docs/conventions/subagent-tool-selection.md`; the shared-rules surface MUST reference that rubric rather than restating the full table.
  - **AC3a**: Each blocking anti-pattern has a one-line "use this instead" sibling in the shared-rules surface.
  - **AC3b**: An end-to-end run after migration of (at minimum) the security-reviewer-changeset role on a real changeset, plus one plan-reviewer role on a representative plan file, completes with zero permission-prompt interruptions for the blocking-pattern list above. If any prompt fires, treat as a defect and fix before testing-exec.

- **FR4 (minimal tool grants)**: Each `.claude/agents/cwf-*.md` MUST declare an explicit allowed-tools list. The list MUST omit `Bash`, `Edit`, and `Write` unless the role's prompt template requires that tool to perform its work. Read-only review roles MUST be restricted to `Read`, `Grep`, `Glob` (the current `.cwf/docs/conventions/subagent-tool-selection.md` Tier 1 set).
  - **AC4a**: Every CWF agent definition has an `allowed-tools:` (or equivalent frontmatter key — design phase locks the exact spelling against Claude Code's documented `.claude/agents/` schema) field.
  - **AC4b**: No in-scope review agent grants `Bash`, `Edit`, or `Write`.
  - **AC4c (prompt-injection guard)**: Subagent prompts use `{...}` substitutions only for advisory context (e.g. task number, phase identifier, changeset bytes). No substitution drives conditional tool calls, next-step logic, or role selection. Substitution happens at the **calling SKILL**, not at agent-runtime — the Agent tool receives a fully-substituted prompt, never raw `{arguments}`. Mirrors the existing CWF SKILL pattern documented at `.cwf/docs/skills/security-review.md` § "(c) Prompt injection".
    - Verification: code review (not automated). Testing-exec records, per agent: each `{...}` token found, the SKILL that substitutes it, why the value is advisory rather than control-flow, reviewer sign-off.

- **FR5 (preserved skill-side contracts)**: The skill-side classifier rules MUST continue to function unchanged. Specifically: the exec-phase security-review three-tier sentinel classifier in `cwf-{implementation,testing}-exec` SKILLs and the plan-review map/reduce REDUCE step in the plan SKILLs MUST receive output in the same shape they receive today.
  - **AC5a**: A smoke run of the migrated exec-phase security-reviewer on a known-good and known-bad changeset produces a first-non-blank line beginning with `findings:` / `no findings` / `error:`.
  - **AC5b**: A smoke run of the migrated plan-reviewer on a representative plan file (this task's own `c-design-plan.md` if available, otherwise any prior task's plan) produces output the existing REDUCE step can consume without changes. The smoke run MUST exercise the parent-agent synthesis path, not merely the subagent output in isolation.

- **FR6 (validation integrity)**: All new `.claude/agents/cwf-*.md` files AND the shared-rules surface file MUST be registered in `.cwf/security/script-hashes.json` (or whichever integrity ledger covers `.claude/`-tree instruction files), and `cwf-manage validate` MUST pass after migration.
  - **AC6a**: `.cwf/scripts/cwf-manage validate` exits 0 on the migrated tree.
  - **AC6b**: Running `.cwf/scripts/command-helpers/security-review-changeset` over a changeset that touches a `.claude/agents/cwf-*.md` file emits that file in its output. (Verified gap as of baseline `2b0d524`: the `@CWF_INTERNAL_PREFIXES` list at `security-review-changeset:56` currently covers `.claude/scripts/`, `.claude/skills/`, `.claude/hooks/`, `.claude/rules/` but NOT `.claude/agents/`. The fix is to add `.claude/agents/` to that list; this AC tests the observable contract, not the list directly.)
  - **AC6c**: The shared-rules surface file (per FR2) is in the integrity ledger alongside the agent files. Tampering with shared rules has fan-out across every agent, so it MUST NOT be a hash-untracked surface.

### User Stories
- **As a maintainer adding a new "no X in subagent bash" rule**, I want to edit one file and have every CWF subagent pick up the rule, so I'm not chasing copy-pasted rule text across N agent definitions.
- **As a SKILL author** invoking the security-reviewer, I want to write `subagent_type=security-reviewer-changeset` and have the prompt, tool grant, and shared rules already bundled, so the SKILL body shrinks to the variable substitution alone.
- **As a CWF developer running an exec phase**, I want subagent runs to not block on permission-prompts for `find -exec grep`, so my exec phase completes without manual intervention.

## Non-Functional Requirements
### Performance (NFR1)
- Agent invocation MUST NOT add measurable latency vs the current `Explore`+inline-prompt path (target: within 10% of current wall-clock for an equivalent prompt). Out of scope: optimising the underlying agent runtime.

### Usability (NFR2)
- A maintainer adding a new shared rule MUST be able to do so in a single Edit-tool call to one file. The location of the shared-rules surface MUST be discoverable from any agent definition (the link in each agent file is the entrypoint).
- Failure modes (missing `.claude/agents/cwf-<name>.md`, malformed frontmatter) MUST NOT silently fall back to a different role; the Agent-tool error (whatever Claude Code emits) MUST propagate to the SKILL caller. Verified in testing-exec by invoking a non-existent role name and recording the resulting error.

### Maintainability (NFR3)
- Zero duplication of shared-rules text across agent definitions; each agent file contains a reference, not the text.
- Per-agent files are self-contained: name, description, allowed-tools, role-specific prompt, plus the link to shared rules. Reviewer can understand the agent's contract by reading one file plus the shared-rules surface.

### Security (NFR4)
- Minimal tool grant per agent (FR4 captures this functionally; restated here as a security property).
- New `.claude/agents/` files MUST be covered by the same integrity-verification regime as other instruction files Claude consumes (`.cwf/security/script-hashes.json` or equivalent).
- The shared-rules surface MUST itself be in the integrity ledger — tampering with it would affect every consumer.
- Prompt-injection surface MUST NOT grow: agent prompts MUST treat any `{arguments}`-derived text the same way today's SKILLs do (advisory, structurally-parsed by helpers).

### Reliability (NFR5)
- Subagent output contracts (sentinel lines, numbered-list fallback, error classification) MUST be byte-identical in shape to current behaviour for the in-scope roles.
- Migration MUST be revertible: until `cwf-manage validate` confirms the new tree and a smoke test confirms the contracts, the old `Explore`+inline-prompt path remains the truth. The cutover is the final commit, not an incremental one.

## Constraints
- POSIX/macOS system-Perl portability rules from `docs/conventions/perl.md` continue to apply to any helper scripts touched.
- Cannot change the exec-phase sentinel contract (`findings:` / `no findings` / `error:`); downstream classifier depends on it.
- The plan-review fan-out MUST remain exactly 4 parallel Agent calls (one per criteria column: improvements, misalignment, robustness, security). The `subagent_type` value and parameterisation method are design choices; the count and parallelism are not.
- All work goes through CWF workflow (no direct commits to main); enforced by the project's fundamental principle, not by tooling.
- Claude Code's `.claude/agents/` frontmatter schema is the authoritative format; this task does not invent a CWF-specific extension. The exact field names used (e.g. `allowed-tools`) MUST match Claude Code's documented schema at implementation time; if the schema changes mid-task, update every agent file and record the schema reference in `f-implementation-exec.md`.
- Agent definitions MUST NOT read environment variables that influence security-critical paths. Tunable parameters arrive via SKILL-level prompt substitution, not `$ENV`. Example: an agent that needs the task number receives it via SKILL-level `{task_num}` substitution, never via `$ENV{TASK_NUM}`. Verification (AC4d): a grep of every CWF agent file for `\$ENV` or `\$[A-Z_]+` returns zero non-illustrative matches. (Threat category (d) per `.cwf/docs/skills/security-review.md`.)
- The `cwf-` prefix (FR1a) is non-negotiable for every CWF-installed agent. Removing it from any file would re-open the namespace collision and the cleanup-safety hole that the prefix is the only signal preventing.

## Decomposition Check
- [ ] **Time**: Will this take >1 week? — No (2-3 days estimated in `a-task-plan.md`).
- [ ] **People**: Does this need >2 people working on different parts? — No.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? — Borderline; see `a-task-plan.md` decomposition note. Concerns are tightly coupled (shared-rules → agent defs → call-sites).
- [ ] **Risk**: Are there high-risk components that need isolation? — No (smoke-test mitigation handles contract-preservation risk).
- [ ] **Independence**: Can parts be worked on separately? — Not cleanly; sequential dependency chain.

**Conclusion (unchanged from a-task-plan.md)**: Proceed as a single task.

## Acceptance Criteria
- [ ] AC1: All in-scope subagent roles defined under `.claude/agents/cwf-*.md`; `cwf-` namespace enforced for both files and SKILL-side `subagent_type` references (FR1, FR1-namespace ACs)
- [ ] AC1-install: cwf-manage installs/updates/cleans agent files; non-CWF files in `.claude/agents/` untouched (FR1-install ACs)
- [ ] AC2: Single shared-rules surface exists and is referenced (not duplicated) (FR2 ACs)
- [ ] AC3: Blocking bash anti-patterns demonstrably suppressed (FR3 ACs)
- [ ] AC4: Tool grants minimal and explicit per agent; prompts free of injection-driven control flow; no env-var reads (FR4 ACs including AC4c, plus AC4d env-var grep)
- [ ] AC5: Skill-side classifier contracts preserved end-to-end, not just at subagent boundary (FR5 ACs)
- [ ] AC6: `cwf-manage validate` passes on migrated tree; security-review-changeset emits `.claude/agents/` paths in its diff; shared-rules file in integrity ledger (FR6 ACs, including AC6b contract-level test and AC6c)

**Design-phase-deferred decisions** (noted here so design knows the open list):
- Plan-reviewer role count (one parameterised vs four separate); both choices satisfy AC1.
- Install mechanism for agent files (symlink-via-staging-dir vs direct copy); verified to work with Claude Code's agent-discovery in design.
- Concrete path of the shared-rules surface file.
- Exact integrity-ledger structure for `.claude/agents/` and the shared-rules file (new section in `script-hashes.json`, or addition to existing sections).
- Exact reference mechanism in agent files (Markdown link vs frontmatter include directive, depending on Claude Code's agent schema at implementation time).

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
