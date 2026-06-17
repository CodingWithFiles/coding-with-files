# Fix normalise wrapped-field stranding - Implementation Plan
**Task**: 208 (bugfix)

## Task Reference
- **Task ID**: internal-208
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/208-fix-normalise-wrapped-field-stranding
- **Template Version**: 2.1

## Goal
Implement the index-walk fold in `_canonicalise_entry_inplace` per the approved design
(KD1–KD3a), so hard-wrapped legacy `**Field**:` values normalise to one
`### Field: value` with nothing stranded.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `/home/matt/repo/coding-with-files/.cwf/scripts/command-helpers/backlog-manager`
  — rewrite `_canonicalise_entry_inplace` (lines 525-548): replace the per-line `for`
  loop with an index walk that folds continuation lines into the field value
  (KD1/KD2). Subsection `---`-strip loop unchanged.

### Supporting Changes
- `/home/matt/repo/coding-with-files/t/backlog-manager.t` — add a wrapped-field
  subtest under the AC18 block (~line 967), covering the KD3 fixture matrix.
- `/home/matt/repo/coding-with-files/.cwf/security/script-hashes.json` — refresh the
  `backlog-manager` hash in the **same commit** as the edit (hash-update convention).

## Implementation Steps
### Step 1: Setup
- [ ] On branch `bugfix/208-fix-normalise-wrapped-field-stranding`; re-read c-design KD1–KD3a.

### Step 2: Core Implementation
- [ ] Rewrite `_canonicalise_entry_inplace` per "Code Changes" below.
- [ ] Left- and right-trim each consumed continuation; join with single space; honour
      seed-empty (no leading space when value starts empty).
- [ ] Leave the subsection `---`-strip loop and `trim_blank_lines` calls untouched.

### Step 3: Testing
- [ ] Add the KD3 wrapped-field subtest (see e-testing-plan.md for the matrix).
- [ ] `prove -lr t/backlog-manager.t` green; then full `prove -lr t/` for no regressions.

### Step 4: Hashes & integrity
- [ ] Refresh `backlog-manager` hash; `cwf-manage validate` → OK (same commit as edit).

### Step 5: Validation
- [ ] Exec-phase changeset review (security + best-practice) per f-implementation-exec.
- [ ] Idempotency: run `normalise` twice on the fixture; second run byte-identical.

## Code Changes
### Before (`backlog-manager:525-536`, entry-level loop)
```perl
sub _canonicalise_entry_inplace {
    my ($entry, $changed) = @_;
    my @new_body;
    for my $line (@{$entry->{body_raw} // []}) {
        if ($line =~ /^\*\*($CWF::Backlog::METADATA_KEY_RE)\*\*:[ \t]*(.*?)\s*\z/) {
            push @{$entry->{metadata}}, { key => $1, value => $2, lineno => undef };
            $$changed = 1;
            next;
        }
        if ($line =~ /^---\r?\n?\z/) { $$changed = 1; next; }
        push @new_body, $line;
    }
    # ... trim + subsection loop unchanged ...
```

### After (entry-level loop → index walk with fold)
```perl
sub _canonicalise_entry_inplace {
    my ($entry, $changed) = @_;
    my @new_body;
    my $body = $entry->{body_raw} // [];
    my $i = 0;
    while ($i < @$body) {
        my $line = $body->[$i];
        if ($line =~ /^\*\*($CWF::Backlog::METADATA_KEY_RE)\*\*:[ \t]*(.*?)\s*\z/) {
            my ($key, $value) = ($1, $2);
            # Fold hard-wrapped continuation lines into the value until a
            # terminator: next field, blank line, '---', or end of body (KD2).
            while ($i + 1 < @$body) {
                my $next = $body->[$i + 1];
                last if $next =~ /^\*\*$CWF::Backlog::METADATA_KEY_RE\*\*:/;
                last if $next =~ /^\s*$/;          # blank / whitespace-only
                last if $next =~ /^---\r?\n?\z/;   # separator
                (my $cont = $next) =~ s/^\s+//;    # drop wrap indentation
                $cont =~ s/\s+\z//;                # drop trailing ws incl. \n
                $value = length $value ? "$value $cont" : $cont;  # seed-empty: no leading space
                $i++;
            }
            push @{$entry->{metadata}}, { key => $key, value => $value, lineno => undef };
            $$changed = 1;
            $i++;
            next;
        }
        if ($line =~ /^---\r?\n?\z/) { $$changed = 1; $i++; next; }
        push @new_body, $line;
        $i++;
    }
    # trim + subsection loop unchanged from here
```

Notes:
- The look-ahead's field regex omits the capture (it only tests for a terminator); the
  capturing form stays on the outer match that actually promotes.
- `^\s*$` matches blank and whitespace-only lines (repo convention, cf.
  `backlog-manager:557`). `\s` spans the trailing `\n`, so no separate newline alt needed.
- Single-line fields: inner `while` finds an immediate terminator (or EOF) and never
  iterates → behaviour identical to today.
- **The trailing `next` in the field branch is load-bearing — do not remove.** The two
  promotion/`---` branches are independent `if`s followed by an unconditional
  `push @new_body, $line`; without `next` a just-promoted field line would also be
  re-appended to the body. (Plan review flagged it as cosmetic; it is not.)

## Test Coverage
**See e-testing-plan.md for the complete KD3 fixture matrix and assertions.**

## Validation Criteria
**See e-testing-plan.md for validation criteria and results.**

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
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
