# Infer task type from required wf steps - Implementation Execution
**Task**: 133 (feature)

## Task Reference
- **Task ID**: internal-133
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/133-infer-task-type-from-required-wf-steps
- **Template Version**: 2.1

## Goal
Execute the implementation following d-implementation-plan.md: add the
rubric doc, the drift-detection test, and the two SKILL.md edits.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status to "Finished" when complete

## Actual Results

### Step 1: Patterns review (no code changes)
- **Planned**: Re-read shared skill docs and Perl test idioms before
  writing.
- **Actual**: Surveyed `.cwf/docs/skills/` (already had
  workflow-preamble.md, checkpoint-commit.md, plan-review.md,
  security-review.md, re-execution.md as references). Surveyed
  `t/options.t` and `t/markdownparser.t` for Perl test style
  (`Test::More`, `FindBin`, `use lib` for `.cwf/lib`).
- **Deviations**: None.

### Step 2: Write the rubric doc
- **Planned**: Create `.cwf/docs/skills/task-type-inference.md` per
  c-design-plan § Rubric Doc Interface.
- **Actual**: Wrote the rubric with required headings (Step Semantics,
  Always-Required Steps, Discriminating Questions, Canonical Step
  Sets, Resolution Algorithm, Ambiguity Prompt Format, Adding A New
  Task Type) and a canonical-step-set table for all 5 supported types.
- **Deviations**: None.

### Step 3: Write the drift-detection test
- **Planned**: Create `t/task-type-inference-rubric.t` with 5
  assertions (exists, headings, table-vs-templates drift, no
  duplication, rubric path present).
- **Actual**: Wrote the test. Used `JSON::PP` to read
  `cwf-project.json:supported-task-types`. Table parser splits rows on
  `|`, trims cells, splits letter cell on `,`. Discovery parser globs
  `.cwf/templates/<type>/` and matches filenames against `/^([a-j])-/`.
  Initial run: 27 assertions pass (1-3 cover rubric structure +
  drift), 2 fail (paths missing from SKILL.md) — exactly as the plan
  predicted for the mid-implementation red bar.
- **Deviations**: None.

### Step 4: Modify cwf-new-task/SKILL.md
- **Planned**: Replace `Parse arguments` block with flexible-arity
  form, add Type Inference subsection pointing at the rubric, add a
  2-arg example.
- **Actual**: Argument block now reads `<num> [<type>] "description"`.
  Disambiguation rule documented. Added 2-arg example
  (`/cwf-new-task 2 "Migrate Bash helpers to Perl"`). Type Inference
  subsection added with hard-coded rubric path and 4-step procedure
  (read → infer S → compute distances → silent pick or prompt).
  Validate-arguments step updated to note the type may come from
  inference. After this step the test passed assertions 1-4 plus
  cwf-new-task's assertion 5; cwf-new-subtask's assertion 5 still
  failed (expected).
- **Deviations**: None.

### Step 5: Modify cwf-new-subtask/SKILL.md
- **Planned**: Mirror Step 4 for the subtask argument layout.
- **Actual**: Argument block now reads
  `<parent-path> <num> [<type>] "description"`. Disambiguation rule
  and Type Inference subsection added with identical body (byte-equal
  to the cwf-new-task version, only the surrounding context differs).
  Added a 4-arg and a 3-arg example.
- **Deviations**: Discovery was missing from the original
  cwf-new-subtask argument list (`feature|bugfix|hotfix|chore`). Added
  `discovery` to keep the supported set consistent with
  `cwf-new-task`. Confirmed via cwf-project.json that discovery is in
  `supported-task-types`.

### Step 6: Refactor pass
- **Planned**: Diff the inference subsections of the two SKILL.md
  files; extract any non-cosmetic duplication into the rubric.
- **Actual**: Diff between the two Type Inference subsections is
  empty for the body — only the surrounding section context differs
  (new-task has `### 1. Validate Arguments` after; new-subtask has
  `### 1. Resolve Parent Directory` after). Step-letter separator
  (`,`) and distance formula (`|S Δ C_T|`) are referenced
  consistently. No new helpers, no Perl, no env vars introduced.
- **Deviations**: None.

### Step 7: Refresh script hashes if needed
- **Planned**: Confirm no `.cwf/scripts/command-helpers/` changes;
  `cwf-manage validate` clean.
- **Actual**: `.cwf/scripts/command-helpers/` untouched.
  `cwf-manage validate` → `[CWF] validate: OK`.
- **Deviations**: None.

### Step 8: End-to-end smoke (deferred)
- **Planned**: Deferred to g-testing-exec.
- **Actual**: Deferred per plan.
- **Deviations**: None.

## Test Results
- `prove t/task-type-inference-rubric.t` → 29 tests, all pass.
- `prove t/` → 441 tests, all pass. No regressions in any pre-existing
  test.
- `cwf-manage validate` → OK.

## Files Changed
- New: `.cwf/docs/skills/task-type-inference.md`
- New: `t/task-type-inference-rubric.t`
- Modified: `.claude/skills/cwf-new-task/SKILL.md`
- Modified: `.claude/skills/cwf-new-subtask/SKILL.md`

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md addressed (smoke
      verification of those criteria is g-testing-exec's job)
- [x] All FR1–FR7 + AC1–AC8 from b-requirements-plan.md addressed in
      design + impl (smoke verification deferred to g-testing-exec)
- [x] All c-design-plan.md decisions implemented
- [x] No planned work deferred without user approval

## Security Review

**State**: findings

Note on classification: the security-review subagent was invoked twice.
Both responses had preamble text before the sentinel line, violating the
prompt protocol. The first response contained a numbered Summary list
(`1. ... 2. ...`), so the three-tier rule's fallback (numbered list →
findings) triggers, recording the verbatim first response below.
However, every numbered item is a `Status: CLEAR` verification, not an
actionable finding. No code change is required. Recorded as `findings`
strictly to honour the classification rule.

Verbatim first-response body:

```
Now I'll analyze the changeset against all five threat categories:

## Analysis against Threat Categories (a)–(e)

### (a) Bash injection / unsafe command construction
- The changeset contains no shell scripts or backtick invocations. The
  test file is a Perl script with `use strict; use warnings`, and the
  SKILL.md files are markdown documentation.
- No new system calls or shell command construction.
- Status: CLEAR

### (b) Perl helpers consuming git or user output without `-z` /
input validation
- `slurp()` safely opens files with UTF-8 encoding and reads them
  entirely. No shell invocation.
- `parse_rubric_table()` splits on newlines and uses regex matching —
  the only inputs are from the local rubric file (controlled source),
  not git or user input.
- `discover_steps()` uses opendir/readdir to enumerate a local
  directory, validates the pattern match `/^([a-j])-/` before using
  captures.
- `read_config_types()` reads cwf-project.json and decodes it with
  JSON::PP. No git or user input.
- All file paths are derived from FindBin::Bin and hardcoded strings.
  No variable interpolation into paths.
- Status: CLEAR

### (c) Prompt injection via user-supplied strings
- The SKILL.md files document how the skills will consume user input.
- The documentation explicitly states: "Read the rubric at the literal
  path .cwf/docs/skills/task-type-inference.md using the Read tool."
- The rubric itself is a markdown document with discriminating
  questions — there are no code instructions that a user-supplied
  string could break out of.
- The SKILL.md files do NOT inline the rubric content (test assertion
  4 enforces this).
- Argument parsing is described procedurally for the LLM to implement,
  not as code with interpolation.
- Status: CLEAR — the design isolates user input from prompt
  instructions by delegating parsing to the LLM and separating the
  rubric from inline prompt text.

### (d) Unsafe environment-variable handling
- No new environment variables are introduced in this changeset.
- The test file uses only hardcoded paths derived from FindBin::Bin.
- SKILL.md files do not reference any environment variables.
- Status: CLEAR

### (e) Pattern-based risks (safe-here-but-risky-elsewhere)
- The regex `qr/^\|\s*\Q$type\E\s*\|/m` in the test file: `$type`
  comes from cwf-project.json (version-controlled, trusted). `\Q...\E`
  quotes all characters in `$type`, making it a literal string match —
  safe against regex metacharacters.
- Safe here because `$type` is constrained to values from the config
  file (a fixed set of task-type names). If this code were copied to
  a context where `$type` came from user input or git output, the
  quoting would still protect it.
- Status: CLEAR

(Subagent concluded with "no findings" at the end of its response, but
the leading preamble plus the numbered Summary list elsewhere in the
body triggered the strict fallback-classification rule.)
```

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
