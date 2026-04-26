# Perl + Git Path Handling

This document describes the convention for Perl helpers and hooks that consume
path output from `git`.

## Convention

When a Perl script reads paths from `git`, use both:

- **Shebang**: `#!/usr/bin/perl -CDSL` — makes Perl decode STDIN, STDOUT,
  STDERR, and `@ARGV` as UTF-8.
- **Source pragma**: `use utf8;` — tells Perl the *source file* is UTF-8.
  Required if the script contains any non-ASCII literals (emoji, accented
  characters, etc.). Without it, source bytes default to Latin-1 and a
  literal like `⚠` (three UTF-8 bytes in the file) becomes three separate
  Latin-1 codepoints, which then get re-encoded as UTF-8 on output →
  double-encoded mojibake (`â  ` instead of `⚠`). `-CDSL` controls I/O
  encoding only, *not* source encoding.
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

## Existing usage

Perl helpers using `-CDSL` shebang:

- `.cwf/scripts/command-helpers/template-copier-v2.1`
- `.cwf/scripts/command-helpers/status-aggregator-v2.1`
- `.cwf/scripts/command-helpers/context-inheritance-v2.1`

Perl helpers consuming git path output (apply this convention going
forward):

- `.cwf/scripts/hooks/stop-uncommitted-changes-warning` (Task 113)

## Pre-convention scripts

`.cwf/scripts/hooks/stop-stale-status-detector` predates this convention
and uses a bare `#!/usr/bin/env perl` shebang with `git diff HEAD
--name-only` (no `-z`). It is grandfathered. New helpers and hooks use
the convention above; do not replicate the older pattern.
