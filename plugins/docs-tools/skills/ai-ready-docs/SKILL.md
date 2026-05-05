---
name: ai-ready-docs
description: Evaluate AsciiDoc procedures for AI-agent readability. Static analysis — no cluster required. Flags prerequisite verify lines, bare parameter names, misplaced tables, inline definitions, verbose abstracts, and other patterns that increase token usage or make procedures harder for AI agent skills to parse and execute. Recommends structural changes that benefit both AI agents and human readers.
allowed-tools: Read, Glob, Grep, Edit, Bash
---

# AI-Ready Documentation Review

Evaluate AsciiDoc procedure modules for AI-agent readability. This is static analysis of document structure — no live cluster is required. The goal is to optimize procedures so AI agent skills can parse and execute them with minimal token usage and maximum accuracy, while keeping the content clear for human readers.

**This is not a live verification tool.** To test procedures against a live cluster, use `docs-tools:verify-procedure`.

## Usage

```
/ai-ready-docs <file.adoc>
/ai-ready-docs <file.adoc> --fix       # Apply recommended fixes in place
/ai-ready-docs <directory>              # Scan all .adoc files in directory
```

- Default mode: report findings only
- With `--fix`: apply fixes using Edit, report what changed
- For assemblies: resolve `include::` directives and analyze all included modules

## Workflow

### Step 1: Load and parse

Read the `.adoc` file. If it is an assembly (`:_mod-docs-content-type: ASSEMBLY`), resolve all `include::` directives and analyze each included module separately. Report findings per file.

For each file, extract:
- The title (first `= ` heading)
- The `[role="_abstract"]` paragraph
- The `.Prerequisites` section
- All `[source,yaml]` and `[source,json]` blocks
- All parameter description patterns (tables, definition lists, inline prose)
- All numbered procedure steps

### Step 2: Evaluate against checklist

Run each check below. For every finding, record the file path, line number, the current pattern, and the recommended fix.

#### 2.1 Prerequisites must not contain verify commands

Flag any `Verify:` lines in `.Prerequisites` sections (e.g., lines matching `Verify: \`....\``). Prerequisites state what must already be true — they are assumed met before the procedure starts.

**Pattern to flag:**
```asciidoc
* Install the {oc-first}.
+
Verify: `oc version`
```

**Recommended fix:** Remove the `+` continuation and `Verify:` line. The prerequisite bullet stands alone:
```asciidoc
* Install the {oc-first}.
```

#### 2.2 Parameter descriptions should use structured tables

Flag inline definition lists used to describe YAML parameters:
```asciidoc
`labels`:: The label assigned to the `IPAddressPool`...
```

**Recommended fix:** Convert to a structured table:
```asciidoc
[cols="2,1,3",options="header"]
|===
| Parameter | Format | Description

| `metadata.labels`
| Key-value pairs
| Labels that can be referenced by `ipAddressPoolSelectors`...
|===
```

#### 2.3 Parameter names must use dot notation

Flag parameter tables where names are bare field names without their YAML path context (e.g., `channel` instead of `spec.channel`). An agent parsing `name` cannot determine whether it maps to `metadata.name` or `spec.name`.

To determine the correct dot notation:
1. Find the YAML example associated with the parameter table
2. Trace each parameter name to its position in the YAML hierarchy
3. Build the dot-separated path (e.g., `spec.addresses`, `metadata.name`, `spec.config.nodeSelector`)

**Pattern to flag:**
```asciidoc
| `channel`
| `stable`
| The subscription channel
```

**Recommended fix:**
```asciidoc
| `spec.channel`
| `stable`
| The subscription channel
```

#### 2.4 Parameter tables should follow YAML examples

Flag parameter tables that appear before the YAML manifest they describe. The YAML example should come first — it gives readers (human and AI) the concrete structure. The table follows as a reference for valid values and constraints.

**Pattern to flag:**
```asciidoc
.Parameters
[cols="2,1,3",options="header"]
|===
| Parameter | Format | Description
...
|===
+
[source,yaml]
----
apiVersion: ...
----
```

**Recommended fix:** Swap the order — YAML first, table after:
```asciidoc
[source,yaml]
----
apiVersion: ...
----
+
.Parameters
[cols="2,1,3",options="header"]
|===
| Parameter | Format | Description
...
|===
```

#### 2.5 Abstracts should not repeat the title

Flag `[role="_abstract"]` paragraphs that restate the procedure title without adding new information.

**Pattern to flag:**
```asciidoc
= Configuring an address pool

[role="_abstract"]
To configure an address pool for MetalLB, you can configure an address pool
to define IP ranges for load balancer services.
```

**Recommended fix:** The abstract should add context the title doesn't convey:
```asciidoc
= Configuring an address pool

[role="_abstract"]
Configure an `IPAddressPool` to define the IP address ranges that MetalLB
can assign to `LoadBalancer` services.
```

#### 2.6 Minimize redundant prose between steps

Flag step introductions that merely restate what the command does, adding tokens without information:

**Patterns to flag:**
- "Run the following command to apply the configuration:" before `oc apply -f`
- "Enter the following command to create the resource:" before `oc create -f`
- "To verify the installation, run:" before `oc get`

**Recommended fix:** Use concise step instructions that add context the command doesn't convey, or let the command speak for itself:
```asciidoc
. Apply the configuration:
```

#### 2.7 YAML examples should be complete enough to execute

Flag YAML examples that are missing `apiVersion` or `kind` — these are the minimum fields an agent needs to construct a valid resource. Also flag examples that have no `metadata.name` or `metadata.namespace` when the resource type requires them.

### Step 3: Report

Present findings grouped by category. For each finding, show the file, line number, current text, and recommended fix.

```
--- AI-Ready Docs Review: <filename> ---

## Prerequisites (N findings)

- Line 12: Verify: `oc version` → Remove verify line
- Line 16: Verify: `oc auth can-i...` → Remove verify line

## Parameter Tables (N findings)

- Line 30: `channel` → `spec.channel` (dot notation)
- Line 34: `name` → `metadata.name` (dot notation)
- Line 25-40: Parameter table before YAML → Move after YAML example

## Token Efficiency (N findings)

- Line 6: Abstract repeats title → Rewrite to add context
- Line 55: "Run the following command to..." → Simplify step text

## Summary

Files scanned: N | Findings: N | Categories: prerequisites (N), parameters (N), efficiency (N)
```

If `--fix` was specified, apply the fixes using Edit and report what changed. For dot notation fixes, always verify the correct path against the associated YAML example before applying.
