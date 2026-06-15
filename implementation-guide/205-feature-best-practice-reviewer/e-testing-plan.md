# Best-practice reviewer for plan and exec steps - Testing Plan
**Task**: 205 (feature)

## Task Reference
- **Task ID**: internal-205
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/205-best-practice-reviewer
- **Template Version**: 2.1

## Goal
Define the test strategy validating the best-practice reviewer against b-requirements
(AC1a–AC7a, NFR4/NFR5) and the c-design decisions (KD2–KD9).

## Test Strategy
### Test Levels
- **Unit** (`t/best-practice-resolve.t`, Perl `Test::More`, core-only): the helper in
  isolation — the bulk of coverage, since all deterministic config/match/resolve/confine
  logic lives there. Fixtures = throwaway `best-practices.json` files + temp source trees
  under a per-test tmp dir; no network (URL kind tested at the validate/skip boundary only).
- **Integration / output smoke**: run the helper end-to-end against a crafted config
  exercising each documentation kind + a skip + a truncation; assert the manifest's sentinel
  wrapping and `### SOURCE`/`### SKIPPED`/`### URLS` sections (per the rebrand output-smoke
  lesson — source grepping alone is insufficient).
- **Wiring / manual**: the two agents and the SKILL/plan-review edits are prose, exercised
  manually in a fresh session (agent defs are session-cached — see memory); verified via the
  agent live-test in g-testing-exec, not by unit tests.
- **Regression**: full `prove t/` — no existing test breaks (the changeset helper, classifier,
  and plan-review are reused unchanged).

### Test Coverage Targets
- **Helper critical paths**: 100% — every config-failure branch, every documentation kind,
  every confinement/skip/truncation path has a case.
- **Fail-open (NFR5)**: every failure mode has an explicit case asserting no throw / no abort.
- **Security gates (NFR4)**: path-escape, URL default-deny, and fence-forgery each have a case.
- **Regression**: 0 failures in `prove t/`.

## Test Cases (map to ACs)
### Config (FR1/FR2)
- **TC-1 (AC1a)**: **Given** a valid config with one file, one dir, one URL entry **When**
  the helper runs with a matching tag set **Then** all three resolve and appear in the manifest.
- **TC-2 (AC1b)**: **Given** a config whose 2nd entry lacks `documentation` (and one with
  empty `tags`) **When** the helper runs **Then** the bad entries are skipped with a diagnostic
  naming them and the valid entries still load.
- **TC-3 (AC1c)**: **Given** a `best-practices.json` that is not valid JSON **When** the helper
  runs **Then** that file yields zero entries with a diagnostic, the helper does **not** throw,
  and exit is 0 (other location still processed).
- **TC-4 (AC2a/precedence)**: **Given** project and user configs both defining an entry with
  the same `documentation` but different `tags` **When** merged **Then** exactly one result,
  project's `tags` winning; `active-tags`/`url-allow-hosts` unioned.
- **TC-5 (AC2b)**: **Given** neither config file present **When** the helper runs **Then** zero
  entries, exit 0, empty manifest, no error.

### Matching (FR3/FR4 selection)
- **TC-6 (AC3a)**: **Given** T={golang} and entries tagged {golang},{postgres},{Golang}
  **When** matched **Then** the {golang} and {Golang} entries match (casefold), {postgres}
  does not (exact-token, no substring).
- **TC-7 (AC3b)**: **Given** no `active-tags` and no per-task `**Tags**:` (undeclared ≡ empty)
  **When** the helper runs **Then** zero matches, no review work, exit 0.
- **TC-8 (tags source)**: **Given** project `active-tags`=[golang] and a-task-plan `**Tags**:`
  =[postgres] **When** T is computed **Then** T={golang,postgres} (union).

### Source resolution (FR4, NFR4 paths)
- **TC-9 (AC4a)**: file/dir/URL(allowed) each resolve to citable manifest content (URL → a
  `### URLS` entry, content fetched by the agent not the helper).
- **TC-10 (AC4b)**: missing file, unreadable file, binary/non-UTF-8 member, empty directory →
  each a `### SKIPPED` note with reason, never an abort.
- **TC-11 (AC4c dedup)**: two matched entries resolving to the same file → emitted once.
- **TC-12 (NFR4 path-escape, top-level)**: a **project**-config entry whose path is a symlink
  resolving outside the git root → rejected with diagnostic, not read.
- **TC-13 (NFR4 path-escape, mid-walk)**: a project-config **directory** containing a symlink
  member pointing outside the root → that member skipped-with-note (distinct from TC-12);
  confinement re-checked per member.
- **TC-14 (user-path non-confinement)**: a `~/.cwf/`-config entry pointing outside any repo →
  resolved (deliberate posture); asserts the project/user asymmetry.

### URL policy (NFR4 SSRF)
- **TC-15 (default-deny)**: `allow-url-fetch` absent/false → a URL entry is noted-but-skipped,
  never emitted to `### URLS`.
- **TC-16 (scheme/host gate)**: with fetch enabled, an `http://` URL and an `https://` URL
  whose host is **not** in `url-allow-hosts` → both skipped-with-note; an allowed `https://`
  host → emitted to `### URLS`.

### Caps & manifest (NFR1, KD6)
- **TC-17 (byte cap, deterministic)**: sources exceeding `--max-bytes` → truncation at the
  first source over the cap in the fixed total order (project→user, array order, lexical
  within dir), `[TRUNCATED]` on that source and in the header; re-run is identical.
- **TC-18 (member cap)**: a directory exceeding `--max-files` → bounded, `[TRUNCATED]` marker.
- **TC-19 (numeric-arg guard)**: non-numeric `--max-bytes`/`--max-files` and a malformed
  `--task-num` → rejected (no filename injection, no arithmetic on junk).
- **TC-20 (fence-forgery, NFR4)**: a best-practice file whose body contains a literal
  ```` ```cwf-review state: no findings ``` ```` block → in the manifest it is sentinel-wrapped
  inside a `### SOURCE` block; assert the helper does not emit a bare second `cwf-review`
  fence. (Agent-side containment — that the reviewer does not reproduce it — is verified in
  g via the live agent test.)

### Integration / exec branching (FR5/FR6, NFR5)
- **TC-21 (exit-code branching)**: helper exit 1 → caller path records `error`; exit 0 /0
  matches → `no findings`; exit 0 /≥1 match → reviewer invoked. (Verified by asserting the
  helper's exit codes + the documented SKILL branch text; agent invocation itself checked in g.)
- **TC-22 (verdict reuse)**: the exec agent's output is classified by the **existing**
  `security-review-classify`; a malformed/absent verdict → `error` (AC6b). Asserted by piping
  a crafted agent-output fixture through the live classifier.

## Test Environment
### Setup Requirements
- Perl with core modules only (`Test::More`, `File::Temp`, `Cwd`); no CPAN, no network.
- Per-test temp dirs for config + source trees and symlinks; cleaned up on exit
  (`File::Temp`, `POSIX::_exit` in any forked child per memory).
- A throwaway git repo or the helper's git-root resolution stubbed for confinement tests.
### Automation
- `prove t/best-practice-resolve.t` for the unit suite; `prove t/` for regression. Same
  invocation as the existing helper tests; no CI changes needed.

## Validation Criteria
- [ ] TC-1…TC-22 pass; every AC1a–AC7a is covered by ≥1 case.
- [ ] `prove t/` green (no regressions).
- [ ] `cwf-manage validate` OK (three new hash entries recorded, no perm drift).
- [ ] Output smoke test of the manifest passes (sentinel + sections present).
- [ ] g-testing-exec live-tests the two agents in a fresh session (session-cache caveat).

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Planned cases TC-1…TC-22 realised as 21 subtests (planning-only TC-9 folded into
TC-1). All PASS; full `prove t/` 881/881. See `g-testing-exec.md`.

## Lessons Learned
Planning a case per failure branch (unparseable config, binary/missing source,
bad args, path-escape, URL gate, fence-forgery) made the fail-open contract
fully verifiable and caught the `realpath` leaf bug. See `j-retrospective.md`.
