# record commit sha not tag-object sha - Design
**Task**: 175 (bugfix)

## Task Reference
- **Task ID**: internal-175
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/175-record-commit-sha-not-tag-object-sha
- **Template Version**: 2.1

## Goal
Define the design for resolving the recorded `cwf_sha` to a commit, at both SHA-resolution sites, matching the existing `^{commit}` idiom in the codebase.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### Decision: peel the resolved ref to its commit with `^{commit}`
- **Decision**: At each site, suffix the ref with `^{commit}` so `git rev-parse` returns the commit a ref points to rather than the ref's own object. For annotated tags this peels the tag object to its commit; for every other ref it is a no-op.
- **Rationale**: One-token change at each call site, no new code paths, no new helper. Matches the established codebase idiom — `.cwf/scripts/command-helpers/security-review-changeset:285` and `.cwf/scripts/command-helpers/task-workflow.d/delete:209` already peel with `${sha}^{commit}` (both in a `rev-parse --verify --quiet` validation context; git semantics are identical when used to record).
- **Trade-offs**: Forward-only (existing installs keep their recorded tag-object SHA until next install/update). Acceptable — the field is display-only and a re-install/update rewrites it.
- **Rejected — shared helper**: `CWF::Common::resolve_head_sha` is HEAD-only and Perl; install.bash is Bash. A new shared abstraction for two one-token call sites would be over-engineering (Rule of Three not met). Keep the fix local at each site.

### The two sites
- **`scripts/install.bash:310`** — `resolved_sha="$(git -C "$TMPDIR_CWF/cwf-source" rev-parse "$resolved_ref")"` → `rev-parse "${resolved_ref}^{commit}"`. Bootstrap installer (subtree + copy paths both flow through `main()` → `post_install`). This single site also feeds the install.bash version-write at `:284` (`cwf_sha=$resolved_sha`), so the one edit covers both install.bash consumers.
- **`.cwf/scripts/cwf-manage:225`** (`resolve_sha`) — `'rev-parse', $ref` → `'rev-parse', "$ref^{commit}"`. Update path.

Both must change together so the subtree-install path (install.bash) and the update path (cwf-manage) record identical SHAs for the same tag.

## System Design

### Data flow (unchanged in shape, corrected in value)
1. `resolve_ref` / `resolve_ref`-equiv resolves a user ref (`v1.1.169`, `main`, a SHA, or `latest`) to a concrete ref.
2. **[changed]** `rev-parse "<ref>^{commit}"` → commit SHA (was: ref object SHA).
3. `cwf-manage` only: the commit SHA feeds `git_describe_version` (`cwf-manage:521`) → still resolves to the tag name (`v1.1.169`), so `cwf_version` is unaffected.
4. SHA written to `.cwf/version` as `cwf_sha`; printed by `cwf-manage status` (`cwf-manage:346`).

### Behaviour matrix (the correctness argument)
| Ref form | `rev-parse <ref>` (before) | `rev-parse <ref>^{commit}` (after) |
|----------|----------------------------|-------------------------------------|
| Annotated tag | tag **object** SHA (bug) | tag's **commit** SHA ✓ |
| Lightweight tag | commit SHA | commit SHA (no-op) |
| Branch | commit SHA | commit SHA (no-op) |
| Raw commit SHA | same SHA | same SHA (no-op) |
| `HEAD` | commit SHA | commit SHA (no-op) |

### Interface / contract
No interface change. `.cwf/version` schema, field names, and `cwf-manage status` output format are unchanged — only the *value* of `cwf_sha` for annotated-tag installs is corrected.

## Constraints
- **Hashed script**: `.cwf/scripts/cwf-manage` is integrity-hashed. Per the hash-updates convention, refresh `.cwf/security/script-hashes.json` in the **same commit** as the edit; restore working perms to the recorded 0500 (not 0700).
- **`set -euo pipefail`** in install.bash: a failed `^{commit}` peel aborts the install. Safe — the ref was already validated by `resolve_ref` and must be a commit-ish (it is later checked out / subtree-split, which would fail for non-commits anyway). No new error handling required.
- Bash 4 / core-Perl-only conventions per CLAUDE.md.

## Decomposition Check
- [x] No signals triggered (carried from a-task-plan): single concern, two co-located one-token edits.

## Validation
- [x] Design review completed (Step 8 plan review — see below)
- [x] Integration points verified: `git_describe_version` input, `.cwf/version` consumers, hash refresh
- [x] Idiom consistency verified against `security-review-changeset:285`, `task-workflow.d/delete:209`

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
The `^{commit}` peel decision held unchanged through exec — two one-token edits, no new helper. Behaviour matrix confirmed by tests (annotated tag corrected; other ref forms no-op). See `j-retrospective.md`.

## Lessons Learned
Idiom reuse over new abstraction was the right call (Rule of Three not met). See `j-retrospective.md`.
