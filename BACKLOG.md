# CWF System Backlog

Future tasks and improvements for the Coding with Files system.

## Task: Fix TC-VALIDATE structural false-failure for in-flight tasks

### Task-Type: bugfix
### Priority: Medium
### Status: Follow-up from Task 203 (j-retrospective.md §Future Work)
### Identified in: Task 203 g-testing-exec.md (Test Failures), j-retrospective.md §Future Work

`t/security-review-changeset.t` contains a subtest (TC-VALIDATE) that asserts the **live**
repo's `cwf-manage validate` exits 0. This assertion is red for **any** in-flight CWF task,
because every task's phase files legitimately carry placeholder statuses
("Planning"/"Requirements"/…) until that task's own pre-retrospective status sweep rewrites
them to terminal. The failure is therefore not a regression in whatever change is under
test — it is a property of running the suite mid-workflow — yet it costs real diagnostic
effort each time to confirm that (Task 203 spent that effort). Fix options: (a) scope the
assertion to a fixture/synthetic repo whose phase files are terminal, mirroring the existing
fixture-based `t/validate-workflow.t`; or (b) have the live-repo assertion tolerate the known
in-flight placeholder statuses (validate only the security/permission portions live, leaving
workflow-status checks to the fixture suite). Decide which surface is the right home for a
live-repo integrity assertion vs a fixture one. No production-code change to
`security-review-changeset` is implied.

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

## Task: Plan-time symbol-deletion reference sweep

### Task-Type: chore
### Priority: Medium
### Status: Follow-up from Task 174 (j-retrospective.md §Process Improvements)
### Identified in: Task 174 d-implementation-plan.md §Lessons Learned, j-retrospective.md

When a plan proposes deleting a named symbol (sub, constant, package var), grep the
whole repo for every reference and surface them as a plan-review finding. In Task 174
the plan source-grepped for the deleted `@CWF_INTERNAL_PREFIXES` but did not extend the
grep to *test assertions* on it, so two test files (`t/cwf-check-tree-symlinks.t`,
`t/install-bash-reinstall.t`) coupled to the constant surfaced only at exec. Symbol-
deletion impact is a mechanical dimension distinct from plan logic — complementary to
the existing "Plan-time helper-path verification gate" backlog item, and could share the
same plan-review pass. Scope: grep d-plan (and ideally c-plan) for symbols slated for
deletion, `grep` each across the repo, list references. Cheap; mechanical.

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

## Task: Plan-time helper-path verification gate

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 150
### Identified in: Task 150 j-retrospective.md §Recommendations / §What Could Be Improved

Add a plan-review pass (or a small helper invoked from the plan-review skill) that resolves any `.cwf/scripts/...` path referenced in a d-implementation-plan against the filesystem at plan time. Task 150's d-plan referenced `.cwf/scripts/command-helpers/cwf-manage`, but the actual helper lives at `.cwf/scripts/cwf-manage` (one level up). The plan-review subagents reviewed plan *logic* and missed the path-existence defect because helper-path verification is a separate dimension. Scope: grep d-plan for path patterns matching `.cwf/scripts/[^ ]+` (or similar), `test -x` each one, surface mismatches as a plan-review finding. Cheap; mechanical; complementary to the existing 4-subagent map/reduce. Optionally extend to b/c/d plan phases uniformly.

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

## Task: Quantitatively justify the security-review subagent line-count cap

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 127
### Approach: 
### Out of scope: changing the subagent prompt itself (covered by the existing "Tighten security-subagent prompt for sentinel-line compliance" follow-up). This task is purely about the threshold value.
### Identified in: Task 127 retrospective (j-retrospective.md § "What Could Be Improved")

The current 500-line cap on security-review subagent invocations (set in Task 123, applied across `.cwf/docs/skills/security-review.md` and the exec-phase skills) is qualitatively justified — large changesets exceed the subagent's effective review window — but no empirical evidence backs the specific value of 500 vs 250 vs 1000. Task 127's changeset (2166 lines) blew through the cap and required a manual approval workflow; the user explicitly flagged the threshold's lack of quantitative basis.

1. Pick 5-10 representative changesets from CWF history at varying sizes (250, 500, 1000, 2000 lines).
2. Run the security-review subagent on each; record finding-rate, false-positive-rate, runtime, and the subagent's own self-reported coverage assessment.
3. Plot finding-rate-per-line and runtime against changeset size; identify the inflection point where review quality starts to degrade.
4. Set the cap from data, not vibes. Document the methodology in `.cwf/docs/skills/security-review.md` so future revisions have a baseline.

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

## Task: Add Security Verification to Testing Workflow

### Task-Type: chore
### Priority: Medium
### Status: Identified during Task 32 security verification
### Problem: Task 32 modified 8 helper scripts and added 2 libraries, but security hash verification wasn't performed until after retrospective. Security verification should be part of the testing phase to catch hash mismatches early.
### Solution: Update testing workflow documentation and templates to include security verification step.
### Scope: 
### Benefits: 
### Success Criteria: 
### Rationale: Security verification is currently ad-hoc. Integrating it into the testing workflow ensures it's performed consistently for all tasks that modify security-sensitive files.
### Related: Task 32 (discovered during post-retrospective security check)

Add instruction to include security integrity checks as a standard part of the testing workflow (g-testing-exec) for all tasks that modify helper scripts or libraries.




1. **Update workflow documentation** (`.cwf/docs/workflow/workflow-steps.md`):
   - Add "Security Verification" as recommended step in Testing Execution section
   - Document when security checks are required (tasks modifying scripts/libraries)
   - Document how to run verification (`/cwf-security-check verify`)

2. **Update testing templates** (`.cwf/templates/pool/g-testing-exec.md.template`):
   - Add "Security Verification" checkbox to execution checklist
   - Add conditional guidance: "If this task modifies helper scripts or libraries, run `/cwf-security-check verify` and update hashes"

3. **Update testing plan templates** (`.cwf/templates/pool/e-testing-plan.md.template`):
   - Add "Security Verification" test case (TC-S1)
   - Test case validates script-hashes.json is up to date after implementation

- Catches hash mismatches early (during testing, not post-retrospective)
- Makes security verification a standard practice, not an afterthought
- Documents when and how to perform security checks

- [ ] workflow-steps.md includes security verification guidance
- [ ] g-testing-exec.md.template includes security checklist item
- [ ] e-testing-plan.md.template includes security test case
- [ ] Future tasks that modify scripts will include security verification in testing phase

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

## Task: Close TOCTOU window in atomic_write_text via O_NOFOLLOW

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 131
### Scope: 
### Risk: very low — single-developer maintenance helpers; concurrent attacker access to the working tree is out of the documented threat model. Worth fixing for defense in depth, especially before any tool that takes user-supplied paths is exposed to multi-user scenarios.
### Identified in: Task 131 c-design-plan plan-review (security agent)

`atomic_write_text` in `CWF::ArtefactHelpers` uses `rename($tmp, $path)` which writes through symlinks. Helpers that defend against this (e.g. `backlog-manager retire`, the `write_backlog_file` / `write_changelog_file` wrappers in `CWF::Backlog`) check `-l $path` before invoking `atomic_write_text`. There is a TOCTOU window between the check and the rename: an attacker who can rewrite the directory between the two calls could swap the regular file for a symlink and have the rename traverse it.

- Modify `atomic_write_text` to use `sysopen` with `O_NOFOLLOW` on the destination, OR perform the `-l` check inside the helper immediately before the rename (narrows but does not eliminate the window).
- Considered alternative: `link()` + `unlink()` instead of `rename()` — gives atomic semantics on POSIX but would change the helper's semantics for callers that rely on inode preservation.
- Update `t/artefacthelpers.t` to verify symlink targets are refused.

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

## Task: Tune security-review-changeset 500-line cap to count edit-lines only

### Task-Type: chore
### Priority: Low
### Identified in: Task 143 retrospective (j-retrospective.md)

The 500-line review cap in `cwf-implementation-exec` / `cwf-testing-exec` SKILLs counts `wc -l` of the entire diff output, which includes hunk headers (`@@ ...`), file headers (`diff --git` / `+++` / `---`), and unchanged context lines. Task 143 fired the cap twice on changesets whose actual edit-line count (`grep -c '^[+-]'`) was well under cap: f-phase 538 total / 399 edits, g-phase 625 total / 419 edits. Either (a) change the SKILL to count `grep -cE '^[+-]' | grep -v '^[+]{3}\|^[-]{3}'` (edit lines only), or (b) raise the cap, or (c) split the cap into two thresholds (warn at 500 edit-lines, hard-stop at 1000). The intent was context-window protection for the subagent; edit-lines is closer to that intent than total-diff-lines.

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

## Task: Investigate UTF-8 mangling in backlog-roundtrip-live test against live BACKLOG.md

### Task-Type: bugfix
### Priority: Medium
### Identified in: Task 147 retrospective (j-retrospective.md)

`t/backlog-roundtrip-live.t::TC-ROUNDTRIP-LIVE-BACKLOG` fails on the live BACKLOG.md with UTF-8 character mangling: characters like `—` (U+2014) and `§` (U+00A7) get rewritten as `â` and `Â§` on round-trip. Reproduced on `main` HEAD as of 2026-05-17, prior to any Task 147 changes. The test reads the file, parses with `parse_backlog_tree`, serialises with `serialize_tree`, encodes back to UTF-8, and compares to the original bytes. Output shows truncated multi-byte UTF-8 sequences — looks like serialize_tree is operating on byte strings (not codepoints) somewhere along the way, or the decode chain is single-byte under one code path.

Investigation candidates: `_read_file_with_global_checks` (uses `<:raw>` + explicit `decode(...)`), the `for ($i = 0; $i < @$lines; $i++)` loop in `_parse_tree` (does `$line` carry decoded text?), and `_serialize_entry`'s string concatenation. The other 5 backlog test files (mutators, parse, validate, manager, manager-argv-utf8) pass, so the round-trip-against-live-file path is the specific failure surface.

Surfaced by Task 147 at f-step-1 baseline test run.

## Task: Tune 500-line security-review cap so test files do not dominate

### Task-Type: chore
### Priority: Low
### Identified in: Task 147 retrospective (j-retrospective.md)

The 500-line cap on the security-review subagent's input (set in `.cwf/docs/skills/security-review.md` and applied by exec-phase SKILLs) is meant to keep the subagent's context window manageable. In practice the cap fires on test-heavy changes where the production delta is small — Task 147's production diff was ~120 lines (`Backlog.pm` helpers + 4-line `cmd_retire` branch), but the new test file `t/backlog-bootstrap-changelog.t` alone added 334 lines, pushing the total to 606. The exec SKILL classifies this as `error` and skips the subagent; the human is left to either split (often not viable for a single logical change) or perform manual review.

Two reasonable options:
1. Have `.cwf/scripts/command-helpers/security-review-changeset` exclude (or 0.5x weight) paths matching `^t/` or `^tests/` from the line-count tally that drives the cap decision. The diff would still include the test files (review covers them), but the cap would key off production volume.
2. Add a configurable per-phase override in `cwf-project.json` so users can tune the cap.

Option 1 is the smaller surface change; the cap stays in one place (the helper) and SKILLs keep their current "ask the helper" contract. Option 2 is more flexible but adds a config knob to maintain.

Identified in Task 147 retrospective (j-retrospective.md § Recommendations).

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

## Task: Wire trunk-resolution fallback chain across retrospective-extras and security-review-changeset

### Task-Type: chore
### Priority: Low
### Status: Follow-up from Task 152
### Identified in: Task 152 c-design-plan.md §Decision 2, §Follow-ups

Wire the documented trunk-resolution fallback chain (`cwf-project.json:trunk` → `git symbolic-ref refs/remotes/origin/HEAD` → hardcoded `main`) across the two call sites that need it: `.cwf/docs/skills/retrospective-extras.md` `## Suggest Merge (Step 12)` (top-level-task branch of the derivation rule) and `.cwf/scripts/command-helpers/security-review-changeset` (already documents the chain at `.cwf/docs/skills/security-review.md:28` but does not yet wire it). Today both sites hardcode `main`. Today's behaviour is loud-failure for non-`main` adopters: a suggested `git checkout main` simply fails on paste (and `security-review-changeset` falls back to `git merge-base HEAD main`, which also fails loudly). Doing both call sites in one task ensures a single convention, single `cwf-project.json` schema bump, single test surface. Trigger: either a non-`main` adopter shows up, or `security-review-changeset` needs the chain wired first for an independent reason.

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

## Task: Rebrand TLA from CWF to CwF across project

### Task-Type: chore
### Priority: Low
### Identified in: Task 184

The canonical three-letter abbreviation is currently "CWF" (all-caps) across glossary.md, README.md, CLAUDE.md, docs, skills, and committed CHANGELOG entries. The intended branding is the mixed-case "CwF". This is pre-existing design drift not noticed until Task 184 (which used the current canonical CWF for the CHANGELOG header fix rather than mixing conventions). Sweep all production artefacts (glossary, README, CLAUDE.md, .cwf/docs, .cwf/templates, skills, agent defs) replacing the standalone TLA "CWF" -> "CwF", excluding immutable history (implementation-guide/* task docs, retired CHANGELOG entries). Verify with an output-level smoke test per the rebrand-smoke-test process memory. Update the glossary Abbrev definition and pronunciation note accordingly.

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

## Task: Retire residual CIG branding from .cwf code and POD

### Task-Type: chore
### Priority: Low
### Identified in: Task 189 docs-sync stale-string sweep

Code and POD under .cwf/scripts/ and .cwf/lib/ still carry the pre-rebrand "CIG" name: "CIG System" author tags in several Perl POD blocks (StatusAggregator/Core.pm, WorkflowFiles/V20.pm + V21.pm, TaskState.pm, TemplateCopier/Core.pm, ContextInheritance/Core.pm, Options.pm, Common.pm), "CIG tasks/scripts" in template-copier comments and POD, CIG_SOFTWARE_VERSION in context-manager.d/version, and "CIG Migration" banners in migrate-v1-to-v2.sh / rollback-migration.sh. Cosmetic only (not user-facing in normal operation). Out of scope for the Task 189 docs-sync chore because these are hash-tracked files: editing them pulls a code+sha256 change set that must not ride in a docs commit. Fix as its own task with the in-task hash refresh per .cwf/docs/conventions/hash-updates.md.

## Task: Extend BACKLOG-000 structural contract to CHANGELOG.md (KD5 parity)

### Task-Type: feature
### Priority: Medium
### Identified in: Task 190

Task 190 added a generic intro-region structural predicate (CWF::Backlog::backlog_structure_errors, @EXPORT_OK) but wired it only into the BACKLOG validate/mutation path. The helper is format-agnostic. Extend the identical scan to CHANGELOG.md so a foreign-format CHANGELOG is rejected up front rather than mis-managed by retire. Security note: if a future CHANGELOG message ever cites verbatim offending-line text, the FR4(c) no-verbatim-echo surface reopens — apply NFR2 control-char-stripping/length-bounding then. TC-7 backstops only the BACKLOG path today.

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
