# Consolidate Cross-Doc Reference Patterns - Retrospective
**Task**: 151 (discovery)

## Task Reference
- **Task ID**: internal-151
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/151-consolidate-cross-doc-reference-patterns
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-18

## Executive Summary
- **Duration**: ~70 min active wall-clock (a→g, excluding overnight gap) vs. 1-2 days estimated. Variance −95%.
- **Scope**: As planned — discovery + standard-setting only, no in-task migration. The 8K-row migration is the deferred BACKLOG entry.
- **Outcome**: Standard committed at `docs/conventions/cross-doc-references.md`; pre-migration baseline (~7,964 divergent rows) is mechanically reproducible from the audit appendix. The improvement in the docs themselves is *latent* until migration runs; what shipped is the rule and the data.

## Variance Analysis

### Time and Effort
- **Estimated**: 1-2 days (a-task-plan §Original Estimate).
- **Actual** (per checkpoint commit timestamps):
  - Planning (a): ~5 min
  - Requirements (b): ~7 min
  - Design (c): ~10 min
  - Implementation plan (d): ~9 min
  - Testing plan (e): ~1 min (no plan-review subagents required)
  - Implementation exec (f): ~25 min (audit-run + style guide + CLAUDE.md + dogfooding + BACKLOG)
  - Testing exec (g): ~17 min (verify-cites + AC1-AC8 + NFR4/NFR5 evidence)
- **Variance**: Massively under. The estimate priced a "research + write document" task at human-pace; the actual work was dominated by getting one 250-line Perl audit script to classify 25K references correctly. The c-design effort spent on the two-axis schema (delimiter × target-shape) and the inverted `kind` fence rule paid for itself in f — the script was largely a transcription of the design contract.

### Scope Changes
- **Additions during exec**:
  - **Noise filter for plain-prose path candidates** (`N/A`, `pass/fail`, `I/O`, etc.). Not in d-plan; surfaced when the first audit produced ~3,000 noise rows. Added as a 4-line filter restricted to `plain-prose × path` candidates. Documented in f-implementation-exec.md §Deviations and in the audit-script comments.
  - **Scanned-files manifest section** in audit output. Not in c-design; surfaced when the first audit's bidirectional `comm` against `git ls-files` revealed 2 files with zero detected references and therefore zero rows in the table — AC1 reads "scanned-files manifest", so emitting one row per scanned file ahead of the reference table was necessary.
  - **`audit-appendix.md` sibling file** to hold the 21,161-row inventory. Not in d-plan (Step 4 said paste inline). The 3.9MB inline appendix was hostile to review and to main-branch compactness; split into a sibling file in the same task directory, preserving the b-requirements NFR3 intent ("audit lives with the task") and the prompt-injection fence wrap.
- **Removals**: None.
- **Impact**: All three additions were surfaced and documented as deviations rather than absorbed silently. No timeline impact (each was <5 min of additional work).

### Quality Metrics
- **Test coverage**: 13/13 TCs PASS. 8 AC tests + 5 NFR hardening tests. All evidence pasted in `g-testing-exec.md` with reproducible shell commands.
- **Defect rate**:
  - 1 caught at first f-exec run: `$' ` shell-magic-variable interpolation inside the URL regex char class caused 46 warnings + 1 crash. Fixed by switching to a negative char class. Recorded as a Perl gotcha worth a memory entry.
  - 1 caught at first f-exec run: top-level `local $/ = undef` leaked into per-file reads, slurping each file as a single line and causing every row to report `source_line=1`. Fixed by scoping the `local` to a bare block.
  - 1 caught at f-checkpoint: `cwf-checkpoint-commit` rejected the dir with 2 `f-*` files. Renamed sibling appendix from `f-implementation-exec-audit.md` to `audit-appendix.md`. Helper invariant ("exactly one wf-step file per phase letter") is real — useful constraint.
  - 1 caught at f-checkpoint validate: `cwf-manage validate` flagged `audit-appendix.md` as missing `## Status`. Added a Status section in a follow-up commit (`f014b1d`). Validate now warns only on the pre-existing `cwf-plan-reviewer-misalignment.md` permission drift, already in BACKLOG.
- **Performance**: `audit.pl` completes in <2s on 1,172 files. No performance concerns.

## What Went Well
- **Two-axis schema (c-design D1) was the right call.** Splitting `delimiter` × `target-shape` made the rules expressible. A single flat enum (the b-requirements first draft) couldn't have answered "which delimiter for which target-shape" without combinatorial enum blowup.
- **Plan-review map/reduce across b-c-d phases caught structural defects pre-exec.** The phantom `intra-task-historic` 5th locality (caught at c review), the `wc -l` shell-out (caught at d review), the row-count sanity bounds that would false-trigger (caught at d review), and the audience-axis dropper (caught at b review) all came from review, not from agent self-correction.
- **The 4-axis security-review wasn't required for e-testing-plan or for f/g checkpoint commits (changesets out of CWF-internal pathspec).** Helper's pathspec scoping correctly recognised that docs/conventions/, CLAUDE.md, BACKLOG.md, and implementation-guide/ are not security-review targets. No false alarms, no theatre.
- **Determinism (NFR5) confirmed mechanically.** Two consecutive `audit.pl` runs at the same baseline produced byte-identical output bodies. `LC_ALL=C` + list-form git + sorted output works.
- **Dogfooding against `commit-messages.md` (AC7) produced a clean signal.** 0 mismatches after applying the template-URL carve-out — the one apparent mismatch (line 66 inline-backtick URL) is genuinely a template placeholder, not a destination URL. The carve-out is principled, not retrofit.

## What Could Be Improved
- **The audit-output size (~3.9MB inline) was not anticipated by the plan.** b-requirements NFR3 said "lives in this task's wf step files — specifically as appendix sections in `f-implementation-exec.md` and `g-testing-exec.md`." 21,161 rows × ~120 bytes/row arrived at 4MB, which is fine as a file but hostile as a wf-step-file section. The deviation handled it but the cost would have been avoided by an explicit "if audit > 1MB, file as sibling" plan-time guard.
- **The "inline-backtick everything intra-repo" rule is opinionated.** The audit data is genuinely split (8,400 backtick / 5,616 plain-prose for intra-repo path). Picking one binds the migration to 5,616 prose-style rows that read naturally in narrative. Worth knowing the rule is a judgment call, not a data-forced conclusion. A reasonable alternative would have been "inline-backtick is preferred but plain-prose accepted in clearly-narrative passages" with no migration entry filed — which would have made this a 0-divergence task. The chosen direction prioritises scannability over narrative comfort; the migration cost makes that priority explicit.
- **AC7 dogfooding sample size is thin.** `commit-messages.md` happens to be URL-heavy (7 of 7 references are external URLs), so the dogfood tested the external-URL rule but not the dominant intra-repo path rule. A second dogfood target like `docs/conventions/perl.md` or `docs/conventions/design-alignment.md` would have exercised the path rules — worth adding to a future audit-style task's e-testing-plan.
- **`audit-appendix.md` triggered a workflow-validate warning** because every `*.md` in `implementation-guide/<task>/` is treated as a wf-step file requiring `## Status`. The helper's invariant is sound for canonical wf-step files but doesn't accommodate task-scoped appendices. Recorded as a minor friction; the fix (`Status: Finished` stub) was 5 lines.

## Key Learnings

### Technical Insights
- **`$'` is Perl's postmatch magic variable AND a valid inside-character-class interpolation surface.** A regex `/[\w\-./%?&=#:~+,;@!$'()*]+/` will silently interpolate `$'` (postmatch, often empty, often dependent on the previous regex's match), corrupting the character class. Use negative classes (`[^\s)<>"\[\]]+`) for URL matching when you don't have a tight allow-list. Worth saving as a feedback memory.
- **`local $/ = undef` at top-level scope leaks.** Inside subroutines that call `open` + `<$fh>` later, the slurp persists and breaks line-by-line reads. Always wrap `local $/` in a bare block `{ ... }`. The fix was 3 lines; the symptom (every row reporting source_line=1) was clearly diagnostic.
- **CommonMark fence detection needs run-length matching.** A `\`\`\`` opener requires a `\`\`\`` closer; a `\`\`\`\`` (4-backtick) opener requires `\`\`\`\`+` closer, so inner 3-backtick fences are content. Indented (4-space) fenced blocks are a separate CommonMark form that this audit deliberately doesn't recognise — the corpus has effectively zero of them.
- **"Outermost delimiter wins" (c-design D1) produces an idiom-vs-decoration ambiguity.** `**See \`docs/conventions/perl.md\`**` resolves to delimiter=bold under the rule, even though semantically the inline-backtick is the "real" delimiter for the path reference and the bold wraps the whole sentence. The data shows 1,641 bold × path rows that are predominantly this idiom. The style guide carves out the head-of-skill-file `**Path**: \`path\`` form explicitly rather than legislating against it.

### Process Learnings
- **Estimation drift on audit-style tasks.** "1-2 days" was massively over-priced. The actual work was 1-2 hours once the design contract was tight. Pattern: when the c-design phase produces a mechanical contract for f-exec (rather than open-ended design choices), exec time collapses by an order of magnitude.
- **Plan-review subagents earn their keep on audits as much as on code.** Without the c-review, the phantom 5th locality and the over-broad `form` enum would have shipped. Without the d-review, the `wc -l` shell-out and the row-count sanity bounds that would false-trigger would have shipped. The plan-review pattern is not specific to code-heavy tasks.
- **"Discovery task that concludes 'no change needed' is valid" (a-plan §Mitigation) was tested but didn't fire.** The audit revealed ~38% of references diverge from any single chosen standard — too much to call "already consistent". But the framing was useful as a pre-commitment: had the data shown 95%+ convergence on one form, the low-divergence outcome branch (b-requirements FR7, AC8) was ready.
- **`audit-appendix.md` workflow integration friction.** The wf-step-helper pattern assumes one `<letter>-<name>.md` per directory. Adding `audit-appendix.md` worked but tripped both the checkpoint-commit helper (false alarm: 2 `f-*` files when the new appendix was first named `f-implementation-exec-audit.md`) and `cwf-manage validate` (false alarm: missing `## Status`). Worth flagging that "task-scoped sibling artefacts" is a real shape and the helpers should accommodate it cleanly. See Future Work.

### Risk Mitigation Strategies
- **Mandatory `mkdir -m 0700` first** before any writes to `/tmp/-home-matt-repo-coding-with-files-task-151/`. Per `.cwf/docs/conventions/tmp-paths.md`. Restated in d-plan, restated in operator-commands log of f-exec. Belt + braces.
- **Prompt-injection fence wrap on every audit-scraped paste.** Audit appendix wrapped in ` ```markdown `; dogfooding excerpt wrapped in ` ```markdown `; BACKLOG migration-body excerpts wrapped in ` ```markdown `. Targets scraped from skill bodies and agent definitions never load as instruction when those files re-enter LLM context downstream.
- **Carve-out ordering documented in audit.pl comments.** The `kind=historic` carve-out for BACKLOG/CHANGELOG runs AFTER the fence-based kind rule and OVERRIDES it. Without that ordering, fence-tagged historic content would mis-classify. The script comment makes the order explicit so future refactors don't re-order silently.

## Recommendations

### Process Improvements
- **Plan-time size estimation for audit outputs.** Any task that produces a row-per-thing audit should include an order-of-magnitude estimate in c-design or d-plan ("expect ~N rows × ~M bytes/row"). If the estimate exceeds 1MB, plan for a sibling file from the start rather than as a deviation.
- **AC7-style dogfooding should target ≥2 distinct files.** One file is a thin sample; covering at least two structurally-different files (e.g. one URL-heavy, one path-heavy) gives a real signal.

### Tool and Technique Recommendations
- **Pure-Perl line counting (`tr/\n//` + carry-over for trailing-newline-absent files) is the right call for verify-cites-style scripts.** No `wc -l` shell-out, no shell-interpolation surface, no platform variance. Worth keeping as a pattern.
- **Negative URL char classes (`[^\s)<>"\[\]\`]+`) avoid the `$'` interpolation trap.** Use them when you don't have a tight allow-list.

### Future Work
- **Migrate cross-doc references to canonical style** — already filed as Low-priority BACKLOG entry. ~7,964 rows; staged migration recommended (convention docs first, templates next, individual wf files last).
- **Helper accommodation for task-scoped sibling artefacts.** `cwf-checkpoint-commit` and `cwf-manage validate` both treat every `*.md` in the task dir as a phase-letter wf-step file. Audit-style tasks legitimately produce sibling artefacts that aren't phase files. Worth a small BACKLOG entry to define the convention (e.g. files matching `[!a-j]*.md` exempted from validate's Status check; checkpoint-commit's `f-*` glob narrowed to `f-[a-z]*-exec.md` or similar).

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-18
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Style guide: `docs/conventions/cross-doc-references.md` (60 lines).
- CLAUDE.md insertion: `CLAUDE.md:73-77`.
- Audit appendix (raw inventory, 22,349 lines): `implementation-guide/151-discovery-consolidate-cross-doc-reference-patterns/audit-appendix.md`.
- Audit script source: embedded in `f-implementation-exec.md` (## Audit Script Source).
- Verifier script source: embedded in `g-testing-exec.md` (## Verifier Script Source).
- Migration BACKLOG entry: `BACKLOG.md` under "Migrate cross-doc references to canonical style".
- Checkpoint commits on `discovery/151-consolidate-cross-doc-reference-patterns`: `e6a5319` (a), `43426f3` (b), `90e611e` (c), `e2f98bc` (d), `084774d` (e), `5cc9b72` (f), `f014b1d` (audit-appendix Status fix-up), `68ca89d` (g), plus this retrospective.
