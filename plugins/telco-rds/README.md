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

## Prerequisites

- Python 3.6+
- Bash
- Claude Code with the telco-rds plugin installed
- A local clone of the upstream reference-design-specifications repo
- A local clone of openshift-docs (for the reference assembly)

## Upstream mapping files

Each RDS type directory in the upstream repo contains two mapping files that track how upstream sections map to downstream modules:

| File | Purpose |
|------|---------|
| `rds-downstream-mapping.yaml` | Machine-readable mapping of section IDs to downstream modules, including internal-only sections, name mismatches, and edge cases |
| `DOWNSTREAM_PORT.adoc` | Human-readable porting reference with the same information plus openshift-docs conventions |

**Keep these files up to date.** When the upstream monolith is updated for a new release, update the mapping files first to reflect any new sections, removed sections, renamed IDs, or new internal-only content. The pipeline skills use `rds-downstream-mapping.yaml` to make correct decisions about which sections to skip, which filenames to use, and which edge cases to handle.

## Usage

### Full workflow (recommended)

Run the complete pipeline using the docs-orchestrator with the telco-rds workflow:

```
/docs-orchestrator <JIRA-ticket> --workflow telco-rds --source ~/reference-design-specifications/telco-core/telco-core-rds.adoc
```

This runs all five steps in sequence: strip → split → generate assembly → style review → modular docs review.

**Optional flags:**

| Flag | Description |
|------|-------------|
| `--source <path>` | Path to the upstream monolithic AsciiDoc file (required) |
| `--reference-assembly <path>` | Existing openshift-docs assembly to copy additional resources sections from |

**Example with reference assembly:**

```
/docs-orchestrator TELCODOCS-1234 --workflow telco-rds \
  --source ~/reference-design-specifications/telco-core/telco-core-rds.adoc \
  --reference-assembly ~/openshift-docs/scalability_and_performance/telco-core-rds.adoc
```

### Run individual skills

You can also run each step separately, which is useful for debugging or re-running a single step:

```bash
# 1. Strip internal content
/telco-rds-strip-internal ~/reference-design-specifications/telco-core/telco-core-rds.adoc --output-dir /tmp/telco-rds/stripped

# 2. Split into modules
/telco-rds-split-monolith /tmp/telco-rds/stripped/telco-core-rds.adoc --output-dir /tmp/telco-rds/modules

# 3. Generate assembly
/telco-rds-generate-assembly --modules-dir /tmp/telco-rds/modules --output-dir /tmp/telco-rds/assembly \
  --reference-assembly ~/openshift-docs/scalability_and_performance/telco-core-rds.adoc
```

### Run scripts directly (without Claude)

The strip and split steps can also be run as standalone scripts:

```bash
# Strip internal content
bash plugins/telco-rds/skills/telco-rds-strip-internal/scripts/strip-internal.sh \
  ~/reference-design-specifications/telco-core/telco-core-rds.adoc \
  --output-dir /tmp/telco-rds/stripped

# Split into modules
python3 plugins/telco-rds/skills/telco-rds-split-monolith/scripts/split-monolith.py \
  /tmp/telco-rds/stripped/telco-core-rds.adoc \
  --output-dir /tmp/telco-rds/modules
```

The assembly generation step requires Claude — it reads the manifest and mapping files and applies editorial judgment for section grouping and additional resources placement.

## Typical release workflow

1. **Update upstream** — engineering updates the monolith (e.g., `telco-core-rds.adoc`) for the new release
2. **Update mapping files** — update `rds-downstream-mapping.yaml` and `DOWNSTREAM_PORT.adoc` to reflect any changes (new sections, removed sections, renamed IDs, new internal-only content)
3. **Run the pipeline** — use the full workflow command above
4. **Review output** — check the generated modules and assembly in the output directory
5. **Copy to openshift-docs** — move the generated files into your openshift-docs working branch
6. **Submit PR** — open a PR against openshift-docs with the updated modules and assembly
