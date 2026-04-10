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
- Generates an assembly file with proper openshift-docs structure
- Calculates `leveloffset` values from the original heading levels
- Optionally uses a reference assembly to determine where `[role="_additional-resources"]` blocks should go

## Process

### Step 1: Read the manifest

Read `manifest.json` from the modules directory. It contains:
- `context` — the `:context:` value (e.g., `telco-core`)
- `rds_type` — `core`, `ran`, or `hub`
- `title` — the document title
- `title_id` — the anchor ID for the assembly
- `modules` — list of module entries with `filename`, `id`, `level`, `content_type`, `heading`

### Step 2: Generate assembly header

Write the assembly file with this header:

```asciidoc
:_mod-docs-content-type: ASSEMBLY
:telco-<rds_type>:
[id="<title_id>"]
= <title>
include::_attributes/common-attributes.adoc[]
:context: <context>

toc::[]

<intro paragraph from title — reuse the first paragraph from the monolith>
```

### Step 3: Add include directives

For each module in the manifest, add an `include::` directive:

```asciidoc
include::modules/<filename>[leveloffset=+N]
```

**leveloffset calculation:**
- Original level 2 (`==`) in the monolith → `leveloffset=+1`
- Original level 3 (`===`) → `leveloffset=+2`
- Original level 4 (`====`) → `leveloffset=+3`
- Formula: `leveloffset = original_level - 1`

### Step 4: Add additional resources sections

If a `--reference-assembly` is provided, read it to identify which modules have `[role="_additional-resources"]` blocks after them. Replicate those blocks in the generated assembly.

If no reference is provided, do NOT add additional resources sections — these require editorial judgment and should be added manually.

### Step 5: Add section grouping headers

Some modules in the openshift-docs assembly are grouped under inline section headers (not from modules). Check the reference assembly for patterns like:

```asciidoc
[id="telco-core-rds-components"]
== Telco core RDS components

The following sections describe the various {product-title} components...

include::modules/telco-core-cpu-partitioning...
```

These inline section headers should be preserved in the generated assembly.

### Step 6: Write the assembly

Write the complete assembly to `<output-dir>/telco-<rds_type>-rds.adoc`.

### Step 7: Write a summary

Print a summary showing:
- Total modules included
- leveloffset distribution
- Any modules from the manifest that were skipped (and why)

## Output

The generated assembly file follows the exact structure used in openshift-docs:

```asciidoc
:_mod-docs-content-type: ASSEMBLY
:telco-core:
[id="telco-core-ref-design-specs"]
= Telco core reference design specifications
include::_attributes/common-attributes.adoc[]
:context: telco-core

toc::[]

The telco core reference design specifications (RDS) configures...

include::modules/telco-core-rds-product-version-use-model-overview.adoc[leveloffset=+1]

include::modules/telco-core-about-the-telco-core-cluster-use-model.adoc[leveloffset=+1]

...
```

## Example

```
/telco-rds-generate-assembly --modules-dir artifacts/telco-core/modules --output-dir artifacts/telco-core/assembly --reference-assembly ~/openshift-docs/scalability_and_performance/telco-core-rds.adoc
```
