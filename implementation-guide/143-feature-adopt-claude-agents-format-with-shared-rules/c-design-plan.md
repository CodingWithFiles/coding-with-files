# Adopt .claude/agents format with shared rules - Design
**Task**: 143 (feature)

## Task Reference
- **Task ID**: internal-143
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/143-adopt-claude-agents-format-with-shared-rules
- **Template Version**: 2.1

## Goal
Lock the architecture and per-file design for migrating CWF's review subagents to `.claude/agents/cwf-*.md`, including the shared-rules surface, install lifecycle, integrity-ledger structure, and reference mechanism. All five design-deferred decisions from `b-requirements-plan.md` § "Design-phase-deferred decisions" are resolved here.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Resolved Design Decisions

### D1: Plan-reviewer role count — **four separate files**

- **Decision**: Four files: `cwf-plan-reviewer-improvements.md`, `cwf-plan-reviewer-misalignment.md`, `cwf-plan-reviewer-robustness.md`, `cwf-plan-reviewer-security.md`. The SKILL invokes them as 4 parallel `Agent` calls, each with its own `subagent_type=cwf-plan-reviewer-<column>` and a small substitution payload (`{plan_file_path}`, `{plan_type}`) — no `{criteria}` substitution.
- **Rationale**: Forward-looking shape variation. The four reviewers are not just different criteria text — they're different roles that we expect to diverge over time at the wf-step / reviewer level (e.g. the security reviewer may grow to invoke a different sub-skill or carry its own pre-flight check; the robustness reviewer may want to read prior tasks' retrospective files; the improvements reviewer may need access to backlog state). One parameterised file forces all of those divergences back into SKILL-side substitution, which is exactly the wrong direction. Each file owns its role end-to-end.
- **Trade-offs**: Four files instead of one. Each has its own frontmatter, shared-rules link, ledger entry, and install symlink. A change to scaffolding (e.g. a new Claude Code frontmatter field, or a shared-rules path rename) is a 4-edit, not a 1-edit. We accept this cost; it scales linearly with the count of plan-reviewer columns, and the count is fixed at 4 by the plan-review constraint.
- **Rejected alternative**: One `cwf-plan-reviewer.md` taking `{criteria}` via SKILL-side substitution. Considered during design-phase plan-review and briefly preferred for simplicity. Reverted on user direction: the per-reviewer divergence we expect to need future-shape-flexibility for cannot live cleanly in a parameterised agent.
- **Integrity granularity**: With 4 files, tampering with one column's prompt changes only that column's hash in `script-hashes.json`. With 1 file, any column edit moves the same single hash. Both shapes are caught by `cwf-manage validate`; 4 files gives finer-grained tamper-attribution.

### D2: Install mechanism — **symlink-via-staging-dir, mirroring skills**

- **Decision**: At install/update, `cwf-manage` (a) subtree-splits `.claude/agents/` from the upstream clone, (b) stages files under `.cwf-agents/` in the target repo, (c) creates per-file symlinks `.claude/agents/cwf-<name>.md` → `../../.cwf-agents/cwf-<name>.md`. Symlinks target individual `.md` files (unlike skills, which symlink whole directories), because Claude Code's agent format expects flat `.claude/agents/<name>.md`, not a directory-per-agent.
- **Rationale**: Maximum consistency with the existing `.claude/skills/` lifecycle in `cwf-manage:415-548`. Updates propagate via subtree pull; cleanup is a single `unlink` per stale symlink. Verified safe-for-discovery: Claude Code follows symlinks for skills today (this repo's installed copies are symlinks to `.cwf-skills/`), so the same will work for agents.
- **Trade-offs**: Adds a fourth `cwf-manage`-managed staging tree (`.cwf-agents/` joins `.cwf/`, `.cwf-skills/`, `.cwf-rules/`). The bookkeeping cost is one new subtree-split + one new symlink-creation function. Worth it: a copy-based approach would diverge from skills and force a separate cleanup story.
- **Rejected alternative**: Direct copy into `.claude/agents/`. Simpler in isolation, but creates two install patterns inside `.claude/` (symlinks for skills, copies for agents) — a cross-cutting inconsistency that future maintainers would have to remember.
- **Conflict-check rule**: Before calling `symlink()` for `cwf-<name>.md`, `create_agent_symlinks()` MUST check: if a regular file (not a symlink) already exists at the target path, emit a clear error ("Regular file `.claude/agents/cwf-<name>.md` blocks CWF agent install; remove it or rename your custom agent") and abort the install. This prevents a confusing "symlink() failed: File exists" error from masking a user-file collision in the `cwf-*` namespace. The cleanup loop continues to *only* unlink entries that are both `-l` AND match `cwf-*.md`, so user-created non-symlink files are never silently removed.
- **Symlink-target safety**: Population of `.cwf-agents/` reuses `cwf-manage`'s existing `copy_tree` (lines 477-502), which calls `_escapes_src` (lines 446-456) on every symlink target in the upstream clone. Symlinks created by `create_agent_symlinks()` use hardcoded relative targets (`../../.cwf-agents/$name` where `$name` is `basename($glob_entry)`); no user-controlled string flows into the target.

### D3: Shared-rules surface path — **`.cwf/docs/skills/cwf-agent-shared-rules.md`**

- **Decision**: Single file at `.cwf/docs/skills/cwf-agent-shared-rules.md`. Co-located with the existing `.cwf/docs/skills/` family (`plan-review.md`, `security-review.md`, `workflow-preamble.md`, etc.) — the directory that already holds the prompt-template seeds these rules complement. Filename prefixed `cwf-` for namespace consistency with the agent files themselves, even though the directory is already CWF-internal.
- **Rationale**: A new top-level directory (`.cwf/agents-shared/`) would force an addition to `@CWF_INTERNAL_PREFIXES`, a new install path in `cwf-manage`, and a new section in `script-hashes.json`. None of that buys anything because `.cwf/docs/skills/` already has the right permissions, the right install path (it's inside `.cwf/`, copied by `update_copy`), and the right convention.
- **Trade-offs**: The filename has to convey "shared by agents", hence `cwf-agent-shared-rules.md` rather than `shared-rules.md`. Future-proofs against confusion with hypothetical SKILL-shared rules.

### D4: Integrity-ledger structure — **new top-level `agents` section; shared-rules under `data`**

- **Decision**: Add a fifth top-level section to `.cwf/security/script-hashes.json`: `"agents"`, parallel to `"data"`, `"lib"`, `"scripts"`. Each entry has `path` (e.g. `".claude/agents/cwf-plan-reviewer-security.md"`) and `sha256`. No `permissions` field (markdown files inherit dir perms; no executable bit needed). The shared-rules file (`.cwf/docs/skills/cwf-agent-shared-rules.md`) goes under the existing `"data"` section alongside `claude-md-preamble-template` — it's a referenced document, not an executable, not an agent.
- **Rationale**: `script-hashes.json` already groups by *role* (`data` = referenced templates/manifests, `lib` = Perl modules, `scripts` = executables). Agents are a new role (LLM instruction files), so a new section is the cleanest fit. The shared-rules file is a referenced rules document, same shape as the existing `claude-md-preamble-template`; reusing `data` avoids creating a second section for a single file.
- **Trade-offs**: `cwf-manage validate` and any tooling that walks `script-hashes.json` must learn about the `agents` key. That's one for-loop in the validator; trivial.
- **Source-of-truth note**: `cwf-manage` and the validator are the only consumers; both live in CWF and update with this task.

### D5: Reference mechanism in agent files — **Markdown link in prompt body**

- **Decision**: Each agent's prompt body includes the line (verbatim, near the top):
  ```
  Shared rules apply to this agent. See `.cwf/docs/skills/cwf-agent-shared-rules.md` for the tool-tier rubric, the blocking-bash-anti-patterns table, and the reference to `.cwf/docs/conventions/subagent-tool-selection.md`.
  ```
  Claude Code reads the agent's body as the system prompt; the Read tool is in every agent's `allowed-tools`, so the subagent can pull the shared rules on first invocation.
- **Rationale**: Claude Code's `.claude/agents/` schema (as of cutoff Jan 2026) supports the YAML frontmatter `name`, `description`, `allowed-tools`, plus the markdown body as the system prompt. There is no documented `include:` or `extends:` field; inventing one would couple us to a future schema we'd have to track. A markdown link inside the body is the lowest-coupling reference.
- **Trade-offs**: The agent must spend one Read call to load the shared rules on each invocation (cheap; the file is small and Read is in-process). The link is a string, so a rename of the shared-rules file requires updating each agent — mitigated by `script-hashes.json` integrity covering the link target, plus the agent files themselves being hash-tracked so any in-place edit is caught.
- **Path resolution**: The link path is repo-root-relative. CWF invariant (across every CWF SKILL today): Claude Code is invoked with the repo root as cwd. The Read tool resolves the relative path against that cwd. If a user invokes a CWF subagent from outside a repo, the Read will fail; that's unsupported and intentional — CWF is a repo-scoped tool.
- **Path-traversal safety**: The link is a literal string baked into the agent body at install time; no substitution, no user input. Tampering with the link would change the agent file's SHA256 and be caught by `cwf-manage validate` (D4 / AC6c).

## System Design

### Component Overview

| Component | Path | Purpose |
|---|---|---|
| Plan-reviewer agents (×4) | `.claude/agents/cwf-plan-reviewer-{improvements,misalignment,robustness,security}.md` | One per criteria column in the plan-review map step. Each owns its column's focus text, criteria, and role-specific intro; the SKILL launches all four in parallel with `subagent_type=cwf-plan-reviewer-<column>`. No `{criteria}` substitution at the SKILL boundary. |
| Security-reviewer-changeset | `.claude/agents/cwf-security-reviewer-changeset.md` | Exec-phase security review; emits sentinel-line output for the `cwf-{implementation,testing}-exec` SKILLs' classifier. |
| Shared-rules surface | `.cwf/docs/skills/cwf-agent-shared-rules.md` | Single source for cross-agent guardrails: tool-tier preference, blocking-bash-anti-patterns table, link to the full `subagent-tool-selection.md` rubric, inclusion-bar paragraph. |
| Staging tree | `.cwf-agents/` (in target repos only; created by `cwf-manage`) | Mirror of upstream `.claude/agents/`. Source-of-truth for the symlinks. |
| Install/update path | `cwf-manage` extensions (`update_subtree`, `update_copy`, new `create_agent_symlinks()`) | Subtree-split `.claude/agents/`, copy into `.cwf-agents/`, create per-file symlinks under `.claude/agents/`. |
| Pathspec coverage | `.cwf/scripts/command-helpers/security-review-changeset` (`@CWF_INTERNAL_PREFIXES` += `.claude/agents/`) | Bring agent files into the exec-phase security-review diff. |
| Integrity ledger | `.cwf/security/script-hashes.json` (`agents` section + `data` entry for shared-rules) | Hash-track every agent file and the shared-rules file. |
| SKILL call-site updates | `.cwf/docs/skills/plan-review.md`, `.cwf/docs/skills/security-review.md`, `.claude/skills/cwf-implementation-exec/SKILL.md:54`, `.claude/skills/cwf-testing-exec/SKILL.md:49` | Replace `subagent_type="Explore"` + inline-prompt invocations with `subagent_type=cwf-<role>`. SKILLs stop carrying the prompt body; they pass substitutions only. |

### Data Flow

**Invocation flow (post-migration)**:
1. SKILL (e.g. `cwf-design-plan`) reaches Step 8 (plan review).
2. SKILL launches 4 parallel `Agent` calls, one per column: `subagent_type=cwf-plan-reviewer-improvements`, `cwf-plan-reviewer-misalignment`, `cwf-plan-reviewer-robustness`, `cwf-plan-reviewer-security`. Each receives only `{plan_file_path}` and `{plan_type}` substitutions — the column's criteria and focus text live in the agent body itself.
3. Each agent loads its respective `.claude/agents/cwf-plan-reviewer-<column>.md` body as system prompt; reads the shared-rules link on first action.
4. Each agent uses `Read`/`Grep`/`Glob` per the tool grant; returns findings.
5. Parent SKILL synthesises (REDUCE step) and applies changes.

**Install flow (target repo)**:
1. User runs `cwf-manage update` in a target repo.
2. `update_subtree` splits `.claude/agents/` from the upstream clone.
3. `update_copy` removes any existing `.cwf-agents/`, copies fresh files in.
4. `create_agent_symlinks()` (new) removes stale `.claude/agents/cwf-*.md` symlinks (only entries that are symlinks AND match `cwf-*`), creates fresh symlinks pointing to `../../.cwf-agents/cwf-*.md`.
5. `cwf-manage validate` walks the new `agents` section of `script-hashes.json`, hashes each target via the symlink, compares.

### Interface Design

#### Agent file frontmatter

```yaml
---
name: cwf-plan-reviewer-security        # MUST match filename stem
description: <one-line role summary>     # used by Agent-tool dispatch
allowed-tools:                           # tier-1 read-only set for review roles
  - Read
  - Grep
  - Glob
---
```

Body: role-specific prompt + the shared-rules reference line + the column's criteria. No `{arguments}` interpolation in the file itself; all substitutions happen in the calling SKILL's prompt construction.

#### `script-hashes.json` (after this task)

```json
{
  "last_updated": "<iso>",
  "data": { ... existing entries plus:
    "agent-shared-rules": {
      "path": ".cwf/docs/skills/cwf-agent-shared-rules.md",
      "sha256": "<sha>"
    }
  },
  "lib": { ... unchanged ... },
  "scripts": { ... unchanged ... },
  "agents": {
    "cwf-plan-reviewer-improvements": {
      "path": ".claude/agents/cwf-plan-reviewer-improvements.md",
      "sha256": "<sha>"
    },
    "cwf-plan-reviewer-misalignment": {
      "path": ".claude/agents/cwf-plan-reviewer-misalignment.md",
      "sha256": "<sha>"
    },
    "cwf-plan-reviewer-robustness": {
      "path": ".claude/agents/cwf-plan-reviewer-robustness.md",
      "sha256": "<sha>"
    },
    "cwf-plan-reviewer-security": {
      "path": ".claude/agents/cwf-plan-reviewer-security.md",
      "sha256": "<sha>"
    },
    "cwf-security-reviewer-changeset": {
      "path": ".claude/agents/cwf-security-reviewer-changeset.md",
      "sha256": "<sha>"
    }
  }
}
```

#### `cwf-manage` extensions (Perl)

Mirrors `create_skill_symlinks` at `cwf-manage:524-549` with two differences:
1. Glob targets are files, not directories (`glob("$staging_dir/cwf-*.md")` instead of `glob("$staging_dir/cwf-*")`).
2. Symlink target paths point to files: `symlink("../../.cwf-agents/$name", "$agents_dir/$name")`.

Cleanup-safety invariant (same as skills): only entries matching `cwf-*.md` AND that are symlinks (`-l`) are unlinked. Regular files (user agents) are never touched.

#### `security-review-changeset` extension

One-line addition to `@CWF_INTERNAL_PREFIXES` at line 56: `'.claude/agents/',`. No other change; the existing per-path classification loop handles it.

**Scope clarification**: There are two other prefix allowlists in CWF — `CWF::Validate::Security.pm:35-46` (`@ALLOWED_SOURCE_PREFIXES` / `@ALLOWED_DEST_PREFIXES`) and `.cwf/scripts/command-helpers/cwf-apply-artefacts:59-70` (identical pair). Both gate the install-manifest's source/dest paths. **Agent files are NOT installed via the install-manifest** (they're installed via subtree-split → staging → symlink, per D2), so these two allowlists do not need updating for functional correctness. A maintenance comment in `c-design-plan.md`'s Operational Notes records this for future readers.

#### Validator generalisation (no change needed)

`CWF::Validate::Security.pm` already iterates `script-hashes.json` sections generically (it walks `keys %$data` and processes any HASH whose entries have a `path` key). Adding the new `agents` section requires zero validator code change — it is picked up automatically. The "one for-loop in the validator" mention in D4 is *already implemented*; D4 is a JSON-data change, not a code change.

## FR4 Threat-Category Coverage

`.cwf/docs/skills/security-review.md` defines five categories (a)–(e). This design's coverage:

- **(a) Bash injection / unsafe command construction**: N/A. No new shell-command construction in the agent lifecycle. `cwf-manage` extensions (`create_agent_symlinks`) call Perl's built-in `symlink()` with hardcoded relative-path strings, never via `system()` or `qx//`.
- **(b) Perl helpers consuming git/user output without `-z` / input validation**: N/A for agent files (they're markdown, not Perl). For the `cwf-manage` extension, the upstream subtree-split path is already covered by existing `copy_tree` machinery and reuses the existing `_escapes_src` defence; no new git output is parsed.
- **(c) Prompt injection via user-supplied strings**: Mitigated by (i) hardcoded `subagent_type` literals in SKILLs (FR1-namespace AC1-namespace-refs); (ii) substitution-only `{...}` patterns in agent prompts that are advisory not control-flow (AC4c); (iii) the shared-rules link being a literal string (D5 path-traversal safety).
- **(d) Unsafe environment-variable handling**: Forbidden by Constraints (line: "Agent definitions MUST NOT read environment variables..."). Verified by AC4d (grep for `\$ENV` and `\$[A-Z_]+` in agent files returns zero non-illustrative matches).
- **(e) Pattern-based risks (safe-here-but-risky-elsewhere)**: D2's `create_agent_symlinks` mirrors the existing `create_skill_symlinks` pattern. The cleanup-safety invariant (only unlink entries that are both `-l` AND match `cwf-*.md`) is *safe here because* the `cwf-*` prefix is owned by CWF and the symlink check excludes user files; *audit future uses* if a new install path ever wants to manage non-`cwf-`-prefixed files in user-shared directories — the invariant would have to change.

## Operational Notes

- **Partial install failure recovery**: If `cwf-manage update` fails between subtree-split and symlink-creation, the repo is left in a partial state (some symlinks may exist, others may not). Re-running `cwf-manage update` is the documented recovery — the cleanup loop in `create_agent_symlinks()` removes stale symlinks before creating fresh ones, so retry is idempotent.
- **Validator messaging for broken symlinks**: If a symlink under `.claude/agents/cwf-*.md` exists but the staging-tree target is missing, `cwf-manage validate` will report file-not-found at the symlink path. The remediation in that case is `cwf-manage update` (re-stage and re-symlink), not a manual file restore.
- **Cross-platform symlink discovery**: Testing-exec verifies Claude Code's agent discovery follows file symlinks on the platforms CWF supports (Linux, macOS — POSIX-only project per memory). If a future platform fails, fallback is D2's rejected alternative (direct copy); revisit then.
- **Future allowlist sync**: If agent files ever become artefact-manifest sources (currently they aren't), update `CWF::Validate::Security.pm` and `cwf-apply-artefacts` allowlists in lockstep. Not required by this task.

## Constraints

- Claude Code `.claude/agents/` schema is the authoritative format (per `b-requirements-plan.md`). Frontmatter keys (`name`, `description`, `allowed-tools`) are literal.
- The 4-parallel-calls fan-out shape for plan-review is preserved (constraint from requirements). D1's 4-file choice makes this a 1:1 mapping (one file per call), not a coincidence.
- No new env-var reads in agents (constraint from requirements). The reference link in the agent body is a literal string, not an env-var-interpolated path.
- The shared-rules surface MUST be referenceable by file path from inside an agent body. Markdown link works because the Read tool is granted; if a future change strips `Read` from a review role, the link breaks — caught by FR3 smoke test.

## Decomposition Check
- [ ] **Time**: Will this take >1 week? — No.
- [ ] **People**: >2 people? — No.
- [ ] **Complexity**: 3+ distinct concerns? — Still borderline (agent definitions, install lifecycle, ledger); design has tightened the coupling between them (each ledger entry mirrors an install target mirrors an agent file), so they ship as one coherent change.
- [ ] **Risk**: High-risk components needing isolation? — No.
- [ ] **Independence**: Parts workable separately? — No; the dependency chain (shared-rules → agents → install → ledger → SKILL call-sites) is linear.

**Conclusion (unchanged)**: Single task.

## Validation
- [ ] All 5 design-deferred decisions from `b-requirements-plan.md` are answered above (D1–D5).
- [ ] Each design decision names a rejected alternative or trade-off so the next maintainer can see what was considered.
- [ ] Component overview is exhaustive: every file mentioned in implementation will appear in the table.
- [ ] Plan-review (Step 8) passes for `design` plan type.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
