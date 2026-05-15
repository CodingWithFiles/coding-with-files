# Perl

Universal rules for every Perl file (script or module) under `.cwf/`.

## Convention

Every Perl file in scan roots (`.cwf/scripts/`, `.cwf/lib/CWF/`) uses:

- **Shebang**: `#!/usr/bin/env perl`. No hardcoded `-C` flags on the kernel
  shebang line.
- **Source pragma**: `use utf8;`. Declared on every Perl file unconditionally,
  not only ones that currently hold non-ASCII literals.
- **Runtime I/O flags**: set via the `PERL5OPT` environment variable, not via
  the shebang. The recommended value is:

  ```
  PERL5OPT=-CDSLA
  ```

  Configured in your Claude Code settings (`~/.claude/settings.json` under
  `"env"`) or your shell's startup file.

The `-CDSLA` flags decode `STDIN`, `STDOUT`, `STDERR`, the default
I/O layer, and `@ARGV` as UTF-8. The `A` flag matters: it is what allows a
Perl script to read non-ASCII bytes from `@ARGV` correctly (the failure mode
fixed in Task 137 — without `A`, a literal `→` arrow passed as a CLI
argument becomes `â†'` mojibake).

## Why

The kernel shebang line is unreliable as a place to configure flags:

- **`Too late for -CDSLA`**: when `PERL5OPT` already supplies some `-C`
  flags and the shebang tries to add `A`, perl rejects the post-init flag
  addition. Empirically observed during Task 137.
- **Kernel shebang-argv parsing variance**: Linux (pre-5.10), macOS, and
  several BSDs differ on whether `-CDSL` is passed as one token or split.
  `env perl` plus `PERL5OPT` bypasses this entirely.
- **Single source of truth**: with `PERL5OPT` as the canonical place for I/O
  flags, a user upgrading their preferred I/O setup changes one env var
  instead of editing 30+ shebangs.

Source-level `use utf8;` is independent of `PERL5OPT`. Without it, a literal
like `⚠` (three UTF-8 bytes in the file) is read as three separate Latin-1
codepoints and re-encoded as UTF-8 on output → double-encoded mojibake.
Default-on prevents the latent failure where a future literal silently
breaks. `PERL5OPT=-CDSLA` controls I/O encoding only, *not* source encoding.

## Enforcement

`CWF::Validate::PerlConventions` enforces this convention on every
`cwf-manage validate` run, which itself runs after every workflow checkpoint
commit. The check walks `.cwf/scripts/` and `.cwf/lib/CWF/` and asserts:

- `use utf8;` is declared in every Perl file (unconditional).
- Every Perl script's shebang is `#!/usr/bin/env perl`. Any hardcoded
  `-C` form is rejected.

Grandfathered exceptions live in
`@CWF::Validate::PerlConventions::GRANDFATHERED` — a hard-coded list that
requires a source edit to extend (no comment-marker opt-out). Grandfathered
files still must declare `use utf8;` and use the canonical shebang;
grandfathering only relaxes git-path-output rules (see
`docs/conventions/git-path-output.md`).

## See also

- `docs/conventions/git-path-output.md` — rules for scripts that capture
  path-emitting `git` output (`-z`, `split /\0/`).
