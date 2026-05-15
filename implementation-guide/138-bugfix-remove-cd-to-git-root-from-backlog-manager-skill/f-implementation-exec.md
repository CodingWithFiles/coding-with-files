# Remove cd to git root from backlog-manager skill - Implementation Execution
**Task**: 138 (bugfix)

## Task Reference
- **Task ID**: internal-138
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/138-remove-cd-to-git-root-from-backlog-manager-skill
- **Template Version**: 2.1

## Goal
Execute the three Edit-tool calls specified in `d-implementation-plan.md` against `.claude/skills/cwf-backlog-manager/SKILL.md`.

## Actual Results

### Step 1: Delete the "Mandatory pre-step" paragraph + trailing blank
- **Planned**: Edit with `old_string` = the 7-line block at lines 18-24 (paragraph + fenced example + threat-model paragraph + trailing blank), `new_string` = empty.
- **Actual**: Edit applied cleanly. The Context section now ends with `**Helper path**: ...` followed by a single blank line directly into `## Subcommands`. No double-blank-line artefact.
- **Deviations**: None.

### Step 2: Strip the `cd "$(...)" && ` prefix from every example
- **Planned**: Single Edit with `replace_all: true`, `old_string` = `cd "$(git rev-parse --show-toplevel)" && .cwf/scripts/command-helpers/backlog-manager`, `new_string` = `.cwf/scripts/command-helpers/backlog-manager`.
- **Actual**: One Edit call replaced all occurrences. All 8 subcommand example fences (`validate`, `list`, `add`, `modify`, `delete`, two `normalise` lines, `retire`) now invoke the helper directly.
- **Deviations**: None.

### Step 3: Delete the Success-Criteria checkbox referencing the cd
- **Planned**: Edit with `old_string` = `- [ ] Subcommand invoked from git-root via \`cd "$(git rev-parse --show-toplevel)"\`\n`, `new_string` = empty.
- **Actual**: Edit applied cleanly. `## Success Criteria` now has exactly the two retained checkboxes (list-form args, exit-code observation).
- **Deviations**: None.

### Step 4: Verify no residue
- **Planned**: Repo-wide grep for `git rev-parse --show-toplevel` and `Mandatory pre-step` returning only the `cwf-init` use as out-of-scope.
- **Actual** (deviation): The original grep pattern `git rev-parse --show-toplevel` is too broad — it flags every internal Perl/shell use that captures the git root into a variable for absolute-path argument passing (e.g. `.cwf/lib/CWF/Common.pm:50`, `.cwf/scripts/cwf-manage:53`, and many more). Those are legitimate and orthogonal to the cd-prefix-in-skill-examples pattern this task targets.
  - Re-ran with the correctly scoped pattern `cd "$(git rev-parse --show-toplevel)"` (the literal cd-prefix form). One match: `.cwf/scripts/update-cwf-skill-docs.sh:10`. Inspected — it's a Task-40 migration shell script that uses `cd` for its own execution context (not user-facing skill guidance). Out of scope for Task 138.
  - `Mandatory pre-step`: zero matches anywhere in the repo.
- **Deviations**: Grep pattern in the d-plan was over-broad. Correcting the pattern in the exec was the right call rather than adjusting the plan retroactively. Recording this lesson here.

## Files Changed
- `.claude/skills/cwf-backlog-manager/SKILL.md` — paragraph deleted, prefix stripped from 8 examples, one Success-Criteria checkbox removed. Net diff: -16 lines, +0 lines (approx).

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md satisfied at the implementation level (testing-execution will confirm the rest)
- [x] All design guidance in c-design-plan.md followed
- [x] No planned work deferred

## Security Review

**State**: findings

**Note**: the original run at f-exec time saw a 0-line changeset because the SKILL.md edit was unstaged when the helper was invoked (the helper anchors against committed history). After the f-checkpoint commit, re-running `security-review-changeset --phase=implementation` returns the full 88-line task diff (`reviewed 1 files, 88 lines, anchor=7500aef`). The Agent (`Explore`) subagent was re-invoked against that diff with the standard exec-phase prompt; verbatim response below.

Classification: `findings` (via fallback rule — body contains a numbered list, primary sentinel was inside body rather than first line).

```
Analysis: the changeset removes the cd-prefix, the threat-model paragraph, and one Success-Criteria checkbox. Per-category review:
- (a) Bash injection: not relevant. Examples use list-form invocation of the helper itself.
- (b) Perl helpers w/ newline-split git output: not relevant; doc-only edit.
- (c) Prompt injection: not relevant; SKILL examples, no user-supplied strings flow into LLM context.
- (d) Unsafe env vars: not relevant; no env-var references in the diff.
- (e) Pattern-based risks: see finding below.

findings:

1. Category (e) — Pattern-based risk: loss of invariant documentation. The deleted "Mandatory pre-step" paragraph documented the reasoning that makes the relative-path invocation safe (kernel ENOENT on a wrong cwd). Removing the documentation removes the audit trail for future readers/maintainers who encounter similar relative-path patterns elsewhere in CWF or who might copy this pattern into a new context where the invariant does not hold. The runtime behaviour is provably safe at this callsite; the concern is defence-in-depth via documented reasoning. Suggested remediation: restore a one-line inline comment above the first example, e.g. `<!-- Relative path is self-anchoring: kernel ENOENT prevents cwd-pivot attacks. -->`, preserving the invariant without mandating the cd.
```

**Decision**: declined. Three reasons:

1. The suggested remediation form (`<!-- ... -->`) is HTML, not markdown. Markdown documents should not use HTML comments as a content channel; if reasoning matters enough to keep, it should be markdown prose, not invisible HTML.
2. Once HTML is off the table, the only markdown-native way to "preserve the reasoning at the callsite" is a regular paragraph or list item — which is exactly the content the design plan chose to delete. The proposed remediation collapses back to undoing the change.
3. `c-design-plan.md`'s "Alternatives Considered" #3 already weighed and rejected the "keep a sanitised note" alternative because it re-introduces noise to defend against an already-debunked threat model and tempts future maintainers to treat the comment as load-bearing rather than archival.

The reasoning is preserved in this task's archived workflow files and will be referenced from the retrospective. No live edit applied.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 138
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
- The plan's "residue grep" pattern was specified too broadly (raw `git rev-parse --show-toplevel`). The intent was the cd-prefix invocation pattern in skill examples, so the correct anchor is `cd "$(git rev-parse --show-toplevel)"`. Worth noting for retrospective: when a phrase is a common idiom inside the codebase, grep patterns for "removal verification" must anchor on the *form being removed*, not the substring it contains.
