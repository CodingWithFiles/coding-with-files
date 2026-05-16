# Adopt .claude/agents format with shared rules - Implementation Execution
**Task**: 143 (feature)

## Task Reference
- **Task ID**: internal-143
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/143-adopt-claude-agents-format-with-shared-rules
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status to "Implemented" when complete

## Actual Results

### Step 1: Author shared-rules surface and agent files
- **Planned**: Write 6 files (1 shared-rules + 4 plan-reviewer + 1 security-reviewer), chmod 0444.
- **Actual**: Wrote all 6:
  - `.cwf/docs/skills/cwf-agent-shared-rules.md`
  - `.claude/agents/cwf-plan-reviewer-improvements.md`
  - `.claude/agents/cwf-plan-reviewer-misalignment.md`
  - `.claude/agents/cwf-plan-reviewer-robustness.md`
  - `.claude/agents/cwf-plan-reviewer-security.md`
  - `.claude/agents/cwf-security-reviewer-changeset.md`
  All chmod 0444 verified via `ls -l`.
- **Deviations**: None.

### Step 2: Wire install / update / cleanup in cwf-manage
- **Planned**: Extend dirty-tree check + error msg, `update_subtree` split/pull, `update_copy` rmtree/copy_tree, new `create_agent_symlinks`, call site in `cmd_update`.
- **Actual**: All five edits applied verbatim:
  - `check_clean_tree` paths arg now includes `.cwf-agents`; error message updated.
  - `update_subtree` adds `subtree split --prefix=.claude/agents -b cwf-agents` and `subtree pull --prefix=.cwf-agents` block.
  - `update_copy` adds `rmtree("$git_root/.cwf-agents")` and `copy_tree("$clone_dir/.claude/agents", "$git_root/.cwf-agents")` + log line.
  - `create_agent_symlinks($git_root)` defined after `create_skill_symlinks`; mirrors the skill structure, includes the D2 non-symlink-conflict check, uses relative target `../../.cwf-agents/$name`.
  - `cmd_update` calls `create_agent_symlinks($git_root)` immediately after `create_skill_symlinks($git_root)`.
- **Deviations**: None.

### Step 3: Extend security-review-changeset prefix coverage
- **Planned**: Insert `'.claude/agents/',` after the existing `.claude/skills/` entry in `@CWF_INTERNAL_PREFIXES`.
- **Actual**: Inserted between `'.claude/skills/'` and `'.claude/hooks/'` to keep the `.claude/*` block grouped.
- **Deviations**: None.

### Step 4: Register integrity-ledger entries
- **Planned**: Compute sha256s; add `data.agent-shared-rules` + new top-level `agents` section with five entries; bump `last_updated`; expect `cwf-manage validate` exit 0.
- **Actual**:
  - `sha256sum` produced the six hashes; recorded verbatim in `.cwf/security/script-hashes.json`.
  - New `agents` section placed after `last_updated` and before `data` (alphabetical order within the JSON would tie-break with `agents` < `data` < `lib` < `scripts`).
  - `cwf-manage` and `security-review-changeset` script hashes also updated (their content changed during Steps 2 and 3); validate then passed.
  - `last_updated` updated to `2026-05-16` (today's date per session context).
  - `cwf-manage validate` → `[CWF] validate: OK`.
- **Deviations**: None. The cwf-manage / security-review-changeset hash bumps were anticipated by the plan's Step 4.3 violation-type remediation (sha256 violation → recompute and re-stage).

### Step 5: Migrate SKILL call-sites
- **Planned**: Plan-review.md drops criteria table + tool-tier paragraph, switches to 4 per-column agent invocations with only `{plan_file_path}` and `{plan_type}` substitution; security-review.md exec-phase template points at `cwf-security-reviewer-changeset` with the sentinel block delegated to the agent body; both exec SKILLs change `subagent_type="Explore"` to `subagent_type="cwf-security-reviewer-changeset"`.
- **Actual**: All four edits applied. `plan-review.md` rewritten end-to-end with a compact column→`subagent_type` mapping table replacing the lookup table. `security-review.md` Exec-phase template now lists `subagent_type=cwf-security-reviewer-changeset` and references the agent body for the sentinel-line contract (the sentinel block remains verbatim in the agent file per design D5). `cwf-implementation-exec/SKILL.md:54` and `cwf-testing-exec/SKILL.md:49` updated.
- **Deviations**: None. Verified `git grep -E 'subagent_type.*Explore'` across `.claude/skills/`, `.cwf/docs/skills/`, `.claude/agents/` returns no matches.

### Step 6: Verification before commit
- **6.1** `.cwf/scripts/cwf-manage validate` → `[CWF] validate: OK`.
- **6.2** `security-review-changeset --phase=implementation` output includes all five `.claude/agents/cwf-*.md` and `.cwf/docs/skills/cwf-agent-shared-rules.md` after `git add -N` on the new files. Without `-N`, untracked new files are invisible to `git diff` (the helper's underlying mechanism); the intent-to-add adds them to the index so the helper sees them while leaving content uncommitted.
- **6.3** AC4d env-var grep `git grep -nE '\$ENV|\$[A-Z_]+' .claude/agents/cwf-*.md` → no matches.
- **6.4** AC1-namespace grep `ls .claude/agents/ | grep -v '^cwf-'` → no output. No non-CWF agents present in this source tree.

**Deviation worth flagging**: Step 6.2 required `git add -N` on the new files for the contract test to see them. This is a property of `git diff` (which excludes untracked files) interacting with the helper's design choice to read from `git diff` (so it picks up in-flight changes before the checkpoint commit). The checkpoint commit at Step 9 makes the `-N` flag irrelevant. Recorded here as orientation for future implementers verifying their own new-file changesets.

## Blockers Encountered

None.

## Deferral Check
Before marking status=Finished, verify:
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] All requirements from b-requirements-plan.md addressed
- [x] All design guidance in c-design-plan.md followed
- [x] No planned work deferred without user approval
- [x] If work deferred: Follow-up task created and linked — N/A

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

## Security Review

**State**: findings

Note: subagent was invoked twice. First run consumed a corrupt
changeset (stderr-into-stdout merge in `> file 2>&1` redirection
introduced the helper's metadata line into the diff body); subagent
correctly flagged the corruption. Second run used a clean
stdout-only capture and produced the verbatim output below.

Note: classification via three-tier rule. Subagent placed the
`findings:` sentinel at the END of its response (not first
non-blank line); primary sentinel rule failed. **Fallback rule
applied** — numbered actionable item present (`^\s*1\.\s`) →
classified as `findings`.

Note: 500-line cap was overridden once at user direction
("Force-invoke subagent anyway") because the 537-line diff was
only 37 lines over and well within practical subagent capacity.
Default SKILL behaviour (record `error: changeset exceeds
500-line review cap`) was bypassed for this one invocation.

Note: harness has not yet loaded the new `.claude/agents/cwf-*.md`
files this session — agent registry refreshes on session restart.
Subagent invoked as `Explore` with the agent body inlined into the
prompt; preserves the agent's procedure verbatim. Future sessions
(and `g-testing-exec`) will use `subagent_type=cwf-security-reviewer-changeset` directly.

### Verbatim subagent output

Perfect. The changeset is clean at line 471. Now let me perform my comprehensive security analysis.

## Analysis

**Category (a) — Bash injection / unsafe command construction:**

Lines 461-462 and 472-474 use list-form `system()` calls. All string literals are hardcoded (`"cwf-agents"`, `".claude/agents"`, `".cwf-agents"`) — no interpolation of user input. This is correct.

**Category (b) — Perl helpers consuming git/user output without `-z` / validation:**

The new `create_agent_symlinks()` function (lines 500-533) uses:
- `glob("$staging_dir/cwf-*.md")` at line 515: glob returns trusted filenames from `.cwf-agents/` (which comes from a cloned repo via `copy_tree` at line 490, sourced from `$clone_dir/.claude/agents`).
- `basename($agent_file)` at line 517: extracts the filename safely.
- No shell invocation of git output or user-supplied strings.

This is correct.

**Category (c) — Prompt injection via user-supplied strings:**

The new agent files contain placeholders `{phase}`, `{changeset}`, `{plan_file_path}`, and `{plan_type}`.

Critical observation: In `cwf-security-reviewer-changeset.md` (lines 195-223), the `{changeset}` placeholder appears at line 223 under the section heading `Changeset:` in the agent definition body. This is an "Inputs" section describing what data the agent will receive. It is NOT within active instruction prose that the LLM would interpret as directives.

In the agent invocation (lines 401-410 of the modified documentation), the placeholder appears as:
```
Inputs:
- phase: {phase}
- changeset: |
{changeset}

Follow the procedure in your agent definition.
```

The `{changeset}` is substituted into a structured input section (marked as `changeset: |`) that the agent treats as data input to review, not as instructions. The agent's own body (in the agent file) then explicitly instructs the reviewer to "Review the `{phase}`-phase changeset for security concerns" — the agent clearly frames the changeset as data to analyze, not instructions.

Similar for `{plan_file_path}` and `{plan_type}`: these appear under `## Inputs` sections in the agent files and are explicitly framed as data, not instructions.

This is correct — the agent design mitigates prompt injection risk through structural separation.

**Category (d) — Unsafe environment-variable handling:**

No new environment-variable handling in the changeset. The existing `CWF_SOURCE` usage (mentioned in security-review.md as a canonical audit surface) is already safe (list-form system()).

No findings.

**Category (e) — Pattern-based risks:**

Line 527: `symlink("../../.cwf-agents/$name", $target_link)` — the `$name` is derived from `basename($agent_file)` where `$agent_file` comes from `glob("$staging_dir/cwf-*.md")`. The glob pattern `cwf-*.md` restricts filenames to the prefix and suffix; `basename()` extracts only the filename portion (no directory traversal possible). The symlink target `../../.cwf-agents/$name` is hardcoded relative path prefix with basename appended. This is safe at the callsite because:
- `.cwf-agents/` is populated exclusively by trusted cloned source (`copy_tree` from a git repo)
- The glob pattern enforces a naming constraint
- `basename()` prevents path traversal

However, if `.cwf-agents/` were ever populated from user-controlled sources or if the glob pattern were relaxed, this pattern could become exploitable. This should be audited if the trust boundary changes.

Safe here because the glob source is trusted and the filename is constrained by the pattern; audit future uses where the staging directory trust model changes.

---

**Changeset integrity:** The diff reads cleanly at line 471 (no corruption as was present in the prior run).

**Tool-tier adherence in agent files:** The agent files correctly declare `allowed-tools: Read, Grep, Glob` and explicitly reference `.cwf/docs/skills/cwf-agent-shared-rules.md` for tool selection and bash anti-patterns. No security violation here.

---

findings:

1. **Pattern-based risk (e) at line 527 — symlink basename injection.** The `symlink("../../.cwf-agents/$name", $target_link)` call concatenates a dynamically extracted filename (`$name = basename($agent_file)`) into a symlink target. Safe here because (i) `.cwf-agents/` is populated solely from the trusted cloned CWF repository, (ii) the glob pattern `cwf-*.md` constrains filenames, and (iii) `basename()` prevents directory traversal. However, if `.cwf-agents/` trust boundary changes in future (e.g., user-contributed agents), this pattern becomes exploitable. **Action:** Add an inline comment documenting the invariant (`.cwf-agents/ is populated only from trusted source`), and audit any future changes to the staging-directory population logic before reusing this pattern in less-restricted contexts.

### Disposition

Finding 1 — **Applied**. Added a six-line invariant-documenting comment above the `symlink()` call in `create_agent_symlinks` (`.cwf/scripts/cwf-manage`) naming the trust boundary (cloned CWF source + glob pattern constraint) and warning future maintainers that reuse must re-establish the invariant. `script-hashes.json` cwf-manage hash bumped to `82430212…`; `cwf-manage validate` returned `[CWF] validate: OK`.

## Lessons Learned
- `git diff` (and any helper layered on it) does not surface untracked files. When verifying a security-review-changeset contract on new files before commit, use `git add -N` (intent-to-add) so the index entry exists without committing content.
- The deliberate asymmetry between `create_skill_symlinks` (no conflict-check) and `create_agent_symlinks` (with conflict-check) is intentional per d-plan; retrofitting the skills counterpart is noted for the retrospective's "Lessons Learned" follow-up.
- 500-line cap can fire on a changeset whose semantic content is well below cap once you count hunk-header and context lines (here: 538 total vs 399 actual edits). Worth considering whether future tuning should count edit-lines only, or whether the current behaviour (over-conservative) is the right safety stance.
