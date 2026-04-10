# Telco RDS Plugin

Automates the transformation of monolithic telco Reference Design Specification (RDS) AsciiDoc files into modular openshift-docs format.

## Problem

Telco docs writers manually transform a single large AsciiDoc file (maintained on GitLab) into ~40 individual module files plus an assembly for openshift-docs. This is repeated every y-stream release and involves:

1. Stripping internal-only content (`// tag::internal[]` blocks)
2. Splitting by `[id=""]` markers into separate module files
3. Adding modular docs headers (`:_mod-docs-content-type:`, `_{context}` suffixes)
4. Generating the assembly file with `include::` directives and `leveloffset` values
5. Style reviewing the output

## Pipeline

```
Monolithic AsciiDoc (GitLab)
  │
  ├─ telco-rds-strip-internal    Strip internal content + product attributes
  │
  ├─ telco-rds-split-monolith    Split into modules by [id=""] markers
  │
  ├─ telco-rds-generate-assembly Generate assembly with include:: directives
  │
  ├─ docs-workflow-style-review  Vale + style guide compliance (reused from docs-tools)
  │
  └─ docs-review-modular-docs   Module structure validation (reused from docs-tools)
```

## Supported RDS types

| Type | Source file | Context |
|------|-----------|---------|
| Telco Core | `telco-core/telco-core-rds.adoc` | `telco-core` |
| Telco RAN DU | `telco-ran/telco-ran-rds.adoc` | `telco-ran` |
| Telco Hub | `telco-hub/telco-hub-rds.adoc` | `telco-hub` |

## Quick start

### Run individual skills

```bash
# 1. Strip internal content
bash plugins/telco-rds/skills/telco-rds-strip-internal/scripts/strip-internal.sh \
  ~/reference-design-specifications/telco-core/telco-core-rds.adoc \
  --output-dir /tmp/telco-rds/stripped

# 2. Split into modules
python3 plugins/telco-rds/skills/telco-rds-split-monolith/scripts/split-monolith.py \
  /tmp/telco-rds/stripped/telco-core-rds.adoc \
  --output-dir /tmp/telco-rds/modules

# 3. Generate assembly (Claude-driven skill)
/telco-rds-generate-assembly --modules-dir /tmp/telco-rds/modules --output-dir /tmp/telco-rds/assembly
```

## Prerequisites

- Python 3.6+
- Bash
- Claude Code with the telco-rds plugin installed
