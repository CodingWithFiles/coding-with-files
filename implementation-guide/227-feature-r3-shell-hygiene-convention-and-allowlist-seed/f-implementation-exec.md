# R3 shell-hygiene convention and allowlist seed - Implementation Execution
**Task**: 227 (feature)

## Task Reference
- **Task ID**: internal-227
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/227-r3-shell-hygiene-convention-and-allowlist-seed
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met (subtask gate for phase f passed)
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan

## Actual Results

### Step 1: Test first (fail-closed predicate + broken-count fixes)
- **Planned**: Add a test-local `is_read_only_safe($entry)` with two independent
  sets (`%SAFE_PREFIX_KEYS` / `%SAFE_EXACT_KEYS`); accept/reject controls incl. the
  prefix form of the exact entry; update the two count assertions broken by the +5 seed.
- **Actual**: Added the predicate and five subtests to `t/cwf-claude-settings-merge.t`
  (TC-RO1 accept/reject controls — 13 assertions incl. `Bash(git branch --show-current:*)`
  rejected and the trailing-newline anchor case; TC-RO2 exact/prefix split; TC-RO3 clean-merge
  corpus presence + generic-set equality + every-generic-entry-safe; TC-RO4 additive; TC-RO5
  idempotent). Predicate parses `Bash(<inner>)` with a negated char class `[^()]+`, `\A`/`\z`
  anchors, `/aa`; splits the `:*` suffix by exact `substr` (no backtracking regex); membership
  via hash lookup. Both sets authored from the admission criterion, with an in-file comment
  stating they are NOT derived from the script corpus (anti-tautology). Updated the two broken
  count assertions: TC-U1 `:126` and TC-U4 `:231`, `3`→`8` allowlist entries (3 manifest + 5 corpus).
- **Deviations**: None material. Fixed a `sort (...)`-as-function Perl warning by binding the
  expected list to `@expected` before `is_deeply` (kept the suite warning-clean).

### Step 2: Minimal implementation
- **Planned**: Add `my @READ_ONLY_ALLOWLIST = (...)` package-lexical constant; `push` it onto
  `@$allow_entries` after `partition_manifest` (line 631), before the single `merge_allow`.
- **Actual**: Added the 5-entry constant next to the `$CANONICAL_*` constants (with the same
  FR4(e) compile-time-constant rationale in a header comment), and
  `push @$allow_entries, @READ_ONLY_ALLOWLIST;` immediately after the `partition_manifest` call.
  One `merge_allow`, one count, preserved. Extended test file green; full `t/` suite green (see below).
- **Deviations**: None.

### Step 3: Convention doc + anchors
- **Planned**: Write `.cwf/docs/conventions/shell-hygiene.md` (new rules + links + curation);
  the opt-out note; add the subagent link and the CLAUDE.md conventions entry.
- **Actual**: Wrote `shell-hygiene.md` — prompt-free/portable idioms (heredoc/inline-script
  avoidance → scratch, `chmod +x && ./script`, no `perl -c`/`bash -n`, prompt-tripping
  substitution, NUL-separated git paths), linking (not restating) the anti-pattern table and
  tool-tier rubric; the allowlist-seed section (admission criterion, excluded-near-neighbour
  table, deny/ask opt-out, harness-matching caveat). Added the load-bearing link in
  `cwf-agent-shared-rules.md` (the shipped FR3 anchor read by shell-doing subagents) and the
  `## Conventions` entry in this repo's `CLAUDE.md` (dogfood-only, matching the siblings).
- **Deviations**: None.

### Step 4: Hash + validate
- **Planned**: Refresh `script-hashes.json` for the edited helper in the same commit; validate OK.
- **Actual**: Two hash-tracked files were edited — `cwf-claude-settings-merge` and
  `cwf-agent-shared-rules.md`. Refreshed both sha256 entries, independently verified with
  `sha256sum` (not the validator's own digest). Perms already matched recorded values (0500,
  0444) — no chmod needed. `cwf-manage validate` → OK. `shell-hygiene.md` and `CLAUDE.md` are
  not hash-tracked.
- **Deviations**: The plan named only the helper for hash refresh; the shared-rules doc edit
  (Step 3) also required a refresh. Both landed together, no deferral.

### Step 5: Manual smoke + redirection/substitution probe
- **Smoke**: `cwf-claude-settings-merge --dry-run` against the repo (no writes) rendered all 5
  corpus entries and no bare `git`/`find`/`sed`/`rg`. Deterministic count (8 on a clean fixture)
  is proven by TC-U1/TC-U4; corpus set-equality by TC-RO3.
- **Probe (redirection/substitution — KD2a residual, 4 vectors `>` `>>` backtick `$(…)`)**:
  A live probe requires a controlled single-`Bash(ls:*)`-rule harness; this session's permission
  scope differs, so it could not run authoritatively offline. Per the plan, an un-runnable probe
  is the **positive branch** — treated as unresolved, not assumed safe. Verified the documentation
  status instead (guide agent against `code.claude.com/docs/en/permissions.md`): compound-command
  splitting on `&&`/`||`/`;`/`|`/`|&`/`&`/newlines with per-subcommand matching is documented;
  **redirection and command substitution are NOT documented** — an undocumented permission-boundary
  gap. Discharged the positive-branch obligations: **(a)** recorded here; **(b)** the
  harness-matching caveat is in `shell-hygiene.md` (operators safe; redirection/substitution
  undocumented + harness-wide; high-frequency-verb blast-radius note); **(c)** seeded backlog item
  *"Verify harness auto-approval of redirection/substitution under Bash prefix allow rules"*
  (discovery, Medium, identified-in Task 227). The class is pre-existing and harness-wide (every
  `allow` entry, incl. existing `.cwf/` seeds), so the task ships with the caveat + backlog, not silently.

## Test Results
- `prove t/cwf-claude-settings-merge.t` → PASS (51 subtests; warning-clean).
- `prove -r t/` → **PASS, Files=78, Tests=1078**. (First full run failed 4 files — all downstream
  of the pre-refresh stale hash on `cwf-claude-settings-merge`; cleared after the Step-4 refresh.)
- `cwf-manage validate` → OK.

## Blockers Encountered

None. (The 4 transient test failures were the expected stale-hash signal, resolved by the
in-task hash refresh — the integrity check working as designed, not a defect.)

## Changeset Reviews

Five reviewers ran in parallel against the exec changeset (anchor `8dce3a6`, 1690 lines / 135
production, under cap). Classified by `security-review-classify`.

### Security Review

**State**: no findings

Static read-only allowlist seed; corpus verified read-only-for-all-args, fail-closed test gate
present, redirection/substitution residual properly surfaced (doc caveat + backlog), no
injection/env surface. The reviewer independently re-verified each corpus entry's read-only-ness
and endorsed the exact-vs-prefix `git branch --show-current` choice.

### Best-Practice Review

**State**: no findings

Perl additions (anchored `/aa` regex, negated char class, `@_`-unpacked predicate, lexical
constants) align with the Perl best-practice corpus; the Go/Postgres corpora are not applicable
to this diff.

### Improvements Review

**State**: no findings

Reuse-first — rides existing `merge_allow`/`read_settings`/`atomic_write`/`partition_manifest`
(no second writer), mirrors the `$CANONICAL_*` constant pattern, doc links rather than restates;
the test-predicate duplication is a deliberate anti-tautology control.

### Robustness Review

**State**: no findings

Static allowlist constant flows into the existing fail-safe additive `merge_allow` path; the test
predicate is fully anchored and the undocumented harness residual is handled conservatively
(surfaced, not assumed safe).

### Misalignment Review

**State**: findings → **RESOLVED**

Finding: `shell-hygiene.md` used markdown-link cross-references for intra-repo paths where
`docs/conventions/cross-doc-references.md` prescribes `inline-backtick × path`. Advisory/cosmetic
(links resolved) but a genuine divergence from a binding shipped convention on newly authored
content. **Fixed in this phase**: converted the four references (`tmp-paths.md` ×2, the
anti-pattern table, the tool-tier rubric) to inline-backtick repo-relative paths, matching the
sibling convention docs. The reviewer confirmed the `CLAUDE.md` and `cwf-agent-shared-rules.md`
entries were already correctly formed.

## Deferral Check
Before marking status=Finished, verify:
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] All requirements from b-requirements-plan.md addressed (if applicable)
- [x] All design guidance in c-design-plan.md followed (if applicable)
- [x] No planned work deferred without user approval
- [x] If work deferred: Follow-up task created and linked (harness-matching probe → backlog item, per KD2a positive branch — not a deferral of Task-227 scope but the planned residual routing)

**If deferral required**: Get user approval, document rationale, create follow-up task.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
- Editing a second hash-tracked file (the shared-rules doc) beyond the one the plan named for a
  hash refresh is a common miss — validate surfaces it deterministically; refresh both in-task.
- An undocumented harness behaviour is not a blocker if the residual is pre-existing and
  harness-wide: verify the documentation status, caveat it, and backlog the live probe — ship
  with the surface visible rather than assuming safe or assuming unsafe.
