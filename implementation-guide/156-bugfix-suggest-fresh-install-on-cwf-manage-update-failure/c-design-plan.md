# suggest fresh install on cwf-manage update failure - Design
**Task**: 156 (bugfix)

## Task Reference
- **Task ID**: internal-156
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/156-suggest-fresh-install-on-cwf-manage-update-failure
- **Template Version**: 2.1

## Goal
Define how `cwf-manage` surfaces a fresh-install suggestion when an update's
laydown fails, scoped so the hint appears only for genuine partial-state
failures.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### Decision 1: Scope the hint with a single flag, not per-`die_msg` edits
- **Decision**: Add a file-scoped lexical `$update_in_progress` (default `0`), declared **before** `die_msg` so the named sub closes over it. `cwf-manage:die_msg` (line 45) appends the fresh-install suggestion to STDERR when the flag is set. `cmd_update` sets the flag to `1` immediately before the laydown dispatch (`if ($method eq 'subtree')`, line 406).
- **Rationale**: `die_msg` is the single exit-1 helper used by ~48 call sites, several inside shared helpers (`run_apply_artefacts:247`, `run_settings_merge:259`, `apply_exact_perms_or_die:869`, `update_copy:548`). One flag covers every laydown failure — including those raised inside helpers — without touching each call site, and without leaking the hint into the same helpers' non-update callers.
- **Why `my`, not `our`**: the only existing file-scope variable, `%FIX_SECURITY_RECOVERY` (line 702), is a `my` file-lexical; matching that keeps the single-`main`-package script consistent. A `my` declared before `die_msg` is closed over by both `die_msg` and `cmd_update`.
- **Trade-offs**: A flag is slightly less explicit than per-site text, but far less repetitive and DRY-consistent. `die_msg` calls `exit` (no return/throw), so an `eval`/wrapper approach is not viable without reworking the whole error model — out of scope.

### Decision 2: Flag set point — before laydown, after clone/checkout
- **Decision**: Set `$update_in_progress = 1` at line 406, *after* clone (396) and checkout (404), *before* the subtree/copy laydown.
- **Rationale**: The hint should appear exactly when the user's install may be left partial, or when the (old) updater's laydown is the failing component — both genuinely remedied by a clean remove-then-add bootstrap. Clone/checkout operate on a throwaway tempdir and mutate nothing in the user's repo; a same-source bootstrap would re-clone and hit the identical failure, so a fresh-install suggestion there would be misleading.
- **Covered failures** (hint shown): subtree delegation (416, 419, 430, 431–433, 442), copy laydown (`update_copy`, `create_*_symlinks`), `run_apply_artefacts` (447), `run_settings_merge` (450), `apply_exact_perms_or_die` (454), and the post-laydown version-file write region (456–464 — `compute_install_manifest_sha`:463 and `write_version_file`→`die_msg`:80). The flag is never reset, so these trailing failures correctly carry the hint (laydown done but version file half-written = genuinely partial).
- **Excluded failures** (no hint): pre-flight guards — malformed ref (367), missing method (370), lock contention (377), unparseable settings (380), tampered manifest (384), dirty tree (386) — plus clone (396) and checkout (404). These are user-actionable with their own remedies; a fresh install would just hit the same guard.

### Decision 3: Suggestion wording — non-prescriptive, references INSTALL.md
- **Decision**: Print, after the existing `[CWF] ERROR:` line and before exit, a `[CWF]`-prefixed multi-line note: states the update did not finish and the install may be partial; says the user *might want to consider* a fresh install (clean remove-then-add); shows the bootstrap form `CWF_FORCE=1 CWF_REF=<tag> CWF_SOURCE=<source-url> bash install.bash`; points at `INSTALL.md` "Recovering an install stuck on an old cwf-manage".
- **Rationale**: Single source of truth — the procedure already lives in `INSTALL.md:84–98`; the hint references it rather than restating the full rationale. Wording is a suggestion, not a directive, per task requirement.
- **Trade-offs**: `die_msg` lacks `$source`/`$resolved` in scope, so the command shows placeholders rather than concrete values.
- **Rejected alternative — interpolate concrete `$source`/`$resolved`**: would make the bootstrap line copy-pasteable, but rejected on two grounds. (1) Security: `$source` can originate from `$ENV{CWF_SOURCE}` (`cwf-manage:85-87`, an FR4(d) audit surface); interpolating it into a printed shell command creates an env-var→suggested-command flow (display-only, but avoidable). (2) Simplicity: threading those values to `die_msg` needs extra globals for marginal gain. The hint is a pointer; `INSTALL.md` carries the concrete, worked recovery command. **Guardrail for implementation: keep the placeholders literal — do not "improve" the hint by interpolating live values.**

## Code Sketch (the subtle parts)
```perl
# Set true once cmd_update enters laydown; never reset (die_msg exits, one
# update per process). Gates the fresh-install suggestion below.
my $update_in_progress = 0;           # declared before die_msg so it closes over it

sub die_msg {
    print STDERR "[CWF] ERROR: @_\n";
    if ($update_in_progress) {
        print STDERR
            "[CWF] The update did not finish; this install may be in a partial state.\n",
            "[CWF] You might want to consider a fresh install (a clean remove-then-add)\n",
            "[CWF] by re-running the bootstrap installer for the target version:\n",
            "[CWF]   CWF_FORCE=1 CWF_REF=<tag> CWF_SOURCE=<source-url> bash install.bash\n",
            "[CWF] See INSTALL.md, \"Recovering an install stuck on an old cwf-manage\".\n";
    }
    exit 1;
}
```
In `cmd_update`, immediately before `if ($method eq 'subtree') {` (line 406):
```perl
$update_in_progress = 1;   # laydown begins; failures past here may leave a partial install
```
No reset needed: `die_msg` exits the process, and each invocation performs one update.

## Constraints
- POSIX / core-Perl only; no new modules (uses existing `print STDERR`).
- `cwf-manage` is integrity-hashed: the edit must travel with a `.cwf/security/script-hashes.json` refresh in the **same commit** (hash-updates convention).
- No change to exit codes or control flow — additive STDERR text only.

## Validation
- [x] Design verified against `cwf-manage` source (`die_msg`:45, `cmd_update`:361–468, helper subs)
- [x] Testability confirmed against existing `t/cwf-manage-update-end-to-end.t` harness (synthetic upstream + captured stderr)
- [x] Plan review (4 parallel reviewer subagents) completed; findings applied

**Testability — the scoping is the load-bearing behaviour**: the e-testing plan must assert hint **absence** for a pre-flight guard failure (e.g. malformed ref / dirty tree) and for a clone/checkout failure, *and* hint **presence** for a laydown failure (e.g. a target ref whose `install.bash` exits non-zero). The negative assertions are what prove the flag scoping, so they are not optional.

## Decomposition Check
No signals triggered — single-file edit (`cwf-manage`) plus same-commit hash refresh, one concern, <1 day.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Design implemented as specified (single-flag scoping, set before laydown). Plan-review finding (version-file-write region) folded into the covered-failures list. See j-retrospective.md.

## Lessons Learned
See j-retrospective.md.
