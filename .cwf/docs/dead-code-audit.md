# Dead Code Audit Methodology

A language-agnostic methodology for identifying dead code without
producing false positives. Applies to any codebase, any language. Two
companion surfaces inside this repository operationalise the doc:

- **Shift-left** — `.claude/agents/cwf-plan-reviewer-misalignment.md`
  consults the [Plan-time heuristics](#plan-time-heuristics) when
  reviewing a `design` or `implementation` plan.
- **Shift-right** — `.cwf/templates/pool/i-maintenance.md.template`
  schedules a periodic [Maintenance-time audit](#maintenance-time-audit)
  using the [Caller categories](#caller-categories).

For Perl/POSIX recipes that operationalise this methodology in the CWF
repo specifically, see `docs/dead-code-audit-perl.md`. That file does
not ship to CWF consumers.

## Principle

A function is *dead* when no live caller exists across **any** caller
category. Absence of static calls is not sufficient evidence: the
caller may be in a script, a generated config, a runtime dispatch
table, or a published extension point. The audit must enumerate
caller-category evidence — not enumerate cross-file grep hits.

The cheapest dead code is dead code never written. A shift-left review
that prevents adding an abstraction with only one callsite is worth
more than a shift-right sweep that removes it six months later. The
audit is recurring hygiene, not a one-off cleanup.

## When to audit

- **Plan time** — during plan review, before code lands. The
  shift-left surface. Heuristics flag plans that introduce code likely
  to read as dead within one or two cycles (single-callsite
  abstractions, config knobs with no operator, parallel implementations
  of an existing primitive).
- **Maintenance time** — periodic sweep against the working tree. The
  shift-right surface. Per-function verdicts via the
  [Caller categories](#caller-categories) checklist.

## Caller categories

Each candidate function is evaluated against every category. A single
positive hit means the function is *not* dead.

### 1. Static direct calls
Same module, named function call (e.g. `foo()` in the same file or
package). Grep the function name as an identifier; verify each hit is
a call site (not a definition, comment, string, or import).

*Cross-language example*: Python `bar()` in the same `.py`; Go `pkg.Bar()`
in the same package; Perl `&bar()` or `bar(@args)` in the same module.

### 2. Static cross-module calls
The function is imported, required, or referenced from another module
or compilation unit. **Grep scope must include non-source filetypes**:
shell scripts, CI YAML, Dockerfiles, Makefiles, generated config,
build-time templates. The library-to-library search is not enough;
script-to-library invocations are easy to miss.

*Cross-language example*: a Python CLI `entry_points` script calling
the library function; a Bash deploy script invoking a Perl helper; a
Makefile rule referencing a script that consumes the library; a CI
workflow YAML calling a wrapper.

*Task 51 case*: `workflow_file_mappings()` was used by
`context-inheritance-v2.0` (a script, not a library). A library-only
grep missed it.

### 3. Same-file private callers
The function is called only from another function in the same file.
Cross-file grep returns zero hits, but the function is alive. Open
each defining file and search for the function name within that file
before declaring it dead.

*Task 51 case*: `format_error()` had no cross-file callers but was
used internally in `Common.pm`. Cross-file-only grep mis-flagged it.

### 4. Reflective / runtime callers
The function is invoked by dispatch table, `eval`/`exec`, dynamic
method resolution, `getattr`, symbolic reference, or any other mechanism
where the name is constructed at runtime. The grep target here is the
function name as a **string literal**, not as an identifier.

*Cross-language example*: Python `getattr(obj, name)()`; Perl
`&{$name}()` or `$dispatch{$key}->()`; JavaScript `obj[key]()`; a
plugin registry keyed by function-name strings.

### 5. Tests-only callers
The only callers are test files. This is a judgement call: legitimate
fixtures and harnesses *do* call code that is otherwise dormant
(rarely-triggered paths, error branches). But a test that exists only
to keep dead production code alive is itself dead. Read the test:
does it exercise a path that production reaches, or only the function
in isolation?

### 6. Advertised external surface
The function is declared in POD, `__all__`, `exports`, package metadata,
a public README, a shipping manifest (e.g. `MANIFEST`,
`script-hashes.json`), or an advertised plugin/hook extension point.
**Such functions are never dead even with no internal callers** —
removing them is a breaking change to a published contract, not a
cleanup.

Be careful to distinguish *advertisement* (the function is named in a
shipping artefact as part of the API) from *historical mention* (the
function name appears in a CHANGELOG entry recording its removal, or
in a planning doc snapshot). Historical mentions are appearance, not
advertisement, and not caller-ness.

## Plan-time heuristics

Declarative criteria for evaluating a plan against. The plan-review
agent reads these as questions to apply, not as a script to execute.

- **Single-callsite abstraction** — if a proposed function, class, or
  module has exactly one callsite in the plan, Rule of Three is not
  met. Flag for inlining unless a second caller is imminent and
  specified.
- **Config knob with no operator** — if a new configuration field,
  flag, or environment variable is introduced and no documented or
  proposed component reads it, the knob is dead on arrival.
- **Parallel implementation** — if the plan introduces a primitive
  (parser, validator, formatter, cache, retry loop) that an existing
  module in the codebase already supplies, the new implementation is
  likely dead in one of two senses: either it replaces and the old is
  dead, or it duplicates and the new is dead. Either way the plan
  needs to state which.
- **Extension point without consumer** — if the plan adds a plugin
  hook, callback registry, or template variable with no in-tree
  consumer, the hook is dead until a consumer appears. Defer until
  the consumer is known, or document the contract as advertised
  external surface (category 6) and accept the maintenance cost.
- **Public API without internal use** — exporting a function that the
  introducing task does not itself call from within the project is a
  category-6 commitment. Flag the export so the plan owner confirms
  the public-surface intent rather than acquiring it by accident.

## Maintenance-time audit

Periodic sweep, scheduled by the `i-maintenance` template's Preventive
Maintenance list.

1. **Candidate list** — enumerate functions of interest (often a
   module or directory; sometimes the entire public surface).
2. **Category checklist** — for each candidate, walk the six
   [Caller categories](#caller-categories) and record per-category
   findings.
3. **Verdict per function** — DEAD only if all six categories show no
   live caller. Otherwise ALIVE with the category and call site that
   kept it alive.
4. **Structured report** — emit a verdict table (template below). A
   prose summary is not a report; the next auditor must be able to
   reproduce the work.

### Verdict template

```
| Function | File:lines | Per-category findings | Verdict | Recommendation |
```

- *File:lines* points to the definition.
- *Per-category findings* records six entries (one per category),
  each either a call-site reference or "none".
- *Verdict* is DEAD or ALIVE.
- *Recommendation* is the action (remove, keep, refactor, document as
  advertised surface).
