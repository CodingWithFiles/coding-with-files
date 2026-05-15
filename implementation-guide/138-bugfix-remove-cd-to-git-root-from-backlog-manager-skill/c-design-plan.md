# Remove cd to git root from backlog-manager skill - Design
**Task**: 138 (bugfix)

## Task Reference
- **Task ID**: internal-138
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/138-remove-cd-to-git-root-from-backlog-manager-skill
- **Template Version**: 2.1

## Goal
Specify the exact edits to `.claude/skills/cwf-backlog-manager/SKILL.md` that strip the `cd "$(git rev-parse --show-toplevel)" && ` prefix and its accompanying threat-model paragraph, and record the rationale so the change is not reverted by a future "defensive" rewrite.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

In this task: **Simplicity** dominates. The change is a deletion; correctness is a string-presence check.

## Architecture Choice
- **Decision**: Delete the prefix and the threat-model paragraph; keep no replacement guidance.
- **Rationale**:
  - The relative-path invocation form `.cwf/scripts/command-helpers/backlog-manager` is, by construction, only usable from a cwd that contains `.cwf/scripts/command-helpers/backlog-manager` — i.e. the repo root. From anywhere else, `execve` fails with `ENOENT` and the call is loud about it. There is no separate "check" being performed; the invocation form itself encodes the requirement.
  - The existing paragraph (SKILL.md lines 18-23) frames the cd as a guard against an attacker who "changes cwd to /tmp and stages /tmp/.cwf/scripts/...". The actor in that story is the same agent (Claude) that would also follow the guard — they share a trust boundary, so the guard cannot constrain the threat.
  - Replacement guidance ("anchor with absolute path", "check `$PWD`", etc.) re-introduces noise to defend against the same non-threat. Deleting outright is the minimal correct change.
  - **Bonus (from security review)**: in a nested-repo / git-worktree edge case where cwd happens to be inside a different repo, the *current* cd form would silently `cd` into that other repo's toplevel and run whatever `.cwf/scripts/command-helpers/backlog-manager` exists there. The new form fails cleanly with ENOENT in that case. The change is a small *gain* in robustness, not a loss.
- **Trade-offs**:
  - **+** SKILL.md becomes shorter and every example is copy-pasteable verbatim.
  - **+** Eliminates the `$(git rev-parse --show-toplevel)` substitution, which is a known source of blocking permissions prompts in the Bash tool.
  - **+** Aligns this skill with the rest of the CWF skill corpus, which already invokes helpers without a cd prefix (`workflow-manager`, `context-manager`, `task-context-inference`, etc.).
  - **−** Loses a (false) security note. A reader who recovers the deleted text from git history might re-add it; mitigated by the retrospective recording the reasoning.

## Edits to Apply

All edits are to `.claude/skills/cwf-backlog-manager/SKILL.md`. Implementation plan will translate these into Edit-tool calls.

| # | Location | Action |
|---|---|---|
| 1 | Lines 18-23 (the "Mandatory pre-step" paragraph and its example fence) | Delete the entire block. The "Context" section ends after the **Helper path** bullet. |
| 2 | Lines 33, 40, 48, 60, 68, 76, 77, 84 (subcommand example fences) | Strip the leading `cd "$(git rev-parse --show-toplevel)" && ` from each invocation, leaving `.cwf/scripts/command-helpers/backlog-manager …` |
| 3 | Line 95 (Success Criteria checkbox: "Subcommand invoked from git-root via `cd …`") | Delete the checkbox outright. The remaining two checkboxes (list-form args, exit-code observation) are the real correctness criteria. The "must run from repo root" property is moved from a skill-author assertion (a checkbox) to a runtime invariant (ENOENT if cwd is wrong); `e-testing-plan` is responsible for verifying the rewritten examples actually run from the repo root. |

**No other files change.** Repo-wide grep confirms no cross-references to the deleted phrases outside this skill (verified `Mandatory pre-step`, `invoked from git-root`).

## Affected Surface
- **Single file**: `.claude/skills/cwf-backlog-manager/SKILL.md`
- **Out of scope**:
  - `.claude/skills/cwf-init/SKILL.md` line 87 uses `git rev-parse --show-toplevel` for a different purpose (captures GIT_ROOT into a variable that is then passed as an *argument* to a helper that needs an absolute path). The pattern is genuinely necessary there; not in scope here.
  - The helper script `.cwf/scripts/command-helpers/backlog-manager` itself. No code changes.
  - The integrity-hash manifest. Skills are not under `.cwf/`, so `cwf-security-check verify` is unaffected; included in success criteria as a sanity check only.

## Alternatives Considered
1. **Replace prefix with a "verify cwd" guard** (e.g. `[[ "$PWD" = "$(git rev-parse --show-toplevel)" ]] || exit 1`). Rejected — same trust-boundary problem, and now lives inside every example. Adds noise.
2. **Move the guard into the helper** (`backlog-manager` refuses to run unless invoked from git root). Rejected — the helper is the thing being attacked in the cited threat model, so a self-check inside it cannot defend against substitution; an attacker's binary just omits the check. Also: the kernel already enforces this via path resolution at the call site.
3. **Keep the prefix, add a comment** explaining it is belt-and-braces. Rejected — verbose, and "belt-and-braces" implies the braces add something, which they do not.
4. **Delete (chosen)**. Minimal, correct, matches the project preference for "no new code/text unless it earns its place".

## Validation Strategy (deferred to e-testing-plan)
- Grep verification (zero residual occurrences).
- Smoke-test two subcommands (`list`, `validate`) from the repo root using exactly the rewritten example form.
- `cwf-security-check verify` clean.

## Decomposition Check
- [ ] **Time**: <0.5 day — no
- [ ] **People**: single edit — no
- [ ] **Complexity**: one file, mechanical — no
- [ ] **Risk**: low — no
- [ ] **Independence**: not splittable — no

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 138
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
