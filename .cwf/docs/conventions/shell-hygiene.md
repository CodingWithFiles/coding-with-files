# Shell Hygiene

Conventions for running shell commands under the Claude Code harness: prefer
idioms that neither trip blocking permission prompts nor sacrifice POSIX
portability, and understand the read-only command allowlist CWF seeds at init.

This doc owns only the rules not documented elsewhere; it links the surfaces
that already cover the rest rather than restating them.

## Prompt-free, portable command idioms

- **No heredocs or inline scripts.** Do not feed a heredoc, `perl -e '…'`, or
  `python -c '…'` to the Bash tool. Write the script to this task's scratch
  directory (`.cwf/docs/conventions/tmp-paths.md`) with the Write tool, then run
  it from there. Inline programs trip permission prompts and are unreviewable.
- **`chmod +x && ./script`, not `perl script` / `bash script`.** Once a script
  is on disk, make it executable and run it directly — the shebang selects the
  interpreter. Invoking the interpreter by name is a compile-then-run Windows
  idiom POSIX does not need.
- **No `perl -c` / `bash -n` pre-check.** This is a POSIX-only project; there is
  no compile-before-run step. Make the script executable and run it.
- **Avoid command substitution that trips a prompt.** A `$(…)` or backtick
  inside a Bash-tool command can trigger a blocking permission check even when
  the outer command is harmless — e.g. `cd "$(git rev-parse --show-toplevel)"`
  when the cwd is already the repo root. Drop the substitution, or split the
  step so the substitution runs where it is actually needed.
- **NUL-separate git path output.** When a `git` subcommand emits paths for
  downstream parsing, pass `-z` and split on `\0` — filenames may contain
  spaces or newlines. (The full maintainer rationale lives outside the shipped
  tree; this one-line rule is the shipped form.)

Idioms that already trip prompts — `cat | grep`, `sed -n 'X,Yp'` line ranges,
`find … -exec`, `tee`, trailing `; echo EXIT: $?` — are catalogued in the
subagent anti-pattern table; use the built-in tool named there instead of
duplicating the guidance:

- Anti-pattern table: `.cwf/docs/skills/cwf-agent-shared-rules.md#blocking-bash-anti-patterns`
- Full tool-tier rubric: `.cwf/docs/conventions/subagent-tool-selection.md`

## The read-only command allowlist seed

`cwf-init` seeds a small set of read-only commands into the project's committed
`.claude/settings.json` (`permissions.allow`), alongside the `.cwf/` helper
entries. They run without a per-invocation confirmation prompt. The current
corpus is `ls`, `pwd`, `git status`, `git rev-parse` (as `Bash(<cmd>:*)`
prefixes) and `git branch --show-current` (an exact entry).

**Admission criterion.** A command qualifies only if it is read-only across the
*entire* argument space the `:*` glob admits — not merely as typically typed. A
`Bash(<prefix>:*)` rule auto-approves every argument string the prefix admits,
so an entry qualifies only when no flag or subcommand anywhere in its option
space can mutate state, execute an arbitrary child process, or do network I/O;
and only when the command is one this convention itself encourages.

**Excluded, with reason** — the near-neighbours that look safe but are not:

| Tempting entry | Why excluded |
|---|---|
| `git diff` / `git log` / `git show` (`:*`) | admit `--output=<file>` (file clobber) and `--ext-diff` (arbitrary exec) |
| `rg` (`:*`) | admits `--pre <cmd>` / `--pre-glob` (arbitrary child execution) |
| `grep` (`:*`) | read-only, but prefer the Grep tool — excluded for coherence, not safety |
| bare `git` (`:*`) | admits `git commit` / `push` / `branch -D` (mutation) |
| `find` / `sed` (`:*`) | admit `-exec` / `-delete` and `-i` (exec / in-place write) |
| `git branch` (`:*`) | admits `git branch -D` — hence the **exact** `--show-current` entry, not a prefix |

**Opting out of a seeded allow.** The durable opt-out is a rule in your **user**
(`~/.claude/settings.json`) or **project-local** (`.claude/settings.local.json`)
layer — `ask` to restore the confirmation prompt, `deny` to forbid the command
outright. Permission scopes merge (union) and `deny` outranks `ask` outranks
`allow`, so your stricter rule wins over the seeded `allow` regardless of
specificity. Deleting the entry from the committed `.claude/settings.json` is
**not** durable: the additive merge re-adds it on the next `cwf-init`.

**Harness matching caveat.** The read-only guarantee rests on how Claude Code
matches a `Bash(<prefix>:*)` rule against a command line. Shell operators are
handled safely — the harness splits on `&&`, `||`, `;`, `|`, `|&`, `&`, and
newlines and requires each subcommand to match a rule independently, so
`Bash(ls:*)` does not approve `ls; rm -rf x`. Redirection (`>`, `>>`) and
command substitution (`$(…)`, backticks) are not documented; if either were
auto-approved under a prefix rule it would be a harness-wide property of every
`allow` entry, not unique to this corpus. Because this corpus adds
high-frequency verbs (`ls`, `git status`), keep prompt-injection risk in mind
when reviewing untrusted input that reaches a shell.

## See also

- `.cwf/docs/conventions/tmp-paths.md` — per-task scratch directories for on-disk scripts.
- Task-220 tool-check enforcement — the deny-side blocklist seed complementing this allow-side seed.
