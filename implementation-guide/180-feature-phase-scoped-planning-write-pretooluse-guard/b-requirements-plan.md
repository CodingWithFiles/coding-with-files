# phase-scoped planning-write PreToolUse guard - Requirements
**Task**: 180 (feature)

## Task Reference
- **Task ID**: internal-180
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/180-phase-scoped-planning-write-pretooluse-guard
- **Template Version**: 2.1

## Goal
Specify R1: a PreToolUse `Edit|Write` guard that, when sandboxing is on, protects
production crown jewels during planning phases and fails **closed** on ambiguous
inference without bricking. Inherits the mechanism findings from Task 178 and the
substrate + FR4 acceptance criteria from Task 179.

## Central open question (for plan review + design)
179-AC4a said "writes are gated to the current task's own planning files; edits
to production code/skills/helpers are blocked." Two realisations exist:
- **(A) Deny-list**: during planning, **deny** writes to production crown jewels
  (`.cwf/`, `.claude/`, skills, helpers); **permit** everything else. Least
  bricking; protects the stated target; the middle ground (e.g. `BACKLOG.md`,
  `README`) stays writable.
- **(B) Allow-list**: during planning, **permit only** the current task's own
  directory; deny all else. Closest to the literal 179 wording; high brick risk
  (blocks legitimate `BACKLOG`/scratch/sibling writes).
Requirements below specify the **invariants both must satisfy** (crown jewels
blocked in planning; task-own always writable; never bricks) and mark the A/B
choice — and the treatment of the middle ground — as a **design decision**
(default leaning A, per fail-closed-without-bricking).

## Functional Requirements

### FR1 — Matcher-regex widening (substrate prerequisite)
- **AC1a**: `read_hook_directives` registers a hook whose `cwf-hook-matcher` is a
  pipe-alternation of tool-name tokens (e.g. `Edit|Write`) as the matcher in
  `.claude/settings.json`. (179 widened only the **event** allowlist.)
- **AC1b (minimal + safe)**: the widened matcher regex admits **only**
  `^[A-Za-z0-9_-]+(\|[A-Za-z0-9_-]+)*$` — an alternation over the *existing*
  token charset, no new metacharacters; any other value still falls back to the
  matcher-less default. Existing single-token matchers (TC-M*) are unaffected.
- **AC1c (rationale)**: the inert-string rationale (the parsed matcher reaches a
  `.claude/settings.json` key — FR4(e)) is restated in the helper comment.
  (Integrity/hash-refresh is owned by AC6a, not restated here.)
- **AC1d (negative)**: an empty alternation / trailing or leading pipe
  (`Edit|`, `|Write`, `||`) is **rejected** and falls back to the matcher-less
  default (one negative test exercises this).

### FR2 — Phase-scoped write gate (core)
- **AC2a**: when sandboxing is on, a PreToolUse hook matched on `Edit|Write`
  evaluates every Edit/Write call.
- **AC2b (classify by phase NAME, not letter)**: the planning/exec boundary is
  derived from the resolved phase **name** (or a version-aware map), **not** a raw
  letter comparison — v2.0 and v2.1 swap the `e`/`f` letter assignments
  (`workflow-steps.md:11`), so a hardcoded `a–e` range is a cross-version bug.
  Design fixes the exact set of phases in which CWF-system writes are expected
  (the canonical answer is **implementation-exec** — where editing `.cwf/` is the
  job; this very task is an example).
- **AC2c (planning-phase protection)**: in a planning phase (task-plan …
  testing-plan), the gate **denies** writes whose canonical target is a production
  crown jewel (set fixed at design — at minimum `.cwf/`, `.claude/`) and
  **permits** writes to the current task's own directory. (A vs B middle-ground
  treatment is the design choice above.)
- **AC2d (deny mechanism + message)**: denial uses the documented Claude Code
  PreToolUse **deny** decision; the reason is a **fixed-token** message whose
  path-class is a **fixed enumerated label** (e.g. `crown-jewel:.cwf`) from the
  design-fixed set — **never** the offending path string, `tool_input`, or file
  body echoed into harness/LLM-visible output (FR4(c)). When the phase is
  unknown (AC3a path), a fixed `phase:unknown` token is used so the message is
  always well-formed. This single message contract covers all denies (subsumes
  the former AC3c).

### FR3 — Fail-closed without bricking
- **AC3a (default-deny-crown-jewels unless positively exec)**: the gate denies a
  crown-jewel write **unless the wf step positively and unambiguously resolves to
  a recognised exec phase**. This single rule subsumes every ambiguity source —
  `task-context-inference` exit 1/2/3, an exit-0 `workflow_step: unknown` or
  unrecognised future letter, empty `task-stack`, a call outside any task, **and
  an internal exception in the hook itself**: all of them fail to positively
  resolve to an exec phase, so all deny the crown jewels. Everything **not** a
  crown jewel is **permitted** in these cases (no brick). This default-deny is the
  **outermost** behaviour (contrast R3's fail-open `eval`): an exception denies
  the crown jewels rather than allowing all.
- **AC3b (trusted source)**: the wf step + task identity derive **only** from
  `task-context-inference` / `CWF::TaskContextInference.pm`, **never** from
  free-form `tool_input` content. (TCI's own inputs — branch, `task-stack` — are
  themselves partly user-controlled; the gate trusts TCI's parsed/exit output but
  must **not** re-feed TCI's `task_slug`/branch string into the deny message —
  see AC2d.)
- **AC3c (canonical, root-correct classification)**: the target is classified by
  its **canonical** path (`realpath`/`..`-collapsed), resolved against the **same
  repo/worktree root TCI used** (the worktree-vs-main-checkout mismatch is the
  known [[feedback_worktree_cwd_dataloss]] hazard). A task-own path that resolves
  *into* a crown jewel is **denied**; if the target cannot be canonicalised to a
  definite in-repo location (escaping symlink, `realpath` error, not-yet-existing
  Write target), it is classified **conservatively as crown-jewel → deny**. Naive
  string-prefix matching does not satisfy this AC.
- **AC3d (no smoothing)**: no path through the gate may disable, relax, or
  silence a boundary or `cwf-manage validate` (`feedback_surface_security_dont_smooth`).

### FR4 — Reuse, don't reinvent
- **AC4a**: branch / `task-stack` / recency parsing and wf-step inference are
  reused from `task-context-inference` — not reimplemented in the hook.
- **AC4b**: the only genuinely new logic is **path classification** (crown jewel
  vs task-own vs other) against the TCI-resolved current task. Design must first
  evaluate `CWF::ArtefactHelpers::validate_write_path_allowlist`
  (`ArtefactHelpers.pm:89`, already imported by the merge helper) — the closest
  existing prefix/traversal primitive — but note it **dies** on absolute/`..`
  paths (it *rejects*; the gate must *classify* a canonical target), so it is
  likely the model for a sibling classifier, not a drop-in. Don't silently
  reinvent its traversal defences, and don't assume a literal fit.

### FR5 — Opt-in + gating
- **AC5a**: the gate is active **only** when `sandbox.enabled` is true. Whether it
  rides `sandbox.enabled` directly or gains a dedicated sub-knob (e.g.
  `planning-write-guard`, defaulting such that enabling sandboxing never silently
  bricks planning) is fixed at design.
- **AC5b**: registration is via `cwf-claude-settings-merge` (like R3), gated —
  not registered when off; OFF output unchanged (no-regression).
- **AC5c (observe-only-first option, testable)**: design decides whether to ship
  an **observe-only** mode (log would-block, do not deny) before enforcing, to
  de-risk Risk 1. **If shipped**, a config switch toggles enforce vs observe and
  **both modes are covered by tests** (observe logs + permits; enforce denies).
  If not shipped, the design records why. ("Weighed" alone is not a testable
  outcome.)

### FR6 — Substrate extension + integrity
- **AC6a**: the new hook gets a `script-hashes.json` entry; the widened helper's
  hash is refreshed in the same commit; `cwf-manage validate` is clean.
- **AC6b**: existing event/matcher registration behaviour is preserved
  byte-for-byte (TC-M* / TC-U* regression).
- **AC6c (self-protected target)**: any settings written go only to
  `.claude/settings.json`.

### FR7 — Documentation
- **AC7a**: `.cwf/docs/sandboxing.md` gains a section on the phase-write guard:
  what it protects, the fail-closed posture, the opt-in knob, and — honestly —
  that Edit/Write are **not** sandboxed (this is a permission/hook advisory gate),
  and the `dangerouslyDisableSandbox`/agent-reachability caveats still apply.
- **AC7b**: the doc states the A/B policy actually shipped and the middle-ground
  treatment, so an adopter knows exactly what is blocked during planning.

### User Stories
- **As a** CWF maintainer with sandboxing on, **I want** the agent prevented from
  editing production code/skills/helpers while it is still planning, **so that** a
  planning-phase agent can't quietly mutate the system it is planning against.
- **As a** CWF adopter, **I want** the guard to fail closed on the crown jewels
  but never brick my legitimate planning writes, **so that** safety doesn't cost
  me a working session.

## Non-Functional Requirements
### Performance (NFR1)
- The hook runs per Edit/Write call and TCI shells out to git; per-call overhead
  must be **bounded and measured** (cache within a single invocation; no network).
  **Concrete budget**: a single hook invocation should add no more than ~3× the
  R3 ~15 ms/call baseline (i.e. **≤ ~50 ms/call** as a soft ceiling); the actual
  figure is recorded in testing and a gross regression past it fails.

### Usability (NFR2)
- A blocked write yields an actionable fixed-token message (path-class + phase
  per AC2d), not a cryptic failure; opt-in; the default never bricks a planning
  session.

### Maintainability (NFR3)
- **Precedence ordering** (the genuinely-new NFR3 content): correctness (no
  crown-jewel leak, no silent weakening, trusted task source) **beats** no-brick
  usability, which **beats** extend-don't-fork, if they conflict. (Reuse-TCI /
  extend-don't-fork / path-classification-is-the-only-new-logic are specified
  once, in FR4 — not restated here.)

### Security (NFR4)
- Fail-closed default-deny (AC3a); task identity from a trusted source (AC3b);
  canonical root-correct classification (AC3c); minimal matcher widening (AC1b);
  fixed-enumeration path-class token, no `tool_input`/path interpolation (AC2d);
  write target self-protected (AC6c); no validate-silencing surface (AC3d).
- **FR4(d) env handling**: the hook derives path/phase decisions **only** from
  `tool_input` paths + TCI output — it reads **no** security-influencing
  environment variable for classification. (Named explicitly so the harness env
  is not an unspecified input.)
- This is the feature's one **fail-closed enforcing** path — the opposite posture
  to R3.

### Reliability (NFR5)
- Path classification is deterministic over relative/absolute/`..`/symlink inputs
  (the testable goal is AC3c); the hook never corrupts `.claude/settings.json`.
  The internal-error / ambiguity behaviour is specified once, in AC3a (default-
  deny-crown-jewels, permit-rest) — not re-specified here.

## Constraints
- POSIX, **core-Perl only**; British spelling; no personal names.
- Hash-refresh-same-commit for every hash-tracked edit; new hook registered +
  allowlisted via the merge helper; no `cwf-manage validate`-silencing surface.
- Fixed-token messages; no `tool_input`/file-body interpolation into output.
- `cwf-project.json` is the single source of truth for the toggle/knob.

## Decomposition Check
- [ ] Time >1 week? No.
- [ ] People >2? No.
- [x] Complexity 3+ concerns? Matcher widening + guard + fail-closed policy +
      config — cohesive on one helper + one new hook.
- [x] Risk needing isolation? The fail-closed policy (a-plan Risk 1) — handled by
      the observe-only-first option (AC5c), not a further split.
- [~] Independence? Matcher widening is a prerequisite for the hook; sequenced.

Single task, per a-plan. No new split.

## Acceptance Criteria
- [ ] AC1: matcher regex admits `Edit|Write` minimally + safely; empty/edge
      alternations rejected; rationale restated; TC-M* green (FR1).
- [ ] AC2: PreToolUse `Edit|Write` gate classifies by phase **name**, denies
      crown-jewel writes in planning, permits task-own, passes through in
      implementation-exec; fixed-enumeration-token deny, no path echo (FR2).
- [ ] AC3: default-deny-crown-jewels unless positively resolved to an exec phase
      (covers exit 1/2/3, unknown-step, internal exception); canonical
      root-correct classification, conservative on unresolvable; trusted task
      source; no smoothing (FR3).
- [ ] AC4: reuse TCI; only new logic is path classification, evaluated against
      `validate_write_path_allowlist` first (FR4).
- [ ] AC5: opt-in behind the sandbox toggle/sub-knob; gated registration; OFF
      no-regression; observe-only-first option weighed (FR5).
- [ ] AC6: hook hashed + helper hash refreshed same commit; existing behaviour
      preserved; validate clean; settings.json-only target (FR6).
- [ ] AC7: limitations doc updated with the guard + the A/B policy shipped (FR7).

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
FR1–FR7 satisfied; NFR1 measured in g (crown 36.9 ms / non-crown 25.9 ms, both
under the ~50 ms budget). The central A/B open question (allow-list vs deny-list)
was resolved at design as Option A (crown-jewel deny-list).

## Lessons Learned
Pinning FR2 to classify by phase *name* (not letter) was the requirement that
mattered most in exec — the letter-stripping rule held across the v2.0/v2.1
reassignment concern. The fixed-token requirement (FR4(c)/(e)) made the
prompt-injection surface trivially closed and the security reviews fast.
