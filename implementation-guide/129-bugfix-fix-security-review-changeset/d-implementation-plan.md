# Fix security-review changeset construction - Implementation Plan
**Task**: 129 (bugfix)

## Task Reference
- **Task ID**: internal-129
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/129-fix-security-review-changeset
- **Template Version**: 2.1

## Goal
Implement KD-1..KD-6 from c-design-plan.md: new `security-review-changeset` Perl helper using `a-task-plan.md`'s recorded baseline; template + skill changes to record that baseline; doc + exec-SKILL refactor to call the helper; one regression test file.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit explains "why".

## Files to Modify

### Primary changes (the helper and its callers)
- `.cwf/scripts/command-helpers/security-review-changeset` — **new**, Perl helper. Anchor resolution + classification + filtered diff. Permissions `0500`.
- `.cwf/docs/skills/security-review.md` — § "Pathspec coverage" rewritten as contract description. The literal `git diff $(git merge-base HEAD main) ...` line removed.
- `.claude/skills/cwf-implementation-exec/SKILL.md` — Step 8: replace `git diff $(git merge-base ...)` with helper invocation.
- `.claude/skills/cwf-testing-exec/SKILL.md` — Step 8: same.

### Baseline-recording changes
- `.cwf/templates/pool/a-task-plan.md.template` — add `**Baseline Commit**: {{baselineCommit}}` line in Task Reference. Single edit covers all task-type symlinks.
- `.cwf/scripts/command-helpers/template-copier-v2.1` — accept `--baseline-commit=<sha>`; thread into `%vars` as `baselineCommit`. Optional argument; default `""` → template renders an empty value (acceptable for synthetic / unusual flows).
- `.claude/skills/cwf-new-task/SKILL.md` — add: capture `git rev-parse HEAD` before `git checkout -b`; pass `--baseline-commit=<sha>` to the script. One-line note about base-branch verification.
- `.claude/skills/cwf-new-subtask/SKILL.md` — same change.

### Test
- `t/security-review-changeset.t` — **new**, Test::More. Synthetic git repos via `File::Temp` (pattern from `t/taskpath.t`). Test matrix per c-design-plan.md KD-6.

### Hash-tracking
- `.cwf/security/script-hashes.json` — add entry for `security-review-changeset` with `permissions: "0500"` and SHA. SHA recorded after the script is finalised; `cwf-manage validate` is the gate.

## Implementation Steps

### Step 1: Helper script — `security-review-changeset`
- [ ] Write `.cwf/scripts/command-helpers/security-review-changeset` with `#!/usr/bin/perl -CDSL`, `use strict; use warnings; use utf8;`. Standard preamble: `use FindBin; use lib "$FindBin::Bin/../../lib"; use CWF::Common qw(check_perl5opt); check_perl5opt();`. Imports: `use CWF::TaskPath qw(parse_branch resolve_num)`.
- [ ] Argument parsing: `--phase=<implementation|testing>`, `--task-num=<NUM>`, `--verbose`. Reject unknown args. If `--task-num` is provided on the CLI, validate against `^\d+(\.\d+)*$` before use; non-match → exit 1 with diagnostic (defence-in-depth against path-traversal-shaped values).
- [ ] If `--task-num` absent: get current branch via `open my $fh, '-|', 'git', 'rev-parse', '--abbrev-ref', 'HEAD'` (list-form `open`-pipe — no shell), chomp; pass to `parse_branch`. If parse fails: exit 1 with `Error: branch <branch> does not match pattern <type>/<num>-<slug>`. The SKILL already short-circuits on `main` before invoking us, so the helper does not check for `main`.
- [ ] Resolve task directory via `CWF::TaskPath::resolve_num($task_num)` (Perl module API, not shell-out). On undef return: exit 1 with `Error: task <num> not found`. Read `full_path` from the returned hashref.
- [ ] Read `<task-dir>/a-task-plan.md`. Match line against `^- \*\*Baseline Commit\*\*:\s+([0-9a-f]{40})\s*$` (allow extra whitespace after colon; SHA must be exactly 40 hex chars — CWF uses SHA-1; if CWF migrates SHAs in future this regex must update; stated as inline comment in the helper). If a line *starts* `- **Baseline Commit**:` but does not match the full pattern, emit a stderr warning `warning: Baseline Commit line found but format unexpected; falling back to merge-base` and proceed to fallback (Step 2).
- [ ] If valid SHA found: validate via `system "git", "rev-parse", "--verify", "--quiet", "${sha}^{commit}"` (list-form, stderr suppressed by `--quiet`). `$? == 0` → anchor = `$sha`. Otherwise fallback.
- [ ] If no field, format-unexpected, or rev-parse fails: invoke fallback (Step 2).
- [ ] List changed files: `open my $fh, '-|', 'git', 'diff', '--name-only', '-z', "${anchor}..HEAD"` (list-form), read all, `\0`-split.
- [ ] Apply CWF-internal-dir rule (KD-2 rule 1) — hardcoded prefix list: `.cwf/scripts/`, `.cwf/lib/`, `.cwf/docs/skills/`, `.cwf/templates/`, `.claude/scripts/`, `.claude/skills/`, `.claude/hooks/`, `.claude/rules/`, plus exact-path matches: `.claude/settings.json`, `.claude/settings.local.json`, `implementation-guide/cwf-project.json`.
- [ ] For paths not in (1): apply shebang sniff (KD-2 rule 2). For each path:
      - Skip if `! -e $path` (deleted in diff) or `-l $path` (symlink — avoids following arbitrary targets) or `! -f $path` (skips FIFOs, sockets, devices — DoS guard against opening `/dev/zero`-shaped diff entries).
      - `open my $fh, '<:raw', $path` (list-form, no shell). `sysread $fh, $buf, 128`. First line = `$buf` truncated at first `\n` or `\r`.
      - If begins `#!`, parse interpreter:
        - `#!/usr/bin/env <name>...` → interpreter = `<name>` (substring after `env`, trim leading whitespace, take up to next whitespace).
        - `#!<path>...` → interpreter = basename of `<path>` (path's last component after `/`; do not strip version digits).
      - Match anchored regex `^(?:perl|bash|sh|ksh|zsh|fish|python\d?|ruby|node|deno|php|lua|pwsh|powershell)$` — **anchored at both ends**, future maintainers extending it MUST preserve `^…$`. Match → include.
- [ ] If filtered list empty: print empty stdout, stderr `reviewed 0 files, 0 lines, anchor=<sha7>`, exit 0.
- [ ] Otherwise emit diff: `open my $fh, '-|', 'git', 'diff', "${anchor}..HEAD", '--', @filtered_paths` (list-form; `@filtered_paths` is a Perl array, never interpolated into a shell string). Slurp `$fh` to stdout. Count lines for stderr summary.

### Step 2: Helper script — fallback path (in-flight tasks)
- [ ] If no baseline field or invalid SHA: resolve trunk:
      1. `eval { CWF::Versioning::read_config() }` — graceful failure if `cwf-project.json` is missing or malformed (synthetic-test scenarios). On success, read `$cfg->{trunk}` (top-level optional field; absent → next step).
      2. If absent: `open my $fh, '-|', 'git', 'symbolic-ref', '--quiet', 'refs/remotes/origin/HEAD'`; on success, capture and strip `refs/remotes/origin/` prefix.
      3. If that also fails: hardcoded `main`.
- [ ] Validate the resolved name via `system "git", "check-ref-format", "--branch", $trunk` (list-form, stderr suppressed). `$? == 0` → name is a valid git branch reference. Non-zero → exit 1 with `Error: trunk name <name> is not a valid git branch reference`. (`git check-ref-format` correctly rejects `..`, `.`, leading slash, `@{`, `\`, control chars, etc. — better than a hand-rolled character regex.)
- [ ] Anchor = `git merge-base HEAD <trunk>` (list-form `open`-pipe, capture). If merge-base fails (e.g. trunk doesn't exist locally) → exit 1 with diagnostic.

### Step 3: Template + template-copier change
- [ ] Edit `.cwf/templates/pool/a-task-plan.md.template`: insert `- **Baseline Commit**: {{baselineCommit}}` between `- **Branch**: {{branchName}}` and `- **Template Version**: 2.1`.
- [ ] Edit `template-copier-v2.1` argument parser (around line 65): accept `--baseline-commit=(.+)` → `$params{baseline_commit} = $1`. Required-list (line 82) does NOT include it (optional).
- [ ] Edit `vars` builder (around line 410): `$vars{baselineCommit} = $params->{baseline_commit} // '';`.
- [ ] Edit usage docstring + help text accordingly.

### Step 4: Skill changes — cwf-new-task and cwf-new-subtask
- [ ] Edit `.claude/skills/cwf-new-task/SKILL.md` Step 3 (Copy Template Files): insert capture step before the `task-workflow create` invocation:
      ```bash
      BASELINE_COMMIT=$(git rev-parse HEAD)
      ```
      and append `--baseline-commit="$BASELINE_COMMIT"` to the `task-workflow create` invocation.
- [ ] Add a one-line user note at the top of the workflow: "verify you are on the intended base branch before running — the baseline commit is whatever HEAD is at this moment."
- [ ] Edit `.claude/skills/cwf-new-subtask/SKILL.md` Step 3 (Validate and Create Subtask): same pattern.

### Step 5: Doc + exec-SKILL refactor (SSOT)
- [ ] Edit `.cwf/docs/skills/security-review.md` § "Pathspec coverage": replace literal `git diff $(git merge-base HEAD main) ...` block with a contract description naming the helper, the CWF-internal directories, and the shebang-classification rule. Keep the maintainer note about updating coverage when adding security-relevant trees, but redirect maintainers to the helper rather than the doc.
- [ ] Edit `.claude/skills/cwf-implementation-exec/SKILL.md` Step 8 line 51: replace `Construct changeset: git diff $(git merge-base HEAD main)..HEAD -- <pathspec from § "Pathspec coverage">.` with `Construct changeset: capture stdout of .cwf/scripts/command-helpers/security-review-changeset --phase=implementation.`
- [ ] Edit `.claude/skills/cwf-testing-exec/SKILL.md` Step 8 line 46: same; `--phase=testing`.

### Step 6: Hash-tracking
- [ ] `chmod 0500 .cwf/scripts/command-helpers/security-review-changeset`.
- [ ] Compute `sha256sum .cwf/scripts/command-helpers/security-review-changeset` (hex-only output via `cut -d' ' -f1` if needed). Add entry to `.cwf/security/script-hashes.json` under the **top-level `scripts`** section (the JSON has `data`, `lib`, `scripts` top-level keys — there is no `command-helpers` subsection; entry sits alongside `checkpoints-branch-manager`, `context-manager`, etc.):
      ```json
      "security-review-changeset" : {
        "path" : ".cwf/scripts/command-helpers/security-review-changeset",
        "permissions" : "0500",
        "sha256" : "<computed-sha256>"
      }
      ```
- [ ] Run `.cwf/scripts/cwf-manage validate` to confirm clean.

### Step 7: Test
- [ ] Write `t/security-review-changeset.t` following the existing `t/*.t` convention:
      ```perl
      use strict;
      use warnings;
      use Test::More;
      use File::Temp qw(tempdir);
      use FindBin;
      use lib "$FindBin::Bin/../.cwf/lib";
      use lib "$FindBin::Bin/lib";
      use CWFTest::Fixtures qw(create_git_repo create_task_dir);   # confirm exact exported names while writing the test
      ```
      Pattern: each test creates a synthetic repo via `tempdir(CLEANUP => 1)` + `create_git_repo`, creates a synthetic task dir via `create_task_dir`, runs the helper as a subprocess (`open '-|', $script_path, @args`), asserts on captured stdout/stderr/exit code.
- [ ] Test cases (6 total, following c-design-plan.md KD-6 minus the auto-detection case which is exercised implicitly by case 3):
      1. **Extensionless shebang (CWF-internal)**: `.cwf/scripts/cwf-foo` with `#!/usr/bin/perl` → assert included.
      2. **Consumer-stack file**: `app/main.py` with `#!/usr/bin/env python3` outside CWF dirs → assert included via shebang sniff (validates bug-report issue 2 fix).
      3. **Unmerged-predecessor isolation**: synthesize repo with `main` → branch `task1` (commit) → branch `task2` from main, create task2's dir with `a-task-plan.md` containing the recorded baseline SHA = main tip → make a single change on task2 → assert diff covers task2's change only, even with task1's unmerged commit reachable.
      4. **Negative — binary blob**: write a binary file under `tools/` (no shebang) → assert excluded.
      5. **Negative — plain text**: `notes.txt` outside CWF dirs → assert excluded.
      6. **Trunk validation**: in-flight task with no baseline field, `cwf-project.json` with `"trunk": ".."` → assert helper exits 1 with diagnostic (validates `git check-ref-format` guard).
- [ ] Run `prove t/security-review-changeset.t`. All assertions pass.
- [ ] Run full `prove t/` to confirm no regressions.

### Step 8: Validation
- [ ] `.cwf/scripts/cwf-manage validate` clean.
- [ ] Manual smoke test: on this branch, `.cwf/scripts/command-helpers/security-review-changeset --phase=testing` runs → emits a non-empty changeset (covering this task's own changes), bounded by the merge-base fallback (this task's `a-task-plan.md` has no baseline field; that's expected — we exercise the fallback path).

## Test Coverage
**See e-testing-plan.md for complete test plan.**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results.**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

If any deferred work is identified during implementation, raise it explicitly with the user before marking complete.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Steps 1-6 + 8 executed in f-phase; Step 7 (test) executed in g-phase per CWF v2.1 phase split. One plan deviation: all `die` calls in the helper converted to `warn …; exit 1;` after smoke test showed Perl's default `die` exit 255 violated the spec'd exit-1 contract. Two SHAs updated (helper + template-copier-v2.1) rather than one — both files changed.

## Lessons Learned
Perl's `die` exits 255, not the spec'd `1`. Helpers throughout `.cwf/scripts/command-helpers/` already follow the `warn …; exit 1;` convention (see `cwf-checkpoint-commit:14-15`); this should be the default for new helpers from the start. Documented in retrospective as a recommendation; no code change to old helpers needed.
