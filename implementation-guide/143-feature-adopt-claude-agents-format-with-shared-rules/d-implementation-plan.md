# Adopt .claude/agents format with shared rules - Implementation Plan
**Task**: 143 (feature)

## Task Reference
- **Task ID**: internal-143
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/143-adopt-claude-agents-format-with-shared-rules
- **Template Version**: 2.1

## Goal
Land the design's two-agent setup, the shared-rules surface, the install lifecycle for `.claude/agents/cwf-*.md`, the security-review-changeset prefix extension, the integrity-ledger entries, and the SKILL call-site migration — in that order, with verifiable checkpoints between.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary changes (new files)

- `.cwf/docs/skills/cwf-agent-shared-rules.md` (NEW) — single shared-rules surface. Contents: tool-tier rubric (lift from `.cwf/docs/conventions/subagent-tool-selection.md` § "Convention"), blocking-bash-anti-patterns table (the four patterns from FR3), reference link to the full rubric, inclusion-bar paragraph.
- `.claude/agents/cwf-plan-reviewer-improvements.md` (NEW) — frontmatter (`name: cwf-plan-reviewer-improvements`, `description: <one line>`, `allowed-tools: [Read, Grep, Glob]`); body lifts the prompt scaffolding from `.cwf/docs/skills/plan-review.md` § "Prompt template" with the **improvements column's criteria** baked in (from the lookup table row "Improvements"). No inline tool-tier paragraph — replaced by the shared-rules link.
- `.claude/agents/cwf-plan-reviewer-misalignment.md` (NEW) — same shape as above; **misalignment column's criteria** baked in.
- `.claude/agents/cwf-plan-reviewer-robustness.md` (NEW) — same shape; **robustness column's criteria** baked in.
- `.claude/agents/cwf-plan-reviewer-security.md` (NEW) — same shape; **security column's criteria** baked in.
- `.claude/agents/cwf-security-reviewer-changeset.md` (NEW) — frontmatter (`name: cwf-security-reviewer-changeset`, `description: <one line>`, `allowed-tools: [Read, Grep, Glob]`); body lifts the prompt template from `.cwf/docs/skills/security-review.md` § "Exec-phase prompt template" (without the inline tool-tier paragraph; sentinel-line contract preserved verbatim).

### Primary changes (existing files)

- `.cwf/scripts/cwf-manage` — add `.cwf-agents/` to: (i) dirty-tree check at line 106; (ii) error message at line 119; (iii) `update_subtree` (new split + pull after `.claude/skills/` block, lines 421-432); (iv) `update_copy` (new `rmtree` + `copy_tree`, lines 509-516); (v) new `create_agent_symlinks($git_root)` function after `create_skill_symlinks` at line 550; (vi) call site for the new function in `cmd_update` after line 383.
- `scripts/install.bash` — analogous fresh-install path additions, mirroring the `.cwf-skills` pattern: (i) subtree split for `.claude/agents` → `cwf-agents` branch (after the skills split, ~line 164); (ii) `subtree add --prefix=.cwf-agents` (after the skills add, ~line 184); (iii) include `.cwf-agents` in the force-remove dir list at ~line 169; (iv) `cp -r "$clone_dir/.claude/agents" .cwf-agents` in the copy method (~line 209); (v) include `.cwf-agents` in the copy method's force-remove at ~line 201; (vi) `create_cwf_symlinks .cwf-agents .claude/agents "cwf-*.md" -f agent` in `post_install` (~line 230). Added during testing exec: the d-plan originally assumed cwf-manage update was the single install entry point, but fresh installs go through install.bash; without these edits, a fresh install would never materialise `.cwf-agents/` or the agent symlinks.
- `.cwf/scripts/command-helpers/security-review-changeset` — add `'.claude/agents/',` to `@CWF_INTERNAL_PREFIXES` at line 56 (one-line addition, preserving the comment block above and array close at line 65).
- `.cwf/security/script-hashes.json` — add `data.agent-shared-rules` entry (path, `permissions: "0444"`, sha256 placeholder); add new top-level `agents` section with five entries (`cwf-plan-reviewer-improvements`, `cwf-plan-reviewer-misalignment`, `cwf-plan-reviewer-robustness`, `cwf-plan-reviewer-security`, `cwf-security-reviewer-changeset`) each with path, `permissions: "0444"`, and sha256 placeholder. All six new file groups carry the same `0444` permissions field for symmetry — every one is an LLM instruction surface where tampering protection matters equally; matches the existing `data.*` template entries (line 7, 11, 16). Final hashes computed during exec via `sha256sum` (per `feedback_complexity_over_continuity.md` — use coreutil, not Perl Digest::SHA).
- `.cwf/docs/skills/plan-review.md` — § "1. MAP: Launch 4 Subagents", change the single `subagent_type: "Explore"` call into 4 distinct calls, one per column: `subagent_type: "cwf-plan-reviewer-improvements"`, `…-misalignment`, `…-robustness`, `…-security`. Remove the criteria-lookup table (§ "2. Criteria Lookup Table") — each column's criteria now live in the corresponding agent file. Remove the inlined tool-tier paragraph (`Do not use program composition…`) and the anti-patterns mini-list (lines ~20-25). The SKILL-side prompt construction now substitutes only `{plan_file_path}` and `{plan_type}` per call; `{focus_area}` and `{criteria}` are gone (baked into each agent file).
- `.cwf/docs/skills/security-review.md` — § "Exec-phase prompt template", change instructions to invoke `subagent_type=cwf-security-reviewer-changeset`. Same removal of inlined tool-tier paragraph. Sentinel-line block (`findings:` / `no findings` / `error:`) STAYS in the agent body verbatim.
- `.claude/skills/cwf-implementation-exec/SKILL.md` line 54 — change `subagent_type="Explore"` to `subagent_type="cwf-security-reviewer-changeset"`. The "using the prompt template" reference (line 54 tail) stands; the prompt template lives in `.cwf/docs/skills/security-review.md` which the SKILL already reads at line 48.
- `.claude/skills/cwf-testing-exec/SKILL.md` line 49 — identical change to the line above.

### Supporting changes

- None for source-tree gitignore (`.cwf-agents/` only exists in *installed* repos, not the source repo — same pattern as `.cwf-skills/` which is not in this repo's `.gitignore` either).
- None for `CWF::Validate::Security.pm` / `cwf-apply-artefacts` allowlists — these gate install-manifest paths, which agent files do not flow through (per design § "Operational Notes / Future allowlist sync").

## Implementation Steps

### Step 1: Author the shared-rules surface and agent files

- [ ] **1.1** Write `.cwf/docs/skills/cwf-agent-shared-rules.md`. Sections: (a) **Tool-tier preference** (lift verbatim from `subagent-tool-selection.md` § "Convention" Tiers 1-5); (b) **Blocking bash anti-patterns** (4-row table: `find … -exec grep`, `find … -exec cat`, `cat … | grep`, `sed -n 'X,Yp'` → preferred built-in); (c) **Full rubric** (one-line link to `.cwf/docs/conventions/subagent-tool-selection.md`); (d) **Inclusion bar** (rule must apply to ≥2 agent roles AND be rooted in a documented convention/incident/pattern).
- [ ] **1.2a** Write `.claude/agents/cwf-plan-reviewer-improvements.md`. Frontmatter per design D5 with `name: cwf-plan-reviewer-improvements`. Body: (i) shared-rules link line (verbatim per design D5); (ii) prompt scaffolding from `plan-review.md` lines 13-34 with the tool-tier paragraph removed; (iii) the **improvements** column's criteria text from the existing lookup table (row "Improvements") baked into the body where the SKILL would previously have substituted `{criteria}`. Same for `{focus_area}` — bake the literal "improvements" focus into the prompt.
- [ ] **1.2b** Write `.claude/agents/cwf-plan-reviewer-misalignment.md`. Same shape; bake the **misalignment** column's criteria + focus.
- [ ] **1.2c** Write `.claude/agents/cwf-plan-reviewer-robustness.md`. Same shape; bake the **robustness** column's criteria + focus.
- [ ] **1.2d** Write `.claude/agents/cwf-plan-reviewer-security.md`. Same shape; bake the **security** column's criteria + focus.
- [ ] **1.3** Write `.claude/agents/cwf-security-reviewer-changeset.md`. Frontmatter per design D5. Body: shared-rules link + the exec-phase prompt template from `security-review.md` lines 123-137 with the tool-tier paragraph removed. Sentinel-line block (`findings:` / `no findings` / `error:`) preserved byte-for-byte.
- [ ] **1.4** `chmod 0444` on all six new files (per established CWF read-only convention for instruction files).

### Step 2: Wire install / update / cleanup in cwf-manage

- [ ] **2.1** Edit `cwf-manage:106` — extend the `git diff --quiet` paths argument list to include `.cwf-agents`. Edit the error string at line 119 to mention `.cwf-agents` alongside `.cwf`, `.cwf-skills`.
- [ ] **2.2** Edit `cwf-manage` `update_subtree` (lines 415-433) — after the `.claude/skills/` split-and-pull block, append an analogous block for `.claude/agents/` → `cwf-agents` branch → `.cwf-agents/` prefix in target. Two `system("git", "-C", ...)` invocations, list-form, no shell. Mirror existing error-message style.
- [ ] **2.3** Edit `cwf-manage` `update_copy` (lines 504-522) — add `rmtree("$git_root/.cwf-agents")` alongside the existing `.cwf-skills` rmtree; add `copy_tree("$clone_dir/.claude/agents", "$git_root/.cwf-agents")` + `log_msg` line.
- [ ] **2.4** Add new function `create_agent_symlinks($git_root)` after `create_skill_symlinks` at line 550. Mirror `create_skill_symlinks` structure:
    ```perl
    sub create_agent_symlinks {
        my ($git_root) = @_;
        my $agents_dir  = "$git_root/.claude/agents";
        my $staging_dir = "$git_root/.cwf-agents";

        make_path($agents_dir) unless -d $agents_dir;

        # Cleanup: only unlink cwf-* entries that are symlinks.
        for my $link (glob("$agents_dir/cwf-*.md")) {
            unlink $link if -l $link;
        }

        my $count = 0;
        for my $agent_file (glob("$staging_dir/cwf-*.md")) {
            next unless -f $agent_file;
            my $name = basename($agent_file);
            my $target_link = "$agents_dir/$name";

            # Conflict-check per design D2: regular file blocks the install.
            if (-e $target_link && !-l $target_link) {
                die_msg("Regular file $target_link blocks CWF agent install; "
                       ."remove it or rename your custom agent");
            }

            symlink("../../.cwf-agents/$name", $target_link)
                or die_msg("Failed to create agent symlink for $name: $!");
            $count++;
        }
        log_msg("Created $count agent symlinks in .claude/agents/");
        return;
    }
    ```
- [ ] **2.5** Call `create_agent_symlinks($git_root)` in `cmd_update` immediately after `create_skill_symlinks($git_root)` at line 383.

### Step 3: Extend security-review-changeset prefix coverage

- [ ] **3.1** Edit `.cwf/scripts/command-helpers/security-review-changeset` — insert `'.claude/agents/',` as a new line in `@CWF_INTERNAL_PREFIXES` immediately after the existing `.claude/skills/` entry at line 62, preserving the `.cwf/` block (lines 57-60) and the `.claude/*` block (lines 61-64) grouping. Comment block above the array and trailing `);` unchanged.

### Step 4: Register integrity-ledger entries

- [ ] **4.1** Compute SHA256 of each new file with `sha256sum` (per the surface-security-issues feedback memory — coreutil, not `perl -MDigest::SHA`):
    - `sha256sum .cwf/docs/skills/cwf-agent-shared-rules.md .claude/agents/cwf-plan-reviewer-improvements.md .claude/agents/cwf-plan-reviewer-misalignment.md .claude/agents/cwf-plan-reviewer-robustness.md .claude/agents/cwf-plan-reviewer-security.md .claude/agents/cwf-security-reviewer-changeset.md`
- [ ] **4.2** Edit `.cwf/security/script-hashes.json`:
    - Under `data`, add an `agent-shared-rules` entry: `{ "path": ".cwf/docs/skills/cwf-agent-shared-rules.md", "permissions": "0444", "sha256": "<sha from 4.1>" }`.
    - Add a new top-level `agents` section after `scripts`, containing five entries: `cwf-plan-reviewer-improvements`, `cwf-plan-reviewer-misalignment`, `cwf-plan-reviewer-robustness`, `cwf-plan-reviewer-security`, `cwf-security-reviewer-changeset` (path + `permissions: "0444"` + sha256 for each).
    - Bump `last_updated` to today's date.
- [ ] **4.3** Run `.cwf/scripts/cwf-manage validate` — expect exit 0. Failure remediation by violation type:
    - **sha256 violation**: recompute that file's hash (Step 4.1 again) and re-stage the JSON.
    - **existence violation**: verify Step 1 created the file with the exact path the JSON entry names; correct one or the other.
    - **permissions violation**: re-run `chmod 0444` (Step 1.4) on the offending file.
    - **JSON parse error**: run `python3 -m json.tool .cwf/security/script-hashes.json` (or any JSON validator) to locate the syntax error from Step 4.2's edit; never proceed past a parse error.

### Step 5: Migrate SKILL call-sites

- [ ] **5.1** Edit `.cwf/docs/skills/plan-review.md` Step 1 (MAP) — change the single `subagent_type: "Explore"` invocation into 4 distinct calls, one per column, using `subagent_type: "cwf-plan-reviewer-improvements"`, `…-misalignment`, `…-robustness`, `…-security`. Remove § "2. Criteria Lookup Table" entirely — each column's criteria now live in its corresponding agent file. Remove the inlined tool-tier paragraph (`Do not use program composition…`) and the anti-patterns mini-list (lines ~20-25). The SKILL-side prompt substitution drops to just `{plan_file_path}` and `{plan_type}`; `{focus_area}` and `{criteria}` are removed because the agent files bake those in.
- [ ] **5.2** Edit `.cwf/docs/skills/security-review.md` § "Exec-phase prompt template" — direct callers to invoke `subagent_type=cwf-security-reviewer-changeset`. Remove the inline tool-tier paragraph from the template body (the agent body has it via shared-rules). Also scan the template body for any standalone anti-patterns list/table that would duplicate the shared-rules content; remove if present. Sentinel-line text (`findings:` / `no findings` / `error:`) stays in the agent body verbatim — the parent classifier rule depends on byte-for-byte preservation.
- [ ] **5.3** Edit `.claude/skills/cwf-implementation-exec/SKILL.md:54` — change `subagent_type="Explore"` to `subagent_type="cwf-security-reviewer-changeset"`.
- [ ] **5.4** Edit `.claude/skills/cwf-testing-exec/SKILL.md:49` — same change as 5.3.
- [ ] **5.5** Grep verification: `git grep 'subagent_type="Explore"'` across `.claude/skills/` and `.cwf/docs/skills/` should now return zero matches for in-scope roles (AC1a). Any remaining `Explore` matches must be for out-of-scope contexts (e.g. `/general-purpose` or future-task subagents); document each one if any.

### Step 6: Verification before commit

- [ ] **6.1** Re-run `.cwf/scripts/cwf-manage validate` — exit 0.
- [ ] **6.2** Run `.cwf/scripts/command-helpers/security-review-changeset --phase=implementation` on the current changeset. Verify the output includes `.claude/agents/cwf-plan-reviewer.md`, `.claude/agents/cwf-security-reviewer-changeset.md`, and `.cwf/docs/skills/cwf-agent-shared-rules.md` (AC6b contract test).
- [ ] **6.3** Grep verification per AC4d: `git grep -E '\$ENV|\$[A-Z_]+' .claude/agents/cwf-*.md` returns zero non-illustrative matches.
- [ ] **6.4** Grep verification per AC1-namespace-files: `ls .claude/agents/ | grep -v '^cwf-' | head -5` — if any output appears, those are non-CWF agents that the cleanup-safety invariant must continue to ignore. Record any findings in `f-implementation-exec.md`.

**Scope note**: Step 6 verifies the source-tree changes that this commit introduces. `.cwf-agents/` and the agent symlinks under `.claude/agents/cwf-*.md` only exist in *installed* repos (created at `cwf-manage update` time); this source repo has the agent `.md` files directly under `.claude/agents/`, no symlinks. Install-time symlink-creation, conflict-check behaviour, and cleanup safety are verified in `e-testing-plan.md` via scratch-repo install runs.

**Deliberate asymmetry**: `create_agent_symlinks` includes a non-symlink-conflict check (Step 2.4) that `create_skill_symlinks` does not. Reason: the conflict-check belongs in both, by the same logic — `cwf-*` is a shared namespace in either directory. But retrofitting `create_skill_symlinks` is out of scope here; tracked for follow-up as a separate backlog item. Note this in `j-retrospective.md` under "Lessons Learned".

## Code Changes

The full code shape is shown above (Step 2.4 `create_agent_symlinks`); other changes are line-level edits with file:line anchors. Avoiding before/after blocks for the line-level edits to keep this plan concise; the design plan's "Interface Design" section already shows the JSON schema and frontmatter shape.

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
