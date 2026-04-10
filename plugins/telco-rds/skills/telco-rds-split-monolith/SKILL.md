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

### Module files

Each module file has this structure:

```asciidoc
:_mod-docs-content-type: CONCEPT
[id="telco-core-networking_{context}"]
= Networking

<section content with demoted sub-headings>
```

### Manifest (manifest.json)

```json
{
  "context": "telco-core",
  "rds_type": "core",
  "title": "Telco core reference design specifications",
  "title_id": "telco-core-reference-design-specification-for-product-title-product-version",
  "modules": [
    {
      "filename": "telco-core-networking.adoc",
      "id": "telco-core-networking",
      "level": 3,
      "content_type": "CONCEPT",
      "heading": "Networking"
    }
  ]
}
```

The `level` field records the original heading depth in the monolith:
- `2` (==) — top-level section, use `leveloffset=+1` in the assembly
- `3` (===) — subsection, use `leveloffset=+2`
- `4` (====) — sub-subsection, use `leveloffset=+3`

## Example

```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/split-monolith.py \
  artifacts/telco-core/stripped/telco-core-rds.adoc \
  --output-dir artifacts/telco-core/modules
```
