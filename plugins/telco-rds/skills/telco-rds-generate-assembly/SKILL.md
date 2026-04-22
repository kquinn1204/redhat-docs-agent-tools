---
name: telco-rds-generate-assembly
description: Generate an openshift-docs assembly file from split telco RDS modules. Reads manifest.json from the split step to build the assembly with correct include directives, leveloffsets, and additional resources sections.
argument-hint: --modules-dir <dir> --output-dir <dir> [--reference-assembly <file>]
allowed-tools: Read, Write, Glob, Grep, Bash
---

# Generate openshift-docs assembly from telco RDS modules

This skill generates the openshift-docs assembly file that ties together the individual module files produced by `telco-rds-split-monolith`.

## When to use

Use this skill after `telco-rds-split-monolith` has produced module files and a `manifest.json`. This skill:

- Reads `manifest.json` to get the module list, heading levels, and context
- Reads `rds-downstream-mapping.yaml` from the upstream repo to handle edge cases and name mismatches
- Generates an assembly file with proper openshift-docs structure
- Calculates `leveloffset` values from the original heading levels
- Optionally uses a reference assembly to determine where `[role="_additional-resources"]` blocks should go

## Prerequisites

The `--modules-dir` comes from the previous `telco-rds-split-monolith` step. The mapping file lives in the same directory as the original monolith (passed via `--source` in the workflow). Verify before proceeding — stop and report if any are missing:

```bash
ls <modules-dir>/manifest.json
ls <path-to-monolith-dir>/rds-downstream-mapping.yaml
```

If `--reference-assembly` is provided, verify it exists too.

## Process

1. **Read inputs** — parse `manifest.json` (fields: `context`, `rds_type`, `title`, `title_id`, `modules`) and `rds-downstream-mapping.yaml`
2. **Generate header** — write `:_mod-docs-content-type: ASSEMBLY`, `:telco-<rds_type>:`, `[id="<title_id>"]`, title, `include::_attributes/common-attributes.adoc[]`, `:context:`, `toc::[]`, and intro paragraph
3. **Add includes** — for each module: `include::modules/<filename>[leveloffset=+N]` where N = `level - 1`. Apply mapping overrides:
   - `name_mismatches` → use `downstream_module` filename
   - `edge_cases` with `downstream_module: null` → skip (no include directive)
   - `sections` list → verify all appear; flag any missing or new
4. **Reference assembly** (if provided) — copy `[role="_additional-resources"]` blocks and inline section grouping headers from the reference. If no reference: do NOT add additional resources sections
5. **Write** — output to `<output-dir>/telco-<rds_type>-rds.adoc`
6. **Summary** — report total modules included, leveloffset distribution, skipped modules with reasons

## Example

```bash
/telco-rds-generate-assembly --modules-dir artifacts/telco-core/modules \
  --output-dir artifacts/telco-core/assembly \
  --reference-assembly ~/openshift-docs/scalability_and_performance/telco-core-rds.adoc
```
