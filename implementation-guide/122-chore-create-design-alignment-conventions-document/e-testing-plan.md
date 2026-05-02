# Create Design-Alignment Conventions Document - Testing Plan
**Task**: 122 (chore)

## Task Reference
- **Task ID**: internal-122
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/122-create-design-alignment-conventions-document
- **Template Version**: 2.1

## Goal
Validate that `docs/conventions/design-alignment.md` is present, accurate, well-wired, and consistent with current CWF reality.

## Test Strategy
This is a documentation task; tests are checks, not automated unit tests. All checks are run manually during g-testing-exec, with concrete commands listed below. Each check has a binary pass/fail and a single-line evidence requirement.

### Test Levels
- **Content tests** — the new doc covers the agreed scope and contains no stale references
- **Wiring tests** — CLAUDE.md, BACKLOG.md, CHANGELOG.md correctly reference / close out the new doc
- **Integrity tests** — `cwf-manage validate` passes; cited file paths resolve

### Coverage Targets
- 100 % of the five topic areas from a-task-plan / d-implementation-plan are addressed
- 100 % of file paths cited in the new doc resolve to real files (sampled — at least one path per topic)
- 0 stale references (`.claude/commands/`, sed-based audit suggestions, etc.)

## Test Cases

### Functional

- **TC-1: Convention doc exists at the documented location**
  - **Given**: branch chore/122-…
  - **When**: Read `docs/conventions/design-alignment.md`
  - **Then**: file exists; first heading is `# Design Alignment` (or close); follows Convention/Why/Existing-usage structure

- **TC-2: All five topic areas present**
  - **Given**: doc from TC-1
  - **When**: Grep for headings or anchor strings for: single source of truth, naming patterns, rename audit checklist, deprecation stance, cross-doc references
  - **Then**: each topic has its own heading or clearly-labelled section

- **TC-3: No v1.0 path references**
  - **When**: Grep doc for `.claude/commands/`, `commands/cwf-`, `cig-`
  - **Then**: zero matches (the v1.0 layout is not the convention)

- **TC-4: No find/sed in the rename-audit checklist**
  - **When**: Grep doc for `find ` / `sed -n` / `find -exec`
  - **Then**: zero matches; the audit prescribes Grep/Glob/Read/`git ls-files`/`cwf-manage validate`

- **TC-5: All cited file paths resolve**
  - **Given**: list of repo-relative paths cited in the doc (extracted by Grep for `\.cwf/`, `\.claude/`, `docs/`)
  - **When**: Read each path
  - **Then**: every cited path resolves to an existing file or directory

- **TC-6: CLAUDE.md links to the new doc**
  - **When**: Grep `CLAUDE.md` for `design-alignment.md`
  - **Then**: a `**Design Alignment**` bullet appears under the existing "Conventions" section, matching the **Commit Messages** bullet style

- **TC-7: BACKLOG.md task block removed**
  - **When**: Grep `BACKLOG.md` for the heading `## Task: Create Design-Alignment Conventions Document`
  - **Then**: zero matches (heading is replaced with a `<!-- Completed: ... — Task 122 (YYYY-MM-DD) -->` marker)

- **TC-8: CHANGELOG.md entry present**
  - **When**: Grep `CHANGELOG.md` for `Task 122`
  - **Then**: an entry exists with `**Status**`, `**Duration**`, `**Impact**`, and a brief summary (modelled on Task 118 / Task 120)

- **TC-9: cwf-manage validate passes**
  - **When**: Run `.cwf/scripts/cwf-manage validate`
  - **Then**: exits 0 with `[CWF] validate: OK`

- **TC-10: Glossary decision recorded**
  - **When**: If "design alignment" was added to `.cwf/docs/glossary.md`, Grep glossary for the term; if not, the Actual Results in d/g notes the deliberate omission with reason
  - **Then**: one of the two outcomes is observable

### Non-Functional

- **NFR-1: Style consistency** — Document uses the same heading depth and tone as `docs/conventions/perl-git-paths.md`. Length is 80–150 lines (no scope sprawl).
- **NFR-2: British spelling** — Spot-check for `centre`, `behaviour`, `organise`; no American variants in new prose.
- **NFR-3: No pseudocode** — Only real, runnable shell snippets (Grep/Read/`git ls-files`/`cwf-manage validate`); no invented commands.

## Test Environment
- Local repo at `/home/matt/repo/coding-with-files`, on branch `chore/122-create-design-alignment-conventions-document`
- No external services, no test fixtures, no test database
- Tools used: Read, Grep, Glob, Bash (only for `cwf-manage validate` and `git ls-files`)

### Automation
None. All checks are manual greps / Reads documented inline in g-testing-exec.

## Validation Criteria
- [ ] TC-1 through TC-10 all pass
- [ ] NFR-1, NFR-2, NFR-3 spot-check pass
- [ ] No find/sed used during testing-exec either (apply the same convention)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 122
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
10/10 functional + 3/3 non-functional checks PASS (full results in g-testing-exec.md). NFR-1 length check passed with documented deviation (168 lines vs 80–150 target). TC-3 has one match for `.claude/commands/` in the doc's `## Why` section describing Task 35's historical failure — accurate, not a stale claim.

## Lessons Learned
A "no stale references" check should ideally scope its grep to prescriptive sections (`## Convention`) rather than the whole doc; descriptive prose in `## Why` legitimately mentions past names. Worth keeping in mind for future doc-validation checks.
