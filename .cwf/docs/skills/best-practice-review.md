# Best-Practice Review

This doc owns the best-practice reviewer's doc-list discipline, the agent prompt
templates, the config-format reference, and the limitations. It parallels
`.cwf/docs/skills/security-review.md` (which owns the FR4 threat model) — both
reviewer surfaces reuse the same deterministic-helper + reviewer-subagent +
classifier split.

## What it does

A user curates **best-practice documentation** (local files or directories)
tagged by applicability (e.g. `golang`, `postgres`, `laravel`). For a given
task, the deterministic helper
`.cwf/scripts/command-helpers/best-practice-resolve` selects the entries whose
tags apply to the task and writes the list of matched doc paths; a reviewer
subagent then **Reads those docs directly** and checks the plan (planning
phase) or the changeset (exec phase) against them. Findings are **advisory** —
they never gate or block the workflow.

## The resolve helper

```
.cwf/scripts/command-helpers/best-practice-resolve --task-num=NUM --phase=PHASE
```

`PHASE` is one of `plan`, `implementation-exec`, `testing-exec` (it discriminates
the output filename so a planning run and the two exec runs for one task never
clobber each other). The helper is **agent-invoked**: run it exactly as shown,
with no surrounding redirect / `wc` / `cat` / `grep`. It writes the matched
entries' paths to a per-task `.out` file and prints one confirmation line on
stdout:

```
best-practice-resolve: wrote <N> matched entries to <abs-path>
```

`<N>` is the **branch signal**: `0` ⇒ no applicable best practices (skip the
reviewer); `≥1` ⇒ invoke the reviewer with the `<abs-path>` as
`{bp_context_file}`. Exit `0` is normal (including 0 matches). Exit `1` is a
resolution failure (bad args, unresolvable root, scratch/.out write failure) —
the caller records `error`, never a silent "no findings". A malformed config is
**fail-open**: the helper drops the offending file/entry with a stderr
diagnostic and still exits `0`. Surface those `warning:` diagnostics to the
user; do not swallow them.

## Doc-list discipline (read before reviewing)

The `.out` is a one-line header plus one `- <tags>: <path>` line per matched
entry. The path is whatever the user put in the config's `documentation` field
(a file or a directory), handed over **verbatim** — the helper does not check
that it exists, confine it, or list its contents.

- **Read each path directly**: a file with the Read tool; a directory by
  enumerating it with Glob and Reading the files. These are the user's own
  curated docs — the reference to assess the work *against*.
- **If a listed source cannot be read**, do **not** report a bare `no findings`:
  an exec reviewer emits `error`, a plan reviewer notes it in prose. Broken must
  never read as clean.
- **Cite the source path** each finding derives from, so the user can trace it.

## Why these agents have no Bash

The two agents are granted `Read, Grep, Glob, LSP` but **not** `Bash`. They read
the changeset/plan and the listed sources with the Read tool — there is no
markdown-reader or network need. Withholding Bash keeps the agents to the
minimal tool set for the job. Do not "restore" Bash for symmetry with the
security reviewers.

## Planning prompt template

Used by `plan-review.md` when `best-practice-resolve --phase=plan` reports ≥1
match. The agent reports **prose only** (no verdict block); findings fold into
the plan-review reduce.

```
Agent call: subagent_type=cwf-plan-reviewer-best-practice

Inputs:
- plan_file_path: {plan_file_path}
- plan_type: {plan_type}
- bp_context_file: {bp_context_file}

Follow the procedure in your agent definition.
```

## Exec prompt template

Used by the exec SKILLs when `best-practice-resolve --phase=<exec-step>` reports
≥1 match. The agent ends with one `cwf-review` verdict block, classified by the
**existing** `.cwf/scripts/command-helpers/security-review-classify` (reused
verbatim — same contract as the security reviewer).

```
Agent call: subagent_type=cwf-best-practice-reviewer-changeset

Inputs:
- wf_step: {wf_step}
- changeset_file: {changeset_file}
- bp_context_file: {bp_context_file}

Follow the procedure in your agent definition.
```

### Classification

Identical to the security review: write the verbatim subagent output to a file
and pipe it through the shared classifier:

```
.cwf/scripts/command-helpers/security-review-classify < <subagent-output-file>
```

One canonical token (`no findings` | `findings` | `error`) results. `error` is
the conservative default for an absent, malformed, or duplicated verdict, and
for any tool-level Agent failure. Record the verbatim output under a
`## Best-Practice Review` section with a `**State**: <token>` line above it.
Do **not** block on `findings` — surface them; the user decides.

## Config reference

`best-practices.json` is read from the project location
(`<git-root>/.cwf/best-practices.json`) and the user location
(`~/.cwf/best-practices.json`). Both load; entries merge. It is a deliberate,
separate file from the hash-tracked `cwf-project.json` (user-curated,
frequently edited) and coexists with the YAML `~/.cwf/autoload.yaml` (JSON here
is an explicit requirement).

```json
{
  "active-tags": ["golang", "postgres"],
  "best-practices": [
    { "documentation": "docs/go-style.md", "tags": ["golang"] },
    { "documentation": "docs/db/",         "tags": ["postgres"] }
  ]
}
```

- **`best-practices[]`** — each entry is `documentation` (a local file or
  directory path) + a non-empty `tags` list. An entry missing `documentation`
  or with empty `tags` is skipped with a diagnostic; the rest still load. A
  whole file that is not valid JSON yields zero entries from that file (with a
  diagnostic) — never an abort. Unknown keys are ignored.
- **`active-tags`** — the project/user default tag set. Plus an optional
  per-task `- **Tags**: a, b, c` line in the task's `a-task-plan.md` Task
  Reference block. The task's applicable set **T** is the union of both.
  Matching is exact-token, case-normalised (no substring). Undeclared ≡ empty ≡
  zero matches.

### Precedence

Project takes precedence over user (the standard CWF hierarchy). On a
`documentation` collision the project entry's `tags` win; `active-tags` are
unioned.

## Limitations

- **Paths are not confined**: a `documentation` path is handed to the reviewer
  verbatim and may point anywhere on disk, including outside the repo. This is
  deliberate — the docs are the user's own curated files (commonly under their
  home dir, e.g. `~/analysis/...`). Safe here because the reviewer only **Reads**
  (no Edit/Write) and findings are advisory; the user owns both the config and
  the paths it names. A reviewer that did more than read advisory text would need
  to reconsider this.
- **Advisory only**: the reviewer reports; it never gates the workflow.
