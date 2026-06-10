# Reviewer agents prefer tools over Bash - Implementation Execution
**Task**: 186 (chore)

## Task Reference
- **Task ID**: internal-186
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/186-reviewer-agents-prefer-tools-over-bash
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status when complete

## Actual Results

### Step 1: Guidance edits — done
- **`cwf-agent-shared-rules.md`** (hash-tracked): lead strengthened to "**Strongly
  prefer earlier tiers over raw Bash**"; tier 1 now names **LSP** (code
  intelligence when a language server is configured, graceful fall-through to
  Grep) and Read for structured text; tier 2 names the **markdown-reader** skill
  for Markdown sections/headings/frontmatter. Two anti-pattern rows added
  (`grep -rn 'sub foo'`→LSP; md `sed`/`grep`/`cat`→markdown-reader).
- **`subagent-tool-selection.md`** (not tracked): mirrored the tier-1 LSP and
  tier-2 markdown-reader additions + the two anti-pattern rows, kept textually in
  sync with shared-rules. Corrected the stale **§ Existing usage** line that
  claimed `plan-review.md` inlines a rubric excerpt (verified false via grep —
  it inlines nothing); repointed it to `cwf-agent-shared-rules.md`.
- **`security-review.md:12`** (not tracked): grant enumeration updated to
  `Read, Grep, Glob, LSP, Bash`; "No `Bash`" assertion removed; retained-Bash
  guided-last-resort posture recorded; **FR4(c) residual-threat** paragraph added
  (untrusted reviewed content + Bash grant ⇒ prompt-injection blast radius
  includes command execution, mitigated by guidance + absence of `Edit`/`Write`).

### Step 2: Grant fix (frontmatter) — done
- All five `.claude/agents/cwf-*reviewer*.md` line 4 changed from the ignored
  `allowed-tools: Read, Grep, Glob` to the honoured
  `tools: Read, Grep, Glob, LSP, Bash`. Confirmed identical pre-edit on all five.
- `cwf-manage fix-security` reported **0 files repaired** — the harness already
  restores recorded `0444` after an edit (chmod-then-restore), so no owner-write
  bit leaked. (Deviation from plan note, see below.)

### Step 3: Hash refresh (same commit) — done
- Pre-verified `git log 6659c1c..HEAD` for all six hashed files: **empty** (no
  intervening edits). Refreshed sha256 for the six entries (five agents +
  `agent-shared-rules`) in `.cwf/security/script-hashes.json`. `cwf-manage
  validate` → **OK**.

### Step 4: CHANGELOG — done
- Added `## Task 186: reviewer agents prefer tools over Bash (chore)` entry
  covering the grant fix, the guidance sharpening, the posture doc + FR4(c) note,
  and the session-cache acceptance caveat. No tagging (human-only).

### Step 5: Validation — done
- TC-1 zero `allowed-tools:` under `.claude/agents/`; TC-2 exactly five
  `tools: Read, Grep, Glob, LSP, Bash` lines; TC-3 `security-review.md` no
  longer asserts "No Bash"; `cwf-manage validate` clean. Fresh-session
  acceptance (TC-8/9/10) deferred to g-testing-exec (agent defs session-cached).

## Deviations
- **fix-security was a no-op (0 repairs).** The plan anticipated clamping an
  owner-write bit added by editing a `0444` file; the harness restores recorded
  perms on write, so there was nothing to clamp. Integrity still verified via
  `validate: OK`. No functional impact.

## Blockers Encountered

None.

## Security Review

**State**: no findings

The on-disk sha256 values match the recorded entries in the `script-hashes.json` diff exactly (improvements `ca7f82df…`, misalignment `4e9fa220…`, robustness `df96c914…`, security `6fd22fdf…`, changeset `6e1f5c5c…`, shared-rules `cff45fb3…`). The same-commit hash refresh is internally consistent. Hash/permission integrity is the province of `cwf-manage validate`, not this review, but the refresh being self-consistent means there's no drift to flag.

Now let me reason through each threat category against the substantive change.

**The central change is a security-relevant tool-grant widening, and the diff itself documents it.** The five reviewer agents moved from `allowed-tools: Read, Grep, Glob` (an ignored key → silent all-tools inheritance) to `tools: Read, Grep, Glob, LSP, Bash`. Relative to the *intended* posture (Read/Grep/Glob, no Bash), this adds `Bash` and `LSP`. Relative to the *actual broken posture* (all tools, including Edit/Write/Agent/WebFetch), this is a tightening.

**(a) Bash injection / unsafe command construction** — No shell command is constructed anywhere in this diff. No `system()`, no backticks, no string interpolation into commands. Not applicable.

**(b) Perl helpers consuming git/user output without `-z`** — No Perl is added or modified. The `script-hashes.json` change is pure data. Not applicable.

**(c) Prompt injection via user-supplied strings** — This is the live category, and the changeset handles it correctly. The reviewer agents consume untrusted input (plan files, diffs carrying task descriptions and `{arguments}`). Granting `Bash` to an agent that ingests untrusted content widens the prompt-injection blast radius from "read/search" to "arbitrary command execution." The diff does not hide this: `security-review.md:14` adds an explicit named **Residual threat (FR4(c))** paragraph stating exactly this — that reviewed content is untrusted, that Bash widens the blast radius to command execution, and that the only mitigations are tool-tier guidance plus the absence of `Edit`/`Write`. The `d-implementation-plan.md` "Security Notes" section and the CHANGELOG entry repeat the disclosure. This is the "surface, don't smooth" posture done correctly: the risk is named, attributed to a deliberate user decision (markdown-reader needs a Bash grant), and a narrowing follow-up is recorded. I treat this as a disclosed, accepted posture rather than an actionable finding.

**(d) Unsafe environment-variable handling** — No env-var handling introduced. Not applicable.

**(e) Pattern-based risks (safe-here-but-risky-elsewhere)** — There is one pattern worth surfacing under the explicit carve-out framing. The grant `tools: Read, Grep, Glob, LSP, Bash` is now established as the copy-paste template for CWF reviewer agents (the CHANGELOG and plan describe it as "the defined grant" applied uniformly across five agents). It is acceptable *here* because the invariant holds: these five agents are read-only-by-procedure (no `Edit`/`Write` granted), and Bash is present only to launch the read-only markdown-reader skill. The risk: if a future reviewer/agent is spun up by copying this grant into a context where `Edit`/`Write` are *also* granted, the "guided, not enforced" no-mutation property collapses entirely — Bash + Edit/Write on untrusted-content ingestion is a full RCE-plus-persistence surface, with nothing structural left to stop it. Framed per the carve-out: **safe here because Edit/Write are withheld and the procedure is read-only; audit future reviewer/agent definitions that copy the `tools: …, Bash` grant to confirm they likewise withhold Edit/Write.** This is a note for future audits, consistent with the follow-up the doc itself flags (narrowing Bash back out, or settings-permissions Skill scoping); it is not a defect in the present diff.

**One observation, not a finding:** The diff grants `Bash` (unrestricted) rather than the narrower capability actually needed. The stated justification is that the markdown-reader skill is a Bash-run Perl script and `rg` for multiline searches — both legitimate. The harness has no sub-Bash granularity in frontmatter (the plan verified that per-skill scoping is a settings-permissions construct, not frontmatter), so unrestricted Bash is the only expressible grant that keeps markdown-reader usable. The diff documents this constraint and the residual risk explicitly. Given the absence of `Edit`/`Write` and the read-only procedures, this is a defensible, fully-disclosed posture decision, not an actionable concern.

Verdict: the only security-relevant change is a tool-grant widening that the diff itself discloses, names against FR4(c), attributes to a deliberate decision, and pairs with a recorded narrowing follow-up. The hash refresh is self-consistent. No undisclosed or actionable security concern remains in the changeset. The category (e) note is an audit pointer with the required safe-here framing, not a blocking finding.

```cwf-review
state: no findings
summary: Doc/frontmatter-only diff; the sole security-relevant change (reviewer Bash grant) is explicitly disclosed and named against FR4(c), hash refresh is self-consistent. One category-(e) audit pointer (safe here: Edit/Write withheld) carries no actionable defect.
```

## Deferral Check
Before marking status=Finished, verify:
- [ ] All steps from d-implementation-plan.md executed
- [ ] All success criteria from a-task-plan.md met
- [ ] All requirements from b-requirements-plan.md addressed (if applicable)
- [ ] All design guidance in c-design-plan.md followed (if applicable)
- [ ] No planned work deferred without user approval
- [ ] If work deferred: Follow-up task created and linked

**If deferral required**: Get user approval, document rationale, create follow-up task.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
