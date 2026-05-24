# security-reviewer clean reviews misclassified - Design
**Task**: 162 (bugfix)

## Task Reference
- **Task ID**: internal-162
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/162-security-reviewer-clean-reviews-misclassified
- **Template Version**: 2.1

## Goal
Replace the fragile line-1-sentinel contract between the `cwf-security-reviewer-changeset` subagent and its callers with a deterministic, position-independent verdict container parsed by a single helper script — so clean reviews are no longer misclassified as `error`/`findings`, while genuinely malformed output still surfaces as `error`.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Current State (verified against code)
- The subagent (`.claude/agents/cwf-security-reviewer-changeset.md`) is told its **VERY FIRST output line** must be a sentinel (`findings:` / `no findings` / `error:`).
- Classification is **LLM-applied prose**, not a script: the "three-tier rule" lives in `.cwf/docs/skills/security-review.md` § "Exec-phase prompt template" and is referenced (one-line summary) by Step 8 of both `cwf-implementation-exec/SKILL.md` and `cwf-testing-exec/SKILL.md`.
- Tier-2 of that rule infers `findings` from any numbered list (`^\s*\d+[.)]\s`) or the phrase "actionable finding" — the source of false `findings` on clean reviews (126-g, 133-g, 134-g).
- CWF **already ships hooks**, at `.cwf/scripts/hooks/` (`stop-stale-status-detector`, `stop-uncommitted-changes-warning`), both hash-tracked (`script-hashes.json:260,265`) and registered by `cwf-claude-settings-merge`. That merge helper, however: (i) only discovers hook scripts whose manifest path matches `^\.cwf/scripts/hooks/[^/]+$` (line 84); (ii) only emits `hooks.Stop` entries shaped `{type, command, timeout=>5}` with **no matcher** (lines 145–167); (iii) `validate_write_path_allowlist`s manifest paths against `['.cwf/scripts/']`, so a `.claude/hooks/` path would make it **die**. There is **no** `SubagentStop` support and **no** `agent_type`-matcher support today. (`.claude/hooks/` is enumerated in `security-review-changeset`'s `@CWF_INTERNAL_PREFIXES` only for *review/hash coverage* — that is a different mechanism from *registration* and does not make a hook installable there.)

## Key Decisions

### D1 — Verdict container: a labelled fenced `cwf-review` block (position-independent)
- **Decision**: the subagent ends its response with a fenced block carrying the machine verdict; reasoning prose may precede it freely:
  ````
  ```cwf-review
  state: <no findings|findings|error>
  summary: <optional one-line note>
  ```
  ````
  Human-readable findings detail stays in the prose body (recorded verbatim); the block carries only the classification.
- **Rationale**: empirically the model reasons first and states its verdict last (across the corpus the verdict reliably landed at the *end* when not on line 1). A labelled fence is exact-match-greppable and immune to the markdown-wrapping variance (bare / `**bold**` / `` `backtick` `` / `> blockquote` / trailing-sentence) that defeated bare-token matching. Position-independence removes the line-1 dependency that failed in all 9 bucket-B cases and regressed at Task 142 even after character-level coercion.
- **Trade-offs**: less skimmable than leading frontmatter; mitigated because the SKILL already surfaces `**State**:` above the verbatim block in the wf file.

### D2 — Deterministic classifier helper as single source of truth
- **Decision**: add `.cwf/scripts/command-helpers/security-review-classify` (Perl, core-only). Reads the subagent output on **stdin**, prints exactly one canonical token (`no findings` | `findings` | `error`) on stdout. Both exec SKILLs call it in Step 8 instead of applying prose rules; the SubagentStop hook (D4) reuses it.
- **Rationale**: converts the LLM-applied three-tier rule into a deterministic, unit-testable parser — aligns with CWF's "scripts handle deterministic operations" philosophy and the "bake checks into scripts" principle. One parser means no drift between the two exec skills and the hook. Enables direct regression tests: feed the ~76 recorded historical subagent outputs to the classifier and assert the corrected verdict.
- **Trade-offs**: new code, justified by three callers (Rule of Three): impl-exec, testing-exec, hook.

### D3 — Parse rule (drops the numbered-list heuristic)
- Collect every `cwf-review` fenced block in the input whose `state:` value (trimmed, case-insensitive) is exactly one of the three tokens.
- **Exactly one valid block → that state.**
- **Zero valid blocks, OR more than one valid block → `error`** (surface; never silently downgrade to `no findings`). Treating >1 valid block as `error` (rather than "unanimous → that state") removes the masking edge the robustness review flagged: an echoed example block plus a real verdict cannot be silently accepted.
- **Echoed-example safeguard**: the worked example in the agent definition (D1) must use a non-token placeholder for `state:` (literally `<no findings|findings|error>`), so an echoed example block never validates and never counts toward the block tally.
- The tier-2 numbered-list / "actionable finding" heuristic is **removed entirely** — severity comes only from the explicit `state:` field.
- Skill-authored deterministic short-circuits (on-main, empty changeset, >500-line cap) are unchanged: the SKILL still writes those verdicts directly without invoking the subagent or the classifier.

### D4 — SubagentStop hook enforcement (backstop) — *scope decision pending (see Decomposition)*
- **Decision**: add a hook at `.cwf/scripts/hooks/subagentstop-security-verdict-guard` (matching the existing hook location and the merge helper's `.cwf/scripts/` write-allowlist — **not** `.claude/hooks/`). Perl, `JSON::PP` (core; the merge helper already uses it). On SubagentStop it reads stdin JSON, extracts `last_assistant_message`, runs the D2 classifier; if no valid `cwf-review` block is present it returns `{"decision":"block","reason":"<re-emit-a-cwf-review-block instruction>"}`, otherwise it allows the stop (no JSON / exit 0). Matched in settings to `agent_type: cwf-security-reviewer-changeset` (the agent's frontmatter `name`). SubagentStop field/matcher/loop-guard semantics verified against the saved reference `/tmp/-home-matt-repo-coding-with-files-task-162/hooks.md` §SubagentStop (lines 1750–1777).
- **Fail-open invariant (security-critical)**: the hook MUST never trap the subagent. Body wrapped in `eval`; on any internal error, malformed stdin JSON, missing/un-executable classifier, or `stop_hook_active == true`, it **allows the stop** (exit 0 / no decision) and leaves the SKILL-side D2 classifier as the authority (which renders the conservative `error`). It must never block on its own failure and never let a verdict-less response through as `no findings`. This mirrors the existing hooks' "always exit 0, whole body in `eval`" discipline.
- **True footprint (corrected from the original "reuse existing path" framing)**: `cwf-claude-settings-merge` cannot register this hook today. D4 requires **extending that hash-tracked helper** to (a) recognise/emit a `SubagentStop` event and (b) support an `agent_type` matcher object — neither exists. The hook script and the helper edit both require same-commit hash refreshes. `stop-hooks-framework.md` (currently Stop-only) must also gain SubagentStop documentation. This is real, security-sensitive plumbing, not a free add-on.
- **Rationale**: guarantees the block is present rather than merely likely. But note the residual gap is narrow: the only attested failure mode is positional/formatting (0/23 genuinely malformed), and D1's position-independent block already eliminates that. D4 guards "model omits the block entirely" — zero attested instances to date.
- **Trade-offs**: meaningful distribution + maintenance footprint (merge-helper extension, new enforcing-hook pattern, framework doc, two hash refreshes) for a backstop against an unobserved failure mode. The core fix (D1–D3) is fully functional without it.

## System Design
### Component Overview
- **Agent definition** (`.claude/agents/cwf-security-reviewer-changeset.md`): owns the container-format contract and a short worked example using **neutral placeholder content** (so the model anchors on shape, not a verdict). Replaces the line-1-sentinel instructions.
- **`security-review-classify`** (new helper): the deterministic parser; single source of truth for D3.
- **`security-review.md`**: § "Exec-phase prompt template" three-tier rule (lines 143–149) is replaced by a reference to the `security-review-classify` helper + the container contract.
- **Exec SKILLs** (impl-exec / testing-exec, Step 8): both Step 8 lines that currently say "Classify per the three-tier rule in `security-review.md`" (`cwf-implementation-exec/SKILL.md:56` and the `cwf-testing-exec/SKILL.md` equivalent) change to "write subagent output to the task tmp dir, pipe through `security-review-classify`, record `**State**:` + verbatim output". Both must change so neither caller references a deleted rule.
- **(D4 only) Hook + merge-helper extension + framework doc**: `.cwf/scripts/hooks/subagentstop-security-verdict-guard`, the `cwf-claude-settings-merge` SubagentStop+matcher extension, and the `stop-hooks-framework.md` update.

### Data Flow
1. Exec SKILL builds the changeset via `security-review-changeset --phase=<implementation|testing>`.
2. Skill-authored short-circuits (on-main / empty / >500-line cap) record their verdict directly and stop — unchanged.
3. Otherwise: Agent call → subagent reasons in prose, then emits a trailing `cwf-review` block.
4. (D4) SubagentStop hook verifies block presence; blocks + forces re-emit if absent.
5. SKILL writes the subagent output to a tmp file → `security-review-classify` → canonical state.
6. SKILL appends `## Security Review`, `**State**: <state>`, then the verbatim output.

### Interface Design
- **Container** (subagent → callers): fenced ```` ```cwf-review ```` block; keys `state:` (required, one of three tokens), `summary:` (optional, one line).
- **Classifier CLI**: `security-review-classify` reads stdin, prints one canonical token to stdout. Deterministic; same input always yields same token.
- **Hook input**: SubagentStop JSON on stdin; consumes `last_assistant_message` and `stop_hook_active`; emits Stop-decision JSON on stdout.

## Constraints
- **Surface, never smooth**: absent/malformed/conflicting verdict → `error`, never auto-downgraded.
- POSIX / core-Perl only (`JSON::PP` is core since 5.14).
- Hash-tracked edits (agent definition, new hook, new helper) refresh `.cwf/security/script-hashes.json` in the same commit (hash-updates convention); disclose at implementation-plan time.
- The hook must survive `cwf-manage update` — reuse the existing `install.bash` settings-merge path.

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [x] **Complexity**: 3+ distinct concerns? Yes — (i) container format + classifier + exec wiring, (ii) hook, (iii) install/settings plumbing.
- [ ] **Risk**: high-risk components needing isolation? No.
- [x] **Independence**: separable? The hook (D4) + its install plumbing is independent of the core fix (D1–D3).

**Recommendation (revised after plan review)**: the plan review established that D4's premise was wrong — it is not a free "reuse the existing settings-merge path" add-on; it requires extending the hash-tracked `cwf-claude-settings-merge` with a new event type + matcher support, a new enforcing-hook pattern, framework-doc changes, and carries a security-sensitive surface — all to guard a failure mode with **zero** attested instances (D1 alone eliminates every historical misclassification). The improvements reviewer recommended dropping D4; robustness/misalignment/security reviewers all flagged it as the dominant risk and undisclosed cost.

Three scopes were weighed: (A) core fix only, drop/backlog D4; (B) core in 162 + D4 as subtask 162.1; (C) both in Task 162.

**Decision (user, before exec): (C) — both D1–D4 in Task 162.** The merge-helper `SubagentStop`+matcher extension, the new enforcing-hook pattern with its fail-open invariant, and the `stop-hooks-framework.md` update are all in scope here. Consequences accepted: a larger changeset that will very likely exceed the 500-line security-review cap (so this task's own exec-phase security review will be the skill-authored `error: exceeds cap` path → manual threat-category walkthrough), and the coupling of the simple parser fix with security-sensitive settings-merge plumbing. The implementation plan (d) sequences D1–D3 first so the core fix is coherent before the D4 plumbing lands.

## Validation
- [ ] **Classifier unit tests** (primary evidence): synthetic fixtures fed to `security-review-classify` on stdin — clean verdict wrapped in heavy reasoning prose, each markdown wrapping (bare/bold/backtick/blockquote) around the fenced block, `findings`/`error` blocks, zero blocks, invalid `state:`, duplicate valid blocks, echoed non-token example. Each asserts the canonical token.
- [ ] **Note — the historical corpus cannot be fed directly**: the ~76 recorded `## Security Review` blocks predate the `cwf-review` format and contain only the old `**State**:` line + verbatim prose; under D3 they would all classify `error` (zero blocks). They are useful as *prose shapes to wrap into synthetic fixtures*, not as direct classifier input.
- [ ] **End-to-end "bug fixed" evidence**: re-run the subagent (with the new agent definition) against a small sample of historical changesets (e.g. the bucket-B tasks 140/142/143/158) and confirm the clean ones now classify `no findings`. This is the only way to demonstrate the misclassification is resolved, since it exercises the new agent output, not just the parser.
- [ ] Skill-authored short-circuit paths (on-main / empty / cap) verified unchanged.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All four decisions implemented as designed: D1 trailing `cwf-review` block (non-token placeholder in the worked example), D2 `security-review-classify` as single authority, D3 exactly-one-valid-block rule (numbered-list heuristic removed), D4 fail-open SubagentStop guard + `cwf-claude-settings-merge` event/matcher extension + `stop-hooks-framework.md` documentation. The corrected "true footprint" framing held — the merge-helper extension was the one non-trivial edit and landed with the Stop path byte-identical.

## Lessons Learned
Matching the verdict format to how a reasoning model actually writes (reason first, conclude last) is what made the fix durable where line-1-sentinel coercion had regressed. The fail-open, affirmative-only hook invariant proved both the safest and the simplest to test.
