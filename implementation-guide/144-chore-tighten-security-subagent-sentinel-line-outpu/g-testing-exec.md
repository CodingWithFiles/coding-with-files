# Tighten security-subagent sentinel-line output - Testing Execution
**Task**: 144 (chore)

## Task Reference
- **Task ID**: internal-144
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/144-tighten-security-subagent-sentinel-line-output
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps
- [x] Update status to "Testing" when in progress, "Finished" when all pass

## Test Results

### Functional Tests

| Test ID | Test Case                                          | Expected                                                      | Actual                                                  | Status | Notes                                                      |
|---------|----------------------------------------------------|---------------------------------------------------------------|---------------------------------------------------------|--------|------------------------------------------------------------|
| TC-1    | Frontmatter integrity (`head -5`)                  | Original `---`/name/description/allowed-tools/`---` block     | Block intact, unchanged from baseline                   | PASS   | `head -5` output identical to pre-edit                     |
| TC-2    | Sentinel tokens preserved verbatim                 | 3 matches: `findings:`, `no findings`, `error:`               | 3 matches, exact spelling                               | PASS   | Classifier contract preserved                              |
| TC-3    | New wording present (`VERY FIRST` + `sentinel`)    | ≥1 match on a sentinel-context line                           | 1 match: `**Your VERY FIRST output line MUST be …`      | PASS   | Strengthening landed                                       |
| TC-4    | Old wording absent (`Start your response…`)        | 0 matches                                                     | 0 matches                                               | PASS   | Loose wording fully replaced                               |
| TC-5    | Pattern-based-risk carve-out preserved             | ≥1 match for `safe here because`                              | 1 match (full carve-out paragraph intact)               | PASS   | Out-of-scope content untouched                             |
| TC-6    | "do not paraphrase" sentence preserved             | ≥1 multiline match for `do not[\s\n]+paraphrase`              | 1 match                                                 | PASS   | Parser-contract sentence intact                            |
| TC-7    | Dogfood — primary-rule classification on clean diff | First non-blank line begins with a sentinel; primary fires    | `no findings` (first line) — primary rule fired twice (f-phase + g-phase reviews) | PASS   | See **Security Review** below — agent returned `no findings` as the literal first line on both invocations |

### Non-Functional Tests

| Check                          | Expected                                              | Actual                                          | Status | Notes                                                                                  |
|--------------------------------|-------------------------------------------------------|-------------------------------------------------|--------|----------------------------------------------------------------------------------------|
| `cwf-manage validate`          | exit 0, no SECURITY / WORKFLOW violations             | exit 0 after remediation (see "Test Failures") | PASS   | Initial run reported 10 violations; user-approved remediations applied                  |
| `git diff --stat` (ex. task dir) | Single in-scope file + ledger entry                  | 2 files: agent (+8/-3) + script-hashes.json (+1/-1) | PASS   | Ledger update is the legitimate consequence of the intentional edit                    |

## Test Failures

### Initial `cwf-manage validate` run — 10 violations surfaced

The first `cwf-manage validate` run after the f-phase edit reported 10 violations:

1. **1× SHA mismatch** on `.claude/agents/cwf-security-reviewer-changeset.md` —
   caused by the intentional edit in f-implementation-exec. The ledger
   entry in `.cwf/security/script-hashes.json` still held the pre-edit
   hash `ef971059…6340630a`.
2. **1× permission violation** on the same file — the Edit tool wrote
   the file back with 0600 (default umask) instead of the recorded
   0444.
3. **6× pre-existing permission violations** on
   `.claude/agents/cwf-plan-reviewer-{improvements,misalignment,robustness,security}.md`
   and `.cwf/docs/skills/cwf-agent-shared-rules.md`, all 0600 instead
   of the recorded 0444. Not introduced by this task — same
   install-time mode-stripping that Task 143's retro flagged as a
   follow-up. Backlog entry "Install-time chmod 0444 on data/agents
   files (avoid post-install fix-security)" already tracks the
   underlying defect.

**Resolution** (user-approved before any remediation, per the
"surface, don't smooth" feedback rule):

- `chmod 0444` on the 7 affected files (1 in-scope edit + 6
  pre-existing).
- Updated the `cwf-security-reviewer-changeset` entry in
  `.cwf/security/script-hashes.json` to the new hash
  `c7033a74…2095e5`, computed from the post-edit file. This is a
  deliberate hash advance for an intentional content change — not an
  auto-recompute or `cwf-manage fix-security` blanket reset.
- 3 trailing WORKFLOW violations surfaced (Status `Planning` rejected
  as not a valid status value in `cwf-project.json`). The skill
  template suggestion was a non-canonical value; corrected to
  `Finished` in a-, d-, and e- (those phases are complete).
- Re-run: `[CWF] validate: OK`.

### TC-7 — dogfood note

The f-implementation-exec **Security Review** subagent invocation
already exercises the tightened prompt against a real changeset.
First non-blank line of the agent response was `no findings` — the
primary classifier path fired (no fallback, no conservative-default
error). g-testing-exec replays the same invocation against a
testing-phase changeset (same diff, different `{phase}` value) with
the same result. Both runs are recorded under § "Security Review"
in their respective wf step files.

This is a single positive observation (n=1 per phase). A quantitative
preface-rate reduction would need the methodology described in the
separate backlog entry on subagent line-count cap justification —
out of scope here, as noted in e-testing-plan § "Test Coverage
Targets".

## Coverage Report

Not applicable — no executable code changed; coverage tools have no
surface to measure. The 7 static checks cover every behavioural
contract surface in the agent file (frontmatter, sentinel tokens,
new wording, old wording removal, carve-out, parser-contract
sentence).

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: no findings

no findings
The diff only tightens prose instructions in a sub-agent prompt (sentinel-line discipline). No code, data flow, permissions, secrets, or external surfaces are touched.

## Lessons Learned
*To be captured during retrospective*
