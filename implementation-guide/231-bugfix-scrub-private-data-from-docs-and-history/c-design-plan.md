# scrub private data from docs and history - Design
**Task**: 231 (bugfix)

## Task Reference
- **Task ID**: internal-231
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/231-scrub-private-data-from-docs-and-history
- **Template Version**: 2.1

## Goal
Define the mechanism that removes the maintainer's private data from **every**
commit — file contents **and** commit/tag messages — and the working tree,
replacing it with generic placeholders, verifiably and reversibly-until-published.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Resolved Open Decisions (from a-task-plan)
- **Scope breadth**: **whole tracked tree** (owner decision). A tree scan found file
  content leaks only in `implementation-guide/**` (paths, emails, names) and
  `CHANGELOG.md` (names); README/BACKLOG/`docs/`/`.cwf/` are clean. **Commit messages
  additionally carry the data** (e.g. `Co-developed-by: … <claude@…>` trailers,
  paths, names) and are in scope — see D1/D6.
- **History-rewrite tool**: **`git filter-repo`** — confirmed installed
  (`/usr/bin/git-filter-repo`). `filter-branch` is the documented fallback; BFG absent.
- **Rewrite surface**: whole-tree text replacement **plus commit/tag message
  replacement**, both via the same rules file. Safe for content because every match
  pattern was verified absent from hashed scripts (they live only in docs/CHANGELOG).
- **Placeholder literals**: the scheme in *Placeholder Table* below.
- **Tag handling**: the rewrite orphans all 39 `v1.1.x` tags; the owner re-creates them
  on the rewritten commits (tagging is human-only).
- **Identity fields**: author/committer are uniformly `github@mattkeenan.net` (the kept
  address) across all history, so **no `--mailmap`/identity rewrite is needed** — only
  message *bodies* (trailers) carry the personal `claude@…` address.

## Key Decisions

### D1 — Architecture: one `filter-repo` pass, content **and** messages, over the whole repo
- **Decision**: express the entire redaction as a single rules file and apply it in
  **one** `git filter-repo` pass across all refs, driving **both**
  `--replace-text` (blob contents) **and** `--replace-message` (commit **and** tag
  message bodies) from that same file. The pass rewrites every historical blob and
  message **and** the tip tree, so working tree, history, and messages are scrubbed by
  one operation.
- **Rationale**: `--replace-text` rewrites file contents only; the goal says "every
  commit", and private data also lives in message trailers/bodies — so message
  replacement is mandatory, not optional. One rules file for both keeps a single source
  of truth and guarantees tip/history/message consistency.
- **Trade-offs**: replacement is content-global — every occurrence of a rule's pattern
  in every blob/message is replaced. Fine for deterministic patterns; ambiguous ones
  are constrained (D3). filter-repo needs `--force` on a non-fresh clone and drops the
  `origin` remote — noted for the runbook.

### D2 — Redaction taxonomy: two rule classes, one file
- **Class A (deterministic)** — safe to replace anywhere (content or message):
  - Personal emails except `github@mattkeenan.net` (the `claude@…` local-part is
    distinct, so a targeted rule never touches the kept address, even on a line/trailer
    containing both).
  - The six **distinctive** other-project names (scratch `inv-distinctive-names.txt`) —
    each unique enough for a literal rule.
  - Username-bearing absolute paths and the disposable-log path.
- **Class B (context-sensitive)** — must NOT be globally replaced:
  - **Ambiguous common-word project names** — two common words, plus the retained `lmm`.
    The bare common word matches 365 files (mostly "quality gate"); `lmm` also names the
    live MCP server (`mcp__lmm__*`) and "LMM corpus". Redacted only at their specific
    project-reference sites (a handful, concentrated in Task 219's aggregation and
    `CHANGELOG.md`).
  - **Project rosters** — enumerations like "(6 projects: …)" reworded to drop the list
    and keep the count/lesson.
- Both classes live in the **same** rules file: Class A as broad regex/literal rules,
  Class B as long distinctive **literal** rules that match only the intended phrase.

### D3 — Constraining Class B safely
- Each Class-B rule's search text is the **full distinctive phrase** as it occurs (from
  the inventory), never the bare ambiguous word — e.g. the exact roster string, or
  `gate (` with its digits in the Task-219 tally. This matches only the project site and
  leaves every "quality gate" and every `mcp__lmm__*` untouched.
- The exact enumeration is the implementation-plan's deliverable; the design guarantee
  is: **no bare common word is ever a rule**, and **rules are applied longest-prefix /
  most-specific first** (filter-repo applies rules in file order — a hard correctness
  contract, so the specific repo path precedes the generic `/home/<user>/repo/<name>`
  rule).

### D4 — Self-reference / idempotence (load-bearing)
- The rules file **is** the private data (raw → placeholder). It, **and any script that
  embeds the raw patterns** (the scrub/verify tooling below), live in **scratch**, are
  **never committed**, and are never published. `verify.sh`'s search patterns *are* the
  Class-A/B strings, so committing it would re-introduce exactly what the task removes;
  it stays scratch-only for the same reason as the rules file.
- The task's committed footprint therefore collapses to **the doc rewrites the pass
  produces plus the task-231 workflow docs** — no new tooling is shipped.
- The pass also rewrites task 231's own committed docs, so every committed doc —
  including this one — is written to **read correctly after the scrub**: it refers to
  categories, counts, and scratch files, not to a raw private string that must survive.
  D6 re-scans the task-231 directory.

### D5 — Safety model
- **Test on a disposable clone first, never the live repo** (the "test DB, never
  production" rule applied to history): all dry-runs and verification (D6) run against a
  fresh `git clone` in scratch. The live-repo rewrite happens only after the clone
  passes every gate.
- **Backup before the live run**: a `git bundle --all` of the pre-rewrite repo kept in
  scratch until the owner confirms the public push (the complete, portable net);
  filter-repo's own `.git/filter-repo/` originals are a secondary net. (No extra
  `refs/backup` ref — subsumed by the bundle, and an unredacted ref inside `--all` would
  spuriously fail the D6 scan.)
- **Hashed-script integrity**: whole-tree scans confirm no Class-A/B pattern appears in
  any hashed script (only docs/CHANGELOG), so replacement cannot alter a hashed blob.
  Re-verified by `cwf-manage validate` post-pass.
- **Tooling posture**: `scrub.sh`/`verify.sh` are scratch-only one-off operational
  scripts (not committed `.cwf/` helpers), so the Perl-helper norm does not bind; their
  patterns are **author-authored, never user input** (FR4(e) — safe by construction;
  audit if ever fed external strings). `scrub.sh` takes the clone destination as an
  operator-supplied argument (derives no scratch path itself).
- **Human-only boundary**: the live-repo rewrite, tag re-creation, and any push are
  surfaced as commands for the **owner** to run (same class as merge-to-main). The task
  only produces and validates the tooling against the clone.

### D6 — Verification gate (the definition of done)
Run against the rewritten clone, in order; any failure stops:
1. **Negative control first** (prove the gate can fail): plant a known Class-A and a
   known Class-B string into the clone, confirm the scan **flags** them, and confirm
   `github@mattkeenan.net` is **not** flagged. Only a gate proven to fail on a planted
   leak may be trusted when it passes.
2. **All-history content scan clean**: `git rev-list --all | xargs git grep -nE
   '<patterns>'` (stdin/xargs form, not `$(…)` — the corpus is ~1981 commits) returns
   nothing for every Class-A pattern and Class-B site.
3. **All-message scan clean**: `git log --all --format='%B%an%ae'` (or `git log -G`
   per pattern) returns nothing for any pattern — the content scan cannot see messages.
4. **Kept-address intact**: `github@mattkeenan.net` still present where expected.
5. **`cwf-manage validate` OK** (no hash/permission drift).
6. **Full test suite green** (`prove -r t/`).
7. **Readability spot-check**: sampled scrubbed lines (CHANGELOG, Task 219) read as
   coherent English.

## System Design

### Component Overview
- **`redact-rules.txt`** (scratch, untracked): the filter-repo replacement rules —
  Class A + Class B — driving both `--replace-text` and `--replace-message`. Single
  source of the raw→placeholder mapping.
- **`scrub.sh`** (scratch, untracked): clones the repo to an operator-supplied
  destination, runs `git filter-repo --replace-text redact-rules.txt --replace-message
  redact-rules.txt --force`, prints the live runbook. Never touches the live repo.
- **`verify.sh`** (scratch, untracked): runs the D6 gate against a target repo path;
  derives its patterns from `redact-rules.txt` (never inlines raw literals); exits
  non-zero on any leak.
- **Placeholder scheme** (this doc): the fixed target vocabulary.

### Data Flow
1. Inventory (scratch) → author `redact-rules.txt` (Class A regex/literal, Class B
   enumerated literals).
2. `git bundle --all` backup → `scrub.sh` → fresh clone → `filter-repo` (text +
   message) → rewritten clone.
3. `verify.sh` → D6 gate on the clone → PASS/FAIL.
4. On PASS: emit the owner runbook (backup → live rewrite → re-tag → push).
5. Owner executes the runbook on the live repo (human-only).

### Placeholder Table (interface contract)
| Class | Example input | Placeholder output |
|---|---|---|
| This repo's path | `/home/<user>/repo/coding-with-files/X` | `<repo-root>/X` |
| Other-repo path | `/home/<user>/repo/<name>` | `/path/to/<other-project>` |
| Other home path | `/home/<user>/<x>` | `/home/<user>/<x>` (username only → `<user>`) |
| Disposable log | `/var/tmp/<name>.log` | `/var/tmp/<other-project>.log` |
| Distinctive name (prose) | a distinctive project name | `<other-project>` |
| Project roster | `(N projects: a, b, c…)` | `(N other projects)` |
| Personal email | a personal non-public `@mattkeenan.net` address | `user@example.com` |
| Kept email | `github@mattkeenan.net` | **unchanged** |

Rules-file sketch (format contract; exact set in d-plan; drives both `--replace-text`
and `--replace-message`; **all literals apply first (file order), then all regexes (file
order)** — filter-repo's actual semantics, confirmed at f-exec. `#` is **not** a comment
in a replace-text file, so the real rules file carries rules only — all literals, then
the regexes:):
```
<personal-email>==>user@example.com
<exact roster phrase>==>(6 other projects)
regex:/home/[A-Za-z0-9._-]+/repo/coding-with-files==><repo-root>
regex:/home/[A-Za-z0-9._-]+/repo/[A-Za-z0-9._-]+==>/path/to/<other-project>
regex:<distinctive-name>==><other-project>
```

## Constraints
- No bare common word (the two ambiguous project words, or `lmm`) may be a replacement pattern.
- **No rule may match `github@mattkeenan.net`** (the kept address) — explicit invariant.
- Rules are applied **all literals first, then all regexes** (each in file order); among
  the regexes, the specific repo path precedes the generic other-repo rule.
- The rules file and any pattern-bearing script are never committed (D4).
- Live rewrite / tagging / push are human-only.
- Redacted values are generic placeholders, not context-carrying aliases.

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ concerns? Coupled (rules, rewrite, verify) — one design.
- [ ] **Risk**: high-risk (live rewrite)? Yes, but isolated behind the clone-first gate
      and the human-only boundary; not separable from the ruleset.
- [ ] **Independence**: separable parts? No — strictly sequential.

**Conclusion**: Do not decompose.

## Validation
- [x] Design review completed (Step 8 map/reduce — 5 reviewers; blocking message-scope
      and self-leak findings folded in)
- [ ] Placeholder scheme approved by owner
- [ ] Clone-first + human-only boundary confirmed

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
The one-pass `filter-repo` design (content + messages, whole repo, one rules file) held.
Two D2 corrections during execution: `lmm` retained entirely (entangled with the
`mcp__lmm__*` API and a tracked path), and the generic other-repo path regex dropped as
redundant (name literals apply before path regexes). D3's rule-ordering wording was
reconciled to filter-repo's actual semantics (all literals first, then all regexes).

## Lessons Learned
Surfacing entangled tokens (`lmm`) to the owner beat forcing a brittle partial rule.
See j-retrospective.md.
