# Security Review

This doc owns the CWF threat model and the prompts for the security-review subagent.

## Scope

Two callers:

1. **Plan phase** — row 4 of the criteria-lookup table in `.cwf/docs/skills/plan-review.md`. The plan SKILLs (`cwf-{requirements,design,implementation}-plan`) inherit it automatically by following the plan-review procedure.
2. **Exec phase** — Step 8 (Security Review) of `cwf-implementation-exec/SKILL.md` and `cwf-testing-exec/SKILL.md`. Each invokes one Agent call with the prompt template in §"Exec-phase prompt template" below.

Both callers restrict the subagent to `Read`, `Grep`, and `Glob` per `.cwf/docs/conventions/subagent-tool-selection.md`. No `Bash`, no `Edit`, no `Write` — the subagent forms judgements but does not mutate state.

**Boundary vs `cwf-manage validate`.** This subagent reviews *judgement-call* security concerns: design intent, code patterns, and input-flow analysis where a human reviewer would form an opinion. It does **not** duplicate the deterministic checks already performed by `.cwf/scripts/cwf-manage validate`, which verifies SHA256 integrity and recorded permissions against `.cwf/security/script-hashes.json`. Permission and hash-integrity violations are caught by `cwf-manage validate`; raising them here would be noise.

**Boundary vs the user-facing `/security-review` built-in.** The Claude Code built-in `/security-review` is a separate, user-invoked, branch-level review tool. It is not callable from a subagent and is not chained from any CWF workflow. Mentioned here only so future readers do not conflate the two.

## Pathspec coverage

The exec-phase subagent reviews the changeset emitted by:

```
.cwf/scripts/command-helpers/security-review-changeset --phase=<implementation|testing>
```

This helper is the **single source of truth** for what counts as security-relevant in CWF. Both exec SKILLs invoke the helper rather than inlining a pathspec or anchor.

The helper resolves its diff anchor in two steps. The success path: read the recorded `**Baseline Commit**: <sha>` field from the task's `a-task-plan.md` (written by `cwf-new-task` and `cwf-new-subtask` at branch creation). The fallback path (in-flight tasks created before this field existed): `git merge-base HEAD <trunk>`, where `<trunk>` is taken from the optional top-level `trunk` field of `cwf-project.json`, or from `git symbolic-ref refs/remotes/origin/HEAD`, or hardcoded `main`. The resolved trunk name is validated via `git check-ref-format --branch` before reaching `git merge-base`.

The helper's classification rules over the resulting changed-files list are:

1. **CWF-internal coverage (unconditional include)**: paths under `.cwf/scripts/`, `.cwf/lib/`, `.cwf/docs/skills/`, `.cwf/templates/`, `.claude/scripts/`, `.claude/skills/`, `.claude/hooks/`, `.claude/rules/`, plus the exact files `.claude/settings.json`, `.claude/settings.local.json`, `implementation-guide/cwf-project.json`. Reviewed regardless of file type — markdown skills/rules carry instructions interpreted by Claude.
2. **Shebang sniff (conditional include)**: any path *outside* (1) is included only if its first line begins with `#!` and the interpreter basename matches the anchored regex `^(?:perl|bash|sh|ksh|zsh|fish|python\d?|ruby|node|deno|php|lua|pwsh|powershell)$`. Symlinks and non-regular files (FIFOs, sockets, devices) are skipped to avoid following arbitrary targets and to defend against DoS-shaped diff entries.
3. **Default exclude**: anything else.

**Maintainer note**: when adding a new security-relevant tree (e.g. a future `.cwf/scripts/post-install/` or a new hook directory), update the `@CWF_INTERNAL_PREFIXES` list inside the helper script. Silent expansion of the attack surface is the failure mode this single-source-of-truth rule prevents. The shebang interpreter regex is anchored at both ends (`^…$`); future maintainers extending it MUST preserve anchoring.

**Known limitations** (each acceptable for v1; tracked as separate backlog items if a consumer reports a gap):

- Library files outside the CWF-internal directories are missed if they have no shebang (the v2 add-an-`always-included-paths`-config-field follow-up would address this if needed).
- Shebang-less scripts loaded via `source`/`.` are missed.
- Uncommon interpreters (`awk`, `tcl`, `make`) are missed; the regex covers the common-case stack.
- UTF-8 BOM-prefixed shebangs (vanishingly rare on POSIX) are missed.

If a user rebases their task branch onto a newer trunk mid-task, the recorded baseline names the old fork point and the diff over-includes trunk drift. Mid-task rebase is not a CWF workflow (tasks land via squash + `git branch -f`); accepting this trade-off keeps the design simple.

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
- **Do instead**: `docs/conventions/perl-git-paths.md` — use `#!/usr/bin/perl -CDSL`, `git ls-files -z`, and `split /\0/`. Existing CWF helpers (`context-manager.d/*`, `template-copier-v2.1`) follow this convention.

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

The plan-review.md criteria-lookup table gains a `Security` column. Each cell is short (≤2 sentences) and references this doc rather than restating the threat model. See `.cwf/docs/skills/plan-review.md` § "Criteria Lookup Table" for the row text.

## Exec-phase prompt template

Substitute `{changeset}` (the `git diff` output produced per § "Pathspec coverage") and `{phase}` (= `"implementation"` or `"testing"`).

```
Review the {phase}-phase changeset below for security concerns per the threat model in `.cwf/docs/skills/security-review.md` § "Threat categories" (a)–(e).

You may only use Read, Grep, and Glob (no Bash, no edits).

Start your response with one of three sentinel lines:
- `findings:` followed by numbered actionable items (what is wrong, where in the diff, what to do).
- `no findings` if the diff is clean. May be followed by a one-line note.
- `error:` if you cannot perform the review (state the reason).

Pattern-based risk findings (per category (e)) are allowed: a pattern that is safe at the callsite but risky if reused elsewhere may be reported with the framing "safe here because X; audit future uses where X might not hold." Aspirational suggestions with no concrete CWF surface are out of scope.

Changeset:
{changeset}
```

The exec SKILL classifies the response per the three-tier rule:

1. **Primary**: first non-blank line begins with `findings:` / `no findings` / `error:` → use that classification.
2. **Fallback**: if primary fails, scan body for a numbered list (`^\s*\d+[.)]\s`) or the literal phrase `actionable finding` → classify as `findings`.
3. **Conservative default**: if neither matches, classify as `error`. Never silently classify as `no findings` — that masks malformed-output failures.

A tool-level failure (Agent call error, timeout, allowlist violation) is also classified `error` regardless of body.

The SKILL records the verbatim subagent output under `## Security Review` in the wf step file, with a `**State**: findings|no findings|error` line above the verbatim block.
