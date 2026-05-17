# Hash Updates

## Convention

Hash refreshes happen in the same task — and the same commit — as the underlying file modification. A refresh deferred to a later task, to retrospective, or to a "release-boundary cleanup" is a process error, not a tidy-up.

## Why

Each `sha256` entry in `.cwf/security/script-hashes.json` signs the file at the moment a maintainer last reviewed it. A deferred refresh by an unrelated task means the signature was never matched to its intent — recomputing later silently absorbs whatever shape the file has now, including changes nobody re-reviewed. The friction from `cwf-manage validate` IS the integrity check working; smoothing it is the failure mode.

## How (mechanical, in order)

1. Make the source edit.
2. `sha256sum <path>` to compute the new digest.
3. Edit the matching `sha256` entry in `.cwf/security/script-hashes.json` in the same commit.
4. `cwf-manage validate` to confirm clean.

## Plan-time disclosure

Any implementation plan whose Files-to-Modify list includes a hashed path MUST list `.cwf/security/script-hashes.json` as a Supporting Change. The check is one grep against `.cwf/security/script-hashes.json` — perform it during d-plan, not at f-exec when validate fires.

## Pre-refresh verification

When refreshing a hash, first verify with

    git log --oneline <last-hash-set-commit>..HEAD -- <path>

that the intervening commits are the known, intended modifications — **per file**, not assumed-shared baselines. Tasks that touched a hashed path without refreshing its entry create per-file drift; a baseline that "looks shared" across two paths can in fact be two different commits. Use `--` to separate revision range from path. If scripting the verification, use `-z` per `docs/conventions/git-path-output.md`.

## Carve-out (narrow, invariant-guarded)

A task whose explicit deliverable IS a hash-table change (fixing prior drift) doesn't need to "match" an unrelated source edit. The carve-out is only safe when ALL of the following hold:

1. The dedicated task names every drifted entry it intends to refresh in its plan.
2. The dedicated task verifies per-file pre-refresh via `git log <last-hash-set-commit>..HEAD -- <path>` and documents the result.
3. The dedicated task contains no other source edits to the drifted files.
4. The originating commit(s) of the drift are explicitly named in the task.

Without all four, the carve-out does not apply. "Dedicated hash-fix task" is not a self-applied label.

## What NOT to build (principle, not enumeration)

Any tool, flag, or mode whose effect is to silence `cwf-manage validate` output without first surfacing it to a human is forbidden. Concrete anti-patterns this covers: a `recompute-hashes` helper; an auto-update hook; a `validate --fix` mode; a `validate --ignore=<path>` flag; a `validate --baseline=HEAD` flag. New surface that smooths a tampering signal into a no-op falls under the same prohibition even when not enumerated here.

## Historical example

Task 147 (commit `246e6c4`) added two `CWF::Backlog` public helpers, one private helper, and 4 lines in `cmd_retire`, but did not refresh the two hash entries. Task 148 discovered the drift mid-flow but, correctly, did not absorb it — the side-quest fix was rebased out before squash and the drift left visible to `cwf-manage validate` as the explicit signal. Task 149 refreshes the hashes properly, with this convention doc as its co-deliverable.

Tasks 139 (`d3d7b86`) and 140 (`f833bbf`) are the positive control: both touched `backlog-manager` and refreshed its `sha256` entry in the same commit. The convention is achievable; Task 147 is the outlier.
