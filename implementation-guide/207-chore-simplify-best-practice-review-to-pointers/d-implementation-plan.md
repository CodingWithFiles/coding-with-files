# Simplify best-practice review to doc pointers - Implementation Plan
**Task**: 207 (chore)

## Task Reference
- **Task ID**: internal-207
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/207-simplify-best-practice-review-to-pointers
- **Template Version**: 2.1

## Goal
Gut the best-practice machinery down to: select tag-matched local doc pointers,
hand the reviewer that path list, let it Read the docs itself.

## Key design decision — keep a slim resolver, preserve the consumer contract
The resolver survives (it is not folded into the agent prompt) because three
deterministic jobs are better in one tested place than re-derived by an LLM:
config merge (project + user), tag-set union (`active-tags` ∪ per-task
`**Tags**`), and project-path realpath-confinement. It keeps the **exact**
consumer contract — exit code + `wrote <N> matched entries to <abs-path>` count
line + a `.out` file at `{bp_context_file}` — so `plan-review.md` and the two
exec SKILLs need only wording tweaks, not logic changes.

What changes is the `.out` payload: it stops being an inlined, sentinel-wrapped,
byte-capped manifest and becomes a plain **list of doc paths** (one per line)
plus the existing `### SKIPPED` diagnostics. Deleted outright: URL detection /
allowlist / `### URLS`, the per-run sentinel, content inlining + byte cap, and
the directory content-walk (a dir pointer is emitted as-is; the reviewer's Glob
handles enumeration). `--max-bytes` / `--max-files` go with them.

**Retained security property**: project-config pointers are still
realpath-confined to the git root before emission; user-config pointers stay
trusted. Per-member confinement is gone with the dir-walk — acceptable because
nothing is inlined into agent context any more and the feature is advisory.

## Files to Modify
### Primary Changes
- `.cwf/scripts/command-helpers/best-practice-resolve` — delete `is_url`,
  `resolve_url`, `@URLS`/`%SEEN_URL`, `$allow_url`/`%url_hosts`,
  `make_sentinel`, `inline_file`, `add_block`, byte-cap state
  (`$REMAINING`/`$CAP_HIT`/`$TRUNCATED`), `gather_dir_files`/`resolve_dir`
  content-walk, and `--max-bytes`/`--max-files`. `resolve_path` keeps the
  `realpath` + `-e` + `confined()` gate **for dirs too** (not just files — the
  per-member walk that formerly caught escaping members is gone, so an
  unconfined `../../etc`-style dir pointer must be rejected at the top level)
  and emits the confined pointer to a `@PATHS` list; `render_manifest` becomes a
  path-list renderer (header + paths + `### SKIPPED`). Keep config load/merge,
  tag union, `read_task_tags`, dedup, confinement, fail-open (eval-wrapped
  `.out` write; exit 0 + count 0 still writes a `.out`), count line. Rewrite the
  header comment block to the new contract. **Note**: a stale URL entry now
  falls through `resolve_path` → "missing or unreadable" → `### SKIPPED` (no
  `is_url` branch); that graceful degradation is intended, not an error.
- `.claude/agents/cwf-best-practice-reviewer-changeset.md` — drop `WebFetch`
  from `tools:` (keep `effort: high` and the no-Bash posture); rewrite the
  procedure (read the `{bp_context_file}` path list, Read each listed doc,
  assess the changeset against them, cite the doc path); delete the
  sentinel/URL/truncation discipline; fix the "Bash withheld" note (no
  inlined-untrusted-content / WebFetch rationale any more). **Add the agent-layer
  fail-closed rule**: if a listed doc path cannot be Read, emit `error` (not a
  bare `no findings`) — "broken must never read as clean" now applies at the
  agent, since reading the docs is its responsibility, not the helper's.
- `.claude/agents/cwf-plan-reviewer-best-practice.md` — same treatment for the
  planning reviewer (prose-only, no verdict block — unchanged); the
  unreadable-doc case is noted in prose rather than a verdict token.
- `.cwf/docs/skills/best-practice-review.md` — replace § "Manifest discipline"
  with a short "Doc-list discipline" (read the path list, Read each doc, assess;
  the docs are the user's own curated/vetted files); update the lead-in line
  (line 3, "owns … manifest-handling discipline"); delete the URL / SSRF /
  DNS-rebinding / sentinel / byte-cap / `### URLS` content; update the config
  schema block (drop `allow-url-fetch` + `url-allow-hosts`); update the
  "Why no Bash" / "Why no WebFetch" sections. **Document the one residual risk**
  in §(e) "safe here because <invariant>" form: a confined project dir pointer
  may contain a symlink escaping the root; safe here because the reviewer only
  Reads (no Edit/Write), content is advisory, and the confinement guarantee is
  on the *pointer*, not its transitive symlink targets.

### Supporting Changes
- **Anchor-fix (all four referencing files)** — the § "Manifest discipline"
  rename to "Doc-list discipline" has four live `§` cross-references that must be
  updated in lock-step or they dangle:
  `.claude/agents/cwf-best-practice-reviewer-changeset.md:30`,
  `.claude/agents/cwf-plan-reviewer-best-practice.md:27`,
  `.claude/skills/cwf-implementation-exec/SKILL.md:53`,
  `.claude/skills/cwf-testing-exec/SKILL.md:47`. (skill-anchor-drift.t does not
  assert these, but they are real references.)
- `.cwf/docs/skills/plan-review.md` §0 — reword "manifest" → "doc-path list";
  contract (exit/count/abs-path) unchanged.
- `.claude/skills/cwf-implementation-exec/SKILL.md` &
  `.claude/skills/cwf-testing-exec/SKILL.md` — same wording tweak + the anchor
  fix above; branch logic on exit code + count is unchanged.
- `t/best-practice-resolve.t` — rewrite: drop URL TCs (TC-1 URL leg, the
  `allow-url-fetch`/host-allowlist cases), inlining/sentinel/byte-cap TCs, and
  dir-member content TCs. **Re-point every retained TC's content-grep**
  (`manifest_of`, `FILE_BODY`/`DIR_MEMBER` body assertions, the
  `# matched entries:` header check in TC-4/5/6/8/10/11/13/14) from
  content-presence to **path-presence**. Keep/adapt: tag match (casefold,
  exact-token, empty set), `active-tags` ∪ per-task `**Tags**`, project
  precedence, absent/broken config fail-open, dedup, project-path confinement
  (TC-12). Add negative TCs: a URL entry lands in `### SKIPPED` (not error); an
  empty/missing dir degrades to a SKIPPED note; exit 0 + count 0 still writes a
  `.out`. (Detailed in e-testing-plan.)
- `.cwf/security/script-hashes.json` — refresh hashes for the three changed
  tracked files (resolver + both agent defs) **in this same commit**
  (hash-updates.md).
- `CHANGELOG.md` — record the breaking simplification (URL support + manifest
  machinery removed; config schema reduced). State that an existing
  `best-practices.json` with URL entries or the two removed keys will now
  **silently no-op** those (URL → SKIPPED diagnostic; unknown keys ignored) —
  the migration signal for users.

### Explicitly NOT changed
- `.claude/settings.json` — the `Bash(...best-practice-resolve:*)` grant stays
  (helper still invoked); no WebFetch grant lives here to remove.
- `.claude/settings.local.json` — carries a per-machine, untracked
  `WebFetch(domain:raw.githubusercontent.com)` grant (the last URL-feature
  trace). Out of scope (not shipped, not hash-tracked); flagged so the
  implementer does not chase a `raw.githubusercontent.com` grep. Mention to user.
- `security-review-classify` — reused verbatim by the exec reviewer; untouched.

## Implementation Steps
### Step 1: Resolver
- [ ] Rewrite `best-practice-resolve` to the path-list contract; delete URL,
      inlining, sentinel, cap, and dir-walk code paths and the two `--max-*` opts.
- [ ] Restore working perms to the recorded value (0500), not 0700.

### Step 2: Agents + docs
- [ ] Update both agent defs (drop WebFetch; keep `effort: high`; rewrite
      procedure + Bash note; add the unreadable-doc → `error`/note rule).
- [ ] Rewrite `best-practice-review.md` to the new contract; remove URL/limits;
      update the lead-in line; document the residual symlink-escape risk (§(e)).
- [ ] Reword `plan-review.md` §0 and the two exec SKILLs (path list, not manifest).
- [ ] Update the four `§ "Manifest discipline"` cross-references to the new
      anchor (both agent defs + both exec SKILLs).

### Step 3: Tests
- [ ] Rewrite `t/best-practice-resolve.t` to the new contract; remove dead TCs.
- [ ] Run the full `prove` suite; confirm green (esp. skill-anchor-drift,
      which references no best-practice anchors but guards the SKILL bodies).

### Step 4: Hashes + changelog
- [ ] Refresh `script-hashes.json` for the 3 changed tracked files.
- [ ] Add the CHANGELOG breaking-change entry.
- [ ] `cwf-manage validate` → OK.

### Step 5: Output-level smoke test
- [ ] Run the resolver against a synthetic config with a file + a dir pointer;
      grep the `.out` for the path list and for **absence** of the removed
      surface (sentinel, `### URLS`, `[TRUNCATED]`).

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.
Removal must be total — no orphaned references to URLs, sentinel, inlining, the
byte cap, or WebFetch left in any skill, doc, agent, or test.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
