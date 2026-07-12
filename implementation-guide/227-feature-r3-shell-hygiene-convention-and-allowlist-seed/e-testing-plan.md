# R3 shell-hygiene convention and allowlist seed - Testing Plan
**Task**: 227 (feature)

## Task Reference
- **Task ID**: internal-227
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/227-r3-shell-hygiene-convention-and-allowlist-seed
- **Template Version**: 2.1

## Goal
Define the test strategy for the read-only allowlist seed (the security-critical half) and the
lightweight checks for the convention doc + anchors.

## Test Strategy
### Test Levels
- **Unit (predicate)**: the test-local `is_read_only_safe($entry)` + `%SAFE_KEYS` checker,
  authored independently of the script's corpus (KD3). Accept/reject controls in one case.
- **Integration (seed)**: run `cwf-claude-settings-merge` against tempdir fixtures (the existing
  `t/cwf-claude-settings-merge.t` harness) and assert on the written `permissions.allow`.
- **Static (doc/anchors)**: assert the doc exists, its links resolve, and no `docs/`-tree link
  is present; assert the two anchor references resolve to the doc.

### Coverage Targets
- **Critical path (the safety gate)**: 100% — every corpus entry validated; every planted-unsafe
  class rejected. This is the load-bearing security control (KD5: append-only merge has no
  retraction, so corpus correctness is the sole defence).
- **Regression**: full `t/` suite PASS (currently `Files≈75`); no change to existing
  settings-merge behaviour (`.cwf/` helper entries, hooks, env, sandbox reconcile).

## Test Cases
### Functional — safety predicate (unit)
- **TC-1 (accept corpus)**: **Given** the 5 corpus entries (`Bash(ls:*)`, `Bash(pwd:*)`,
  `Bash(git status:*)`, `Bash(git rev-parse:*)`, `Bash(git branch --show-current)`); **When**
  `is_read_only_safe` runs on each; **Then** all accepted.
- **TC-2 (reject unsafe — the positive control's negative half)**: **Given** planted
  `Bash(git diff:*)`, `Bash(rg:*)`, `Bash(git:*)`, `Bash(find:*)`, `Bash(sed -i:*)`,
  `Bash(git branch:*)`, and **`Bash(git branch --show-current:*)`** (the prefix form of the exact
  entry); **When** the predicate runs; **Then** every one is rejected. (TC-1+TC-2 share a case — a
  negative control needs its positive control alongside it.)
- **TC-3 (exact/prefix split — the d-review hole)**: **Given** the predicate's two independent
  sets (`%SAFE_PREFIX_KEYS` / `%SAFE_EXACT_KEYS`); **Then** `Bash(git branch --show-current)`
  (exact) is accepted while `Bash(git branch --show-current:*)` (prefix) and `Bash(git branch:*)`
  are rejected — proving a prefix form of the exact entry cannot hit the exact slot.
- **TC-4 (anchor discipline)**: **Given** an entry with a trailing newline `Bash(ls:*)\n`;
  **When** matched; **Then** rejected — proves `\A`/`\z` (not `^`/`$`) anchoring.

### Functional — seed integration
- **TC-5 (corpus present)**: **Given** a clean fixture (manifest + no `.claude/settings.json`);
  **When** the helper runs; **Then** `permissions.allow` contains all 5 corpus entries.
- **TC-6 (only-safe generic entries)**: **Given** the clean fixture post-merge; **When** every
  allow entry lacking `.cwf/scripts/` is collected; **Then** each passes `is_read_only_safe` and
  the set equals exactly the expected corpus.
- **TC-7 (additive — separate fixture)**: **Given** a fixture whose `.claude/settings.json`
  pre-contains `Bash(npm test:*)`; **When** the helper runs; **Then** that entry survives and the
  corpus is added alongside it (kept off TC-6's fixture so set-equality isn't polluted).
- **TC-8 (idempotent)**: **Given** an already-seeded fixture; **When** the helper re-runs;
  **Then** zero duplicate corpus entries (`%seen` dedupe).
- **TC-9 (malformed pre-existing settings — reuse guarantee)**: **Given** a `.claude/settings.json`
  that is invalid JSON; **When** the helper runs; **Then** it dies without clobbering the file
  (asserts the inherited `read_settings` fail-closed behaviour, FR8).
- **TC-9a (regression — existing count assertions)**: the unconditional +5 seed changes the clean-
  fixture allow count 3→8; the existing `t/cwf-claude-settings-merge.t:126` (TC-U1) and `:231`
  (TC-U4) count assertions must be updated to 8 and re-pass (not left to a blanket "suite PASS").

### Non-Functional
- **Security**: TC-2/TC-3/TC-4 ARE the security tests — exact/prefix membership split,
  anchor-hole closure. **Operators** are documented-safe (per-subcommand match, sourced KD2a) — no
  test needed. **Redirection/substitution** (manual probe, d-plan Step 5): exercise all four
  vectors (`>`, `>>`, backtick, `$(…)`) under `Bash(ls:*)`; record in Actual Results; a positive
  result triggers the doc-caveat + backlog branch, not a silent pass.
- **Reliability**: TC-8 (idempotent convergence), TC-9 (safe-on-malformed).
- **Usability**: doc scannable in one sitting; `--dry-run` reports the corpus count (manual).

### Static — doc & anchors
- **TC-10**: `.cwf/docs/conventions/shell-hygiene.md` exists; every link in it resolves; it
  contains no link into the maintainer-only `docs/` tree (FR2); and it documents the durable
  **deny/ask opt-out** (KD5) — `ask` restores the prompt, `deny` forbids, in the user/`.local` layer.
- **TC-11**: the **load-bearing** reference in the shipped `cwf-agent-shared-rules.md` resolves to
  the doc (FR3); this repo's `CLAUDE.md` `## Conventions` entry also resolves (dogfood-only).

## Test Environment
- **Framework**: `Test::More` under `prove` (matches the existing `t/` suite); core Perl only.
- **Fixtures**: tempdir builders already in `t/cwf-claude-settings-merge.t` (`build_fixture`,
  `write_settings`, `read_settings`); no production `.claude/settings.json` touched.
- **Automation**: `prove -r t/` (bare — `PERL5OPT=-CDSLA` is already in the env).

## Validation Criteria
- [ ] TC-1 … TC-9a pass; full `t/` suite PASS (incl. the updated TC-U1/TC-U4 counts)
- [ ] TC-10/TC-11 static checks pass
- [ ] `cwf-manage validate` OK (hash refreshed with the helper edit)
- [ ] Redirection/substitution probe (4 vectors) recorded in Actual Results; positive result routed
      to the doc-caveat + backlog branch

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
The abstract TC-1..TC-9a plan was realised as concrete `t/` subtests (TC-RO1..RO5 + the two
updated count assertions) and all passed; full regression green (Files=78, Tests=1078). The one
test that could not run authoritatively offline — the redirection/substitution 4-vector probe —
was handled via the positive branch (doc caveat + backlog), not silently passed.

## Lessons Learned
Realising an abstract test plan as named subtests keeps the plan and the executable suite
traceable to each other without duplicating the plan into the code. An un-runnable test is a
signal to surface (caveat + backlog), never to quietly mark green.
