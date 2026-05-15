# Git path output

Rules for Perl scripts that consume path output from `git`.

**Prerequisite reading**: `docs/conventions/perl.md` (universal Perl rules).

## Convention

When a Perl script reads paths from a `git` subcommand, use both:

- **Git invocation**: pass `-z` to any subcommand that emits paths
  (`git status --porcelain -z`, `git diff -z --name-only`,
  `git ls-files -z`, …). Records become NUL-separated and paths are
  emitted verbatim — no double-quote wrapping, no backslash/octal escaping
  for any character.
- **Parsing**: `split /\0/, $output` to recover the records. Drop empty
  trailing entries.

Combined with the universal `PERL5OPT=-CDSLA` (which decodes the captured
output as UTF-8), this gives the script paths as proper Perl character
strings, suitable for `substr`, regex, and `length` working on characters
rather than raw bytes.

## Why

`-z` is git's documented mechanism for verbatim, machine-readable path
output. From `git`'s `core.quotePath` man page entry: "Many commands can
output pathnames completely verbatim using the `-z` option."

The alternatives are strictly weaker:

- **Default quoting**: paths with bytes >0x80 come out as
  `"caf\303\251.md"` — literal quote characters and octal escapes that
  must be unescaped on the receiving side.
- **`core.quotepath=false`**: suppresses escaping for bytes >0x80, but
  double-quotes, backslashes, and control characters (newlines, tabs)
  *still* get escaped. Any path containing those characters still needs
  unescaping.
- **`-z`**: nothing is ever escaped. Records are NUL-separated, paths are
  raw bytes.

## Enforcement

`CWF::Validate::PerlConventions` walks `.cwf/scripts/` and asserts that any
script which *captures* output from a path-emitting git subcommand
(`status`, `diff`, `ls-files`, `diff-tree`, `diff-index`) passes `-z`.

Grandfathered exceptions live in
`@CWF::Validate::PerlConventions::GRANDFATHERED`. Adding entries requires
a source edit.

## Pre-convention scripts

`.cwf/scripts/hooks/stop-stale-status-detector` predates this convention
and uses `git diff HEAD --name-only` (no `-z`). It is grandfathered.
New helpers and hooks use the convention; do not replicate the older
pattern.

## See also

- `docs/conventions/perl.md` — universal Perl rules (shebang, PERL5OPT,
  `use utf8;`).
