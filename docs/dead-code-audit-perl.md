# Dead Code Audit — Perl / POSIX Recipes (CWF-internal)

Perl/POSIX applied recipes; principles in `.cwf/docs/dead-code-audit.md`.
If anything below contradicts the canonical doc, the canonical doc wins.

This file does **not** ship to CWF consumers. Symbol names in the
recipes are operator-supplied at audit time, not interpolated from any
automated source. Worked examples use list-form invocations.

## Per-category greps

- **Cross-file usage**: `grep -rn 'function_name' .cwf/lib/ .cwf/scripts/`
- **Same-file usage**: open each defining `.pm` file and search for
  the function name within the file (cross-file grep won't find it).
- **Script-to-library usage**: `grep -rn 'function_name' .cwf/scripts/command-helpers/`
- **Reflective callers**: `grep -rn '"function_name"' .cwf/` — the
  function name as a quoted string is the dispatch-table signal.
- **POD / advertised surface**: `grep -rn '=head2 function_name' .cwf/lib/`
  plus a check for `script-hashes.json` membership (a tracked script
  is an advertised artefact).
- **Historical mentions to discount**: `CHANGELOG.md`,
  `implementation-guide/*/`. These are appearance, not caller-ness.

## Structured-report row

Match the canonical verdict template:

```
| Function | File:lines | Per-category findings | Verdict | Recommendation |
```
