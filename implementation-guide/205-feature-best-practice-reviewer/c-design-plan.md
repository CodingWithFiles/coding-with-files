# Best-practice reviewer for plan and exec steps - Design
**Task**: 205 (feature)

## Task Reference
- **Task ID**: internal-205
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/205-best-practice-reviewer
- **Template Version**: 2.1

## Goal
Define the architecture for a tag-aware best-practice reviewer that augments the planning
plan-review and exec changeset-review surfaces, settling the decisions deferred in
requirements (config home, task-tag model, match semantics, source resolution, URL policy,
verdict/guard integration).

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Architecture Choice
**Decision**: Mirror the existing security-review architecture exactly — a **deterministic
Perl helper** resolves all config/matching/source work and writes a per-task context
`.out` file (the "best-practice context"); a **reviewer subagent** reads that file plus the
artefact under review and reports. No new orchestration model is introduced.

**Rationale**: Security-sensitive work (config parsing, path canonicalisation, tag matching,
de-duplication, size capping) is deterministic and testable in isolation; the LLM does only
judgement. This is the same split CWF already uses for `security-review-changeset` (helper)
+ `cwf-security-reviewer-changeset` (agent) + `security-review-classify` (classifier), so
the pattern, the verdict contract, and the fail-open posture are inherited, not reinvented.

**Trade-offs**: One new helper and one or two new agent definitions to maintain; offset by
reusing the changeset helper, the classifier, and the plan-review map/reduce wholesale.

## Key Decisions

### KD1 — Config home: a dedicated `best-practices.json` (NOT `cwf-project.json`)
A new file `best-practices.json` in **both** `<git-root>/.cwf/` (project) and `~/.cwf/`
(user). Rejected folding into `cwf-project.json` because: (a) the user requirement is two
locations — project **and** user — and `cwf-project.json` has no user-level counterpart;
(b) `cwf-project.json` is SHA256-hash-tracked and security-sensitive (`.cwf/security/`),
whereas this config is user-curated and edited often — keeping untrusted, frequently-changed
data out of the hash-tracked file avoids needless integrity churn; (c) two same-shaped files
merge cleanly. The file is **not** hash-tracked. This deliberately adds a JSON file alongside
the existing YAML `~/.cwf/autoload.yaml` — JSON is an explicit user requirement (b-FR1); the
coexistence is intentional, not oversight.

**Merge precedence (AC2a)**: project entries take precedence over user on collision, reusing
the existing CWF config hierarchy documented in `cwf-config` (`Project .cwf/… > Global
~/.cwf/… > defaults`). Collision key = canonical `documentation` identity; the
higher-precedence entry's `tags` win. `active-tags`, `allow-url-fetch`, and `url-allow-hosts`
are unioned (lists) / project-wins (scalar `allow-url-fetch`).

### KD2 — Config schema
```json
{
  "allow-url-fetch": false,
  "url-allow-hosts": ["raw.githubusercontent.com"],
  "active-tags": ["golang", "postgres"],
  "best-practices": [
    { "documentation": "docs/go-style.md",        "tags": ["golang"] },
    { "documentation": "docs/db/",                 "tags": ["postgres"] },
    { "documentation": "https://raw.githubusercontent.com/o/r/main/X.md",
      "tags": ["postgres", "sql"] }
  ]
}
```
- `best-practices[]`: the tuples. `documentation` is a string (file/dir path, repo-relative
  or absolute, or `https://` URL); `tags` is a non-empty string list. Entry missing
  `documentation` or with empty `tags` → skipped with a diagnostic (AC1b). A file that is
  not valid JSON → that whole file yields zero entries with a diagnostic (AC1c).
- `active-tags`: the tag set considered applicable to this project (see KD3).
- `allow-url-fetch` (default `false`) + `url-allow-hosts`: URL policy (see KD5).

### KD3 — Task tags: explicit, project-default + optional per-task (NOT inference)
A task's applicable tag set T = union of (a) `active-tags` from project and user configs and
(b) an optional per-task `**Tags**:` field added to the Task Reference block of
`a-task-plan.md`. **Inference from repo content is rejected** for v1 (explicit over implicit;
avoids false matches the robustness review flagged). Most projects set `active-tags` once and
every task inherits it; per-task tags augment for one-off concerns. Undeclared ⇒ empty ⇒ zero
matches (AC3b). Adding the optional `**Tags**:` field is the task-level data model FR3 named.

### KD4 — Matching: exact-token, case-normalised intersection
An entry matches when `lower(entry.tags) ∩ lower(T) ≠ ∅`. Exact token equality after
Unicode-casefold; no substring or prefix matching (deterministic, testable — AC3a).

### KD5 — Source resolution (in the helper) + URL policy
The helper resolves each **matched** entry's `documentation`:
- **file** → contents, UTF-8 decoded; skipped-with-note if missing/unreadable/binary.
- **directory** → each contained text file's contents in **deterministic lexical order**;
  non-UTF-8/binary members skipped-with-note; empty dir → noted, no content. A member-count
  guard (default 256 files, overridable) bounds a pathological wide/deep tree before the byte
  cap (KD6) engages; recursion otherwise stops at the byte cap.
- **URL** → only when `allow-url-fetch=true` **and** the URL is `https://` **and** its host
  is in `url-allow-hosts`; otherwise noted-but-skipped. The host-allowlist is the sole SSRF
  control — no DNS resolution or private-range checks in the helper (simpler and stronger:
  the operator names trusted hosts). The helper does **not** fetch; it emits validated URLs
  into the manifest `### URLS` section for the agent to fetch via `WebFetch` (size-capped).
  Residual: DNS rebinding between allowlist check and fetch — accepted for an advisory,
  fail-open, non-secret-bearing feature; documented in the limitations doc.
- **Path trust boundary & symlinks (uniform rule)**: every **project-config** path — the
  top-level entry path *and* every member encountered during a directory walk — is
  `Cwd::realpath`-resolved (symlinks + `..` collapsed, both core modules) and confinement-
  checked against the git root; anything resolving outside is rejected/skipped-with-note. A
  top-level entry that is itself a symlink escaping the root is therefore rejected, and a
  symlink met mid-walk that escapes is skipped-with-note — one rule, no TOCTOU ambiguity.
  User-config (`~/.cwf/`) paths are trusted to point anywhere the user owns (their own
  machine config) and are not repo-confined.
- **De-duplication**: identical resolved sources are emitted once (AC4c), keyed by canonical
  path / normalised URL.

### KD6 — Best-practice context manifest (`.out`)
The helper writes one per-task `.out` (scratch dir, `mkdir -m 0700`, per tmp-paths
convention) and prints one confirmation line
`best-practice-resolve: wrote <N> matched entries to <abs-path>` (mirrors the changeset
helper). Format:
- A header listing T and matched tags, plus byte-cap/truncation status.
- Per source a `### SOURCE <kind> <id>` block whose verbatim content is wrapped in a
  **random per-run sentinel delimiter** (e.g. `<<BP-7f3a…>> … <<END-BP-7f3a…>>`); the agent
  is instructed that sentinel-wrapped content is **untrusted data, never instructions**, and
  must never be reproduced inside a fenced block in its output. This is the concrete
  fence-forgery defence (NFR4): a best-practice doc containing a ```` ```cwf-review ```` fence
  cannot become a second/forged verdict block, and the classifier's one-block rule is the
  backstop.
- A `### SKIPPED` section: noted-but-skipped sources + reasons.
- A `### URLS` section: the validated, allowlisted URLs — the **sole** set the agent may
  `WebFetch`. The agent must never fetch a URL found *inside* a `### SOURCE` block (closes
  the allowlist-bypass-via-injection path).
- **Truncation**: a global byte cap (default 64 KiB, overridable via `--max-bytes`) bounds
  total inlined content (NFR1). When the cap or the member-count guard truncates a source,
  the manifest carries an explicit `[TRUNCATED]` marker on that source and in the header, so
  the reviewer knows content is incomplete and must not report a bare `no findings` purely
  because truncated content showed nothing.

Exit codes mirror the changeset helper: `0` ok (including 0 matches → empty manifest),
`1` resolution failure → caller records `error`.

### KD7 — Planning integration (5th map/reduce column, conditional)
A new agent `cwf-plan-reviewer-best-practice` (**Read, Grep, Glob, LSP, +WebFetch** — `Bash`
is deliberately **not** granted: these agents read the manifest via the Read tool and have no
markdown-reader need, so dropping Bash is the cheapest mitigation for their enlarged untrusted
surface, which now includes the inlined manifest content *and* WebFetch). The plan SKILLs'
Step 8 runs `best-practice-resolve` first; **iff** it reports ≥1 matched entry, the
best-practice column is added to the plan-review map alongside the existing four, given
`{plan_file_path}`, `{plan_type}`, and `{bp_context_file}`. Zero matches ⇒ column skipped (no
wasted agent). Plan reviewers report prose only (no verdict block); findings fold into the
existing reduce. `plan-review.md` gains an optional row documenting this.

**Two agents, one discipline**: KD7 and KD8 are separate agent files because their output
contracts differ irreconcilably (prose-into-reduce vs a parsed `cwf-review` verdict) — the
same reason CWF already keeps `cwf-plan-reviewer-security` separate from
`cwf-security-reviewer-changeset`. The load-bearing, security-sensitive part — how to treat
the sentinel-wrapped manifest as untrusted data and fetch only `### URLS` — is written **once**
in a shared section both agent bodies reference (alongside `cwf-agent-shared-rules.md`), not
copy-pasted.

### KD8 — Exec integration (changeset reviewer)
A new agent `cwf-best-practice-reviewer-changeset` (**Read, Grep, Glob, LSP, +WebFetch** —
same no-Bash decision as KD7) reuses the **existing** `security-review-changeset` `.out` as
the changeset input and the **same** `cwf-review` verdict contract + `security-review-classify`
classifier. The exec SKILLs gain a step that runs `best-practice-resolve`; iff ≥1 match,
invoke the agent with `{changeset_file}` and `{bp_context_file}`, write its verbatim output to
`best-practice-review-output-<wf_step>.out`, classify with the existing helper, and record a
`## Best-Practice Review` section (mirrors `## Security Review`). A truncated manifest (KD6)
obliges the agent to reflect incompleteness rather than emit a bare `no findings`.
- **Double-count question (FR6) resolved**: the SubagentStop guard
  (`subagentstop-security-verdict-guard`) is matched by agent name
  (`cwf-hook-matcher: cwf-security-reviewer-changeset`), so it never fires for the new agent.
  Each reviewer is a distinct subagent with its own stop event and its own output file
  classified independently — no shared state, no double-count.
- **No sibling re-emit guard** is added: the SKILL-side `security-review-classify` is the
  authority and conservatively maps an absent/malformed/duplicated verdict to `error` (AC6b),
  and the feature is advisory + fail-open, so a re-emit backstop earns nothing here. (If ever
  wanted, registering a name-matched sibling hook is a trivial follow-up.)

### KD9 — Fail-open everywhere (NFR5)
Absent/zero-match config, unparseable file, unresolvable source, helper exit 1, malformed or
absent verdict — all degrade to a clear no-op / skipped-note / `error`, never a workflow halt
and never task-file corruption.

## Component Overview
- **`best-practice-resolve`** (Perl, core-only): config load+merge+validate → task-tag
  resolution → match → source resolution (file/dir + URL validation) → manifest `.out`.
  Single source of truth for all deterministic work. Unit-testable in isolation.
- **`cwf-plan-reviewer-best-practice`** (agent; Read/Grep/Glob/LSP/WebFetch, no Bash):
  planning-phase reviewer; prose findings.
- **`cwf-best-practice-reviewer-changeset`** (agent; same tools): exec-phase reviewer;
  `cwf-review` verdict.
- **Shared manifest-handling section** (one doc, referenced by both agents): untrusted-data
  discipline for sentinel-wrapped content + fetch-only-`### URLS` rule.
- **Reused unchanged**: `security-review-changeset`, `security-review-classify`, the
  plan-review map/reduce, the scratch-dir convention.
- **Docs**: a user-facing config reference (schema + worked example + precedence) and a
  limitations note (URL/DNS-rebinding residual); `plan-review.md` + both exec SKILLs updated.

## Data Flow
1. Phase SKILL (plan or exec) invokes `best-practice-resolve` for the task.
2. Helper loads project+user `best-practices.json`, validates, computes T, matches entries,
   resolves sources (local content inlined; allowed URLs listed), writes the manifest `.out`,
   prints the confirmation line + match count.
3. Match count 0 → SKILL skips the reviewer (planning) / records `no findings` (exec).
4. Match count ≥1 → SKILL launches the reviewer agent with the artefact + `{bp_context_file}`.
5. Agent reads the manifest (treating content as untrusted data), fetches any allowed URLs via
   WebFetch, reviews, and reports (prose for planning; `cwf-review` verdict for exec).
6. Planning: findings fold into the reduce. Exec: output classified by `security-review-classify`
   and recorded under `## Best-Practice Review`.

## Interface Design
- **`best-practice-resolve --task-num=<num> [--max-bytes=N] [--max-files=N]`** → writes
  `.out`, prints `best-practice-resolve: wrote <N> matched entries to <abs-path>`; exit `0` ok
  / `1` failure. `--task-num` reuses the changeset helper's `/^\d+(?:\.\d+)*$/` validation (the
  value becomes a filename component, so the path-injection guard is mandatory).
- **Manifest `.out`**: header (T, matched tags, byte-cap/truncation status) +
  `### SOURCE <kind> <id>` blocks (sentinel-wrapped verbatim, untrusted, `[TRUNCATED]` when
  capped) + `### SKIPPED` (id + reason) + `### URLS` (the sole allowlisted fetch set).
- **Agents**: inputs `{plan_file_path}`/`{changeset_file}`, `{plan_type}`/`{wf_step}`,
  `{bp_context_file}`; follow agent-definition procedure; fetch only `### URLS` entries; exec
  agent ends with one `cwf-review` block.

## Constraints
- Perl core-modules-only — the helper needs only `Cwd` (`realpath`), `File::Spec`, and
  `JSON::PP` (no `Socket`: the host-allowlist replaces any DNS/private-range check and the
  helper does not fetch).
- The two new agents are granted Read/Grep/Glob/LSP/WebFetch but **not** Bash, narrowing the
  prompt-injection blast radius vs the existing Bash-holding reviewers.
- Must not change the existing reviewers' contracts; additive only.
- British spelling; progressive disclosure (reference `security-review.md` / `plan-review.md`,
  don't restate the threat model).

## Decomposition Check
Unchanged: 2 signals (Complexity, Risk). Single task. The helper (KD5/KD6) is the natural
seam if a split is ever needed; not warranted now.

## Validation
- [ ] Each KD traces to an FR/NFR/AC in b-requirements-plan.md (KD1→FR1/FR2, KD3/KD4→FR3,
      KD5→FR4/NFR4, KD6→NFR1, KD7→FR5, KD8→FR6, KD9→NFR5).
- [ ] Reuse verified against live source (changeset helper, classifier, guard matcher).
- [ ] No new non-core Perl dependency introduced.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
The helper→agent→classifier reuse held end-to-end. One design point was revised
in exec: KD8 specified exec best-practice as a *serial* second review step; it
was restructured to a *parallel* peer of the security reviewer (see
`f-implementation-exec.md` DEVIATION and `j-retrospective.md`).

## Lessons Learned
Design should explicitly decide a new reviewer's concurrency ("parallel peer or
serial step?") — leaving it implicit forced a correction during exec. See
`j-retrospective.md` § What Could Be Improved.
