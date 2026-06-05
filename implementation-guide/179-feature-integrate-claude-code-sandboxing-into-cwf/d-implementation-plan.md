# Integrate Claude Code sandboxing into CWF - Implementation Plan
**Task**: 179 (feature)

## Task Reference
- **Task ID**: internal-179
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/179-integrate-claude-code-sandboxing-into-cwf
- **Template Version**: 2.1

## Goal
Implement the c-design build: extend `cwf-claude-settings-merge` + `CWF::Validate::Config`,
add the R3 logging hook, ship the limitations doc, seed R1 (179.1). TDD throughout.

## Workflow
Patterns first → failing test → minimal impl → green → refactor → same-commit hash refresh.

## Files to Modify
### Primary
- `.cwf/scripts/command-helpers/cwf-claude-settings-merge` — config read (D1), type re-check
  (D4), R2 paired-rule generation (D6), ownership-by-shape reconcile (D2),
  `failIfUnavailable` + pure-Perl dep probe + fixed-token guard (D5), event-allowlist
  widening to `{Stop, SubagentStop, PreToolUse}` (D-events), R3 hook registration. **Hash-tracked.**
- `.cwf/lib/CWF/Validate/Config.pm` — `_validate_sandbox_block`, registered at lines 129–130;
  reuse `_is_bool`/`_scalar_repr`/`_violation`. **Hash-tracked.**
- `.cwf/scripts/hooks/pretooluse-sandbox-logging` — new R3 hook (D8). **Hash-tracked (new).**
- `implementation-guide/cwf-project.json` + `.cwf/templates/cwf-project.json.template` —
  add the `sandbox` block (default OFF; `~/.ssh`/`~/.aws`; `fail-if-unavailable: true`;
  `violation-logging: false`).

### Supporting
- `.cwf/security/script-hashes.json` — refresh helper + `Config.pm`; add the new hook entry
  (`permissions: "0500"`, fresh `sha256`). **Same commit as the edits.**
- `.cwf/install-manifest.json` (`gitignore-entries` artefact) **+** `.gitignore` — add the R3
  log path so it is gitignored (reusing the mechanism that already lists `.cwf/task-stack`,
  `.cwf/.update.lock`).
- `.cwf/docs/` — limitations doc (FR7).
- `t/cwf-claude-settings-merge.t`, `t/validate-config.t` — extend (tests first).

## Implementation Steps

### Step 1 — Config schema + validator (D3; FR1/AC1e) — tests first
- [ ] `t/validate-config.t` failing cases: non-bool `enabled`/`fail-if-unavailable`/
      `violation-logging` → violation; `credential-deny-list` non-array / non-string entries
      → violation; **absent block → no violation**; absent list + `enabled:true` → no violation.
- [ ] Add `_validate_sandbox_block` (reusing `_is_bool`/`_scalar_repr`/`_violation`), gated on
      `exists $config->{sandbox}` (mirror `_validate_versioning_block`); register at 129–130. Green.

### Step 2 — Helper reads config + re-checks types (D1/D4; FR1/FR6)
- [ ] Failing tests, **at the right granularity** (the three cases are distinct surfaces):
      (i) config **file absent** ⇒ OFF, output identical to today, exit 0;
      (ii) file present, **`sandbox` block absent** ⇒ OFF, identical output (golden file, AC1b);
      (iii) **unparseable JSON** ⇒ surfaced error (not silent-OFF);
      (iv) **malformed block** (wrong-typed switch / non-array list) ⇒ helper **dies**
      `[CWF] ERROR:` (not silent-OFF).
- [ ] Implement: **`-f` existence guard before the read** (`read_json_file` *dies* on a
      missing file — `ArtefactHelpers.pm:33` — so absent-file must be guarded to mean OFF, or
      fresh installs regress). Read via a **helper-local relative**
      `read_json_file('implementation-guide/cwf-project.json')` — justified by the helper's
      existing cwd==git-root invariant (this is **not** the `CWF::Versioning` path
      `cwf-version-bump`/`security-review-changeset` use; do not claim that reuse). Re-validate
      knob types in the helper (don't trust `validate` ran). Gate new behaviour on
      `sandbox.enabled`. Green.

### Step 3 — R2 paired rules + ownership-by-shape reconcile (D2/D6; FR2)
- [ ] **Pin the "CWF-shaped" predicate** (the removal crux): a `permissions.deny` entry is
      CWF-owned iff it matches the exact forms CWF emits — `Read(<P>)` / `Read(<P>/**)` — for
      the credential-path syntax CWF generates. On toggle-OFF/absent, remove the **entire**
      `sandbox.*` block and **every** entry matching that predicate (whole managed family).
- [ ] Failing tests: ON ⇒ `denyRead` = list, `permissions.deny` = `Read(P)`+`Read(P/**)` per
      entry; OFF/absent ⇒ all of the above removed; a non-CWF-shaped user deny (`Bash(curl *)`)
      **preserved** across ON→OFF; **AC1c collision (explicit)**: a user-authored
      `Read(~/.ssh)` byte-identical to a CWF default **is removed** on toggle-OFF — assert this
      as the *documented, intended* outcome (ownership-by-shape == ownership; users put
      overrides in `settings.local.json`); changed-list-then-OFF ⇒ **no orphan**; idempotent
      re-run adds nothing; `allow`/`hooks`/`PERL5OPT` unchanged.
- [ ] **Rule-form tests (D6) — string-form, not runtime-matcher** (the Perl suite emits JSON;
      it cannot exercise Claude Code's matcher): assert the emitted strings equal the
      doc-specified forms, and **re-verify the `~`-expansion + `allowRead`-narrowing behaviour
      against current Claude Code docs at exec and cite**. **Fail-closed fallback**: if no rule
      form reliably expands `~` to `$HOME`, the merge must **surface and refuse**, not emit a
      hollow `Read(~/…)` that denies nothing (a silent boundary hole).
- [ ] Implement desired-set + reconcile-by-shape; write via `atomic_write_text` to
      `.claude/settings.json` only (AC6d). Green.

### Step 4 — `failIfUnavailable` + dep probe + guard (D5; FR3)
- [ ] Failing tests: ON ⇒ `failIfUnavailable: true` default; knob `false` ⇒ reflected;
      hand-set differing value ⇒ **warn-not-overwrite, fires under `--dry-run` and on repeat**
      (mirror `merge_env` exactly); value re-checked as JSON bool before write; missing-dep
      probe ⇒ fixed-token message naming package + knob; **empty/`.` PATH segment is NOT
      resolved to cwd**; probe never blocks generation.
- [ ] Implement authoritative `failIfUnavailable`; pure-Perl `$ENV{PATH}` split + `-x` test
      for `bwrap`/`socat` (compile-time literal names; **skip empty segments**; no shell, no
      `which`); fixed-token message (no probe-output interpolation). Green.

### Step 5 — Event allowlist + R3 hook (D-events/D8; FR5)
- [ ] Failing tests (**inject a manifest fixture**, do not depend on Step 7's live
      `script-hashes.json` — avoids Step 5/7 circular coupling): `read_hook_directives` accepts
      `PreToolUse`; a `PreToolUse`+`Bash` hook registers under **PreToolUse** (not Stop-fallback);
      matcher regex **unchanged** (a `|` matcher still rejected → 179.1); `violation-logging:false`
      ⇒ no hook registered (knob is read, not just written). R3 hook behaviour:
      `dangerouslyDisableSandbox` present ⇒ one record appended; log-write failure ⇒ swallowed,
      tool proceeds (never blocks).
- [ ] Widen event allowlist (helper line 82) to `{Stop, SubagentStop, PreToolUse}`. Write
      `.cwf/scripts/hooks/pretooluse-sandbox-logging` modelled on
      `subagentstop-security-verdict-guard`: **whole body under `eval`** (malformed stdin ⇒
      fail-open), output/record via **`JSON::PP->encode` of a fixed-key hash** (timestamp + a
      **boolean/enum flag derived from presence** — never the raw `command`/`tool_input`
      echoed), exit 0. Log destination: a **persistent, gitignored** path under `.cwf/` (e.g.
      `.cwf/sandbox-violations.log`) — **not hash-tracked** (runtime state like
      `.cwf/task-stack`); operator-facing only, **never re-fed into LLM context**. Green.

### Step 6 — Limitations doc (FR7)
- [ ] New `.cwf/docs/` page: CWF advises / OS enforces / operator overrides; Bash-only;
      `dangerouslyDisableSandbox` agent-reachable (advisory unless `allowUnsandboxedCommands:
      false`); no reliable violation event (R3 best-effort); fail-closed only while
      `failIfUnavailable` true; **`denyRead` does not cover env-resident credentials — use
      `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB`** (AC7a). Reference from the `sandbox` config docs (AC7b).

### Step 7 — Integrity + full validate (same commit)
- [ ] Add the R3 log path to the `gitignore-entries` artefact in `.cwf/install-manifest.json`
      and to `.gitignore`; confirm the log is **not** hash-tracked and a runtime write to it
      leaves `cwf-manage validate` clean (test).
- [ ] Refresh `script-hashes.json` for the helper + `Config.pm`; add the new hook entry
      (`permissions: "0500"`, fresh `sha256`) — **same commit** (`hash-updates.md`). Set the
      hook's working perms to recorded `0500`.
- [ ] Run the full `t/` suite, `cwf-claude-settings-merge --dry-run` ON and OFF, and
      `.cwf/scripts/cwf-manage validate` — all clean.

### Step 8 — Seed R1 follow-up (179.1; D7)
- [ ] `.cwf/scripts/command-helpers/backlog-manager add --title='R1: phase-scoped
      planning-write PreToolUse guard (CWF sandboxing 179.1)' --task-type=feature
      --priority=Medium --body-file=<scratch>` (list-form; `--title` required). Body: reuse
      `task-context-inference`; fail-closed (deny production crown-jewel writes on ambiguous
      inference) without bricking; **needs the matcher regex widened to admit `Edit|Write`**
      (179 widened only the event allowlist); same-commit hash refresh. Confirm single live
      entry (grep count == 1; `validate --all` exit 0).

## Code Changes
Edit sites fixed: helper config-read + reconcile + line-82 allowlist + probe; `Config.pm`
129–130; new hook modelled on `subagentstop-security-verdict-guard`. No pseudocode for routine
merge logic; the non-obvious pieces (ownership-by-shape predicate, `-f` guard, rule-form
fallback, fixed-key log record) carry explicit tests above.

## Test Coverage
**See e-testing-plan.md** — unit (validator, paired rules, reconcile incl. AC1c collision,
probe incl. empty-PATH-segment, hook registration + suppression), string-form (rule forms +
doc-cite), regression (sandbox-OFF golden file; full `t/` suite), negative (no path silences
validate; log write leaves validate clean). **NFR1**: e-testing must carry a bounded per-call
cost note for the R3 hook (lighter than R1 — no `task-context-inference`).

## Validation Criteria
**See e-testing-plan.md.** Gate: full suite green; `cwf-manage validate` clean; dry-run ON
and OFF correct; single live 179.1 backlog entry.

## Scope Completion
Complete Steps 1–8. R1 is **planned-out** to 179.1 by design (D7/AC4d) with a seeded item —
the approved descope, not a silent deferral. Do not mark Finished until the hash refresh
(Step 7) and `validate` are clean in the same commit as the edits.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
