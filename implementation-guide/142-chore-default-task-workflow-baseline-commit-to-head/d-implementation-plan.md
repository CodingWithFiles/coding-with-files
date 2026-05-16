# default task-workflow baseline-commit to HEAD - Implementation Plan
**Task**: 142 (chore)

## Task Reference
- **Task ID**: internal-142
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/142-default-task-workflow-baseline-commit-to-head
- **Template Version**: 2.1

## Goal
Make `--baseline-commit` optional in `template-copier-v2.1`, defaulting to HEAD resolved internally, and remove the `BASELINE_COMMIT=$(git rev-parse HEAD)` shell substitution from the `/cwf-new-task` and `/cwf-new-subtask` SKILL examples.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Design Decision (chore has no c-design-plan)

Two shapes were proposed in the BACKLOG entry:
1. **Omit `--baseline-commit`**, helper resolves HEAD internally.
2. **Accept literal `HEAD`** as a sentinel the helper resolves.

**Chosen: option 1.** Rationale:
- "The best part is no part" — option 1 removes the flag entirely from the documented invocation; option 2 keeps it. HEAD is the load-bearing default in essentially every legitimate use, so making it implicit reflects reality.
- One path, not two. Option 2 leaves both `--baseline-commit=HEAD` and `--baseline-commit=<sha>` as valid shapes for the *same* common case; that's the "two ways to spell HEAD" trap.
- Recorded value in `a-task-plan.md` remains a literal 40-char SHA either way — the resolution happens before substitution.
- The rare expert path (`--baseline-commit=<sha>` for a non-HEAD branch base) keeps working unchanged.

## Files to Modify

### Primary Changes
- `.cwf/lib/CWF/Common.pm` — add `resolve_head_sha()` to the exported API alongside the existing `find_git_root()`. Same pattern (backtick → chomp → validate). Returns the 40-char SHA on success, `undef` on failure (no commits, not in a repo). Add to `@EXPORT_OK` list at line 14.
- `.cwf/scripts/command-helpers/template-copier-v2.1` — import `resolve_head_sha` from CWF::Common (already imports `generate_slug`). Add a small wrapper (or inline call) right before the `$vars{baselineCommit} = ...` line (~399). If `--baseline-commit` was passed, use the explicit value verbatim. If absent, call `resolve_head_sha()`; on undef, `die_msg` with a clear error.
- `.claude/skills/cwf-new-task/SKILL.md` § 3 — strip the `BASELINE_COMMIT=$(...)` capture line and the `--baseline-commit="$BASELINE_COMMIT"` argument from the example block. Keep the surrounding "Verify you are on the intended base branch" guidance — the helper resolves whatever HEAD is at invocation time, so the warning still applies.
- `.claude/skills/cwf-new-subtask/SKILL.md` § 3 — same change as cwf-new-task. The `BASELINE_COMMIT=$(...)` block disappears; the `--baseline-commit="$BASELINE_COMMIT"` line in the prose disappears.

### Supporting Changes
- `.cwf/security/script-hashes.json` — recompute `sha256` for the `template-copier-v2.1` entry (keyed by name, not line number) via `sha256sum` and hand-update. Bump the top-level `last_updated` field. Per Task-141 / `feedback_surface_security_dont_smooth` — no automation, no `recompute-hashes` helper.
- New test file `t/common-resolve-head-sha.t` — unit-test the resolver. Three shapes:
  1. Inside a git repo with at least one commit → returns 40-char hex SHA matching `git rev-parse HEAD`.
  2. Inside a fresh repo with no commits → returns undef (HEAD ref exists but has no commit object).
  3. Outside any git repo (use a tempdir not under one) → returns undef.
  Use `CWFTest::Fixtures::create_git_repo` (already exported, line 112) for the repo-with-commit case. The "no commits" case is `mkdir + chdir + git init` only.
- `t/template-copier-slug-validation.t` (or a sibling file using the same `do`-load + `eval`-die-catch pattern) — integration test that running `template-copier-v2.1` without `--baseline-commit` populates `{{baselineCommit}}` in the rendered `a-task-plan.md` with a 40-char hex SHA. Explicit `--baseline-commit=<sha>` still passes through verbatim (covers the rare expert path).

### Out of Scope (do not touch)
- `--destination` parameter ergonomics (the SKILL.md example reads as parent path, helper treats it as full task-dir path *or* auto-constructs if omitted — separate defect, separate backlog entry).
- Other helpers using `$(git ...)` substitutions in their SKILL examples (e.g. `security-review-changeset`). General-case fix is a separate refactor explicitly named out-of-scope in BACKLOG entry.

## Implementation Steps

### Step 1: Setup
- [ ] Re-read a-task-plan.md and BACKLOG entry to confirm scope
- [ ] Confirm `git rev-parse HEAD` is the canonical resolution call (already used in SKILL examples, no alternative considered)

### Step 2: Library + helper change
- [ ] Open `.cwf/lib/CWF/Common.pm`. Add `resolve_head_sha` to `@EXPORT_OK` at line 14. Add `sub resolve_head_sha` near `find_git_root` (line 49+). Implementation: ``my $sha = `git rev-parse HEAD 2>/dev/null`;`` → `chomp $sha;` → `return $sha =~ /^[0-9a-f]{40}$/ ? $sha : undef;`. Lowercase regex matches `git`'s actual output (no case-folding — `git rev-parse` always returns lowercase hex).
- [ ] Open `.cwf/scripts/command-helpers/template-copier-v2.1`. Add `resolve_head_sha` to the `use CWF::Common qw(...)` import at line 42 (currently imports `generate_slug`). 
- [ ] In `compute_variables` near line 399, replace `$vars{baselineCommit} = $params->{baseline_commit} // '';` with the resolver call: if explicit value is defined and non-empty, use it verbatim; otherwise call `resolve_head_sha()`, and `die_msg` if undef. Wording: ``die_msg("Could not resolve HEAD as baseline commit. Run inside a git repository with at least one commit, or pass --baseline-commit=<sha> explicitly.");``.
- [ ] Remove the implicit `// ''` fallback — the value is always populated after this point (explicit or resolved). The empty-string fallback was a quiet no-op that masked the omission; failing loud is the right shape.
- [ ] Update the in-script usage banner (lines 5, 16-17, 22, 129, 136-137, 142-143) — mark `--baseline-commit` as "optional; defaults to HEAD" rather than just "Optional", and drop `--baseline-commit=...` from the example invocations at lines 22 and 142-143 so the documented best-practice example reflects the new default.

### Step 3: SKILL.md edits
- [ ] `.claude/skills/cwf-new-task/SKILL.md` lines 83-89: replace the example block. Remove `BASELINE_COMMIT=$(git rev-parse HEAD)` capture line; remove the `--baseline-commit="$BASELINE_COMMIT"` continuation in the example. Leave the surrounding prose (lines 78-82) intact.
- [ ] `.claude/skills/cwf-new-subtask/SKILL.md` lines 82-88: equivalent. The bullet list item that captures `BASELINE_COMMIT` (lines 85-87) collapses to a single sentence noting the recorded baseline is HEAD at invocation time.

### Step 4: Test
- [ ] **Unit tests** — new file `t/common-resolve-head-sha.t`. Use `CWFTest::Fixtures::create_git_repo` for the happy-path fixture. Subtests:
  1. Repo with a commit → 40-char hex SHA returned, matches `git rev-parse HEAD` ground truth.
  2. Empty repo (`git init`, no commits) → returns undef.
  3. Outside any repo (tempdir not under a git repo) → returns undef.
- [ ] **Integration test** — extend the existing `do`-load + `eval`-die-catch pattern from `t/template-copier-slug-validation.t` (or add a sibling file). Two cases:
  1. Helper invoked with no `--baseline-commit` flag, cwd inside a real repo with a commit → rendered `a-task-plan.md` has 40-char hex SHA in the `**Baseline Commit**:` field.
  2. Helper invoked with `--baseline-commit=<sha>` (explicit) → that exact value appears verbatim in the rendered file (pass-through preserved for the rare expert path).
- [ ] Run full test suite to verify no regressions: `prove -r t/`

### Step 5: Hash regen
- [ ] Run `sha256sum .cwf/scripts/command-helpers/template-copier-v2.1` to get the new digest.
- [ ] Hand-update the `template-copier-v2.1` entry in `.cwf/security/script-hashes.json` — replace the `sha256` value (do not reference by line number; the entry is keyed by name).
- [ ] Bump the top-level `last_updated` field to today's date.
- [ ] If `CWF::Common.pm` is hashed (check `.cwf/security/script-hashes.json` for an entry), repeat the regen for it. If not hashed, no action.
- [ ] Run `.cwf/scripts/cwf-manage validate` and confirm no integrity warnings for the changed files.

### Step 6: Smoke test
- [ ] `git stash` any uncommitted work; create a throwaway test task via the new shape (no `--baseline-commit` flag, no `BASELINE_COMMIT=` capture); verify no permission prompt and that the resulting `a-task-plan.md` has a 40-char SHA in the **Baseline Commit** field; `git checkout` back and delete the throwaway task via `/cwf-delete-task`.

## Code Changes

### Before (CWF/Common.pm — near `find_git_root`, line 49+)
No `resolve_head_sha` exists.

### After
Add to `@EXPORT_OK` (line 14):
```perl
our @EXPORT_OK = qw(check_perl5opt format_error parse_semver version_cmp find_git_root resolve_head_sha generate_slug);
```

New subroutine:
```perl
sub resolve_head_sha {
    my $sha = `git rev-parse HEAD 2>/dev/null`;
    chomp $sha;
    return $sha =~ /^[0-9a-f]{40}$/ ? $sha : undef;
}
```

### Before (template-copier-v2.1 — line 42 import + line 399 call site)
```perl
use CWF::Common qw(generate_slug);
...
$vars{baselineCommit} = $params->{baseline_commit} // '';
```

### After
```perl
use CWF::Common qw(generate_slug resolve_head_sha);
...
if (defined $params->{baseline_commit} && length $params->{baseline_commit}) {
    $vars{baselineCommit} = $params->{baseline_commit};
} else {
    my $sha = resolve_head_sha();
    die_msg("Could not resolve HEAD as baseline commit. Run inside a git repository with at least one commit, or pass --baseline-commit=<sha> explicitly.")
        unless defined $sha;
    $vars{baselineCommit} = $sha;
}
```

(No validation of an explicit SHA — keep pass-through behaviour identical to current code. The 40-char check only gates the resolver's own output, where we control the source.)

### Before (cwf-new-task/SKILL.md § 3, lines 83-89)
```bash
BASELINE_COMMIT=$(git rev-parse HEAD)
.cwf/scripts/command-helpers/task-workflow create \
  --task-type="{type}" --destination="{task-dir}" \
  --task-num="{num}" --description="{description}" \
  --baseline-commit="$BASELINE_COMMIT"
```

### After
```bash
.cwf/scripts/command-helpers/task-workflow create \
  --task-type="{type}" --destination="{task-dir}" \
  --task-num="{num}" --description="{description}"
```

(cwf-new-subtask: equivalent collapse of lines 85-88.)

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

All success criteria in a-task-plan.md must hold:
- No `git rev-parse HEAD` matches in either SKILL.md after the edits
- Test cases for all three shapes pass
- Script hash regenerated and `cwf-manage validate` clean
- End-to-end smoke test creates a task with no permission prompt and a populated baseline SHA

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 142
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
