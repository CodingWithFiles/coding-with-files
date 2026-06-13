# Bash tool-check framework - Design
**Task**: 201 (feature)

## Task Reference
- **Task ID**: internal-201
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/201-bash-tool-check-framework
- **Template Version**: 2.1

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Verified Assumptions (measured against the codebase)
- **PreToolUse stdin carries `session_id`** (top-level, guaranteed), plus `cwd`,
  `transcript_path`, `tool_name`, and `tool_input.command` (the Bash command
  string). Source: official Claude Code hooks docs, confirmed this task. This
  removes the FR4 "session-key may be absent" risk — the documented fallback
  stays as defence-in-depth but is not the primary path.
- **Deny contract**: exit 0 + `{"hookSpecificOutput":{"hookEventName":
  "PreToolUse","permissionDecision":"deny","permissionDecisionReason":<msg>}}`.
  Allow = empty stdout, exit 0. (Matches `pretooluse-planning-write-guard`.)
- **Registration is automatic and unconditional**: `cwf-claude-settings-merge`
  registers ANY `.cwf/scripts/hooks/<file>` listed in the install manifest, with
  `timeout => 5`, reading `cwf-hook-event:` / `cwf-hook-matcher:` directives
  (`cwf-claude-settings-merge:166-185`). Only the two sandbox hooks are
  knob-gated. A second `PreToolUse`/`Bash` hook simply joins the same matcher
  group — no merge-helper code change. The 5 s harness timeout is also a
  fail-open backstop: a hook killed for running too long does not block the call.
- **`.gitignore`** is owned by the `gitignore-entries` `line-additive` artefact
  (`cwf-apply-artefacts:298`); its `lines` array lives in `install-manifest.json`
  (currently `.cwf/task-stack`, `.cwf/.update.lock`, `.cwf/sandbox-violations.log`).
  Adding our pattern = one more array element. Runs at install (`cwf-init`) and
  upgrade (`cwf-manage update`), idempotent by construction.
- **Regex code-injection is already closed**: Perl refuses `(?{...})`/`(??{...})`
  in an interpolated (variable) pattern unless `use re 'eval'` is in scope. We
  NEVER use that pragma, so config-supplied regexes cannot execute code — in any
  layer. This is what lets the checked-in layer safely allow regex rules.
- **`~/.cwf/` user-global root has precedent**: `cwf-config` already establishes
  `~/.cwf/` as the CWF user-global config root (`autoload.yaml`, `utils/`,
  `templates/`) with a documented "project `.cwf/` > global `~/.cwf/` > defaults"
  precedence (`cwf-config/SKILL.md:34-50`). This task adds a `tool-check/bash/`
  subtree under that existing root — it is NOT a new home-dir convention. Like
  the rest of `~/.cwf/`, the dir is user-created/owned, lives outside any repo
  (so no `.gitignore` applies to it), and is NOT on any project integrity
  manifest. The trust posture (FR7(e)) treats it as author-owned accordingly.

## Key Decisions

### Architecture Choice
- **Decision**: A thin Perl PreToolUse hook (`pretooluse-bash-tool-check`) over a
  pure-policy library (`CWF::ToolCheck`) — the same lib/wrapper split as
  `CWF::PlanningGuard` + `pretooluse-planning-write-guard`. The hook does I/O
  (read stdin, locate + read the three config layers, read/write repeat-state,
  run the alarm-bounded match loop, emit the decision); the lib holds the pure,
  unit-testable policy (layer merge, the repeat-bypass decision, provenance-based
  rule filtering, and the data-only PCRE match).
- **Rationale**: mirrors the established, reviewed pattern; keeps the
  security-load-bearing logic testable without a live hook; fail-open is easy to
  guarantee when the wrapper wraps the whole body in `eval` and defaults to empty
  stdout / exit 0.
- **Trade-offs**: two new artefacts (hook + lib) to hash-track, vs a single
  monolithic hook that would be far harder to unit-test. Worth it.

### Scope decision — ship the mechanism, not a rule set ("best part is no part")
- CWF ships the framework + a documented **example** file (schema + one worked
  regex and one worked Perl rule) under `.cwf/docs/`. It ships **zero active
  rules**. The premise of the task is that the offending-command set shifts per
  model / per Claude Code version, so a shipped fixed rule set would be wrong by
  construction. With no rule files present the framework is a strict no-op (FR5).
- **Empty ruleset by default — locked (user decision).** CWF ships NO active
  rules, and this task does NOT seed this repo's own rules either. The framework
  ships inert; any rules are operator-supplied. (Seeding this repo's sed/awk/find
  rules, if ever wanted, is an entirely separate future task.)

### Rule kinds + the trust boundary (FR7(e) — the load-bearing decision)
- Two matcher kinds: `regex` (PCRE, data-only) and `perl` (a `sub { ($cmd,$ctx) }`
  returning truthy).
- **Per-layer trust**:
  | Layer | Path | Travels via `git clone`? | `regex` | `perl` |
  |-------|------|--------------------------|---------|--------|
  | user-global | `~/.cwf/tool-check/bash/settings.json` | no (author machine) | ✅ | ✅ |
  | project checked-in | `{root}/.cwf/tool-check/bash/settings.json` | **yes** | ✅ | **❌ ignored** |
  | project-local | `{root}/.cwf/tool-check/bash/settings.local.json` (gitignored) | no | ✅ | ✅ |
- **Disposition of arbitrary-Perl supply-chain risk**: a `perl` rule in the
  *checked-in* layer is the only vector by which `git clone` could introduce code
  that runs on a collaborator's machine. Therefore `perl` rules are **honoured
  only from the two author-trusted layers that never travel via clone**
  (user-global, project-local). Regex rules are safe in every layer because we
  never enable `re 'eval'`. This removes the RCE without a trust-prompt
  mechanism — the simplest disposition that holds.
- **Compile-time execution is the real hazard (ordered invariant)**: a `perl`
  rule string runs arbitrary code at COMPILE time — a `BEGIN {}` block (or a
  compile-time `while(1)`) inside the string fires the instant the string is
  `eval`-compiled, *before* the coderef is ever invoked. Two consequences the
  implementation MUST honour:
  1. A checked-in-layer `perl` rule is dropped **before its string is ever
     passed to `eval`/compiled** — not compiled-then-filtered. The drop is keyed
     on the rule's PROVENANCE, which is the path the hook loaded the layer from
     (`load_layer($blob, $provenance)` — the hook supplies provenance per file);
     provenance is NEVER read from rule content, so a rule cannot self-assert a
     more-trusted origin.
  2. The wall-clock guard (NFR1) MUST wrap `perl`-rule COMPILATION as well as
     invocation, so a compile-time hang is bounded too.
  Compilation of a trusted-layer `perl` rule happens under `eval`; a compile
  failure (or a runtime die) drops that single rule and fails open — never dies,
  never blocks. ("pre-validated coderef" = one that compiled cleanly under this
  guarded `eval`.)

### Repeat-bypass algorithm (FR4)
Pure decision in `CWF::ToolCheck`; state I/O in the hook. Per session we persist
only the SHA-256 of the last command WE denied. On a Bash call with command `C`
(hash `h`):
1. read `last_denied` for this session (absent ⇒ none);
2. compute whether any merged rule matches `C` (first match wins);
3. **match AND `last_denied == h`** → repeat of a just-denied command → **allow**
   (empty stdout) and clear state [the bypass];
4. **match AND `last_denied != h`** → **deny** with the rule's guidance; set
   `last_denied = h`;
5. **no match** → **allow**; clear `last_denied`.

This satisfies AC3: an intervening different command hits case 4 or 5 and
overwrites/clears the stored hash, so the streak breaks and the next identical
`C` is denied again. After a bypass the state is cleared (no permanent bypass).
State is keyed ONLY by command-hash, never by rule-set identity, so editing or
removing a rule mid-session cannot produce a stale bypass: the worst case is one
extra deny or one extra allow (bounded by NFR5), and SHA-256 makes a cross-command
collision negligible.

### Merge + ordering + hand-error resolution (FR3)
- Layers are read in order **user-global → checked-in → project-local**; later
  layers have higher precedence.
- Rules are keyed by `id`. Merge keeps a single ordered list: a new `id` is
  appended (preserving first-seen evaluation position); a repeated `id` in a
  later layer **replaces the existing entry's fields in place** (position kept,
  so override does not silently reorder evaluation); an entry with
  `"enabled": false` **removes** that `id` from the eval list (the disable
  mechanism).
- **Hand-error resolution** (well-formed JSON the malformed-layer guard won't
  catch): duplicate `id` *within one layer* → last-in-document-order wins
  (consistent with cross-layer "later wins"); an override/disable of an `id` that
  exists in no layer → silent no-op (erroring would risk blocking — fail-open).
- First-match-wins over the final ordered list. Evaluation order is therefore
  fully determined by first-seen position, independent of override timing.

### ReDoS / hang bound (NFR1)
- The whole match loop runs under a single `Time::HiRes::alarm` wall-clock budget
  (default **2 s**, sub-second granularity; `Time::HiRes` is core) comfortably
  below the 5 s harness timeout; `$SIG{ALRM}` → fail-open (empty stdout). This
  bound wraps regex matching AND `perl`-rule COMPILATION AND invocation, so a
  hanging `perl` rule — including a compile-time hang — is covered (robustness F4,
  security F1).
- Defence-in-depth length cap: a command longer than **64 KB** is NOT matched at
  all — it fails open (allow), it is NOT truncated-then-matched. Truncation would
  let an attacker push a denylisted substring past the cap to evade a rule
  (security F3); refusing to match over-cap is the safe direction for an advisory
  deny-framework and avoids that evasion. The cap cheaply bounds backtracking
  input below the point where catastrophic blow-up is plausible.
- The 5 s harness kill is the GUARANTEED backstop if in-process `alarm` fails to
  pre-empt a pathological backtrack mid-match on some Perl build — alarm efficacy
  is build-dependent, so safety does not rest on it (robustness F2/F3). Tests
  MUST assert the TOTAL wall-clock bound (alarm + cap) stays under the harness
  timeout on a known-pathological pattern, not merely that the alarm fires.
- **Rejected**: forking each match into a killable child. Correct but pays a
  fork on every Bash call (the hot path); the alarm + length-cap + harness-kill
  layering is cheaper and sufficient.

## System Design

### Component Overview
- **`pretooluse-bash-tool-check`** (hook, `.cwf/scripts/hooks/`): impure shell.
  Reads stdin JSON; extracts `command`, `session_id`, `cwd`; locates the three
  layer files; delegates merge + decision to the lib; runs the alarm-bounded
  match; reads/writes repeat-state; emits the deny/allow decision. Whole body in
  `eval` → any exception ⇒ allow. Directives: `cwf-hook-event: PreToolUse`,
  `cwf-hook-matcher: Bash`. The hot path is SILENT (no per-call logging — it runs
  on every Bash call, so logging dropped/invalid rules per-call would spam).
- **Surfacing (out of the hot path)**: the hook also supports a `--check`
  invocation that loads + merges the layers and reports, once, what it found —
  dropped checked-in `perl` rules, rules that fail to compile, invalid regexes,
  disabled/overridden ids. This honours "surface, never smooth" without hot-path
  noise and doubles as the user's way to test a rule file. (`--check` is also how
  AC2/AC6 tests inspect merge behaviour.) Documented in the schema doc.
- **`CWF::ToolCheck`** (lib, `.cwf/lib/CWF/`): pure policy. `load_layer($blob,
  $provenance)` (parse + provenance tagging + per-layer `perl`-drop),
  `merge_rules(\@layers)` (ordering + override/disable + dup-id resolution),
  `rule_matches($rule, $cmd)` (data-only PCRE / invokes a pre-validated coderef),
  `decide_repeat($matched, $last_denied, $cur_hash)` (the 5-case algorithm).
- **Repeat-state store**: one file per session under a repo-namespaced tmp dir
  (see Data Models). No lib logic beyond hashing — the hook owns the I/O.
- **Config/manifest integration**: new `lines` entry in `install-manifest.json`
  (gitignore); new hook + lib entries in `install-manifest.json` `scripts` +
  `.cwf/security/script-hashes.json`.

### Data Flow
1. Claude Code is about to run a `Bash` tool call → fires PreToolUse → pipes the
   event JSON to the hook on stdin.
2. Hook parses JSON → `command`, `session_id`, `cwd`. Malformed ⇒ allow.
3. Hook reads the three layer files (absent/unreadable/symlink ⇒ that layer
   contributes nothing); passes blobs + provenance to `CWF::ToolCheck`.
4. Lib merges → ordered rule list (checked-in `perl` rules already dropped).
5. Hook reads `last_denied` for `session_id`; runs the alarm-bounded
   first-match-wins loop via the lib.
6. Lib's `decide_repeat` yields allow / deny(guidance) / bypass.
7. Hook writes/clears repeat-state, then emits the decision (deny JSON, or empty
   stdout). Exit 0 always.

## Interface Design

### Rule file schema (`settings.json` / `settings.local.json`)
```
{
  "rules": [
    {
      "id":       "no-sed-line-range",          // stable, required
      "regex":    "(?:^|[|;&]\\s*)sed\\s+-n",   // PCRE; mutually exclusive with "perl"
      "guidance": "Use Read with offset/limit, not `sed -n 'X,Yp'`."
    },
    {
      "id":       "complex-pipeline-check",
      "perl":     "sub { my ($cmd, $ctx) = @_; return $cmd =~ tr/|// > 3 }",
      "guidance": "Long pipelines trip permission prompts; write a scratch script."
    },
    { "id": "no-sed-line-range", "enabled": false }   // disable a lower-layer rule
  ]
}
```
- Exactly one of `regex` / `perl` per active rule; `guidance` required for an
  active (non-disable) rule. Unknown keys ignored (forward-compatible).
- A `perl` rule in the checked-in layer is dropped (never compiled), per the
  documented trust policy — silently in the hot path (see surfacing below).
- A `perl` rule's coderef receives `($cmd, $ctx)` where `$ctx` is exactly
  `{ cwd => <string> }` — a bounded, documented context (the call's cwd from the
  PreToolUse payload), not an open grab-bag. Rules that don't need it ignore it.

### Hook I/O contract
- **In** (stdin JSON): `session_id`, `cwd`, `tool_name`, `tool_input.command`.
- **Out (deny)**: exit 0 + `hookSpecificOutput` deny with
  `permissionDecisionReason` = the matched rule's `guidance` **verbatim** —
  never a reflected `tool_input` value (FR7(c)).
- **Out (allow / bypass / any error)**: empty stdout, exit 0.

### Data Models — repeat-state
- **Dir**: `${TMPDIR:-/tmp}/<dashified-repo-root>-tool-check/`, created
  `mkdir -m 0700` on first use (tmp-paths convention: symlink/TOCTOU guard).
- **File**: `<session_id>.last`, written 0600 atomically, content = hex SHA-256
  of the last denied command.
- **session_id sanitisation**: accepted only if it matches
  `^[A-Za-z0-9._-]{1,200}$` (no `/`, no `..`); otherwise treated as "no state"
  (always evaluate, never bypass — safe degrade, FR7(d)).
- **Concurrency**: per-session file ⇒ no cross-session clobber. Within a session
  a same-file race can only mis-fire the bypass once (extra deny or extra allow),
  never a hang or hard block — fail-open (NFR5).

## Constraints
- Core Perl only (`JSON::PP`, `Digest::SHA`, `Time::HiRes`, `POSIX`, `FindBin`,
  `File::Spec`/`Cwd` — all core); `use utf8;`; never `use re 'eval'`.
- PCRE-only regex; output conforms to the PreToolUse JSON contract.
- Reuse: settings-merge registration (no code change), `gitignore-entries`
  artefact, integrity manifest. New user-global root is `~/.cwf/` (not `~/.claude/`).

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [x] **Complexity**: engine + config/merge + install — but unchanged from
      planning; tightly coupled.
- [ ] **Risk**: arbitrary-Perl risk now has a concrete, simple disposition
      (checked-in layer = no `perl`); no longer needs isolation.
- [x] **Independence**: separable, but coupling argues for one task.

**Assessment**: proceed as one task (unchanged).

## Validation
- [x] Design review completed (4-subagent map/reduce, below)
- [x] Integration points verified against the actual codebase (see Verified
      Assumptions)
- [ ] Architecture approved by the maintainer

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
The pure-policy-lib + thin-I/O-hook split was implemented as designed. The provenance-keyed
perl drop, three-layer merge, and repeat-bypass state machine all matched the design with
one minor deviation (`rule_matches` gained a 4-arg `$ctx`, recorded in f-implementation-exec.md).

## Lessons Learned
Mirroring `CWF::PlanningGuard` / `pretooluse-planning-write-guard` gave a tested structure,
the hook JSON contract, and integrity registration without rediscovery. The trust boundary
(gate before `eval`, keyed on caller-derived provenance) was the load-bearing design choice
and the security review endorsed it unchanged.
