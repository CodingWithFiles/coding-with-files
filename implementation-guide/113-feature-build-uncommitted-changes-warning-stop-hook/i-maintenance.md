# Build uncommitted changes warning Stop hook - Maintenance
**Task**: 113 (feature)

## Task Reference
- **Task ID**: internal-113
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/113-build-uncommitted-changes-warning-stop-hook
- **Template Version**: 2.1

## Active Maintenance Requirements

**Scheduled maintenance**: NONE — read-only script, no state, no logs, no external dependencies beyond `git` and Perl core. Fires on Stop events; idle otherwise.

**Reactive maintenance**:
- **IF** false positives reported (hook warns when no wf files are uncommitted) → **THEN** check whether `git status --porcelain -z --untracked-files=all -- 'implementation-guide/*/[a-j]-*.md'` is matching unexpected files. Most likely cause: pathspec drift if the wf file naming convention changes.
- **IF** mojibake reappears in output (e.g. `â  ` instead of `⚠`) → **THEN** `use utf8;` may have been removed from the script, or `-CDSL` dropped from the shebang. See `docs/conventions/perl-git-paths.md`.
- **IF** hook stops firing → **THEN** check `.claude/settings.local.json` for the `hooks.Stop[0].hooks` entry; the second command object (Task 113) may have been lost during a settings edit.
- **IF** TC-8 backlog item ("Add Conflict-State Regression Test") is picked up → **THEN** the test belongs in this hook's territory; cross-reference Task 113's e-testing-plan TC-8 row.

**Deprecation trigger**: If CWF stops using `implementation-guide/*/[a-j]-*.md` for workflow files, or if Claude Code changes the Stop hook mechanism (e.g., schema change to the JSON output contract).

## Known Co-Behaviour
- Task 104's stop-stale-status-detector fires on the same Stop event. Output ordering in the system reminder is determined by the order in `hooks.Stop[0].hooks`. The two hooks are independent and can both fire on the same wf file (different failure modes).

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 113
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**
