# re-align Perl-script conventions to Task-27 form - Design
**Task**: 139 (bugfix)

## Task Reference
- **Task ID**: internal-139
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/139-re-align-perl-script-conventions-to-task-27-form
- **Template Version**: 2.1

## Goal
Specify the doc structure, validator rewrite, shebang-revert procedure, and hash-regeneration step that together return CWF Perl helpers to the original Task-27 convention.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### Decision 1 — Convention docs split into two files; old file deleted
- **Decision**: Replace `docs/conventions/perl-git-paths.md` with two new files:
  - `docs/conventions/perl.md` — universal rules for every Perl file under `.cwf/`: `#!/usr/bin/env perl`, `use utf8;`, `PERL5OPT=-CDSLA` recommendation. Leads with `-CDSLA` and explains why the `A` flag matters (cite Task 137: `@ARGV` byte-decoding cannot be set via shebang because it must take effect before perl reads `@ARGV`).
  - `docs/conventions/git-path-output.md` — niche rules for scripts that capture path-emitting git output: `-z` flag, `split /\0/`, NUL-handling. Opens with a one-line prerequisite reference to `perl.md`.
- **Rationale**: The filename `perl-git-paths.md` advertises only the niche concern, so a reader looking for "how do we write Perl in this project?" never opens it. That is the structural gap the backlog entry diagnoses. Splitting on filename surfaces both topics independently.
- **Trade-offs**: Two files instead of one means cross-references must stay in sync. Mitigated by the inbound-reference audit step and by keeping each file short.
- **Reversibility**: High. The split is a `git mv` + content shuffle; reversible by another commit if it proves unergonomic.

### Decision 2 — CLAUDE.md `## Conventions` section anchors both new docs
- **Decision**: Add two bullets to the existing `## Conventions` section in CLAUDE.md, alongside the bullets for `commit-messages.md` and `design-alignment.md`. Order: `perl.md` first (universal), `git-path-output.md` second (niche). New-doc structure follows the existing convention-doc shape (`## Convention` / `## Why` / `## Enforcement`) to match `commit-messages.md` and `design-alignment.md`. Exact bullet wording deferred to implementation phase — must be static literal text (no template substitution) to avoid prompt-injection surface.
- **Rationale**: The structural failure that allowed Tasks 113/115/124 to drift the convention silently was that no agent reading CLAUDE.md from the top would discover the prior decision. Anchoring closes that gap at the project entry point.
- **Trade-offs**: CLAUDE.md grows by two lines. Negligible.
- **Other entry points audited**: `README.md` (audience: external; convention details belong in the linked doc, not the entry). `INSTALL.md` (audience: installers; PERL5OPT recommendation already lives there — see Decision 6 for the required update from `-CDSL` to `-CDSLA`). `.claude/rules/cwf-workflow-files.md` (scope: wf files only; not the right place). Conclusion: CLAUDE.md anchors the docs; INSTALL.md is updated as part of the inbound-reference audit.

### Decision 3 — Validator tightened: reject hardcoded `-C` shebangs
- **Decision**: Amend `CWF::Validate::PerlConventions` — not a wholesale rewrite. The existing script-detection regex at `PerlConventions.pm:80` already accepts `env perl`; the change is a single new rule:
  - **New**: reject any shebang matching `#!/usr/bin/perl\b\s*-C` (hardcoded `-C` flags on the kernel shebang line). Required form: `#!/usr/bin/env perl`.
  - **Unchanged**: universal `use utf8;` requirement.
  - **Unchanged**: `-z` requirement on path-emitting git captures — explicitly preserves FR4(b) coverage (`-z` enforcement on captured `git status|diff|ls-files|diff-tree|diff-index` output) per the CWF threat model in `.cwf/docs/skills/security-review.md`.
  - **Error messages** cite `docs/conventions/perl.md` for shebang/utf8 and `docs/conventions/git-path-output.md` for `-z`. These citation strings depend on the doc-split (Decision 1) landing first; that's why Decision 1 is the first milestone.
- **Rationale**: The kernel shebang-argv parsing variance plus the "Too late for `-CDSLA`" failure mode (Task 137) make hardcoded `-C` flags a structural liability. `env perl` + `PERL5OPT` is the original Task-27 form and decouples the I/O encoding decision from per-script edits. Framing the change as a *tightening* (one added rule) rather than an inversion keeps the diff small and the surface visible.
- **Trade-offs**: Adopters whose `PERL5OPT` is missing the `A` flag will re-introduce the Task 137 mojibake on `@ARGV` decode. Mitigated by lead-with-`-CDSLA` in `perl.md` and by surfacing the recommendation in `cwf-manage update` output if the change is small (defer to implementation phase — out of scope if it ends up being non-trivial).
- **Grandfather list**: Keep `@GRANDFATHERED`. Re-audit `stop-stale-status-detector` under the new rule.
  - **Decision criterion**: After amending the validator, run it against the unchanged tree. If the script now passes the shebang rule (it should — its shebang is already `#!/usr/bin/env perl`), remove it from the grandfather list **only if** it also satisfies `-z` (unlikely; the script uses `git diff HEAD --name-only` without `-z`). Most likely outcome: keep it grandfathered for the `-z` exemption only; document this in `f-implementation-exec.md`.

### Decision 4 — Shebang reverts are mechanical, one commit
- **Decision**: Edit line 1 of each of the 11 files identified in `a-task-plan.md` from `#!/usr/bin/perl -CDSLA` to `#!/usr/bin/env perl`. No other changes in this commit. Single commit titled "Revert hardcoded shebangs to env-perl form".
- **Rationale**: Keep the diff narrow so review can verify that only line 1 changed. Wider diffs would obscure the intent.
- **Trade-offs**: None — purely mechanical.
- **Files**: `cwf-manage`, `backlog-manager`, `cwf-apply-artefacts`, `security-review-changeset`, `context-inheritance-v2.0`, `context-inheritance-v2.1`, `template-copier-v2.0`, `template-copier-v2.1`, `status-aggregator-v2.0`, `status-aggregator-v2.1`, `stop-uncommitted-changes-warning`.

### Decision 5 — Hash regeneration follows the Task-137 procedure exactly
- **Decision**: After the shebang reverts and validator amendment are in place, **`cwf-manage validate` must run and report only the expected SHA mismatches** (no other violations) before any hash splicing starts. Then regenerate hashes using `sha256sum` per modified file and hand-splice into `.cwf/security/script-hashes.json` via Edit. Bump `last_updated`. One commit scoped to `.cwf/security/script-hashes.json`.
- **Blocking gate**: The validate run between shebang revert and hash regen is the gate that catches a missed file. If validate reports a missing-shebang violation for any file not in the 11-script list, stop and investigate before splicing.
- **Pre-splice review**: Before writing the new hashes, list the 12 expected entries (11 scripts + `PerlConventions.pm` module) and compute `sha256sum` for each. Compare against the current `script-hashes.json` to confirm the set of changing entries matches exactly. No surprise entries; no missing entries.
- **Rationale**: This is the procedure Task 137 used (`f-implementation-exec.md:43-44`). `sha256sum` preserves verifier/producer diversity ([[feedback_complexity_over_continuity]]). Manual splice keeps the change reviewable and prevents the "smoothing" anti-pattern that an automated `recompute-hashes` script would introduce ([[feedback_surface_security_dont_smooth]]). The validate-first gate makes a missed shebang revert impossible to silently ship.
- **Trade-offs**: Manual splice is tedious for 12 entries. Tedium is the cost of keeping the trust boundary visible.
- **Out of scope**: Building any new hash-regeneration tooling. If we find ourselves tempted, that is a separate backlog item.

### Decision 6 — Inbound-reference audit covers two patterns across all live surfaces
- **Decision**: After the doc split, grep the repo for two patterns and fix every live hit:
  1. `perl-git-paths` (the deleted filename).
  2. `-CDSL[^A]` and bare `-CDSL` followed by end-of-string / quote (catches stale `PERL5OPT=-CDSL` recommendations that need `-CDSLA`).
- **Live vs frozen scope**:
  - **Frozen** (no edits): `implementation-guide/` (historical task records); `### Retired Backlog Items` sections in `BACKLOG.md` / `CHANGELOG.md`.
  - **Live** (must update): all other paths. Explicit surfaces to verify:
    - `INSTALL.md` — currently recommends `PERL5OPT=-CDSL`; update to `-CDSLA` with one-line rationale ("the `A` flag decodes `@ARGV` as UTF-8, required to avoid Task-137 mojibake"). This surface is the highest-leverage fix for the stale-environment risk.
    - `.cwf/docs/skills/security-review.md` — referenced from skill prompts.
    - `docs/conventions/design-alignment.md` — convention-doc index.
    - `.cwf/templates/` — template files may reference the deleted doc.
    - `.cwf/docs/` (recursive) — any other doc that cross-references.
    - Active entries in `BACKLOG.md`.
    - The validator module's pod/comments.
- **Final repo-wide check**: After all edits, run `git grep -n 'perl-git-paths'` and `git grep -n -- '-CDSL\b'` from the repo root. Outside `implementation-guide/` and retired-items sections, both should report zero hits.
- **Rationale**: Live references must point at the new docs or the new docs are discoverable in name only. The two-pattern audit catches both the structural drift (doc filename) and the symptom drift (stale flag). History stays frozen.
- **Trade-offs**: Two-tier policy (live vs frozen) requires judgement. The line is unambiguous: `implementation-guide/` and "Retired Backlog Items" sections are history; everything else is live.

## System Design

### Component Overview
- **`docs/conventions/perl.md`** (new): Universal Perl rules — single source of truth for shebang + `PERL5OPT` + `use utf8;`.
- **`docs/conventions/git-path-output.md`** (new): Git-specific path-handling rules — `-z`, `split /\0/`, NUL-handling.
- **`docs/conventions/perl-git-paths.md`** (deleted).
- **`CLAUDE.md`** (edited): Two new bullets under `## Conventions`.
- **`CWF::Validate::PerlConventions`** (amended): One new shebang-rejection rule; error messages cite new doc paths.
- **`t/validate-perl-conventions.t`** (edited): Existing fixtures TC-U4 / U4b / U4c / U4d currently treat `#!/usr/bin/perl -CDSLA` as the *valid* form — flip these to assert it is *invalid* (citation: `docs/conventions/perl.md`). Add a positive-case fixture: `#!/usr/bin/env perl` + `-z` git capture passes all checks. Add a negative-case fixture: hardcoded `-C*` shebang is rejected regardless of trailing flags.
- **`t/common.t`** (edited if any shebang assertions present): align with the new convention.
- **Shebang revert across 11 scripts**: Line-1 edit per file.
- **`.cwf/security/script-hashes.json`** (regenerated): 12 SHA256 updates + `last_updated` bump.
- **Active inbound references** (edited): `security-review.md`, `design-alignment.md`, active `BACKLOG.md` entries, `INSTALL.md` if applicable.

### Data Flow
1. Maintainer or agent reads CLAUDE.md → finds `## Conventions` bullets → opens `perl.md`.
2. `perl.md` documents shebang + PERL5OPT; if the script captures git path output, the reader follows the cross-reference to `git-path-output.md`.
3. Validator (`cwf-manage validate`) walks `.cwf/scripts/` + `.cwf/lib/CWF/`; rejects any file violating the rules in those docs.
4. CI / pre-commit / retrospective phase all run `cwf-manage validate`; a drifted shebang surfaces immediately.

## Interface Design

### `CWF::Validate::PerlConventions::validate($git_root)` (unchanged signature)
Return: list of violation hashes, same shape as today (`{ rel, field, actual, expected, message }`). Field values:
- `field = 'shebang'`: actual is the offending first line; expected is `#!/usr/bin/env perl`.
- `field = 'use_utf8'`: unchanged.
- `field = 'git_z'`: unchanged; error message updated to cite `docs/conventions/git-path-output.md`.

### Document cross-reference contract
- `perl.md` mentions the existence of `git-path-output.md` in a "See also" section at the end.
- `git-path-output.md` opens with: "Prerequisite reading: `perl.md` (universal Perl rules)."
- Neither file duplicates the other's rules; cross-link, do not copy.

## Constraints
- POSIX-only target; no GNU-specific tooling in the regeneration procedure.
- Perl core modules only ([[feedback_perl_core_only]]).
- Historical task records under `implementation-guide/` are immutable.
- Squashed-main / archaeological-branch methodology — one checkpoint commit per phase, milestone-scoped commits during implementation-exec.

## Decomposition Check
- [ ] **Time**: ~1 day total.
- [ ] **People**: 1.
- [ ] **Complexity**: Two concerns, tightly coupled (validator cites new doc paths). Decomposition would force an awkward intermediate state.
- [ ] **Risk**: Hash-regen and validator-inversion risks are each contained to one milestone within this task.
- [ ] **Independence**: Milestones are sequenced.

**Decision**: No decomposition. Four sequenced milestones inside this single task.

## Validation
- [x] Design review completed (4 plan-review subagents — Improvements, Misalignment, Robustness, Security).
- [x] Architecture choices grounded in current code: validator path verified, hash file location verified, inbound reference surfaces grepped, INSTALL.md PERL5OPT recommendation confirmed at `-CDSL` (needs update).
- [x] Cross-references between new docs specified explicitly.
- [x] Validate-first gate added between shebang revert and hash regen (Robustness review).
- [x] Final repo-wide grep added as last-mile check (Robustness review).
- [x] FR4(b) coverage preservation made explicit in Decision 3 (Security review).

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
