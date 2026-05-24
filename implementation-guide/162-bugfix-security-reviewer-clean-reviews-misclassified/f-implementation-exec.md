# security-reviewer clean reviews misclassified - Implementation Execution
**Task**: 162 (bugfix)

## Task Reference
- **Task ID**: internal-162
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/162-security-reviewer-clean-reviews-misclassified
- **Template Version**: 2.1

## Goal
Execute the implementation following d-implementation-plan.md and e-testing-plan.md.

## Actual Results

### Step 1: Classifier helper + tests (D2/D3) — core
- **Planned**: New `security-review-classify` (stdin → token, D3 rule), `t/security-review-classify.t`, hash entry, validate.
- **Actual**: Wrote `.cwf/scripts/command-helpers/security-review-classify` (core-only Perl, self-contained — no CWF lib dependency, so it stays trivially unit-testable). Scans stdin for closed `cwf-review` fenced blocks (fence length tracked so a shorter nested fence cannot close early), collects blocks with exactly one valid `state:`, applies the exactly-one rule. `t/security-review-classify.t` covers TC-C1–C14 (18 assertions) — all green. Added manifest entry; `cwf-manage validate: OK`.
- **Deviations**: None. Chose self-contained over `use CWF::Common` (the `check_perl5opt` warn-only helper) because the parser is ASCII-token-only and several sibling helpers omit it.

### Step 2: Agent container contract (D1) — core
- **Planned**: Rewrite agent body to the container contract + worked example (non-token placeholder), update frontmatter `description`, refresh hash.
- **Actual**: Rewrote `.claude/agents/cwf-security-reviewer-changeset.md` — removed the "VERY FIRST output line" sentinel language; the model now reasons in prose then ends with one `cwf-review` block. Worked example uses `state: <no findings|findings|error>` (non-token placeholder) so an echoed example never validates. Frontmatter `description` reworded from "Emits sentinel-line classification." to the verdict-block contract. Restored `0444`, refreshed hash; `validate: OK`.
- **Deviations**: None.

### Step 3: Wire callers (D2 integration) — core
- **Planned**: Replace the three-tier rule in `security-review.md` with the container contract + classifier reference; rewire both exec SKILL Step 8 lines.
- **Actual**: Replaced § "Exec-phase prompt template" three-tier rule with a "Verdict container" + "Classification (deterministic, single source of truth)" subsection pointing at `security-review-classify`. Both exec SKILLs (`cwf-implementation-exec`, `cwf-testing-exec`) Step 8: capture verbatim subagent output to the task scratch dir (per `tmp-paths`), pipe through the helper, record `**State**:` + verbatim. Grep confirmed no stale `three-tier` / `VERY FIRST` / numbered-list references remain (the surviving `sentinel` hits are unrelated CLAUDE.md/artefact block markers). These files are not hash-tracked — no refresh. **Core fix (D1–D3) complete and standalone-coherent here.**
- **Deviations**: None.

### Step 4: SubagentStop hook (D4 part 1)
- **Planned**: `subagentstop-security-verdict-guard` (return-inside-eval, fail-open, affirmative-only block, JSON::PP encode, header directives), hash entry, validate.
- **Actual**: Wrote the hook reusing the classifier as a subprocess via a self-managed pipe + `exec { $prog } $prog` (no shell, no message-derived path; `POSIX::_exit` in the child on any failure). Whole body in `eval` with `return` early-outs and a single `exit 0`. Blocks only when the classifier ran cleanly AND returned exactly `error` AND `stop_hook_active` is false; allows in every other case (fail-open). `reason` is a fixed literal encoded via `JSON::PP->encode`. `t/subagentstop-security-verdict-guard.t` covers TC-H1–H7 (18 assertions, incl. injection-inertness) — all green. Added hash entry before the Step 5 edit; `validate: OK`.
- **Deviations**: Added `or POSIX::_exit(127)` onto the `exec` statement to silence Perl's "Statement unlikely to be reached" warning (kept the trailing `_exit` as belt-and-braces).

### Step 5: Merge-helper extension (D4 part 2)
- **Planned**: Read+validate header directives, generalise `merge_hooks` by event+matcher group, preserve byte-identical Stop path, refresh hash, extend tests.
- **Actual**: Added `read_hook_directives` (first 15 lines; `-f && !-l` guard; values validated `event ^(?:Stop|SubagentStop)$`, `matcher ^[A-Za-z0-9_-]+$` before use). `partition_manifest` hook branch preserves the `push @allow, "Bash($path)"` line and now carries `{entry, event, matcher}`. Rewrote `merge_hooks` to group by event with a factored `find_or_make_group` helper — matcher-less entries still append to `{event}[0]` (byte-identical Stop path), matchered entries get a `{matcher, hooks}` group. Extended `t/cwf-claude-settings-merge.t` with TC-M1–M5; all 21 subtests green (16 retained, incl. backward-compat TC-U1/TC-U3). Restored `0700` working perms, refreshed hash. `--dry-run` against the real repo confirms the SubagentStop matchered group and an unchanged matcher-less Stop group. `validate: OK`.
- **Deviations**: Did **not** run the non-dry-run merge against the real `.claude/settings.json` / `settings.local.json` — the dev repo deliberately holds only `env` in the tracked settings and the maintainer's `settings.local.json` is untracked local state. Registration is the end-user install path; mutating local config is out of scope.

### Step 6: Docs (D4 part 3)
- **Planned**: Document SubagentStop event, `agent_type` matcher, header-directive convention, fail-open discipline, settings shape in `stop-hooks-framework.md`.
- **Actual**: Added a "## SubagentStop hooks" section: event/matcher mechanics, the shipped guard, fail-open discipline, header-directive registration with the validated value rules, the authoritative `hooks.SubagentStop` settings shape, and the silent-failure risk (wrong matcher → never fires → invisibly disabled backstop, hence the registration test). Not hash-tracked — no refresh.
- **Deviations**: None.

### Step 7: Validation
- **Actual**: Full `prove t/` — **574 tests, all pass**. `cwf-manage validate: OK`.
- **Note (perms gotcha)**: an initial run failed `t/install-bash-reinstall.t` TC-5 because I had `chmod 0500` the edited scripts (read-only). The recorded manifest permission is a *minimum* (`actual & min == min`); the dev working tree convention is `0700`. `cp -rp` into the TC-5 fixture preserved the read-only bit, breaking its overwrite. Restoring the three scripts to `0700` (recorded `0500` still satisfied) fixed it. Recorded as a feedback memory.

## Blockers Encountered
None.

## Security Review

**State**: error

error: changeset exceeds 500-line review cap; split the change or perform manual review

(Deterministic skill-authored outcome: `security-review-changeset --phase=implementation` = 982 lines across 10 files, anchor `638131d`, with the 4 new code files made visible via `git add -N`. As anticipated in c-design-plan/d-implementation-plan, the cap path supersedes the subagent. Per "surface, never smooth" the `error` state stands; a manual threat-category walkthrough follows and does not overwrite it.)

### Manual threat-category walkthrough (categories a–e)

Focus on the new/changed security-sensitive code: `security-review-classify`, `subagentstop-security-verdict-guard`, and the `cwf-claude-settings-merge` extension.

- **(a) Bash injection / unsafe command construction**: No string-form `system`/backticks introduced. The hook spawns the classifier with `exec { $classifier } $classifier` (block form, no shell); `$classifier` is `$FindBin::Bin`-derived, not input-derived. The message is delivered on a pipe (fd dup), never on a command line. Classifier and merge-helper add no command construction. **Clean.**
- **(b) git/user output without `-z` / validation**: No git output consumed in the new code. Directive values are regex-validated (`event`, `matcher`) before reaching any settings key. **Clean.**
- **(c) Prompt injection via user-supplied strings**: `last_assistant_message` (potentially influenced by an adversarial changeset under review) flows only into (i) the classifier's stdin — ASCII-token-matched, never executed — and (ii) a block decision whose `reason` is a fixed literal built via `JSON::PP->encode`; no message-derived bytes reach harness-visible output (TC-H7 asserts this). The classifier emits one of three fixed tokens, carrying nothing downstream. The agent worked-example placeholder is a non-token, so an echoed example cannot be weaponised into a forced verdict. **Clean.**
- **(d) Unsafe environment-variable handling**: No new env-var consumption. `CANONICAL_PERL5OPT` remains a compile-time constant. **Clean.**
- **(e) Pattern-based risks (safe-here-but-risky-elsewhere)**:
  - `exec { $classifier } $classifier` is safe here because the path is install-derived; *audit any future reuse where the program path is partly user-controlled.*
  - `matcher` regex `^[A-Za-z0-9_-]+$` is deliberately strict; *any future widening must preserve the `^…$` anchoring to prevent settings-key injection.*
  - `read_hook_directives` reads hook file content, which is defence-in-depth **behind** hash integrity (tampering caught by `cwf-manage validate`); the `-f && !-l` guard blocks symlink-following.
- **Fail-open / DoS**: the hook blocks only on an affirmative clean-classifier `error` with `stop_hook_active` false; every failure mode allows the stop, so it can never trap the subagent or stall the workflow. The `stop_hook_active` guard plus the harness block cap prevent infinite re-emit loops.

**Manual conclusion**: no actionable security findings in the changeset. Recommend accept-and-record (the deterministic `error` reflects the cap, not a defect).

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [ ] b-requirements-plan.md — N/A (bugfix workflow has no requirements phase)
- [x] All design guidance in c-design-plan.md followed
- [x] No planned work deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
