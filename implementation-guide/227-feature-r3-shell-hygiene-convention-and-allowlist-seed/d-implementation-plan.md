# R3 shell-hygiene convention and allowlist seed - Implementation Plan
**Task**: 227 (feature)

## Task Reference
- **Task ID**: internal-227
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/227-r3-shell-hygiene-convention-and-allowlist-seed
- **Template Version**: 2.1

## Goal
Implement the design: a shipped shell-hygiene convention doc and a read-only generic-command
allowlist seeded through the existing `cwf-claude-settings-merge` path, with a fail-closed
membership test.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cwf/docs/conventions/shell-hygiene.md` **(new)** — the shipped convention. Owns the NEW
  rules (heredoc/inline-script avoidance → per-task scratch; `chmod +x && ./script` not
  `perl script`; no `perl -c`/`bash -n`; avoid prompt-tripping command substitution; brief
  NUL-safe git-path note). Links (does not restate): `cwf-agent-shared-rules.md` anti-pattern
  table, `subagent-tool-selection.md`, Task-220 tool-check, `tmp-paths.md`. Curation
  include/exclude per c-design KD-table (excludes `sleep 1 && git`, Perl-dev conventions,
  out-of-category items).
- `.cwf/scripts/command-helpers/cwf-claude-settings-merge` **(edit)** — add a package-lexical
  `my @READ_ONLY_ALLOWLIST = (...)` constant (mirrors the file's existing `$CANONICAL_PERL5OPT`
  / `$CANONICAL_RULES_INJECT_CMD` scalar-constant precedent — **supersedes c-design's Interface
  "function" form**, which the improvements/misalignment reviewers flagged as a single-callsite
  wrapper). Append it to `@$allow_entries` immediately after the `partition_manifest` call
  (line 631), before the single existing `merge_allow($settings, $allow_entries)` at line 650.
  One merge, one count preserved. Corpus: `Bash(ls:*)`, `Bash(pwd:*)`, `Bash(git status:*)`,
  `Bash(git rev-parse:*)`, and exact `Bash(git branch --show-current)`.

### Supporting Changes
- `.cwf/docs/skills/cwf-agent-shared-rules.md` **(edit)** — one static link to
  `shell-hygiene.md` (subagent anchor; no user-string interpolation — FR3).
- `CLAUDE.md` **(edit)** — add `shell-hygiene.md` to **this repo's** `## Conventions` listing,
  matching the sibling entries (`tmp-paths.md` / `session-hygiene.md` / `worktree-process.md`).
  **Scope correction (d-review):** this is **maintainer/dogfood-only** — `cwf-init` does *not*
  seed a `## Conventions` section into an end-user's CLAUDE.md (it installs only the 3-line
  `claude-md-preamble` between `CWF-PREAMBLE-START/END`). So FR3 ("referenced from a shipped
  surface an agent reads") is satisfied by the **shipped `cwf-agent-shared-rules.md` link**
  (read by the shell-doing review/exec subagents), plus the doc's home in the shipped
  `.cwf/docs/conventions/` tree. Broader end-user *main-loop* injection is **out of scope**: it
  would require editing `rules-inject.txt` (terse every-turn budget + pending consumer-owned
  reclassification) or the preamble — a separate decision, and one no sibling convention has
  either. The subagent link is therefore the load-bearing FR3 anchor, not optional.
- `t/cwf-claude-settings-merge.t` **(extend)** — corpus + fail-closed predicate tests (below).
- `.cwf/security/script-hashes.json` **(refresh)** — new sha256 for the edited helper, in the
  **same commit** as the edit (hash-updates convention).

<!-- No named symbol is deleted; no **Deletes** line. -->

## Implementation Steps
### Step 1: Test first (patterns → failing tests)
- [ ] In `t/cwf-claude-settings-merge.t`, add a test-local `is_read_only_safe($entry)` with **two
      independently-authored sets** (the KD3 checker, NOT imported from the script): a
      `%SAFE_PREFIX_KEYS` (keys safe as a `Bash(<key>:*)` prefix) and a `%SAFE_EXACT_KEYS` (keys
      safe **only** as an exact `Bash(<key>)` entry). Parse `Bash(<inner>)`; if the inner ends
      `:*`, strip it and require the key ∈ `%SAFE_PREFIX_KEYS`; otherwise require the whole inner
      ∈ `%SAFE_EXACT_KEYS`. This closes the d-review hole where `Bash(git branch --show-current:*)`
      would hit the same slot as the safe exact entry. Membership via `eq`/hash lookup; anchor
      every regex `\A`/`\z` + `/aa`; parse with a **negated char class** (not greedy `.*`) and
      read `$1`/named capture **only on match success**. **Author both sets from KD2 first
      principles, never by transforming the script's corpus — a comment at each definition site
      must state this**, else the checker is a tautology.
- [ ] Predicate controls (one case, both directions): **accept** the 5 corpus entries (4 prefix +
      the 1 exact); **reject** `Bash(git diff:*)`, `Bash(rg:*)`, `Bash(git:*)`, `Bash(find:*)`,
      `Bash(sed -i:*)`, `Bash(git branch:*)` (nearest dangerous neighbour), **and
      `Bash(git branch --show-current:*)`** (the prefix form of the exact entry — must be rejected
      by the prefix/exact split; currently the highest-value missing control).
- [ ] **Update existing assertions broken by the +5 unconditional seed** (d-review, misalignment):
      `t/cwf-claude-settings-merge.t:126` (TC-U1, `added 3 allowlist entries`) and `:231` (TC-U4,
      dry-run `would add 3 allowlist entries`) must become **8** (3 manifest + 5 corpus). Confirm
      no *other* count assertion regresses (`:1027` converged-run `0` and `:166` `git status`
      overlap are safe per review).
- [ ] Behavioural (clean fixture, **no** non-`.cwf` user entry): after a normal merge, read back
      `permissions.allow`; assert the 5 corpus entries are present, and that every allow entry
      NOT containing `.cwf/scripts/` (the generic corpus) passes `is_read_only_safe` and the set
      equals the expected corpus.
- [ ] Additive (**separate fixture**): a pre-existing user allow entry (e.g. `Bash(npm test:*)`)
      survives a merge; corpus adds alongside it. Kept off the clean fixture above so the
      set-equality assertion is not polluted by the user entry.
- [ ] Idempotent: a second merge adds zero duplicate corpus entries.

### Step 2: Minimal implementation
- [ ] Add `my @READ_ONLY_ALLOWLIST = (...)` (package-lexical constant) with the 5 entries.
- [ ] `push @$allow_entries, @READ_ONLY_ALLOWLIST;` after line 631.
- [ ] Run the extended test file green; run the full `t/` suite for no regressions.

### Step 3: Convention doc
- [ ] Write `.cwf/docs/conventions/shell-hygiene.md` per KD4 (new rules + links; curation table).
- [ ] Include the **"opting out of a seeded allow"** note (KD5): the durable opt-out is a user/
      `.local`-layer rule — `ask` to restore the prompt, `deny` to forbid — because deleting the
      entry from the committed `.claude/settings.json` is transient (re-seeded on next merge).
- [ ] Add the subagent link in `cwf-agent-shared-rules.md` and the `CLAUDE.md` conventions entry.

### Step 4: Hash + validate
- [ ] Refresh `.cwf/security/script-hashes.json` for `cwf-claude-settings-merge`; restore the
      script's working perms to the RECORDED value (executable helper).
- [ ] `cwf-manage validate` → OK before the checkpoint commit.

### Step 5: Manual smoke
- [ ] `cwf-claude-settings-merge --dry-run` in a scratch fixture; confirm the corpus count and
      that no entry is a bare `git`/`find`/`sed`/`rg`.
- [ ] **Redirection/substitution probe** (KD2a residual — cover **all four** undocumented vectors):
      `ls > f`, `ls >> f`, `` ls `mut` ``, and `ls $(mut)` under `Bash(ls:*)`. Operators
      (`;`/`&&`/`|`/…) are already **documented safe** (per-subcommand match), so no probe needed.
      Record each result in `## Actual Results`.
  - **Negative branch (any vector prompts, not auto-approved):** the read-only claim holds as
    designed; note it.
  - **Positive branch (any vector auto-approved) — must NOT ship silently:** (a) record it in
    `## Actual Results`; (b) add a **hard caveat** to `shell-hygiene.md` (the corpus is read-only
    *only* under the harness's arg semantics, and this vector widens it); (c) seed a **backlog
    item** for the CWF-wide re-review (the exposure spans every `permissions.allow` entry, incl.
    the existing `.cwf/` helper seeds). The task may still ship (the class is pre-existing and
    harness-wide) but only *with* (a)+(b)+(c). If the probe cannot run offline, treat as the
    positive branch (record + caveat + backlog) rather than assuming safe.

**Verified dependency (KD2a, sourced):** the read-only guarantee holds because Claude Code splits
compound commands on `&&`/`||`/`;`/`|`/`|&`/`&`/newlines and requires each subcommand to match a
rule independently (`code.claude.com/docs/en/permissions.md`) — so `Bash(ls:*)` does not approve
`ls; rm …`. Redirection/substitution are undocumented (KD2a); the residual is harness-wide, not
corpus-specific, **but** this task adds high-frequency verbs (`ls`, `git status`) that raise the
*practical* prompt-injection blast radius if the residual is real — state that honestly in the doc.

## Test Coverage
**See e-testing-plan.md for the complete test plan.** Core: the KD3 SAFE_KEYS predicate
(accept-corpus / reject-unsafe, one case each with its control), corpus presence, additive,
idempotent. The predicate is authored independently in the test — membership, not a
substring scan of the entry (the c-design security finding).

## Validation Criteria
**See e-testing-plan.md.** Gate: full `t/` suite PASS; `cwf-manage validate` OK; the doc
references resolve; no generic corpus entry outside `%SAFE_KEYS`.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished. Both
deliverables (doc + seed) and the hash refresh land together; no deferral.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Executed as planned (test-first → minimal impl → doc+anchors → hash+validate → smoke). One
deviation surfaced: the plan named only the helper for hash refresh, but editing
`cwf-agent-shared-rules.md` required a second refresh — `validate` caught it, both landed in-task.
See `f-implementation-exec.md` for step-by-step actuals.

## Lessons Learned
A plan should enumerate *every* hash-tracked file it intends to edit, not just the primary one,
so the in-task refresh set is known before `cwf-manage validate` has to surface the omission.
Folded into the retrospective recommendations.
