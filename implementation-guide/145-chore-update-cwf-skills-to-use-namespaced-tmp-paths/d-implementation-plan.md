# update cwf skills to use namespaced tmp paths - Implementation Plan
**Task**: 145 (chore)

## Task Reference
- **Task ID**: internal-145
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/145-update-cwf-skills-to-use-namespaced-tmp-paths
- **Template Version**: 2.1

## Goal
Establish a project-namespaced `/tmp/` scratch-path convention as a single source of truth, so future skill text and existing agent memory point at one place instead of carrying the rule.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Scope clarification

A repo-wide grep for `/tmp/` confirmed **no current CWF skill text explicitly prescribes `/tmp/<task>/...` paths**. The pattern is emergent from agent memory plus ad-hoc practice. References found:

- `INSTALL.md` (install-time, single-user, no collision risk) — out of scope.
- `BACKLOG.md` / `CHANGELOG.md` (historical) — out of scope.
- `implementation-guide/17-.../e-testing.md` (protected wf-files) — out of scope.
- `.cwf/scripts/command-helpers/template-copier-v2.0` / `-v2.1` (illustrative `--destination=/tmp/test` example strings, not runtime paths) — out of scope.
- `.cwf/docs/skills/security-review.md:98` (illustrative bash-injection anti-pattern using `/tmp/cwf-update`) — out of scope as a path example, but a one-line inline annotation will be added so future readers don't "fix" it to match the new convention (see Step 3 below).

The work is therefore docs-only: one convention doc + cross-references on the project's documented discovery surface + agent-memory updates.

## Canonical form (resolved during plan review)

`/tmp/<dashified-absolute-repo-path>-task-<num>/` — Claude-Code-style dashified path mirroring `~/.claude/projects/` naming.

Example: `/tmp/-home-matt-repo-coding-with-files-task-145/`

Chosen because:
- Unambiguous across multiple worktrees of the same repo (a basename-only form like `/tmp/coding-with-files-task-145/` would collide).
- Matches a naming convention the user already encounters (`~/.claude/projects/`).
- Trivial to derive at runtime: `repo_root=$(pwd); echo "/tmp/${repo_root//\//-}-task-${num}"`.

A short-form fallback (`/tmp/<basename>-task-<num>/`) is *not* offered — multiple forms invite drift and the dashified form is no harder to construct programmatically than the basename form.

## Files to Modify

### Primary Changes (new)
- `.cwf/docs/conventions/tmp-paths.md` — **new file**. Single source of truth. Sections:
  1. Convention (canonical form, derivation snippet, worked examples for: scratch scripts, commit-message scratch files, subagent prompt captures).
  2. Threat model (single-user dev host scope; mandatory `mkdir -m 0700` on first use to defend against `/tmp` symlink attacks on shared hosts; do not write secrets / `.env` content).
  3. Why (collision avoidance for concurrent project-agents; cites the `~/.claude/projects/` precedent).
  4. What is out of scope (install scripts, historical artefacts, user-owned files).
  5. See also (cross-links to `design-alignment.md`, the relevant agent-memory entries).

**Placed under `.cwf/docs/conventions/` (not `docs/conventions/`)** because the convention is content-applicable to adopters (their agents face the same collision risk in their own repos). Adopters install only `.cwf/` via `git subtree`; a dev-repo-only `docs/` location would strand them. Single file, no mirror, no symlink. Follows the same placement pattern as the existing `.cwf/docs/conventions/subagent-tool-selection.md`.

Hash-registry note: `.cwf/security/script-hashes.json` does not track `subagent-tool-selection.md` (the precedent installed convention), so `tmp-paths.md` likewise needs no hash record. Verified by grep during plan amendment.

### Supporting Changes (cross-references — mandated by `design-alignment.md:116-122`)
- `CLAUDE.md` — add a `**Tmp Paths**:` bullet under `## Conventions` (line 49+), matching the existing `**Commit Messages**` style. Bullet points at `.cwf/docs/conventions/tmp-paths.md`. This is the project's documented top-level discovery surface for conventions.
- `docs/conventions/design-alignment.md` lines 7-8 — extend the dev-repo-vs-installed scope paragraph to acknowledge that conventions which need to ship to adopters live under `.cwf/docs/conventions/`, regardless of dev-repo origin. One-line clarification; preserves existing wording.
- `.cwf/docs/glossary.md` — verify whether "namespaced scratch path" or "canonical tmp dir" needs a glossary entry; add if so. (Mandated by `design-alignment.md:120-122` *if* a new term is introduced.)
- `.cwf/docs/skills/security-review.md:98` — append a `# illustrative — not a canonical scratch path` inline comment on the existing anti-pattern, so future readers don't gold-plate it to match `tmp-paths.md`.

### Explicitly NOT modified (and why)
- `.cwf/docs/skills/checkpoint-commit.md` — no current `/tmp/` reference; adding a cross-ref would be speculative.
- `.cwf/docs/skills/security-review.md` § "Pathspec coverage" — the section is about *which files the subagent reviews*, not about scratch-file persistence. Wrong anchor.
- `docs/conventions/tmp-paths.md` — no dev-repo copy. Single file lives at `.cwf/docs/conventions/tmp-paths.md`; dev repo accesses it via that path. (Inverts the implicit "primary in `docs/`, copy in `.cwf/`" pattern; `design-alignment.md` line-7-8 update documents the exception.)
- `INSTALL.md`, `BACKLOG.md`, `CHANGELOG.md`, `implementation-guide/<old-task>/...` — install-time, immutable history, or protected wf-files.
- `.claude/settings.local.json` — user-owned; existing `/tmp/task-NNN/` allowlist entries predate the convention. Do not retroactively rewrite. (A note in `tmp-paths.md` § "What is out of scope" will explicitly call this out.)
- No new helper script (deferred per `a-task-plan.md` constraint).

### Adjacent work (outside repo — must be done in-session before marking task Finished)
Per `MEMORY.md` § "Recurring Process Errors" the deferral anti-pattern (Task 37) is to mark Finished while side-work remains. The following memory files must be updated and verified in-session:

- `~/.claude/projects/-home-matt-repo-coding-with-files/memory/feedback_no_heredocs.md` — replace `/tmp/<task>/` with the canonical form; link to `tmp-paths.md`.
- `~/.claude/projects/-home-matt-repo-coding-with-files/memory/feedback_no_tee_permissions.md` — already updated this session; verify alignment with canonical form.
- `~/.claude/projects/-home-matt-repo-coding-with-files/memory/MEMORY.md` — `/tmp/msg.txt` in the squash-commit entry: update to namespaced form.

Verification gate: before marking the task Finished, `grep -rn '/tmp/<task>\|/tmp/cwf-task\|/tmp/msg.txt' ~/.claude/projects/-home-matt-repo-coding-with-files/memory/` must return zero hits (or only hits inside "historical references" annotations).

## Implementation Steps

### Step 1: Write the convention doc
- [ ] Write `.cwf/docs/conventions/tmp-paths.md` per § "Files to Modify" → "Primary Changes" structure. Include a copy-pastable derivation snippet that the e-testing-plan smoke test can exercise verbatim.
- [ ] Decide whether a glossary term is introduced; if so, add to `.cwf/docs/glossary.md` per `design-alignment.md:120-122`.

### Step 2: Update design-alignment scope paragraph
- [ ] Edit `docs/conventions/design-alignment.md:7-8` to acknowledge that conventions which need to ship to adopters live under `.cwf/docs/conventions/`. Minimal one-line clarification; do not rewrite the surrounding paragraph.

### Step 3: Update discovery surface
- [ ] Add `**Tmp Paths**:` bullet to `CLAUDE.md` § Conventions, matching `**Commit Messages**:` style. Bullet points at `.cwf/docs/conventions/tmp-paths.md`.

### Step 4: Annotate the existing anti-pattern
- [ ] Append `# illustrative — not a canonical scratch path; see .cwf/docs/conventions/tmp-paths.md` to `.cwf/docs/skills/security-review.md:98` so future readers don't "fix" it to match the new convention.

### Step 5: Update agent memory (in-session, pre-Finished)
- [ ] Edit the three memory files listed in § "Adjacent work".
- [ ] Run the verification grep before the checkpoint commit for phase g (testing-exec) — failure to clear the grep blocks marking task Finished.

### Step 6: Restore `cwf-security-reviewer-changeset.md` permissions
- [ ] `chmod 0444 .claude/agents/cwf-security-reviewer-changeset.md` to restore the recorded permissions per `.cwf/security/script-hashes.json:26`.
- [ ] Verify with `ls -la` that the file is now `-r--r--r--`.
- [ ] Do not modify the file content; the SHA already matches the recorded value (verified during plan amendment).
- [ ] This step is orthogonal to the namespaced-tmp-paths work but folded in to clear the validation noise that surfaces on every checkpoint commit during this task. The validation mechanism itself is unchanged.

### Step 7: Confirm no hash-record update needed
- [ ] Grep `.cwf/security/script-hashes.json` for any path that will change. Already verified during plan amendment: `subagent-tool-selection.md` (the precedent installed convention) is not tracked, so `tmp-paths.md` follows the same pattern. Expect no hash update.
- [ ] If grep finds an unexpected tracked path among modified files, surface to user and follow the manual hash-update flow used in prior `.cwf/docs/` edits (see Task 143 git log for precedent). Do not propose automation.

## Code Changes

Docs-only task. No code change examples. If implementation reveals that a skill needs more than the planned edits, surface to user and reconsider scope — do not silently expand.

## Test Coverage
**See e-testing-plan.md for complete test plan.**

Headline test outline: invoke the convention's derivation snippet under two simulated repo roots (e.g. `/tmp/repo-a-root` and `/tmp/repo-b-root`) with the same task number; assert the resulting scratch paths differ. The convention doc must contain the derivation snippet verbatim so the test can copy-paste it without drift.

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results.**

## Rollback
Additive, docs-only. Rollback is `git revert <implementation-commit>`. No schema/data migration; no installed-CWF impact.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

The § "Adjacent work" verification grep is the explicit gate for this task.

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
