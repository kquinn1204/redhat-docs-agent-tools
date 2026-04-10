---
name: telco-rds-strip-internal
description: Strip internal-only tagged content from monolithic telco RDS AsciiDoc files. Removes all content between // tag::internal[] and // end::internal[] markers, and strips top-level product attribute definitions that are provided by openshift-docs common-attributes.adoc.
argument-hint: <input-file> [--output-dir <dir>]
allowed-tools: Read, Bash, Write
---

# Strip internal content from telco RDS monolith

This skill removes Red Hat internal-only content from telco RDS AsciiDoc source files, preparing them for downstream publication in openshift-docs.

## When to use

Use this skill as the first step in the telco RDS pipeline, before splitting the monolith into modules. It handles:

- Removing all content between `// tag::internal[]` and `// end::internal[]` markers (inclusive)
- Removing top-level product attribute definitions (`:product-title:`, `:product-version:`, `:imagesdir:`, `:rh-storage:`, `:cgu-operator:`, `:rh-rhacm:`) which are provided by `_attributes/common-attributes.adoc` in openshift-docs

## Usage

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/strip-internal.sh <input-file> [--output-dir <dir>]
```

**Arguments:**
- `<input-file>` — Path to the monolithic RDS AsciiDoc file (e.g., `telco-core/telco-core-rds.adoc`)
- `--output-dir <dir>` — Output directory (default: current directory)

**Output:**
- Writes the stripped file to `<output-dir>/<original-filename>` (overwrites if exists)
- Prints the count of internal blocks removed and lines stripped

## Example

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/strip-internal.sh \
  ~/reference-design-specifications/telco-core/telco-core-rds.adoc \
  --output-dir artifacts/telco-core/stripped
```
