# Reconcile or retire stale .cwf/utils spec docs - Testing Execution
**Task**: 197 (chore)

## Task Reference
- **Task ID**: internal-197
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/197-reconcile-or-retire-stale-cwfutils-spec-docs
- **Template Version**: 2.1

## Goal
Execute the five verification test cases from e-testing-plan.md and confirm the four `.cwf/utils/*.md` docs are cleanly retired with no dangling references and no integrity regression.

## Test Results

### Functional Tests

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1 | Files removed | `git ls-files .cwf/utils/` empty; worktree dir absent | 0 tracked files; `.cwf/utils/` ABSENT | PASS |
| TC-2 | No dangling functional reference | No helper/lib/skill/template/test hit on the four basenames | Files-with-matches = `BACKLOG.md`, `CHANGELOG.md`, and 9 `implementation-guide/**` archives only; zero non-archive consumers | PASS |
| TC-3 | Second backlog item de-referenced | `grep -c "utils/template-engine" BACKLOG.md` = 0 | 0 matches | PASS |
| TC-4 | Originating backlog item retired | Title absent from BACKLOG, present in CHANGELOG | BACKLOG = 0, CHANGELOG = 1 | PASS |
| TC-5 | Integrity gate green | `cwf-manage validate` exit 0, `validate: OK` | `[CWF] validate: OK`, exit 0 | PASS |

**TC-2 detail**: `grep -rln` across `*.md/*.pl/*.pm/*.json` for the four basenames, then excluding `implementation-guide/`, `BACKLOG.md`, `CHANGELOG.md`, yields an empty set — no `.cwf/scripts`, `.cwf/lib`, `.claude/skills`, `.cwf/templates`, or `t/**` test consumer. The remaining matches are the two close-out docs (handled by this task) and archival task records (tasks 1, 59, 96, 151, 160, 196, plus this task's own plans). The pre-rebrand `.cig/utils/...` strings in task 1 are historical and not live paths.

### Non-Functional Tests
N/A — documentation-only deletion. No performance, security-auth, or reliability surface. (The d-phase plan review and the f-phase changeset security review both returned `no findings`.)

## Test Failures
None. All five test cases passed on first execution.

## Coverage Report
100% of planned test cases (TC-1 … TC-5) executed; 5/5 PASS. Coverage targets from e-testing-plan.md met: all four target files removed, zero dangling references beyond the intended historical records, integrity gate green.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
- The TC-2 sweep filter must not assume grep prefixes paths with `./` — GNU grep with a `.` start-path emits bare `implementation-guide/...` paths, so a `^\./...` exclusion silently matches nothing. Filter on the bare path prefix instead.

## Security Review

**State**: no findings

I have the changeset and the threat model. Let me reason through the five threat categories.

This is the testing-exec phase changeset for Task 197. Let me characterise what it ships.

**Nature of the changeset.** This is a documentation-only change. It comprises:
- Deletion of four inert `.cwf/utils/*.md` spec docs (`config-loader.md`, `hierarchy-manager.md`, `task-validator.md`, `template-engine.md`), all mode `100644` prose files.
- New Task-197 workflow files (`a`/`d`/`e`/`f`/`g`/`j`).
- Edits to `BACKLOG.md` and `CHANGELOG.md` for close-out.

No Perl, shell, JSON config, hooks, skills, or templates are added or modified. No executable code anywhere in the diff.

**(a) Bash injection / unsafe command construction.** No executable code is added or modified. The deleted `hierarchy-manager.md` contained an illustrative `find … | sed` numbering snippet (diff lines 65-69) — but it is being *removed*, not introduced, and it was never a wired-up command (it was prose documentation). The workflow files quote `git rm`, `grep`, `cwf-manage validate` invocations as descriptive prose recording what was run, not as code that executes from these files. No interpolation of slugs/branch names/paths into shell calls. Nothing to flag.

**(b) Perl helpers consuming git/user output.** No Perl is added or changed; no git-porcelain parsing introduced. N/A.

**(c) Prompt injection via user-supplied strings.** No `{arguments}` substitution surface or any new untrusted-input flow is added or altered. The new content is authored process prose. One positive note: the f-exec file records that `backlog-manager retire --note` enforces printable-ASCII (rejected an em-dash), which is an input-validation observation, not a concern. Nothing to flag.

**(d) Unsafe environment-variable handling.** No env vars introduced or consumed; no paths flow to `chmod`/`rm`/`open` from any added code. The plan correctly notes none of the four deleted files were hash-tracked. N/A.

**(e) Pattern-based risks (safe-here-but-risky-elsewhere).** No reusable code pattern is added. The one structural consideration is that deleting files in `.cwf/` removes content that ships to end users via `git read-tree --prefix=.cwf/`. The testing-exec evidence (TC-1 through TC-5, diff lines 615-619) confirms `git ls-files .cwf/utils/` is empty and the only surviving references to the four basenames are archival `implementation-guide/**` task records and append-only `CHANGELOG.md` historical notes — no live helper/lib/skill/template/test consumer. The BACKLOG diff (line 195) confirms the second open backlog item dropped its live `template-engine.md:41` path token, leaving `SKILL.md:48` as the sole awk site, so no dangling live pointer to a deleted file remains. No security-relevant residue.

One observation worth noting (not a finding): the f-implementation-exec file embeds its own `## Security Review` section with a self-emitted `cwf-review` block (diff lines 586-589). That is the *implementation-exec* phase's own recorded verdict captured inside a committed workflow file — it is inert prose here, not a second verdict competing with mine. The deterministic classifier parses only my response, not file contents, so there is no classifier-confusion risk from that embedded block.

This is a subtractive documentation change with no executable, hash-tracked, env-var, or input-flow surface. The testing-exec verification confirms no functional consumers and no integrity drift. Clean.

```cwf-review
state: no findings
summary: Testing-exec changeset for Task 197 is documentation-only (deletes four inert .cwf/utils/*.md docs plus Task-197 workflow/backlog/changelog edits); no executable, hash-tracked, env-var, or input-flow surface, and verification confirms no dangling live references.
```
