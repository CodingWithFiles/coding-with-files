# Harden security-review-changeset agent contract - Requirements
**Task**: 182 (feature)

## Task Reference
- **Task ID**: internal-182
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/182-harden-security-review-changeset-agent-contract
- **Template Version**: 2.1

## Goal
Define functional and non-functional specifications for hardening the `security-review-changeset` invocation contract and output handling so it is a single, deterministic, agent-invoked command.

## Current Behaviour (baseline)
- Accepts `--phase=implementation|testing` (informational, no behavioural effect), `--task-num=NUM` (override; auto-derived from branch otherwise), `--max-lines=N` (default unset = **no cap**), `--verbose`.
- Emits the **full diff to stdout**; a one-line summary (`reviewed N files, M lines (P production), anchor=<sha7>`) to **stderr**.
- Exit: 0 ok, 1 error, 2 production-count exceeds `--max-lines` (diff already on stdout).

## Functional Requirements
### Core Features
- **FR1 (flag rename)**: Replace `--phase=` with `--wf-step=<step>`. `--phase=` is **removed**, not aliased — passing it is an unknown-argument error (exit 1). Maps to user requirement (2).
  - **AC**: `--phase=implementation` → exit 1 unknown argument; `--wf-step=implementation-exec` accepted.
- **FR2 (wf-step value set)**: `--wf-step` accepts only canonical workflow-step identifiers from a fixed allowlist (the skill suffixes: `task-plan`, `requirements-plan`, `design-plan`, `implementation-plan`, `testing-plan`, `implementation-exec`, `testing-exec`, `rollout`, `maintenance`, `retrospective`). Unknown values → exit 1. Maps to user requirement (1)'s `{wf_step}` examples.
  - **AC**: `--wf-step=design-plan` accepted; `--wf-step=bogus` and `--wf-step=../escape` → exit 1.
  - **NOTE (scope)**: This task does **not** add new call sites. The script is still invoked only from the exec phases; the broader allowlist only makes the label/filename correct wherever it is called. Adding plan-phase invocations is out of scope.
- **FR3 (default cap)**: `--max-lines` defaults to **500** and remains overridable with any positive integer; omitting it now caps at 500 (previously: no cap). Maps to user requirement (4). **Note (R1 neutralised)**: both current call sites already pass `--max-lines=500` explicitly, so the new default reproduces today's behaviour for them; the default only newly affects a caller that *omits* the flag, of which there are none today.
  - **AC**: no `--max-lines` ⇒ cap=500 enforced; `--max-lines=900` ⇒ cap=900; `--max-lines=0`/`--max-lines=x` ⇒ exit 1.
- **FR4 (self-managed output file)**: The script computes the canonical per-task scratch dir (per `tmp-paths.md`), creates it with `mkdir -m 0700` (first-use guard), and writes the changeset to `<tmp>/security-review-changeset-<wf-step>.out`. The diff is written to the file, **not** to stdout. Maps to user requirement (3).
  - **FR4.1 (worktree-safe path)**: the scratch namespace is derived from the **main** tree, resolved via `git rev-parse --path-format=absolute --git-common-dir` per `tmp-paths.md`, so invocation from inside a linked worktree does not produce a divergent path. (The script has no repo-root resolution today — this is new.)
  - **FR4.2 (overwrite + symlink-safe write)** *(wording refined in design D1 — `rename`-replace, not `O_NOFOLLOW`-refuse)*: the write replaces any existing `.out` for that task+wf-step via a same-dir temp + atomic `rename` (truncate is inherent — `rename` atomically replaces the destination, so a prior run's content cannot leak into the new line count). Because `rename` replaces the destination name rather than writing through it, a pre-planted symlink at the target is **replaced and its referent file left unmodified** (not "refused" — the safety guarantee is no-write-through, not open-failure). The same-dir temp is created `O_EXCL`. `mkdir -m 0700` guards the directory.
  - **FR4.3 (empty changeset)**: when the changeset is empty, the script still writes a (0-line) `.out` file and prints the confirmation line with a count of 0; "empty" is signalled by the count in the confirmation line / file size, **not** by empty stdout (the old discriminator is gone — see FR6).
  - **AC**: after a run, the `.out` file exists at the canonical main-tree path and contains the full diff; stdout contains no diff lines.
- **FR5 (stdout confirmation)**: After writing, the script prints exactly one confirmation line to stdout giving the absolute output path and its line count, so the agent needs no follow-up `wc`/`cat`/`grep`. Maps to user requirement (5).
  - **FR5.1 (count definition)**: the reported count is the number of lines in the `.out` file; the file is written with a trailing newline so the reported count equals `wc -l` of the file unambiguously (resolves the no-trailing-newline off-by-one).
  - **AC**: stdout is a single line naming the absolute `.out` path and its line count; it equals `wc -l` of the file.
- **FR6 (invocation + consumption contract)**: Migrate the whole contract surface — **four sites** — to the new model. Maps to user requirements (1) and (5).
  - **FR6.1 (call sites)**: the exec-phase skills `cwf-implementation-exec` and `cwf-testing-exec` instruct the exact one-command form `.cwf/scripts/command-helpers/security-review-changeset --wf-step={wf_step}` (with `{wf_step}` = `implementation-exec` / `testing-exec` respectively), no surrounding boilerplate, and state the script is agent-invoked. The `--max-lines=500` argument is removed from both (now the default).
  - **FR6.2 (skill branching)**: each skill's Step-8 branching is rewritten to key off the confirmation line / `.out` file (read the file, branch on count) instead of stdout diff content. The old "exit 0 + empty stdout = no findings" branch is replaced by "count == 0".
  - **FR6.3 (agent consumption)**: the `cwf-security-reviewer-changeset` agent definition is migrated from receiving the inlined `{changeset}` variable to receiving the `.out` **path** and Reading it; the `{phase}` input is renamed to `{wf_step}`.
  - **FR6.4 (canonical contract doc)**: `.cwf/docs/skills/security-review.md` (the doc both skill and agent cite as source of truth) is updated to the `--wf-step` flag, the file-output model, and the new exit/empty semantics.
  - **AC**: an output-level grep over the **four** sites finds no `--phase`, no `--max-lines=500`, and no inlined `{changeset}` capture; the exact invocation string and the `.out`-path consumption are present.

### User Stories
- **As a** security-review subagent, **I want** one canonical command that produces a named output file and tells me where it is and how big it is, **so that** I don't guess paths or bolt on extra `wc`/`grep`/redirect calls.
- **As a** CWF maintainer, **I want** the wf-step label validated against a fixed allowlist, **so that** the value can safely become part of an output filename.

## Non-Functional Requirements
### Performance (NFR1)
- No material change: one extra `mkdir` and one file write versus today's stdout emission. Single git diff pass as before.

### Usability (NFR2)
- The confirmation line is the whole agent-facing contract: one command in, one path+count line out. Error messages stay actionable (`expected one of: …` for bad `--wf-step`).

### Maintainability (NFR3)
- Reuse the canonical tmp-path derivation rather than re-deriving inline; keep option parsing in the existing `@ARGV` loop style. No new non-core Perl modules.

### Security (NFR4)
- `--wf-step` is validated against a fixed allowlist before it reaches any filesystem path (path-traversal defence, mirroring the existing `--task-num` guard at `security-review-changeset:87-92`). The filename interpolation `security-review-changeset-<wf-step>.out` is safe **because** of this gate — a future relaxation of FR2 would reopen the path-injection surface.
- The output dir is created by the script itself with `mkdir -m 0700` (directory guard) **before** any write — not left to a helper's umask-default `make_path` — per the tmp-paths symlink-attack defence. The `.out` file is written via same-dir temp + `rename` (the temp is created `O_EXCL`), so a pre-planted symlink at the target is **replaced, not written through** — its referent is never modified — see FR4.2. This makes the safety property testable (referent unchanged) rather than asserted.

### Reliability (NFR5)
- If the wf-step is missing/invalid, the task number cannot be resolved, or the output dir/file cannot be created, the script exits 1 with a clear message and writes no partial confirmation.
- Exit-code semantics preserved: 0 ok, 1 error, 2 over-cap. On exit 2 the `.out` file is still written and the confirmation still printed (the over-cap signal is for the caller, not a reason to withhold output).

## Constraints
- Perl core-only; POSIX; `PERL5OPT=-CDSLA`; `use utf8;`.
- `security-review-changeset` is hashed → refresh `.cwf/security/script-hashes.json` in the same commit (hash-updates convention); chmod back to the recorded permission value after editing.
- Output path form and the `mkdir -m 0700` guard are governed by `.cwf/docs/conventions/tmp-paths.md` — do not invent a new `/tmp` form.

## Decomposition Check
Unchanged from a-task-plan: 0 signals triggered (single script + its docs/tests, ~1 day). No decomposition.

## Acceptance Criteria
- [ ] AC1 (FR1): `--phase=…` → exit 1 (unknown argument); `--wf-step=implementation-exec` accepted.
- [ ] AC2 (FR2): allowlisted wf-steps accepted; unknown / traversal-shaped values (`bogus`, `../escape`) → exit 1.
- [ ] AC3 (FR3): default cap is 500 and overridable; invalid `--max-lines` → exit 1.
- [ ] AC4 (FR4): `.out` written at the canonical `mkdir -m 0700` path; stdout carries no diff.
- [ ] AC4.1 (FR4.1): invoked from inside a linked worktree, the path still resolves to the main-tree namespace.
- [ ] AC4.2 (FR4.2): a second run fully replaces the first run's file content (truncate); a pre-planted symlink at the target is replaced and its referent file left unmodified (no write-through).
- [ ] AC4.3 (FR4.3): empty changeset ⇒ 0-line `.out` + confirmation line with count 0 (no reliance on empty stdout).
- [ ] AC5 (FR5/FR5.1): single stdout confirmation line (absolute path + count) equal to `wc -l` of the file.
- [ ] AC6 (FR6): output-level grep over the four sites finds the exact invocation string and the `.out`-path consumption, and no `--phase` / `--max-lines=500` / inlined-`{changeset}` capture.
- [ ] AC6.1 (FR6.2): each exec skill's Step-8 branching keys off the file/count, not stdout diff content.
- [ ] AC6.2 (FR6.3/6.4): agent reads the `.out` path and uses `{wf_step}`; `security-review.md` describes the `--wf-step` + file-output model.
- [ ] AC7 (NFR4/5): bad wf-step, unresolvable task, or uncreatable dir/file → exit 1, no partial confirmation; exit-2 over-cap still writes file + confirmation.
- [ ] AC8: script hash refreshed in the same commit; `cwf-manage validate` clean for the changed script.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All FRs/NFRs and AC1–AC8 satisfied (see `g-testing-exec.md` for the AC→test-case mapping). The FR4.2 wording was corrected during design review from O_NOFOLLOW "refuse" to `rename`-"replace" (no-write-through) — the guarantee the chosen mechanism actually provides.

## Lessons Learned
*To be captured during implementation*
