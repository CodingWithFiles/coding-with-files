# Lint agent files for ignored allowed-tools key - Implementation Plan
**Task**: 193 (hotfix)

## Task Reference
- **Task ID**: internal-193
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/193-lint-agent-files-for-ignored-allowed-tools-key
- **Template Version**: 2.1

## Goal
Add `CWF::Validate::Agents` — a validator that flags any CWF agent file whose
frontmatter uses the silently-ignored `allowed-tools:` key (correct key: `tools:`)
— and wire it into `cwf-manage validate`.

**Scope (per a-task-plan Open Decision 1)**: lint *only* `allowed-tools:` for this
hotfix. A general "unknown agent frontmatter key" linter is deferred to a backlog item.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Approach (mirrors `CWF::Validate::Templates`)
The new validator copies the established validator contract exactly:
`validate($git_root)` returns a (possibly empty) list of violation hashrefs with keys
`category, file, field, actual, expected, fix`; `cmd_validate` aggregates and prints them.

### Scan target (per a-task-plan high-priority risk)
Agent files live at different paths by context. Resolve **one** target per run:
- If `-d "$git_root/.cwf-agents"` → scan `$git_root/.cwf-agents/cwf-*.md`
  (installed consuming project: these are the real files).
- Else → scan `$git_root/.claude/agents/cwf-*.md`
  (this dev repo: the source files; no `.cwf-agents/` exists here).

This avoids double-counting (in a consuming project `.claude/agents/cwf-*.md` are
symlinks *into* `.cwf-agents/`, so we never scan both). Restrict the glob to the
`cwf-*` namespace so the validator polices CWF-namespaced agents only, not a user's
own (non-`cwf-`) agent files. Enumerate via `opendir`/`readdir` +
`grep /^cwf-.*\.md\z/` (matches `Templates.pm` style); skip non-files.

### Detection (per a-task-plan medium risk: parsing brittleness)
For each candidate file, inspect **only the YAML frontmatter block**, not body prose:
1. Read the file. Line 1 must be an opening marker matching `/^---\s*$/`; if not,
   the file has no frontmatter → skip (no violation).
2. Scan subsequent lines for the **closing** marker, also anchored as a full line
   (`/^---\s*$/`). Flag any line *before* the close matching `/^allowed-tools\s*:/`
   (key at line start, optional spaces before colon).
3. **Unterminated frontmatter** (EOF reached with no closing `---`): treat the block
   as having no valid frontmatter → skip (no violation). Do **not** fall back to
   scanning the whole file — that would reintroduce the body false-positive TC-3 guards against.
4. First match per file → one violation for that file (do not emit duplicates).

## Files to Modify
### Primary Changes
- `.cwf/lib/CWF/Validate/Agents.pm` *(new)* — the validator module. Package
  `CWF::Validate::Agents`, `@EXPORT_OK = qw(validate)`. Header comment block in the
  house style. `use strict/warnings/utf8`. Core-only (no non-core modules).
  Violation shape:
  - `category => 'AGENTS'`
  - `file     => <repo-relative path>` (e.g. `.claude/agents/cwf-foo.md`)
  - `field    => 'frontmatter-key'`
  - `actual   => 'allowed-tools:'`
  - `expected => 'tools:'`
  - `fix      => "Rename the 'allowed-tools:' key to 'tools:'."` (terse imperative,
    matching sibling validators; the *why* — Claude Code silently ignores
    `allowed-tools:` in agent definitions, leaving the agent with all tools — lives in
    the module header comment, not repeated in every emitted violation).
- `.cwf/scripts/cwf-manage` — two edits:
  - Add `use CWF::Validate::Agents ();` alongside the other `use CWF::Validate::*`
    lines (~line 30-36).
  - Add `CWF::Validate::Agents::validate($git_root),` to the `@all_violations` list
    in `cmd_validate` (~line 605-614).

### Supporting Changes
- `t/validate-agents.t` *(new)* — unit tests over tempdir fixtures (see Test Coverage).
- `.cwf/security/script-hashes.json` — add the entry for the new module **in the same
  commit** ([[hash-updates]]):
  ```json
  "CWF::Validate::Agents" : {
    "path" : ".cwf/lib/CWF/Validate/Agents.pm",
    "sha256" : "<sha256sum of the final file>"
  }
  ```
  Lib `.pm` modules carry **no** `permissions` key (perms stay 0600/`100644`, like the
  sibling validators). Compute the digest with `sha256sum` (the verifier uses
  `Digest::SHA` — keep implementation diversity at the producer/verifier boundary).
  `cwf-manage` is an executable script and is itself hashed: refresh **its** sha256 in
  the same commit too, since this task edits it.

### Not changed
- `.cwf/install-manifest.json` — no edit. `scripts/install.bash` lays down the whole
  `.cwf` tree via `git ls-files -z -- .cwf … | git checkout-index`, so a new tracked
  `.cwf/lib/...` file is included automatically (the manifest does not enumerate
  individual lib files).
- No existing agent file changes (all five already use `tools:`).

## Implementation Steps
### Step 1: Test-first
- [ ] Write `t/validate-agents.t` with fixtures (positive + negative + edge cases per
      Test Coverage). Run it — the positive case fails (module absent). Red.

### Step 2: Module
- [ ] Create `.cwf/lib/CWF/Validate/Agents.pm` implementing the scan-target +
      frontmatter-only detection above. `chmod 0600`.
- [ ] Re-run `t/validate-agents.t` → green.

### Step 3: Wire-in
- [ ] Add `use CWF::Validate::Agents ();` and the `cmd_validate` call in `.cwf/scripts/cwf-manage`.
- [ ] `cwf-manage validate` stays green on the real tree (all five agents use `tools:`).
      (Positive detection is covered deterministically by TC-2/TC-4 over tempdir
      fixtures — no manual flip-and-revert of a live agent file, which risks leaving a
      broken agent / dirty tree if interrupted.)

### Step 4: Integrity
- [ ] `sha256sum .cwf/lib/CWF/Validate/Agents.pm` and `.cwf/scripts/cwf-manage`; update
      both entries in `script-hashes.json`.
- [ ] `cwf-manage validate` → OK (PerlConventions + Security/hash checks pass).

### Step 5: Full suite
- [ ] Run the `t/` suite (`prove t/`) — no regressions.

## Test Coverage
**See e-testing-plan.md for the complete test plan.** Headline cases:
- TC-1 happy path: fixture `.claude/agents/cwf-x.md` with `tools:` → 0 violations.
- TC-2 bad key: fixture with `allowed-tools:` in frontmatter → 1 AGENTS violation, all
  hashref fields asserted, file path correct.
- TC-3 frontmatter-only: `allowed-tools:` appearing in the **body** (after closing `---`)
  → 0 violations (no false positive).
- TC-4 `.cwf-agents/` branch: fixture builds `.cwf-agents/cwf-x.md` (no `.claude/agents`)
  with bad key → flagged; confirms the installed-context path.
- TC-5 non-CWF file ignored: `.claude/agents/other.md` (no `cwf-` prefix) with bad key
  → 0 violations.
- TC-6 no-frontmatter file (line 1 is not `---`) → 0 violations.
- TC-7 unterminated frontmatter: opening `---` on line 1, no closing `---`, with
  `allowed-tools:` appearing later in the file → 0 violations (block is not valid
  frontmatter; must not scan the whole file).
- The real-tree regression (current five agents pass) is exercised by `cwf-manage validate`.

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Implemented per plan (`38ffb41`). One deviation: detection reworked to a two-pass
find-close-then-scan after TC-7 failed against the initial single-pass cut — same intent
("skip unterminated blocks"), corrected control-flow shape. See f-implementation-exec.md Step 2.

## Lessons Learned
A plan that names an *invariant* (skip unterminated frontmatter) should, where cheap, also
pin the *control-flow shape* that guarantees it ("two-pass: find terminator, then scan
inside") — the gap is exactly where the defect entered. Full set in j-retrospective.md.
