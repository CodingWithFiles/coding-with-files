# Bash tool-check rules

The Bash tool-check framework intercepts `Bash` tool calls via a fail-open
PreToolUse hook (`pretooluse-bash-tool-check`) and, on the first matching rule,
**denies** the call with that rule's guidance — nudging the agent away from
commands that trip Claude Code's own permission prompts (needlessly complex
shell, harness-sanctioned tools, …). It ships **inert**: with no rule files the
hook is a strict no-op. CWF supplies the mechanism, not the rules — the
offending-command set shifts per model and per Claude Code version, so any rules
are yours to supply.

## Layers and precedence

Rules merge from three layers, low → high precedence:

| Layer | Path | Travels via `git clone`? | `regex` | `perl` |
|-------|------|--------------------------|---------|--------|
| user-global | `~/.cwf/tool-check/bash/settings.json` | no | yes | yes |
| project checked-in | `{repo}/.cwf/tool-check/bash/settings.json` | **yes** | yes | **ignored** |
| project-local | `{repo}/.cwf/tool-check/bash/settings.local.json` (gitignored) | no | yes | yes |

The project-local layer is **gitignored** (`.cwf/tool-check/*/settings.local.json`,
shipped in the install manifest). This is a security control, not tidiness: the
project-local layer honours `perl` rules, so keeping it out of `git` is what stops
a committed project-local `perl` rule from executing on every cloner — the same
clone-untrusted-execution hazard the checked-in `perl` drop guards against.

`perl` rules execute arbitrary code, so they are honoured only from the two
author-owned layers that never travel via `git clone`. A `perl` rule in the
checked-in layer is **dropped before it is ever compiled** (a cloned repo cannot
run code on a collaborator's machine). `regex` rules are safe in every layer:
the engine never enables `re 'eval'`, so an embedded `(?{...})`/`(??{...})` code
block never executes (it dies → caught → treated as no-match).

## Enabling: the `active` kill-switch and seeding

The framework ships inert. Two things turn it on:

- **Rules** in at least one layer (there is nothing to match otherwise).
- The global **`active`** kill-switch resolving to true (its default).

`/cwf-config tool-check seed` writes a small regex-only starter set into the
**checked-in** layer (and `/cwf-init` offers the same on first setup, default
decline). `/cwf-config tool-check off` / `on` flip the switch via the
**project-local** layer — an ephemeral, gitignored, per-checkout toggle that
never dirties tracked state. All three are the one helper
(`.cwf/scripts/command-helpers/tool-check-seed`); do not hand-edit the files.

### The `active` flag

A settings file may carry an optional top-level `active`:

```json
{ "active": false, "rules": [ ... ] }
```

- `active` is resolved across the **trusted** layers only —
  **project-local > user-global**, first definer wins, default **true**.
- Only a JSON **boolean** counts. A string `"false"`, `0`, `null`, or an array
  is ignored and falls through (so a hand-typed `"active":"false"` — which is
  Perl-truthy — can never leave the switch stuck on).
- A **checked-in** `active` is **ignored** for the switch — mirroring the
  checked-in `perl` drop, a clone-travelling `active:false` must not silence a
  downstream user's own user-global rules. (Seeded checked-in rules are active
  anyway via the default.)
- Default true means a pre-existing settings file (rules, no `active` key) keeps
  working unchanged: this is a kill-switch, not an enable gate.

Degradation: if a project-local layer that held `active:false` later becomes
unreadable (symlink, corrupt JSON), it is skipped and the switch falls through to
**true** — the hook comes back *on*. Consistent with the deny-is-safe posture (a
broken kill-switch fails toward *more* nudging, never toward capability).
`--check` surfaces the per-layer `active` values; re-running `off` restores it.

## Rule schema

A settings file is `{"active": <bool, optional>, "rules": [ ... ]}`. Each rule is
keyed by a stable `id`:

```json
{
  "rules": [
    {
      "id": "no-sed-line-range",
      "regex": "(?:^|[|;&]\\s*)sed\\s+-n",
      "guidance": "Use Read with offset/limit, not `sed -n 'X,Yp'`."
    },
    {
      "id": "complex-pipeline",
      "perl": "sub { my ($cmd, $ctx) = @_; return $cmd =~ tr/|// > 3 }",
      "guidance": "Long pipelines trip permission prompts; write a scratch script."
    },
    { "id": "no-sed-line-range", "enabled": false }
  ]
}
```

- An active rule has exactly one matcher — `regex` (PCRE) **or** `perl` — plus a
  required `guidance` string. The `guidance` is returned to the agent verbatim;
  it never reflects the command.
- `regex` is **PCRE only** (Perl's native engine) — no POSIX BRE/ERE, no glob.
  It matches the raw command string (data-only).
- `perl` is a `sub { ($cmd, $ctx) = @_; ... }` string returning truthy on match.
  `$ctx` is `{ cwd => <string> }` (the call's working directory). Code runs under
  `use strict`/`use warnings`; a rule that fails to compile or dies is dropped
  and the call falls through (fail-open).
- `{ "id": ..., "enabled": false }` disables a rule defined in a
  lower-precedence layer (the override/disable mechanism). Unknown keys are
  ignored (forward-compatible).

### Merge semantics

- Layers are flattened low → high. A new `id` is appended (keeping its
  first-seen evaluation position); a repeated `id` **replaces the existing
  entry's fields in place** (position preserved, so an override never reorders
  evaluation); `enabled:false` removes the `id`.
- A duplicate `id` within one layer resolves last-in-document-order; a
  disable/override of an `id` present in no layer is a silent no-op.
- Evaluation is **first-match-wins** over the final ordered list.

## Repeat bypass

If the agent retries the **exact same command** immediately after a deny, the
hook does **not** block it the second time — it falls through to Claude Code's
native permission check. This is the escape hatch for a wrongly-flagged command.
Any intervening different command resets the streak. State is per session, keyed
only by a hash of the last denied command, under a repo-namespaced scratch dir
(see `.cwf/docs/conventions/tmp-paths.md`); a missing/odd state file simply means
"not a repeat" (never a stale bypass).

## Inspecting your rules — `--check`

```
.cwf/scripts/hooks/pretooluse-bash-tool-check --check
```

Reports per-layer parse status, any dropped checked-in `perl` rules, ids defined
in more than one layer, and the effective ordered rule list. Exit 0 when every
layer parses; non-zero if a layer fails to parse (scriptable). This output is for
a human terminal — do not pipe it back into agent context.

## Safety posture

The hook is **fail-open**: any error, malformed input, unreadable/odd config, or
pathological pattern yields allow (empty stdout, exit 0). A tool-check must never
brick Bash. Matching runs under a wall-clock bound; the registration
`timeout => 5` is the guaranteed backstop. A command larger than 64 KB is not
matched at all (it is not truncated — refusing to match over-cap avoids a
truncate-to-evade vector).
