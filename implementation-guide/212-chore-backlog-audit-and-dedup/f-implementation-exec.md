# Backlog audit and dedup - Implementation Execution
**Task**: 212 (chore)

## Task Reference
- **Task ID**: internal-212
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/212-backlog-audit-and-dedup
- **Template Version**: 2.1

## Status
**Status**: Finished
**Next Action**: Changeset reviews (Step 8), then checkpoint commit
**Blockers**: None — user approved the action list (5 retires + 3 merges; partials left as-is)

## Method
Steps 1–3 of d-implementation-plan executed: all 91 active items partitioned into 10
line-range batches, each assessed by a parallel **Explore** agent against the live
codebase (`.cwf/` tree, `.claude/` skills/agents, `git log`). Verdicts are advisory inputs
to the human-gated action list; nothing is applied until Step 4 approval. Five DONE claims
were re-verified by hand before being proposed for retirement (one was rejected — see
below).

## Verdict ledger (all 91)
Baseline: 91 active items (18 Medium + 73 Low). Verdict legend: DONE = fully
done/superseded (retire); PARTIAL = partly done (resize/keep); OPEN = still valid;
UNCLEAR = needs a closer look.

### Retire — DONE/superseded (5), each hand-verified
| # | Title | Superseded by | Verification |
|---|---|---|---|
| 33 | Add Security Verification to Testing Workflow | checkpoint-commit auto-runs `cwf-manage validate` (`.cwf/docs/skills/checkpoint-commit.md:16`) + hash-updates convention + g-testing-exec Step 8 changeset Security Review | scope-checked: validate gates every checkpoint commit; only residual is a ~5-line `workflow-steps.md` doc note |
| 49 | Close TOCTOU window in atomic_write_text via O_NOFOLLOW | Task 182 — `atomic_write_text` uses temp+`rename` (symlink-replace, not write-through) | `ArtefactHelpers.pm:80` `rename "$tmp",$path` confirmed |
| 63 | Investigate UTF-8 mangling in backlog-roundtrip-live test | Task 137 fixed argv double-encoding (`-CDSLA`) | `prove t/backlog-roundtrip-live.t` → PASS (2/2) |
| 64 | Tune 500-line security-review cap so test files do not dominate | Task 168 production-weighted cap + `max-lines-exclude-paths` (default `t/**`) | `cwf-project.json:40` `max-lines-exclude-paths` confirmed |
| 68 | Wire trunk-resolution fallback chain across retrospective-extras and security-review-changeset | Done — full fallback chain in `security-review-changeset` (cwf-project `trunk` → `origin/HEAD` → `main`) + retrospective-extras | agent-cited `security-review-changeset:442-481` |

**Rejected DONE → kept OPEN**: "Make cwf-plan-reviewer-misalignment enforced-permission
survive git checkout" — an agent marked it DONE (file is 0444), but git tracks only the
execute bit, so 0444 does **not** survive a fresh checkout (returns as 0644 until
`fix-security` re-clamps). The concern is real; stays OPEN.

### Merge clusters (3 proposed)
| Cluster | Sources → survivor | Rationale |
|---|---|---|
| Best-practice resolver | 88 *Live-agent run of best-practice reviewer* + 89 *Narrow best-practice active-tags* + 90 *Align best-practice-resolve relevance and output format* → **1** | all three concern the resolver's relevance/format/live-verification; the Task-212 plan-review itself hit the off-domain tag bug (golang/postgres matched a Perl/MD chore) |
| Security-review line cap | 19 *Quantitatively justify the line-count cap* + 59 *Tune cap to count edit-lines only* → **1** | both revisit the same 500-line cap threshold; justify + change belong together (cluster's DONE member #64 retired separately) |
| Branding cleanup (offered) | 76 *Rebrand TLA CWF→CwF* + 80 *Retire residual CIG branding from .cwf code/POD* → **1** | overlapping file sweeps over project branding; distinct old-brands (CIG vs CWF-case) but one coordinated pass is cheaper |

### Partial — done-portion noted, residual carved (16)
3 Generalised agent-frontmatter unknown-key linter (allowed-tools validated; general linter residual) ·
15 Collapse parse_backlog/changelog_tree (internally unified; only public-API collapse remains — a major-version break) ·
20 Standardise Placeholder Syntax (no stray model-substitution found; only a style-guide doc residual) ·
26 Comprehensive Dead Code Audit (methodology shipped Task 148; the audit run itself remains) ·
27 Create Perl Idioms Documentation (`perl.md` rules done; idioms doc residual) ·
43 Document Workflow Phase Sequences by Task Type (overview table exists; per-type detail residual) ·
45 Add Conflict-State Regression Test (harness `t/stop-uncommitted-changes-warning.t` exists; conflict-state cases residual) ·
50 Roll intent-CTA description convention (1 of ~20 skills done) ·
56 Retrofit create_skill_symlinks (install.bash has conflict-check; cwf-manage equivalent residual) ·
57 Install-time chmod 0444 (Task 170 ceiling model made it lower-urgency; install-time clamp residual) ·
60 Naming convention for throwaway test branches (de-facto `tmp/` in use; not codified) ·
67 Promote `sleep 1 && git` prefix to convention doc (inline in retrospective-extras; standalone doc residual) ·
69 Single source of truth for PERL5OPT (constant in one helper; docs still duplicate literal) ·
77 Retire remaining vestigial version fields (`cwf-version` retired Task 188; `security.version-tracking` residual) ·
79 Prune vestigial blocks from cwf-project.json (template lists current; `OWNER/REPO` placeholders residual) ·
83 Embedded-block first-insert conflict (silent first-insert implemented; source CLAUDE.md lacks markers — residual)

### Unclear (1) — needs a closer read before any verdict
17 Extend security-review-changeset shebang interpreter regex (agents could not locate/confirm the interpreter regex in the helper; assess before acting)

### Open — still valid, keep (66)
All remaining items: 1,2,4,5,6,7,8,9,10,11,12,13,14,16,18,21,22,23,24,25,28,29,30,31,32,
34,35,36,37,38,39,40,41,42,44,46,47,48,51,52,53,54,55,58,61,62,65,66,70,71,72,73,74,75,
78,81,82,84,85,86,87,91. (The cap items 19/59 and best-practice items 88/89/90 are folded
into merges above; branding 76/80 likewise if that merge is approved.)

## Conservation ledger (projected, pending approval)
- Baseline active items: **91**
- Proposed removals: 5 retired + merge net (7 sources − 3 survivors = 4) = **9 fewer**
- Projected active after: **82** (or **81** if the branding merge is approved)
- Every original title maps to exactly one verdict; no item unaccounted (TC-2).

## Proposed action list (Step 4 — AWAITING APPROVAL)
1. **Retire 5** done/superseded items (#33→Task 212 note, #49→182, #63→137, #64→168, #68→168).
2. **Merge** best-practice cluster (88+89+90 → 1) and cap cluster (19+59 → 1).
3. **Branding merge** (76+80 → 1) — offered, your call.
4. **Partials**: recommend **leaving as-is** (residual work is real and still tracked; titles only slightly overstate remaining scope) rather than 16× `delete`+`add` churn that reorders the backlog. Resize any specific ones on request.
5. **#17 unclear**: leave OPEN pending a closer read.

## Security Review

**State**: no findings

Data-only backlog/CHANGELOG audit; no executable/Perl/shell/env-var surface. Category (a–e)
all clear. The one untrusted-input flow — backlog item bodies fanned out to Explore agents —
is correctly gated behind the human approval step and the constrained `backlog-manager`
helper; no mutation fires on an agent verdict alone. `retire --note` ASCII-sanitisation
rejects `-->`, so the CHANGELOG HTML-comment markers cannot be broken out of.

## Best-Practice Review

**State**: no findings

Markdown-only chore; the supplied `golang`/`postgres` corpora are off-domain (no Go or SQL
in the diff), so no applicable best practice is diverged from — a genuine "no applicable
practice" outcome (and itself an instance of the resolver-relevance defect this task's
merged "Best-practice resolver" item records).

## Improvements Review

**State**: no findings

All mutations reuse existing `backlog-manager` verbs; no duplicated helpers or avoidable new
code. Dedup collapses 7 near-duplicate entries into 3 union survivors; retires append to
existing `## Task N:` CHANGELOG sections rather than duplicating headers.

## Robustness Review

**State**: no findings

All five cited supersession evidences verified against the live tree; conservation ledger
(91 → 82) balances; merge survivors union their sources; the false-positive DONE
(0444-doesn't-survive-checkout) was correctly rejected rather than over-retired.

## Misalignment Review

**State**: no findings

Mutations and CHANGELOG retires follow the canonical `backlog-manager` heading-tree and
`Retired Backlog Items` conventions; no reinvention. (Non-blocking note from the reviewer:
`g-testing-exec.md` is still raw template — expected, as the testing-exec phase runs next.)

## Actual Results
User approved (5 retires + best-practice/cap/branding merges; 16 partials left as-is).
Applied via `backlog-manager` in plan order — 5 retires, then each merge as add-survivor
then delete-sources. Survivor bodies composed in scratch (`survivor-*.txt`).

**Mutations applied:**
- Retired → CHANGELOG: *Add Security Verification to Testing Workflow* (Task 212),
  *Close TOCTOU window…* (182), *Investigate UTF-8 mangling…* (137),
  *Tune 500-line security-review cap so test files…* (168),
  *Wire trunk-resolution fallback chain…* (168).
- Merge → *Best-practice resolver: relevance, output format, and live-agent verification*
  (sources 88+89+90 deleted).
- Merge → *Revisit the security-review line cap: quantitative basis and edit-lines counting*
  (sources 19+59 deleted).
- Merge → *Branding cleanup: CWF to CwF rebrand and retire residual CIG naming*
  (sources 76+80 deleted).

**Validation (all pass):**
- TC-1 `backlog-manager validate --all` → OK.
- TC-2 conservation: 91 − 5 retired − 7 merge-sources + 3 survivors = **82** active (matches `list` count).
- TC-3 all 5 retired entries present under their tasks' `### Retired Backlog Items`; absent from BACKLOG.
- TC-4 3 survivors active; `validate` clean ⇒ no slug collision.
- TC-5 every retire carries an ASCII `--note` citing concrete superseding evidence.

## Lessons Learned
*To be captured during retrospective.*
