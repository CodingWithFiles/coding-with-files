# Permission-drift repair and agent guidance - Implementation Plan
**Task**: 183 (feature)

## Task Reference
- **Task ID**: internal-183
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/183-permission-drift-repair-and-agent-guidance
- **Template Version**: 2.1

## Goal
Implement the design (D1–D8): one canonical fix-on-sight section + two cross-reference pointers,
plus the (already-clean) repair-sweep confirmation and the backlog retire. Docs-only, no code.

## Workflow
Patterns first → minimal doc edits → verify with grep + `validate` → commit explains "why"

## Files to Modify
### Primary Changes
- `.cwf/docs/conventions/hash-updates.md` (D1–D4) — add a new `## Fix permission drift on sight`
  section after the existing "Recorded permissions are a ceiling" section: the rule
  (clamp via `cwf-manage fix-security`), the perm-vs-sha256 boundary (cross-ref "what NOT to
  build"), the working-tree-only persistence note (cross-ref "recorded permissions are a
  ceiling"), and ≥1 role-phrased negative example. Quote the command byte-identically.
- `.cwf/docs/skills/checkpoint-commit.md` (D5) — add a one-line fix-on-sight note reachable on
  **both** paths: in the "Script (primary method)" block near `:16` (the helper-runs-`validate`
  line) and at the "Manual Procedure" validate step (`:46-50`, replacing/augmenting the generic
  "fix them before proceeding"). Each cross-references the new hash-updates section.
- `CLAUDE.md` (D6) — append one bullet to the `## Conventions` → "Hash Updates" entry (`:83-87`)
  pointing at the fix-on-sight rule.

### Supporting Changes
- **None to `.cwf/security/script-hashes.json`** — all three files above are confirmed
  non-hash-tracked (design Verified Assumptions). This is the stated no-refresh decision.
- `BACKLOG.md` / `CHANGELOG.md` (D7/FR5) — Task-173 item retired via `backlog-manager retire`,
  performed in the **retrospective** phase (j), not here (it pairs with the CHANGELOG task entry).

## Implementation Steps
### Step 1: Repair-sweep confirmation (FR1/AC1)
- [ ] Run `cwf-manage fix-security --dry-run`; confirm it **exits 0** with `0` files to repair
  (guards against a coexisting sha256 `UNFIXABLE` reading as success). Record output in f-exec.
- [ ] Run `cwf-manage validate`; confirm no permission violation. (Expected clean — the
  planning-phase clamp already cleared the residual.)

### Step 2: Canonical section in `hash-updates.md` (FR2/FR3, D1–D4)
- [ ] Add `## Fix permission drift on sight` after the "Recorded permissions are a ceiling"
  section. Content:
  - the rule: when `validate`/a checkpoint surfaces a **permission** violation, repair it
    immediately with `cwf-manage fix-security` — quoted byte-identically to the command named in
    `validate`'s `Fix:` line (`CWF/Validate/Security.pm`: "…Clear excess bits or run:
    cwf-manage fix-security") — do not defer it as "out of scope" / a "separate backlog item";
  - the boundary: clamping is the **only** auto-repairable violation; **sha256/content** drift is
    NOT — surface it, never smooth it (cross-ref `## What NOT to build` in the same doc; no
    "recompute the hash" path);
  - persistence: perm drift is a working-tree property git does not record (`100755`/`100644`),
    so the repair leaves `git status` clean and is not a committable diff (cross-ref "Recorded
    permissions are a ceiling");
  - ≥1 negative example phrased by rationalisation + incident number (Task 182 "deferred as a
    separate backlog item"; Task 174 deferred clamp) — no personal names.

### Step 3: Friction-point pointers in `checkpoint-commit.md` (FR2/D5)
- [ ] In the "Script (primary method)" block (near `:16`), add a one-line note: permission
  violations from the helper's `validate` are fix-on-sight via `cwf-manage fix-security`; sha256
  violations are surface-not-smooth — see
  `` `.cwf/docs/conventions/hash-updates.md#fix-permission-drift-on-sight` ``.
- [ ] At the "Manual Procedure" validate step (`:46-50`), augment the generic guidance with the
  same fix-on-sight / surface-not-smooth distinction and the same cross-reference.
- [ ] Use the repo-rooted inline-backtick cross-reference form per `cross-doc-references.md`
  (`` `.cwf/docs/conventions/hash-updates.md#fix-permission-drift-on-sight` ``) — NOT a `../`
  relative path; that matches the sibling-doc idiom (`cwf-agent-shared-rules.md`, `security-review.md`).

### Step 4: Index pointer in `CLAUDE.md` (FR2/D6)
- [ ] Append one bullet to the "Hash Updates" entry (after `:87`) as a **pure pointer**, e.g.
  "- Fix permission drift on sight: clamp via `cwf-manage fix-security` rather than defer".
  Do NOT re-encode the perm-vs-sha256 boundary here (it lives in the canonical section and in
  `checkpoint-commit.md` already) — pointer only, no prose duplication.

### Step 5: Verify (FR2/FR3/FR4 + regression)
- [ ] Grep the three files for the rule/pointers; confirm the command string is byte-identical to
  the command named in `validate`'s `Fix:` line (`CWF/Validate/Security.pm` — the bare
  `cwf-manage fix-security`, no `--dry-run`), and that no "recompute hash"/validate-silencing
  wording was introduced (FR4).
- [ ] Run `cwf-manage validate` → expect `validate: OK` (docs-only; no hash/perm change).
- [ ] Confirm `git status` shows only the three doc files (no `script-hashes.json`, no mode bits).

### Step 6: Backlog retire — deferred to j (FR5/D7)
- [ ] **Not in f.** Recorded here so it is not forgotten: at retrospective, after the CHANGELOG
  `## Task 183:` section exists, run
  `backlog-manager retire --id=restore-task-173-permission-drift-on-three-helper-scripts --task=183`
  (resolve the exact `--id` slug from `backlog-manager list` at that time; `--exact-title` as
  fallback). Confirm it leaves `backlog-manager validate` clean.

## Code Changes
None — this task modifies documentation only. No scripts, hooks, agents, rules, or `cwf-manage`
surface change (FR4: no new validate-silencing surface).

## Test Coverage
**See e-testing-plan.md for complete test plan** — covers AC1 (sweep exit 0), AC2/AC3 (rule +
boundary + byte-identical command + cross-refs), AC4 (no new surface), AC6 (induce-drift →
fix → `validate: OK` + clean `git status`). AC5 (backlog retire) is verified at j.

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.
The only deliberately-deferred item is Step 6 (backlog retire), which belongs to the
retrospective phase by design (D7) — documented here, not descoped.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
