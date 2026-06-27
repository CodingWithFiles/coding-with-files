# classify auto-discover review outputs - Implementation Plan
**Task**: 214 (chore)

## Task Reference
- **Task ID**: internal-214
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/214-classify-auto-discover-outputs
- **Template Version**: 2.1

## Goal
Add an additive `--dir`/`--phase` discovery mode to `security-review-classify` that classifies every `*-review-output-<phase>.out` file in one literal, allowlist-matching invocation, while leaving the existing `stdin → one token` contract byte-identical.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Design Decisions (no separate design phase for chore)

### CLI surface
- **stdin mode (unchanged, default)**: no positional/flag args ⇒ slurp STDIN, print exactly one canonical token. The SubagentStop hook (`exec { $classifier } $classifier` — no args) and all single-file `< file` callers keep working untouched.
- **discovery mode (new)**: `security-review-classify --dir <DIR> --phase <PHASE>`. Both flags required together; supply one without the other ⇒ usage error (exit 1). `--dir=<X>`/`--phase=<Y>` `=`-forms also accepted. This is a single literal argv — no loop, no `$var`, no redirect — so it matches the existing allowlist entry `Bash(.cwf/scripts/command-helpers/security-review-classify:*)` and raises no prompt.

### Discovery rule
- In `<DIR>`, match names `^(.+)-review-output-<PHASE>\.out$` (PHASE regex-quoted with `\Q…\E`). `readdir` + regex (not shell glob) per repo conventions. Capture the reviewer name (group 1) and the canonical pattern in **one pass** — build `[$reviewer, $file]` pairs from the single match, so the `-review-output-<phase>.out` pattern is written in exactly one place (no looser second regex inside the loop). The `-review-output-` infix excludes the large `*-review-changeset-<phase>.out` diff inputs that share the dir; the `<PHASE>` suffix scopes to the current phase so implementation-exec and testing-exec outputs in the same task scratch dir never cross-contaminate.
- **Skip symlinks and non-regular entries**: filter name-match first, then `-f "$dir/$_" && ! -l "$dir/$_"` (lstat-based — `-f` alone follows a symlink-to-regular-file, contradicting the skip intent and the test case). Scratch `.out` files are always Write-tool regular files; a matching symlink/subdir is anomalous and is skipped.
- Process matches in **lexical filename order** for deterministic output.

### Output format (discovery mode)
- One line per discovered file: `<reviewer>: <token>` where `<reviewer>` is capture group 1 (e.g. `security`, `best-practice`, `improvements`, `robustness`, `misalignment`) and `<token>` is the canonical verdict from the **same** parser used by stdin mode. The reviewer token is passed through **verbatim** — the helper does not validate it against a roster; the SKILL owns roster/count validation.
- **Per-file read failure is not silent**: if a matched, regular file fails to open, emit `<reviewer>: error` (consistent with "per-line `error` is the signal") plus an `[CWF] WARNING:` stderr line — never a bare `next` that drops the reviewer.
- Zero matches ⇒ print nothing to stdout, emit one `[CWF] WARNING:` line to stderr naming the dir/phase (explicit, not silent). The skill cross-checks line-count against the number of reviewers it launched; on a shortfall it records the missing reviewer's section as `error` (surface, never smooth — honours the "every section always emitted" invariant).
- Duplicate reviewer prefixes are not expected (one file per reviewer); if two files yield the same capture group the helper emits both lines unchanged and the SKILL count cross-check surfaces the anomaly.
- Exit 0 always (token, including per-line `error`, is the signal — consistent with stdin mode).
- `--phase` is **not** validated against a canonical step set (unlike the sibling `security-review-changeset --wf-step`): an out-of-set phase is harmless by design — it simply matches nothing and takes the zero-match warning path.

### Single-parser invariant
- Refactor the existing block-walking logic (current lines 68–116) into one sub `classify_text($input) → $token`. Both modes call it. This **preserves** the "one parser, no drift" guarantee (the whole reason the helper exists, Task 162) — discovery mode adds I/O around it, not a second parser.

## Files to Modify
### Primary Changes
- `.cwf/scripts/command-helpers/security-review-classify` — add arg parsing for `--dir`/`--phase`; extract `classify_text()`; add discovery loop (readdir + regex + per-line emit). stdin path unchanged.

### Supporting Changes
- `.claude/skills/cwf-implementation-exec/SKILL.md` — replace the per-file `classify ... < <file>` instruction (Step 8 "Classify + record") with the single discovery-mode invocation. Include the explicit **capture-group → section-heading** map (load-bearing for correct recording): `security → ## Security Review`, `best-practice → ## Best-Practice Review`, `improvements → ## Improvements Review`, `robustness → ## Robustness Review`, `misalignment → ## Misalignment Review`. State the launched-vs-classified cross-check and its failure action: any launched reviewer with no output line is recorded `error`.
- `.claude/skills/cwf-testing-exec/SKILL.md` — same edit for the 2-reviewer testing-exec set (`security`, `best-practice` only).
- `.cwf/docs/skills/security-review.md`, `.cwf/docs/skills/best-practice-review.md` — update the usage snippet to document both modes (keep the stdin form; add discovery form).
- `.cwf/security/script-hashes.json` — refresh the `security-review-classify` SHA256 **in the same commit** as the helper edit (hash-update convention).
- `t/security-review-classify.t` — extend with discovery-mode cases (see Test Coverage).

No named symbol is deleted (the block-walk logic moves into a sub within the same file; no cross-file reference changes). No `**Deletes**:` line required.

## Implementation Steps
### Step 1: Helper — refactor parser, add discovery mode
- [ ] Extract the block-walk into `sub classify_text { my ($input) = @_; ... return $token }`; stdin path becomes `print classify_text(slurp STDIN), "\n"`.
- [ ] Add arg parsing: collect `--dir`/`--phase` (both `space` and `=` forms); keep `--help`/`-h`; reject unknown args as today. Neither flag ⇒ stdin mode; exactly one ⇒ usage error; both ⇒ discovery mode.
- [ ] Discovery: `opendir`; in one pass select name-matches `^(.+)-review-output-\Q$phase\E\.out$` then keep only `-f && ! -l`; sort by filename; for each, slurp + `classify_text` + print `"$reviewer: $token\n"`. On per-file open failure print `"$reviewer: error"` + stderr warning (no bare `next`).
- [ ] Zero matches ⇒ stderr `[CWF] WARNING: security-review-classify: no *-review-output-<phase>.out files in <dir>`; exit 0.
- [ ] Update **both** the leading usage/contract comment **and** the `usage()` sub string to document both modes (and note the `--dir`-is-trusted-scratch-path invariant for future reusers).

### Step 2: Refresh hash
- [ ] `cwf-manage fix-security` (or targeted hash refresh) to update `script-hashes.json`; restore working perms to the recorded `0500` (not 0700) per the hashed-script-perms rule.

### Step 3: Skills + docs
- [ ] Edit the two exec SKILLs and the two `.cwf/docs/skills/*-review.md` snippets per Files to Modify.

### Step 4: Tests
- [ ] Extend `t/security-review-classify.t` (see Test Coverage); run the full `t/` suite for regressions.

### Step 5: Validation
- [ ] `cwf-manage validate` OK; empirical no-prompt check of the literal discovery invocation against the allowlist.

## Code Changes
### Before (stdin only)
```perl
# ... arg loop rejects all non-help args ...
my $input = do { local $/; <STDIN> };
# ... 50 lines of block-walk inline ...
if (@valid_states == 1) { print "$valid_states[0]\n" }
else                    { print "error\n" }
exit 0;
```

### After (two modes, one parser)
```perl
sub classify_text {
    my ($input) = @_;
    # ... the existing block-walk, returning the token ...
    return (@valid_states == 1) ? $valid_states[0] : 'error';
}

# ... parse --dir/--phase ...
if (defined $dir) {                              # discovery mode
    opendir(my $dh, $dir) or do { warn "[CWF] WARNING: ...\n"; exit 0 };
    # one pass: capture reviewer + canonical pattern, then lstat-filter
    my @pairs =
        sort { $a->[1] cmp $b->[1] }
        grep { -f "$dir/$_->[1]" && ! -l "$dir/$_->[1]" }
        map  { /^(.+)-review-output-\Q$phase\E\.out$/ ? [$1, $_] : () }
        readdir $dh;
    warn "[CWF] WARNING: ... no *-review-output-$phase.out in $dir\n" unless @pairs;
    for my $p (@pairs) {
        my ($who, $f) = @$p;
        if (open my $r, '<', "$dir/$f") {
            my $in = do { local $/; <$r> };
            print "$who: ", classify_text($in), "\n";
        } else {
            warn "[CWF] WARNING: cannot read $dir/$f: $!\n";
            print "$who: error\n";
        }
    }
    exit 0;
}
print classify_text(do { local $/; <STDIN> }), "\n";   # stdin mode (unchanged behaviour)
exit 0;
```

## Test Coverage
Extend `t/security-review-classify.t` (full plan in e-testing-plan.md):
- **Regression**: all existing stdin cases still pass byte-for-byte.
- **Discovery happy path**: a temp dir with three `*-review-output-implementation-exec.out` files of mixed states ⇒ three sorted `<reviewer>: <token>` lines.
- **Phase scoping**: a `*-review-output-testing-exec.out` and a `*-review-changeset-implementation-exec.out` in the same dir are **ignored** when `--phase implementation-exec`.
- **Zero matches**: empty/irrelevant dir ⇒ empty stdout, stderr warning, exit 0.
- **Symlink/non-regular skip**: a subdir matching the name pattern, **and a symlink-to-regular-file** matching it, are both skipped (pins the `! -l` decision).
- **Open failure → `error` line**: a matched regular file that cannot be opened yields `<reviewer>: error` + stderr warning, not a dropped line.
- **Unknown-arg rejection (regression pin)**: an unrecognised flag ⇒ exit 1 (no current test covers this; add one so the preserved rejection is pinned).
- **Arg errors**: `--dir` without `--phase` (and vice-versa) ⇒ exit 1 usage.

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Implemented as designed — `classify_text()` extraction (single-parser invariant intact), `--dir`/`--phase` parser, one-pass `[reviewer,file]` capture with `-f && ! -l` filter, lexical emit, zero-match + per-file-failure warnings. See f-implementation-exec.md for step-by-step results.

## Lessons Learned
The `--dir` vs sibling `--task-num`/`scratch_dir()` divergence (flagged by two exec reviewers) was a conscious trade, deferred as an optional alignment follow-up. See j-retrospective.md.
