# report whether parent branch is direct ancestor - Implementation Execution
**Task**: 202 (feature)

## Task Reference
- **Task ID**: internal-202
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/202-report-whether-parent-branch-is-direct-ancestor
- **Template Version**: 2.1

## Goal
Execute the implementation following d-implementation-plan.md: hoist `run_quiet`
into `CWF::Common`, add `parent_branch_ancestry` to `CWF::TaskPath`, surface it
additively in `context-manager.d/hierarchy`, refactor `delete` onto the shared
runner, and refresh the four affected hashes in this commit.

## Actual Results

### Step 1: Shared runner (CWF::Common)
- **Planned**: add `use POSIX ()`, exported `run_quiet(@cmd)` (list-form
  fork/exec, child `POSIX::_exit(127)`, `$?>>8`, `-1` on fork fail).
- **Actual**: Done. `use POSIX ();` added; `run_quiet` added after
  `resolve_head_sha` with the Task-159 `POSIX::_exit` rationale in its header
  comment; appended to `@EXPORT_OK`.
- **Deviations**: None.

### Step 2: Ancestry function (CWF::TaskPath)
- **Planned**: add `parent_branch_ancestry($task_path)` returning 1/0/undef;
  import `run_quiet`; export the new function.
- **Actual**: Done. Added after `branch_exists`. Logic exactly as designed:
  `get_parent`→`resolve`→`format_branch`→list-form `rev-parse --verify --quiet
  refs/heads/<branch>` existence guard→`merge-base --is-ancestor <branch> HEAD`
  with `0⇒1, 1⇒0, else⇒undef`. Header documents why it deliberately avoids the
  backtick `branch_exists` (shell-safety + prefix-collision). Imported
  `run_quiet`; appended `parent_branch_ancestry` to `@EXPORT_OK`.
- **Deviations**: None.

### Step 3: hierarchy output
- **Planned**: import the function; emit JSON literal + conditional markdown line.
- **Actual**: Done. `parent_branch_ancestry` added to the `use CWF::TaskPath`
  import; `$anc` computed once after `resolve`; `depth` JSON line gained a
  trailing comma and `"parent_branch_is_ancestor": <true|false|null>` appended;
  markdown prints `Parent branch ancestor of HEAD: <yes|no|unknown>` inside the
  existing `parent_path` guard. Smoke-tested on top-level task 202 →
  `"parent_branch_is_ancestor": null` and **no** markdown line (correct — no
  parent). JSON validity confirmed by eye; real-parser assertion is TC-8 (g).
- **Deviations**: None.

### Step 4: delete refactor
- **Planned**: remove local `run_quiet` (lines 44-56); import from `CWF::Common`.
- **Actual**: Done. Local sub replaced with a one-line comment noting the import;
  `run_quiet` added to the `use CWF::Common` import. All seven prior callsites
  resolve to the shared definition; the only behavioural delta is `exit 127` →
  `POSIX::_exit(127)` in the failed-exec child (a strict hardening). Full suite
  (incl. delete's coverage) green.
- **Deviations**: None.

### Step 5: Tests
- **Planned**: unit-test the tri-state against synthetic repos; hierarchy output
  assertions via a real JSON parser; full-suite regression.
- **Actual**: New unit/integration tests (TC-1…TC-9, fixture extension) are
  g-testing-exec scope per the CWF phase split and are written there. In this
  phase: full existing suite run — **798 tests, all pass** (`prove -l -j4 t/`).
- **Deviations**: New-test authoring deferred to g-testing-exec (phase boundary,
  not a scope cut).

### Step 6: Integrity + validation
- **Planned**: refresh the four hashes in this commit; `cwf-manage validate`
  clean; per-file `git log` verification.
- **Actual**: Done. Verified each of the four files was last committed by a prior
  task (Common/TaskPath @ 173, hierarchy @ 124, delete @ 136) so the refresh
  records only this task's edits. `cwf-manage fix-security` clamped two
  **pre-existing** perms drifts (`install-manifest.json` 0600→0444,
  `pretooluse-bash-tool-check` 0700→0500) but — by design ("surface, never
  smooth") — refused to rewrite the four content hashes; those were updated
  manually in `script-hashes.json` from `sha256sum`, and the two edited scripts
  were `chmod 0500` back to recorded. `cwf-manage validate` → **OK**.
- **Deviations**: Two perms-only drifts on files this task did not edit were
  clamped in the same pass per the fix-on-sight convention (rather than deferred)
  and surfaced to the user. No content-hash smoothing occurred.

## Blockers Encountered
None. (Initial full-suite run showed failures in five hash/git-sensitive test
files; root-caused to the expected dirty-tree + stale-hash state — all five pass
once hashes were refreshed and perms clamped. A `git stash` cross-check confirmed
no pre-existing source-level failures; the residual "4 violations on the stashed
tree" were Edit-tool perms drift that `git stash` cannot revert, not repo issues.)

## Security Review

**State**: no findings

## Security Review — Task 202 (`implementation-exec`)

I reviewed the changeset against FR4(a)–(e) plus prompt-injection and environment-variable surface. The only executable changes are in four files (`.cwf/lib/CWF/Common.pm`, `.cwf/lib/CWF/TaskPath.pm`, `context-manager.d/hierarchy`, `task-workflow.d/delete`), the `.claude/settings.json` regeneration, and the hash-manifest refresh. Lines 338–1448 of the diff are task-doc boilerplate (a–j templates) with no executable content.

### (a) Credential / secret exposure
None. No secrets, tokens, or env-borne credentials are read, logged, or emitted. The new JSON/markdown fields carry only a tri-state ancestry boolean. No concern.

### (b) Injection / untrusted-input handling — the load-bearing check
This is the focus area. The derived branch name's provenance: `get_parent($task_path)` → `resolve($parent)` (which parses an on-disk task dirname) → `format_branch($num,$type,$slug)` returns the bare string `"$type/$num-$slug"`. `format_branch` applies no charset sanitisation, so the branch string is fully attacker-influenced by anyone who can create a directory under `implementation-guide/`.

The mitigation is correct: every git call routes through `run_quiet(@cmd)`, which uses list-form `exec(@cmd)` (Common.pm:140). No shell is spawned, so the branch name — even if it contained `;`, `$(...)`, backticks, or spaces — is passed as a single, distinct `argv` element to `git`, never tokenised by a shell. Verified at both callsites:
- `run_quiet('git','rev-parse','--verify','--quiet',"refs/heads/$branch")` (TaskPath.pm:549).
- `run_quiet('git','merge-base','--is-ancestor',$branch,'HEAD')` (TaskPath.pm:551).

This is the meaningful improvement over the pre-existing `branch_exists` (TaskPath.pm:507–514), which uses backtick `git branch --list '$branch'` — a shell-interpolated form. The design explicitly declined to reuse `branch_exists` for the existence guard, both for shell-safety and to avoid the `--list` glob's prefix-collision false-positive. Sound decision. No injection concern in the new path.

Pattern note (category (e), safe-here): `branch_exists` itself remains shell-interpolated and untouched by this task. Safe at current callsites only because branch names there are constrained. Audit any future caller that feeds `branch_exists` a name derived from less-trusted input. Out of scope here; flagged for future reuse.

### (c) Unsafe filesystem / path operations
`run_quiet` opens `/dev/null` for the child's three standard streams — fixed paths, no TOCTOU surface. No temp files, traversal, or symlink following introduced. No concern.

### (d) Command / shell execution surface
The hoist is behaviour-preserving with one deliberate hardening: failed-`exec` child uses `POSIX::_exit(127)` not `exit 127` (Task-159 convention — avoids inherited `END` blocks, e.g. `File::Path` cleanup in `delete`, deleting parent state). Observable exit codes unchanged. The `delete` refactor preserves behaviour: local sub removed, imported from `CWF::Common`, all seven callsites resolve to the shared definition; body byte-identical except the `exit`→`POSIX::_exit` change. No regression.

### (e) Privilege / permission changes
No `chmod`/`chown`/`setuid`/umask in code. Hash manifest refreshes four sha256 entries; the two scripts retain `"permissions": "0500"` (ceiling, not bumped). Refreshes belong in the same exec commit per hash-updates convention. No concern.

### Environment-variable handling
`run_quiet` does not scrub/inject env vars; child inherits the environment and execs `git` from `PATH`, matching every other CWF git-helper callsite. No new env-borne risk.

### Prompt-injection surface
New output is a fixed tri-state token — no attacker-controlled free text echoed. The `.claude/settings.json` `UserPromptSubmit` hook appears only because the file was reserialised; pre-existing, intentional. No new surface.

### Note on settings.json
`.claude/settings.json` reserialised with the `hooks`/`permissions`/`worktree` block; added `permissions.allow` entries are scoped `Bash(.cwf/scripts/...)` prefixes, no wildcard grant. Author confirms the reformat was intentionally folded into this task. Not a security defect.

Conclusion: the injection-critical property (list-form, never shell-interpolated) holds at both new callsites; the `delete` refactor is behaviour-preserving and strictly hardened. No actionable security findings.

```cwf-review
state: no findings
summary: Branch name is list-form only at both new git callsites (no shell injection); delete refactor is behaviour-preserving and POSIX::_exit-hardened. branch_exists shell form noted as a safe-here pattern to audit on future reuse.
```

## Deferral Check
- [x] All steps from d-implementation-plan.md executed (Step 5 new-test authoring
      is g-testing-exec by phase split, not a deferral).
- [x] Success criteria from a-task-plan.md met (additive ancestry signal landed).
- [x] Requirements from b-requirements-plan.md addressed (FR1-FR6, NFR1-NFR4).
- [x] Design guidance in c-design-plan.md followed (tri-state, shared runner, list-form).
- [x] No planned work deferred without approval.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*Consolidated in j-retrospective.md.*
