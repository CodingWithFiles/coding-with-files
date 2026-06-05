# CWF-managed Claude Code sandboxing

CWF can generate Claude Code sandbox/permission config from a single block in
`implementation-guide/cwf-project.json`. It is **off by default**.

## What it is — and is not

**CWF advises; the OS enforces; the operator overrides.** CWF never sandboxes
anything itself — it writes config into `.claude/settings.json` that *Claude
Code and the operating system* enforce, and that the operator can widen or
switch off. Read every guarantee below in that light: this is advisory config,
not an enforced boundary CWF stands behind.

## Configuration (`cwf-project.json`)

```json
"sandbox": {
  "enabled": false,
  "fail-if-unavailable": true,
  "credential-deny-list": ["~/.ssh", "~/.aws"],
  "violation-logging": false
}
```

`cwf-project.json` is the **single source of truth**. The generated
`.claude/settings.json` region is CWF-owned and rewritten on every
`cwf-claude-settings-merge` run — do not hand-edit it. Put your own overrides in
`.claude/settings.local.json` (higher precedence, never touched by CWF) or in
the knobs above.

- **`enabled`** — master toggle. Off (or absent) ⇒ CWF writes **zero** sandbox /
  `permissions.deny` keys. Toggling off later removes everything CWF wrote.
- **`fail-if-unavailable`** — written to `sandbox.failIfUnavailable`
  authoritatively (the knob value always wins). `true` (default) means Claude
  Code refuses to start when the sandbox cannot initialise — fail-closed.
- **`credential-deny-list`** — paths denied to the agent. Each entry compiles to
  **both** a `sandbox.filesystem.denyRead` entry (the Bash-subprocess path) and
  `Read(<path>)` + `Read(<path>/**)` permission denials (the Read-tool path).
- **`violation-logging`** — opt-in, default off. See *Violation logging* below.

To **narrow** a shipped default, add an `allowRead` entry (or use
`settings.local.json`) — do **not** delete the deny line, as the next merge
re-adds it.

## Limitations (read before relying on this)

- **The sandbox is Bash-only.** It constrains commands run via the Bash tool.
  The Read / Edit / Write tools do **not** go through the sandbox — that is why
  the credential deny-list is *paired*: `denyRead` for Bash, `Read(...)` denials
  for the Read tool. Neither half alone closes the boundary.
- **The escape hatch is agent-reachable.** A Bash call may carry
  `dangerouslyDisableSandbox`, which bypasses the sandbox. It is advisory unless
  the operator also sets `permissions.allowUnsandboxedCommands: false`. CWF does
  not set that for you.
- **There is no reliable sandbox-violation event.** Claude Code exposes no
  structured "a sandbox rule was hit" signal, so violation logging (below) is a
  best-effort proxy, **not** an audit trail.
- **Fail-closed only while `fail-if-unavailable` stays `true`.** Set it to
  `false` and an unavailable sandbox fails *open* — commands run unsandboxed.
- **`denyRead` does not cover credentials already in the environment.** A secret
  exported as an env var (e.g. `AWS_SECRET_ACCESS_KEY`) is inherited by Bash
  subprocesses regardless of any path deny-list. To strip those, use Claude
  Code's `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` — it is orthogonal to this deny-list
  and CWF does not manage it.
- **Platform.** The Linux backend needs `bubblewrap` (`bwrap`) and `socat`; CWF
  warns (never blocks) if they are missing while sandboxing is on. macOS uses
  Seatbelt and needs neither. Native Windows / WSL1 have no sandbox — with
  `fail-if-unavailable: true` Claude Code will refuse to start there.

## Violation logging

With `violation-logging: true`, CWF registers a PreToolUse hook
(`pretooluse-sandbox-logging`) that observes Bash calls carrying
`dangerouslyDisableSandbox` and appends a minimal record (timestamp, tool name,
a presence flag — **never the raw command**) to `.cwf/sandbox-violations.log`
(gitignored). It is **observe-only**: it never blocks, relaxes, or silences a
boundary, and a failed log write is swallowed. The log is operator-facing — do
not feed it back into an LLM; treat its contents as untrusted.
