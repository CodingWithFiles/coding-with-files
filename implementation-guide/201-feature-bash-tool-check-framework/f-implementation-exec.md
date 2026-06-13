# Bash tool-check framework - Implementation Execution
**Task**: 201 (feature)

## Task Reference
- **Task ID**: internal-201
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/201-bash-tool-check-framework
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status when complete

## Actual Results

### Step 1: Lib + lib tests (TDD)
- **Planned**: `t/tool-check.t` then `CWF::ToolCheck.pm` (load_layer, merge_rules,
  compile_perl, rule_matches, decide_repeat) to green.
- **Actual**: Both created; `prove t/tool-check.t` → 7 subtests (TC-1…TC-6) PASS
  on first run. Pure policy, no git/hook needed.
- **Deviations**: `rule_matches` signature is `($rule, $cmd, $coderef, $ctx)` —
  the d-plan listed a 3-arg form; the 4th arg (`$ctx = { cwd => … }`) is the
  bounded context the design says a `perl` rule's coderef receives as
  `($cmd, $ctx)`. Minor, additive; keeps the perl-match path testable in the lib.

### Step 2: Hook + e2e tests (TDD)
- **Planned**: `t/pretooluse-bash-tool-check.t` then the thin I/O wrapper.
- **Actual**: Both created; `prove t/pretooluse-bash-tool-check.t` → 9 subtests
  (TC-7…TC-16 coverage incl. repeat-bypass state machine, the fail-open matrix,
  symlink-safe state, ReDoS-under-external-timeout, `--check`) PASS.
- **Deviations**: Two bugs caught by the e2e run and fixed: (1) `--check` used
  `my (@raw, $exit) = ((), 0)` — the array slurped the `0`, dying under strict;
  split into separate declarations. (2) the em-dash in `--check` human output
  needed `binmode(STDOUT, ':utf8')`. Hot-path output (JSON::PP) is ASCII-safe and
  unaffected.

### Step 3: Schema doc
- **Planned/Actual**: `.cwf/docs/tool-check-rules.md` — schema, the per-layer
  trust table, merge/override/disable semantics, repeat-bypass, `--check`,
  safety posture, one worked `regex` + one worked `perl` example. No active rules
  shipped (empty default, locked). `.cwf/docs/` is not hash-tracked → no manifest
  entry needed.

### Step 4: Manifest edits
- **Actual**: `install-manifest.json` gitignore `lines` += 
  `.cwf/tool-check/*/settings.local.json`. Hook chmod `0500`, lib `0600`. Added
  two `script-hashes.json` `scripts` entries (hook with `permissions:0500` + 
  `sha256`; lib with `sha256`, no `permissions`), computed with `sha256sum`.
- **Deviations**: `install-manifest.json` is itself hash-tracked; editing it
  changed its own `sha256`, so its manifest entry was refreshed in the same
  commit (per [[hash-updates]] in-task refresh — a file modified this task).

### Step 5: Validate + full suite
- **Actual**: `cwf-manage validate` → OK (after the install-manifest self-hash
  refresh). `prove t/tool-check.t t/pretooluse-bash-tool-check.t
  t/cwf-claude-settings-merge.t t/installmanifest-integrity.t
  t/cwf-apply-artefacts.t` → all PASS (76 tests).

### Step 6: Dogfood registration check
- **Actual**: `cwf-claude-settings-merge --dry-run` shows the hook registered
  under `PreToolUse` / matcher `Bash` / `timeout 5`. With no rule files, a sample
  Bash event piped to the hook → exit 0, **zero stdout bytes** (strict no-op).

## Blockers Encountered

None. Two self-caught implementation bugs (above) fixed during the e2e run.

The exec-phase security-review changeset helper first exited `2` (603
production lines > the default 500 cap; `t/**` and `implementation-guide/**` are
already discounted, so the overage is genuine code — the hook alone is ~330
heavily-commented lines). Because this changeset introduces the framework's only
new exposure (operator-supplied Perl + config regex), skipping the review would
be backwards. The `--max-lines` ceiling is an explicitly-overridable review-cost
knob (not an integrity gate), so the helper was re-run at `--max-lines=800` to
obtain the review. Recorded transparently here as a deviation from the SKILL's
default no-`--max-lines` invocation.

## Deferral Check
Before marking status=Finished, verify:
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] All requirements from b-requirements-plan.md addressed
- [x] All design guidance in c-design-plan.md followed
- [x] No planned work deferred without user approval
- [x] If work deferred: n/a (no deferral)

## Security Review

**State**: no findings

I have everything I need. Let me now reason through the threat categories.

## Security review — Task 201 Bash tool-check framework (implementation-exec)

I reviewed the full changeset. The security-load-bearing code is in three new files plus two manifest edits: `.cwf/lib/CWF/ToolCheck.pm`, `.cwf/scripts/hooks/pretooluse-bash-tool-check`, the schema doc `.cwf/docs/tool-check-rules.md`, the `install-manifest.json` gitignore line, and the `script-hashes.json` entries. The remaining diff is the task's workflow guide files (a–j; most are unfilled template scaffolding) and the two test files. This feature is unusual in that it deliberately introduces an arbitrary-Perl execution surface (`compile_perl` runs `eval $code`), so I gave categories (b), (d) and (e) the most scrutiny.

### (a) Bash injection / unsafe command construction

The production code never shells out with any tool-input-derived string. The hook reads `tool_input.command`, `session_id`, `cwd` purely as match subjects or path components; it calls `find_git_root` (which runs `git rev-parse` with no interpolation — confirmed at `.cwf/lib/CWF/Common.pm:66-76`) and otherwise only does `open`/`sysopen`/`rename`/`mkdir`/`chmod` on paths it constructs itself. No `system`/`qx`/backticks with interpolated data anywhere in `ToolCheck.pm` or the hook. Clean.

The one place `git -C '$tmp'` is interpolated into a shell `system` is in `t/pretooluse-bash-tool-check.t:2196,2231` — test-only, with `$tmp` from `File::Temp::tempdir` (not attacker-controlled). Not a production concern; noting it only as a pattern (see (e)).

### (b) Untrusted input to Perl / git output without `-z` / input validation

This is the heart of the design and it is handled correctly:

- The config-supplied `regex` is applied as `$cmd =~ /$pat/` inside an `eval` with **no `use re 'eval'` in scope** (`ToolCheck.pm:269-285`). I confirmed the module never imports that pragma. This means an embedded `(?{...})`/`(??{...})` code block in a config regex dies at match time → caught → no-match, which is exactly what lets the clone-travelling checked-in layer carry regex rules safely. TC-4 (`t/tool-check.t:2557-2569`) asserts the `(?{ $main::PWNED = 1 })` pattern does not execute.
- The `perl` matcher is the genuine arbitrary-code surface, and `compile_perl` does `eval $code` (`ToolCheck.pm:257`). The mitigation is provenance-keyed dropping in `load_layer` (`ToolCheck.pm:210-211`): a `perl` rule whose provenance is `checked-in` is dropped **before** its string ever reaches `compile_perl`. Provenance is supplied by the caller from the path it read, never parsed from rule content — TC-3 explicitly tests that a rule whose JSON content claims `provenance: user-global` is still dropped when loaded as `checked-in`. This is the right trust boundary: the only layer that travels via `git clone` cannot execute code.
- No git porcelain is newline-split in the new code; the only git call is `find_git_root`, which returns a single path. The `-z` concern (parsing multi-record git output) does not arise here.

### (c) Prompt injection via reflected strings

The deny reason is always the matched rule's `guidance` verbatim (`emit_deny`, `ToolCheck.pm`/hook `:486-496`); the command string is never reflected into the output. TC-7 asserts the matched command fragment `1,5p` never appears in the deny JSON. The `--check` diagnostic is explicitly documented as human-terminal-only ("NEVER pipe this output back into agent context") in both the hook header and the schema doc. Good.

One observation, not a finding: `--check` does echo rule `id`s and provenance from config into stdout. Since config is author-trusted and the output is documented as not-for-agent-context, this is consistent with the stated posture.

### (d) Unsafe environment-variable handling

Two env vars are consumed: `$HOME` (user-global layer root) and `$TMPDIR` (state-dir base). Neither is tool-input-derived. `$TMPDIR` flows into `state_dir` where the repo root is dashified and appended; the dir is created `mkdir(…, 0700)` then re-checked `-d && !-l` (symlink/TOCTOU guard) per the tmp-paths convention. `session_id` — the only partly-external component composed into a path — is validated against `^[A-Za-z0-9._-]{1,200}$` in `session_state_file` (`:439-444`), rejecting `/` and `..`; on rejection the hook keeps no state (safe degrade, never bypass). TC-10 confirms a `../evil` session_id writes no state file and never bypasses. State writes use `O_CREAT|O_EXCL` temp + atomic `rename` rather than `open '>'` onto a possibly-symlinked `<sid>.last`, defeating a pre-planted-symlink clobber; TC-12 exercises this against a sentinel. This category is handled carefully.

### (e) Pattern-based risks (safe-here-but-risky-elsewhere)

Two patterns worth recording with their invariants:

1. **`eval $code` in `compile_perl` (`ToolCheck.pm:257`)** — arbitrary code execution by construction. Safe here because `load_layer` guarantees the only strings that reach it originate from the two author-owned, never-cloned layers (user-global, project-local), the drop being keyed on caller-supplied provenance rather than rule content. Audit future uses: if any caller is ever added that passes a `perl` string sourced from a clone-travelling or otherwise less-trusted layer (e.g. a future "team-shared executable rules" layer, or relaxing the checked-in drop), this becomes remote code execution on `git clone`. The invariant to preserve is "every string reaching `compile_perl` came from a layer that does not travel via clone." This is documented in the module's SECURITY header, which is the correct mitigation per the carve-out.

2. **`git -C '$tmp'` / `cd '$tmp' && …` shell interpolation in `t/pretooluse-bash-tool-check.t` (`:2196,2231`)** — safe here because `$tmp` is a `File::Temp` path containing no shell metacharacters. Audit future uses: if this test helper were copied into a context where the interpolated directory is user- or fixture-derived, it would be a shell-injection vector. Prefer list-form `system('git','-C',$tmp,'init','-q')` if this helper is ever generalised. Test-only and not shipped, so low priority — recorded for completeness, not as a blocker.

### Other observations (non-findings)

- Fail-open posture is the deliberate, documented security stance for a tool-check (never brick Bash); it is the opposite of the planning-write-guard and is correct for this artefact's role. The ReDoS bound rests on the guaranteed harness `timeout => 5` SIGKILL with the in-process 2s alarm and 64KB cap as best-effort layers — the design correctly does not rest safety on alarm pre-emption. TC-13/TC-14 cover the matrix.
- The 64KB cap refuses-to-match rather than truncates, avoiding a truncate-to-evade vector (`ToolCheck.pm:272`).
- `script-hashes.json` and `install-manifest.json` edits are integrity-manifest bookkeeping verified by `cwf-manage validate` (out of scope here per the doc's boundary note); the hook is recorded `0500`, the lib has no `permissions` key (regular file), consistent with convention.

### Conclusion

No actionable security defects. The arbitrary-Perl surface — the one genuinely new exposure — is bounded correctly by a provenance-keyed drop that runs before compilation, the regex surface is data-only via the absence of `re 'eval'`, path/env handling is validated and symlink-safe, and no untrusted string is reflected to the agent or interpolated into a shell. The two patterns in (e) are reported with their invariants per the carve-out; neither is a defect at its current callsite.

```cwf-review
state: no findings
summary: arbitrary-Perl surface bounded by provenance-keyed pre-compile drop; regex data-only (no re 'eval'); session_id/path handling validated and symlink-safe; (e) patterns recorded with invariants, no defects
```

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
