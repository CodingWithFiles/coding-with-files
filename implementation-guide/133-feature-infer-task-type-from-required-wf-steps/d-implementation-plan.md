# Infer task type from required wf steps - Implementation Plan
**Task**: 133 (feature)

## Task Reference
- **Task ID**: internal-133
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/133-infer-task-type-from-required-wf-steps
- **Template Version**: 2.1

## Goal
Implement the design: a rubric doc under `.cwf/docs/skills/`, two SKILL.md edits, and a drift-detection test. No new Perl helpers; no changes to `template-copier-v2.1`.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary Changes
- **New** `.cwf/docs/skills/task-type-inference.md` — the rubric doc. Sections per design: step semantics, always-required steps, discriminating questions (b/c/h/i), canonical-step-set table (type → letters + `(b,c,h,i)` tuple), resolution algorithm (symmetric difference, exact-match-silent, otherwise prompt), ambiguity-prompt example, three-step "adding a new task type" procedure.
- **Modify** `.claude/skills/cwf-new-task/SKILL.md` — replace the existing `**Parse arguments**` block with the flexible-arity block from the design (Skill Modification Interface). Add a "Type Inference" subsection that points at the rubric doc by hard-coded path. Do not duplicate rubric content. Update the **Examples** section to include a 2-arg form invocation.
- **Modify** `.claude/skills/cwf-new-subtask/SKILL.md` — same edits as `cwf-new-task`, scoped to the subtask argument layout (`<parent-path> <num> [<type>] "<description>"`). The disambiguation rule is unchanged in shape; only the position of the inferred token shifts.

### Supporting Changes
- **New** `t/task-type-inference-rubric.t` — drift-detection test. Asserts:
  1. `.cwf/docs/skills/task-type-inference.md` exists and is readable.
  2. The file contains the required section headings (`# Task Type Inference`, `## Step Semantics`, `## Discriminating Questions`, `## Canonical Step Sets`, `## Resolution Algorithm`, `## Adding A New Task Type`).
  3. The canonical-step-set table parses cleanly (one row per supported type) and **matches the actual step-letter set discovered from `.cwf/templates/<type>/*.template`** for each type listed in `cwf-project.json:supported-task-types`. Parser contract: split each table row on `|`, trim whitespace from each cell, split the step-letters cell on `,`, trim each letter, drop empties, sort. Compare to the sorted set of phase letters extracted by globbing `.cwf/templates/<type>/*.template` and matching the filename against `/^([a-j])-/`. The comparison is order-independent, whitespace-tolerant, and case-sensitive (lowercase).
  4. Neither `.claude/skills/cwf-new-task/SKILL.md` nor `.claude/skills/cwf-new-subtask/SKILL.md` inline the canonical-step-set table prose (grep negative — search for the string `(b,c,h,i)` and for any line beginning with `| feature` etc.).
  5. Both SKILL.md files contain the literal rubric path `.cwf/docs/skills/task-type-inference.md` (grep positive).
- **Out of scope for this t/ test**: runtime-only failure modes (rubric file missing at skill invocation, malformed LLM step set, degenerate inference at distance ≥3). These are LLM-runtime behaviours, not static-file invariants. They are covered as smoke-test cases in `e-testing-plan.md` instead.
- No changes to `template-copier-v2.1`, `task-workflow`, `cwf-project.json`, or any existing template. **Note**: this implements design Decision 3, which relaxes the literal wording of requirements FR6 ("read from filenames at runtime") to "encoded in the rubric doc, manually synced — drift detected by the t/ test". The requirement's *intent* (no skill code changes when types are added) is preserved.

## Implementation Steps

### Step 1: Patterns review (no code changes)
- [ ] Re-read `.cwf/docs/skills/workflow-preamble.md`, `.cwf/docs/skills/checkpoint-commit.md`, `.cwf/docs/skills/plan-review.md` to align the rubric doc's tone, length, and heading conventions.
- [ ] Re-read `t/markdownparser.t` and `t/options.t` for the Perl test idioms used in this repo (Test::More, `use lib` for `.cwf/lib`, `subtest` blocks).

### Step 2: Write the rubric doc (test-after — pattern is documentation, not code)
- [ ] Create `.cwf/docs/skills/task-type-inference.md` following the schema in `c-design-plan.md § Rubric Doc Interface`.
- [ ] Include the canonical-step-set table in markdown format with one row per supported type. Each row lists: `Type | (b,c,h,i) | Step letters`.
- [ ] Include the ambiguity-prompt example verbatim from `c-design-plan.md § Ambiguity Prompt Format`.
- [ ] Document the three-step "adding a new task type" procedure (templates dir, cwf-project.json entry, rubric row).

### Step 3: Write the drift-detection test (between Steps 2 and 4)
- [ ] Create `t/task-type-inference-rubric.t` per the supporting-changes spec above.
- [ ] Run order matters: this step **must** run after Step 2 (so assertions 1–3 can pass) and before Step 4 (so assertions 4–5 fail initially, proving the test detects the absent SKILL.md edits). Expected `prove t/task-type-inference-rubric.t` output: assertions 1, 2, 3 pass; 4 and 5 fail with messages identifying which SKILL.md lacks the rubric path.
- [ ] Document this expected-initial-failure pattern in a comment at the top of the test file so future readers don't mistake the red bar for a regression mid-implementation.

### Step 4: Modify `cwf-new-task/SKILL.md`
- [ ] Replace the `Parse arguments` section with the flexible-arity block (per design).
- [ ] Add a `Type Inference` subsection containing exactly: a single sentence describing the 2-arg trigger condition, a single sentence pointing to the rubric path, and the four-step inference procedure (read rubric → infer S → compute distances → pick or prompt). No rubric prose inlined.
- [ ] Add one 2-arg example to the `Examples` block.
- [ ] Verify `t/task-type-inference-rubric.t` assertion 5 (rubric path present in this file) now passes.

### Step 5: Modify `cwf-new-subtask/SKILL.md`
- [ ] Mirror the changes from Step 4. The disambiguation rule applies to the third positional token (after `<parent-path>` and `<num>`).
- [ ] Verify `t/task-type-inference-rubric.t` passes fully.

### Step 6: Refactor pass
- [ ] Diff the inference subsections of the two SKILL.md files. Anything beyond cosmetic difference (subtask vs top-level argument layout) is duplication — extract to the rubric doc.
- [ ] Confirm the SKILL.md inference prose explicitly states the step-letter separator (`,`) and the distance formula (symmetric difference size) used by the test parser. If either drifts, the rubric, SKILL.md, and test parser get out of sync silently.
- [ ] Confirm no helper scripts, no Perl, no env vars introduced. `git diff` should show three modified/created markdown files plus one new t/ test, nothing else.

### Step 7: Refresh script hashes if needed
- [ ] No `.cwf/scripts/command-helpers/` changes are planned, so `.cwf/security/script-hashes.json` should not need an update. Confirm via `cwf-manage validate` after the f-implementation-exec checkpoint.

### Step 8: End-to-end smoke (manual, deferred to g-testing-exec)
- [ ] Deferred. Listed in `e-testing-plan` as the smoke-test matrix. Not part of this step's check-off.

## Code Changes
No code (Perl/Bash) is touched. The "before/after" is markdown-only:

### Before (`.claude/skills/cwf-new-task/SKILL.md` argument-parsing section, current)
```
**Parse arguments**: `<num> <type> "description"`
- num: Task number in decimal notation (1, 1.1, 1.1.1, etc.)
- type: feature|bugfix|hotfix|chore|discovery
- description: Brief task description (will be slugified)
```

### After
```
**Parse arguments**: `<num> [<type>] "description"`
- num: Task number in decimal notation (1, 1.1, 1.1.1, etc.)
- type: feature|bugfix|hotfix|chore|discovery (optional — see Type Inference)
- description: Brief task description (will be slugified)

**Disambiguation rule**: If a token between <num> and the description matches a value
in cwf-project.json:supported-task-types, treat it as <type>. Otherwise <type> is
omitted and Type Inference runs. To use a bare type-name as the description,
provide <type> explicitly.

**Type Inference**: When <type> is omitted, see
`.cwf/docs/skills/task-type-inference.md`. The skill: (1) reads that rubric;
(2) infers the required step set S from the description; (3) computes |S Δ C_T|
for each candidate type T using the rubric's canonical-step-set table;
(4) uses the type with distance 0 if exactly one exists, otherwise prompts the
user with the top candidates and the differing step letters.
```

The `cwf-new-subtask/SKILL.md` change is the same shape, scoped to its parameter layout.

## Test Coverage
**See e-testing-plan.md for complete test plan**

In summary, this task's testable surface is:
- One Perl test (`t/task-type-inference-rubric.t`) covering structural integrity and rubric-vs-templates drift.
- Manual smoke tests covering each AC1–AC8 (run in g-testing-exec; matrix defined in e-testing-plan).

There are no unit-testable Perl functions added because the design deliberately avoids new helper scripts.

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

For this step, "Finished" means:
- [ ] Rubric doc exists at the design-specified path with all required sections.
- [ ] Both SKILL.md files reference the rubric path; neither duplicates rubric prose.
- [ ] `t/task-type-inference-rubric.t` passes.
- [ ] `prove t/` (full suite) shows no regressions.
- [ ] `cwf-manage validate` clean.
- [ ] `git diff` shows only the four expected files (rubric doc, two SKILL.md files, one t/ test).

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

If the rubric proves harder to write than expected (e.g., the discriminating questions need worked examples to be useful), expand the rubric in-place rather than deferring. The whole point of this task is a *complete* rubric; a stub would leave AC3 (ambiguity prompting) untestable.

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
