# Perl + Git Path Handling

This document describes the convention for Perl helpers and hooks that consume
path output from `git`.

## Convention

When a Perl script reads paths from `git`, use both:

- **Shebang**: `#!/usr/bin/perl -CDSL` — makes Perl decode STDIN, STDOUT,
  STDERR, and `@ARGV` as UTF-8.
- **Source pragma**: `use utf8;` — tells Perl the *source file* is UTF-8.
  Declare it on **every** Perl file under `.cwf/` (script or module),
  unconditionally — not only ones that currently hold non-ASCII literals.
  Without it, a literal like `⚠` (three UTF-8 bytes in the file) is read
  as three separate Latin-1 codepoints and re-encoded as UTF-8 on output
  → double-encoded mojibake (`â  ` instead of `⚠`). Default-on prevents
  the latent failure where a future literal silently breaks. `-CDSL`
  controls I/O encoding only, *not* source encoding.
- **Git invocation**: pass `-z` to any git subcommand that emits paths
  (`git status --porcelain -z`, `git diff -z --name-only`, `git ls-files -z`,
  …). Records become NUL-separated and paths are emitted verbatim — no
  double-quote wrapping, no backslash/octal escaping for any character.
- **Parsing**: `split /\0/, $output` to recover the records, drop empty
  entries.

## Why

`-z` is git's documented mechanism for verbatim, machine-readable path
output. From the `core.quotePath` man page entry: "Many commands can output
pathnames completely verbatim using the `-z` option."

The alternative — leaving git's default quoting on, or setting
`core.quotepath=false` — is strictly weaker:

- Default quoting: paths with bytes >0x80 come out as
  `"caf\303\251.md"` (literal quote characters and octal escapes).
- `core.quotepath=false`: suppresses escaping for bytes >0x80, but
  double-quotes, backslashes, and control characters (newlines, tabs)
  *still* get escaped. Any path containing those characters still needs
  unescaping.
- `-z`: nothing is ever escaped. Records are NUL-separated, paths are
  raw bytes.

`-CDSL` then makes Perl treat git's UTF-8 byte output as proper unicode
strings, so `substr`, regex, and `length` work on characters rather than
raw bytes.

## Enforcement

`CWF::Validate::PerlConventions` (Task 124) enforces this convention on
every `cwf-manage validate` run, which itself runs after every workflow
checkpoint commit. The check walks `.cwf/scripts/` and `.cwf/lib/CWF/` and
asserts:

- `use utf8;` is declared in every Perl file (unconditional).
- Any script that captures output from a path-emitting git subcommand
  (`status`, `diff`, `ls-files`, `diff-tree`, `diff-index`) passes `-z`.
- Such scripts use the `#!/usr/bin/perl -CDSL` shebang.

Grandfathered exceptions live in `@CWF::Validate::PerlConventions::GRANDFATHERED`
— a hard-coded list that requires a source edit to extend (no comment-marker
opt-out). Allowlisted files still must declare `use utf8;`.

## Pre-convention scripts

`.cwf/scripts/hooks/stop-stale-status-detector` predates this convention
and uses a bare `#!/usr/bin/env perl` shebang with `git diff HEAD
--name-only` (no `-z`). It is grandfathered via the allowlist above.
New helpers and hooks use the convention; do not replicate the older
pattern.
