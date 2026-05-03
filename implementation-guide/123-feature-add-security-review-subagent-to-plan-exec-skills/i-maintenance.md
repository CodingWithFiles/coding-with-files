# Add security-review subagent to plan/exec skills - Maintenance
**Task**: 123 (feature)

## Task Reference
- **Task ID**: internal-123
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/123-add-security-review-subagent-to-plan-exec-skills
- **Template Version**: 2.1

## Active Maintenance Requirements

**Scheduled maintenance**: NONE — docs-and-skills change with no state, no logs, no cron, no external dependencies. Subagent fires only at SKILL invocation time.

**Reactive maintenance**:
- **IF** the security subagent consistently returns `**State**: error` across multiple tasks → **THEN** check `.cwf/docs/skills/security-review.md` § "Exec-phase prompt template" hasn't been malformed; verify both exec SKILLs still construct the changeset correctly (`git diff $(git merge-base HEAD main)..HEAD -- <pathspec>`); confirm Agent tool is still in `allowed-tools` for both exec SKILLs (grep `^- Agent` in their frontmatter).
- **IF** the security subagent consistently returns `**State**: findings` with substantively-no-findings bodies (the TC-AC8 pattern) across the next few tasks → **THEN** tighten the prompt template in `security-review.md` § "Exec-phase prompt template" to push the sentinel line ahead of any analysis. Suggested wording: "Your VERY FIRST output line MUST be the sentinel — do not preface with analysis." This is a one-line edit; create a follow-up task and update the prompt in one place (the canonical doc; both exec SKILLs inherit automatically).
- **IF** a new security-relevant tree is added to the repo (e.g. a future `.cwf/scripts/post-install/` or a new hook directory) → **THEN** update the pathspec in `.cwf/docs/skills/security-review.md` § "Pathspec coverage". The maintainer note inside that section makes this single-source-of-truth invariant explicit; both exec SKILLs reference the doc by section name and will pick up the change automatically with no SKILL edit.
- **IF** the user-facing built-in `/security-review` command changes scope (e.g. becomes callable from a subagent) → **THEN** revisit the boundary text in `security-review.md` § "Scope" and decide whether the in-workflow subagent should chain it. Currently the boundary is hard: built-in is user-invoked only.
- **IF** `cwf-manage validate` changes which trees it covers (currently `.cwf/scripts/` and `.cwf/lib/` per the hash manifest) → **THEN** revisit the boundary in `security-review.md` § "Scope" so the subagent doesn't start duplicating coverage that has become deterministic.

**Deprecation trigger**: If CWF migrates plan-review off the existing 3-subagent map/reduce pattern (or away from the `Read/Grep/Glob` allowlist), the 4th security subagent must migrate together with the other 3 — they share the procedure in `plan-review.md`. The Security column in the criteria-lookup table is structurally identical to the other three columns and will follow whatever pattern they follow.

## Known Co-Behaviour
- **Plan-phase 4th subagent and exec-phase Step 8 are independent integration points**. They share the canonical doc and threat model but invoke separately. Either can be reverted without disturbing the other if needed (per h-rollout § "Rollback Triggers").
- **Workflow plan files describing this design (`c-design-plan.md`, `f-implementation-exec.md`) contain the verbose pathspec verbatim** as part of their prose. This is expected and does not violate the single-source-of-truth invariant — only runtime artefacts (SKILLs, helpers) are bound by it. If a future task moves the pathspec, do not chase the stale copies inside Task 123's workflow files; treat them as an archaeological record.
- **The three-tier classifier (primary sentinel → numbered-list fallback → conservative-default error)** lives in `security-review.md` § "Exec-phase prompt template" and is referenced by both exec SKILLs. If the classifier rules are tightened or relaxed, edit the doc once; both SKILLs will follow.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 123
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*Captured per phase above*

## Lessons Learned
Reactive triggers keyed off the canonical doc as the single source of truth — adding a security-relevant tree means editing the doc once, not chasing references in two SKILLs.
