# fix install allowlist and hook enablement - Implementation Execution
**Task**: 126 (bugfix)

## Task Reference
- **Task ID**: internal-126
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/126-fix-install-allowlist-and-hook-enablement
- **Template Version**: 2.1

## Goal
Execute d-implementation-plan.md: ship `cwf-claude-settings-merge`, register it in the integrity manifest, and wire it into `/cwf-init` so a fresh install produces a `.claude/settings.json` with the right `Bash(...)` allowlist entries and CWF Stop hooks.

## Actual Results

### Step 1: Setup
- **Planned**: clean tree, baseline tests green.
- **Actual**: Branch `bugfix/126-fix-install-allowlist-and-hook-enablement`, tree clean apart from untracked f/g/j wf files. Baseline `prove t/validate-security-coverage.t` PASS; full `prove -r t/` = 29 files / 271 tests, all PASS.

### Step 2: Helper alongside test
- **Planned**: write helper + test, chmod 0500, prove green.
- **Actual**: Wrote `.cwf/scripts/command-helpers/cwf-claude-settings-merge` (~150 lines). Wrote `t/cwf-claude-settings-merge.t` with 9 subtests (TC-U1 through TC-U6 incl. all four U5 sub-cases). `chmod 0500`. First prove run failed at parse time — `qr/.../` regexes containing forward slashes inside `\Q...\E` were terminating the regex at the first `/`. Fixed by switching to `qr{...}` delimiters in 5 places. Re-run: PASS, 9 subtests.
- **Deviations**: regex-delimiter fix not in plan; trivial.

### Step 3: Register helper in integrity manifest
- **Planned**: compute sha256, add manifest entry under `scripts`, bump `last_updated`.
- **Actual**: `sha256sum` → `2806a6fbf60501465b72d12018231a7e3dc7c610964308796a5a1438a346f0aa`. Added entry alphabetically between `cwf-checkpoint-commit` and `cwf-find-task-numbering-structure` (initial insertion was misplaced after `context-manager`; corrected). Bumped `last_updated` to `2026-05-05`. `prove t/validate-security-coverage.t` PASS (TC-C1 = 23, was 22). `cwf-manage validate` → `[CWF] validate: OK`.

### Step 4: Wire into /cwf-init
- **Planned**: insert Step 6d before Step 7 with helper invocation + abort-on-error semantics.
- **Actual**: Inserted Step 6d into `.claude/skills/cwf-init/SKILL.md`, mirroring Step 1a's failure-handling shape. Added Success Criteria checkbox. WARN/ERROR distinction explicit per d-impl: `[CWF] WARN:` tolerated, `[CWF] ERROR:` aborts.

### Step 5: Smoke-verify on fixture
- **Planned**: build sandbox manifest with one of each entry type, run helper, re-run for idempotency.
- **Actual**: Built `/tmp/task-126/sandbox` with stub `cwf-manage`, `command-helpers/ahelper`, `hooks/stop-test`. First run: `added 3 allowlist entries, 1 hook entries`. Output JSON contains the three allow entries (helper as `:*`, cwf-manage as `:*`, hook as exact, no `:*`) and one Stop hook in `hooks.Stop[0].hooks[]` with `timeout: 5`. Second run: `added 0 allowlist entries, 0 hook entries` (idempotent). Dry-run against this repo (TC-I3): output contains both real CWF hooks and the cwf-manage allowlist entry.

### Step 6: Commit
- See checkpoint commit below.

## Files Changed
- **NEW** `.cwf/scripts/command-helpers/cwf-claude-settings-merge` (chmod 0500)
- **NEW** `t/cwf-claude-settings-merge.t`
- **MODIFY** `.cwf/security/script-hashes.json` (one new `scripts.cwf-claude-settings-merge` entry; `last_updated` bumped)
- **MODIFY** `.claude/skills/cwf-init/SKILL.md` (new Step 6d + Success Criteria checkbox)

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md addressed (validation completes in g-phase)
- [x] All design guidance in c-design-plan.md followed (KD1–KD11)
- [x] No planned work deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: findings

Now let me check if there are issues with how the settings directory/file symlinks are handled. Let me look at the read_settings function again:

I've analyzed the changeset thoroughly. Let me compile my findings:

## Analysis

**Threat Category (a) - Bash injection**: The script does NOT construct or invoke shell commands via `system()`, backticks, or interpolated strings. All file operations use Perl functions, and JSON data flows only to JSON encoding (lines 204-205), not to command construction. SAFE.

**Threat Category (b) - Perl helpers consuming git/user output without `-z`**: The script does NOT invoke git commands or parse git output. It reads local JSON manifest file (line 46) and parses it with JSON::PP (line 50). No newline-splitting of untrusted input. SAFE.

**Threat Category (c) - Prompt injection via user-supplied strings**: The script takes only a `--dry-run` flag from command-line args (lines 31-37), which is validated by exact-match comparison (line 32). The actual data (paths, JSON content) flows from the manifest and settings files, not from user input via ARGV. SAFE.

**Threat Category (d) - Unsafe environment-variable handling**: The script does NOT reference any environment variables. All paths are hardcoded: `'.cwf/security/script-hashes.json'` (line 40), `'.claude'` (line 41), `'$settings_dir/settings.json'` (line 42). SAFE.

**Threat Category (e) - Pattern-based risks**: There are two patterns to audit:

1. **Line 69 - Path validation via regex**: The check `$path !~ m{^\.cwf/scripts/} || $path =~ m{(^|/)\.\.(/|$)}` validates paths against a hardcoded prefix and rejects parent-directory traversal. This is safe here because the `$path` values come only from JSON manifest entries read from a tracked file (`.cwf/security/script-hashes.json`) under CWF control, not from user input or environment. The pattern is conservative (rejects anything not starting with `.cwf/scripts/` and anything containing `..`), but safe here because the manifest is not user-editable at runtime. SAFE WITH NOTE.

2. **Line 188 - Rename with interpolated path**: The code constructs `"$tmp"` and `$settings_path` for `rename()`. The `$tmp` object stringifies to a safe temp file path (created by File::Temp with a secure TEMPLATE at line 183), and `$settings_path` is a hardcoded string (`'.claude/settings.json'`). The rename is safe here. SAFE.

**Shebang and UTF-8 handling**: The script uses `#!/usr/bin/env perl` (line 1) and declares `use utf8;` (line 16). However, per the security-review.md threat model § "Perl helpers consuming git or user output without `-z`", the established convention in CWF is to use `#!/usr/bin/perl -CDSL` (as seen in `.cwf/scripts/cwf-manage:1`) to enable UTF8 locale handling at the interpreter level. This script declares `use utf8;` in source but does NOT enable the `-CDSL` flag at invocation. This is a pattern mismatch but not a vulnerability in isolation — the script reads JSON files (which JSON::PP handles correctly) and does not parse line-based git output. However, it deviates from the established CWF Perl convention.

findings:

1. **Shebang deviation from CWF Perl convention (low risk but maintainability concern)**: Line 1 uses `#!/usr/bin/env perl` instead of the CWF convention `#!/usr/bin/perl -CDSL` established in `.cwf/scripts/cwf-manage:1`. While this script does not parse line-based git output and is safe in isolation, the deviation creates a pattern inconsistency. Future maintainers might copy this pattern into a context where the invariant (no git line-splitting) does not hold. Recommendation: Change line 1 to `#!/usr/bin/perl -CDSL` to match the CWF standard and eliminate the footgun. This is safe here because the `-CDSL` flag is benign in all Perl contexts; audit future uses where a developer copies this helper's shebang pattern into a git-parsing context.

### Disposition
**Accept-and-record** (false positive). The d-implementation-plan explicitly chose `#!/usr/bin/env perl` because `-CDSL` is reserved for git-path-handling scripts (per `docs/conventions/perl-git-paths.md`). All other `.cwf/scripts/command-helpers/` files use `#!/usr/bin/env perl`; only `cwf-manage` and the small number of helpers that read git output use `-CDSL`. Adopting the agent's recommendation would break the existing convention in the opposite direction. No code change.

## Lessons Learned
*To be captured during retrospective*
