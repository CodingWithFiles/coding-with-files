# Seed exclude-path defaults, raise review cap 1000 - Design
**Task**: 221 (feature)

## Task Reference
- **Task ID**: internal-221
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/221-seed-exclude-path-defaults-raise-review-cap-1000
- **Template Version**: 2.1

## Architecture Overview
No new code paths, modules, or runtime logic. The feature is entirely (a) seeded
config data, (b) a one-constant + one-comment cap bump, and (c) doc/dog-food sync.
All matching reuses Task 218's git `:(glob,exclude)` pathspec engine in
`security-review-changeset` — `max_lines_exclude_paths()` (`:552-578`) already
reads `security.review.max-lines-exclude-paths`, prefixes each entry with
`:(glob,exclude)`, and hands it to `git diff --numstat`. This task only supplies
the default *values* and raises the built-in cap. Design priority order here is
**Reversibility → Simplicity → Consistency**: every change is a data edit or a
single literal, trivially revertible, and mirrors an existing precedent
(`sandbox` + `_sandbox-note` seeding, Task 218 config shape).

## Components (changed files)

### 1. `.cwf/templates/cwf-project.json.template` (seed surface)
Add, after the existing `sandbox` block, a sibling intent note + a `security`
block carrying only `review.max-lines-exclude-paths` (no `max-lines` — see
Decision D2). Mirrors `_sandbox-note`/`sandbox`.

```json
  "_security-review-note": "Paths discounted from the security.review.max-lines production-line cap only — they are still fully reviewed. Defaults cover common test/generated/vendored/doc-only layouts; edit for your project. See .cwf/docs/skills/security-review.md.",
  "security": {
    "review": {
      "max-lines-exclude-paths": [
        "**/*_test.*", "**/*.test.*", "**/*_spec.*", "**/*.spec.*",
        "**/test/**", "**/tests/**", "**/__tests__/**", "**/spec/**",
        "**/vendor/**", "**/node_modules/**", "**/dist/**", "**/build/**",
        "**/target/**", "**/__pycache__/**",
        "**/*.min.*", "**/*.generated.*",
        "docs/**/*.md", "*.md"
      ]
    }
  }
```

### 2. `.cwf/scripts/command-helpers/security-review-changeset` (cap bump — hash-tracked)
The default lives in one executable constant, but `500` appears at **four** sites
(confirmed by grep — the earlier "two sites" claim was wrong):
- `:101` — `my $DEFAULT_MAX_LINES = 500;` → `1000` (the one live-code edit).
- `:32` — `#`-header banner prose `built-in default (500)` → `(1000)`.
- `:100` — the self-note `keeps its own hand-maintained "500" literal` → **reword**
  to drop the hardcoded value (e.g. "…its own hand-maintained numeric literal"),
  removing this drift point permanently rather than re-pinning it (per the
  best-practice reviewer / PBP "rewrite rather than re-comment").
- `:316` — comment `max_lines now always defined (default 500)` → `(default 1000)`.
The interpolating `print_usage` POD needs no edit (reads `$DEFAULT_MAX_LINES`).
Refresh this file's entry in `.cwf/security/script-hashes.json` in the same commit.

### 3. `implementation-guide/cwf-project.json` (dog-food the new default)
Remove the now-redundant `security.review.max-lines: 1000` (`:40`); keep
`max-lines-exclude-paths` (`t/**`, `implementation-guide/**`). After this the repo
has no explicit cap and **inherits** the new built-in 1000 — proving FR6 default
inheritance. (This does not exercise the 1000 *value* at runtime: the repo's own
excludes discount most changeset lines, so counts rarely approach 500, let alone
1000. The cap-value check is the `t/` unit assertion, not the dog-food config.)
`version-tracking` and the rest of the `security` block are untouched.

### 4. Doc sync — two files
- **`CWF-PROJECT-SPEC.md`** (`:76`, `:87-89`): the bullet already lists
  `review.max-lines-exclude-paths`; only the section framing "appear in the
  dog-fooded config" is now incomplete. Clarify that the
  `max-lines-exclude-paths` **default** now also ships seeded in the template for
  new projects, and that the built-in cap default is 1000 (a helper default).
  Per D2 the template does **not** ship `max-lines`, so do not describe `max-lines`
  as seeded. Still a pass-through/unvalidated key — no validator change (D3). If
  the existing text already reads accurately, keep the edit minimal.
- **`.cwf/docs/skills/security-review.md`** (`:47`): the two prose `500` literals
  (`built-in default (500)` and `degrades to 500`) go stale — update both to
  `1000`. This file is **not** hash-tracked (verified), so no `script-hashes.json`
  refresh for it.

### 6. `t/security-review-changeset.t` (re-baseline the 500-anchored tests)
The cap bump breaks existing coverage that hardcodes 500 — this is load-bearing,
not optional:
- `TC-DEFAULTCAP` (`:1024-1039`): a 520-line diff currently asserts `exit 2` and
  `cap exceeded: … > 500` with no `--max-lines`. After the bump 520 < 1000 → the
  helper exits 0 and the subtest fails. Re-baseline it to the new default (assert
  1000 passes / 1001 exits 2, or raise the fixture above 1000).
- Audit the other 500-named subtests for comment/semantic drift: `TC-CAP3`
  (`:757-772`, "defaults to 500") and `TC-CONFIGCAP5/6/7` (`:1695-1755`, "degrade
  to 500"). The file carries 32 `500` mentions total; the e-testing-plan does the
  systematic sweep so none is left stale.

## Data Flow (unchanged)
`cwf-init` copies template → `implementation-guide/cwf-project.json`. At review
time `security-review-changeset` reads `security.review.max-lines-exclude-paths`
via `CWF::Versioning::read_config()`, builds `:(glob,exclude)` pathspecs, and
`git diff --numstat` computes the production count that is compared against the
cap (`--max-lines` > `security.review.max-lines` > `$DEFAULT_MAX_LINES`).

## Key Design Decisions

- **D1 — Generic globs, not CWF-specific.** The template ships to every ecosystem,
  so the seed uses conventional cross-ecosystem test/generated/vendored patterns,
  never `t/**` or `implementation-guide/**` (those stay in this repo's own config).
- **D2 — Seed excludes only, not `max-lines`.** Seeding `max-lines: 1000` in the
  template would duplicate the built-in default. Omitting it means new projects
  inherit the built-in (now 1000) and add an explicit cap only when they diverge —
  the same reasoning that makes us drop this repo's redundant key (FR6).
- **D3 — No validator change.** `security.review` stays a pass-through key
  (`CWF::Validate::Config` ignores it). Seeding a value does not warrant promoting
  it to a validated contract; keeps blast radius minimal.
- **D4 — Doc-markdown scope (resolves FR2).** Use `*.md` (top-level docs like
  README/CHANGELOG) + `docs/**/*.md` (a **top-level** `docs/` tree). Deliberately
  *not* `**/docs/**/*.md` — the leading `**/` would also match `.cwf/docs/**`
  (shipped CWF conventions), needlessly widening the fail-open surface. Top-level
  anchoring keeps the doc exclusion conservative. **Security caveat**: markdown is
  the primary prompt-injection (FR4(c)) carrier, and discounting it from the cap by
  default means a large adversarial-markdown changeset stays under the cap (still
  fully reviewed — the cap gates review invocation, not content filtering). Kept
  per R1's explicit "doc-only markdown" intent, but the trade-off is surfaced in
  the `_security-review-note` and the CHANGELOG/rollout note, not smoothed.
- **D5 — Intent via `_security-review-note`.** Strict JSON has no comments; the
  sibling `_`-note mirrors the established `_sandbox-note` convention.

## FR3 guardrail verification (design-time)
None of the seeded globs match the security-relevant paths `.cwf/scripts/`,
`.cwf/hooks/`, `.cwf/security/`, or `cwf-project.json`: the test/vendored/generated
globs target unrelated directory names, `*.md` matches only top-level markdown, and
`docs/**/*.md` is anchored to a top-level `docs/` tree (not `.cwf/docs`). Confirmed
mechanically in the testing phase (AC3).

## Interfaces / Contracts
- No API or function-signature change. Config key names and precedence are
  Task 218's contract, preserved verbatim.
- Test seam: `t/cwf-project-template.t` gains an assertion that the template now
  carries `security.review.max-lines-exclude-paths` as a non-empty array (guards
  against accidental removal), and `t/` gains coverage that the cap default is 1000
  and that each seeded glob is a valid pathspec (detailed in e-testing-plan).
- **Glob-validity is a hard gate, not a nicety** (robustness reviewer): a single
  malformed seeded glob makes git fatal → `security-review-changeset` exits 1,
  breaking the security review for *every* new project. The validity test must run
  each glob through git's real `:(glob,exclude)` engine (e.g. `git diff --numstat`
  / `ls-files` with the pathspec), **not** a Perl-side regex approximation that
  could pass while git rejects the pattern.
- **AC3 guardrail must be re-runnable, not a one-time assertion** (security
  reviewer): the suffix-anchored globs (`**/*_test.*`, `**/*.spec.*`, `**/*.min.*`,
  `**/*.generated.*`) match by *filename*, so the "no seeded glob touches
  `.cwf/scripts|hooks|security` / `cwf-project.json`" guarantee holds by current
  layout, not by construction (a future `.cwf/scripts/foo_test.pl` would be
  discounted — still reviewed, just not capped). Encode AC3 as a committed test
  that re-checks the guardrail against the live tree, so drift is caught later too.

## Decomposition Check
- [ ] Time / People / Complexity / Risk / Independence — all No. Single-concern,
      four-file data/doc change. No decomposition.

## Rollout disclosure (surface, never smooth)
Raising `$DEFAULT_MAX_LINES` 500→1000 silently loosens the review cap for every
existing install that relies on the built-in default (no explicit
`security.review.max-lines`): on their next CWF update a review that fired at 500
now tolerates 1000. Per this repo's "surface, never smooth" ethos for anything
that relaxes a security guardrail, the CHANGELOG entry (and h-rollout note) must
call this out explicitly, with the one-line mitigation that a project pins its own
`security.review.max-lines` to restore a stricter cap. (The 1000 value is a
deliberate maintainer decision — long-baseline diffs routinely exceed 500.)

## Trade-offs
- **Breadth vs fail-open**: a wider glob set catches more non-production churn but
  exempts more paths from the cap. Mitigated by conservative directory targeting,
  top-level doc anchoring (D4), and the FR3 guardrail. Accepted per NFR4.
- **Generic vs precise**: generic globs match nothing in some layouts (safe by
  omission, NFR5) rather than risk wrong exclusions; correctness over coverage.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
