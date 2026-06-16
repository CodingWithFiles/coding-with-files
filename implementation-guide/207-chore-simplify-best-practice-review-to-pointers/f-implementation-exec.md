# Simplify best-practice review to doc pointers - Implementation Execution
**Task**: 207 (chore)

## Task Reference
- **Task ID**: internal-207
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/207-simplify-best-practice-review-to-pointers
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Actual Results

### Step 1: Resolver
- **Planned**: Rewrite `best-practice-resolve` to the path-list contract; delete
  URL, inlining, sentinel, cap, and dir-walk code paths and the two `--max-*`
  opts. Restore perms to 0500.
- **Actual**: Rewrote the helper. Deleted `is_url`, `resolve_url`, `@URLS`/
  `%SEEN_URL`, `$allow_url`/`%url_hosts`, `make_sentinel`, `inline_file`,
  `add_block`, byte-cap state, `gather_dir_files`/`resolve_dir`, `display_id`,
  `--max-bytes`/`--max-files`, and the `Encode` import. `resolve_path` now
  realpath-resolves, existence-checks, confines project pointers (files **and**
  directories), and emits `{ kind => file|dir, path => realpath }` to `@PATHS`.
  `render_manifest` → `render_doclist` (header + `### DOCS` `file:`/`dir:` list +
  `### SKIPPED`). Config merge dropped `allow-url-fetch`/`url-allow-hosts`.
  Consumer contract (exit code, count line, `.out` path) unchanged. Restored to
  `0500`.
- **Deviations**: None.

### Step 2: Agents + docs
- **Planned**: Drop WebFetch from both agents; rewrite procedures; add the
  unreadable-doc rule; rewrite `best-practice-review.md`; reword `plan-review.md`
  §0 and the two exec SKILLs; fix the four anchor cross-references.
- **Actual**: Both agent defs now `tools: Read, Grep, Glob, LSP` (no WebFetch);
  procedures rewritten to "Read the `### DOCS` paths directly"; the changeset
  agent emits `error` on an unreadable listed doc, the plan agent notes it in
  prose; `effort: high` retained on the changeset agent. `best-practice-review.md`
  rewritten: § "Doc-list discipline" replaces § "Manifest discipline", URL/SSRF/
  DNS-rebinding/sentinel/byte-cap content removed, config schema reduced, residual
  symlink-escape risk documented in §(e) form. The four `§ "Manifest discipline"`
  cross-references (both agent defs, both exec SKILLs) updated to
  § "Doc-list discipline".
- **Deviations**: `plan-review.md` needed no edit — it already referred to
  "best-practice context" generically and never used the word "manifest" (the
  d-plan's anticipated reword was a no-op). Verified by grep.

### Step 3: Tests
- **Planned**: Rewrite `t/best-practice-resolve.t` to the new contract; remove
  dead TCs; re-point retained TCs to path-presence; add URL/empty-dir/fail-open
  negative TCs. Run the full suite.
- **Actual**: Rewrote the suite (17 subtests): TC-pathlist, TC-schema-invalid,
  TC-failopen-broken, TC-precedence, TC-failopen-absent, TC-tags-casefold,
  TC-tags-empty, TC-tags-union, TC-dedup, TC-confine-file, TC-confine-dir (new),
  TC-dir-empty-vs-missing (new), TC-url-degrades (new), TC-user-trusted,
  TC-argvalidation, TC-branch-signal, TC-classifier. All path assertions check
  `### DOCS` lines; a `no_removed_surface` helper asserts absence of
  SOURCE/URLS/sentinel/TRUNCATED. Dropped the URL-leg, URL-gate, byte-cap,
  member-cap, mid-walk-member, and sentinel-fence TCs. `prove t/` green:
  870 tests / 72 files.
- **Deviations**: **TC-emptydir reinterpreted.** The e-testing-plan anticipated
  an empty directory degrading to a `### SKIPPED` note. The finalised design
  emits a directory pointer *as-is* (the reviewer's Glob enumerates it) and does
  no directory inspection, so an existing-but-empty dir is a valid `dir:` pointer,
  not a skip. Only a **missing** pointer is skipped. The TC was renamed
  `TC-dir-empty-vs-missing` and asserts both behaviours. This keeps the core
  "no dir walk" decision intact rather than reintroducing a readdir.

### Step 4: Hashes + changelog
- **Planned**: Refresh `script-hashes.json` for the 3 changed tracked files;
  add the CHANGELOG breaking-change entry; `cwf-manage validate`.
- **Actual**: Refreshed sha256 for `best-practice-resolve`,
  `cwf-best-practice-reviewer-changeset`, `cwf-plan-reviewer-best-practice` in
  the same commit; bumped `last_updated`; restored agent perms to recorded 0444.
  Added the Task 207 CHANGELOG entry (breaking simplification + migration note:
  URL entries and removed keys silently no-op). `cwf-manage validate: OK`.
- **Deviations**: None. The SKILLs and `best-practice-review.md` are not
  hash-tracked, so no entries for them.

### Step 5: Output-level smoke test
- **Planned**: Run the resolver against a synthetic config (file + dir pointer);
  grep the `.out` for the path list and for absence of the removed surface.
- **Actual**: Ran against a temporary `.cwf/best-practices.json` with a file
  (`CHANGELOG.md`), a dir (`docs/conventions/`), a stale URL, and a missing
  file. The `.out` listed `- file: …/CHANGELOG.md` and `- dir: …/docs/conventions`
  under `### DOCS`, with the URL and the missing file under `### SKIPPED`
  ("missing or unreadable"). Absence grep for `sentinel|### URLS|### SOURCE|
  [TRUNCATED]` was clean. Temporary config and `.out` removed. Repo-wide sweep
  for `allow-url-fetch|url-allow-hosts|make_sentinel|### URLS|WebFetch` clean.
- **Deviations**: None.

## Blockers Encountered
None.

## Security Review

**State**: no findings

The deterministic changeset helper reported `cap exceeded: 552 production lines > 500`
(exit 2) but wrote the full 2204-line changeset. Per the "surface, don't smooth"
precedent (Task 205), the reviewer was run deliberately on the full changeset
rather than recording a bare `error` and skipping review of a security-sensitive
helper. Cap surfaced here, not hidden.

Verbatim reviewer output:

> Security review of the implementation-exec changeset (Task 207). Reviewed the
> resolver Perl, the two agent definitions, the skill docs, the SKILL wording,
> the rewritten test file, the hash refresh, and the CHANGELOG against FR4(a–e).
> (a) No shell invocations introduced/modified; arg allowlist guards retained;
> removed `--max-*` guards went with their options (unknown args now exit 1).
> (b) Config via eval-wrapped `JSON::PP`, paths via `realpath`+stat; no git
> porcelain newline-splitting; `Encode` dropped with `inline_file` — no content
> is decoded because none is read (net surface reduction). (c) Net *improvement*:
> the resolver emits only paths, not inlined/fetched bodies, so no sentinel/fence
> defence is needed; `WebFetch` removed from both agents eliminates the SSRF leg;
> the agent-side fail-closed rule (unreadable doc ⇒ error) is correctly added.
> (d) `$ENV{HOME}` used only to build path strings for stat, never fed to a
> shell; user-config non-confinement is the documented, tested posture. (e) The
> `confined()` gate is verified to cover directories as well as files (closing
> the gap left by deleting the per-member walk), tested by TC-confine-file and
> the new TC-confine-dir. The sole residual — a symlink inside a confined dir
> escaping the root — is correctly documented in `best-practice-review.md`
> § Limitations in "safe here because X; audit future uses" framing; accepted
> for an advisory, read-only, non-secret-bearing feature. Same-commit hash
> refresh discipline noted (validate's job to verify values).
>
> ```cwf-review
> state: no findings
> ```

## Best-Practice Review

**State**: no findings

`best-practice-resolve --task-num=207 --phase=implementation-exec` reported 0
matched entries (this repo carries no `.cwf/best-practices.json`). No
best-practice agent was launched — `no findings: no applicable best practices`.
This is the expected 0-match end-to-end branch noted in the Task 205 carry-over.

## Revision (post-exec review feedback) — paths handed over verbatim

On reviewing the exec, the maintainer judged the path-list design (above) still
over-engineered and directed a further cut: **match tags, hand the reviewer the
`documentation` path verbatim, and let the agent do the rest.** This supersedes
Steps 1–3 above.

- **Resolver**: now does only config read/merge + tag union + match, then writes
  one `- <tags>: <path>` line per matched entry, the path **verbatim** from the
  config. Deleted on top of the earlier cut: per-path existence check, realpath
  confinement (`confined`, `resolve_path`, the `Cwd`/`realpath` import), the
  `### DOCS`/`### SKIPPED` sections, `%SEEN_PATH` de-dup, and the file-vs-dir
  distinction. ~290 lines, down from 612 (Task 205) → 460 (path-list) → here.
- **Agents**: procedures now say "read the `- <tags>: <path>` lines and Read each
  source directly (file → Read, dir → Glob+Read)"; the changeset agent keeps the
  fail-closed `error`-on-unreadable rule. No `### DOCS`/`### SKIPPED` wording.
- **Doc**: `best-practice-review.md` § "Doc-list discipline" rewritten to the
  verbatim-line format; § Limitations now states paths are **not confined** (a
  deliberate simplification for a read-only advisory feature pointing at the
  user's own curated docs, commonly under `~/`).
- **Tests**: rewritten to 13 subtests asserting verbatim emission
  (`TC-verbatim`, `TC-no-checks` — nonexistent/outside-repo paths emitted as
  written, proving no existence check and no confinement), plus the retained
  tag-match / precedence / fail-open / arg-guard / branch-signal / classifier
  cases. `prove t/best-practice-resolve.t` 13/13; `prove t/` 866/72 green.
- **Hashes** re-refreshed for the 3 tracked files; `cwf-manage validate: OK`.
- **Smoke**: a config with a project file + an absolute `~/analysis`-style dir
  produced exactly `- smoke: CHANGELOG.md` / `- smoke, go: /home/.../golang-best-practice`.

### Security Review (revised changeset)

**State**: findings (advisory — deliberate confinement removal, no blocking defect)

Re-run on the full changeset (cap `650 production lines > 500` surfaced, not
skipped). The reviewer confirmed a **net security reduction** (SSRF removed,
content-inlining removed, WebFetch removed) and accepted the deliberate dropping
of project-path confinement **for this read-only advisory feature** — recording
it as a category-(e) pattern-risk with audit guidance rather than a blocking
defect:

> Safe here because the reviewer agents are granted `Read, Grep, Glob, LSP` only
> — no Edit/Write/Bash/WebFetch — so an emitted path can only be **read**;
> findings are advisory and never gate the workflow; the user owns both the
> config and the paths. **Load-bearing invariant for future audit**: (1) the
> reviewer agents must never gain a write/exec/network capability — if they do,
> an unconfined project `best-practices.json` (which can arrive via a PR) becomes
> an arbitrary-read / exfiltration primitive, and the read-only tool grant is now
> the *only* remaining defence; (2) the project-vs-user trust distinction has
> collapsed. Restore confinement before any future change grants a non-read tool,
> feeds this `.out` to a different consumer, or makes the feature gate the
> workflow. Documented in `best-practice-review.md` § Limitations.
>
> ```cwf-review
> state: findings
> ```

This finding is **surfaced for the maintainer's decision**, per the advisory
contract — it does not block. The maintainer explicitly accepted confinement
removal when directing the simplification.

### Best-Practice Review (revised changeset)

**State**: no findings

`best-practice-resolve --task-num=207 --phase=implementation-exec` reported 0
matches (no `.cwf/best-practices.json` in this repo) — `no findings: no
applicable best practices`.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] No applicable b-requirements/c-design (chore)
- [x] No planned work deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
- The directory pointer is now emitted verbatim; "empty directory" is no longer
  a resolver concern (it became a reviewer/Glob concern). Removing the walk also
  removed the only place that could observe emptiness — a clean simplification.
- Agent definition edits are session-cached, so the reviewer behaviour change
  (no WebFetch, read-docs-directly) cannot be live-verified this session; note
  fresh-session verification in the retrospective.
