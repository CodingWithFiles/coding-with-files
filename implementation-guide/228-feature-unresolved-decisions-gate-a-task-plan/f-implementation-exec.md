# unresolved-decisions gate for a-task-plan - Implementation Execution
**Task**: 228 (feature)

## Task Reference
- **Task ID**: internal-228
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/228-unresolved-decisions-gate-a-task-plan
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan

## Implementation Steps (from d-implementation-plan.md)

Three surfaces edited (design D2), all untracked by `script-hashes.json` — no hash refresh,
no new code, no new script.

## Actual Results

### Step 1: Authority — `.cwf/docs/workflow/workflow-steps/planning.md`
- **Planned**: append to `Focus on` / `Avoid` / `Key Questions`; add the D4 definition +
  litmus + 4 worked examples block; reconcile both `Avoid` tension lines (naming ≠ choosing).
- **Actual**: added one `Focus on` bullet (name every open surface/mechanism/constraint
  decision as a question); reconciled **both** `Avoid` lines inline — "Detailed design
  decisions" and "Specific technology choices" now each carry the naming≠choosing carve-out,
  no free-standing prose (design improvements-review fix honoured); added two `Key Questions`;
  added the self-contained **"Open-decisions gate & outcome-shaped criteria"** block with the
  mechanism-named definition, litmus test, and four examples (2 ✗, 2 ✓).
- **Deviations**: none.

### Step 2: Prompt — `.cwf/templates/pool/a-task-plan.md.template`
- **Planned**: insert `## Open Decisions` after `## Constraints`; add outcome-shaped note
  under `## Success Criteria`.
- **Actual**: `## Open Decisions` section inserted between `## Constraints` and
  `## Decomposition Check` (one-line instruction + bulleted prompt + `None open —
  <justification>` escape hatch, bare "None" marked non-conformant); HTML-comment note added
  under `## Success Criteria` pointing to `planning.md`, keeping the existing "measurable
  outcome" per-criterion text.
- **Deviations**: none. Edit made in the pool only; all 5 per-type symlinks resolve to it.

### Step 3: Gate — `.claude/skills/cwf-task-plan/SKILL.md`
- **Planned**: append two `- [ ]` items to the skill's `## Success Criteria` list (design I2),
  mapping 1:1 to FR1 / FR2.
- **Actual**: two checklist items appended — "Open decisions captured …" (FR1) and "Success
  criteria are outcome-shaped …" (FR2). This is D1's sole enforcement surface. Step-6 echo
  left as-is (deliberate non-edit; authority is `planning.md`).
- **Deviations**: none.

### Step 4: Exec smoke check
- **Symlink resolve**: all 5 per-type `a-task-plan.md.template` symlinks resolve to the edited
  pool file. ✓
- **Generate-and-grep (AC1 smoke)**: `task-workflow create` of a throwaway feature task
  produced an `a-task-plan.md` with `## Open Decisions` between `## Constraints` (§52) and
  `## Decomposition Check` (§64) and the criteria note under `## Success Criteria`; throwaway
  deleted. ✓
- **Existing-plan parse**: `status-aggregator-v2.1 228` parses this task cleanly (25%). ✓
- **`cwf-manage validate`**: `[CWF] validate: OK` — no hash/permission drift; confirms none
  of the three files is hash-tracked. ✓

## Blockers Encountered

None.

## Security Review

**State**: no findings

Docs/template/skill-only change (task-plan open-decisions gate); no code, Perl, shell,
env-var, or new prompt-injection surface introduced. Zero executable surface across all five
FR4(a–e) threat categories. The posture asserted in this exec file (no new script/exec/env-var
surface, no hash-tracked file, validate clean) matches the diff.

## Best-Practice Review

**State**: no findings

Matched sources (golang, postgres, perl) are language-specific code best practices; this
Markdown-only changeset introduces none of those languages, so nothing is in scope. Genuine
"consistent" result — all sources were readable.

## Improvements Review

**State**: no findings

Three-file change reuses the existing planning-norm pattern (doc authority + template prompt +
skill gate, mirroring the why/explicit-request split across the same three files). Definition
single-sourced in `planning.md`; template and skill reference it rather than restating. No
duplicated or re-added code; `## Open Decisions` is genuinely new (no prior open-questions
section in the pool).

## Robustness Review

**State**: no findings

The one substantive risk — a structural-reader break from the inserted `## Open Decisions`
section — verified fail-safe: `status-aggregator-v2.1` reads status via marker-based
`CWF::TaskState::status_get`, not positional ordering, so a new mid-document H2 is invisible to
it. The `None open — <justification>` escape hatch defends the gate-bypass edge case.
Guidance-only enforcement (D1) is a documented correctness>mechanism trade-off, not a fragile
path.

## Misalignment Review

**State**: findings — **resolved in this phase**

Well-aligned three-surface reuse. One minor advisory: two new bare `planning.md`
cross-references (template `## Success Criteria` comment; skill checklist item) diverged from
the intra-repo backtick convention (`docs/conventions/cross-doc-references.md`:
`inline-backtick × path`). **Fixed** — both references now backticked (`` `planning.md` ``).
No other misalignment; `## Open Decisions` correctly kept distinct from `## Constraints` (D3)
and no new `plan-mechanical-check` rule added (D1, scope-clear of R13).

## Deferral Check
Before marking status=Finished, verify:
- [ ] All steps from d-implementation-plan.md executed
- [ ] All success criteria from a-task-plan.md met
- [ ] All requirements from b-requirements-plan.md addressed (if applicable)
- [ ] All design guidance in c-design-plan.md followed (if applicable)
- [ ] No planned work deferred without user approval
- [ ] If work deferred: Follow-up task created and linked

**If deferral required**: Get user approval, document rationale, create follow-up task.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
See the per-step Actual Results and five review sections above: three surfaces edited, all
reviews clean bar one misalignment finding fixed in-phase, `cwf-manage validate` OK.

## Lessons Learned
Marker-based structural readers make an added named section invisible to them, so additive
template edits are safe by construction.
