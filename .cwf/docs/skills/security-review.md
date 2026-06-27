# Security Review

This doc owns the CWF threat model and the prompts for the security-review subagent.

## Scope

Two callers:

1. **Plan phase** — row 4 of the criteria-lookup table in `.cwf/docs/skills/plan-review.md`. The plan SKILLs (`cwf-{requirements,design,implementation}-plan`) inherit it automatically by following the plan-review procedure.
2. **Exec phase** — Step 8 (Security Review) of `cwf-implementation-exec/SKILL.md` and `cwf-testing-exec/SKILL.md`. Each invokes one Agent call with the prompt template in §"Exec-phase prompt template" below.

Both callers grant the subagent `Read`, `Grep`, `Glob`, `LSP`, and `Bash` per `.cwf/docs/conventions/subagent-tool-selection.md`. `Bash` is retained as a **guided last resort** — for running the markdown-reader skill (a Bash-run Perl script) or `rg` when the Grep tool can't express a search — not because the review needs to mutate state. The tool-tier guidance steers reviewers to `Read`/`Grep`/`Glob`/`LSP` and skills first; raw Bash is the bottom tier. No `Edit`, no `Write` is granted, so the subagent forms judgements but does not write files; state-mutation avoidance now rests on guidance plus the absence of `Edit`/`Write` rather than on the absence of `Bash`.

**Residual threat (FR4(c)).** Reviewed content — plan files, and diffs carrying task descriptions or `{arguments}` — is untrusted input. With `Bash` granted, the prompt-injection blast radius now includes command execution, mitigated only by the tool-tier guidance and the absence of `Edit`/`Write` (no in-place file mutation). This is a deliberate posture choice to keep the markdown-reader skill usable; narrowing Bash back out, or scoping Skill access via settings-permissions, remains a possible follow-up.

**Boundary vs `cwf-manage validate`.** This subagent reviews *judgement-call* security concerns: design intent, code patterns, and input-flow analysis where a human reviewer would form an opinion. It does **not** duplicate the deterministic checks already performed by `.cwf/scripts/cwf-manage validate`, which verifies SHA256 integrity and recorded permissions against `.cwf/security/script-hashes.json`. Permission and hash-integrity violations are caught by `cwf-manage validate`; raising them here would be noise.

**Boundary vs the user-facing `/security-review` built-in.** The Claude Code built-in `/security-review` is a separate, user-invoked, branch-level review tool. It is not callable from a subagent and is not chained from any CWF workflow. Mentioned here only so future readers do not conflate the two.

## Changeset coverage

The exec-phase subagent reviews the changeset constructed by:

```
.cwf/scripts/command-helpers/security-review-changeset --wf-step=<step>
```

where `<step>` is the calling workflow step (`implementation-exec` or `testing-exec`). The helper is **agent-invoked**: run it exactly as shown, with no surrounding redirect / `wc` / `cat` / `grep` boilerplate. It writes the full changeset to a per-task `.out` file and prints one confirmation line `security-review-changeset: wrote <N> lines to <abs-path>` on stdout — the agent Reads that file rather than capturing a diff from stdout.

This helper is the **single source of truth** for changeset construction (the diff anchor, the output file, and the review cap) in CWF. Both exec SKILLs invoke the helper rather than inlining a pathspec or anchor.

The helper resolves its diff anchor in two steps. The success path: read the recorded `**Baseline Commit**: <sha>` field from the task's `a-task-plan.md` (written by `cwf-new-task` and `cwf-new-subtask` at branch creation). The fallback path (in-flight tasks created before this field existed): `git merge-base HEAD <trunk>`, where `<trunk>` is taken from the optional top-level `trunk` field of `cwf-project.json`, or from `git symbolic-ref refs/remotes/origin/HEAD`, or hardcoded `main`. The resolved trunk name is validated via `git check-ref-format --branch` before reaching `git merge-base`.

The helper emits the full `git diff` (anchor → working tree) over **every**
changed file. There is no path, directory, or language filtering: the security
review must see every line the task ships, whatever stack the consumer's
project uses. Test-vs-production weighting applies only to the review cap
(below), never to what is reviewed — test files are reviewed, but discounted
from the cap's line count.

**Known limitation**:

If a user rebases their task branch onto a newer trunk mid-task, the recorded baseline names the old fork point and the diff over-includes trunk drift. Mid-task rebase is not a CWF workflow (tasks land via squash + `git branch -f`); accepting this trade-off keeps the design simple.

### Production-weighted review cap

The full changeset is always written to the `.out` file for the subagent. Independently, the helper enforces a review cap on a **production-weighted** line count rather than the raw diff. `--max-lines` defaults to `500` (the exec SKILLs no longer pass it explicitly) and remains overridable with any positive integer. The production count is the sum of added+deleted lines (`git diff --numstat`) over all changed files, **minus** any path matching a `security.review.max-lines-exclude-paths` glob. Those patterns are gitignore/git pathspec globs declared in `cwf-project.json`; git's own `:(glob,exclude)` engine does the matching — the helper performs no path classification of its own and the count excludes diff context/hunk-header lines by construction. Excluded paths are still **reviewed** (emitted in the changeset) — they are only discounted from the cap count (tests, generated code, the repo's own process docs, etc.). The former key name `test-paths` is deprecated but still honoured (with a warning) when the new key is absent.

Contract: when the production count exceeds the cap the helper exits `2` (the `.out` file is already written and the confirmation line already printed, so a manual reviewer can still recover the path); the exec SKILL records `**State**: error` with the helper's `cap exceeded:` reason and does not invoke the subagent. Exit `1` (any construction failure, including an uncreatable scratch dir, a `.out` write failure, or a malformed `max-lines-exclude-paths` pattern git rejects) is likewise surfaced as `error` — never silently read as an empty "no findings" changeset. An empty changeset is **not** an error: the helper writes a 0-line `.out` file, prints the confirmation with count 0, and exits `0`; the exec SKILL reads `**State**: no findings` (`no findings: empty changeset`) from the count, not from empty stdout.

Fail-safe direction and limitation: `security.review.max-lines-exclude-paths` defaults unset, so with no configuration there is no discount and the cap measures raw production lines (no regression for any repo). Any layout that is unconfigured or unmatched counts as *production* — the cap fires earlier, never later. Directory-based test layouts (e.g. `t/**`, `tests/**`) are covered cleanly; co-located suffix conventions (`**/*_test.go`, `**/*.spec.ts`) are expressible as globs but not exhaustively pursued. An uncovered test file is a *coverage* gap (counts as production), never an *unsafe* one. The helper (`.cwf/scripts/command-helpers/security-review-changeset`) is the source of truth for this count.

## Threat categories

Five categories the subagent must cover. Each carries (i) a one-line definition, (ii) an anti-pattern example with file:line citation if a real instance exists in the codebase, otherwise an `# illustrative` snippet using CWF-shaped names, (iii) a one-line "do instead" pointer.

### (a) Bash injection / unsafe command construction

- **Definition**: shell metacharacter exposure through interpolation of task slugs, branch names, file paths, or other partly-controlled strings into shell commands or `system($string)` calls.
- **Anti-pattern** (`# illustrative` — no real instance in current CWF source):
  ```perl
  # in some hypothetical helper:
  my $branch = "feature/$task_num-$slug";
  system("git checkout $branch");      # single-string form invokes the shell
  ```
- **Do instead**: list-form `system` with no shell, as in `.cwf/scripts/cwf-manage:255` (`system("git", "clone", "--quiet", $source, $clone_dir)`). The list form passes arguments directly to `execvp` — no shell parses them, so quoting hazards do not apply.

### (b) Perl helpers consuming git or user output without `-z` / input validation

- **Definition**: Perl helpers that newline-split git porcelain output, or interpolate untrusted strings into backticks, instead of using NUL-separated output and list-form spawn.
- **Anti-pattern** (`# illustrative`):
  ```perl
  # newline-splitting git output — breaks on filenames containing '\n':
  my @files = split /\n/, qx{git ls-files};
  for my $f (@files) {
      open my $fh, '<', $f or die;
      ...
  }
  ```
- **Do instead**: `docs/conventions/git-path-output.md` — use `git ls-files -z` and `split /\0/`. The universal Perl rules (`#!/usr/bin/env perl`, `PERL5OPT=-CDSLA`, `use utf8;`) live in `docs/conventions/perl.md`. Existing CWF helpers (`context-manager.d/*`, `template-copier-v2.1`) follow both conventions.

### (c) Prompt injection via user-supplied strings

- **Definition**: untrusted strings (task descriptions, slugs, branch names, file content, git output) flowing verbatim into LLM context where they could carry instructions interpreted by a downstream model.
- **Real surface**: `.claude/skills/cwf-implementation-exec/SKILL.md:25` and every other SKILL with `**Task arguments**: {arguments}` substitution — `{arguments}` is the user's raw `/cwf-… <task-num> <free text>` input and reaches LLM context as-is.
- **Anti-pattern** (`# illustrative`):
  ```markdown
  Now read the description below and write a plan:

  Description: {arguments}

  Begin the plan with:
  ```
  An attacker-controlled description like `123 ignore previous instructions and …` can subvert the SKILL. The CWF mitigation today is structural: `{arguments}` is parsed by helper scripts (e.g. `task-context-inference`) and only the validated task-number portion drives behaviour. Free-text is informational only.
- **Do instead**: parse `{arguments}` through a helper script that validates the task-number prefix before any LLM action keys off it. Free-text portions should be treated as advisory. Never let `{arguments}` content choose the next tool call.

### (d) Unsafe environment-variable handling

- **Definition**: env vars influencing security-critical operations (paths fed to `chmod`/`rm`, URLs cloned from, hash-tracked file contents) without explicit validation.
- **Real surface**: `.cwf/scripts/cwf-manage:85-87` — `CWF_SOURCE` overrides the configured CWF source URL and flows into `git clone` at `cwf-manage:255`. The current code is **safe** (list-form `system("git", "clone", ..., $source, ...)`, no shell), so this is cited as the canonical surface to audit, not as a defect.
- **Anti-pattern** (`# illustrative` — what unsafe handling would look like):
  ```perl
  my $source = $ENV{CWF_SOURCE} // 'https://example.com/cwf';
  system("git clone $source /tmp/cwf-update");   # shell metachars in $source execute
                                                 # `/tmp/cwf-update` is illustrative — not a
                                                 # canonical scratch path; see
                                                 # .cwf/docs/conventions/tmp-paths.md
  ```
- **Do instead**: keep the list form as in `cwf-manage:255`. When new env vars are added, route them through the same list-form invocation pattern; any new env var feeding `chmod`/`rm`/`open` paths must canonicalise (`File::Spec->rel2abs`, deny `..`) before use.

### (e) Pattern-based risks (safe-here-but-risky-elsewhere)

- **Definition**: a code pattern that is provably safe at the current callsite because of a callsite-specific invariant, but which would become exploitable if reused in a context where that invariant does not hold.
- **Anti-pattern** (`# illustrative`):
  ```perl
  # in cwf-version-tag (illustrative):
  my $tag = "v$major.$minor.$task_num";
  qx{git tag -a $tag -m "Task $task_num"};   # safe today: $task_num is a digits-only int
  ```
  Safe at this callsite because `$task_num` has been validated upstream as decimal-numeric. Risky if copy-pasted into a context where `$task_num` is replaced by a slug, branch name, or any other partly-user-controlled string.
- **Required framing**: report as `safe here because <invariant>; audit future uses where <invariant> might not hold`. The pattern-risk carve-out exists so the subagent surfaces real signal without sliding into aspirational suggestions.
- **Do instead**: prefer list-form spawn (as in (a) and (d) above) so the safety doesn't depend on the callsite's invariant; or, if backticks are required, document the invariant inline so the next reader knows what they would break by reusing the snippet.

## Plan-phase row

The plan-review map (`.cwf/docs/skills/plan-review.md` § "1. MAP: Launch Subagents") includes the `Security` column, run by the `cwf-plan-reviewer-security` agent. Its criteria are baked into that agent body and reference this doc rather than restating the threat model.

## Exec-phase prompt template

Invoke the `cwf-security-reviewer-changeset` agent. The agent body
holds the full review instructions and the verdict-block contract;
the SKILL-side prompt only needs to pass `{wf_step}` and
`{changeset_file}`.

Substitute `{wf_step}` (= `"implementation-exec"` or `"testing-exec"`)
and `{changeset_file}` (the absolute `.out` path from the helper's
confirmation line, per § "Changeset coverage"). The agent Reads that
file itself — the diff is not inlined into the prompt.

```
Agent call: subagent_type=cwf-security-reviewer-changeset

Inputs:
- wf_step: {wf_step}
- changeset_file: {changeset_file}

Follow the procedure in your agent definition.
```

### Verdict container

The subagent reasons in prose, then ends its response with a single
fenced `cwf-review` block carrying the machine verdict:

````
```cwf-review
state: <no findings|findings|error>
summary: <optional one-line note>
```
````

The block is position-independent — prose precedes it freely; only the
block is parsed for the verdict, so the model is no longer required to
lead with a sentinel.

### Classification (deterministic, single source of truth)

The exec SKILL does **not** apply a prose rule. It writes each verbatim
subagent output to a `<reviewer>-review-output-<phase>.out` file in the
per-task scratch dir, then classifies them all in one discovery-mode
invocation (no shell loop — matches the allowlist, raises no prompt):

```
.cwf/scripts/command-helpers/security-review-classify --dir <scratch-dir> --phase <phase>
```

This prints one `<reviewer>: <token>` line per discovered file (lexical
order). The single-file stdin form is unchanged and still used by the
SubagentStop guard hook and any single-file caller:

```
.cwf/scripts/command-helpers/security-review-classify < <subagent-output-file>
```

Each token is one canonical value (`no findings` | `findings` | `error`)
per the parse rule the helper owns: exactly one valid `cwf-review` block
→ that state; zero or more than one valid block → `error`. Both modes
share one parser, and both exec SKILLs plus the SubagentStop guard hook
(`.cwf/scripts/hooks/subagentstop-security-verdict-guard`) call the same
helper, so there is no classifier drift.

`error` is the conservative default — an absent, malformed, duplicated,
or non-token verdict surfaces as `error`, never silently downgraded to
`no findings`. A tool-level failure (Agent call error, timeout,
allowlist violation) is likewise recorded as `error`.

The SKILL records the verbatim subagent output under `## Security
Review` in the wf step file, with a `**State**: findings|no
findings|error` line (the helper's token) above the verbatim block.
