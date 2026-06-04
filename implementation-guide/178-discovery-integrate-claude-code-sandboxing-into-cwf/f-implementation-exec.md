# Integrate Claude Code sandboxing into CWF - Implementation Execution
**Task**: 178 (discovery)

## Task Reference
- **Task ID**: internal-178
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/178-integrate-claude-code-sandboxing-into-cwf
- **Template Version**: 2.1

## Goal
Execute the c/d plan: gather cited evidence, fill the mechanism inventory and
feasibility verdict tables, price the substrate gaps, carry forward the weaknesses,
write the recommendation, and seed the backlog. No CWF production code is written.

## Evidence sources (this session)
- **Docs** (fetched this session; `docs.claude.com/en/docs/claude-code/*` 301-redirects
  to `code.claude.com/docs/en/*`):
  - `code.claude.com/docs/en/sandboxing` — sandbox keys, defaults, escape hatch, limits.
  - `code.claude.com/docs/en/settings` — permissions precedence + cross-scope merge.
  - `code.claude.com/docs/en/hooks` — full hook-event list.
- **Substrate** (read first-hand this session):
  - `.cwf/scripts/command-helpers/cwf-claude-settings-merge` — confirmed it writes
    `permissions.allow`, `hooks`, and `env.PERL5OPT` only (`merge_allow`/`merge_hooks`/
    `merge_env`); it does **not** write `sandbox.*` or `permissions.deny`.
    `read_hook_directives` validates the event to `{Stop, SubagentStop}` only
    (`/^(?:Stop|SubagentStop)$/`, line 82) — any other directive falls back to `Stop`.

## Step 1 — Mechanism evidence (FR1)

Key quoted findings (verbatim from `code.claude.com/docs/en/sandboxing` unless noted):

- **Scope — sandbox is Bash-only**: "The sandbox isolates Bash subprocesses." "Built-in
  file tools: Read, Edit, and Write use the permission system directly rather than running
  through the sandbox." → The boundary that governs how CWF writes *planning files* (the
  Edit/Write tools) is the **permission system**, not `sandbox.filesystem.*`.
- **R1 write keys**: "By default, sandboxed commands can only write to the current working
  directory." `sandbox.filesystem.allowWrite` grants Bash-subprocess write outside cwd;
  `Edit` allow/deny rules grant/block the Edit tool. Settings are static per scope — no
  documented per-session/per-phase switch. The only documented *blocking, observable,
  pre-execution* gate keyed on live state is a **PreToolUse** hook: "Before a tool call
  executes. Can block it" via `permissionDecision: "deny"` (hooks doc).
- **R2 read keys**: default read policy "still allows reading credential files such as
  `~/.aws/credentials` and `~/.ssh/`. Add them to `denyRead` to block them." Path prefixes:
  `~/` "becomes `$HOME/...`" (so `~` **is** expanded); `/` is absolute; `./`/no-prefix is
  project-root (project settings) or `~/.claude` (user settings). "the arrays are merged:
  paths from every scope are combined, not replaced." `allowRead` "re-allows reading
  specific paths within a `denyRead` region." `allowManagedReadPathsOnly: true` → "only
  `allowRead` entries from managed settings are honored." Caveat: `denyRead` is sandbox
  (Bash) scope; the **Read tool** is governed separately by `Read(...)` permission deny
  rules — full credential denial needs **both**.
- **R3 violation signal**: the hook-event list contains no event that fires on a sandbox
  violation or unsandboxed fallback. Closest proxies: **PreToolUse** (can observe a call
  carrying the `dangerouslyDisableSandbox` parameter *before* it runs), **PostToolUseFailure**
  ("After a tool call fails" — noisy), **PermissionDenied** ("When a tool call is denied by
  the auto mode classifier" — classifier denials only, not sandbox violations). No structured
  "sandbox violated" event exists.
- **Escape hatch (enforceability)**: "when a command fails because of sandbox restrictions,
  Claude analyzes the failure and may retry the command with the `dangerouslyDisableSandbox`
  parameter" → **agent-reachable**, not operator-only. The retry "goes through the regular
  permission flow and requires your approval" (so it is gated by the permission flow, which
  auto/skip-permissions modes can remove). `"allowUnsandboxedCommands": false` ("Strict
  sandbox mode") → "the `dangerouslyDisableSandbox` parameter is completely ignored."
- **Fail-open**: "if the sandbox cannot start … Claude Code shows a warning and runs commands
  without sandboxing. To make this a hard failure instead, set … `failIfUnavailable` to
  `true`." Default is **fail-open**.
- **Self-protection**: "the sandbox automatically denies write access to Claude Code's
  settings.json files at every scope and to the managed settings directory."

**Transient-failure rule applied**: all three docs fetched successfully (after following the
301 to `code.claude.com`); no verdict rests on a failed fetch.

## Step 2 — Substrate audit (FR3)
Confirmed first-hand this session (see Evidence sources). The two extension gaps:

1. **Settings surface gap** — `cwf-claude-settings-merge` writes `permissions.allow` only.
   `sandbox.*` (filesystem allow/deny, network) and `permissions.deny` are **unmanaged**;
   a feature must add merge logic for them. The helper is hash-tracked, so the edit lands
   its `script-hashes.json` refresh in the **same commit** (`docs/conventions/hash-updates.md`).
2. **Hook-event gap** — `read_hook_directives` accepts `{Stop, SubagentStop}` only.
   R1's and R3's `PreToolUse` (and R3's `PostToolUseFailure`) registration needs the
   allowlist widened — same hash-refresh-same-commit constraint.

Config conventions a new key would follow live in `implementation-guide/cwf-project.json`
(the active config) and `.cwf/templates/cwf-project.json.template`.

## Step 3 — Mechanism inventory

| Req | Mechanism (key / hook event / rule) | Citation (this session) | In `cwf-claude-settings-merge` today? | Gap / extension cost |
| --- | --- | --- | --- | --- |
| R1 | `sandbox.filesystem.allowWrite` (Bash subprocess writes) | sandboxing doc, "Configure sandboxing" | No (`sandbox.*` unmanaged) | Add `sandbox.*` merge to helper (+ hash refresh) |
| R1 | `Edit(...)` allow/deny permission rules (Edit/Write tool) | settings doc permissions example; sandboxing doc "Read, Edit, and Write use the permission system" | Partial — helper writes `permissions.allow`, not `permissions.deny` | Add `permissions.deny` merge (+ hash refresh) |
| R1 | **PreToolUse** hook, `permissionDecision:"deny"`, keyed on current wf step | hooks doc "Before a tool call executes. Can block it" | No (events limited to Stop/SubagentStop) | Widen hook-event allowlist (+ hash refresh) |
| R1 | per-phase static-config switch | none found (settings static per scope; no per-phase key documented) | — | n/a — drives R1 to the hook mechanism |
| R2 | `sandbox.filesystem.denyRead` (+ `allowRead` re-allow) | sandboxing doc "Add them to `denyRead` to block them"; "re-allows … within a `denyRead` region" | No (`sandbox.*` unmanaged) | Add `sandbox.*` merge (+ hash refresh) |
| R2 | `Read(...)` permission deny (Read tool path) | settings doc `"deny": ["Read(./.env)", …]` | No (helper writes `allow` only) | Add `permissions.deny` merge (+ hash refresh) |
| R2 | `allowManagedReadPathsOnly` (managed lockdown) | sandboxing doc "only `allowRead` entries from managed settings are honored" | No | Managed-settings concern; out of CWF project-scope write |
| R3 | **PreToolUse** observing `dangerouslyDisableSandbox` param | sandboxing doc (escape-hatch param) + hooks doc (PreToolUse) | No | Widen hook-event allowlist (+ hash refresh) |
| R3 | **PostToolUseFailure** (post-hoc, noisy) | hooks doc "After a tool call fails" | No | Widen hook-event allowlist (+ hash refresh) |
| R3 | structured "sandbox violated" event | none found | — | n/a — caps R3 at unreliable proxy |

## Step 4 — Feasibility verdicts

| Req | Verdict | Fail-open behaviour | Enforceable vs advisory (escape-hatch) | Key caveats |
| --- | --- | --- | --- | --- |
| **R1** (phase-scoped writes) | **Feasible-with-caveats** (via PreToolUse hook; **Not-feasible** as a static per-phase sandbox switch) | Hook fires regardless of sandbox availability (hooks are not gated by `failIfUnavailable`); but a Bash-subprocess write path still fails open if the sandbox is down | **Advisory** unless `allowUnsandboxedCommands:false` — a misaligned agent can retry sandboxed *Bash* writes via `dangerouslyDisableSandbox`. The PreToolUse hook over the **Edit/Write** tools is not bypassable by that param (those tools never enter the sandbox), so the hook path is the enforceable one | No per-phase static key exists; needs a PreToolUse hook keyed on the wf step inferred from on-disk task files / `task-stack`; needs helper hook-event widening |
| **R2** (credential deny-list) | **Feasible-with-caveats** | `denyRead` (Bash) fails open if sandbox unavailable; `Read(...)` permission deny does **not** depend on the sandbox, so it still applies | **Advisory** for the Bash path (agent-reachable `dangerouslyDisableSandbox`); **enforceable** for the Read-tool path (permission deny, "Explicit deny rules are always respected"). Closing the Bash gap needs `allowUnsandboxedCommands:false` | Needs **both** `denyRead` and `Read(...)` deny to be complete; `~` expands; cross-scope merge is **union** → an adopter narrows a shipped default with `allowRead`, **not** by deleting the entry; needs helper `sandbox.*`+`permissions.deny` management |
| **R3** (issue logging, default-off) | **Feasible-with-caveats — unreliable** | Logging hook is independent of sandbox availability | N/A (observe-only; does not enforce) | **No structured violation event exists** — only PreToolUse (catches `dangerouslyDisableSandbox` retries before they run) + PostToolUseFailure (noisy). Default-OFF switch in `cwf-project.json`. Must not become a silent boundary-disable |

Wiring applied: R1's "per-phase static switch" candidate is *none-found* → that sub-mechanism
is Not-feasible-today, which is why R1 resolves to the hook path. R3's *none-found* structured
event caps it at Feasible-with-caveats-**unreliable**. No mechanism was left Unverifiable
(all three docs were reachable and quoted).

## Step 5 — Weakness carry-forward (FR5)
Documented sandbox weaknesses the feature must account for:
- **Default read leaks credentials** — the reason R2 exists (verbatim above).
- **Non-TLS-inspecting egress proxy** — "does not terminate or perform TLS inspection";
  broad `allowedDomains` enable domain-fronting exfiltration. Bears on any R3 claim that
  logging makes exfil observable — it does not.
- **`excludedCommands` has no managed-only lockdown** — "a developer can always append
  entries that run additional commands outside the sandbox." An R1/R2 boundary can be
  widened here out-of-band.
- **Fail-open** unless `failIfUnavailable:true` — on an unsupported platform (native
  Windows; WSL1) or missing `bubblewrap`/`socat`, sandbox protections silently vanish.
- **Agent-reachable escape hatch** — `dangerouslyDisableSandbox` is model-initiated; R1/R2
  Bash-path boundaries are advisory against a misaligned agent unless `allowUnsandboxedCommands:false`.
- **Subprocess env inheritance** — sandboxed Bash inherits parent env incl. credentials
  unless `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` is set (env vars are orthogonal to `denyRead`).

**No-smoothing**: R3 logging must never be wired to silence or disable a boundary
(`feedback_surface_security_dont_smooth`); it observes, it does not relax.

## Step 6 — Recommendation & decomposition (FR6)

**Recommendation: BUILD, staged — but ship the honest enforcement-ownership framing with it.**
CWF *provides/advises* sandbox + permission config and *observes* via hooks; Claude Code and
the OS enforce it; the operator can widen or disable it (`excludedCommands`,
`dangerouslyDisableSandbox`, removing `failIfUnavailable`). CWF cannot *guarantee* any
boundary — every user-facing string must say "advises", not "enforces".

**Shared prerequisite (build first):** extend `cwf-claude-settings-merge` to (a) manage
`sandbox.*` and `permissions.deny`, and (b) widen the hook-event allowlist to `PreToolUse`
(and `PostToolUseFailure` for R3) — each with its `script-hashes.json` refresh in the same
commit. Without this, none of R1/R2/R3 can be installed through the supported path.

**Staging order (by verdict strength):**
1. **R2 — credential deny-list** (cleanest; closes a documented credential leak). Ship
   paired `denyRead` + `Read(...)` deny with `~/.ssh`, `~/.aws` defaults, editable list in
   `cwf-project.json`. Recommend pairing with `allowUnsandboxedCommands:false` guidance to
   make the Bash path enforceable.
2. **R1 — phase-scoped writes** via a PreToolUse hook keyed on the wf step (from on-disk
   task files / `task-stack`); gates the Edit/Write tools to the task's planning files
   during phases a–e. Gated on the hook-event widening above.
3. **R3 — issue logging**, default-OFF switch; logs PreToolUse `dangerouslyDisableSandbox`
   retries + PostToolUseFailure. Ship with the "unreliable / proxy-signal" caveat documented.

**Decomposition decision:** the eventual feature **should be decomposed** at `/cwf-new-task`
time into the prerequisite + R2 + R1 + R3 (four units; R1/R2/R3 are independent per the
verdicts). Seeded as **one** parent BACKLOG feature entry carrying that decomposition, to
keep the backlog uncluttered while preserving the staging plan (the split happens at task
creation, not as four separate backlog items).

**Don't-build (stated, not omitted):** do **not** attempt R1 as a static per-phase
`allowWrite` switch (no such mechanism), and do **not** present R3 as reliable violation
detection (no structured event). Managed-settings-only lockdowns
(`allowManagedReadPathsOnly`, `failIfUnavailable`) are an operator/MDM concern, not
something CWF writes into a project's `.claude/settings.json`.

## Step 7 — Backlog seed
See `## Backlog Seed Result` below (helper-mediated; exit code recorded).

## Deferral Check
- [x] All steps from d-implementation-plan.md executed (Steps 1–7)
- [x] All success criteria from a-task-plan.md met (SC1–SC5: cited verdicts; R1 phase
      mechanism = PreToolUse hook, no static switch; R2 deny-list shape; R3 signal +
      default-off; recommendation + decomposition)
- [x] All requirements from b-requirements-plan.md addressed (FR1–FR6)
- [x] All design guidance in c-design-plan.md followed (evidence hierarchy, failure-wired
      verdicts, substrate gaps priced, enforceable-vs-advisory, helper-mediated seed)
- [x] No planned work deferred without user approval

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
- The single most consequential fact: **the sandbox is Bash-only**. It re-routes R1/R2 away
  from "just set `sandbox.filesystem.*`" toward the permission system (`Edit`/`Read` rules)
  for the file tools, with the sandbox covering only the Bash-subprocess path. Any feature
  that set only `sandbox.*` would leave the Read/Edit tools unguarded.
- No structured sandbox-violation hook event exists; R3 is inherently a proxy signal.

## Backlog Seed Result
- Pre-add grep (`list --all-items | grep -i sandbox`): no pre-existing entry.
- `backlog-manager add --title='CWF-managed Claude Code sandboxing config (R2 credential
  deny-list, R1 phase-scoped writes, R3 violation logging)' --task-type=feature
  --priority=Medium --body-file=<scratch>` → exit 0.
- Post-add count (`list --all-items | grep -c "CWF-managed Claude Code sandboxing config"`)
  = **1** (single live entry, no duplicate).
- `backlog-manager validate --all` → exit 0 (format OK).

## Security Review

**State**: no findings

The changeset comprises six files: BACKLOG.md plus the a–e workflow-step files. The f-implementation-exec.md (the findings file referenced throughout) is not in this implementation-phase changeset — it is presumably produced in the exec phase that this very diff plans. That is consistent with the caller's note that this is the implementation phase and "no executable code is added."

Let me reason through the threat categories.

## Security review — Task 178 implementation-phase changeset

I reviewed the full diff (851 lines, six files: `BACKLOG.md` and the a–e workflow-step Markdown files under `implementation-guide/178-discovery-integrate-claude-code-sandboxing-into-cwf/`). All additions are prose Markdown — planning, requirements, design, implementation-plan, and testing-plan documents for a discovery task, plus one BACKLOG entry. No executable code, no scripts, no permission/hash/settings files are touched in this changeset.

I checked each threat category against the CWF surface.

**(a) Privilege / permission escalation.** Nothing in the diff modifies file permissions, `script-hashes.json`, `.claude/settings.json`, `cwf-project.json`, or any helper/hook. The documents repeatedly and correctly state that any hashed-file edit (e.g. a future `cwf-claude-settings-merge` change) MUST land its `script-hashes.json` refresh in the same commit (a-task-plan L128, BACKLOG L17, c-design-plan L518–522, d L631–633). No escalation surface is introduced.

**(b) Integrity-check evasion / "smoothing".** This is the category most relevant to the subject matter, and the documents handle it correctly. The "surface, never smooth" principle is invoked repeatedly and applied in the right direction: R3 logging "must never silence or disable a boundary" (BACKLOG L22), the don't-build list explicitly rejects R3-as-silent-disable (b L280, c L528–529, d L659), and the design forbids "any surface that silences `cwf-manage validate`" (BACKLOG L17, c L520–522). The discovery does not itself propose, build, or recommend any integrity-bypass tooling. This is aligned with `feedback_surface_security_dont_smooth.md`.

**(c) Destructive or irreversible operations.** The only durable mutation outside the task's own wf files is the helper-mediated BACKLOG seed, and that entry is present in this diff (BACKLOG L10–26). The documents mandate helper-mediated, list-form/opaque-arg, `--body-file` backlog writes with no heredocs (d L667–688, e L820–821), consistent with `feedback_no_heredocs`. No `rm`, no `git worktree` removal, no `discard_changes`. The diff is additive (six new/appended files).

**(d) Sandbox / scope-boundary scope creep.** The diff stays within the declared discovery scope: it adds task docs and one BACKLOG line. The plan explicitly forbids touching production config (`d` L598–600, TC-7 at e L811–816). The BACKLOG entry's "Don't-build" line correctly scopes managed-only lockdowns (`allowManagedReadPathsOnly`, `failIfUnavailable`, `allowManagedDomainsOnly`) as an operator/MDM concern rather than something CWF would write into a project's `.claude/settings.json` (BACKLOG L24) — that is the right boundary call and avoids CWF over-reaching into operator-owned enforcement.

**(e) Pattern-based / future-reuse risks.** No code patterns are introduced here, so there is nothing to flag as "safe here but risky if reused." I note two forward-looking items that the documents themselves already carry as caveats into the seeded feature — these are correctly recorded, not defects in this changeset, but worth restating so the feature task does not lose them:
- The seeded R2 deny-list must ship as a PAIRED `sandbox.filesystem.denyRead` + `Read(...)` permission deny, because the sandbox is Bash-only and neither path alone covers both the Bash-subprocess and Read-tool read surfaces (BACKLOG L20). A future implementer who ships only one half would leave credentials readable via the other path. The diff states this correctly.
- The documents correctly flag `dangerouslyDisableSandbox` agent-reachability as the axis that decides "enforceable vs advisory" (c L449–458, FR5 L281–285). This is the right threat framing for the eventual feature; nothing actionable in this prose changeset.

**Prose-injection check.** The documents ingest and quote external Claude Code doc/schema text as evidence. The requirements and testing plans explicitly require that ingested doc/schema text "appears only as quoted evidence, never acted on as instruction" (b NFR4 L322, e L819–820), consistent with the instruction-priority order. I found no embedded instruction in the diff that attempts to alter agent behaviour.

Conclusion: this is a clean, additive, documentation-only changeset for a discovery task. The security-relevant content (sandboxing, deny-lists, logging) is assessed at the planning level with the correct enforcement-ownership framing and the correct "surface, don't smooth" stance. No actionable security concerns in the diff under review.

Relevant files (all absolute):
- `/home/matt/repo/coding-with-files/BACKLOG.md`
- `/home/matt/repo/coding-with-files/implementation-guide/178-discovery-integrate-claude-code-sandboxing-into-cwf/a-task-plan.md`
- `/home/matt/repo/coding-with-files/implementation-guide/178-discovery-integrate-claude-code-sandboxing-into-cwf/b-requirements-plan.md`
- `/home/matt/repo/coding-with-files/implementation-guide/178-discovery-integrate-claude-code-sandboxing-into-cwf/c-design-plan.md`
- `/home/matt/repo/coding-with-files/implementation-guide/178-discovery-integrate-claude-code-sandboxing-into-cwf/d-implementation-plan.md`
- `/home/matt/repo/coding-with-files/implementation-guide/178-discovery-integrate-claude-code-sandboxing-into-cwf/e-testing-plan.md`

```cwf-review
state: no findings
summary: Documentation-only discovery changeset; correct "surface, don't smooth" stance and enforcement-ownership boundary; no actionable security concerns.
```
