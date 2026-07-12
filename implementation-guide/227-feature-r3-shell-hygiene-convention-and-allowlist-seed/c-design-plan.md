# R3 shell-hygiene convention and allowlist seed - Design
**Task**: 227 (feature)

## Task Reference
- **Task ID**: internal-227
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/227-r3-shell-hygiene-convention-and-allowlist-seed
- **Template Version**: 2.1

## Goal
Define the architecture for two deliverables: (1) a shipped shell-hygiene convention doc,
and (2) a read-only generic-command allowlist seed added to the **existing**
`cwf-claude-settings-merge` path — both reuse-first, fail-closed, and reversible.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### KD1 — Extend `cwf-claude-settings-merge`, one merge call, no new writer (D3 resolved)
- **Decision**: The read-only corpus is a **package-lexical constant**
  (`my @READ_ONLY_ALLOWLIST = (...)`) in `.cwf/scripts/command-helpers/cwf-claude-settings-merge`.
  Its entries are **appended to the existing `@allow_entries` array** built from
  `partition_manifest`, so the helper's single existing `merge_allow($settings, $allow_entries)`
  call (one merge, one count) is preserved — no second `merge_allow` call. *(Revised from the
  earlier `read_only_allowlist()` sub form — a package-lexical constant mirrors the file's own
  `$CANONICAL_*` precedent exactly and drops a single-callsite wrapper; per the d-plan reviewers.)*
- **Rationale**: `merge_allow` is additive (`%seen` dedupe → idempotent), lands in
  `.claude/settings.json` → `permissions.allow`; the helper reads via `read_settings` (which
  **dies** on a symlinked/non-regular/**malformed-JSON** settings file) and writes via
  `atomic_write_text` (symlink-safe). Reuse satisfies FR8 (additive/idempotent/safe-on-malformed)
  and NFR3 (no second writer) by construction. The compile-time constant mirrors the helper's
  established `$CANONICAL_PERL5OPT` / `$CANONICAL_RULES_INJECT_CMD` FR4(e) pattern — hash-tracked
  with its own script, never sourced from probe/manifest content.
- **Trade-offs**: Couples the corpus to the merge helper's lifecycle — acceptable (both are the
  "what does cwf-init put in settings.json" concern).

### KD1a — Settings layer: seed the committed project file, not user-global or `.local` (sourced)
- **Decision**: The corpus lands in the **project `.claude/settings.json`** (committed/shared) —
  which is where `cwf-claude-settings-merge` already writes. **Not** `~/.claude/settings.json`
  and **not** `.claude/settings.local.json`.
- **Rationale (settings-merge semantics, verified against official docs**
  `code.claude.com/docs/en/settings.md` + `permissions.md`**)**: Claude Code reads three permission
  scopes — user `~/.claude/settings.json`, project `.claude/settings.json`, project-local
  `.claude/settings.local.json` (plus managed/enterprise on top) — and **`permissions.allow`/`deny`/
  `ask` MERGE (union) across scopes rather than override**. The task goal is that a *new project
  and everyone who clones it* inherits the corpus → that requires the **committed** layer
  (`.claude/settings.json`). The other two are wrong for this goal:
  - `~/.claude/settings.json`: per-user, not shipped with the repo; seeding it at project init
    leaks project config into the user's global scope.
  - `.claude/settings.local.json`: **harness-owned** (the harness rewrites it on every permission/
    sandbox grant → two-writer clobber, per project memory) **and** gitignored, so it would never
    reach a cloner.
- **Consequence**: because scopes union, our entries are strictly *additive* to whatever a user
  already has in any layer — consistent with `merge_allow`'s additive `%seen` dedupe. And because
  `deny`/`ask` outrank `allow`, a user's pre-existing stricter rule is never overridden by a seeded
  `allow` (net-protective).
- **Committed-layer trust (recorded as deliberate)**: writing `allow` into a *committed, shared*
  file means every cloner auto-authorises these prefixes without a per-machine prompt — the exact
  surface KD2/KD3 contain (read-only-for-all-args corpus + independent SAFE_KEYS gate). The
  residual reliance on Claude Code's own project-settings trust model for a malicious *downstream*
  PR that widens the committed allow list is inherent to the committed-settings feature and out of
  scope here.

### KD2 — Corpus admission criterion: read-only for the ENTIRE glob-admitted arg space
Because the harness auto-approves `Bash(<prefix>:*)` for **every** argument string the prefix
admits, an entry qualifies only if it is read-only across that whole set — not merely as typed.
An entry qualifies iff **all** hold:
1. **Read-only for all argument vectors**: no argument string the `:*` glob admits can mutate,
   execute an arbitrary child, or do network I/O.
2. **No prefix escape**: the command word (+ subcommand) has no flag/subcommand anywhere in its
   option space that violates (1).
3. **Not discouraged by the convention** (coherence): the seed must not pre-authorise a command
   the shell-hygiene doc steers you away from.

**Corpus (final):** `ls`, `pwd`, `git status`, `git rev-parse` (all `Bash(<cmd>:*)`), and
`git branch --show-current` as an **exact** entry `Bash(git branch --show-current)`. Each ships
with a one-line read-only justification (FR5).

**Excluded, with reason (this table IS the FR5/FR6 evidence the reviewers required):**
| Tempting entry | Why excluded |
|---|---|
| `git diff` / `git log` / `git show` (`:*`) | admit `--output=<file>` (file clobber) and `--ext-diff` / `-p --ext-diff` (arbitrary exec) |
| `rg` (`:*`) | admits `--pre <cmd>` / `--pre-glob` (arbitrary child execution) |
| `grep` (`:*`) | read-only, but the convention prefers the **Grep tool**; excluded for coherence (criterion 3), not safety |
| bare `git` (`:*`) | admits `git commit` / `push` / `branch -D` (mutation) |
| `find` / `sed` (`:*`) | admit `-exec`/`-delete` and `-i` (exec / in-place write) |
| `git branch` (`:*`) | admits `git branch -D` — hence the exact `--show-current` entry, not a prefix |

### KD2a — Harness matching semantics: operators verified safe; redirection/substitution are a harness-wide residual (sourced)
KD2's "read-only for all arg vectors" reasoning covers a command's own flag/subcommand space; it
does not by itself cover what the shell admits *around* the command. Verified against the official
docs (`code.claude.com/docs/en/permissions.md`):
- **Shell operators — DOCUMENTED SAFE**: Claude Code is shell-operator-aware; the recognised
  separators are `&&`, `||`, `;`, `|`, `|&`, `&`, and newlines, and **a rule must match each
  subcommand independently**. So `Bash(ls:*)` does **not** approve `ls; rm -rf x` or
  `ls && curl … | sh`. This closes the primary widening vector. (The same page confirms exec
  wrappers — `watch`/`setsid`/`flock` — and `find -exec`/`-delete` always prompt, corroborating
  our exclusions.)
- **Redirection (`>`,`>>`) and command substitution (`$(…)`/backticks) — UNDOCUMENTED**: the docs
  are silent on whether `ls > file` or `ls $(mutating)` are auto-approved under a prefix rule.
  **Framing (why this does not block):** if either *were* admitted, it would be a **harness-wide**
  property of `Bash(<prefix>:*)` matching affecting **every** allow entry — including the many
  `.cwf/scripts/command-helpers/*:*` entries CWF already seeds today — not a risk our read-only
  corpus uniquely introduces. Our corpus is therefore no worse than the existing seed on this axis.
- **Action**: a manual live probe (d-plan Step 5) checks **all four** undocumented vectors
  (`>`, `>>`, backtick, `$(…)`) on a fixture. A positive result (any vector auto-approved) must
  **not** ship silently: record it, add a hard caveat to `shell-hygiene.md`, and seed a backlog
  item for the CWF-wide re-review; an un-runnable probe is treated as positive. Surfaced, not smoothed.
- **Practical blast radius (honest note)**: even though the residual is harness-wide, this task
  adds **high-frequency** verbs (`ls`, `git status`) that a prompt-injection payload weaponises
  more readily than the pre-existing low-frequency `.cwf/scripts/command-helpers/*:*` entries. The
  *class* is pre-existing; the *practical* exposure grows if the residual is real — stated in the doc.

### KD3 — Fail-closed gate: allowlist-membership predicate, not a substring scan (FR6)
- **Decision**: The `t/` predicate `is_read_only_safe($entry)` decides safety by **membership**,
  not by scanning the literal for bad flags (a scan passes `git diff:*` because the string holds
  no bad token — the reviewers' key finding). It uses **two independently-maintained sets** so a
  prefix entry and an exact entry are never conflated (d-review hole):
  1. Parses `Bash(<inner>)`.
  2. If `<inner>` ends `:*`: strip it, require the key ∈ **`%SAFE_PREFIX_KEYS`** (commands
     hand-verified read-only for **all** arg vectors). Else: require the whole `<inner>` ∈
     **`%SAFE_EXACT_KEYS`** (safe only as an exact entry). This rejects
     `Bash(git branch --show-current:*)` (prefix form of the exact entry) which a single-set
     predicate would wrongly accept.
  3. Rejects any bare `git`/`find`/`sed`/`rg` and anything outside both sets — secondary defence.
  - **Regex discipline** (validation-security, per Perl BP): anchor with `\A`/`\z` (never
    `^`/`$` — `$` matches before a trailing `\n`), match ASCII with `/aa`, parse with a negated
    char class (not greedy `.*`), read captures only on match success. Membership via `eq`/hash.
- **Negative control with its positive control in the same case** (Task 220 lesson): plant
  `Bash(git diff:*)`, `Bash(rg:*)`, `Bash(git:*)`, `Bash(find:*)`, `Bash(sed -i:*)`,
  `Bash(git branch:*)` (nearest dangerous neighbour), and `Bash(git branch --show-current:*)`
  (prefix form of the exact entry) → assert **rejected**; the real corpus → assert **accepted**.
- **Rationale**: The literal corpus is the single source; SAFE_KEYS + the predicate are the
  independent checker that stops a future maintainer widening the corpus unsafely. Test-enforced,
  no runtime cost on the offline seeder.

### KD4 — Convention doc: main-loop-scoped, add-and-link (D2 resolved)
- **Decision**: New doc `.cwf/docs/conventions/shell-hygiene.md`, main-loop-scoped; it does
  **not** supersede the subagent rubric `subagent-tool-selection.md`. It states only rules not
  already documented and **links** overlapping surfaces (FR2).
- **New content it owns**: heredoc / inline `perl -e`,`python -e` avoidance (write to the
  per-task scratch dir, run from there); `chmod +x && ./script`, not `perl script`/`bash script`;
  no `perl -c`/`bash -n` pre-check; avoid command substitution that trips prompts; a brief
  NUL-separated git-path note (the canonical `git-path-output.md` is maintainer-only, not shipped);
  and a short **"opting out of a seeded allow"** note (per KD5): the **durable** opt-out is a
  layer rule — `ask` to restore the confirmation prompt, `deny` to forbid outright — in your user
  or `.local` settings; deleting the entry from the committed `.claude/settings.json` is
  **transient** (a later `cwf-init`/merge re-adds it).
- **Links (not restated)**: the anti-pattern table (`cwf-agent-shared-rules.md`), the tool-tier
  rubric (`subagent-tool-selection.md`), tool-check enforcement (Task 220), `tmp-paths.md`.

### KD5 — Default posture: on-by-default, no per-project decline knob (D1 resolved)
- **Decision**: The read-only corpus is seeded **unconditionally** by `cwf-init`, exactly like
  the existing `.cwf/`-helper allow entries in the same helper — **no new opt-out toggle**.
- **Rationale**: `cwf-init` is itself the opt-in; the existing helper already seeds an allowlist
  unconditionally, so a separate decline knob for a strictly-read-only addition is an unjustified
  moving part. This resolves FR8's "declined" clause (there is no decline state — nothing to keep
  byte-for-byte-unchanged beyond the additive-merge guarantee already met).
- **User opt-out is the deny/ask escape hatch (NFR2, sourced)**: because permission scopes union
  and **`deny` > `ask` > `allow`** (verified: `code.claude.com/docs/en/permissions.md` — a deny
  beats a matching allow regardless of specificity), a user who dislikes a seeded allow adds a rule
  in their **user or `.local` layer** — `ask` to restore the normal confirmation prompt, `deny` to
  forbid outright. That layer rule is the **durable** opt-out (NFR2's "single documented action"),
  because `merge_allow` never touches `deny`/`ask` or `settings.local.json`. Deleting the entry
  from the committed `.claude/settings.json` is **not** equivalent: it is transient — the additive
  `merge_allow` re-adds it on the next `cwf-init`/merge. Documented in the KD4 doc.
- **Accepted limitation (surfaced, not smoothed)**: `merge_allow` is append-only — it has no
  *automatic* retraction path (unlike `reconcile_sandbox`'s authoritative region), so a later
  `cwf-init` cannot itself pull a mis-shipped entry from users' `settings.json`. But the claim is
  narrower than before: **corpus correctness (KD2/KD3) is the primary defence for the *allow*
  mechanism**, and the deny/ask escape hatch above is a real user-side mitigation on top. The
  gate is still fail-closed and the corpus minimal + provably read-only-for-all-args. An
  authoritative prune region is **not** built now (no unsafe entry ships); a separate task if ever.

## System Design

### Component Overview
- **`shell-hygiene.md`** (new, `.cwf/docs/conventions/`): owns the NEW rules; links the rest.
- **`cwf-claude-settings-merge`** (edit): `@READ_ONLY_ALLOWLIST` constant; `push @$allow_entries, @READ_ONLY_ALLOWLIST` after `partition_manifest` (the manifest result is an arrayref `$allow_entries`), before the single `merge_allow`.
- **Runtime reference** (edit, FR3): the **load-bearing** anchor is a static pointer to
  `shell-hygiene.md` from the shipped `cwf-agent-shared-rules.md` — read by the shell-doing
  review/exec subagents. **d-review correction**: `cwf-init` does *not* seed a `## Conventions`
  section into an end-user's CLAUDE.md (only the 3-line `claude-md-preamble`), so this repo's
  `CLAUDE.md` `## Conventions` entry is **maintainer/dogfood-only** (parity with the siblings,
  which likewise aren't force-injected into an end-user main loop). Broader end-user *main-loop*
  reach is out of scope (would need a `rules-inject.txt`/preamble change — a separate decision).
  Reference is static CWF text — no user-string interpolation (FR3 injection-safety).
- **Test** (new/extended `t/`): the KD3 SAFE_KEYS predicate + negative/positive controls.
- **`script-hashes.json`** (refresh): the helper is hash-tracked → refresh in the same commit.

### Data Flow (seed)
1. `/cwf-init` step 6d runs `cwf-claude-settings-merge`.
2. Helper reads `.claude/settings.json` (dies safely if malformed/symlinked).
3. `@allow_entries` = manifest-derived `.cwf/` helpers (existing) **+** `@READ_ONLY_ALLOWLIST` (new).
4. Single `merge_allow` adds only missing entries (existing entries + order preserved).
5. `atomic_write_text` writes back symlink-safely. Re-run = convergent no-op.

### Rule curation table (FR7 — doc rules; skeleton finalised in implementation)
| Candidate (source) | Ship? | Rationale |
|---|---|---|
| Heredocs / inline `perl -e`,`python -e` → scratch file | **Include** | Generalisable; trips prompts; not yet shipped |
| `chmod +x && ./script`, not `perl script`/`bash script` | **Include** | Portable POSIX idiom; not yet shipped |
| No `perl -c` / `bash -n` pre-check | **Include** | Generalisable; not yet shipped |
| One-off scripts / temp files → per-task scratch dir | **Include (link)** | Link `tmp-paths.md`, don't restate |
| Avoid command substitution that trips prompts (`cd "$(git rev-parse …)"` at root) | **Include** | Generalisable prompt-avoidance |
| `cat\|grep`, `sed -n` ranges, `find -exec`, `tee`, `; echo EXIT` | **Include (link)** | Already in the anti-pattern table → link only |
| NUL-separated git path output (`-z` + split) | **Include (brief)** | Cross-project; canonical doc is maintainer-only → state briefly |
| `sleep 1 && git` prefix | **Exclude** | Harness-timing workaround, not a portable shell rule |
| `use utf8;` / `PERL5OPT=-CDSLA` / core-modules-only | **Exclude** | CWF-development Perl conventions, not shell hygiene |
| "Filenames are not classifications" / no personal names / British spelling | **Exclude** | Out of category |

## Interface Design
- **`@READ_ONLY_ALLOWLIST`** — package-lexical constant list of `Bash(...)` strings; consumed in
  list context. `partition_manifest` returns the arrayref `$allow_entries`, so append via
  `push @$allow_entries, @READ_ONLY_ALLOWLIST` (deref), keeping the single `merge_allow` call.
- **`merge_allow($settings, $allow_entries)`** — existing signature, single existing call, reused verbatim.
- **`is_read_only_safe($entry)`** (test-side) → bool; SAFE_KEYS membership + `\A\z`/`/aa` anchoring.
- **Doc reference** — one static Markdown link from a main-loop-read shipped surface.

## Constraints
- `.cwf/docs/conventions/` (shipped), never `docs/` (Location split).
- Hash refresh for `cwf-claude-settings-merge` in the same commit.
- No second writer; link, don't restate, existing rule surfaces.

## Decomposition Check
- [ ] Time >1wk? No. — [ ] People >2? No. — [ ] 3+ concerns? No (doc + seed).
- [ ] Risk needing isolation? No (fail-closed gate + minimal provably-safe corpus). —
- [x] Independence? doc/seed separable but small & context-shared → 1 signal, no decomposition.

## Validation
- [ ] Design review completed (Step 8 plan review)
- [x] Reuse target verified in source (`merge_allow`:225, `read_settings`:198, `atomic_write_text`:436)
- [x] Integration point verified (`cwf-init` SKILL step 6d invokes the helper)
- [x] Corpus prefix-safety re-verified (git diff `--output` / rg `--pre` escapes excluded)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
The design's two load-bearing decisions held through exec: the committed-project settings layer
as the seed target (what a cloner inherits) and the deny/ask `.local`-layer escape hatch as the
opt-out. The design-review round added the exact-vs-prefix key split and corrected the FR3
anchor (commits `3576c62`, `8a1d532`) before any code was written.

## Lessons Learned
Splitting the safe-key sets into `%SAFE_PREFIX_KEYS` and `%SAFE_EXACT_KEYS` at design time — not
a single set with a substring scan — is what let the test gate distinguish the exact entry from
its unsafe prefix form. A membership model beats a pattern-match model for a security allowlist.
