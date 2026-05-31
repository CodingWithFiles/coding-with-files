# Audit show-toplevel sites for worktree-safety - Design
**Task**: 173 (bugfix)

## Task Reference
- **Task ID**: internal-173
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/173-audit-show-toplevel-sites-for-worktree-safety
- **Template Version**: 2.1

## Goal
Define how to make CWF's repo-root resolution worktree-safe: a classification of the 13 sites by *how the resolved root is used*, a single shared resolution primitive for the sites that want the canonical (main) tree, and explicit no-change rationale for sites that are worktree-local by design.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### Architecture Choice
- **Decision**: Classify each site by *consumption pattern* (what the resolved root is used for), not by file type. Route every "wants the canonical repo root" site through a **single shared resolver** in `CWF::Common`; fix pure-shell/prose sites inline; leave worktree-local-by-design sites unchanged with rationale.
- **Rationale**: The data-loss mechanism (Task 172) is not "show-toplevel returns the worktree root" in the abstract — it is operating on canonical, persistent repo state (task stack, templates, checkpoints, config) while anchored to a tree that may be removed. Consumption pattern, not extension, determines the risk and the correct fix. A single resolver keeps the fix DRY and gives one tested choke-point.
- **Trade-offs**: Centralising means TaskPath/WorkflowFiles call `CWF::Common`. Confirmed safe: `CWF::Common` is a leaf module (no `use CWF::*`), so no circular dependency is possible — the "must confirm" caveat is resolved. The alternative (inline snippet per site) duplicates the subtle `git rev-parse` incantation and is harder to test. Centralisation wins on Testability + Consistency.

### Consumption-pattern classes
- **Class A — persistent CWD mutation** (`cd "$(git rev-parse --show-toplevel)"`): the direct data-loss vector — moves the shell into a tree that can vanish. Sites: `scripts/update-cwf-skill-docs.sh:10`; prose in `cwf-init/SKILL.md:87` and `tmp-paths.md:28`. **Highest priority.**
- **Class B — path-anchoring capture** (`my $git_root = \`…\`;` then used to build paths): does *not* move CWD, but reads/writes canonical repo state relative to the captured root; if that root is a transient worktree, writes land in the disposable tree. Sites: `.cwf/lib/CWF/Common.pm:52` (`find_git_root` — the choke-point), `.cwf/lib/CWF/TaskPath.pm:38`, `.cwf/lib/CWF/WorkflowFiles.pm:159`, `checkpoints-branch-manager:11`, `template-copier-v2.0:120`, `template-copier-v2.1:159`, `migrate-v2.1-file-order:31`. **Plus three transitive `find_git_root` callers** (fixed for free once the choke-point is safe): `.cwf/lib/CWF/Versioning.pm:33`, `.cwf/lib/CWF/Backlog.pm:669`, `backlog-manager:46`.
- **Class C — worktree-local by design**: must observe the *current* worktree to function. Site: `task-workflow.d/delete:153` (Check 7 self-worktree guard — compares the current worktree against worktrees holding the branch being deleted; rewriting it to the main tree breaks the `wt_rp eq $self_rp` self-exclusion). **No change.**
- **Class D — diagnostic reporter**: `context-manager.d/location:13` exists to *report* where you are. Honest reporting may mean surfacing both the current worktree and the main tree rather than silently substituting. **Judgement call — see Open Questions.**
- **Error-message-only capture** (reclassified out of Class B per review): `task-stack:14` captures `$git_root` *solely* to build a relative path for error messages; the stack file itself opens via the CWD-relative constant `$STACK_FILE = '.cwf/task-stack'`. Routing this site changes only error text, not where state lives — see OQ-1.

### Resolution primitive
- **Decision**: **Repoint the existing `find_git_root`** in `CWF::Common` to worktree-safe behaviour rather than adding a parallel `find_repo_root`. Review established `find_git_root` is exported (`@EXPORT_OK`, `.cwf/lib/CWF/Common.pm:14`) and has three live callers (Versioning, Backlog, backlog-manager) — all Class B, all wanting the canonical root — so the keep/replace question is already settled: repoint it, and those three are fixed transitively. The routed inline-backtick sites switch to calling `find_git_root()`.
- **Mechanism**: return the **main worktree root** even inside a linked worktree, equal to `--show-toplevel` otherwise. Derive from `git rev-parse --path-format=absolute --git-common-dir` (flag order matters — see below), take the parent directory when the result ends in `/.git`, else fall back to `--show-toplevel`.
- **Flag ordering (verified, git 2.43.0)**: `--path-format=absolute` MUST precede `--git-common-dir`; the reverse order returns a *relative* `.git`. Confirmed empirically in a real linked worktree: absolute common-dir ends in `/.git`, parent is the main root, and `--show-toplevel` from the worktree returns the worktree path (the bug). The empirical test (e-testing-plan) must assert this ordering, not rediscover it.
- **Parent derivation**: use `File::Spec` (core) to take the parent of the common-dir, not ad-hoc regex stripping of `/.git` — canonicalise before use (security finding FR4(d)).
- **Spawn discipline**: the command is argument-free, so the existing backtick form stays safe; if any future variant must pass a path (`-C $dir`), switch to list-form `open '-|'` — never interpolate a path into the backtick (FR4(b)/(e)).
- **Documented fallback**: when `--git-common-dir`'s result does not end in `/.git` (bare repo / quirk), the resolver falls back to `--show-toplevel`; this branch is part of the contract and must be a tested path, not an afterthought.

## System Design

### Per-site disposition table
The original grep found 13 sites; review surfaced a 14th (`cwf-manage`'s own resolver) plus 3 transitive callers fixed via the choke-point. "Route" = switch the inline backtick to call `find_git_root()`. Sites marked ⚑ are judgement calls (Open Questions).

| # | Site | Class | Proposed treatment |
|---|------|-------|--------------------|
| 1 | `.cwf/lib/CWF/Common.pm:52` (`find_git_root`) | B | **Choke-point** — repoint to worktree-safe behaviour |
| 2 | `.cwf/lib/CWF/TaskPath.pm:38` | B | Route → `find_git_root()` |
| 3 | `.cwf/lib/CWF/WorkflowFiles.pm:159` | B | Route → `find_git_root()` |
| 4 | `command-helpers/checkpoints-branch-manager:11` | B | Route — canonical checkpoints branch |
| 5 | `command-helpers/task-stack:14` ⚑ | err-msg only | Reclassified — capture feeds error text only; stack opens CWD-relative (OQ-1) |
| 6 | `command-helpers/task-workflow.d/delete:153` | C | **No change** — load-bearing self-worktree guard |
| 7 | `command-helpers/template-copier-v2.0:120` | B | Route — templates copied into canonical tree |
| 8 | `command-helpers/template-copier-v2.1:159` | B | Route — templates copied into canonical tree |
| 9 | `command-helpers/context-manager.d/location:13` ⚑ | D | Report main + worktree, don't silently substitute (OQ-2) |
| 10 | `scripts/migrations/migrate-v2.1-file-order:31` | B | Route — rewrites tracked task files |
| 11 | `scripts/update-cwf-skill-docs.sh:10` | A | Replace `cd "$(…)"` with safe-root resolution |
| 12 | `.claude/skills/cwf-init/SKILL.md:87` | A | Fix prose: `GIT_ROOT` must be main tree (OQ-3: is the arg even load-bearing?) |
| 13 | `.cwf/docs/conventions/tmp-paths.md:28` | A | Fix prose: `repo_root` derivation must be worktree-safe |
| 14 | `.cwf/scripts/cwf-manage:86` (own `find_git_root`, raw `--show-toplevel`) | B? | **Newly surfaced** — decide: route to safe behaviour or explicitly scope out (OQ-4) |
| T1 | `.cwf/lib/CWF/Versioning.pm:33` | B (transitive) | Fixed for free via choke-point |
| T2 | `.cwf/lib/CWF/Backlog.pm:669` | B (transitive) | Fixed for free via choke-point |
| T3 | `command-helpers/backlog-manager:46` | B (transitive) | Fixed for free via choke-point |

### Data flow (resolver)
1. Caller invokes `CWF::Common` resolver (Perl) or inline snippet (shell/prose).
2. Resolver asks git for the common dir; if inside a linked worktree, derives the main worktree root; else returns `--show-toplevel`.
3. Caller anchors canonical-state paths (`.cwf/task-stack`, `implementation-guide/…`, templates, config) to that root — guaranteed to be the persistent main tree.
4. Class C guard remains on the *current* worktree path; Class D reports both.

### Edited hashed helpers → hash refresh (same commit)
Edited hashed artefacts include `.cwf/lib/CWF/Common.pm`, the routed `.pm` modules (TaskPath, WorkflowFiles, Versioning, Backlog), command-helpers (checkpoints-branch-manager, template-copier-v2.0/v2.1, context-manager.d/location, migrate-v2.1-file-order, backlog-manager), `update-cwf-skill-docs.sh`, and — if OQ-4 routes it — `cwf-manage`. Each edit triggers a `.cwf/security/script-hashes.json` refresh in the *same commit* (hash-updates convention). Restore working perms to the **recorded** value, not bumped (Task 170 ceiling). `.pm` modules carry no `permissions` key — keep them `100644`, do not chmod to executable.

## Interface Design

### Resolver contract (`CWF::Common::find_git_root`, repointed)
```
find_git_root() → absolute path string of the MAIN worktree root,
                  or undef if not inside a git repo.
  - In the main tree:        == `git rev-parse --show-toplevel`
  - In a linked worktree:    == the main tree's root (NOT the worktree)
  - common-dir not .../.git:  fall back to `--show-toplevel` (tested branch)
  - Outside a repo:          undef (callers already handle undef/empty)
```
Backward-compatibility: existing callers (TaskPath, WorkflowFiles, Versioning, Backlog, backlog-manager) test `length $root` / `undef`; repointing preserves that contract — only the *value* inside a worktree changes (the intended fix). Keeping the symbol name avoids a parallel resolver and fixes the three transitive callers without touching them.

### Shell/prose snippet (Class A)
A single canonical worktree-safe snippet, defined once and reused verbatim in `update-cwf-skill-docs.sh`, `cwf-init/SKILL.md`, and `tmp-paths.md`, so the three Class-A sites stay in lockstep.

## Open Questions (for review before implementation)
- **OQ-1 — task-stack scope** (premise corrected by review): site 5's `$git_root` capture feeds only an error-message path; the stack file opens via the CWD-relative `$STACK_FILE = '.cwf/task-stack'`, so a linked worktree already gets its own stack regardless of this capture. Routing the resolver here changes only error text. *If* canonical-shared stack behaviour is actually wanted, that is a separate change to how `$STACK_FILE` is resolved (open relative to the resolved root) — not in scope unless we decide the stack should be shared. Proposal: treat as no-change (per-worktree stack is the natural reading of a gitignored file); confirm.
- **OQ-2 — `location` reporter**: should `context-manager location` report the main tree, the current worktree, or both? Proposal: report both (it is a diagnostic; silent substitution would hide the very worktree the user is in). Reported paths are filesystem-derived, so no new injection surface (FR4(c)).
- **OQ-3 — `cwf-init` GIT_ROOT arg**: the backlog R2 note questions whether the `GIT_ROOT="$(…)"` capture passed to `cwf-apply-artefacts` is load-bearing at all, since most helpers resolve the root internally. If not, drop the capture entirely rather than make it worktree-safe.
- **OQ-4 — `cwf-manage:86` own resolver**: `cwf-manage` defines its *own* `find_git_root` (raw `--show-toplevel`, line 87), independent of `CWF::Common`. It installs/validates against `.cwf/`. Decide: route it to safe behaviour (it should anchor to the main tree for install/validate), or explicitly scope it out with rationale. Proposal: route it — running install/validate against a transient worktree is exactly the loss class.

## Constraints
- POSIX shell + core-Perl only; macOS system-perl (no non-core modules).
- The exact `git rev-parse` incantation must be empirically verified in a real worktree before shipping — no documentation-only claims (repo memory: no fabricated citations).
- Hashed-helper edits: hash refresh in the same commit; recorded perms are an upper bound.
- Class C (`delete` guard) semantics preserved exactly — verified by the existing delete tests plus a self-worktree case.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? If yes, consider decomposition
- [ ] **People**: Does this need >2 people working on different parts? If yes, consider decomposition
- [ ] **Complexity**: Does this involve 3+ distinct concerns? If yes, consider decomposition
- [ ] **Risk**: Are there high-risk components that need isolation? If yes, consider decomposition
- [ ] **Independence**: Can parts be worked on separately? If yes, consider decomposition

## Validation
- [x] Design review completed (4 parallel reviewers: improvements, misalignment, robustness, security — findings applied below)
- [ ] Open Questions OQ-1..OQ-4 resolved with the maintainer before implementation
- [ ] Integration points verified (3 transitive `find_git_root` callers covered by tests)

**Plan-review changes applied**: corrected the false "no callers" claim (repoint `find_git_root`, +3 transitive callers); fixed `.cwf/lib/CWF/` path prefixes; reclassified `task-stack` as error-message-only and corrected OQ-1's premise; added `cwf-manage:86` as 14th candidate (OQ-4); recorded verified flag ordering (`--path-format=absolute` first) + `File::Spec` parent derivation + documented fallback branch + argument-free spawn discipline; resolved the circular-`use` caveat (Common is a leaf).

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 173
**Blockers**: OQ-1..OQ-4 are open judgement calls for maintainer review before exec

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
