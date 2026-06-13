# Bash tool-check framework - Requirements
**Task**: 201 (feature)

## Task Reference
- **Task ID**: internal-201
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/201-bash-tool-check-framework
- **Template Version**: 2.1

## Goal
Define functional and non-functional specifications for a configurable,
fail-open PreToolUse framework that matches `Bash` tool calls against
user-owned PCRE/Perl rules and echoes avoidance guidance back to the agent.

## Functional Requirements

### Core Features

- **FR1: PreToolUse `Bash` interception + ordered evaluation + guidance output**
  - A PreToolUse hook matched to the `Bash` tool MUST read the tool-call JSON,
    extract the command string, and evaluate the merged rule set in order.
  - On the FIRST matching rule it MUST emit a Claude Code PreToolUse `deny`
    decision whose `permissionDecisionReason` is that rule's guidance text, so
    the agent receives an actionable instruction on how to avoid the command.
  - On no match it MUST emit nothing (empty stdout, exit 0) — the call proceeds
    to Claude Code's normal handling.
  - Registration uses the existing `cwf-hook-event: PreToolUse` /
    `cwf-hook-matcher: Bash` directive convention consumed by
    `cwf-claude-settings-merge`. The new hook COEXISTS with the existing
    `pretooluse-sandbox-logging` hook on the same `PreToolUse`/`Bash`
    registration; both must remain independent (one observes, one guards) and
    neither depends on the other's outcome.
  - Acceptance: a command matching a rule is denied with that rule's message
    verbatim; a non-matching command produces empty stdout and exit 0; the hook
    is registered only via the directive convention.

- **FR2: Two rule kinds — PCRE regex and Perl function**
  - A rule MUST support at least: a stable `id`, a `guidance` message, and a
    matcher that is EITHER a `regex` (PCRE — Perl's native engine, applied with
    `=~`) OR a named `perl` function (for cases a single pattern cannot express).
  - Regex matching is PCRE-only: no POSIX BRE/ERE, no glob, no second flavour.
  - A Perl-function rule receives the command string (and MAY receive limited
    context such as the cwd) and returns truthy to match.
  - A Perl-function rule is arbitrary code: it can not only die but also HANG
    (infinite loop / blocking syscall). It MUST therefore execute under the same
    wall-clock guard as regex matching (NFR1), so a hanging rule fails open
    rather than bricking `Bash`.
  - Acceptance: a regex rule and a Perl-function rule each independently fire on
    a crafted command and return their guidance; an invalid regex, a
    Perl-function that dies, AND a Perl-function that hangs past the time bound
    are each skipped (do not block — see FR5/NFR1), not fatal.

- **FR3: Three-layer config sourcing with defined precedence**
  - Rules MUST be sourced and merged from three layers:
    1. user-global `~/.cwf/tool-check/bash/settings.json`
    2. project checked-in `{repo-root}/.cwf/tool-check/bash/settings.json`
    3. project-local `{repo-root}/.cwf/tool-check/bash/settings.local.json`
  - `~/.cwf/` is the established CWF user-global config root (already used by
    `cwf-config` for `autoload.yaml`/`utils`/`templates`, with a documented
    "project `.cwf/` > global `~/.cwf/` > defaults" precedence). This FR extends
    that existing convention to a `tool-check/bash/` subtree — it does NOT invent
    a new user-global location.
  - The merge MUST define: (i) evaluation order across layers, (ii) how a
    later layer can override or disable an earlier layer's rule (by `id`), and
    (iii) what happens when a layer is absent or empty (treated as no rules).
  - The merge MUST also define deterministic resolution for the well-formed-JSON
    error cases that the malformed-layer guard (NFR5) does NOT catch: two rules
    sharing an `id` within one layer, and an override/disable referencing an
    `id` that exists in no layer. Both are realistic hand-authoring mistakes
    (NFR2) and must resolve predictably, not by accident.
  - The directory segment is namespaced by tool (`tool-check/bash/`) so future
    tools (e.g. another interpreted tool) can add sibling rule sets without
    schema change.
  - Acceptance: with rules present in all three layers, evaluation order matches
    the documented precedence; a local-layer override by `id` suppresses/replaces
    the matching lower-layer rule; absent layers are silently ignored; a
    duplicate `id` within a layer and an override of an absent `id` each resolve
    per the documented rule (no crash, no nondeterministic pick).

- **FR4: Exact-repeat bypass**
  - If the agent issues the EXACT same command immediately after that command
    was guidance-denied (twice in a row), the hook MUST NOT deny it again — it
    emits nothing and lets the call fall through to Claude Code's built-in
    permission check (which blocks until the user responds).
  - "Same command twice in a row" is keyed per session and compares the
    command string against the immediately preceding denied command.
  - **Session-key source MUST be confirmed against the PreToolUse contract.**
    The only documented session carrier in this repo is `session_id` on the
    Stop-hook stdin; whether PreToolUse stdin exposes it is NOT yet established
    (the two existing PreToolUse hooks never read it). The design MUST verify the
    field exists on the PreToolUse payload; if it does not, FR4 degrades to a
    safe defined fallback (e.g. no session key ⇒ treat every call as "not a
    repeat", i.e. guidance shows once and the second identical call is still
    guided — never a hang or hard block).
  - **Repeat-state store safety**: the store is read-then-written on every Bash
    call and is new attack/contention surface. The design MUST: (i) derive its
    path from a trusted source only — any session identifier composed into the
    path MUST be validated/sanitised (no `..`, no path separators) per FR7(d);
    (ii) honour the on-disk safety convention for its location — `/tmp` use
    follows `.cwf/docs/conventions/tmp-paths.md` (namespaced dir, `mkdir -m 0700`
    first-use guard against symlink/TOCTOU), otherwise `$HOME`-anchored at 0600;
    (iii) isolate concurrent sessions so parallel/batched Bash calls cannot
    clobber each other's "previous command" (no single global state file).
  - A missing/unreadable/corrupt repeat-state store MUST be treated as "not a
    repeat" (fail toward showing guidance, never toward a hang or hard block).
  - Acceptance: command X denied once; identical X issued again → empty stdout,
    exit 0; a different command Y in between resets the repeat state so a
    subsequent X is denied again; the session-key source (or its documented
    fallback) is verified against the PreToolUse contract; the state path rejects
    a session id containing `..`/separators.

- **FR5: Fail-open safety + opt-in / zero-cost-when-absent**
  - ANY error — malformed config in any layer, a config file that exists but is
    unreadable or is an irregular file (symlink/permission-denied), invalid
    regex, dying OR hanging Perl function, unreadable state, internal exception,
    or a pattern/function that exceeds the time bound (see NFR1) — MUST result in
    the call being ALLOWED (empty stdout, exit 0). A tool-check MUST never brick
    `Bash`.
  - When no rule files exist in any layer, the framework is a no-op: behaviour
    is identical to not having the hook installed.
  - Acceptance: each failure mode (bad JSON, bad regex, dying function, missing
    state file, simulated timeout) is exercised and yields empty stdout/exit 0;
    with no config files present the hook denies nothing.

- **FR6: Install + upgrade integration (via the existing gitignore artefact)**
  - The `.cwf/tool-check/*/settings.local.json` entry MUST be added to the
    project `.gitignore` by EXTENDING the existing `gitignore-entries` artefact
    in `cwf-apply-artefacts` (`strategy => line-additive`) — NOT by new gitignore
    logic in `install.bash`. That artefact already runs at fresh install (via
    `cwf-init`) and at upgrade (via `cwf-manage update`), and its `line-additive`
    strategy already guarantees the idempotent fresh-install-and-upgrade
    behaviour required here (it manages sibling entries like `.cwf/task-stack`).
  - The hook ships in the integrity manifest like other CWF hooks; its
    registration in merged settings follows the same opt-in posture as existing
    CWF hooks (no behaviour change for projects that add no rules).
  - Acceptance: the new pattern is added to the `gitignore-entries` artefact;
    fresh install produces the `.gitignore` entry; upgrade on a project lacking
    it adds it; upgrade on a project already having it makes no duplicate;
    `cwf-manage validate` passes with the new hook present.

- **FR7: Security model — trust boundaries + threat-model mapping**
  - Because Perl-function rules and config-supplied regexes EXECUTE inside the
    hook, the design MUST state the trust posture per layer and address the
    canonical FR4(a–e) categories from `.cwf/docs/skills/security-review.md`:
    - **(a) Bash injection / unsafe command construction**: the hook only READS
      the command string for matching; it MUST NOT itself shell out with any
      part of `tool_input` interpolated.
    - **(b) Untrusted input to Perl / git output**: the command string from
      `tool_input` is untrusted data; it MUST be used only as a match subject,
      never `eval`-as-code and never interpolated into a shell.
    - **(c) Prompt injection via reflected strings**: guidance text returned to
      the agent MUST be rule-authored only; the hook MUST NOT reflect the
      matched command (or any `tool_input` field) back into the deny reason.
    - **(d) Environment / path handling**: layer file paths are derived from
      `$HOME` and the repo root, not from `tool_input`; no `tool_input`-derived
      path reaches the filesystem.
    - **(e) Pattern-based risk**: the genuinely new exposure is arbitrary Perl
      from config. A CLONED repo's checked-in project rules execute on the next
      developer's machine (supply-chain surface), whereas user-global and
      `settings.local.json` are author-trusted. The design MUST state how this
      is bounded (e.g. trust posture, what executes from which layer, and
      whether Perl-function rules from the checked-in layer require explicit
      opt-in).
  - Acceptance: the design phase names, for each of (a)–(e), how this framework
    avoids or bounds the threat; the arbitrary-Perl supply-chain risk has an
    explicit, stated disposition (not left implicit).

### User Stories
- **As** a CWF user **I want** to declare a rule that catches a command shape
  which trips permission prompts (e.g. `sed -n` for line ranges) **so that** the
  agent is told the better approach instead of stalling on a prompt.
- **As** a CWF user on a model/Claude-Code version with a different sanctioned-tool
  set **I want** to maintain my own rule list **so that** CWF adapts without a
  CWF release.
- **As** a CWF maintainer **I want** the same command, if I really mean it, to go
  through on the second identical attempt **so that** a wrong rule never hard-blocks
  me — it defers to the native permission prompt.
- **As** a team **I want** shared rules checked in and personal rules local +
  gitignored **so that** conventions are shared without forcing everyone's tweaks.

## Non-Functional Requirements

### Performance (NFR1)
- The hook runs on EVERY `Bash` call, so it MUST be cheap: core-Perl only, no
  heavy startup, config parsed once per invocation.
- Rule evaluation — BOTH regex matching and Perl-function execution — MUST be
  bounded by a wall-clock guard so a pathological pattern (ReDoS) or a hanging
  function cannot stall `Bash`; on timeout the hook fails open.
- The guard MUST be DEMONSTRATED to interrupt a known-pathological case. An
  in-process `alarm`/`SIGALRM` may not pre-empt a catastrophic backtrack mid-match
  on all Perl builds (the engine can run to completion inside one opcode before
  the signal is delivered); the design MUST confirm the chosen mechanism actually
  fires mid-match, and adopt a fork/`SIGKILL` fallback if in-process `alarm`
  cannot pre-empt. (No existing `alarm` precedent in `.cwf/` to inherit.)
- Target: negligible added latency for the common (few-rules) case.

### Usability (NFR2)
- Rule files are plain JSON, authored by hand; the schema MUST be small and
  documented with at least one worked regex example and one Perl-function example.
- Guidance messages are the framework's UX: they MUST read as actionable
  instructions ("use Read with offset/limit, not `sed -n`"), not bare refusals.
- Layer precedence and the override-by-`id` mechanism MUST be documented in one
  place.

### Maintainability (NFR3)
- Match/merge POLICY MUST be a pure, unit-testable Perl lib (no git, no I/O),
  separated from the thin I/O wrapper — mirroring `CWF::PlanningGuard` /
  `CWF::Common`.
- Core Perl modules only (`JSON::PP`, `POSIX`, etc.); `use utf8;` per repo rules.

### Security (NFR4)
- Security posture is specified in FR7 (threat-model mapping) and FR5 (fail-open
  as a denial-of-tool defence). One point bears repeating as a hard invariant:
  fail-open is security-relevant — the hook must never become a way to block the
  agent.

### Reliability (NFR5)
- A malformed, unreadable, or partially-invalid layer MUST degrade to "that
  layer contributes no rules" — PER LAYER, never aborting evaluation of the
  other layers.
- Repeat-state corruption/contention MUST degrade to "not a repeat", never to a
  hang or a hard block, including under concurrent/batched Bash calls.

## Constraints
- Perl core-only; `use utf8;`; PCRE-only regex (user-confirmed).
- Output MUST conform to the Claude Code PreToolUse JSON contract.
- Reuse existing infrastructure: `cwf-claude-settings-merge` registration, the
  integrity manifest, and the `gitignore-entries` artefact in
  `cwf-apply-artefacts` for `.gitignore` management (NOT `install.bash`).
- User-global location is `~/.cwf/` (the established CWF user-global root used by
  `cwf-config`; note it is `~/.cwf/`, NOT `~/.claude/`).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [x] **Complexity**: 3+ distinct concerns (engine, config/merge, install).
- [ ] **Risk**: high-risk (arbitrary Perl) — handled in design, not a separate
      workstream.
- [x] **Independence**: parts separable.

**Assessment**: unchanged from planning — tightly coupled, proceed as one task.

## Acceptance Criteria
- [ ] AC1: A rule (regex and Perl-function each) denies a matching command with
      its verbatim guidance; non-matching commands pass (empty stdout/exit 0).
- [ ] AC2: Three-layer sourcing merges with documented precedence and supports
      override/disable-by-`id`; absent layers ignored; duplicate-`id`-within-layer
      and override-of-absent-`id` resolve deterministically.
- [ ] AC3: Exact-repeat of a just-denied command is not re-denied; an
      intervening different command resets the state; session-key source (or its
      fallback) verified against the PreToolUse contract; state path rejects a
      session id with `..`/separators.
- [ ] AC4: Every failure mode (bad JSON, unreadable/symlinked config file, bad
      regex, dying function, hanging function/timeout, missing/corrupt state)
      fails open; the timeout guard is demonstrated to interrupt a pathological
      pattern; no config files ⇒ no-op.
- [ ] AC5: Fresh install and upgrade both add the `settings.local.json`
      `.gitignore` entry idempotently; `cwf-manage validate` passes.
- [ ] AC6: Design names, per FR4(a)–(e), how each threat is avoided/bounded,
      including an explicit disposition for arbitrary Perl from a checked-in layer.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All functional and non-functional requirements were implemented and verified by
TC-1…TC-16. The PCRE-only constraint and the fail-open posture held through to test.

## Lessons Learned
Two defence-in-depth controls (`--check`, the 64 KB cap) surfaced only at plan-review
rather than here. For security-sensitive features, the threat-model/requirements phase is
the right place to enumerate input caps and diagnostics, not later.
