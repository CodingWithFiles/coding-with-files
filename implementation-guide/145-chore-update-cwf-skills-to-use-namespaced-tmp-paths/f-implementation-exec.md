# update cwf skills to use namespaced tmp paths - Implementation Execution
**Task**: 145 (chore)

## Task Reference
- **Task ID**: internal-145
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/145-update-cwf-skills-to-use-namespaced-tmp-paths
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status to "Finished" when complete

## Implementation Steps (from d-implementation-plan.md)

See d-implementation-plan.md § "Implementation Steps" (Steps 1–7).

## Actual Results

### Step 1: Write `.cwf/docs/conventions/tmp-paths.md`
- **Planned**: New convention doc with 5 sections (Convention, Threat model, Why, Out of scope, See also); copy-pastable derivation snippet; worked examples.
- **Actual**: Created at `.cwf/docs/conventions/tmp-paths.md`. All 5 required headings present. Derivation snippet uses `git rev-parse --show-toplevel` + `${repo_root//\//-}` parameter expansion + `mkdir -m 0700 -p`. Worked example: `/tmp/-home-matt-repo-coding-with-files-task-145/`. Cross-links to `[[feedback_no_heredocs]]` and `[[feedback_no_tee_permissions]]` in body.
- **Glossary decision**: No new term coined. Doc uses plain English ("scratch directory", "scratch path"); no glossary entry needed. Verified by `grep -niE 'namespaced scratch|canonical tmp|tmp.path' .cwf/docs/glossary.md` returning zero matches both pre- and post-implementation.
- **Deviations**: None.

### Step 2: Update design-alignment.md scope paragraph
- **Planned**: One-line clarification at lines 7-8 acknowledging that ship-to-adopter conventions live under `.cwf/docs/conventions/`.
- **Actual**: Replaced 2-line scope paragraph with expanded 5-line version naming `subagent-tool-selection.md` and `tmp-paths.md` as concrete examples and stating "no dev-repo mirror". Surrounding paragraphs preserved.
- **Deviations**: Slightly longer than "one-line" — added concrete examples to anchor the rule. Still additive, no rewrites elsewhere.

### Step 3: Add `**Tmp Paths**:` bullet to CLAUDE.md § Conventions
- **Planned**: Bullet matching `**Commit Messages**:` style, pointing at `.cwf/docs/conventions/tmp-paths.md`.
- **Actual**: Appended after `**Git Path Handling**:` bullet. Three sub-bullets cover canonical form, `mkdir -m 0700` guard, and the derivation snippet pointer. Style matches surrounding bullets.
- **Deviations**: None.

### Step 4: Annotate `.cwf/docs/skills/security-review.md:98`
- **Planned**: Append `# illustrative — not a canonical scratch path; see .cwf/docs/conventions/tmp-paths.md` to the anti-pattern line.
- **Actual**: Added three trailing comment lines (the existing `# shell metachars in $source execute` was preserved on its own line). Annotation reads: `# /tmp/cwf-update is illustrative — not a canonical scratch path; see .cwf/docs/conventions/tmp-paths.md`. Original anti-pattern code unchanged.
- **Deviations**: Comment split across three lines for column-width readability; intent identical.

### Step 5: Update agent-memory files + grep gate
- **Planned**: Update `feedback_no_heredocs.md`, `feedback_no_tee_permissions.md`, `MEMORY.md`. Verify grep gate clears.
- **Actual**:
  - `feedback_no_heredocs.md` — replaced "one-off scripts" sub-section with canonical-form examples; appended explicit "Historical:" annotation describing the old un-namespaced form.
  - `feedback_no_tee_permissions.md` — verified already canonical (this session's prior edit holds; line 19 documents rationale).
  - `MEMORY.md` — updated squash-commit line (line 20) to canonical form with historical annotation; updated `feedback_no_heredocs` index entry (line 43) to point at `[[tmp-paths]]` instead of stale `/tmp/<task>/`.
  - `project_archaeological_main.md` — **deviation**: discovered during grep gate run. The plan listed three memory files; this fourth file (memory entry on archaeological-main methodology) also embedded `/tmp/msg.txt`. Updated in-line with canonical form + `[[tmp-paths]]` link.
- **Grep gate result**: Three remaining `/tmp/task-*`/`/tmp/msg.txt` matches, all inside explicit historical/rationale annotations per the plan's exception clause (`feedback_no_tee_permissions.md:19`, `feedback_no_heredocs.md:25`, `MEMORY.md:20`). Pass.
- **Deviations**: Plan named 3 memory files; actually updated 4 (added `project_archaeological_main.md`). Surfaced honestly here; the gate-driven discovery is exactly the failure mode the gate exists to catch.

### Step 6: Restore `.claude/agents/cwf-security-reviewer-changeset.md` to 0444
- **Planned**: `chmod 0444`; verify perms via `ls -la`; do not modify content.
- **Actual**: `chmod 0444` succeeded. `ls -la` confirms `-r--r--r--`. `sha256sum` returns `c7033a74da495e7ef7b401f0b88ab6b8d8e53cfb69acb1a924c463bb182095e5`, matching `script-hashes.json:27`. Content unchanged; perms-only restoration.
- **Deviations**: None.

### Step 7: Confirm no hash-record update needed
- **Planned**: Grep `script-hashes.json` for any modified path; expect none.
- **Actual**: `grep '"path"' .cwf/security/script-hashes.json | grep -E 'tmp-paths|design-alignment|security-review\.md|CLAUDE\.md'` returns zero matches. No hash record needs updating. `cwf-manage validate` post-implementation returns `OK` with exit 0 (was 1 violation pre-implementation; Step 6 cleared it).
- **Deviations**: None.

## Blockers Encountered
None.

## Deferral Check
Before marking status=Finished, verify:
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] All requirements from b-requirements-plan.md addressed (N/A for chore)
- [x] All design guidance in c-design-plan.md followed (N/A for chore)
- [x] No planned work deferred without user approval
- [x] If work deferred: Follow-up task created and linked (none deferred)

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: no findings

no findings
The diff adds an inline comment clarifying that `/tmp/cwf-update` in an illustrative bad-example snippet is not a canonical scratch path, pointing to `.cwf/docs/conventions/tmp-paths.md`. Documentation-only change to a security-review reference doc; no executable code, no new attack surface, no change to threat-model coverage.

## Lessons Learned
- Grep gate caught a 4th memory file (`project_archaeological_main.md`) not on the original plan list. This is exactly the failure mode the gate exists for; the plan's success isn't "list every file upfront" but "the gate clears before marking Finished".
- The 0444 restoration cleanly resolved the noisy `cwf-manage validate` warning that was bleeding into every checkpoint commit during planning phases — confirms that folding orthogonal-but-noisy hygiene into a related task can be net-positive when the SHA pre-verification eliminates the integrity-bypass concern.
- The security-review-changeset helper only included `.cwf/docs/skills/security-review.md` (1 file, 14 lines) — `CLAUDE.md`, `docs/conventions/design-alignment.md`, the new `.cwf/docs/conventions/tmp-paths.md`, and the four memory files are all outside the helper's CWF-internal coverage prefixes. Expected behaviour; noted so reviewers don't wonder why the diff is small relative to the change.
