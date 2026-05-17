# update cwf skills to use namespaced tmp paths - Testing Plan
**Task**: 145 (chore)

## Task Reference
- **Task ID**: internal-145
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/145-update-cwf-skills-to-use-namespaced-tmp-paths
- **Template Version**: 2.1

## Goal
Validate that the new `docs/conventions/tmp-paths.md` doc, its discovery-surface cross-reference, the security-review.md annotation, and the agent-memory updates are coherent, byte-correct, and that the documented derivation snippet actually produces non-colliding paths across simulated repo roots.

## Test Strategy

### Test Levels
Docs-only task — no `t/` suite additions, no Perl tests. All tests are shell assertions executed inline during g-testing-exec, or quick `grep`/`diff` checks. No new test framework.

### Test Coverage Targets
- **Critical paths**: 100% of explicit success criteria from a-task-plan.md and d-implementation-plan.md must have a matching test case below.
- **Edge cases**: derivation snippet exercised against two distinct repo roots; collision-free verified.
- **Regression**: `cwf-manage validate` post-implementation matches pre-implementation state (i.e. no new violations beyond the pre-existing `cwf-security-reviewer-changeset.md` permissions warning carried in from main).

## Test Cases

### Functional Test Cases

- **TC-1: `tmp-paths.md` exists at the installed-conventions location and has required sections**
  - **Given**: d-implementation-plan Step 1 complete.
  - **When**: `grep -E '^## (Convention|Threat model|Why|Out of scope|See also)' .cwf/docs/conventions/tmp-paths.md`
  - **Then**: All five expected headings present (one match per heading, in order). File lives under `.cwf/` (not `docs/`) so it ships to adopters via subtree install.

- **TC-2: Canonical form documented unambiguously**
  - **Given**: TC-1 passes.
  - **When**: Read `.cwf/docs/conventions/tmp-paths.md` § Convention.
  - **Then**: Exactly one canonical form is stated (`/tmp/<dashified-absolute-repo-path>-task-<num>/`); no "form A vs form B" fallbacks offered; a worked example matching `/tmp/-home-matt-repo-coding-with-files-task-145/` appears verbatim.

- **TC-3: Derivation snippet is copy-pastable**
  - **Given**: TC-2 passes.
  - **When**: Extract the bash derivation snippet from `.cwf/docs/conventions/tmp-paths.md`, write to `/tmp/-home-matt-repo-coding-with-files-task-145/derive.sh`, run with `repo_root=/tmp/repo-a` and `num=145`, then again with `repo_root=/tmp/repo-b` and `num=145`.
  - **Then**: Both invocations produce a valid path; the two paths differ; neither contains shell metacharacters.

- **TC-4: First-use `mkdir -m 0700` guard documented**
  - **Given**: TC-1 passes.
  - **When**: `grep -F 'mkdir -m 0700' .cwf/docs/conventions/tmp-paths.md`
  - **Then**: At least one match in the § Threat model section.

- **TC-5: `CLAUDE.md § Conventions` lists the new convention**
  - **Given**: d-implementation-plan Step 3 complete.
  - **When**: `awk '/^## Conventions/,/^## /' CLAUDE.md | grep -F '**Tmp Paths**'`
  - **Then**: Exactly one match. Bullet text references `.cwf/docs/conventions/tmp-paths.md`. Bullet form matches the existing `**Commit Messages**:` style (verified by side-by-side read).

- **TC-5b: `design-alignment.md` scope paragraph updated**
  - **Given**: d-implementation-plan Step 2 complete.
  - **When**: Read `docs/conventions/design-alignment.md` lines 5-12 with the Read tool.
  - **Then**: The scope paragraph at lines 7-8 (or wherever it now sits) acknowledges that conventions which need to ship to adopters live under `.cwf/docs/conventions/`. Surrounding wording preserved; change is one-line, additive.

- **TC-6: `security-review.md:98` annotation present**
  - **Given**: d-implementation-plan Step 4 complete.
  - **When (automated)**: Two grep assertions:
    1. `grep -F 'illustrative — not a canonical scratch path' .cwf/docs/skills/security-review.md` — confirms annotation exists.
    2. `grep -F '/tmp/cwf-update' .cwf/docs/skills/security-review.md` — confirms the original anti-pattern code is still present (annotation added, not replaced).
  - **When (proximity check)**: Use the Read tool with `offset` around the line returned by `grep -nF '/tmp/cwf-update' .cwf/docs/skills/security-review.md` and `limit ≈ 8`; visually confirm the annotation comment is on or adjacent to the `/tmp/cwf-update` line.
  - **Then**: Both grep assertions return one match each; the Read-tool window shows the annotation co-located with the anti-pattern line.

- **TC-7: Glossary entry decision recorded**
  - **Given**: d-implementation-plan Step 1 complete (glossary sub-task resolved).
  - **When**: Inspect `.cwf/docs/glossary.md` for "namespaced scratch path" or "canonical tmp dir".
  - **Then**: Either an entry exists (with a one-line definition and link to `.cwf/docs/conventions/tmp-paths.md`), or `g-testing-exec.md` records the explicit "no new term coined" finding from Step 1.

### Non-Functional Test Cases

- **TC-NF1 (security — symlink-attack defence reads correctly)**: The threat-model section must explicitly name the symlink-attack scenario (`/tmp/` predictability + multi-user host) and prescribe `mkdir -m 0700` *before* any write. Verify by reading the section as a security reviewer would; pass = a reader unfamiliar with the convention would correctly avoid both symlink-clobber and secret leakage. Subjective pass/fail.

- **TC-NF2 (`cwf-manage validate` regression)**: Pre-implementation, capture `cwf-manage validate` exit code + violation count. Post-implementation (after Step 6 chmod), recapture. Pass = exit code is 0 and violation count is 0. The `cwf-security-reviewer-changeset.md` permissions warning that fired throughout planning phases is expected to be *gone* post-implementation — that's the Step 6 success signal.

- **TC-NF3 (chmod-only, no content drift)**: After Step 6, `sha256sum .claude/agents/cwf-security-reviewer-changeset.md` must equal `c7033a74da495e7ef7b401f0b88ab6b8d8e53cfb69acb1a924c463bb182095e5` (the value recorded in `script-hashes.json:27`). Pass = SHAs match; this proves the restoration touched permissions only, not content.

### Adjacent-work verification (memory grep gate)

- **TC-M1: Memory files reference canonical form**
  - **When**: `grep -rln '/tmp/' ~/.claude/projects/-home-matt-repo-coding-with-files/memory/ | xargs grep -l '/tmp/task-\|/tmp/cwf-task-\|/tmp/msg\.txt' || true`
  - **Then**: Empty result (no stale forms). Any remaining `/tmp/...` mentions must reference `tmp-paths.md` or appear inside an explicit "historical reference" annotation.
  - **Blocking**: This gate must pass before marking the task Finished. Failure means Step 4 of d-implementation-plan is incomplete.

## Test Environment

### Setup Requirements
- A scratch directory at `/tmp/-home-matt-repo-coding-with-files-task-145/` (the convention dogfoods itself — phase g operates inside the convention's own canonical path).
- Two ephemeral repo-root paths (`/tmp/repo-a`, `/tmp/repo-b`) for TC-3. No real git operations needed; the derivation snippet is path-arithmetic only.
- Standard CWF tooling available (`grep`, `awk`, `sed`, `diff`, `cwf-manage`).

### Automation
- Tests run inline during g-testing-exec as Bash tool calls.
- No CI integration (docs-only chore; existing CI covers Perl helper integrity).
- No test execution schedule.

## Validation Criteria
- [ ] TC-1 through TC-7 all pass (including TC-5b).
- [ ] TC-NF1 (security read) passes subjective review.
- [ ] TC-NF2 (validate regression) confirms zero violations post-implementation (Step 6 cleared the pre-existing warning).
- [ ] TC-NF3 (chmod-only, no content drift) confirms SHA unchanged after permission restoration.
- [ ] TC-M1 (memory grep gate) returns empty.
- [ ] Headline goal met: two simulated repo roots produce non-colliding scratch paths via the documented snippet.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
