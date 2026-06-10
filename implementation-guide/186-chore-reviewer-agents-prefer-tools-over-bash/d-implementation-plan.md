# Reviewer agents prefer tools over Bash - Implementation Plan
**Task**: 186 (chore)

## Task Reference
- **Task ID**: internal-186
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/186-reviewer-agents-prefer-tools-over-bash
- **Template Version**: 2.1

## Goal
Make the five review/security subagents genuinely prefer specialised tools
and skills over raw Bash: (1) sharpen the shared tool-tier guidance to name
`LSP` and the `markdown-reader` skill with strong-preference framing, and
(2) correct the ignored `allowed-tools:` subagent frontmatter key to the
honoured `tools:` key with a **defined** grant `Read, Grep, Glob, LSP, Bash`
— replacing the silent all-tools inheritance while keeping Bash so the
markdown-reader skill (a Bash-run Perl script) remains usable.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Resolved Decision (user, at review gate)
**Keep Bash; guide hard.** Grant `tools: Read, Grep, Glob, LSP, Bash`.
Guidance strongly steers reviewers to Read/Grep/Glob/LSP and the
markdown-reader skill, with raw Bash as the last resort. Rationale: the
`markdown-reader` skill is a Bash-run Perl script, so it is only usable if
the reviewer holds a Bash grant — removing Bash would make the requested
markdown-reader preference impossible. Consequence: `security-review.md:12`
(which currently documents "No `Bash`") is updated to reflect the retained
Bash, governed by guidance rather than enforcement; `Edit`/`Write` remain
ungranted.

## Key Findings (audit + docs verification)
- **`allowed-tools:` is ignored for subagents.** This session's harness
  agent registry reported all five reviewers as "(Tools: All tools)" despite
  `allowed-tools: Read, Grep, Glob`. The honoured key is `tools:`. Skills use
  `allowed-tools:` (a *different* schema) — `.claude/skills/*/SKILL.md` are
  correct and **out of scope**.
- **Docs verification (code.claude.com):**
  - `tools:` accepts both a comma-separated string and a YAML array (we keep
    the existing comma-separated style).
  - `LSP` is a documented built-in tool (tools-reference) — valid grant token.
  - **Skills are invokable by subagents at runtime via the `Skill` tool
    without listing `Skill` in `tools:`** ("without [the `skills:` field] the
    subagent can still discover and invoke project, user, and plugin skills
    through the Skill tool during execution"). So naming the markdown-reader
    skill in guidance + granting Bash is sufficient; no `Skill` token and no
    `skills:` preload field are required.
  - Per-skill scoping (`Skill(markdown-reader)`) is a **settings-permissions**
    construct, **not** a frontmatter capability — frontmatter cannot restrict
    a subagent to a single skill (the `skills:` field only controls
    preloading, not access). See Security Notes.
  - Behaviour of an **unrecognised** `tools:` token is undocumented → use only
    confirmed names (all five are confirmed) and verify in a fresh session.
- **`markdown-reader` is a Bash-run Perl-script skill** at
  `~/.claude/skills/markdown-reader/` (a *personal/user* skill, not shipped by
  CWF). Reviewers installed into other repos won't have it — hence it is named
  in guidance "when available", never assumed.
- **`LSP` is read-only** (goToDefinition/findReferences/documentSymbol/…),
  errors gracefully with no server. This repo (Perl/Markdown) likely has no
  server; LSP is granted for downstream installs that do.
- **Hash tracking.** The 5 agent files **and** `cwf-agent-shared-rules.md`
  are sha256-tracked (`permissions: "0444"`). `subagent-tool-selection.md`,
  `security-review.md`, and `plan-review.md` are **not** tracked.
- **`plan-review.md` inlines no tier enumeration** (verified) — no edit needed.

## Files to Modify
### Primary Changes
- `.cwf/docs/skills/cwf-agent-shared-rules.md` — Tool-tier preference §:
  tier 1 adds `LSP` ("when a language server is configured") and `Read` for
  structured text; tier 2 (Skills) names the **markdown-reader** skill for
  reading/searching Markdown sections over `cat`/`sed`/`grep`-on-markdown;
  strengthen the lead to "**strongly** prefer … over raw Bash". Tiers 3–5
  stay (reviewers hold Bash). **(hash-tracked)**
- `.cwf/docs/conventions/subagent-tool-selection.md` — mirror the tier-1
  `LSP` and tier-2 markdown-reader additions. (not hash-tracked)
- `.cwf/docs/skills/security-review.md` (line ~12) — update the documented
  grant from "Read, Grep, Glob; No Bash" to the new defined set
  `Read, Grep, Glob, LSP, Bash`; state plainly that Bash is retained as a
  guided last resort (e.g. to run the markdown-reader skill / `rg`), that
  state-mutation avoidance now rests on guidance + the absence of
  `Edit`/`Write`, and that this is a deliberate posture choice. **Name the
  residual threat concretely**: reviewed content (plan files, diffs carrying
  task descriptions / `{arguments}`) is untrusted input per FR4(c); with Bash
  granted, the prompt-injection blast radius now includes command execution,
  mitigated only by guidance and the absence of `Edit`/`Write`.
  (not hash-tracked)
- `.claude/agents/cwf-plan-reviewer-improvements.md` — frontmatter
  `allowed-tools: Read, Grep, Glob` → `tools: Read, Grep, Glob, LSP, Bash`. **(hash-tracked)**
- `.claude/agents/cwf-plan-reviewer-misalignment.md` — same. **(hash-tracked)**
- `.claude/agents/cwf-plan-reviewer-robustness.md` — same. **(hash-tracked)**
- `.claude/agents/cwf-plan-reviewer-security.md` — same. **(hash-tracked)**
- `.claude/agents/cwf-security-reviewer-changeset.md` — same. **(hash-tracked)**

### Supporting Changes
- `.cwf/security/script-hashes.json` — refresh sha256 for the 6 hashed files
  (5 agents + shared-rules doc). Plan-time disclosure per `hash-updates.md`.
- `CHANGELOG.md` — entry: guidance sharpening (LSP + markdown-reader) + the
  `allowed-tools:`→`tools:` correction, with the security note that the
  reviewers were silently inheriting ALL tools and are now a defined set
  (`Read, Grep, Glob, LSP, Bash`; no Edit/Write).

## Implementation Steps
### Step 1: Guidance edits
- [ ] `cwf-agent-shared-rules.md`: tier-1 add `LSP` (when a server is
  configured) + `Read` for structured text; tier-2 add the markdown-reader
  skill; strengthen lead to "**strongly** prefer … over raw Bash"; add an
  anti-pattern row `grep -rn 'sub foo'` → `LSP goToDefinition/findReferences
  (when available)` and `sed/grep on a .md` → `markdown-reader section`.
  Keep `Grep`/markdown-reader the *unconditional default* for this repo's
  Perl/Markdown; LSP is the preferred path only "when a server is configured"
  so the common case doesn't route through a dead tier first.
- [ ] Mirror tier-1 `LSP` + tier-2 markdown-reader in `subagent-tool-selection.md`,
  keeping the two rubric copies **textually in sync** (the shared-rules doc
  defers to it via "Full rubric: …"). While in that file, correct the stale
  § Existing usage line (~54) that claims `plan-review.md` inlines a rubric
  excerpt — it does not.
- [ ] `security-review.md:~12`: update the grant enumeration + posture note +
  FR4(c) residual-threat sentence (see Primary Changes).

### Step 2: Grant fix (frontmatter)
- [ ] In each of the 5 agent files, replace line 4
  `allowed-tools: Read, Grep, Glob` with `tools: Read, Grep, Glob, LSP, Bash`.
- [ ] Editing a `0444` file makes the harness add owner-write; restore each to
  its recorded `0444` via `cwf-manage fix-security` (clamps the excess bit).

### Step 3: Hash refresh (same commit)
- [ ] Per hashed file, pre-verify: `git log --oneline 6659c1c..HEAD -- <path>`
  (last hash-set commit `6659c1c`, Task 185) — expect empty until this task.
- [ ] `sha256sum <path>` for the 6 hashed files; update the matching `sha256`
  entries in `.cwf/security/script-hashes.json`.
- [ ] **Note**: between Step 2 and the refresh, `cwf-manage validate` is
  *expected* to report sha256 mismatches — not a defect.
- [ ] `cwf-manage validate` → expect OK.

### Step 4: CHANGELOG
- [ ] Append an entry in the existing `## Task N: <title> (<type>)` format.
  Versioning/tagging is human-only — do not tag.

### Step 5: Validation
- [ ] `cwf-manage validate` clean.
- [ ] Static grep: no `allowed-tools:` under `.claude/agents/`; exactly five
  `tools: Read, Grep, Glob, LSP, Bash` lines; `security-review.md` no longer
  asserts "No `Bash`".
- [ ] Fresh-session smoke test (recorded in e/g): registry shows the five
  reviewers with the **exact** set `Read, Grep, Glob, LSP, Bash` and excludes
  `Edit`/`Write`; a reviewer can invoke the markdown-reader skill; a sample
  plan review still completes; the `cwf-security-reviewer-changeset` still
  emits a well-formed `cwf-review` verdict block that `security-review-classify`
  parses. **Contingency**: if markdown-reader is unreachable at runtime, add a
  `skills:` field (or reconsider a `Skill` grant) before ship — the core
  `allowed-tools:`→`tools:` fix still holds regardless.

## Code Changes
### Before (each agent file, line 4)
```yaml
allowed-tools: Read, Grep, Glob
```
### After
```yaml
tools: Read, Grep, Glob, LSP, Bash
```

## Security Notes (surface, don't smooth)
- **Net posture vs status quo**: a tightening — from *all tools* (incl.
  Edit/Write/Agent/WebFetch/…) to a defined `Read, Grep, Glob, LSP, Bash`.
  But weaker than the no-Bash alternative: Bash can mutate state, so "does not
  mutate state" is now a *guided* property (+ absence of Edit/Write), not an
  enforced one. This is the user's deliberate choice to keep markdown-reader.
- **Runtime Skill access is unchanged by this task** and cannot be narrowed in
  frontmatter: a subagent can invoke *any* available skill via the Skill tool
  (it had this under all-tools too). Restricting reviewers to only
  markdown-reader would require settings-permissions `Skill(...)` allow/deny —
  out of scope here; noted as a possible follow-up.

## Test Coverage
**See e-testing-plan.md** (static greps + `cwf-manage validate` + fresh-session
registry/markdown-reader/smoke check).

## Validation Criteria
**See e-testing-plan.md**

## Scope Completion
Guidance edits, the security-review.md update, all five grant fixes, the six
hash refreshes, and the CHANGELOG entry ship together — partial application
leaves aspirational guidance, a doc/grant divergence, or hash drift.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five steps executed as planned. One deviation: `cwf-manage fix-security` was a
no-op (0 repairs) — the harness restores recorded `0444` on write, so no owner-write
bit leaked. Both exec-phase security reviews returned `no findings`. See
`f-implementation-exec.md` for the per-step record.

## Lessons Learned
The keep-Bash decision rested on markdown-reader being a Bash-run Skill, not a
built-in — confirmed at plan time, which is what made the grant correct rather than
aspirational. Full learnings in `j-retrospective.md`.
