# Harden security-review-changeset agent contract - Design
**Task**: 182 (feature)

## Task Reference
- **Task ID**: internal-182
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/182-harden-security-review-changeset-agent-contract
- **Template Version**: 2.1

## Goal
Define the architecture for the four-site contract migration: the `security-review-changeset` script self-manages a worktree-safe output file and reports it, and its callers/agent/doc consume the file instead of stdout.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Verified Assumptions (measure twice)
Confirmed against the codebase before designing:
- **`CWF::Common::find_git_root()`** (`Common.pm:66`) already does the worktree-safe main-tree resolution (`git rev-parse --path-format=absolute --git-common-dir`, parent-of-`.git`) FR4.1 needs — **reuse, don't re-derive**.
- **`CWF::ArtefactHelpers::atomic_write_text($path,$blob, mode=>…)`** (`ArtefactHelpers.pm:54`) writes via same-dir `File::Temp` (`O_EXCL`) + `rename`. `rename(2)` **replaces a destination symlink** rather than writing through it → satisfies FR4.2's truncate **and** symlink-safety with no hand-rolled `O_NOFOLLOW`. **Reuse.**
- The script **already derives task_num** from `--task-num` or the branch (`security-review-changeset:103-113`) and validates it (`:89-92`) — FR3/task-num is solved; the `--wf-step` validation mirrors that guard.
- **Consumers are exactly four** (grep-verified): `cwf-implementation-exec/SKILL.md:48-59`, `cwf-testing-exec/SKILL.md` (same Step 8), `cwf-security-reviewer-changeset.md`, `.cwf/docs/skills/security-review.md`. The `settings.local.json` allowlist uses a wildcard (`security-review-changeset *`) — unaffected; `cwf-new-task/SKILL.md:80` is prose about the baseline anchor — unaffected.
- **Test exists**: `t/security-review-changeset.t` (updated in the testing phase, not now).

## Key Decisions
### D1 — Reuse existing helpers over hand-rolling
- **Decision**: derive the scratch path with `find_git_root()` + inline dashify; **the script itself** creates the dir with `mkdir($dir, 0700)` **first** and checks the result; then write the diff with `atomic_write_text($path, $blob, mode => 0600)`.
- **Imports**: `find_git_root` is **added to the existing** `use CWF::Common qw(check_perl5opt)` line (`security-review-changeset:61`) — not a new `use`. Only `use CWF::ArtefactHelpers qw(atomic_write_text)` is genuinely new. Both modules are core-only.
- **mkdir-first is load-bearing (security finding)**: `atomic_write_text` falls back to `File::Path::make_path($dir)` at **umask-default** mode when the dir is absent (`ArtefactHelpers.pm:59-63`), which would create the scratch dir world-traversable and defeat the tmp-paths symlink/read-after-write guard. So the script MUST `mkdir($dir, 0700)` itself before calling the helper; the helper's `make_path` then no-ops. A failed/foreign-owned dir is a fatal **exit-1** path (see exit table). Inline dashify (rather than a shared util) is consistent with `tmp-paths.md`, which explicitly **defers** a path helper ("three lines of shell, no helper script").
- **`die`→`exit 1` mapping (robustness finding)**: `atomic_write_text` **`die`s** on write/rename/chmod failure (`ArtefactHelpers.pm:62-85`), which alone would exit 255 with a `[CWF] ERROR:` prefix — inconsistent with this script's `warn "$PROG: …"; exit 1` convention and the caller's "exit 1 ⇒ error" branch. Wrap the call in `eval { … }; if ($@) { warn "$PROG: …"; exit 1 }`.
- **Rationale**: correctness (worktree-safe; `rename` replaces a dest symlink rather than writing through it — referent untouched) for free; reuse over duplication. No new non-core modules.
- **Trade-offs**: one new `use`; one `eval` wrapper.

### D2 — stdout = confirmation only; diff → file
- **Decision**: the full diff is written to `<scratch>/security-review-changeset-<wf-step>.out`; stdout carries exactly one confirmation line; the existing stderr summary stays.
- **Empty changeset is a deliberate behavioural change (robustness finding)**: today the `!@included` branch (`security-review-changeset:151-154`) `exit 0`s with **no** output. Under the new contract it MUST still `mkdir` + write a **0-line** `.out` file + print the confirmation (count 0) + `exit 0`, so the caller's count-based branch always has a line to parse. The old "empty stdout = no findings" discriminator is gone (D6).
- **Exit-2 ordering (robustness finding)**: the cap check moves to **after** the file write + confirmation print (today the diff is emitted before the count is computed, `:156-176`). Sequence on over-cap: write file → print confirmation → print `cap exceeded: …` (stderr) → `exit 2`. The caller can still recover the path for its error record.
- **Rationale**: kills the agent's `> /tmp/…; wc -l; grep` boilerplate (the originating complaint).
- **Trade-offs**: changes the caller contract (handled in D6); the "empty stdout" discriminator is replaced by the reported count.

### D3 — `--wf-step` allowlist
- **Decision**: replace the `--phase=(implementation|testing)` regex with an `--wf-step=<step>` check against a fixed allowlist hash of the ten skill suffixes (`task-plan … retrospective`). Unknown / traversal-shaped → exit 1 with `expected one of: …`. No `--phase` alias.
- **Why wf-step is in the filename**: a single task can run a security review in **both** `implementation-exec` and `testing-exec`; keying the output filename on the wf-step keeps each phase's `.out` distinct under the one task scratch dir, so one phase's run does not clobber the other's record. That makes ≥2 of the values genuinely live.
- **Rationale**: the value becomes a filename component; a fixed literal allowlist makes interpolation injection-safe (NFR4). The full ten-value list (vs the two live exec values) is a deliberate, cheap forward-compat choice per the user's `{wf_step}` examples (flagged in requirements) — literal kebab-case entries, no executable surface.

### D4 — default `--max-lines=500`
- **Decision**: initialise `max_lines => 500`; an explicit `--max-lines=N` overrides. Validation regex unchanged (`/^[1-9]\d*$/`).
- **Rationale**: encodes today's de-facto value as the default so callers drop the flag (FR3); R1 is neutral because both call sites already pass 500.

### D5 — count + confirmation
- **Decision**: ensure the written blob ends in `\n`; report the file's line count (newline count of the normalised blob). Confirmation line format:
  `security-review-changeset: wrote <N> lines to <abs-path>`.
- **Rationale**: trailing-newline normalisation makes the count == `wc -l` unambiguously (FR5.1).

### D6 — caller/agent/doc migration
- **Decision**: callers run the one-liner and branch on **exit code first**, then (within exit 0) on the reported count:
  - exit 1 → `error` (construction failed); exit 2 → `error` (cap, with the `cap exceeded:` reason);
  - exit 0 **and** count 0 → `no findings: empty changeset`;
  - exit 0 **and** count > 0 → pass the **path** to the agent as `{changeset_file}`; the agent Reads it (it already has `Read`).
  - exit 0 but **no parseable confirmation line** → `error` (never a silent skip).
  `{phase}` → `{wf_step}` throughout. `security-review.md` updated to the new flag, file-output model, and empty/exit semantics.
- **Filename deconfliction (misalignment finding)**: Step 8 of both skills *also* writes the **subagent's verbatim output** to the scratch dir for `security-review-classify`. That is a different artefact from this task's changeset-**input** file. Pin distinct names: input = `security-review-changeset-<wf-step>.out` (this task); output/verdict = `security-review-output-<wf-step>.out` (name pinned in the skill migration). `security-review-classify`'s contract is **untouched** — it still reads the verdict file from stdin redirection; it is not a fifth migration site.
- **Rationale**: without this the skills' stdout-based branching breaks (robustness finding). Keeps one source of truth.

## System Design
### Component Overview
- **`security-review-changeset` (script)**: option parse (`--wf-step` allowlist, `--max-lines` default), task-num resolve (unchanged), anchor + diff (unchanged), **new**: scratch-path derivation, `mkdir -m 0700`, `atomic_write_text` of diff, stdout confirmation, exit handling.
- **Exec SKILLs (×2)**: Step-8 invocation + branching rewrite.
- **`cwf-security-reviewer-changeset` agent**: input `{changeset}`→`{changeset_file}` (path it Reads), `{phase}`→`{wf_step}`.
- **`security-review.md`**: canonical contract doc text.

### Data Flow
1. Exec SKILL Step 8 → runs `security-review-changeset --wf-step=<step>`.
2. Script → resolves anchor + diff → `mkdir($dir,0700)` (script-owned, first) → `atomic_write_text` the diff to `<scratch>/…-<wf-step>.out` (0600) → prints `wrote N lines to <path>` → checks cap → exit 0/2/1.
3. SKILL → branch on **exit code first**: exit 1/2 ⇒ error; exit 0 ⇒ read count+path from the confirmation line — count 0 ⇒ no findings; count > 0 ⇒ Agent call with `{changeset_file}=<path>`; missing/unparseable line ⇒ error.
4. Agent → Reads `<path>` → reviews → emits `cwf-review` verdict block.

## Interface Design
### Script CLI (after)
- `security-review-changeset --wf-step=<allowlisted-step> [--task-num=NUM] [--max-lines=N] [--verbose]`
- **stdout**: one line — `security-review-changeset: wrote <N> lines to <abs-path>`.
- **stderr**: unchanged `reviewed N files, M lines (P production), anchor=<sha7>[, includes uncommitted]`; `--verbose` path list; `cap exceeded: …` before exit 2.
- **Exit**: 0 ok (incl. empty — file written with 0 lines + confirmation); 1 error (bad/missing `--wf-step`, bad `--max-lines`, unresolvable task, **dir uncreatable / `atomic_write_text` die mapped via `eval`→`warn "$PROG:…"; exit 1`**); 2 over-cap (file written + confirmation printed **before** exit).

### Output path
```
/tmp/<dashified-abs-main-root>-task-<num>/security-review-changeset-<wf-step>.out
```

## Constraints
- Perl core-only; `PERL5OPT=-CDSLA`; `use utf8;`.
- Hashed script → refresh `.cwf/security/script-hashes.json` in the same commit; chmod to recorded perm after edit.
- Output path + `mkdir -m 0700` per `tmp-paths.md` — no new `/tmp` form.

## Decomposition Check
Unchanged: 0 signals. One script + three doc/consumer sites, all in one commit. No decomposition.

## Validation
- [ ] Reuse of `find_git_root` / `atomic_write_text` confirmed sufficient for FR4.1/FR4.2 (`rename`-replace, not `O_NOFOLLOW`-refuse — requirement wording corrected)
- [ ] Script-owned `mkdir($dir,0700)`-first ordering and `eval`→exit-1 mapping specified (not left to helper `make_path`)
- [ ] Confirmation-line format agreed (D5); caller treats missing/unparseable line on exit 0 as error
- [ ] Input vs verdict scratch filenames deconflicted; `security-review-classify` contract untouched
- [ ] Four-site migration scope confirmed complete (no fifth consumer)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
D1–D6 implemented as designed. The reuse bets (D1) paid off: `find_git_root` + `atomic_write_text` needed no modification. One design-time gap surfaced in exec — the hashed-file set (D1 import note) named only the script, not the agent file; both were refreshed in-commit once `cwf-manage validate` flagged it.

## Lessons Learned
*To be captured during implementation*
