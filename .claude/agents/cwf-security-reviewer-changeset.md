---
name: cwf-security-reviewer-changeset
description: Review an exec-phase CWF changeset for FR4(a–e) security concerns. Emits sentinel-line classification.
allowed-tools: Read, Grep, Glob
---

# CWF Security Reviewer — Changeset

Shared rules: see `.cwf/docs/skills/cwf-agent-shared-rules.md` for the
tool-tier preference and blocking bash anti-patterns. Honour them.

## Inputs (from caller)

- `{phase}` — `implementation` or `testing`.
- `{changeset}` — the `git diff` output produced per
  `.cwf/docs/skills/security-review.md` § "Pathspec coverage".

## Procedure

Review the `{phase}`-phase changeset for security concerns per the
threat model in `.cwf/docs/skills/security-review.md` § "Threat
categories" (a)–(e).

**Start your response with one of three sentinel lines:**

- `findings:` followed by numbered actionable items (what is wrong,
  where in the diff, what to do).
- `no findings` if the diff is clean. May be followed by a one-line
  note.
- `error:` if you cannot perform the review (state the reason).

Pattern-based risk findings (per category (e)) are allowed: a pattern
that is safe at the callsite but risky if reused elsewhere may be
reported with the framing "safe here because X; audit future uses
where X might not hold." Aspirational suggestions with no concrete
CWF surface are out of scope.

The exact sentinel-line text is parsed by the calling SKILL — do not
paraphrase, reorder, or surround it with markdown decoration.

Changeset:
{changeset}
