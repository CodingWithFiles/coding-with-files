# Permission-drift repair and agent guidance - Implementation Execution
**Task**: 183 (feature)

## Task Reference
- **Task ID**: internal-183
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/183-permission-drift-repair-and-agent-guidance
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status to "Finished" when complete

## Implementation Steps (from d-implementation-plan.md)

Docs-only change: one canonical fix-on-sight section + two cross-reference pointers, plus the
(already-clean) repair-sweep confirmation. No code, no hash changes. Step 6 (backlog retire) is
deferred to retrospective (j) by design (D7).

## Actual Results

### Step 1: Repair-sweep confirmation (FR1/AC1)
- **Planned**: `fix-security --dry-run` exits 0 with 0 files; `validate` no permission violation.
- **Actual**: `cwf-manage fix-security --dry-run` → `would repair 0 file(s); 0 unfixable`,
  **exit 0**. `cwf-manage validate` → `validate: OK`, exit 0. Tree clean (planning-phase clamp of
  the two Task-182 files already cleared the residual).
- **Deviations**: None.

### Step 2: Canonical section in hash-updates.md (FR2/FR3, D1–D4)
- **Planned**: Add `## Fix permission drift on sight` after "Recorded permissions are a ceiling":
  rule + perm-vs-sha256 boundary + working-tree-only persistence + ≥1 role-phrased negative example;
  command quoted byte-identically.
- **Actual**: Section added at `hash-updates.md:24`. Contains: the rule (run `cwf-manage
  fix-security`, do not defer as "out of scope"/"separate backlog item"); the boundary (clamp is
  the only auto-repairable violation, sha256/content is surface-not-smooth, cross-refs "What NOT to
  build", "Never recompute a hash to clear a validate warning"); persistence (working-tree-only,
  git records only `100755`/`100644`, no committable diff, cross-refs "Recorded permissions are a
  ceiling"); negative example phrased by rationalisation + incident (Task 182 `cwf-claude-settings-merge`
  defer-as-"separate backlog item"; Task 174 deferred clamp) — no personal names.
- **Deviations**: None. Command string `cwf-manage fix-security` verified byte-identical to
  `CWF/Validate/Security.pm:131`.

### Step 3: Friction-point pointers in checkpoint-commit.md (FR2/D5)
- **Planned**: One-line fix-on-sight note on BOTH the Script path (near `:16`) and the Manual
  Procedure validate step (`:46-50`), each cross-referencing the hash-updates section in
  repo-rooted inline-backtick form.
- **Actual**: Note added after the Script-path `cwf-manage validate` line and at the Manual
  Procedure validate step. Both cross-reference
  `.cwf/docs/conventions/hash-updates.md#fix-permission-drift-on-sight` (backtick form, no `../`).
  `grep -c` confirms 2 occurrences of the anchor.
- **Deviations**: None.

### Step 4: Index pointer in CLAUDE.md (FR2/D6)
- **Planned**: One pure-pointer bullet on the "Hash Updates" Conventions entry; no prose
  duplication of the boundary.
- **Actual**: Bullet added at `CLAUDE.md:88`: "Fix permission drift on sight: clamp via
  `cwf-manage fix-security` rather than defer (sha256 drift is surfaced, never smoothed)".
- **Deviations**: None — pointer only.

### Step 5: Verify (FR2/FR3/FR4 + regression)
- **Planned**: grep the three files; confirm byte-identical command and no validate-silencing
  wording; `validate: OK`; `git status` shows only the three docs.
- **Actual**: Byte-identical command present in all three docs. The only "recompute" mentions are
  the two prohibitions (new boundary line + existing "What NOT to build") — no silencing surface
  introduced (FR4). Anchor slug `fix-permission-drift-on-sight` matches the GitHub heading slug of
  `## Fix permission drift on sight` (TC-XREF). `cwf-manage validate` → `validate: OK`.
  `git status` shows only the three modified docs — no `.cwf/security/script-hashes.json`, no mode
  bits (none of the three files are hash-tracked, so no refresh; stated no-refresh decision holds).
- **Deviations**: None.

### Step 6: Backlog retire — deferred to j (FR5/D7)
- **Planned**: Not in f. Retire the Task-173 BACKLOG item at retrospective.
- **Actual**: Deferred as designed; recorded in d-implementation-plan.md Step 6 so it is not lost.
- **Deviations**: None — deliberate per-design deferral, not descope.

## Blockers Encountered

None.

## Deferral Check
Before marking status=Finished, verify:
- [x] All steps from d-implementation-plan.md executed (Steps 1–5; Step 6 is by-design j-phase work)
- [x] All success criteria from a-task-plan.md met (SC1 drift clear; SC2 rule; SC3 boundary; SC5
  demonstrable via TC-REPRO in g; SC4 backlog retire is the j-phase item)
- [x] All requirements from b-requirements-plan.md addressed (FR1–FR4, FR6 docs in place; FR5 at j)
- [x] All design guidance in c-design-plan.md followed (D1–D8)
- [x] No planned work deferred without user approval (only the by-design D7 j-phase retire)
- [x] If work deferred: recorded in d-plan Step 6 (no follow-up task needed — same task, later phase)

## Security Review

**State**: no findings

I have read the full changeset and the threat model. This is a documentation-only change for Task 183. Let me reason through the five threat categories.

**Nature of the changeset.** The diff touches only four files, all documentation/prose:
- `.cwf/docs/conventions/hash-updates.md` — adds a `## Fix permission drift on sight` section.
- `.cwf/docs/skills/checkpoint-commit.md` — adds fix-on-sight notes on both the script and manual paths.
- `CLAUDE.md` — one pointer bullet under the Hash Updates conventions entry.
- `implementation-guide/183-.../{a..e}-*.md` — the standard CWF workflow planning/requirements/design/impl-plan/testing-plan files.

There are no Perl scripts, no shell, no hooks, no agents, no `cwf-manage` surface changes, and no `script-hashes.json` edits. The design (D8) explicitly rejects touching the hash-tracked `claude-md-preamble.md`.

**(a) Bash injection / unsafe command construction.** No code is added or modified. The docs quote command strings (`cwf-manage fix-security`, `chmod 0700 <script>`) as literal prose for an agent to run, not as interpolated shell built from untrusted input. The FR6/TC-REPRO induce-drift procedure prescribes `chmod 0700` on a *named, recorded* tracked script with no string interpolation from task slugs or user input. Nothing constructs a shell command from partly-controlled data. No concern.

**(b) Perl helpers consuming git/user output without `-z`.** No Perl is added or changed. The change reuses the existing clamp-only `fix-security` engine rather than building a new one (FR1/FR4). No concern.

**(c) Prompt injection via user-supplied strings.** No new `{arguments}` substitution surface or LLM-context flow is introduced. The new prose is static convention text that ships into agent context, but it is authored content, not untrusted input being relayed verbatim. The negative examples are deliberately phrased by rationalisation and incident number, with no user-controlled interpolation. No concern.

**(d) Unsafe environment-variable handling.** No env vars are introduced or consumed. No `chmod`/`rm`/`open` path is built from an env var. No concern.

**(e) Pattern-based risks (safe-here-but-risky-elsewhere).** The substantive security content of this change is itself a *defensive* boundary statement, and it draws it correctly: it scopes auto-repair strictly to permission **clamping** (`actual & recorded` — can only clear bits, never raise) and explicitly forbids auto-absorbing **sha256/content** drift, cross-referencing the existing "what NOT to build" / "surface, never smooth" prohibition. This is exactly the right line and it preserves the tamper-signal guarantee. I checked specifically for the failure mode the threat model and the project's standing rules care about — a new surface that silences `cwf-manage validate` without surfacing first — and FR4/AC4/TC-NOSURFACE explicitly forbid it; no such surface is added.

One pattern worth a forward note, with the required framing: the FR6/TC-REPRO procedure instructs an agent to deliberately induce a security-relevant state (`chmod 0700` on a recorded-`0500` tracked script) and then repair it. **Safe here because** the induced bit is `u+rwx` only (no group/other write/execute, no setuid/setgid/sticky), the target is a single named tracked script in the working tree, the change is within git's `100755` class so it produces no committable diff, and `validate` keeps flagging until the idempotent clamp runs (the design notes interrupt-recovery). **Audit future uses where** this "induce drift then fix" recipe might be copied into a context that loosens *group/other* write/execute or setuid/setgid bits, or that operates on a hashed file's *content* rather than its mode — there the same recipe would cross from a reversible mode tweak into either a recorded-ceiling-widening or a tamper-signal scenario, which the clamp cannot undo. This is a documentation note, not a defect in the diff as written.

No actionable security concerns in this changeset.

```cwf-review
state: no findings
summary: Docs-only Task-183 change; correctly scopes auto-repair to permission clamping and preserves the sha256 surface-not-smooth boundary; no code, env, or injection surface added.
```

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*See per-step Actual Results above.*

## Lessons Learned
*To be captured during retrospective*
