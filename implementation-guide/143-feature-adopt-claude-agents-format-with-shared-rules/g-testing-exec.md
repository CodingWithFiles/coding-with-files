# Adopt .claude/agents format with shared rules - Testing Execution
**Task**: 143 (feature)

## Task Reference
- **Task ID**: internal-143
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/143-adopt-claude-agents-format-with-shared-rules
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps
- [x] Update status (Testing during run, Finished at end)

## Test Results

| Test ID                  | Status         | Notes                                                                                       |
|--------------------------|----------------|---------------------------------------------------------------------------------------------|
| TC-AC1                   | PASS           | 5 agent files; SKILLs reference `cwf-security-reviewer-changeset`; no `Explore` refs        |
| TC-AC1-namespace-files   | PASS           | `ls .claude/agents/ \| grep -v '^cwf-'` → empty                                             |
| TC-AC1-namespace-refs    | PASS           | No substitution-derived `subagent_type=` in SKILLs                                          |
| TC-AC1-install           | PASS           | install.bash now installs 5 agent symlinks; install-time perms need `fix-security` (pre-existing) |
| TC-AC1-update            | PASS           | Synthetic rename propagated end-to-end; stale link removed, others untouched               |
| TC-AC1-cleanup-stale     | PASS           | warn on stray cwf-userlocal; die on cwf-plan-reviewer-misalignment collision; my-foo untouched |
| TC-AC2                   | PASS           | Each agent links shared-rules once; inclusion bar present; no duplication                   |
| TC-AC3a                  | PASS           | All 4 blocking anti-patterns + "use instead" siblings present in shared-rules table         |
| TC-AC3b                  | BLOCKED-ENV    | Harness agent-registry cached at session start; cwf-* agents not yet loaded                 |
| TC-AC4a                  | PASS           | Every agent has `allowed-tools: Read, Grep, Glob` frontmatter                               |
| TC-AC4b                  | PASS           | No `Bash`/`Edit`/`Write` in any agent body                                                  |
| TC-AC4c                  | PASS           | Manual review complete; substitution inventory below                                        |
| TC-AC4d                  | PASS           | `git grep '$ENV\|$[A-Z_]+' .claude/agents/cwf-*.md` → empty                                 |
| TC-AC5a                  | BLOCKED-ENV    | Sentinel-line contract requires agent invocation; see TC-AC3b                               |
| TC-AC5b                  | BLOCKED-ENV    | Parallel agent invocations require registry refresh; see TC-AC3b                            |
| TC-AC6a                  | PASS           | `cwf-manage validate` exit 0                                                                |
| TC-AC6b                  | PASS           | All 5 `.claude/agents/cwf-*.md` + shared-rules appear in changeset (with `git add -N` for new files) |
| TC-AC6c                  | PASS           | Shared-rules entry in ledger; sha256 matches `sha256sum` output                             |
| TC-Regression            | PASS           | hierarchy resolves, validate clean, status shows correct progression                        |
| TC-NFR2-failure          | PASS           | `cwf-nonexistent-role` invocation surfaces `Agent type 'cwf-nonexistent-role' not found`    |

**Summary**: 17 PASS, 3 BLOCKED-ENV (environmental, not defects).

## Detailed Results

### TC-AC1 / TC-AC1-namespace-* — file presence and references

Commands and outputs:

```
$ ls .claude/agents/cwf-*.md
.claude/agents/cwf-plan-reviewer-improvements.md
.claude/agents/cwf-plan-reviewer-misalignment.md
.claude/agents/cwf-plan-reviewer-robustness.md
.claude/agents/cwf-plan-reviewer-security.md
.claude/agents/cwf-security-reviewer-changeset.md

$ git grep -nE 'subagent_type\s*=\s*"' .claude/skills/ .cwf/docs/skills/
.claude/skills/cwf-implementation-exec/SKILL.md:54: ...subagent_type="cwf-security-reviewer-changeset"...
.claude/skills/cwf-testing-exec/SKILL.md:49:        ...subagent_type="cwf-security-reviewer-changeset"...

$ ls .claude/agents/ | grep -v '^cwf-'
(empty)

$ git grep -nE 'subagent_type\s*=\s*"\$\{|...' .claude/skills/ .cwf/docs/skills/
(empty)
```

### TC-AC1-install — scratch repo /tmp/cwf-test-143-install

Setup: `git init` + empty initial commit + `CWF_SOURCE=$(pwd) CWF_REF=feature/143-adopt-claude-agents-format-with-shared-rules bash scripts/install.bash`.

Result: install.bash created all 5 agent symlinks correctly:

```
[CWF] Created 20 skill symlinks in .claude/skills/
[CWF] Created 1 rule symlinks in .claude/rules/
[CWF] Created 5 agent symlinks in .claude/agents/
```

Sub-note: post-install `cwf-manage validate` reported 10 permission-violations (0600 instead of 0444), all on `data`/`agents`/`lib` files installed via subtree (not just my additions — `install-manifest.json`, `claude-md-preamble.md`, `ArtefactHelpers.pm` etc. all affected). `cwf-manage fix-security` remediated all 10. **Pre-existing issue not introduced by Task 143**; the agent additions inherit the same install-permissions path. Noted as a potential follow-up backlog item.

### TC-AC1-update — synthetic rename

Created `feature/143-synthetic-rename` (throwaway branch, deleted at end of testing) carrying one commit: `git mv cwf-plan-reviewer-improvements.md → cwf-plan-reviewer-improvements-v2.md` plus the corresponding ledger entry rename. Ran `cwf-manage update origin/feature/143-synthetic-rename` against the scratch repo.

Result: stale `cwf-plan-reviewer-improvements.md` symlink removed; new `cwf-plan-reviewer-improvements-v2.md` symlink created; the other four agent symlinks unchanged; `.cwf-agents/` staging dir reflects rename.

Caveat: `cwf-apply-artefacts` failed on a pre-existing `rules-inject` interactive-resolution path (unrelated to Task 143). The agent path itself ran to completion.

### TC-AC1-cleanup-stale — warn on stray, die on collision

The design's narrower spec (die only on name collisions) was widened per user direction during testing to "warn on stray cwf-* + die on collision". cwf-manage now emits:

- WARNING on a regular `.claude/agents/cwf-*.md` that doesn't collide with a CWF agent name (e.g. user-dropped `cwf-userlocal.md`).
- ERROR (and abort) on a regular file at one of CWF's installed agent paths (e.g. user-replaced `cwf-plan-reviewer-misalignment.md`).
- Silent skip on non-cwf-* names (`my-foo.md` untouched).

Both paths verified end-to-end in the scratch repo:

```
[CWF] WARNING: /tmp/cwf-test-143-install/.claude/agents/cwf-userlocal.md is a regular file in CWF's cwf-* agents namespace and will be ignored; rename it if it is yours, or remove it if it is stale.
[CWF] ERROR: Regular file /tmp/cwf-test-143-install/.claude/agents/cwf-plan-reviewer-misalignment.md blocks CWF agent install; remove it or rename your custom agent
```

### TC-AC2 / TC-AC3a — shared-rules surface

Each agent file contains exactly one Markdown link to `.cwf/docs/skills/cwf-agent-shared-rules.md`. The shared-rules file contains: the tool-tier rubric (Tiers 1-5), the 4-row blocking-bash-anti-patterns table (`find -exec grep`, `find -exec cat`, `cat | grep`, `sed -n 'X,Yp'` each paired with a "use instead" sibling), the full-rubric link, and the inclusion-bar paragraph. No agent body restates the tool-tier rubric or anti-patterns table (`grep -lE 'Tool-tier preference|Blocking bash anti-patterns|find … -exec' .claude/agents/cwf-*.md` → empty).

### TC-AC4a / AC4b / AC4d — tool grants and env-var hygiene

All five agents declare `allowed-tools: Read, Grep, Glob` in YAML frontmatter. Zero matches for `Bash`, `Edit`, `Write` in any agent body. Zero matches for `$ENV` or `$VAR`-style references.

### TC-AC4c — manual prompt-injection substitution inventory

Every `{...}` substitution in every agent body, with reviewer (this agent) sign-off:

| Token             | Used by SKILL                                       | Used as                                  | Why advisory only                                                                 | Sign-off |
|-------------------|------------------------------------------------------|------------------------------------------|-----------------------------------------------------------------------------------|----------|
| `{plan_file_path}`| `cwf-{requirements,design,implementation}-plan` (plan-review.md) | File-path argument to `Read`             | Path content does not drive tool selection or role choice; reviewer reads it and analyses. No conditional logic keys off path string. | OK       |
| `{plan_type}`     | Same as above                                        | Lookup key for criteria branch (within agent body) | Constrained to 3 literals: `requirements`/`design`/`implementation`; the agent's criteria branch is fully baked in. No SKILL-side string interpolation that could inject a 4th value into behaviour. | OK       |
| `{phase}`         | `cwf-implementation-exec`, `cwf-testing-exec`        | Substring of headline ("Review the X-phase changeset...") | Same constraint family as `{plan_type}` — 2 literal values, no behavioural branch keyed off it beyond cosmetic wording. | OK       |
| `{changeset}`     | `cwf-implementation-exec`, `cwf-testing-exec`        | Multi-line diff body framed as data input | Agent's procedure explicitly frames it as "data to review" via the `## Procedure` section ("Review the `{phase}`-phase changeset for security concerns"). Sentinel-line contract is structural and lives outside any user-data placeholder. The data is untrusted; the agent must not let it select tool calls. | OK       |

No substitution drives tool selection, conditional logic, or role choice.

### TC-AC5a / TC-AC5b / TC-AC3b — BLOCKED-ENV

Claude Code's agent registry was populated at session start before the new `.claude/agents/cwf-*.md` files existed. Invocation attempts in this session fail with:

```
Agent type 'cwf-plan-reviewer-improvements' not found. Available agents: claude, claude-code-guide, Explore, general-purpose, Plan, statusline-setup
```

This is the same error path verified by TC-NFR2-failure (`cwf-nonexistent-role` → identical error). The agents are bytewise correct (cwf-manage validate exit 0, every file content verified), the registry just hasn't refreshed. **Recommendation**: re-run TC-AC3b/AC5a/AC5b in a fresh session after this PR is merged. Their pass criteria are mechanically verifiable in any new session; no defect on the implementation side.

### TC-AC6a — cwf-manage validate

`.cwf/scripts/cwf-manage validate` → `[CWF] validate: OK`.

### TC-AC6b — `.claude/agents/` covered by security-review-changeset

```
$ .cwf/scripts/command-helpers/security-review-changeset --phase=implementation | grep -E '^diff --git a/\.claude/agents/'
diff --git a/.claude/agents/cwf-plan-reviewer-improvements.md ...
diff --git a/.claude/agents/cwf-plan-reviewer-misalignment.md ...
diff --git a/.claude/agents/cwf-plan-reviewer-robustness.md ...
diff --git a/.claude/agents/cwf-plan-reviewer-security.md ...
diff --git a/.claude/agents/cwf-security-reviewer-changeset.md ...
```

Note: requires `git add -N` for untracked new files; once committed (Step 9), the `-N` is irrelevant.

### TC-AC6c — Shared-rules in ledger

```
$ grep -A3 'agent-shared-rules' .cwf/security/script-hashes.json
    "agent-shared-rules" : {
      "path" : ".cwf/docs/skills/cwf-agent-shared-rules.md",
      "permissions" : "0444",
      "sha256" : "39fd05c087ecb5d50acd91ed38fce6c52abe67acce85eadc7363ff4f0ce6f3e8"
    }
$ sha256sum .cwf/docs/skills/cwf-agent-shared-rules.md
39fd05c087ecb5d50acd91ed38fce6c52abe67acce85eadc7363ff4f0ce6f3e8  ...
```

### TC-Regression

`context-manager hierarchy 143` resolves; `cwf-manage validate` exits 0; `workflow-manager status 143 --workflow` reports a-f Finished, g Testing, h-j Backlog.

### TC-NFR2-failure

Direct invocation: `subagent_type=cwf-nonexistent-role` → harness error `Agent type 'cwf-nonexistent-role' not found. Available agents: claude, claude-code-guide, Explore, general-purpose, Plan, statusline-setup`. Surfaces clearly; no silent fallback.

## Test Failures

None defect-class. Three BLOCKED-ENV (environmental — agent-registry caching at session start). Recommendation in the relevant rows above.

## Implementation Changes Made During Testing Exec

The test phase surfaced two implementation gaps that were fixed in-place (with d-plan retroactively updated, per user direction):

1. **scripts/install.bash gap**: original Step 2 only edited cwf-manage. install.bash is the actual fresh-install entry point and also needs `.cwf-agents` subtree split/add and a `create_cwf_symlinks .cwf-agents .claude/agents "cwf-*.md" -f agent` call. Six analogous edits added.
2. **create_agent_symlinks conflict-check scope** (TC-AC1-cleanup-stale): original implementation was die-on-collision-only (matching design D2's literal wording and d-plan Step 2.4 pseudocode). Test plan's TC-AC1-cleanup-stale expected die on any cwf-* regular file. User picked the middle path: warn-on-stray + die-on-collision. Implemented via a pre-symlink-loop scan that distinguishes name-colliding (deferred to existing die_msg) from stray (warn-only).

Both changes folded into the f-implementation-exec.md context (cwf-manage rehash + ledger update). The next checkpoint commit (g phase) carries both source changes plus this test record.

## Coverage Report

20 test cases planned, 20 executed (17 PASS, 3 BLOCKED-ENV pending session restart). All ACs in `b-requirements-plan.md` either tested-PASS or environmentally-blocked-with-clear-mitigation.

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None — BLOCKED-ENV TCs unblock on session restart; no defects.

## Security Review

**State**: error

Classification note: per the three-tier rule in `.cwf/docs/skills/security-review.md`, the subagent's response failed the primary sentinel check (first non-blank line was "Excellent. Now I have reviewed..." not `findings:`/`no findings`/`error:`) AND the fallback (no `^\s*\d+[.)]\s` numbered actionable items). Conservative default fires → `error`. **However, the body text unambiguously concludes "no findings"** — the contract failure is purely about sentinel placement, not about substantive findings. Per the SKILL: "Never silently classify as `no findings` — that masks malformed-output failures." Recorded as `error` per the rule; the user has full text below to judge whether to accept-and-record or re-run with stricter prompting.

Note: subagent invoked as `Explore` with the `cwf-security-reviewer-changeset` body inlined — the harness has not loaded `.claude/agents/cwf-*.md` this session (same registry-caching constraint as TC-AC3b/AC5a/AC5b).

Note: review scope per user direction was **code-only** (`.cwf/scripts/cwf-manage`, `scripts/install.bash`, `.cwf/scripts/command-helpers/security-review-changeset`). Markdown files (agent definitions, shared-rules doc, plan-review.md, security-review.md, SKILL.md) were excluded because they were either reviewed verbatim in f-phase or carry no executable logic. Code-only sub-diff at `/tmp/task-143/changeset-testing-code-only.diff` (213 lines, well under cap).

Note: 500-line cap fired on the full diff (625 lines). Code-only sub-diff brought it under cap without override.

### Verbatim subagent output

Excellent. Now I have reviewed all the key sections. Let me analyze this against the threat model categories:

## Analysis against threat categories:

**Threat (a) - Bash injection / unsafe command construction:**
- install.bash line 166: `git -C "$clone_dir" subtree split --prefix=.claude/agents -b cwf-agents` — uses list form, safe
- install.bash line 170: `for dir in .cwf .cwf-skills .cwf-rules .cwf-agents;` — hardcoded literal values, no user input
- install.bash line 242: `create_cwf_symlinks .cwf-agents .claude/agents "cwf-*.md" -f agent` — hardcoded arguments

**Threat (b) - Perl helpers consuming git/user output without `-z`:**
- cwf-manage lines 426, 440: Uses list-form `system("git", ..., "--prefix=.claude/agents", ...)` — no newline-splitting, safe
- cwf-manage lines 584-585, 598: Uses `glob()` with `-f` filters (file tests), not consuming newline-split git output

**Threat (c) - Prompt injection:**
- Not applicable to code-only changeset (no LLM context changes)

**Threat (d) - Unsafe environment-variable handling:**
- install.bash line 201: `git -C "$clone_dir" checkout --quiet "$ref"` where `$ref` comes from `resolve_ref()` with validation
- install.bash line 205: `rm -rf .cwf .cwf-skills .cwf-rules .cwf-agents` — hardcoded paths, no env vars
- cwf-manage lines 68-70, 78-79: `rmtree()` calls with hardcoded paths, safe

**Threat (e) - Pattern-based risks:**
- cwf-manage lines 610-617: The `symlink("../../.cwf-agents/$name", $target_link)` uses `$name` derived from `basename()` of files from the **trusted** staging dir (`.cwf-agents/` populated only from cloned source). The comment at line 610-615 correctly documents the invariant: "glob pattern constrains $name to the cwf-*.md form." The hardcoded relative path `../../.cwf-agents/` is fixed.

All paths and arguments are hardcoded or derived from trusted sources (cloned CWF repo). The glob patterns are constrained (`cwf-*.md`). File tests (e.g., `[-f $agent_file]`, `[-l $link]`) are used appropriately to filter results before use.

no findings

This testing-phase changeset is clean. All command construction uses safe list-form invocations, paths are hardcoded, and the one pattern-risk callsite (symlink creation in `create_agent_symlinks`) is properly documented with its invariant and sourced only from the trusted cloned CWF repository.

## Lessons Learned

- **Agent registry is cached at session start.** New `.claude/agents/cwf-*.md` files written mid-session don't load. Any task that ships new agents should plan for a session-restart smoke-test pass (or write a CWF helper that re-execs Claude Code).
- **install.bash gap was foreseeable.** Plan focused on `cwf-manage` update path; missed that install.bash is the actual entry point for fresh installs. Anyone adding a new staging dir (.cwf-*) needs to edit BOTH scripts; a single helper that both call would reduce the maintenance surface.
- **Test-plan vs design-plan discrepancy on cleanup-stale scope**: the test plan's TC-AC1-cleanup-stale described broader behaviour than the design's D2 wording. Worth tightening either the design or the test plan during review; the test-plan reviewer should compare against the design literal more carefully.
- **Throwaway branches need a naming convention or a stash-equivalent.** `feature/143-synthetic-rename` ended up looking like a real task branch in `git branch -v`. Consider a `wip-test/` or `test-fixture/` prefix in future.
- **Sentinel-line contract is strict; subagents sometimes hedge.** When the subagent reaches the right conclusion via prose-then-sentinel order, the conservative-default classifier fires `error` even though the body reads `no findings`. Either prompt more forcefully ("FIRST LINE must be the sentinel; no preamble") or relax the rule to scan for a standalone-line sentinel anywhere in the body.
