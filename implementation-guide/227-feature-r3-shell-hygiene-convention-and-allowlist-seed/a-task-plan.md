# R3 shell-hygiene convention and allowlist seed - Plan
**Task**: 227 (feature)

## Task Reference
- **Task ID**: internal-227
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/227-r3-shell-hygiene-convention-and-allowlist-seed
- **Baseline Commit**: 8dce3a65b4b62bc02a4a5ecc513c7cee0c9135d4
- **Template Version**: 2.1

## Goal
Deliver the two remaining R3 deliverables so a **new** CwF-using project inherits the
shell-hygiene guidance the maintainer's corpus re-derived across 601 retrospectives,
instead of learning it prompt-by-prompt.

**Why (intent):** Task 219 found the same ~10 shell-avoidance rules (heredoc avoidance,
`chmod && execute`, no `perl -c`, read/grep over `sed`/`awk`, NUL-safe git paths, the
`sleep 1 && git` prefix, etc.) being independently re-derived across projects, wasting
prompts and tripping permission gates. Task 220 already shipped the **tool-check**
mechanism (deny/warn hook + seed + toggle + `cwf-init` opt-in). Two R3 deliverables
remain, and they are the *documentation* and *friction-reduction* halves — distinct from
tool-check's *enforcement* half.

**Explicit request:** Implement the remainder of R3 — namely (verbatim from the backlog
Remaining-scope note): "the broader shell-hygiene **convention** doc and the Bash
**allowlist seed** (distinct from tool-check)."

<!-- Scope note surfaced to owner: R3 originally had THREE parts. Part 3 (the Task-206
     path-injection hook at cwf-init) is NOT in this task's scope — the backlog Remaining
     note names only the convention doc and the allowlist seed, and the hook-rooting class
     was addressed by Task 224 (R7). Flagging, not resolving: say so if part 3 should be
     folded in. Premise caveat (also from the backlog): the "new projects re-derive them
     all" driver is partly stale for THIS maintainer, whose Jul-2026 user-global ruleset
     already enforces these everywhere; the beneficiary of a *checked-in* seed + doc is a
     new/other CwF project without that user-global setup. -->

## Success Criteria
- [ ] A shipped shell-hygiene **convention doc** exists under `.cwf/docs/conventions/`
      (binding on all CwF-using projects), consolidating the generalisable shell-avoidance
      rules with a one-line rationale each, and is referenced from the appropriate
      skill/agent-rules surface so it is discoverable at runtime (not an orphan file).
- [ ] A default **Bash allowlist seed** is applied at `cwf-init`, permitting only
      read-only commands and `.cwf/` helper invocations — **no mutating verbs**
      (`git commit`, `rm`, `mv`, writes, network) — verifiably narrower than "allow all".
- [ ] The allowlist seed is **additive and reversible**: seeding into an existing
      `.claude/settings*.json` never clobbers or reorders a user's existing permission
      entries, and a project that declines the seed is byte-for-byte unchanged.
- [ ] The convention doc curates **generalisable** rules and explicitly excludes
      maintainer-personal taste items (decision recorded in requirements), so it reads as
      project-neutral guidance rather than one person's preferences.
- [ ] Both deliverables carry tests proving the shape (doc referenced + present; seed
      applied/skipped correctly; no mutating verb present in the seed).

## Original Estimate
**Effort**: N/A — calendar estimate treated as noise (Task 219 S7 finding; Task 220 precedent)
**Complexity**: Medium
**Dependencies**: `cwf-init` config-seeding path (shared with Task 220/221 seeds);
`.cwf/docs/conventions/` shipped-convention location; the merge semantics of whatever
settings file the allowlist lands in.

## Major Milestones
1. **Rule curation**: Enumerate the candidate shell-hygiene rules from the corpus/MEMORY
   feedback set and decide which generalise vs which are maintainer-personal (requirements).
2. **Convention doc**: Author the consolidated `.cwf/docs/conventions/` doc and wire a
   runtime reference to it.
3. **Allowlist seed**: Add the read-only/`.cwf`-only seed to the `cwf-init` flow, additive
   and reversible, reusing the existing seed-application path where possible.
4. **Verify**: Tests for doc presence+reference and seed apply/skip/no-mutating-verb.

## Risk Assessment
### High Priority Risks
- **Allowlist widens default-permitted commands** (the R3 source's stated tradeoff): a
  careless seed could pre-authorise a mutating command and remove a safety prompt.
  - **Mitigation**: Hard-constrain the seed to read-only + `.cwf/` helpers; add a test
    asserting no mutating verb / network / write command is present; keep it additive so a
    user's stricter settings win.
- **Seed clobbers a user's existing `.claude/settings*.json`**: naive write destroys
  hand-tuned permissions or harness-owned keys.
  - **Mitigation**: Merge additively via the existing symlink-safe settings-writer path
    (per Task 220's atomic-writer work); treat the harness-owned `settings.local.json` as
    off-limits (MEMORY: two-writer clobber). Design phase picks the exact target file.

### Medium Priority Risks
- **Convention doc becomes a stale duplicate** of the scattered MEMORY feedback items and
  the tool-check regex set, drifting from them over time.
  - **Mitigation**: Doc states generalisable *principles* and points at tool-check for
    enforcement rather than re-listing regexes; single-source where a rule already lives.
- **Curation over-includes maintainer-personal rules**, shipping one person's taste as a
  universal convention.
  - **Mitigation**: Explicit include/exclude decision in requirements with rationale per rule.

## Dependencies
- The `cwf-init` seeding mechanism and config templates touched by Tasks 220/221.
- The shipped-convention directory contract (`.cwf/docs/conventions/`) and its runtime
  reference points (skills / agent-shared-rules).
- Existing symlink-safe atomic settings-writer(s) noted in Task 220's retrospective.

## Constraints
- Convention binds on all CwF users → doc lives in `.cwf/docs/conventions/`, not the
  maintainer-only `docs/conventions/` (per CLAUDE.md split).
- Any edit to a hashed `.cwf/` script refreshes `script-hashes.json` in the same commit.
- Reuse the existing seed/settings-write path; do not introduce a second writer.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No.
- [ ] **People**: Does this need >2 people working on different parts? No.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — two (doc, seed).
- [ ] **Risk**: Are there high-risk components that need isolation? The seed carries a
      permission-widening risk, but it is contained by the read-only constraint — not
      isolation-worthy.
- [x] **Independence**: Can parts be worked on separately? Yes — the doc and the seed are
      independent. But both are small and share the `cwf-init`/conventions context, so a
      single task is the lower-overhead choice. **1 signal → no decomposition.**

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five success criteria met. The convention doc (`.cwf/docs/conventions/shell-hygiene.md`)
ships and is referenced from the FR3 anchor in `cwf-agent-shared-rules.md` and this repo's
`CLAUDE.md`. The read-only seed rides the existing `merge_allow` path (additive + idempotent,
5 entries, no mutating verb). Scope held exactly to the two named remainders; R3 part 3 stayed
out (Task 224). Merge to main is the only outstanding action (human-only).

## Lessons Learned
The plan correctly predicted the complexity would sit in the seed's *safety framing*, not its
mechanics — the exact-vs-prefix `git branch` call and the independent test gate were where the
work landed. See `j-retrospective.md` for the full analysis.
