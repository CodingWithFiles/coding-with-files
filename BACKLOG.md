# CWF System Backlog

Future tasks and improvements for the Coding with Files system.

## Task: Task 219 cross-project friction remediation (14 seeded follow-ups)

### Task-Type: feature (group — promote items individually)
### Priority: High (R1 delivered by Task 221, R2 by Task 222, R7 by Task 224; R3 partly by Task 220)
### Status: Follow-up from Task 219 (j-retrospective.md §Future Work)
### Identified in: Task 219 f-implementation-exec.md §4

Task 219 mined 601 retrospectives across 11 CwF projects plus session logs and LMM and
produced 14 ranked, tradeoff-stated recommendations (full detail + sources in
`implementation-guide/219-.../f-implementation-exec.md` §3/§4). Promote each into its own
task via the normal workflow. Ordered impact-desc, effort-asc:

- **R1 (feature, High)** — ✅ **Delivered by Task 221.** Seeded a generic 20-glob
  `security.review.max-lines-exclude-paths` default (`*_test.*`, generated/vendored globs,
  scoped doc-only markdown) into the `cwf-init` config template, and raised the built-in
  cap 500→1000. Reused Task 218's exclude engine (no new runtime code); seed reaches new
  inits only, cap bump reaches every updating install. Dominant finding was the cap
  tripping on test/generated/doc across 7 projects (~40 task instances).
- **R2 (feature, High)** — ✅ **Delivered by Task 222.** Every phase now stamps its **own**
  wf file to a terminal `Status` at its checkpoint (a–i via `cwf-checkpoint-commit`; `j`
  via an `&&`-chained `cwf-set-status … Finished` hard precondition), and the shipped
  `f-implementation-exec` template's non-canonical `"Implemented"` hint was removed. Per
  the explicit constraint the retrospective status sweep is **retained as defence-in-depth**
  (not made a no-op — inconsistent state causes false positives in the hierarchical
  context scripts), and the `stop-stale-status-detector` hook was strengthened to flag any
  non-canonical status, not just `Backlog`. Reuse-only (exported `status_is_valid`); one
  hashed-file edit. Status leak was seen in 8 projects.
- **R3 (feature, Med)** — Ship a consolidated shell-hygiene convention + a default Bash
  allowlist seed (read-only/`.cwf` helpers only, never mutating verbs) + the Task-206
  path-injection hook at `cwf-init`, so new projects inherit the ~10 avoidance rules.
  **Partly delivered by Task 220**: the tool-check seed + toggle + `cwf-init` opt-in
  now exist (regex-only starter set, `/cwf-config tool-check on|off|seed`). Note the
  original "new projects re-derive them all" premise was stale — the corpus predates
  the maintainer's Jul-2026 user-global ruleset (`~/.cwf/tool-check/bash/settings.json`),
  which already enforces these across every project. Remaining R3 scope: the broader
  shell-hygiene *convention* doc and the allowlist seed (distinct from tool-check).
- **R4 (feature, Med)** — Add an "unresolved decisions" gate to `a-task-plan` (name every
  open surface/mechanism/constraint) and forbid mechanism-named acceptance criteria. 6 projects.
- **R5 (feature, Med)** — CwF upgrade runbook; fix `.cwf/version` read-tree restage;
  document sandbox-off requirement + expect-perm-drift/`fix-security`. 5 projects.
- **R6 (chore, Med)** — Replace the `a-task-plan` day-effort field with a complexity tier +
  risk register (LLM-paced work makes calendar estimates noise). 4 projects.
- **R7 (bugfix, High)** — ✅ **Delivered by Task 224**, with a corrected premise. The stated
  defect — hook paths resolved from cwd, so rules silently skip from a subdirectory — was
  **already fixed by Task 204** (`d985db3`, one day after R7's evidence was recorded);
  `find_git_root()` was never implicated. Task 224 verified this and re-aimed at the two
  live residuals of the same class: the shipped `stop-hooks-framework.md` example still
  taught the bare-relative (fail-open) registration, and nothing enforced the
  `${CLAUDE_PROJECT_DIR}/` prefix, so a hand-edited `.claude/settings.json` silently
  disabled a hook with no signal. A new `CWF::Validate::Hooks` now surfaces (never repairs)
  any CWF hook command carrying a bare `.cwf/` reference.
- **R8 (feature, Med)** — Plan-review refinements: testing-plan contradiction check
  (expected verdicts vs locked rules); verify-before-assert to cut false positives; REDUCE
  weighs live-session corrections over subagent doc-citation consensus. 5 projects.
- **R9 (feature, Med)** — Fail-closed test-DB config (never fall back to production
  `DATABASE_URL`) + a standing test-DB wrapper. Enforces the existing "always test DB" rule
  (a prod embeddings wipe occurred).
- **R10 (feature, Med)** — Library/internal task-type variant with non-SaaS
  rollout/maintenance templates (merge-to-trunk / build-gate / git-revert). 2 projects.
- **R11 (chore, Low)** — Testing-exec read-not-script default for unchanged ≤500-line artefacts.
- **R12 (feature, Med)** — Size-gate reviewer/agent fan-out on trivial changesets to curb
  per-spawn re-init token overhead.
- **R13 (chore, Low)** — Extend `plan-mechanical-check` to flag unsourced count claims
  ("N sites", "M bytes") for plan-time re-verification.
- **R14 (feature, Low)** — Fixture-migration helper + targeted-test/profile-first guidance.
- **Incidental (bugfix, Low)** — Fix the `Wide character in print` UTF-8 output defect in
  `plan-mechanical-check`/`CWF::ArtefactHelpers.pm:73` (missing `binmode`/`PERL5OPT=-CDSLA`).

## Task: plan-mechanical-check — warn on hashed path missing script-hashes.json disclosure

### Task-Type: chore
### Priority: Medium
### Status: Follow-up from Task 217 (j-retrospective.md §Future Work)
### Identified in: Task 217 j-retrospective.md §Recommendations

Task 217's d-plan wrongly asserted the edited `.claude/agents/*.md` files were not
hash-tracked; in fact both are recorded in `.cwf/security/script-hashes.json` at
`0444`. The error was caught by the security plan-reviewer (and only after two other
reviewers had echoed it), not deterministically. The `hash-updates.md` plan-time
disclosure rule already requires that any Files-to-Modify path which is hash-tracked
be listed with `.cwf/security/script-hashes.json` as a Supporting Change — but nothing
enforces it. Scope: extend `.cwf/scripts/command-helpers/plan-mechanical-check` with a
third scan that, for each path referenced in the plan's Files-to-Modify list, checks
whether that path has an entry in `script-hashes.json`; if it does AND the plan does
not also list `script-hashes.json` as a Supporting Change, surface a `hash-disclosure`
finding. Fail-open like the existing scans (advisory, never blocks). This closes the
exact class of error Task 217 hit, at plan time, deterministically — complementary to
the existing path-resolution and symbol-deletion scans. Refresh the helper's `sha256`
in the same commit.

## Task: Extract a shared CWF::Common::tmp_base() helper

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 215 (j-retrospective.md §Future Work)
### Identified in: Task 215 j-retrospective.md §Recommendations / f- and g-phase improvements review

The `${TMPDIR:-/tmp}` base selection (Perl form:
`(defined $ENV{TMPDIR} && length $ENV{TMPDIR}) ? $ENV{TMPDIR} : '/tmp'`) is now
open-coded in four sites — `CWF::Common::scratch_parent`,
`pretooluse-bash-tool-check`, `best-practice-resolve`, and the
`t/backlog-bootstrap-changelog.t` fix added in Task 215 — crossing the Rule of Three.
The Task 215 improvements reviewer flagged this; it was deferred from that bugfix to
avoid widening its blast radius into two further production sites. Scope: add an
exported `CWF::Common::tmp_base()` that returns the selected base (trailing-slash
stripped, matching `scratch_parent`'s current normalisation), then replace the four
inline ternaries with calls to it. Note the seam interaction with Task 215's
`$SANDBOX_TMP_PROBE` — `scratch_parent` needs the env→probe→/tmp three-way logic, so
`tmp_base()` is the *env-or-`/tmp`* half (the probe branch stays in `scratch_parent`),
or `tmp_base()` takes an optional probe argument. Decide at design time. Refresh
`Common.pm` sha256 in the same commit. Purely a consistency/maintainability gain.

## Task: Converge the three symlink-safe atomic settings-writers

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 220 (j-retrospective.md §Future Work)
### Identified in: Task 220 f-implementation-exec.md §Misalignment Review (accepted-with-rationale)

Task 220's `tool-check-seed` hand-rolls a symlink-safe atomic JSON writer (temp +
`O_EXCL` + `rename` at 0600, per-level `-d && !-l` parent creation, every syscall
checked) rather than reusing `CWF::ArtefactHelpers::atomic_write_text`, because the
shared writer uses `File::Path::make_path` and does **not** reject a symlink target,
and `read_json_file` has no symlink guard — so a direct swap would lose the NFR4
symlink defence. The misalignment reviewer accepted the duplication as the right trade
(bad abstraction is worse than duplication; a security-sensitive writer should not be
coupled to a general-purpose one), but the temp+`O_EXCL`+`rename` pattern now exists in
three places (`tool-check-seed`, `cwf-apply-artefacts`, `cwf-claude-settings-merge`),
crossing the Rule of Three. Scope: add an opt-in symlink-reject mode (and per-level
`-d && !-l` parent creation) to `CWF::ArtefactHelpers::atomic_write_text` — and a
symlink guard to `read_json_file` — strong enough for the tool-check threat model, then
converge all three writers onto it. `CWF::ArtefactHelpers` is hash-tracked and used by
other helpers, so re-audit each caller and refresh its sha256 in the same commit.
Purely a consistency gain; do not weaken the tool-check writer to achieve it.

## Task: Align security-review-classify discovery mode with its sibling helper's interface

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 214 (j-retrospective.md §Future Work)
### Identified in: Task 214 j-retrospective.md §What Could Be Improved / §Recommendations

Task 214 added a `--dir <DIR> --phase <PHASE>` discovery mode to
`security-review-classify`. Two exec-phase reviewers (improvements, misalignment)
independently flagged that this interface diverges from its matched-pair sibling
`security-review-changeset`, which (a) takes `--wf-step` validated against the canonical
ten-step allowlist (`%WF_STEP`) rather than an unvalidated `--phase`, and (b) derives the
per-task scratch dir itself via `CWF::Common::scratch_dir($task_num)` (the same
`find_git_root` + dashified-`$TMPDIR` + two-level `0700` mkdir + symlink-parent-reject
guard) rather than taking a caller-supplied `--dir`. The Task-214 form is deliberate and
documented (the helper stays read-only; a single literal argv is what matches the
`:*` allowlist), and was accepted to ship — but it pushes scratch-path derivation into
SKILL prose and introduces a second name (`--phase`) for an established concept
(`--wf-step`). Scope: add an alternative `--task-num <num> --wf-step <step>` invocation
that reuses `scratch_dir()` and validates the step against the shared allowlist, keeping
the two sibling helpers symmetric; the `--dir`/`--phase` form may stay as a lower-level
escape hatch or be retired. A `--task-num` form still matches the same `:*` allowlist
entry, so the no-prompt property is preserved. Update both exec skills and the two
`*-review.md` snippets accordingly. Optional — purely a consistency/maintainability gain.

## Task: Path-resolution audits must cover generated artefacts and all path surfaces

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 204 (j-retrospective.md §Recommendations)
### Identified in: Task 204 j-retrospective.md §What Could Be Improved / §Recommendations

Task 204 fixed cwd-relative `.cwf/...` resolution, but its original survey counted bare
`.cwf/...` only in checked-in `SKILL.md` source and missed a third surface — the generated
`.claude/settings.json` hook registration — which was caught only by a live
`PreToolUse:Bash hook error` mid-task. It also discovered (via spike) that different path
surfaces resolve against different roots: Bash invocations and Read/Edit tool paths resolve
against the **shell** cwd, while hook commands resolve in a harness environment where only
`${CLAUDE_PROJECT_DIR}` is guaranteed. Capture this as a convention/checklist so future
cwd/root tasks (a) enumerate every path surface — Bash, tool-path, hook, generated config —
and what each resolves against, as an explicit design-phase spike item, and (b) grep
**generated** outputs, not just source. No production-code change implied; this is a docs/convention
addition (candidate home: a short note under `.cwf/docs/conventions/` or the design-phase guidance).

## Task: Convention note — `effort`/`model` values on hash-tracked guard agents carry security weight

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 187 (j-retrospective.md §Future Work) — watch-item, may be a no-op
### Identified in: Task 187 g-testing-exec.md (Security Review), j-retrospective.md §Future Work

Task 187 introduced the first `effort:` frontmatter in the repo: `effort: low` on the two exec
skills and `effort: high` pinned on `cwf-security-reviewer-changeset`. The changeset reviewer
noted that `cwf-manage validate` signs a hashed file's *bytes* but does not judge whether a
frontmatter *value* is safe — a future edit setting `effort: low` on a reviewer/guard agent
would pass `validate` while silently degrading the security gate. Capture this as a sentence in
`hash-updates.md` (or `design-alignment.md`): when refreshing the hash of a reviewer/guard agent,
confirm its `effort`/`model` value is not a downgrade, because integrity tooling will not catch
it. Low priority and possibly unnecessary (the pin pattern is self-documenting); recorded so the
insight is not lost. No code change implied.

## Task: Generalised agent-frontmatter unknown-key linter

### Task-Type: feature
### Priority: Low
### Status: Follow-up from Task 193 (j-retrospective.md §Future Work)
### Identified in: Task 193 a-task-plan.md (Open Decision 1), j-retrospective.md §Future Work

Task 193 delivered `CWF::Validate::Agents` scoped narrowly to the silently-ignored
`allowed-tools:` key. `allowed-tools:` is not the only agent frontmatter key Claude Code
silently ignores — any unrecognised key is dropped without warning. Generalise the validator
to flag *any* key not in an authoritative allow-list of valid agent keys (`name`,
`description`, `tools`, `model`, …). The hard part is the allow-list itself: it is a moving
target tied to Claude Code's agent schema, and the repo already carries intentional
non-core keys (`effort:`, introduced in Task 187) that must NOT be flagged — so the list
must be maintained deliberately, not guessed. Scope: extend `CWF::Validate::Agents` with an
allow-list check + fixtures; decide the list's source of truth and update cadence. Related
but distinct from the *"effort/model values carry security weight"* item above (that concerns
the *value* of a known key; this concerns *unknown keys*).

## Task: Decide whether fresh install.bash should clamp perms to the recorded ceiling

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 185 (j-retrospective.md §Future Work)
### Identified in: Task 185 f-implementation-exec.md §Blockers, j-retrospective.md

A raw `curl|bash` fresh install (BOTH `read-tree` and `copy`) leaves laid-down files at
umask-derived perms (e.g. a 0500-recorded script materialised 0700), so `cwf-manage
validate` reports recorded-ceiling violations until the first `cwf-manage fix-security`
or `cwf-manage update` (which runs `apply_exact_perms_or_die`). This is **pre-existing and
method-independent** — Task 185 confirmed `copy` produces the identical 42 violations, so
read-tree is no regression. b-requirements **AC1** ("fresh install … validate clean") is
stricter than this established behaviour. Decide whether `install.bash` `post_install`
should invoke `cwf-manage fix-security` to clamp (making a raw fresh install validate-clean
for both methods), weighing the benefit against a new installer→cwf-manage coupling at
bootstrap (a new failure surface in the curl|bash path). If adopted, update AC framing and
add a fresh-install validate-clean test; if declined, record AC1's scope as the
update/migration path. No `cwf-detect-merges`/laydown change is implied.

## Task: Add a lost-uncommitted-work recovery runbook

### Task-Type: chore
### Priority: Medium
### Status: Follow-up from Task 172 (recommendation R3, P1)
### Identified in: Task 172 f-implementation-exec.md §3(d), j-retrospective.md §Future Work

Document that never-committed work leaves **no HEAD-reflog trace** — it survives only as dangling objects (e.g. a `git stash push -u`/`pop` leaves a dangling stash commit) recoverable via `git fsck --unreachable` / `git reflog stash`, not the HEAD reflog. In the Task 172 anchor incident the lost 11-file changeset was recovered from dangling commit `a49e33b`, but only after the wrong tool (HEAD reflog) was tried first. Scope: a short `.cwf/docs` runbook + a MEMORY pointer. Docs-only.

## Task: Security-review convention — verify tool-rule semantics against live output

### Task-Type: chore
### Priority: Medium
### Status: Follow-up from Task 172 (recommendation R4, P1)
### Identified in: Task 172 f-implementation-exec.md §2 (FR1-2), j-retrospective.md §Future Work

The new model reasoned from **remembered tool-rule semantics** and was wrong: phases a–e of the anchor task assumed `G703` was not a real gosec rule (gosec emits `G703: Path traversal via taint analysis`), caught only when the tool was actually run. Scope: a `security-review.md` skill-doc convention reinforcing the standing no-fabrication rule (`feedback_no_fabricated_citations`) — verify external-tool rule semantics against live tool output, never assert a remembered rule catalogue. Docs/convention.

## Task: Add a "workflow" keyword-disambiguation guard

### Task-Type: chore
### Priority: Medium
### Status: Follow-up from Task 172 (recommendation R5, P1)
### Identified in: Task 172 f-implementation-exec.md §4, j-retrospective.md §Future Work

The harness reserves "workflow" for its multi-agent `Workflow` orchestration tool, colliding with CWF's pervasive "workflow" vocabulary (a system-reminder steers toward the tool on the word; witnessed in-session during Task 172). Scope: **start with option 1 (behavioural guard)** — a short note in CLAUDE.md/skills: "in CWF, 'workflow' = the CWF phase system, not the harness `Workflow` tool; never spawn multi-agent orchestration for CWF phases." Hold option 2 (targeted wording: "Workflow Skills"→"CWF phase skills", update `glossary.md:157`) as a fast-follow. Option 3 (full rename across filenames/`workflow-manager`/`wf` abbrev) is a deferred **major-version** decision, not a first move.

## Task: Mechanical detection of `echo "EXIT: $?"` / `echo "exit=$?"` bash habit

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 150
### Identified in: Task 150 j-retrospective.md §What Could Be Improved

The `[[feedback_no_echo_exit]]` memory entry exists, but the bash-habit leak still occurred twice during Task 150 exec phases. Surface-level review of memory entries does not prevent the habit from firing on autopilot. A mechanical detector would close the gap: e.g. a post-Bash-call hook that greps the command for `;\s*echo\s+["']?(?:EXIT|exit)\s*[:=]?\s*\$\?` and either blocks (strict) or surfaces (advisory) the pattern, citing the feedback memory. Out-of-scope alternatives: lifting the rule into CLAUDE.md `## Conventions` (more bulk in always-loaded surface); waiting for the harness to detect this class (not under CWF control). Lowest-friction option is an in-repo bash-call linter or a Stop-hook check.

## Task: Make `.claude/agents/cwf-plan-reviewer-misalignment.md` enforced-permission survive git checkout

### Task-Type: chore
### Priority: Medium
### Status: Follow-up from Task 149
### Identified in: Task 149 a-task-plan.md §Constraints, j-retrospective.md §Future Work

`.cwf/security/script-hashes.json` requires permissions `0444` on `.claude/agents/cwf-plan-reviewer-misalignment.md`, but `cwf-manage validate` reports `Actual: 0600` and the violation persists after every fresh clone or branch switch. Root cause: git tracks only the executable bit, so `chmod 0444` doesn't survive `git checkout`. This is structural — separate from any source-edit drift the file might have. Resolution options: (a) change the expected permission in `script-hashes.json` to `0644` or `0664` (match what git can actually preserve), (b) move permission-enforcement out of `cwf-manage validate` for non-executable text files, (c) install a post-checkout hook that re-applies the recorded permission. (a) is the lowest-cost option but should be considered against whether the read-only invariant is actually load-bearing for this agent file. Task 149's a-plan explicitly excluded this from its scope; the convention doc on hash updates is intentionally orthogonal to the permission-bit question.

## Task: Tighten AC4-style grep gates to "metadata position only"

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 132
### Identified in: Task 132 g-testing-exec.md and j-retrospective.md

Task 132 used a file-wide `grep -cE '^\*\*[A-Z][\w\- ]*\*\*:' BACKLOG.md CHANGELOG.md` as one of two AC4 gates ("legacy `**Field**:` metadata is gone"). After migration the grep returns 3 + 134 hits — *all in body content* (e.g. `**Create**:` followed by a bullet list). Validators correctly do not classify these as metadata, and the semantic gate (`backlog-manager validate` clean + round-trip byte-identical) holds. The grep is a coarse syntactic proxy. Replace with either (a) a parser-driven gate that walks the tree and asserts no metadata-position `**Field**:` survived, or (b) a tighter regex that only matches the first non-blank lines after a `## ` heading. (a) is the cleaner option since the parser already exists. Optional — there is no functional gap.

## Task: Lift backlog-manager test scaffolding to `CWFTest::Fixtures`

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 132
### Identified in: Task 132 `/simplify` deferred work

`t/backlog-tree-parse.t`, `t/backlog-tree-validate.t`, `t/backlog-tree-mutators.t`, `t/backlog-roundtrip-live.t` all duplicate the same `write_tmp` / `parse_and_validate_*` / `has_rule` / `get_rule` helpers. Lift these into `t/lib/CWFTest/Fixtures.pm` (or extend the existing test-support module if one is added later). Cost is small; payoff is single-source-of-truth for the most reused test idiom. Deferred from Task 132's `/simplify` pass because it's wider scope than the simplify pass warranted.

## Task: Adopt CWF::Options for backlog-manager argument parsing

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 132
### Identified in: Task 132 `/simplify` deferred work

`backlog-manager` rolls its own `parse_args` because no existing helper handles the "unbounded `--key=value`" argument shape it needs. Either (a) extend `CWF::Options` (or whichever the canonical options module is) to support the unbounded shape, or (b) document that `backlog-manager`'s arg parser is the canonical pattern for "unbounded options" and lift it back into the shared module for any other helper that needs the same shape. (b) is more conservative; (a) is cleaner long-term.

## Task: Collapse parse_backlog_tree/parse_changelog_tree into single parse_tree($path, $kind)

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 132
### Identified in: Task 132 `/simplify` deferred work

`CWF::Backlog` exports `parse_backlog_tree` and `parse_changelog_tree` as two-line wrappers over `_parse_path($_[0], $kind)`. Collapsing to a single `parse_tree($path, $kind)` (with `$kind` being a public enum string `'backlog'` or `'changelog'`) would shrink the surface and make the kind explicit at call sites. Touches public API — needs a deprecation pass or a major version bump. Deferred from Task 132's `/simplify` because changing exported surface was wider scope than warranted at simplify time.

## Task: Backfill **Baseline Commit** field in in-flight tasks' a-task-plan.md

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 129
### Identified in: Task 129 retrospective (j-retrospective.md)

Tasks created before Task 129 landed have no `**Baseline Commit**:` line in their `a-task-plan.md`. The `security-review-changeset` helper falls back to `git merge-base HEAD <trunk>` for these, which preserves Task 129's no-regression promise but does not give them the per-task-baseline benefit. A one-line backfill helper (or a manual edit per task) would normalise the corpus. Optional — there is no functional gap.

## Task: Extend security-review-changeset shebang interpreter regex

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 129
### Identified in: Task 129 retrospective (j-retrospective.md)

The v1 anchored interpreter regex covers `perl|bash|sh|ksh|zsh|fish|python\d?|ruby|node|deno|php|lua|pwsh|powershell` — >95% of in-the-wild interpreters. Files with `awk`, `tcl`, `make`, `gawk`, or version-pinned interpreters (e.g. `python3.11`) are missed. Focused extension; preserve the `^…$` anchoring invariant.

## Task: Adopt `File::chdir` for test scaffolds that change directory

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 129
### Identified in: Task 129 retrospective (j-retrospective.md)

`t/security-review-changeset.t` (and likely others) uses `chdir $repo` ... `chdir $orig` to scope subprocess invocations. If a test `die`s between the two, `chdir $orig` never runs, leaking cwd state into subsequent tests. Use `local $CWD` from `File::chdir` for exception-safe lexical scoping. Not currently broken (tests die fast, tempdirs auto-clean), but a worth-it refactor as the test scaffolding grows.

## Task: Standardise Placeholder Syntax in Remaining CLI Docs

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 88
### Scope: 
### Identified in: Task 88 retrospective (j-retrospective.md)

`workflow-preamble.md` and `decomposition-guide.md` use `<var>` syntax in CLI argument
documentation (showing command syntax, not model-substitution targets). Task 88 established
the convention: `{}` = "substitute this value", `<>` = reserved for HTML/XML/email.
These files should be audited and any model-substitution `<var>` instances converted to
`{var}`. Pure CLI syntax examples (e.g. `cmd <arg>`) should be reviewed to determine
whether a deliberate style-guide entry would be clearer.

- Audit `.cwf/docs/skills/workflow-preamble.md` for `<var>` instances
- Audit `.cwf/docs/workflow/decomposition-guide.md` for `<var>` instances
- Convert model-substitution uses to `{}`; decide on CLI syntax documentation style
- Add a one-liner to the style guide (or glossary) clarifying the distinction

## Task: Add Slug Generation Helper Script (`cwf-slug`)

### Task-Type: feature
### Priority: Low (downgraded post-Task-119)
### Scope: 
### Identified in: Task 100 discovery (originally framed as deduplication of prose-described algorithm). Task 119 already collapsed the prose duplication and centralised the algorithm in `template-copier-v2.1`. Remaining motivation is preview-without-side-effect; lower priority than originally scoped.

Expose `generate_slug` from `template-copier-v2.1` as a standalone helper so callers can preview the slug a description will produce before invoking task creation.

- Script wraps `template-copier-v2.1`'s `generate_slug` (or extracts it to a shared module)
- Returns the slug for a given description; exits non-zero with the same `[CWF] ERROR:` message if the slug is empty or exceeds `SLUG_MAX_LEN` (consistent with task-creation behaviour)
- Useful for skills/scripts that want to compute the slug for display or branch-name construction without committing to task creation

## Task: Lift `die_msg` to a Shared `CWF::Common` Module

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 119
### Scope: 
### Deferred from: Task 119 (out of scope per c-design-plan.md Decision 3; surfaced again in /simplify Code Reuse review)

Both `cwf-manage` and `template-copier-v2.1` define identical `sub die_msg { print STDERR "[CWF] ERROR: @_\n"; exit 1; }` helpers. `CWF::Common` already exists (exports `parse_semver`, `version_cmp`) and is a natural home. Lifting `die_msg` deduplicates the helper and makes the `[CWF] ERROR:` prefix the single canonical convention.

- Add `die_msg` (and matching unit tests) to `.cwf/lib/CWF/Common.pm`
- Update `cwf-manage` and `template-copier-v2.1` to `use CWF::Common qw(die_msg)` and remove their inline copies
- Refresh script hashes

Carried over from the sister "Migrate Remaining `print STDERR + exit` Blocks in `template-copier-v2.1` to `die_msg`" entry (retired in this merge, Task 146):

- Replace each `print STDERR "Error: ..." + exit N` block with `die_msg("...")`, preserving exit codes via a 2-arg form if needed
- Update tests if any assertion strings depend on the old format
- `template-copier-v2.1`'s existing error paths (unknown args, missing required params, invalid format, config load failure, template-dir-not-found, broken symlinks, copy failures) still use the older `print STDERR "Error: ..." + exit N` pattern -- migrating them is the natural consequence of lifting `die_msg`, unifying the `[CWF] ERROR:` prefix convention across the whole script.

## Task: Codify the `main() unless caller();` Testability Convention

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 119
### Scope: 
### Identified in: Task 119 retrospective (Process Learning)

Task 119's plan-review caught that `template-copier-v2.1`'s top-level execution dies on `do`-load (empty `@ARGV` hits the required-param check before tests can override `die_msg`). Solution: wrap top-level in `sub main { ... } main() unless caller();`. This is a recurring testability requirement for any helper script with bare top-level execution; should be documented as a CwF convention so future scripts adopt it from the start.

- Document the convention in `docs/conventions/` (or similar) — explain the `do`-load failure mode, the `main() unless caller();` fix, and the `*main::die_msg` test-override pattern that depends on it
- Reference from the existing Tasks 115/116 test patterns

## Task: Replace cwf-extract Skill with Helper Script

### Task-Type: feature
### Priority: Low
### Scope: 
### Identified in: Task 100 discovery (rank 2.0, only fully-deterministic skill)

The entire cwf-extract skill is deterministic end-to-end: input type detection (regex check for "/" or ".md"), section→file lookup (fixed mapping table), and content extraction (awk pattern). Could be replaced by a single helper script, making the skill a one-line wrapper.

- Create `cwf-extract` helper script in `.cwf/scripts/command-helpers/`
- Implement input type detection, section→file mapping, awk extraction
- Reduce SKILL.md to a wrapper that calls the script

## Task: Lightweight Rollout/Maintenance Templates for Internal/Developer-Tool Tasks

### Task-Type: chore
### Priority: Medium
### Status: Follow-up from Task 57; reinforced by Task 114
### Scope: 
### Identified in: Task 57 retrospective (j-retrospective.md — i-maintenance.md lessons learned); Task 114 h-rollout.md and i-maintenance.md (both Lessons Learned sections); coalesced from a duplicate entry in Task 130 (2026-05-07)

Both `h-rollout.md` and `i-maintenance.md` ship with full enterprise templates (blue-green/canary, SLAs, monitoring, alerting, scaling). For internal tooling and developer-tool changes — which is most CwF self-development — these templates are 80% boilerplate that gets manually marked "not applicable". Task 114 wrote both phases as essentially custom freeform documents because the template didn't fit; Task 57 also flagged this in i-maintenance lessons learned.

- Create "internal" variants of h-rollout.md and i-maintenance.md templates
- Reduce to relevant sections (deployment strategy, known issues, architecture reference)
- Template selection during `/cwf-new-task` based on project type or explicit flag

Carried over from the sister "Consider `internal-feature` template variant for service-less CLI helpers" entry (retired in this merge, Task 146):

- For tasks whose deliverable is a local CLI helper with no service surface, no users, and no telemetry, the v2.1 template's h-rollout.md and i-maintenance.md sections (monitoring, alerting, phased-rollout, scaling, SLOs) collapse to mostly-N/A. The template-variant approach (e.g. `internal-feature`, or extending `chore`) should drop these vestigial sections rather than only trim them.
- Surfaced again during Task 136 rollout + maintenance phases -- cross-task evidence: Tasks 57, 114, 136 all hit the same wall.
- Optional; no functional gap, just a paperwork-reduction opportunity -- but the cross-task recurrence argues for landing it rather than letting it accrete more re-discoveries.

## Task: Comprehensive Dead Code Audit for CWF Library Modules

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 51
### Problem: Task 51 only addressed functions already identified as dead. Remaining library modules may have additional cleanup opportunities not yet discovered.
### Solution: Systematic audit of all library modules:
### Scope: Audit only, do not remove code. Create follow-up tasks for actual removal.
### Dependencies: Requires "Document Dead Code Audit Methodology" task completed first
### Rationale: Proactive cleanup improves maintainability, reduces confusion, keeps codebase lean
### Identified in: Task 51 retrospective (j-retrospective.md - "Future Work")

Run comprehensive dead code audit across all `.cwf/lib/*.pm` files using improved methodology from dead code audit documentation.


- Apply documented audit methodology to each .pm file
- Generate structured audit reports for each module
- Create follow-up task(s) for confirmed dead code removal
- Consider using Perl::Critic or static analysis tools

## Task: Create Perl Idioms Documentation

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 50
### Problem: Task 50 implementation initially used non-idiomatic patterns (`grep { defined($_) }` instead of `grep defined`, if/else blocks instead of ternary conditionals). User review during planning phase caught and corrected these, but patterns should be documented for consistency across all CWF scripts.
### Solution: Create perl-idioms.md with sections:
### Scope: Documentation only, no code changes
### Rationale: Consistent idiomatic code improves readability, maintainability, reduces cognitive load
### Identified in: Task 50 retrospective (j-retrospective.md - "Recommendations")

Create `.cwf/docs/conventions/perl-idioms.md` documenting common idiomatic Perl patterns for CWF scripts.


- **Filtering**: `grep defined` vs `grep { defined($_) }`, `map` patterns
- **Conditionals**: Ternary operators vs if/else blocks, postfix conditionals
- **String operations**: `s///` substitution, `=~` vs `!~`
- **File operations**: Three-arg open, lexical filehandles
- **Error handling**: `die` with context, `or die` idiom
- **References**: When to use, dereferencing patterns

## Task: Add "Skipped-If" Conditional Logic to Workflow System

### Task-Type: feature
### Priority: Low
### Status: Follow-up from Task 50
### Problem: Task 50 added "Skipped" status for marking phases N/A, but developers must manually set status for each task. For task types with predictable phase applicability (bugfixes never need maintenance, hotfixes skip rollout), conditional logic would eliminate manual work.
### Solution: Add `"phase-applicability"` section to cwf-project.json:
### Scope: 
### Rationale: Eliminates manual work, reduces errors, codifies workflow conventions
### Identified in: Task 50 retrospective (j-retrospective.md - "Recommendations")

Allow task types to conditionally skip workflow phases based on type (e.g., bugfixes always skip i-maintenance.md).


```json
"phase-applicability": {
  "feature": ["a","b","c","d","e","f","g","h","i","j"],
  "bugfix": ["a","b","c","d","e","f","g","j"],  // skip h-rollout, i-maintenance
  "hotfix": ["a","d","f","g","j"],  // skip b,c,e,h,i
  "chore": ["a","d","f","g","j"]  // skip b,c,e,h,i
}
```
Template-copier automatically marks non-applicable phases as "Skipped" during task creation.

- Update cwf-project.json schema
- Modify template-copier to set "Status: Skipped" for non-applicable phases
- Update workflow-steps.md with phase applicability by task type

## Task: Create Integration Test for Inconclusive Inference Scenarios

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 37
### Scope: 
### Identified in: Task 37 retrospective (j-retrospective.md)

Create integration test harness that manipulates git state to produce real signal conflicts, enabling testing of inconclusive inference scenarios.

- Create test script that sets up controlled signal conflicts
- Test branch signal vs recency signal conflict
- Test all three signals disagreeing
- Test no signals scenario (empty repository)
- Validate real TaskContextInference output matches expectations

## Task: Create Verification Test Pattern Templates

### Task-Type: chore
### Priority: Low
### Status: Identified from Task 36 retrospective
### Problem: Task 36 used grep/diff verification effectively for 17-file update. This pattern is reusable but not documented.
### Solution: Create verification pattern templates in documentation.
### Scope: 
### Success Criteria: 
### Rationale: Codifies effective verification approach from Task 36 for reuse.
### Discovered: Task 36 retrospective - grep/diff verification proved effective

Create reusable grep/diff verification patterns for multi-file update tasks.



1. **Create `docs/patterns/verification-tests.md`**:
   - Grep count pattern: `grep -l "PATTERN" files/* | wc -l`
   - Diff statistics: `git diff --stat`
   - Insertion consistency: Check all files show same line count
2. **Add examples**: Multi-file updates, consistent snippets, completeness checks

- [ ] Verification patterns documented with examples
- [ ] Future multi-file tasks reference patterns
- [ ] Verification approach consistent across tasks

## Task: Add Material Changes Review to Phase Commit Checklists

### Task-Type: chore
### Priority: Medium
### Status: Identified from Task 35 retrospective
### Problem: Task 35 experienced repeated oversight where actual command file changes (the core deliverables) were not committed at multiple checkpoints:
### Solution: Add explicit commit review step to each workflow phase documentation.
### Scope: 
### Success Criteria: 
### Rationale: Prevents repeated oversight pattern where documentation gets committed but actual code/config changes are forgotten. Explicit checklist reduces cognitive load and provides systematic review process.
### Discovered: Task 35 retrospective - command files not committed at any checkpoint despite being the core deliverable

Add explicit commit checklist step to workflow documentation and templates to prevent oversight of committing actual deliverables.

- Implementation-exec phase (checkpoint commit)
- Rollout phase
- Retrospective phase

Root cause: Exclusive focus on implementation-guide/ documentation files caused deliverables in other directories (.claude/, .cwf/, etc.) to be overlooked.


1. **Update workflow-steps.md**: Add commit checklist guidance to each phase (implementation-exec, testing-exec, rollout, retrospective)
2. **Update phase templates**: Add "Commit Checklist" section to execution templates:
   - f-implementation-exec.md.template
   - g-testing-exec.md.template
   - h-rollout.md.template
   - j-retrospective.md.template
3. **Checklist content**:
   ```markdown
   ## Pre-Commit Checklist
   - [ ] Run `git status` to see all modified files
   - [ ] Review all modified files - are they material to this task?
   - [ ] Stage all material changes: implementation-guide/, .claude/, .cwf/, source files, etc.
   - [ ] Verify staged changes match task scope (git diff --staged)
   - [ ] Don't assume only implementation-guide/ files need committing
   ```

- [ ] Workflow documentation includes commit review guidance
- [ ] All execution templates have commit checklist section
- [ ] Checklist explicitly mentions reviewing files outside implementation-guide/
- [ ] Future tasks less likely to miss committing core deliverables

## Task: Add Baseline Verification Step to Implementation Planning Templates

### Task-Type: chore
### Priority: Low
### Status: Identified from Task 35 retrospective
### Problem: Task 35 estimated 35 historical references but actual count was 52. Baseline was established incorrectly, causing mid-stream test criteria adjustment during testing phase.
### Solution: Update d-implementation-plan.md template to include baseline verification section.
### Scope: 
### Success Criteria: 
### Rationale: Pre-execution baseline verification prevents mid-stream test criteria adjustments and ensures test cases are accurate from the start.
### Discovered: Task 35 retrospective - baseline of 35 references was inaccurate, actual was 52

Add explicit baseline verification step to implementation planning phase for tasks involving counts, metrics, or quantitative validation.



1. **Update template**: `.cwf/templates/pool/d-implementation-plan.md.template`
2. **Add section** after "Implementation Steps":
   ```markdown
   ## Baseline Verification (if applicable)

   For tasks involving counts, metrics, or quantitative validation:
   - [ ] Establish accurate baseline BEFORE implementation
   - [ ] Document baseline measurement method
   - [ ] Record baseline values with verification date
   - [ ] Note any assumptions or exclusions

   Example: Historical reference count
   - Baseline: grep -r "pattern" dir/ | wc -l
   - Value: 52 references (2026-02-06)
   - Exclusions: Task's own documentation
   ```

- [ ] Template includes baseline verification section
- [ ] Section is conditional ("if applicable")
- [ ] Provides clear example for count-based tasks
- [ ] Future tasks establish accurate baselines before implementation

## Task: Test Edge Cases for Task Context Inference System

### Task-Type: chore
### Priority: Low
### Status: Deferred from Task 32 testing execution
### Background: Task 32 implemented a signal-based inference system that automatically detects the current task and workflow step from environmental signals (git branch, worktree, state file, recency, progress). During testing execution (g-testing-exec.md), 42/45 tests passed (93%) with zero failures. Three edge case tests were deferred because they require test environments that would break the current task context or create artificial conflicting state.
### Deferred Test Cases: 
### Test Requirements: 
### Scope: 
### Out of Scope: 
### Success Criteria: 
### Rationale: These edge case tests validate inference behavior in atypical scenarios. While the primary use case (developer working on feature branch with active task) is fully validated and production-ready, these edge cases ensure graceful degradation when signals are missing or conflicting. Testing was deferred from Task 32 because creating the test environments would break the current task context, but they should be validated in a controlled test environment to ensure robustness.
### Estimated Effort: 2-4 hours (environment setup, test execution, documentation)
### Priority: Low because:
### Related: Task 32 (feature-task-tracking-using-inference-scoring) - implementation and testing complete except for these three edge cases

Execute three edge case tests for the task context inference system (Task 32) that were deferred due to requiring special test environments.



1. **TC-I3: Uncorrelated Signals (Conflicting State)**
   - **Scenario**: Multiple signals disagree on which task is current
   - **Example**: Branch points to Task 32, but state file points to Task 11
   - **Expected**: User prompt asking to clarify which task is correct, exit code 1
   - **Why deferred**: Requires artificially creating conflicting state
   - **Environment**: Need to set up branch/state file/recency signals that disagree

2. **TC-I4: No Signals (Main Branch)**
   - **Scenario**: No signals detected (e.g., working on main branch with no task context)
   - **Expected**: Error message "Cannot infer context - no signals detected", exit code 3
   - **Why deferred**: Requires switching to main branch, which loses current task context
   - **Environment**: Need main branch with no feature work in progress

3. **TC-S2: Skill Failure Fallback**
   - **Scenario**: `/current-task-wf` skill invoked when inference cannot determine context
   - **Expected**: "Unable to infer context" message displayed
   - **Why deferred**: Requires no-signal environment (same as TC-I4)
   - **Environment**: Need environment where all inference signals return null


**For TC-I3 (Uncorrelated Signals)**:
- Create test fixture with conflicting signals
- Set git branch to feature/32-slug
- Set `.cwf/current-task` to different task number (e.g., 11)
- Verify wrapper script outputs user prompt
- Verify exit code 1 (uncorrelated)
- Clean up test fixtures after test

**For TC-I4 and TC-S2 (No Signals)**:
- Switch to main branch (loses feature branch signal)
- Clear `.cwf/current-task` if present
- Work in directory with no recent modifications
- Verify wrapper script outputs error
- Verify exit code 3 (no signals)
- Verify skill displays fallback message
- Return to feature branch after test


1. **Create isolated test environment**:
   - Git worktree or separate clone for testing without disrupting main work
   - Test fixtures for artificial signal conflicts
   - Cleanup script to restore original state

2. **Execute TC-I3**: Test uncorrelated signals scenario
   - Set up conflicting signals
   - Run `task-context-inference` wrapper
   - Verify user prompt and exit code 1
   - Document results in Task 32 testing file

3. **Execute TC-I4**: Test no signals scenario
   - Set up environment with no signals
   - Run `task-context-inference` wrapper
   - Verify error message and exit code 3
   - Document results in Task 32 testing file

4. **Execute TC-S2**: Test skill failure fallback
   - Use same no-signal environment
   - Invoke `/current-task-wf` skill
   - Verify fallback message displayed
   - Document results in Task 32 testing file

5. **Update Task 32 documentation**:
   - Update g-testing-exec.md with edge case results
   - Change test status from "SKIP" to "PASS" or "FAIL"
   - Update coverage metrics

- Fixing issues found (this is testing only, not bug fixes)
- Modifying inference algorithm based on findings
- Adding new test cases beyond these three

- [ ] Isolated test environment created without disrupting main work
- [ ] TC-I3 executed with documented results (PASS/FAIL)
- [ ] TC-I4 executed with documented results (PASS/FAIL)
- [ ] TC-S2 executed with documented results (PASS/FAIL)
- [ ] Task 32 g-testing-exec.md updated with results
- [ ] Original environment restored after testing
- [ ] Any bugs discovered documented (separate BACKLOG items if fixes needed)



- Primary use case (correlated signals) is fully validated
- These are edge cases with low likelihood in normal usage
- System is production-ready without these tests
- No known bugs in these scenarios (just untested)

## Task: Add Status Calculation Overview to Workflow Documentation

### Task-Type: chore
### Priority: Low
### Status: Proposed (identified during Task 25 retrospective discussion)
### Problem: Current documentation explains status VALUES (Backlog=0%, Finished=100%) but not how task completion percentage is CALCULATED:
### Solution: Add brief "How Status Works" section to `.cwf/docs/workflow/workflow-steps.md`:
### To check task status: 
### Status values: See [Status Values](#status-values) section above for complete list.
### Scope: 
### Out of Scope: 
### Success Criteria: 
### Rationale: Users and LLM need to understand how task percentage is calculated, but full details belong in script documentation (DRY). Brief overview with references provides sufficient context.

Add brief explanation of how task status/progress calculation works to workflow documentation, following DRY and progressive disclosure principles.

- No explanation that status is aggregated from workflow file Status fields
- No mention of status-aggregator script
- No reference to /cwf-status (user-invocable currently, agent-invocable after skills migration)
- Users/LLM don't understand how "25% complete" is derived


```markdown
## How Task Status Works

Task completion percentage is calculated by aggregating the `## Status` field from each workflow file (a-plan.md through h-retrospective.md). Each status value has a percentage weight (Backlog=0%, In Progress=25%, Finished=100%, etc.).

- User runs: `/cwf-status <task-path>` (command - user-only currently)
- Script: `status-aggregator <task-path>` (called by cig-status command)
- Future: Agent can invoke via Skill("cig-status") after skills migration

**How it's calculated**: See `status-aggregator` script for implementation details.

```

1. Add brief "How Task Status Works" section to workflow-steps.md
2. Position after "Status Values" section (lines 16-48)
3. Include references to status-aggregator script
4. Note that /cwf-status is user-only currently, agent-invocable after skills migration
5. Keep brief (4-6 sentences), follow progressive disclosure

- Detailed status-aggregator implementation (that's in the script itself)
- Fixing status aggregator issues (separate BACKLOG item exists)
- Skills migration (separate BACKLOG item exists)

- [ ] Brief explanation added to workflow-steps.md
- [ ] References status-aggregator script
- [ ] Notes future agent invocability
- [ ] Follows progressive disclosure (brief with pointers to details)

## Task: Add Active Maintenance Cost Analysis to g-maintenance Template

### Task-Type: chore
### Priority: Medium
### Problem: Current g-maintenance.md template doesn't distinguish between:
### Solution: Add required section to g-maintenance.md template:
### Total scheduled cost: [Hours per year]
### Estimated reactive burden: [Hours per year, may be zero]
### Active costs: [Scheduled + reactive estimates]
### Benefits: [Concrete value delivered, if feature used]
### Justification: [Why ongoing cost is worth it, or why zero cost makes it low-risk]
### Deprecation trigger: [When would we remove this feature?]
### Scope: 
### Rationale: Prevents open-ended future commitments by requiring explicit justification of ongoing work. Makes maintenance costs visible upfront, enabling better decisions about feature complexity.

Update the g-maintenance.md template to require explicit analysis of active maintenance costs versus passive benefits, preventing open-ended future commitments.

- **Active scheduled tasks**: Work that MUST be done on a regular schedule (maintenance, noun form)
- **Reactive support**: Work that MIGHT be needed IF issues arise
- **Passive benefits**: Value delivered without ongoing work

This leads to proposals for "quarterly reviews" or "monthly checks" without justifying the time commitment. Maintenance is an ongoing cost that needs explicit justification.


```markdown
## Active Maintenance Requirements

### Scheduled Maintenance Tasks
List tasks that MUST be done on a regular schedule:
- [Task description] - [Frequency] - [Estimated time]


If NONE: Explicitly state "NONE - no scheduled maintenance required"

### Reactive Maintenance Only
List scenarios where action MIGHT be required (IF/THEN format):
- **IF** [trigger condition] → **THEN** [action] ([estimated time])


### Cost/Benefit Analysis
```

1. Update `.cwf/templates/pool/g-maintenance.md.template` with new section
2. Position after "Monitoring Requirements" section, before "Status"
3. Include examples for both scenarios:
   - Example A: Feature with scheduled maintenance (database cleanup, log rotation)
   - Example B: Feature with zero scheduled maintenance (configuration/documentation changes)
4. Update documentation to explain distinction between active/reactive/passive

## Task: Extract CWF Argument Validation Pattern to Documentation

### Task-Type: feature
### Priority: Low
### Note: Task 11 was cancelled (commands→skills migration in Task 57 bypassed the underlying $ARGUMENTS bug). The pattern itself remains useful as a security-review reference, hence kept at Low rather than removed. Reclassified from `Needs-Triage` in Task 130.

Create reusable documentation for the secure argument parsing pattern developed in Task 11. This pattern (LLM validates format → extracts arguments → invokes bash with literals) prevents command injection and handles arbitrary user input safely. Should be documented in `.cwf/docs/` for use in future CWF commands or similar systems. Include: (1) Security model explanation, (2) Format validation regex patterns, (3) Example implementation, (4) Test scenarios.

## Task: Standardize Exit Codes to errno-Style Values

### Task-Type: chore
### Priority: Low

Consolidate exit codes across all CWF helper scripts to use errno-compatible values for better semantic meaning and consistency. Currently, exit codes are inconsistent across scripts (e.g., exit 3 means "Missing required argument" in hierarchy-resolver but "No parent tasks" in context-inheritance). Proposed standard:
- 0 = Success
- 2 = ENOENT (No such file or directory) - for "not found" errors
- 13 = EACCES (Permission denied) - for permission errors
- 22 = EINVAL (Invalid argument) - for validation errors

Scripts to update: hierarchy-resolver, context-inheritance, status-aggregator, format-detector, template-version-parser, and any future helper scripts. Update documentation in script headers and `.cwf/docs/` to reflect standard.

## Task: Surface Task-Level Status Label in Status Summary Line

### Task-Type: feature
### Priority: Low
### Status: Follow-up from Task 58
### Proposed change: When all workflow files share the same status (e.g., all "Cancelled"), append it to the summary line: `- 11 (bugfix): ... - 0% [Cancelled]`. When mixed, either show the lowest-progress status or omit.
### Scope: Both `status-aggregator-v2.0` and `status-aggregator-v2.1`. Affects markdown and JSON output modes.
### Identified in: Task 58 retrospective (j-retrospective.md)

The status-aggregator summary line shows only the percentage (e.g., `- 11 (bugfix): ... - 0%`), with no status label. A Cancelled task at 0% looks identical to a Backlog task at 0%. The `--workflow` flag shows per-file status labels, but the top-level summary line does not surface the dominant or consensus status.

## Task: Improve status-aggregator Error Message Clarity

### Task-Type: chore
### Priority: Low

Improve error message in `status-aggregator` to clarify that it expects a task number (e.g., "17", "1.2.3"), not a full file path. Current error "Invalid task path format: 17-feature-new-helper-script-to-setup-templates-for-new-task" is confusing because users might provide the directory name or full path. Updated error should say something like "Error: Invalid task number format. Expected decimal notation (e.g., '17', '1.2', '1.2.3'), not a file path or directory name." This improves usability by helping users understand the correct input format immediately.

## Task: Implement Interface-Based Version Dispatch for status-aggregator

### Task-Type: refactor
### Priority: Medium
### Status: Discovered in Task 26 (TC-F11 test failure)
### Identified in: Task 26 testing execution (TC-F11) on a mixed v2.0/v2.1 project

### Problem
`status-aggregator --workflow` does not show the per-task workflow breakdown for all tasks in mixed-version (v2.0 + v2.1) projects. The trampoline detects a version globally and routes to a single version-specific aggregator; that aggregator then fails to find the wf-files of any task in the other version. TC-F11 from Task 26's testing plan captures the failure mode and is currently marked "KNOWN LIMITATION".

### Approach
Move version detection per-task rather than per-process. Define a small interface (list_wf_steps, get_task_progress, format_output) and a dispatch table keyed by version. Each `CWF::WorkflowFiles::V20` / `V21` module implements the interface; a single unified `status-aggregator` script iterates tasks, looks up the per-task version, and calls through the dispatch. The trampoline simplifies or goes away.

### Success Criteria
- [ ] TC-F11 passes: `status-aggregator --workflow` shows workflow files for every task on a mixed-version corpus
- [ ] All existing tests continue passing
- [ ] One unified status-aggregator script; no v2.0 / v2.1 split
- [ ] Interface compliance validated at module-load time
- [ ] Net code reduction relative to baseline

### Files affected
- Create: `.cwf/lib/CWF/WorkflowFiles/Dispatch.pm`
- Modify: `.cwf/lib/CWF/WorkflowFiles/V20.pm`, `V21.pm` (implement the interface)
- Modify or unify: `.cwf/scripts/command-helpers/status-aggregator{,-v2.0,-v2.1}`

### Scope note
Significant refactor touching the status-aggregation core. Workaround exists (task-specific queries via `/cwf-status <num>`); the gap is only the workflow-overview path. Detailed dispatch-table and Perl code design belongs in the eventual task's c-design / d-implementation phases, not in BACKLOG.

## Task: Audit CWF Skills for Hardcoded Data

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 43
### Scope: 
### Note: Originally framed against `.claude/commands/cwf-*.md`; rescoped to skills in Task 130 after the commands→skills migration (Task 57) eliminated the original audit target. The audit motivation still applies to the skill files that replaced them.
### Identified in: Task 43 retrospective (j-retrospective.md); rescoped in Task 130 (2026-05-07)

Audit all CWF skill files to identify and eliminate hardcoded data that should be read from configuration files instead.

- Check all `.claude/skills/cwf-*/SKILL.md` files (and any companion `*-extras.md` docs) for hardcoded lists, paths, or configuration values
- Identify data that duplicates information in `script-hashes.json`, `cwf-project.json`, or other config files
- Refactor to read from canonical sources instead of duplicating data

## Task: Document Workflow Phase Sequences by Task Type

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 43
### Scope: 
### Identified in: Task 43 retrospective (j-retrospective.md)

Create quick reference documentation for workflow phase sequences (which files are used) for each task type.

- Document feature workflow: a, b, c, d, e, f, g, h, i, j (all 10 phases)
- Document bugfix workflow: a, c, d, e, f, g, j (7 phases)
- Document hotfix workflow: a, d, f, g, h (5 phases)
- Document chore workflow: a, d, f, j (4 phases)
- Add to `.cwf/docs/workflow/` directory
- Include in command help or error messages when phase skipped

Carried over from the sister "Document Bugfix Workflow Differences" entry (retired in this merge, Task 146):

- Bugfix workflow skips h-rollout.md and uses checkpoint commits for rollout instead -- this should be called out explicitly in the per-type documentation, not just implied by the phase list.
- The bugfix-specific entry was motivated by Task 36's confusion about an attempted /cwf-rollout invocation on a bugfix task that had no h-rollout.md. The per-type docs should make the "missing phase" cases discoverable from the docs alone, not only via failure.
- Per-type comparison table (Feature / Bugfix / Hotfix / Chore × phase) is the discoverable shape; document rollout alternatives for workflows without h-rollout.

## Task: Research Compaction Failure Frequency via LMM Memory Analysis

### Task-Type: discovery
### Priority: Medium
### Status: Backlog
### Problem: Best practices recommend adding compaction preservation instructions to CLAUDE.md (e.g., "When compacting, always preserve: current task number, current workflow phase, list of modified files, task branch name"). Before implementing, we need to know whether compaction-related context loss is actually a frequent problem in CWF usage.
### Approach: 
### Identified in: Claude Code best practices analysis (2026-04-16)

Analyse conversation history via LMM memory MCP to determine how often compaction causes loss of critical CWF context, and whether custom compaction instructions in CLAUDE.md would mitigate it.


1. Query LMM for conversations where the agent lost track of task context mid-session
2. Look for patterns: agent asking "which task are we on?", re-reading files it already read, repeating completed work
3. Correlate with session length (longer sessions more likely to compact)
4. Assess frequency and impact
5. If frequent: recommend specific compaction instructions for CLAUDE.md
6. If rare: deprioritise

## Task: Add Conflict-State Regression Test for stop-uncommitted-changes-warning

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 113
### Problem: The hook's parsing path (`substr($_, 3)`) is identical for every porcelain status code, so conflict records *should* parse correctly. But this is unverified end-to-end. If git ever changes the porcelain format for conflicts (e.g. emits two paths separated by NUL, like renames), the hook would silently misreport.
### Scope: 
### Identified in: Task 113 g-testing-exec (TC-8 deferred as stretch)

Add a small regression test that exercises the `stop-uncommitted-changes-warning` hook against synthetic git porcelain output containing conflict-state records (`UU`, `AA`, `DD`). Currently the parser is verified by code inspection only — the live TC-8 test was deferred during Task 113 because reproducing a real merge conflict on a wf file is brittle.


- Add a test that feeds synthetic porcelain output into a parsing helper, or stages a real `UU` record via `git update-index --cacheinfo` against a stub blob
- Cover `UU`, `AA`, `DD`, and at least one rename (`R`) to round out porcelain-class coverage
- Wire into `prove` if there's an existing test harness, otherwise document as a manual one-liner
- **Update (Task 200)**: a harness now exists — `t/stop-uncommitted-changes-warning.t` (throwaway-git-repo subprocess shape). The conflict-state cases slot in as additional cases there rather than needing a new file; stage `UU`/`AA`/`DD`/`R` records in the per-case temp repo and assert the hook's grouped output.

## Task: Skill Cross-Reference Linter for SKILL.md / *-extras.md Step Numbers

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 114
### Problem: There's no static check that SKILL.md step numbers match their extras-file labels. The d-implementation-plan Step 9 grep audit only looks for cross-references *to* the skill from outside; it doesn't catch internal docs that mirror the numbering.
### Scope: 
### Rationale: Caught by dog-fooding in Task 114. The fix is mechanical; the linter prevents recurrence and surfaces the issue before the next renumbering.
### Identified in: Task 114 j-retrospective.md

`*/SKILL.md` files numbered step lists (Step 1, Step 2, ...). Their companion `.cwf/docs/skills/*-extras.md` files mirror those numbers in section headings (e.g. "## CHANGELOG.md and BACKLOG.md Update (Step 8)"). When a SKILL.md is renumbered, the extras file silently drifts. Task 114 introduced two new steps in `cwf-retrospective/SKILL.md` (Step 9 bump, Step 11 tag), bumping squash from 9→10 and merge-suggestion from 10→12. The drift in `retrospective-extras.md` was only caught by actually running the retrospective skill in Task 114's own j-phase — and fixed in-task.


- Small Perl helper, e.g. `.cwf/scripts/command-helpers/cwf-validate-skill-refs`
- Given each SKILL.md, parse out its `**Step N**:` headings; given the corresponding extras file, parse `## ... (Step N)` and `### N.X` labels; warn on any mismatch
- Wire into `cwf-manage validate` as a soft check (warn, not fail) initially
- One subtest per SKILL/extras pair in a new `t/skill-refs.t`

## Task: Consider parent-agent inline tool-selection rubric

### Task-Type: discovery
### Priority: Low
### Status: Follow-up from Task 118 retrospective
### Discovery questions: 
### Identified in: Task 118 j-retrospective.md (Future Work)

Task 118 added a tool-selection rubric for CWF subagents (canonical doc + brief inline excerpt in the plan-review prompt). The same anti-patterns (`sed -n 'X,Yp'`, `cat | grep`, `find … -exec cat`) apply when the *parent* Claude Code agent reaches for them — and Task 118's empirical observation that subagents ignore soft prompt restrictions is plausibly the same for the parent agent reading CLAUDE.md.

- Does the parent agent already comply with the rubric? Pull a recent transcript and check.
- The harness's system prompt already says "Read files: Use Read (NOT cat/head/tail)" — is that catching the cases Task 118's anti-patterns name, or are there gaps the canonical doc covers that the system prompt doesn't?
- If a gap exists: is the right place to address it CLAUDE.md (project-scoped), `~/.claude/CLAUDE.md` (user-scoped), or a CWF skill that can install the guidance into either?

**Resolution paths** (pick in design phase):
- **A**: No gap — close the discovery; convention doc remains subagent-scoped
- **B**: Gap exists, scope is project-specific — add a one-line reference to `.cwf/docs/conventions/subagent-tool-selection.md` from the project's CLAUDE.md
- **C**: Gap exists, scope is user-wide — add a CWF install-time hook that writes a tool-selection block into `~/.claude/CLAUDE.md` (with user opt-in)

## Task: Resolve symlinks in validate_path_allowlist

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 131
### Scope: 
### Risk: low — the only known production callers operate on hard-coded repo paths, not user-supplied ones. The exposure is via `backlog-manager add --body-file` which is not yet wired into automation.
### Identified in: Task 131 c-design-plan plan-review (security agent)

`validate_path_allowlist` in `CWF::ArtefactHelpers` rejects absolute paths and `..` traversal but does not resolve symlinks before checking the allowlist. A symlink inside the repo pointing outside the allowed prefixes (e.g. `t/fixtures/escape -> /etc/passwd`) would slip through, allowing `--body-file=t/fixtures/escape` in `backlog-manager add` (and analogous flows in any other helper using `validate_path_allowlist`) to read arbitrary files.

- Modify `validate_path_allowlist` to call `Cwd::realpath()` on the input and on each allowed prefix; reject if the resolved path doesn't begin with a resolved allowed prefix.
- Audit existing callers (`cwf-apply-artefacts`, `cwf-claude-settings-merge`, `backlog-manager`) to confirm none rely on symlink-not-resolved behaviour.
- Update `t/artefacthelpers.t` (or equivalent) with a symlink-escape regression test.

## Task: Roll intent-CTA description convention to remaining skills

### Task-Type: chore
### Priority: Low
### Identified in: 134

Task 134 established the skill-reference-doc convention at .cwf/docs/skills/skill-reference-convention.md and produced one instance for cwf-backlog-manager. Roll the same treatment to the remaining ~20 user-invocable skills: rewrite each frontmatter description to intent-CTA shape (name domain + 2-3 example user phrasings, <=30 words, double-quoted YAML form) and add a per-skill reference doc at .cwf/docs/skills/reference/<skill>.md (<=30 lines, 3-5 example phrasings, no SKILL.md links).

## Task: `/cwf-delete-task` no-arg form — default to topmost stack entry

### Task-Type: feature
### Priority: Low
### Status: Follow-up from Task 136
### Identified in: Task 136 retrospective (j-retrospective.md)

Let `/cwf-delete-task` default to the topmost entry on `.cwf/task-stack` when invoked with no `<task-path>` argument — the common case is "undo what I just did", which is by definition the topmost stack entry. Would need its own FR set covering: (a) empty-stack behaviour (refuse with a useful message), (b) interaction with the existing positional `<task-path>` (no-arg form is distinct, not an alias), (c) `--force` semantics (unchanged). Out of scope for Task 136 which deliberately required an explicit task path.

## Task: Make path-allowlists overridable in cwf-project.json

### Task-Type: chore
### Priority: Low
### Status: Open
### Identified in: Task 137 implementation-exec (2026-05-13)

Once `validate_path_allowlist` is split into `validate_write_path_allowlist`, `validate_read_path_allowlist`, and `validate_temp_path_allowlist` (see the "Very High" backlog item from Task 137), make each list overridable in `implementation-guide/cwf-project.json` so adopters can extend or replace the defaults without forking the helper modules.

### Why
The three allowlists encode CWF's opinions about safe project paths. Reasonable defaults will not fit every adopter:

- An adopter with a non-default `implementation-guide/` base-path needs to relocate the write allowlist.
- An adopter who wants `--body-file` to *only* accept paths under a curated location can tighten the read list.
- An adopter on a platform with non-standard temp roots (CI runners using `$RUNNER_TEMP`) needs to extend the temp list.

Today the lists are hardcoded inside `CWF::ArtefactHelpers.pm`. Forking is the only override path.

### Proposed shape
Add a `path-allowlists` block to `cwf-project.json`:

```json
{
  "path-allowlists" : {
    "write" : [".cwf/", ".claude/", "docs/", "implementation-guide/", "t/"],
    "read"  : [],
    "temp"  : ["/tmp/", "$TMPDIR/"]
  }
}
```

Semantics:

- Each list is **optional**. Absent keys inherit the module default.
- `"read": []` means "no prefix constraint" (matches the proposed default after the split — read sources should be unrestricted).
- Each helper function reads its list at call time via the existing `cwf-project.json` loader, falling back to the hardcoded default when the file or the key is absent.
- Environment-variable expansion (`$TMPDIR`, `$HOME`) handled in the loader, not in the validator.

### Work to do
- After the validator-split task lands: extend the `cwf-project.json` loader to parse the new block.
- Thread the loaded lists through each helper's call sites; remove the hardcoded defaults from `CWF::ArtefactHelpers` (or keep them as a fallback).
- Document the block in `docs/conventions/design-alignment.md` or a new config doc.
- Update tests to cover override + fallback behaviour.

### Dependencies
Strictly downstream of the "Split validate_path_allowlist into write/read/temp variants" task. No point landing this without that one first.

## Task: Investigate whether cwf-init GIT_ROOT capture is redundant

### Task-Type: discovery
### Priority: Low
### Status: Follow-up from Task 138
### Identified in: Task 138 j-retrospective.md

Task 138 removed the `cd "$(git rev-parse --show-toplevel)" && ` prefix from `cwf-backlog-manager`'s SKILL.md examples on the basis that the relative path `.cwf/scripts/command-helpers/backlog-manager` is self-anchoring via kernel ENOENT. The Task-138 scope explicitly excluded `.claude/skills/cwf-init/SKILL.md:87` because its use is *different* — it captures `GIT_ROOT` into a shell variable and passes it as an *argument* to `cwf-apply-artefacts`. Investigate whether that argument is actually load-bearing: most CWF helpers resolve the git root internally via `find_git_root()` in `CWF::Common`. If `cwf-apply-artefacts` already does so (or can trivially be changed to), the `GIT_ROOT=$(...)` capture and the two-argument call form can be dropped, leaving a bare `.cwf/scripts/command-helpers/cwf-apply-artefacts --bootstrap-init`. ~30 min investigation; the resolution may be "no change" if the helper genuinely needs the argument distinct from its internal git root resolution (e.g. for cross-repo bootstrap scenarios).

## Task: Add validate_temp_path_allowlist for transient-file callers

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 140
### Identified in: Task 140 retrospective (j-retrospective.md)

Add `validate_temp_path_allowlist($path)` to `CWF::ArtefactHelpers` when a Perl-side temp-file caller appears that justifies its existence.

### Background
Task 140 (`split-path-allowlist-by-access-mode`) implemented two of the three variants proposed in the original Task 137 BACKLOG entry: `validate_write_path_allowlist` (verbatim copy of the prior `validate_path_allowlist` behaviour) and `validate_read_path_allowlist` (defined / non-empty / `-f` / `-r`). The third variant (`validate_temp_path_allowlist`) was deferred at d-implementation-plan time after grep against the two candidate callers named in the original BACKLOG entry (`cwf-checkpoint-commit`, `security-review-changeset`) confirmed neither writes Perl-side temp files today. Adding the function with zero callers would be dead code.

### Proposed semantics (unchanged from Task 137 BACKLOG entry)
Accept `/tmp/`, `$TMPDIR/`, and the system temp dir. Reject paths under `.cwf/`, `.claude/`, `docs/`, `implementation-guide/`, `t/`, or anything else inside the git tree. Used when a caller needs to write a transient file that must not be tracked.

### Trigger
Add the function only when a Perl-side caller appears that genuinely writes a temp file the project should not track. Most likely candidate: a future refactor of `security-review-changeset` that emits intermediate state to a temp file rather than stdout. When that happens, write the function on the same pattern as the existing two variants in `CWF::ArtefactHelpers`, then wire the caller to it in the same task.

### Resolution-as-no-action
This entry may legitimately stay open indefinitely. If a year passes with no caller appearing, close it as "obviated — convention is that Perl-side temp writes go via `File::Temp` directly, no allowlist wrapper needed."

### Dependencies
None. The two variants this would join are already shipped by Task 140.

## Task: Drop --destination from cwf-new-task SKILL example (helper auto-constructs)

### Task-Type: chore
### Priority: Low
### Identified in: Task 142 retrospective (2026-05-16)

The `/cwf-new-task` and `/cwf-new-subtask` SKILL.md examples show `--destination="{task-dir}"` in the `task-workflow create` invocation block. This is misleading in two ways:

1. The placeholder `{task-dir}` reads as the *parent* directory (`implementation-guide/`). A first-time invocation that passes the parent path causes the helper to dump templates loose into the parent, not into a nested task directory. (Encountered at Task 142 task-creation time; one extra rm + re-invocation to recover.)

2. The helper itself auto-constructs the full task-directory path when `--destination` is omitted entirely. `template-copier-v2.1` § parse_parameters around line 110: "Construct destination if not provided. Reuse the slug we just computed rather than slugifying the description a second time."

### Fix shape
- Drop `--destination` from the SKILL example block in both `cwf-new-task/SKILL.md` and `cwf-new-subtask/SKILL.md`.
- Document the auto-construct behaviour in the trailing prose.
- Optionally: an explicit-path follow-up sentence for the rare case where a caller wants to override (e.g. subtasks nested into an existing parent — `cwf-new-subtask` may still need the flag for that case; verify the auto-construct logic respects the parent path).

### Scope
~15 min. Two SKILL.md edits. No code change, no test change, no hash regen. Verify subtask auto-construct still produces the nested `<parent>/<num>-<type>-<slug>/` shape before dropping the flag from the subtask SKILL example.

### Why Low
- The current shape works for callers who read carefully or who run the helper enough times to learn the pattern.
- The recovery is one `rm` away (no destructive side effect beyond loose template files).
- Lower-priority than the wave of security-review prompt-compliance work currently in the backlog.

### Out of scope
- Removing `--destination` from the helper's CLI surface. The flag remains supported for callers who want explicit control; only the SKILL example shape changes.

## Task: Retrofit create_skill_symlinks with warn-on-stray + die-on-collision

### Task-Type: chore
### Priority: Medium
### Identified in: Task 143 retrospective (j-retrospective.md)

`cwf-manage`'s `create_skill_symlinks` (existing) does not have the conflict-check / warn-on-stray behaviour that Task 143 added to `create_agent_symlinks`. Same logic applies in both directories â `cwf-*` is CWF's namespace in `.claude/skills/` as much as in `.claude/agents/`. A user-dropped `cwf-mything` regular file should emit the same warning; a user-dropped file colliding with a CWF skill name should die. Lift the warn/die block into a shared helper sub (e.g. `_check_namespace_conflicts($source_dir, $target_dir, $glob, $kind)`) and call it from both `create_skill_symlinks` and `create_agent_symlinks`. Task 143's d-implementation-plan.md explicitly flagged this as a deliberate-asymmetry deferral.

## Task: Install-time chmod 0444 on data/agents files (avoid post-install fix-security)

### Task-Type: chore
### Priority: Low
### Identified in: Task 143 g-testing-exec.md TC-AC1-install

Fresh `install.bash` runs leave the `data` and `agents` sections at 0600 (whatever umask creates), and `cwf-manage validate` fires 10 permission violations until `cwf-manage fix-security` runs. The validator's check (`(actual & expected) == expected` for 0444) is correct; the install path doesn't enforce. Fix: have `install.bash`'s `copy_tree` / `post_install` set 0444 on every file whose ledger entry declares that permission. Or have install.bash invoke `cwf-manage fix-security` at the end of post_install. This is a pre-existing issue (not introduced by Task 143); Task 143's agent files just inherit the same path.

## Task: Session-restart smoke-test helper for newly installed agents

### Task-Type: feature
### Priority: Low
### Identified in: Task 143 retrospective (j-retrospective.md)

Claude Code's agent registry is loaded at session start. Newly installed `.claude/agents/cwf-*.md` files (via `install.bash` or `cwf-manage update`) are not discoverable until session restart. Task 143's TC-AC3b, TC-AC5a, TC-AC5b were classified BLOCKED-ENV for this reason. Options: (a) post-install helper that prints `"Restart Claude Code to load X new agent(s)"` and exits; (b) auto-re-exec of `claude` after install (probably too invasive); (c) document the constraint in `.cwf/docs/skills/cwf-agent-shared-rules.md` and `cwf-new-task` so authors know upfront. (a)+(c) is the minimal-risk path.

## Task: Naming convention for throwaway test branches

### Task-Type: chore
### Priority: Low
### Identified in: Task 143 retrospective (j-retrospective.md)

Task 143 needed a synthetic upstream commit (renamed agent file) to exercise TC-AC1-update. Created `feature/143-synthetic-rename` as a throwaway branch; the user flagged the noise (`feature/143-...` looked like a real task branch in `git branch -v`). Adopt a prefix convention for non-task throwaway branches â `wip-test/`, `test-fixture/`, or `scratch/` â and document it in `CONTRIBUTING.md` or the relevant convention doc. Cheap; pays off whenever a task needs a synthetic upstream ref for testing.

## Task: Status value mismatch: planning-phase skill templates suggest 'Planning' but cwf-project.json doesn't include it

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 144
### Identified in: Task 144 retrospective (j-retrospective.md Â§ Recommendations Â§ Process Improvements)

The planning-phase skill templates (cwf-task-plan, cwf-implementation-plan, cwf-testing-plan) consistently emit `**Status**: Planning` in their suggested wf-step-file body, but `Planning` is not in the canonical `status-values` map in `implementation-guide/cwf-project.json` (which currently enumerates Backlog/Blocked/Cancelled/Finished/In Progress/Skipped/Testing/To-Do). Every task using these skills hits a 3-violation validate-fail on first run and has to manually correct to a canonical value. Resolution options: (i) add `Planning` (and possibly `Testing-plan` etc.) to the canonical set with appropriate progress weights, or (ii) patch the skill templates to default to an existing value such as `In Progress`. Pick one. Identified in Task 144 retrospective (j-retrospective.md Â§ Recommendations).

## Task: Unify implementation-guide directory-scan helpers across CWF::Backlog and CWF::TaskContextInference

### Task-Type: chore
### Priority: Low
### Identified in: Task 147 c-design D1 (Out of Scope)

Three slightly different `implementation-guide/N-*-*` directory scans now exist across two modules: `CWF::Backlog::_scan_task_dirs` (Task 147 — strict, returns all matches, anchors `<type>` against `supported-task-types`), and `CWF::TaskContextInference::_get_task_slug` (`:491-509`) / `_get_task_dir` (`:560-578`) (best-effort, first-match). Contracts differ (strict-or-die vs best-effort-first) but the scan primitive (opendir + filter on `\AN-<type>-<slug>\z`) is the same.

Worth promoting the primitive into a small `CWF::TaskDir` module exposing a single `scan_task_dirs($task_num)` returning `(@matches)` plus two thin wrappers preserving the two existing contracts. Keeps the supported-task-types regex anchoring in one place, eliminates the three-scan drift surface, and lets future helpers share a single discipline (symlink rejection, anchored type alternation, `\Q$task_num\E` quoting).

Out of scope for Task 147 — the new scan was intentionally factored only within `Backlog.pm` to avoid scope creep on the user-facing fix.

## Task: Plan-review or impl-plan should grep existing tests for contract-message strings being changed

### Task-Type: chore
### Priority: Low
### Identified in: Task 147 retrospective (j-retrospective.md)

Task 147's implementation plan didn't catch that AC14 in `t/backlog-manager.t` asserted the old "Task N has no CHANGELOG entry → die" contract that this task explicitly replaces per FR1. The test broke on first post-implementation run; ~10 min to update. The plan-review subagents (Improvements/Misalignment/Robustness) caught several other defects but didn't flag this one because they review the plan against the codebase abstractly, not against the existing test corpus by message content.

Proposed: add a step to either the implementation-plan checklist or the plan-review subagent prompts that says "grep all `t/*.t` files for any string literals referenced as the existing contract being changed (specifically: assertion regexes that pin error messages or behaviour the task changes); enumerate each match in the plan as either 'remains valid' or 'needs update'."

The pattern generalises beyond Task 147: any task that changes a user-facing message, error contract, or exit code potentially has tests that pin the old form. Catching them at plan-review time costs minutes; catching them at exec time costs a re-plan or a test-file edit.

Identified in Task 147 retrospective (j-retrospective.md § Recommendations).

## Task: Migrate cross-doc references to canonical style

### Task-Type: chore
### Priority: Low
### Identified in: Task 151 g-testing-exec.md

Task 151 audit identified ~7,964 cross-doc references that diverge from the canonical rules now in `docs/conventions/cross-doc-references.md`. This entry tracks the migration. **Migration is not in scope for task 151** — discovery and standard-setting only; the rewrite is here.

**Scope (per locality)**:

```markdown
| Divergence category                                | Count | Target form                                  |
|----------------------------------------------------|-------|----------------------------------------------|
| plain-prose × path (intra-repo)                    | 5,616 | inline-backtick × path                       |
| plain-prose × path (intra-task)                    | 2,128 | inline-backtick × path                       |
| plain-prose × in-file-anchor                       |   134 | markdown-link × in-file-anchor               |
| plain-prose × path:line and path:line-range        |    36 | inline-backtick × {path:line, line-range}    |
| inline-backtick × in-file-anchor                   |    20 | markdown-link × in-file-anchor               |
| bold × in-file-anchor                              |    16 | markdown-link × in-file-anchor               |
| inline-backtick × external-url (non-template)      |  ≤ 14 | markdown-link × external-url                 |
| Total                                              | ~7,964|                                              |
```

**Top-10 files by divergence count**:

```markdown
| file                                                                                | divergent rows |
|-------------------------------------------------------------------------------------|----------------|
| .cwf/docs/workflow/workflow-steps.md                                                |            184 |
| CLAUDE.md                                                                           |            113 |
| .cwf/docs/skills/security-review.md                                                 |             71 |
| implementation-guide/151-discovery-consolidate-cross-doc-reference-patterns/d-implementation-plan.md |             49 |
| implementation-guide/151-discovery-consolidate-cross-doc-reference-patterns/c-design-plan.md |             47 |
| .cwf/templates/pool/d-implementation-plan.md                                        |             39 |
| .claude/skills/cwf-implementation-plan/SKILL.md                                     |             36 |
| implementation-guide/151-discovery-consolidate-cross-doc-reference-patterns/b-requirements-plan.md |             35 |
| .claude/skills/cwf-design-plan/SKILL.md                                             |             34 |
| implementation-guide/151-discovery-consolidate-cross-doc-reference-patterns/a-task-plan.md |             32 |
```

**Dogfooding result against `docs/conventions/commit-messages.md`** (per Task 151 AC7): 0 mismatches. The 7 references in that file match the new rules.

**Constraints on the migration**:
- Templates (`.cwf/templates/pool/*.md`) and skill bodies (`.claude/skills/**/*.md`, `.claude/agents/**/*.md`) are LLM-facing and load-bearing. Migration of these must be tested for LLM-attention regression after each batch.
- Historic files (`BACKLOG.md`, `CHANGELOG.md`) are exempt per the carve-out in `docs/conventions/cross-doc-references.md`.
- The migration should be staged: convention docs first (small, verifiable), then wf-step templates (LLM-attention regression risk), then helper-script docs, then individual task wf-step files (large volume, low risk per file).
- A re-run of Task 151's `audit.pl` should serve as the verification gate: divergence count should drop monotonically with each migration commit, ending at ≤ 100 (residual: bold × path skill-header idiom, ambiguous narrative-vs-reference cases, and any template carve-outs).

Audit script preserved at: `implementation-guide/151-discovery-consolidate-cross-doc-reference-patterns/f-implementation-exec.md` (## Audit Script Source section).

## Task: Promote sleep 1 && git prefix to a referenced convention doc

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 152
### Identified in: Task 152 c-design-plan.md §Decision 3, §Follow-ups

Promote the `sleep 1 && git` prefix convention from MEMORY.md/global CLAUDE.md (both maintainer-local) into a referenced convention doc under `.cwf/docs/conventions/` (e.g. `sleep-git-prefix.md`) so installed skills can reference one place instead of copy-pasting the rule. Task 152 was the first wf doc to bake the convention into installed wording other adopters will see; `retrospective-extras.md` Step 12 currently restates the scope inline. Rule scope (carry over verbatim to the new doc): the prefix applies only to (a) Bash-tool calls that invoke `git`, and (b) suggested user-facing `git ff` merge commands — both because Claude Code spawns a background `git` that briefly holds `.git/index.lock`. Naming must always include `git` (never `sleep 1 && convention`); the rule does NOT apply to non-git Bash calls. After the convention doc lands, edit `retrospective-extras.md` to reference it rather than restate it.

## Task: Single source of truth for the canonical PERL5OPT value (-CDSLA)

### Task-Type: chore
### Priority: Low
### Identified in: Task 153

The canonical PERL5OPT value `-CDSLA` is duplicated across several surfaces: `INSTALL.md`, `docs/conventions/perl.md`, `.claude/skills/cwf-init/SKILL.md`, the `check_perl5opt` warning in `.cwf/lib/CWF/Common.pm`, and now the `$CANONICAL_PERL5OPT` constant in `.cwf/scripts/command-helpers/cwf-claude-settings-merge` (Task 153). A change to the value (as in Task 137/139, `-CDSL` → `-CDSLA`) must be made in every place by hand.

Consider a single source of truth — e.g. the helper constant becomes the authority and the docs reference it, or a small shared data point read by `check_perl5opt` and the merge helper. Scope discipline: Task 153 deliberately did not build this (the bug there was setting *location*, not value duplication). Low priority — the value changes rarely.

## Task: Clarify _score_progress: rename misleading $percentage param and delete stale bell-curve comment

### Task-Type: chore
### Priority: Low
### Identified in: Task 157 j-retrospective.md (Future Work)

Clarity-only, no behaviour change. The `_score_progress` sub in `.cwf/lib/CWF/TaskContextInference.pm` is correct but reads like a bug in isolation, which led to a mis-filed bugfix (retired in Task 157).

Two edits:
1. Rename the parameter `$percentage` (`:447`) to a work-potential name (e.g. `$work_potential`). It does not receive raw completion — `_get_progress_signal` feeds it `_calculate_task_progress` (`:488`), which returns the post-cliff `state_achievable` value. The name is the root of the misread.
2. Delete the stale comment `# Score tasks by progress (bell curve, peak at 50%)` (`:410`) in `_get_progress_signal`. There is no bell curve; the cliff in `state_achievable` (`TaskState.pm:150`) plus the linear ramp govern. The comment inside `_score_progress` (`:450-452`) is already accurate and should be kept.

`TaskContextInference.pm` is hash-tracked (`.cwf/security/script-hashes.json`), so the change requires a same-commit `script-hashes.json` refresh (hash-updates convention). Verify no behaviour change: existing TaskContextInference tests should pass unchanged.

## Task: Align cwf-extract skill and template-engine extraction guidance to grep+read

### Task-Type: chore
### Priority: Low
### Identified in: Task 160

Task 160 replaced sed-based section-extraction guidance in COMMANDS.md and DESIGN.md with grep+read. But the actual extraction mechanism elsewhere still uses an awk one-liner: .claude/skills/cwf-extract/SKILL.md:48 (awk "/^## {section-name}/{p=1; print; next} p && /^## [^#]/{p=0} p" {file-path}). (The template-engine.md design doc that also prescribed this awk command was retired in Task 197; SKILL.md:48 is now the sole awk site.) The user-facing docs now describe grep+read while the implementing skill describes awk. Decide whether to converge the skill on grep+read (matching the docs and the no-sed-line-range-reads tool preference, avoiding a Bash awk invocation) or to re-document the docs back to awk, then apply consistently. SKILL.md is hash-tracked, so a skill change needs a same-commit script-hashes.json refresh.

## Task: Fresh-session end-to-end corroboration of the cwf-review verdict container

### Task-Type: chore
### Priority: Low
### Identified in: Task 162 retrospective (j-retrospective.md)

Task 162 fixed the security-review misclassification at the parser level (security-review-classify; deterministic unit suite green). The live end-to-end check could not run in the editing session because agent definitions are loaded at session start, so the live subagent exercised the old contract. In a FRESH session, re-run cwf-security-reviewer-changeset (new definition) against bucket-B changesets (e.g. Tasks 140/142/143/158) and confirm: (a) the subagent ends its response with a cwf-review block, (b) clean reviews classify no findings via the helper, and (c) the SubagentStop guard fires (blocks) when the block is absent. Corroboration only — not a code change unless a discrepancy is found.

Additional evidence (Task 163): both exec-phase reviews (f-implementation-exec.md, g-testing-exec.md "## Security Review") classified `error` because the subagent omitted the cwf-review block on otherwise-clean verdicts — two more negative data points consistent with the session-cached-definition hypothesis. Worth prioritising; reference Task 163's f/g sections alongside the bucket-B set.

## Task: Reclassify rules-inject.txt as consumer-owned; add seed-once artefact strategy

### Task-Type: chore
### Priority: Medium
### Identified in: Task 167 (downstream bug report — manifest SHA drift discovered the underlying ownership-model confusion)

`.cwf/rules-inject.txt` is currently subtree-shipped and modelled as CWF-owned (apply-artefacts `replace` strategy), but its content — project-specific recurring-process-errors guidance — is naturally consumer-customisable. The original Task-99 intent ("we ship one canonical list, consumers receive it on update") conflicts with the real use case ("each project has different recurring errors and should configure their own").

Reclassify `.cwf/rules-inject.txt` as **consumer-owned, seeded-once**:

- Ship the suggested baseline at a clearly CWF-owned path (e.g. `.cwf/templates/rules-inject.suggested.txt`).
- `/cwf-init` seeds `.cwf/rules-inject.txt` from the suggested baseline only if the dest does not already exist.
- `cwf-manage update` never touches `.cwf/rules-inject.txt`.
- Add a `seed-once` strategy to `cwf-apply-artefacts` for this and any future similarly-owned files (joins the existing club of `BACKLOG.md`, `CHANGELOG.md`, `cwf-project.json`, the `implementation-guide/` tree).
- Optionally provide `cwf-manage diff-rules-inject` so consumers can see when the suggested baseline drifts upstream and choose whether to adopt — no automation, no prompt.
- Remove `.cwf/rules-inject.txt` from the `.cwf/` subtree shipping path (move the suggested baseline out of any subtree-tracked location, or scope subtree pulls to exclude it) so the file stops creating subtree merge cliffs at update time.
- Update Task-99 `i-maintenance.md` to reflect the new ownership: maintainers update the *suggested* baseline; consumers own the active file.

**Depends on** the High-priority bugfix "install manifest baselines disagree with subtree" landing first — that bug must be resolved before the rules-inject manifest entry can be cleanly removed.

**Why now (Medium, not High)**: the immediate consumer-blocking symptom (every update conflicts) is the High bug's surface. This chore fixes the underlying ownership-model confusion so the class of bug cannot recur in a different form, but it is not itself a regression — consumers can be unblocked first.

## Task: Restore CWF_UPGRADE_RESOLVE keep/new coverage without rules-inject

### Task-Type: chore
### Priority: Low
### Identified in: task-167

Task 167 removed `rules-inject` from the install-manifest inventory. The
existing `TC-FR5-KEEP` and `TC-FR5-NEW` subtests in `t/cwf-apply-artefacts.t`
used `rules-inject` as the conflict surface for `CWF_UPGRADE_RESOLVE=keep|new`
behaviour against the `apply_replace` strategy; both subtests were retired
because the rules-inject artefact id no longer exists in the inventory and
the synthetic-manifest fixture path would be rejected by the path-allowlist
validator.

`TC-FR5-INVALID` (env-var sanity) survives unchanged. The runtime branches
of `prompt_resolve` for `keep` and `new` are now exercised indirectly when
`apply_embedded_block` or `apply_tree_replace` hit a conflict, but no direct
artefact-level subtest covers them.

Restore the explicit coverage:

- Add `TC-FR5-KEEP` and `TC-FR5-NEW` against `cwf-rules-bundle`
  (tree-replace path — `apply_tree_replace` calls `prompt_resolve` at
  the same shape as `apply_replace` did), OR
- Add them against `claude-md-preamble` (embedded-block path —
  `apply_embedded_block` likewise).

Tree-replace is the closer functional analogue (per-file content conflict
on a real artefact). Embedded-block is fine if simpler fixtures are
preferred. Either keeps `prompt_resolve`'s keep/new branches directly
covered.

This is **Low** because the underlying machinery is exercised by other
integration tests (the function is called from three strategies) and the
runtime hasn't lost behaviour — only direct test coverage. No consumer
impact.

## Task: README skill-list drift guard (documented vs shipped /cwf-* set)

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 169
### Identified in: Task 169 retrospective (j-retrospective.md)

README's documented command/skill reference drifted from the shipped surface for 62 tasks (last touched Task 106) before Task 169 resynced it. There is no mechanical gate tying the documented `/cwf-*` set to the shipped `.claude/skills/cwf-*` set, so this class of drift recurs silently.

Consider a lightweight check (linter or test) asserting README's documented `/cwf-*` skill set equals the shipped skill set, with the known carve-outs (`cwf-manage` is a script not a skill; `cwf-project` is a `cwf-project.json` false positive; `test-cwf-skill` is a fixture). Optionally extend to task types (vs `cwf-project.json:supported-task-types`).

Open question (why this is a candidate, not a commitment): whether the maintenance cost and false-positive surface of a new gate is worth it for a doc that changes rarely. Decide in the task's planning phase. Could fold into the existing "Skill Cross-Reference Linter" item rather than standing alone.

Identified in: Task 169 retrospective (j-retrospective.md).

## Task: Retire remaining vestigial version fields (cwf-version, security.version-tracking)

### Task-Type: chore
### Priority: Low
### Identified in: Task 188 (j-retrospective.md §Future Work)

Task 188 retired the top-level `version` field strictly-narrow. The identical vestigial-version pattern remains: the template still ships `cwf-version` + `_cwf-version-note`, and the live config still carries `security.version-tracking`. Before retiring, run the same bare-string + spec sweep Task 188 used (Step 1) — note `CWF-PROJECT-SPEC.md` documents `cwf-version` as a *required* field, so retiring it means updating the spec too; confirm zero code readers first. `cwf-version` may be load-bearing in a way `version` was not (it states the targeted CWF system version), so verify before deleting. Update template, live config, and spec together; add/extend the guard test.

## Task: fix-security TC-8 asserts a 0444 floor that contradicts the recorded-perms ceiling model

### Task-Type: bugfix
### Priority: Low
### Identified in: Task 188 (g-testing-exec.md TC-4, j-retrospective.md §Future Work)

`t/cwf-manage-fix-security.t` TC-8 ("drift pin") asserts each `.claude/agents/*.md` satisfies a *floor* of 0444 (perms >= recorded). But Task 170 made recorded perms a *ceiling* (`cwf-manage validate` passes when actual ⊆ recorded), and git only tracks the executable bit, so on any clean checkout these files sit at 0400/umask — `validate` is content (0400 ⊆ 0444) yet TC-8 fails. Result: the full suite is not green on a fresh tree. Reconcile by asserting the ceiling (actual ⊆ recorded) rather than a floor, or by changing the expectation/recorded value. Entangled with the existing perm cluster: "Make cwf-plan-reviewer-misalignment.md enforced-permission survive git checkout" and "Enforce recorded permissions as upper bound" (Task 170). Pre-existing; not introduced by Task 188 (verified by stashing and re-running on baseline 13840c5).

## Task: Prune vestigial blocks from the live implementation-guide/cwf-project.json

### Task-Type: chore
### Priority: Medium
### Identified in: Task 189 d-implementation-plan.md (Deferred to BACKLOG)

The live implementation-guide/cwf-project.json carries dead schema. Its templates block lists old plan.md and implementation.md filenames that are unused, since template-copier sources per-type file sets from CWF::WorkflowFiles::V21 %WORKFLOW_FILES rather than the config. Its security.canonical-source holds OWNER/REPO placeholders. Prune or correct these blocks so the live config no longer advertises schema the system ignores. Found during Task 189 docs-sync planning while grounding CWF-PROJECT-SPEC.md against the real schema.

## Task: Extend BACKLOG-000 structural contract to CHANGELOG.md (KD5 parity)

### Task-Type: feature
### Priority: Medium
### Identified in: Task 190

Task 190 added a generic intro-region structural predicate (CWF::Backlog::backlog_structure_errors, @EXPORT_OK) but wired it only into the BACKLOG validate/mutation path. The helper is format-agnostic. Extend the identical scan to CHANGELOG.md so a foreign-format CHANGELOG is rejected up front rather than mis-managed by retire. Security note: if a future CHANGELOG message ever cites verbatim offending-line text, the FR4(c) no-verbatim-echo surface reopens — apply NFR2 control-char-stripping/length-bounding then. TC-7 backstops only the BACKLOG path today.

Concrete evidence (found during Task 213): CHANGELOG.md already carries an orphaned entry — a full Status/Duration/Impact triplet (the `cwf-backlog-manager` cd-prefix / kernel-ENOENT self-anchoring cleanup) with no `## Task N:` heading of its own, so it is silently folded under the preceding `## Task 139` section. A CHANGELOG structural predicate (a `## Task N:` heading must precede each Status/Duration/Impact triplet) would reject exactly this. A real defect a contract scan would catch.

## Task: BACKLOG-000 accepted-boundary gaps: unterminated-leading-fence masking and headerless-legacy

### Task-Type: feature
### Priority: Low
### Identified in: Task 190

BACKLOG-000 has two documented fail-open boundaries (pinned by TC-8/TC-9, see cwf-backlog-manager.md): (1) an unterminated leading ``` fence masks all following foreign content to EOF, so foreign structure hidden under a never-closed fence is not flagged; (2) a preamble of pure prose with no headings/lists, and foreign content placed AFTER a genuine entry, are not detected. These are coverage gaps in a defensive check (fail-open grants no new capability), acceptable for v1 but worth tightening: e.g. treat an unterminated leading fence in a zero-entry file as itself a BACKLOG-000 signal. Low priority — no correctness or security impact, only completeness of the manageability assertion.

## Task: Embedded-block first-insert treated as conflict when CLAUDE.md lacks preamble markers

### Task-Type: bugfix
### Priority: Low
### Identified in: downstream v1.1.189 upgrade report

The install manifest ships a `claude-md-preamble` embedded-block artefact
(`install-manifest.json:25-33`) sourced from
`.cwf/templates/install/claude-md-preamble.md`, delimited by the
`CWF-PREAMBLE-START` / `CWF-PREAMBLE-END` HTML-comment markers in the
consumer's root `CLAUDE.md`. On a v1.1.189 upgrade of an install whose
`CLAUDE.md` lacked those markers, `apply_embedded_block` treated the absent
block as a **conflict** requiring `CWF_UPGRADE_RESOLVE=new`, rather than as a
clean first-time insert.

Arguable behaviour: the first introduction of an embedded block into a
marker-less container is unambiguous — there is nothing to overwrite, so it
should insert without demanding conflict resolution. Reserve the conflict path
for the case where markers exist and the enclosed content differs.

Investigate before changing: confirm exactly how `apply_embedded_block`
classifies a marker-less container (genuine conflict vs. defensive prompt), and
whether an auto-insert risks clobbering a hand-authored preamble that uses
different/no markers. If auto-insert is safe, gate it on "no start marker
present" and keep `CWF_UPGRADE_RESOLVE` for the markers-present-but-differ case.

Dog-fooding note: this source repo's own root `CLAUDE.md` carries no
`CWF-PREAMBLE` markers — we ship the block but do not consume it. Either adopt
the preamble here or document why the source is exempt; the current state means
the artefact's update path is never exercised against our own tree.

Related but distinct: `BACKLOG.md` already logs a `prompt_resolve` keep/new
*test-coverage* gap (Task: "Restore CWF_UPGRADE_RESOLVE keep/new coverage
without rules-inject"). That entry is about test fixtures; this one is about the
default classification of a first insert. Lower severity than the lock bug — a
documented env-var escape hatch exists.

Surfaced by a downstream v1.1.189 upgrade (reported as issue 2 of 2).

## Task: Confirm sandbox sets TMPDIR=/tmp/claude and verify denial (Task 199 FR7/D2)

### Task-Type: chore
### Priority: Medium
### Status: Follow-up from Task 199 (BLOCKED-ENV: unsandboxed dev session)
### Identified in: Task 199 g-testing-exec.md, j-retrospective.md §Future Work

Task 199 re-rooted the per-task scratch convention to `${TMPDIR:-/tmp}` so it lands under the sandbox temp root. Two checks could not run in the unsandboxed dev session (confirmed unsandboxed: bare-`/tmp` write allowed, `TMPDIR` unset) and are BLOCKED-ENV:

1. **D2 pivot fact** — confirm an active sandbox sets `TMPDIR=/tmp/claude`. Repro: in a fresh sandboxed session, `echo "$TMPDIR"`. Supporting evidence it is set: `/tmp/claude/go-build` exists (Go test/build temp keys off `$TMPDIR`).
2. **FR7 denial enforcement** — a bare `/tmp/x` write is denied and `/tmp/claude/x` permitted. Repro: in a sandboxed session, `mkdir /tmp/x` (expect deny) vs `mkdir /tmp/claude/x` (expect allow); then run `.cwf/scripts/command-helpers/security-review-changeset --wf-step=implementation-exec` and confirm its `.out` lands under `/tmp/claude/...`.

Resolution rule (from Task 199 FR4 AC(ii)/(iii)): if `TMPDIR` is **set** (expected) the class-(c) default-location `File::Temp`/`tempdir` sites (`cwf-apply-artefacts:647-648`, `cwf-manage:490`) are disposition (ii) — already safe, no code change. If **unset**, fix class-(c): export `TMPDIR` into those helpers' env or pin `DIR` to a `/tmp/claude` subdir. Record the disposition and close either way. Distinct from the Task-178 CWF-managed sandbox-config feature (that writes sandbox settings; this conforms our paths).

## Task: Seed CWF's own bash tool-check rules (checked-in layer)

### Task-Type: chore
### Priority: Medium
### Status: Follow-up from Task 201 (j-retrospective.md §Future Work)
### Identified in: Task 201 h-rollout.md (Phase 3, deferred), j-retrospective.md §Future Work

Task 201 shipped the bash tool-check *mechanism* inert (empty default ruleset). It deliberately did not seed the checked-in layer (`.cwf/tool-check/bash/settings.json`) with rules for this repo, because the set of commands that trip Claude Code's permission prompts shifts per model and per Claude Code version, so a fixed shipped set would be wrong by construction.

Scope: author a starter rule pack for CWF's own development, targeting the recurring offenders already documented in MEMORY.md feedback (e.g. `sed -n` line-range reads, `find`, `tee`, inline `perl -e`/heredocs, `git -C`, `echo "EXIT: $?"`). Regex-only — the checked-in layer drops `perl` rules before compilation by design. Re-evaluate the pack whenever the session model or Claude Code version changes; treat it as living config, not a one-off.

**Update (Task 220)**: the *seeding mechanism* now exists — `tool-check-seed seed` merges an embedded regex-only starter set (currently `sed -n`, `cat|grep`, `find -exec`) into the checked-in layer, exposed via `/cwf-config tool-check seed` and the `/cwf-init` opt-in. Task 220's h-phase settled the **rollout decision for *this* repo: declined for now** — ship the mechanism only, do not commit a checked-in starter set here (the maintainer already runs a richer user-global set, so the marginal value is low). This item therefore stays open as the standing adoption decision: revisit whether to commit a checked-in pack for CWF's own development and, if so, whether to widen the embedded pack to the fuller offender list above.

Use `--check` to preview the merged effective set before committing the pack.

## Task: Migrate CWF::TaskPath::branch_exists off backtick/--list-glob to list-form run_quiet

### Task-Type: bugfix
### Priority: Low
### Status: Follow-up from Task 202
### Identified in: Task 202 retrospective (j-retrospective.md)

`CWF::TaskPath::branch_exists` (`TaskPath.pm`) checks branch existence with a
backtick, shell-interpolated `git branch --list '$branch'`. This has two
weaknesses: (1) the single-quote wrapping breaks on a branch name containing an
embedded `'`, and is shell-interpolated rather than list-form; (2) `--list` is a
glob, so it can false-positive on a prefix-collision sibling (`feature/1-foo`
matching a query for `feature/1-foobar`).

It is safe at its current callsites only because the branch names there are
constrained. Task 202 deliberately did **not** reuse it for its new existence
guard, instead establishing the list-form `run_quiet('git','rev-parse','--verify',
'--quiet',"refs/heads/$branch")` + exact-match pattern (now in `CWF::Common`).

Scope: migrate `branch_exists` onto the list-form `run_quiet` + `rev-parse
--verify` shape, OR — if no caller ever feeds it a less-trusted name — document it
as a deliberately-constrained-input helper. This is a watch-item, not a forced
rewrite; act when a future caller would pass a name derived from less-trusted
input. Both Task 202 exec-phase security reviews flagged it as a safe-here pattern
to audit on reuse.

## Task: Add reviewer-concurrency decision to the design-phase checklist

### Task-Type: chore
### Priority: Low
### Identified in: Task 205 retrospective (j-retrospective.md)

When a design introduces a new reviewer/agent, the design phase must explicitly decide its concurrency: parallel peer in the existing MAP (default) vs a serial step, with any serialisation justified by a strict output→input data dependency (fast deterministic helpers feeding agent inputs do not count). Task 205 designed exec best-practice as a serial second step; it had to be restructured to a parallel peer during exec after explicit user direction. Codify as a checklist item (candidate home: docs/conventions/design-alignment.md) so the decision is made before code. Durable principle already in memory feedback-reviewers-parallel.

## Task: Hoist shared cwf-review verdict block into agent-shared-rules and de-dup the five changeset reviewers

### Task-Type: chore
### Priority: Low
### Identified in: Task 210

The `cwf-review` verdict block is now inlined byte-identically across five
changeset reviewer agents (security, best-practice, improvements, robustness,
misalignment). Agent `.md` files have no include mechanism, so the shared body
is copied. Consider hoisting the shared Verdict block (and the "Bash is
intentionally withheld" paragraph) into `cwf-agent-shared-rules.md` and having
each agent reference it, then de-dup the five changeset reviewers. Deferred from
Task 210 to keep that task scoped (the hoist would force re-hashing the two
pre-existing changeset agents and editing the hash-tracked shared-rules doc).

## Task: Best-practice resolver: relevance, output format, and live-agent verification

### Task-Type: discovery
### Priority: Low
### Identified in: Tasks 205, 207, 208, 209 retrospectives; consolidated in Task 212 backlog audit

Consolidates three related concerns about the best-practice resolver and its reviewer
agents. Scope: investigation first; no behaviour change until the relevance question is
settled. Low risk — findings are advisory and never gate the workflow.

1. Relevance. `best-practice-resolve` tag-matches off-domain corpora (the standing
   `golang` / `postgres` tags) for CWF's own Perl/Markdown/JSON changes, so every
   CWF-internal task spends two agent rounds producing "no supplied practice applies"
   verdicts. Decide whether matching should consider the task's actual language/artefact
   surface, or whether this is purely a user-config concern (a narrower active-tag set or
   a per-task tag override so the resolver returns 0 matches and skips the reviewer).
   Surfaced in Tasks 207, 208, 209 — and again in Task 212's own plan-review, where
   golang/postgres matched a Markdown audit chore.

2. Output format. The resolver's `.out` format (a `- <tags>: <path>` list) does not match
   the `### DOCS` `file:`/`dir:` shape the reviewer agent definitions document. The agents
   cope by enumerating directories directly, but the mismatch is undocumented. Align the
   resolver output with the `### DOCS` shape, or update the agent definitions to the actual
   format.

3. Live-agent verification. This repo ships no best-practices.json fixture with matching
   docs, so only the 0-match (no-op) branch is exercised end-to-end; the populated path is
   covered by unit tests but never by a live agent run, and Task 207's agent-definition
   edits are session-cached. In a FRESH session, exercise the reviewer in a consuming or
   throwaway fixture repo with a real best-practices.json over file and directory pointers
   and confirm: (a) both reviewer agents have no WebFetch and Read the listed sources
   directly; (b) the exec changeset reviewer emits the fail-closed `error` when a listed
   source is unreadable; (c) the planning plan-review column and the exec changeset
   reviewer emit sensible findings.

## Task: Branding cleanup: CWF to CwF rebrand and retire residual CIG naming

### Task-Type: chore
### Priority: Low
### Identified in: Tasks 184, 189; consolidated in Task 212 backlog audit

Two related branding sweeps over the codebase, best done as one coordinated pass with a
single output-level smoke test (source-grep alone is insufficient, per the
rebrand-smoke-test process memory). Both exclude immutable history (implementation-guide/*
task docs, retired CHANGELOG entries).

1. TLA case. The canonical three-letter abbreviation is currently all-caps "CWF" across
   glossary.md, README.md, CLAUDE.md, .cwf/docs, .cwf/templates, skills, agent defs, and
   committed CHANGELOG entries; the intended branding is mixed-case "CwF" (pre-existing
   drift, noticed Task 184). Sweep all production artefacts replacing the standalone TLA
   "CWF" with "CwF", and update the glossary Abbrev definition and pronunciation note.

2. Pre-rebrand "CIG" name. Code and POD under `.cwf/scripts/` and `.cwf/lib/` still carry
   the pre-rebrand "CIG" name: "CIG System" author tags in several Perl POD blocks
   (StatusAggregator/Core.pm, WorkflowFiles/V20.pm and V21.pm, TaskState.pm,
   TemplateCopier/Core.pm, ContextInheritance/Core.pm, Options.pm, Common.pm), "CIG
   tasks/scripts" in template-copier comments and POD, CIG_SOFTWARE_VERSION in
   context-manager.d/version, and "CIG Migration" banners in migrate-v1-to-v2.sh /
   rollback-migration.sh. Cosmetic only. These are hash-tracked files, so the in-task hash
   refresh per `.cwf/docs/conventions/hash-updates.md` applies.

## Task: Best-practice tags should trigger on task content, not blanket active-tags

### Task-Type: feature
### Priority: Medium
### Identified in: Task 213 plan review (d-implementation-plan plan-review MAP)

`best-practice-resolve` matches a best-practice entry whenever any of its tags is in `T = active-tags ∪ the task's manual **Tags** line`, with **no inspection of what content the task actually touches**. So globally-active tags fire the best-practice reviewer on every task regardless of subject. Observed during Task 213 plan review: a Perl-only CWF task matched both `golang` and `postgres` purely from the user-global `~/.cwf/best-practices.json` `active-tags: ["golang","postgres"]`; the 5th reviewer ran and correctly self-no-op'd, but it should not have been launched at all.

Intended behaviour: a tag contributes to the match set only when the task actually authors/modifies content matching that tag (e.g. a `golang` tag fires only when the change touches Go content), not as a blanket always-on union.

Design surface (why this is a feature, not a one-liner):
- A tag/entry needs a **content-matcher** (file extensions? shebang? per-tag content regex?) — a `best-practices.json` schema addition + migration. This is the crux decision.
- **Plan-time vs exec-time differ**: at plan-review time there is no diff yet, so triggering must infer from the plan's stated scope (e.g. "Files to Modify") — a softer heuristic; at exec/changeset time there is a real diff to scan for matching content. Likely two mechanisms.
- **Security (FR4)**: scanning file/diff contents against tag matchers is an untrusted-content surface — bound/strip as per existing conventions.
- Backward-compatible default: with no content-matcher configured, preserve today's tag-union behaviour (fail-open), so existing configs keep working.

Keep the `active-tags` union escape hatch for users who genuinely want a tag always on; content-triggering is the additive, opt-in refinement.

## Task: workflow-manager status aggregate percentage weighting

### Task-Type: bugfix
### Priority: Low
### Identified in: Task 222 retrospective (j-retrospective.md)

With phases a–i all Finished and only j outstanding, `workflow-manager status <n> --workflow` reported the task aggregate as 25%. The per-phase percentages are correct (each 100%) but the roll-up weighting is unintuitive and could mislead a status sweep into thinking a near-complete task is barely started. Investigate the aggregation in the status roll-up (likely primary-path weighting), confirm intended semantics, and either fix the weighting or document why it reads this way. Correctness-of-display only; no functional impact. Identified in Task 222 retrospective.

## Task: template-copier reads snake_case directory_structure.base_path (latent bug)

### Task-Type: bugfix
### Priority: Low
### Identified in: Task 223

template-copier-v2.1:194 reads $config->{directory_structure}{base_path}, but the config key is the kebab-case directory-structure.base-path. It never matches, so a project with a non-default base-path silently gets the implementation-guide default. Task 223 added doc_pathspec() which reads the correct kebab key; the copier remains on the wrong one. Fix: read the kebab key (and consider a shared accessor).

## Task: Shared cached config read in security-review-changeset

### Task-Type: chore
### Priority: Very Low
### Identified in: Task 223

The helper now has three independent CWF::Versioning::read_config() sites (max_lines_exclude_paths, config_max_lines, doc_pathspec) plus the fallback-anchor path. A single memoised/cached read would remove the duplication. Out of scope for Task 223 (each site is already eval-guarded and correct).

## Task: Make CwF aware that sandbox null-routing pollutes git status

### Task-Type: chore
### Priority: Medium
### Identified in: Task 224 kickoff

Sandboxes commonly "null route" sensitive config files to limit the blast radius of a
sandboxed agent — bind-mounting `/dev/null` over a config filename/filepath (or using an
equivalent mapping method) so the agent can neither read nor write the real file. A
side effect is that these mapped paths surface inside the working tree, where `git status`
reports them as untracked entries.

Observed at Task 224 kickoff: `git status` in the repo root listed `.bashrc`,
`.bash_profile`, `.profile`, `.zshrc`, `.zprofile`, `.gitconfig`, `.ripgreprc`,
`.gitmodules`, `.idea/`, `.vscode/`, `.mcp.json`, and `.claude/{hooks,launch.json,routines,workflows}`
as untracked. None are stray files; all are sandbox artefacts. `stat(1)` reports every one
as a character special file, not a regular file, confirming the bind mount.

CwF is currently unaware of this. Consequences:

- **False positives.** The standing "run `git status` before every commit" rule makes an
  agent inspect untracked files. Sandbox artefacts read as unexplained stray files, so the
  agent raises a spurious warning and burns turns investigating (this happened at Task 224).
- **Commit hazard.** A blanket `git add -A` would stage `/dev/null`-backed entries.
- **Detection surfaces.** Any helper or skill that reasons about working-tree cleanliness
  (checkpoint commit, status sweep, changeset diffing) may draw wrong conclusions.

Scope to settle at kickoff:

- Where the knowledge lives: a sandboxing limitations doc (see the pending Task-178-seeded
  sandboxing feature decisions, which already call for an explicit advises-not-enforces
  limitations doc) versus a standalone convention.
- Whether the wf step skills / commit helpers should recognise and ignore null-routed
  entries, and how to identify one reliably (stat the path; a bind-mounted `/dev/null` is a
  character device, not a regular file — detection by content/type, not by filename, per the
  "filenames are not classifications" rule).
- Whether `cwf-init` should seed `.gitignore` entries, and the tradeoff: an ignore rule hides
  a genuinely stray file of the same name, so detection-by-type is likely preferable to
  ignore-by-name.
- Non-goal: defeating or working around the sandbox. The mapping is a security control; CwF
  should understand it, not route around it.

## Task: Doc-drift check when a task changes an enforced shape

### Task-Type: chore
### Priority: Medium
### Status: Follow-up from Task 224
### Identified in: Task 224 j-retrospective.md §What Could Be Improved

When a task changes a shipped behaviour or a required shape, the docs that *teach* that
shape are not automatically part of the changeset, and nothing checks them.

Task 204 fixed `cwf-claude-settings-merge` to emit `${CLAUDE_PROJECT_DIR}/`-rooted hook
commands, but left `.cwf/docs/workflow/stop-hooks-framework.md` documenting the
bare-relative form. That example sat wrong for roughly a year. An operator hand-registering
a hook from it would have reproduced the exact fail-open the task had just closed. Task 224
found it only because it went looking.

This is the same class as the existing "rebrands need output-level smoke-test" rule:
source-level correctness is not documentation correctness, and a clean grep of the code
proves nothing about the prose.

Scope to investigate:

1. A plan-time prompt (or a `plan-mechanical-check` extension) that asks: does this task
   change a shape, path, or invariant that any doc, template, or skill demonstrates? If so,
   name the files and grep them for the old shape.
2. Whether the check can be made mechanical for the narrow, high-value case of *registration
   examples* — fenced JSON blocks under `.cwf/docs/` containing a `"command":` key — since
   those are executable-shaped and drift silently.

Explicit non-goal: a general documentation linter. The value is in the narrow case where a
doc teaches a shape that code elsewhere enforces.

## Task: plan-mechanical-check false-positives on path:line references

### Task-Type: bugfix
### Priority: Low
### Identified in: Task 225 design-phase plan review (c-design-plan.md)

`plan-mechanical-check` flags valid `path:line` references as broken paths.

Two independent defects in the path check, both confirmed against source:

1. **No `:NN` strip before the existence test.** `path_check()` strips a trailing
   markdown anchor (`plan-mechanical-check:193`, `s/#.*$//`) but never strips a
   trailing line-number suffix. The token `docs/conventions/design-alignment.md:46`
   is therefore probed verbatim with `-e`, always fails, and is reported as
   `path-advisory` even though both the file and the cited line exist.

2. **Selector silently skips bare `file.ext:NN` tokens.** `extract_path_tokens()`
   requires a `/` in the token (`plan-mechanical-check:226`,
   `next unless $t =~ m{/}`). So `TaskState.pm:99` is never checked at all, while
   `docs/conventions/design-alignment.md:46` is checked and false-positives. The
   two defects mask each other: only *some* line-anchored references misfire, which
   is why this has gone unnoticed.

This matters because `path:line` is CWF's own documented cross-doc convention
(`docs/conventions/cross-doc-references.md`) and the clickable form the harness
expects. The checker systematically false-positives on the most idiomatic way to
cite a location, and systematically under-checks the other idiomatic form.

**Severity is bounded, deliberately.** The finding is emitted in the `path-advisory`
tier, the helper's own preamble says findings are "a net, not a proof", and the gate
never blocks. It is misfiring *inside* its stated contract, not breaking it. That is
why this is Low rather than higher.

**Likely fix**: strip `/:\d+$/` from the probe token alongside the existing anchor
strip, and widen the selector so bare `file.ext:NN` references are candidates too.
Guard against the obvious over-strip — a real path may legitimately end in a colon
and digits — by only stripping when the residue resolves.

Observed during Task 225's design-phase plan review, where the design plan's
reference to `docs/conventions/design-alignment.md:46` was reported as a
non-existent path. Out of scope for Task 225, which should not absorb it.

## Task: Gate j-phase squash on child branch merged-ness (Finished does not imply merged)

### Task-Type: bugfix
### Priority: Medium
### Status: Follow-up from Task 225
### Identified in: Task 225 design phase (c-design-plan.md) and retrospective

Task 225 gates exec-and-later phases on child *status* (Finished/Skipped/Cancelled). That makes the reported squash-stranding unreachable only if Finished children have actually been merged into the parent branch. A child can today be Finished and unmerged, in which case `j` still squashes the parent and rewrites the base the child branched from — the exact failure Task 225 was opened for.

Scope: add a git-ancestry invariant to the `j` chokepoint (`checkpoints-branch-manager create`), asserting each Finished child branch is an ancestor of the parent tip before the `git reset --soft`.

`CWF::TaskPath::parent_branch_ancestry()` (`TaskPath.pm:536`) already exists and looks like the right primitive.

Open question the design must settle: policy for already-deleted child branches (a merged child whose branch was pruned has no ref to test).

Rationale for deferral: the Task 225 gate is a *status* invariant, testable purely against the file tree. Merged-ness is a *git* invariant needing branch resolution, ancestry checks, and the deleted-branch policy. Bundling them would have doubled the surface and delayed the fix for the common case.

## Task: Refactor tmp/working-dir handling for Claude Code sandbox compatibility (inside and outside sandbox)

### Task-Type: chore
### Priority: Medium
### Identified in: Task 225 tagging session

Refactor how CwF derives and uses per-task scratch / working directories so the scheme is coherent and correct in **both** execution contexts Claude Code presents: outside the sandbox (hooks run unsandboxed, `TMPDIR` unset → `/tmp`) and inside the Bash sandbox (`TMPDIR=/tmp/claude-1000`, `/tmp` read-only except allowlisted paths). Today the handling is spread across scripts, hooks, docs and the tmp-paths convention, and the two contexts disagree on the actual path.

**Root friction (Task 215, [[reference-hook-sandbox-tmpdir-asymmetry]]):** the path-injection hook runs unsandboxed and emits a path under `/tmp`, while the Bash tool runs sandboxed and can only write under `/tmp/claude-1000`. The scratch base an agent is told to use and the base it can actually write can therefore differ. Task 215 patched the hook to probe a writable base; this item is the wider cleanup that convention, scripts and docs still need.

**Goal:** one canonical, single-source-of-truth derivation for the scratch path that resolves correctly regardless of sandbox state — honour `$TMPDIR` when set, fall back to `/tmp` — with every consumer (scripts, hooks, templates, docs) going through it, and the security guards intact in both contexts.

**Workstreams:**
1. Canonical path resolver — one helper/derivation that yields the right base inside and outside the sandbox; retire ad-hoc `/tmp` and bare-`$TMPDIR` assumptions at call sites (this session hit the `$TMPDIR`-lacks-project-slug trap directly).
2. Site audit — sweep every place that builds a tmp/working path (`.cwf/scripts`, hooks, conventions, templates, skill docs) and route them through the resolver; grep a generated artefact for stale bare-`/tmp` paths (output-level smoke test, not just source grep).
3. Guard integrity — confirm the mandatory two-level `mkdir -m 0700` guard and parent-symlink reject still hold under both contexts and both path variants.
4. Permissions / sandbox auto-registration (the original narrow item, now one component) — optionally register the scratch dir in the host repo's per-user `.claude/settings.local.json` at install and `cwf-manage update`, across two layers:
   - Layer 1 `permissions.additionalDirectories` — suppresses file-tool (Read/Edit/Write) prompts; a defined, tolerated schema key.
   - Layer 2 `sandbox.filesystem.allowWrite` — grants sandboxed Bash write; the harness accepts `sandbox` though SchemaStore does not define it. The sandbox may already permit the scratch dir depending on host defaults, so Layer 2 may be unnecessary — confirm per host.
   - Must be `settings.local.json` (per-user, gitignored), never the committed `settings.json`: the scratch path is derived from the *absolute* repo path plus `TMPDIR` prefix, so it differs per developer/machine, whereas the committed file is identical on every clone. The path cannot be made clone-stable — absolute-path derivation is the concurrent-checkout collision guarantee (two checkouts of one repo on one machine need distinct scratch dirs).
5. Docs/convention update — fold the outcome back into `.cwf/docs/conventions/tmp-paths.md` and the CLAUDE.md summary so the canonical form documents both contexts.

**Open risks / unknowns to resolve before design:**
- Two-writer contention on `settings.local.json` — it is harness-owned (rewritten on "always allow" grants and `/sandbox` selections). CwF's existing `cwf-claude-settings-merge` targets only `settings.json`; it does not cover racing the harness on the local file. Design for idempotent re-merge, treat harness-written keys as read-only.
- `additionalDirectories` takes concrete dirs, not globs, so both TMPDIR path variants may need enumerating.
- Widening no-prompt writes under world-writable `/tmp` touches the tmp-paths threat model — route Layer 1/2 through the security reviewer.
- Coupling — writing a permissions grant into a Claude Code config file couples CwF to the harness more than the Task 206 path hook does.

**Empirical tests owed (before relying on any of this):**
- Real harness behaviour for unknown keys and rewrite-on-grant in `settings.local.json`, on a throwaway copy. The earlier "an unknown key nukes the whole file" belief was traced to a stale memory and refuted against the current schema (`additionalProperties: true`; `sandbox` not even defined there). Behavioural GitHub-issue claims (#3481/#9234/#19487) remain unverified.
- Actual writable scratch base inside vs outside the sandbox on a target host, to validate the resolver.

**Payoff:** removes a recurring class of friction (wrong scratch base across the sandbox boundary, ad-hoc `/tmp` assumptions, and Write-tool permission prompts) rather than the narrow prompt-suppression the original item scoped. Judged Medium as it touches a foundational convention; not urgent, since scratch writes currently function.

## Task: Fix dangling challenge-requirements cross-reference for no-requirements-phase task types

### Task-Type: bugfix
### Priority: Low
### Identified in: Task 226 retrospective (j-retrospective.md)

Task 226 fenced "best part is no part" to the means in planning.md, pointing to "the requirements and implementation phases" for the fuller challenge-every-requirement discipline. That discipline text lives only in requirements.md, which bugfix/hotfix/chore tasks lack (no b phase). The maxim itself is still stated inline in planning.md for all types, so this is a dangling cross-reference, not a broken path.

Fix: either give bugfix/hotfix/chore a dedicated downstream home for the challenge-requirements discipline (e.g. in the implementation-phase docs), or soften planning.md's cross-reference so it does not point at a phase those types lack.

Low priority — cosmetic doc-consistency, no functional impact.
