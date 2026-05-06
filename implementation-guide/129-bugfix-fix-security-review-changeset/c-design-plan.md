# Fix security-review changeset construction - Design
**Task**: 129 (bugfix)

## Task Reference
- **Task ID**: internal-129
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/129-fix-security-review-changeset
- **Template Version**: 2.1

## Goal
Replace the three-axes-broken pathspec/anchor at `.cwf/docs/skills/security-review.md:23` with a content-classifying, language-stack-agnostic, per-task-baseline-anchored changeset construction. Single source of truth lives in one Perl helper script; the doc and both exec SKILLs reference it.

## Design Priorities
Correctness > Maintainability > Performance. (Project rule: this overrides the generic Testability → Readability ordering when they conflict.) Within Maintainability: Readability → Consistency → Simplicity → Reversibility.

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit. Reuse existing CWF library modules (`.cwf/lib/CWF/*`) and helper-script conventions (Perl, `use utf8;`, `git ... -z`, list-form `system`, `#!/usr/bin/perl -CDSL`).

## Key Decisions

### KD-1: Diff anchor — baseline commit SHA stored in `a-task-plan.md`

- **Decision**: `cwf-new-task` and `cwf-new-subtask` capture `git rev-parse HEAD` *before* creating the task branch and pass it to `template-copier-v2.1` as `--baseline-commit=<sha>`. The template substitutes `${baseline_commit}` into a new `a-task-plan.md` field:
  ```markdown
  ## Task Reference
  - …
  - **Baseline Commit**: <40-char sha>
  ```
  The new `security-review-changeset` helper resolves the anchor in this order:
  1. Read `a-task-plan.md` for the task, parse the `**Baseline Commit**:` line, validate the SHA matches `^[0-9a-f]{40}$` and exists via `git rev-parse --verify <sha>^{commit}`. Success → anchor.
  2. Fallback (in-flight tasks created before this fix; their `a-task-plan.md` has no field or a literal `${baseline_commit}` placeholder): `git merge-base HEAD <trunk>`. Trunk resolution: optional top-level `"trunk"` field in `cwf-project.json` → `git symbolic-ref refs/remotes/origin/HEAD` → hardcoded `main`. Resolved name validated against `^[A-Za-z0-9_./\-]+$` before reaching `git`.
- **Rationale**: A markdown field is data; a git ref is plumbing. The data approach is discoverable (a human reading `a-task-plan.md` sees the SHA), self-documenting (field name explains itself), survives rebases of the task-plan checkpoint commit (the file content moves with it), and needs no new git namespace, no cleanup story, and no `.git/` knowledge. Solves bug-report axes (1)–(3) for the steady-state case; the merge-base fallback covers in-flight tasks with no regression.
- **Trade-offs**:
  - **+** No git-ref namespace, no cleanup helper needed, no template-aware `cwf-manage` checks.
  - **+** Subtask-symmetric: each subtask's own `a-task-plan.md` records its own baseline.
  - **+** Visible in normal file diffs and reviews. Future readers can audit the recorded value.
  - **−** If a user rebases the task branch onto a newer trunk mid-task, the recorded SHA names the old fork point and the diff over-includes trunk drift. Mid-task rebase is not a CWF workflow (tasks land via squash + `git branch -f`, never via rebase onto main); if a user breaks this assumption they keep the pieces. Same failure mode as the current `merge-base` anchor — no regression.
  - **−** In-flight tasks hit the fallback; their reviews continue to over-include earlier-task work if predecessors are unmerged. Acceptable: no regression vs. today.
- **Out-of-scope user scenarios** (documented as a one-line note in `cwf-new-task/SKILL.md` and `cwf-new-subtask/SKILL.md`): detached HEAD at task creation, or branching off another task's branch. The recorded SHA is whatever HEAD is at that moment; user is responsible for being on the intended base.

### KD-2: Content classification by shebang sniff over the diff window

- **Decision**: After computing the raw set of files changed between the baseline ref and HEAD (`git diff --name-only -z <base>..HEAD`), classify each path:
  1. **CWF-internal directory rule (unconditional include)**: paths matching the union of `.cwf/scripts/`, `.cwf/lib/`, `.cwf/docs/skills/`, `.cwf/templates/`, `.claude/scripts/`, `.claude/skills/`, `.claude/hooks/`, `.claude/rules/`, `.claude/settings.json`, `.claude/settings.local.json`, `implementation-guide/cwf-project.json`. Reviewed unconditionally regardless of file type — markdown skills/rules carry instructions interpreted by Claude.
  2. **Shebang sniff (conditional include)**: for paths *not* in (1):
     - Open file `<:raw`, `sysread` up to 128 bytes.
     - Take the first line — bytes up to the first `\n` or `\r` (whichever comes first), capped at the 128-byte read.
     - If first line begins with `#!`, parse the interpreter:
       - `#!/usr/bin/env <name> [args…]` → interpreter = `<name>` (everything after `env`, before next whitespace).
       - `#!<path> [args…]` → interpreter = basename of `<path>` (strip path; strip trailing `-<flags>`; do not strip version digits).
     - If interpreter (after the above stripping) matches the anchored regex `^(?:perl|bash|sh|ksh|zsh|fish|python\d?|ruby|node|deno|php|lua|pwsh|powershell)$` → include.
     - The regex is **anchored at both ends** (`^…$`); future maintainers extending it must preserve anchoring (any unanchored alternative could match arbitrary substrings). Documented invariant.
  3. **Default exclude**: anything else.
  Files deleted in the diff are skipped (no content to classify). Submodule pointer changes are skipped. Files matching gitattributes `binary` are not specially handled — the shebang test still applies; a binary that happens to begin with `#!` followed by a listed interpreter name is misclassified (vanishingly rare; documented limitation).
- **Rationale**: Solves bug-report issue (1) — extension is a label, content is the truth. Solves issue (2) for consumer repos — a Python or Go file with a shebang is reviewed without CWF-side edits, and the classification list covers the common-case stack. Cost is bounded by *diff size*, not repo size.
- **Trade-offs**:
  - **+** Single rule covers extensionless CWF helpers (rule 1) and language-agnostic consumer scripts (rule 2). Bounded cost. No `file(1)` fork.
  - **−** Library files with no shebang outside CWF-internal dirs are missed. CWF-internals covered by rule 1. Consumer-side library coverage is a v2 concern (see "Deferred").
  - **−** Shebang-less scripts loaded via `source`/`.` are missed. Documented limitation.
  - **−** Uncommon interpreters (`awk`, `tcl`, `make`, `gawk`) are missed. v1 limitation; the listed regex covers >95% of in-the-wild script interpreters; the list is extendable in a focused follow-up.
  - **−** UTF-8 BOM-prefixed shebang files are missed (vanishingly rare on Unix). Documented limitation.

### KD-3: Single helper script — `.cwf/scripts/command-helpers/security-review-changeset`

- **Decision**: New Perl helper:
  - **Invocation**: `security-review-changeset [--phase=implementation|testing] [--task-num=NUM] [--verbose]`. `--task-num` optional; if omitted, parse from current branch via `CWF::TaskPath::parse_branch` (existing utility at `.cwf/lib/CWF/TaskPath.pm:334`).
  - **stdout**: the `git diff` text covering classified files only — what the subagent reviews.
  - **stderr**: one-line summary `reviewed N files, M lines, anchor=<sha7>`. With `--verbose`, also one path per line.
  - **exit codes**: `0` = changeset produced (may be empty — caller decides), `1` = unrecoverable error (not in a git repo; trunk name fails validation regex; no fallback resolves), `2` reserved.
  - **Permissions**: `0500`, registered in `.cwf/security/script-hashes.json`.
  - **Reuse**: `CWF::Versioning::read_config()` (`.cwf/lib/CWF/Versioning.pm:43`) for `cwf-project.json` access. `CWF::TaskPath::parse_branch()` for branch-name parsing. `CWF::Common::check_perl5opt()` for the standard preamble. Do not re-roll JSON or branch-name parsing.
- **Rationale**: A single executable is the strictest form of single-source-of-truth. Reusing existing CWF library modules keeps the helper short and consistent with the rest of `command-helpers/`.

### KD-4: SSOT relocation — pathspec leaves the doc, contract stays in the doc

- **Decision**: `.cwf/docs/skills/security-review.md` § "Pathspec coverage" is rewritten to describe the *contract*: the helper at `.cwf/scripts/command-helpers/security-review-changeset` returns the changeset; the doc names *what* (CWF-internal directories + shebang-classified scripts in the diff window) and *why* (the three failure modes); the *how* lives in the helper. The literal `git diff $(git merge-base HEAD main) ...` line is removed. Both exec SKILLs replace their `git diff $(git merge-base ...)` line with `.cwf/scripts/command-helpers/security-review-changeset --phase=<phase>`.
- **Rationale**: Doc owns the *what* and *why*; helper owns the *how*. Maintainers updating the directory set or interpreter regex edit the helper; the doc is stable.

### KD-5: Update `cwf-new-task` and `cwf-new-subtask` to record the baseline commit

- **Decision**: Both skills capture `git rev-parse HEAD` *before* `git checkout -b ...` and pass it to `template-copier-v2.1` as `--baseline-commit=<sha>`. The template-copier substitutes `${baseline_commit}` in `a-task-plan.md`. Pool template `.cwf/templates/pool/a-task-plan.md` (or its task-type-specific symlinks) gains the `**Baseline Commit**:` line in the Task Reference section. Both SKILL files gain a one-line user note: "verify you are on the intended base branch before running this command — the baseline is whatever HEAD is at that moment."
- **Rationale**: One field, one substitution variable, two SKILL captures. The change is small enough to fit in a single d-implementation step.

### KD-6: Test — `/t/security-review-changeset.t` using `Test::More`

- **Decision**: Add `t/security-review-changeset.t` following the existing `t/*.t` Test::More convention. Reuse `t/lib/CWFTest/Fixtures.pm` patterns (synthetic git repos via `File::Temp`, as in `t/taskpath.t`). Test matrix:
  1. **Extensionless shebang script (CWF-internal)**: create `tools/cwf-foo` with `#!/usr/bin/perl` → assert included.
  2. **Consumer-stack file (no override)**: create `app/main.py` with `#!/usr/bin/env python3` outside any CWF-internal dir → assert included via shebang sniff alone (no config override needed; this is the consumer-repo win that bug-report issue (2) calls for).
  3. **Unmerged-predecessor isolation**: synthetic repo with `main` → branch `task1` (commit) → branch `task2` from main, create a task directory containing `a-task-plan.md` with the recorded baseline SHA = main's tip → make a single change on task2 → assert the diff covers task2's change only, even with task1's unmerged commit reachable.
  4. **Negative case — binary blob**: write a binary file under `tools/` (no shebang) → assert excluded.
  5. **Negative case — shebang-less plain text**: write `notes.txt` outside CWF-internal dirs → assert excluded.
  6. **Trunk name validation**: write `cwf-project.json` with `"trunk": "main; rm -rf /"` → assert helper exits 1 with diagnostic (validates KD-1's character-set guard).
  7. **Trunk auto-detection**: synthetic repo with `git symbolic-ref refs/remotes/origin/HEAD` set, no `cwf-project.json` trunk field → assert resolution succeeds.
- **Rationale**: Direct mapping from bug-report axes to test cases; plus security cases for the trunk-name guard and auto-detection path.

## System Design

### Component Overview
- **`security-review-changeset`** (new, `.cwf/scripts/command-helpers/`): orchestrator. Resolves anchor (read `a-task-plan.md` baseline → fallback to merge-base) → lists changed files → classifies → emits filtered diff.
- **`cwf-new-task/SKILL.md` and `cwf-new-subtask/SKILL.md`** (modified): capture `git rev-parse HEAD` and pass to template-copier; one-line note about verifying base branch.
- **`template-copier-v2.1`** (modified): accept `--baseline-commit=<sha>` and substitute `${baseline_commit}` in template output.
- **`a-task-plan.md` template** (modified, `.cwf/templates/pool/`): add `**Baseline Commit**: ${baseline_commit}` line in Task Reference section.
- **`cwf-implementation-exec/SKILL.md` and `cwf-testing-exec/SKILL.md` Step 8** (modified): replace inline `git diff …` with helper invocation.
- **`.cwf/docs/skills/security-review.md`** (modified): § "Pathspec coverage" rewritten as contract description.
- **`cwf-project.json` schema** (extended, fallback-only): optional top-level `"trunk": "<name>"` field used only when `a-task-plan.md` lacks a baseline (in-flight tasks).
- **`.cwf/security/script-hashes.json`** (modified): register the new helper with permissions and SHA256.
- **`t/security-review-changeset.t`** (new): regression test.

### Data Flow
1. Exec SKILL Step 8 invokes `security-review-changeset --phase=<phase>` via Bash tool.
2. Helper resolves task number from branch name (or `--task-num`) using `CWF::TaskPath::parse_branch`.
3. Helper locates the task directory via existing `context-manager hierarchy <num>` and reads `a-task-plan.md`.
4. Helper greps for `^- \*\*Baseline Commit\*\*: ([0-9a-f]{40})\s*$`, validates via `git rev-parse --verify <sha>^{commit}`. Success → anchor.
5. Fallback (no field, placeholder still present, or invalid SHA): resolve trunk (config → `git symbolic-ref` → `main`, validated against `^[A-Za-z0-9_./\-]+$`), then `git merge-base HEAD <trunk>` → anchor.
6. Helper runs `git diff --name-only -z <anchor>..HEAD` → list of changed paths.
7. Helper applies CWF-internal-dir rule, then shebang sniff → filtered path list.
8. Helper runs `git diff <anchor>..HEAD -- <filtered-paths>` (list-form `system`/`open`-pipe; never shell-string) → emits to stdout.
9. SKILL captures stdout, applies the existing line-count cap and three-tier classifier from `security-review.md`, invokes the subagent.

## Interface Design

### CLI contract
```
security-review-changeset [--phase=implementation|testing] [--task-num=NUM] [--verbose]

stdout: <git diff output for classified files>
stderr: reviewed N files, M lines, anchor=<sha7>
        [+ one path per line if --verbose]
exit:   0 = ok (changeset may be empty), 1 = error
```

### Config schema (additive)
```json
{
  "trunk": "main"
}
```
Top-level field of `implementation-guide/cwf-project.json`. Optional. Absent → fall back to `git symbolic-ref` then hardcoded `main`. Type: string matching `^[A-Za-z0-9_./\-]+$`.

### Baseline commit field

In `a-task-plan.md`:
```markdown
## Task Reference
- **Task ID**: internal-<num>
- **Branch**: <type>/<num>-<slug>
- **Template Version**: 2.1
- **Baseline Commit**: <40-char SHA — HEAD at the moment cwf-new-task ran>
```
Written once at task creation; never edited thereafter. Survives indefinitely as part of the task's record.

## Constraints
- **POSIX-only**, Perl, `use utf8;`, `#!/usr/bin/perl -CDSL`, `git ... -z`, list-form `system`, per `docs/conventions/perl-git-paths.md`.
- **No shell metacharacter exposure**: every git invocation is list-form (`system "git", "diff", "--name-only", "-z", $base.."..HEAD"` etc.). The trunk name is regex-validated (`^[A-Za-z0-9_./\-]+$`) before reaching `git`. File paths from `git diff --name-only -z` are `\0`-split.
- **Anchored regex invariant**: the shebang-interpreter regex must remain anchored at both ends. Future edits adding interpreters MUST preserve `^(?:…)$`. Stated in KD-2 and as a comment in the helper source.
- **Reuse-don't-rewrite**: `CWF::Versioning::read_config`, `CWF::TaskPath::parse_branch`, `CWF::Common::check_perl5opt` are existing modules; the new helper imports them.
- **Hash-tracked**: the new helper must be added to `.cwf/security/script-hashes.json` (this happens via the existing `cwf-manage` integration; the implementation plan will name the exact step).

## Deferred (not in this task)
- Consumer-declared `always-included-paths` config field for non-shebang library coverage. Deferred — bug-report does not require it; KD-2 already solves consumer-repo issue (2). Open as follow-up if a consumer reports a gap.
- Backfill helper that writes a baseline-commit line into in-flight tasks' `a-task-plan.md` files. Deferred — no regression for those tasks; manual edit is one line if a maintainer wants it.
- Expanding the shebang regex to cover `awk`/`tcl`/`make`/`gawk` and version-pinned interpreters (`python3.11`). Deferred — extension is a focused follow-up; the v1 list covers >95% of script interpreters.

## Decomposition Check
- [ ] **Time**: <1 day implementation + ~half-day test. Stays under threshold.
- [ ] **People**: 1 person.
- [x] **Complexity**: 3 distinct concerns, but one helper + one test file; decomposition would force re-reading the same code thrice. Resolved as one task in a-task-plan.
- [ ] **Risk**: KD-1 (anchor) is the riskiest decision and is named explicitly with documented out-of-scope user scenarios.
- [ ] **Independence**: low — the three changes share a fix-site.

## Validation
- [ ] Plan review (Step 8 of the design skill) passes — done.
- [ ] All five success criteria from a-task-plan.md map to concrete components in this design.
- [ ] No language-extension hardcode appears anywhere in this plan.
- [ ] The trunk name is read from config / symbolic-ref / hardcoded fallback — never assumed `main` without resolution; always validated before reaching git.
- [ ] Task 129's own g-testing-exec generates a security-review changeset whose line count is bounded by this task's delta (its `a-task-plan.md` was written from the old template so has no baseline field → exercises the merge-base fallback path, which validates that fallback's behaviour for in-flight consumer tasks).

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All six key decisions implemented as specified. KD-1 (markdown-field baseline + merge-base fallback): implemented; helper exercises the fallback path on this very task (whose `a-task-plan.md` predates the new field) and produces the bounded diff promised in the design. KD-2 (shebang sniff): implemented with `-e && -f && !-l` guard and anchored interpreter regex. KD-3 (single helper): `.cwf/scripts/command-helpers/security-review-changeset`, ~340 lines Perl, `0500`, hash-tracked. KD-4 (SSOT relocation): `.cwf/docs/skills/security-review.md` § "Pathspec coverage" rewritten as contract; both exec SKILLs invoke the helper. KD-5 (cwf-new-task / cwf-new-subtask baseline capture): both SKILLs updated; template-copier-v2.1 accepts `--baseline-commit=<sha>`. KD-6 (test): 13 subtests PASS.

## Lessons Learned
Plan-review subagents in d-phase caught four real defects — module-API vs shell-out, `git check-ref-format` vs hand-rolled regex, symlink/FIFO/device guard, and `script-hashes.json` top-level `scripts` section — before any code was written. The cost of running 4 parallel Explore subagents is small relative to the cost of an implementation rework cycle. Lesson: do not skip the plan-review step.
