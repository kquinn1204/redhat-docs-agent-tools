---
name: telco-rds-split-monolith
description: Split a stripped telco RDS monolithic AsciiDoc file into individual module files based on [id=""] markers. Each section becomes a separate module with Red Hat modular documentation headers. Produces a manifest.json for assembly generation.
argument-hint: <input-file> --output-dir <dir> [--context <ctx>] [--rds-type core|ran|hub]
allowed-tools: Read, Bash, Write
---

# Split telco RDS monolith into modules

This skill splits a stripped (internal content removed) telco RDS monolithic AsciiDoc file into individual module files following Red Hat modular documentation standards.

## When to use

Use this skill after `telco-rds-strip-internal` has removed internal content. This skill:

- Parses the monolith by `[id="..."]` markers — each marker starts a new module
- Creates one `.adoc` file per section in the output directory
- Adds `:_mod-docs-content-type:` header (CONCEPT, PROCEDURE, or REFERENCE) based on content analysis
- Appends `_{context}` to anchor IDs for modular docs compliance
- Demotes headings so each module's top heading is `=` (level 1)
- Writes a `manifest.json` listing all modules with their heading levels for assembly generation

## Prerequisites

Before running, verify all exist — stop and report if any are missing:

```bash
ls ${CLAUDE_SKILL_DIR}/scripts/split-monolith.py
python3 --version
ls <source-dir>/rds-downstream-mapping.yaml  # same directory as the original monolith
ls <input-file>  # stripped monolith from previous step
```

## Mapping reference

Before splitting, read `rds-downstream-mapping.yaml` from the upstream repo directory. Use it to:

- **Skip internal-only sections** — IDs listed under `internal_only` should not produce modules (they should already be stripped, but verify)
- **Rename mismatched modules** — IDs listed under `name_mismatches` must use the `downstream_module` filename instead of the default 1:1 mapping (e.g., `telco-core-deployment` → `telco-core-deployment-components.adoc`)
- **Handle edge cases** — IDs listed under `edge_cases` with `downstream_module: null` should not produce module files; include the `note` in the manifest for the assembly step

## Usage

```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/split-monolith.py <input-file> \
  --output-dir <dir> \
  [--context <ctx>] \
  [--rds-type core|ran|hub]
```

**Arguments:**
- `<input-file>` — Stripped monolithic AsciiDoc file
- `--output-dir <dir>` — Directory to write module files and manifest
- `--context <ctx>` — Context variable for `_{context}` suffix (default: derived from filename)
- `--rds-type <type>` — One of `core`, `ran`, `hub` (default: derived from filename)

## Output

The script produces individual `.adoc` module files (with `:_mod-docs-content-type:` headers and `_{context}` suffixed IDs) and a `manifest.json` listing all modules with `filename`, `id`, `level`, `content_type`, and `heading`. The `level` field maps to assembly `leveloffset`: level 2 → `+1`, level 3 → `+2`, level 4 → `+3`.

After the script completes, verify the output:

```bash
ls <output-dir>/*.adoc | wc -l  # module count should match sections list in mapping
cat <output-dir>/manifest.json | python3 -m json.tool  # verify valid JSON
```

## Example

```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/split-monolith.py \
  artifacts/telco-core/stripped/telco-core-rds.adoc \
  --output-dir artifacts/telco-core/modules
```
