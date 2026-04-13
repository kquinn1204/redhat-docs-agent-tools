---
name: docs-upstream-sync
description: Review and fix upstream-synced documentation modules for downstream compliance. Diffs a feature branch against main, identifies issues (hardcoded product names, typos, broken AsciiDoc, inconsistent versions), and applies fixes with human confirmation.
argument-hint: [--base-branch <branch>] [--module-pattern <glob>] [--dry-run]
allowed-tools: Read, Write, Glob, Grep, Edit, Bash, Agent, AskUserQuestion
---

# Upstream Sync Review & Fix

Interactive skill for reviewing documentation modules that have been synced from an upstream source (e.g., GitLab engineering repos) into a downstream AsciiDoc documentation repository (e.g., openshift-docs). Identifies and fixes issues introduced by the sync to ensure compliance with the downstream build system.

## Problem Statement

Upstream engineering teams maintain documentation modules in separate repositories (e.g., GitLab). When these modules are synced into the downstream docs repo, they often contain:

- **Hardcoded product names** where AsciiDoc build-time attributes are required (e.g., "OpenShift" instead of `{product-title}`)
- **Typos** introduced during upstream editing
- **Broken AsciiDoc syntax** (unclosed quotes, malformed links, broken list continuations)
- **Inconsistent version references** in external URLs
- **Content type mismatches** that may need review
- **Missing or incorrect cross-references**

This skill automates the detection and fix of these issues while keeping the human in the loop for judgment calls.

## Arguments

- `--base-branch <branch>` — Branch to diff against (default: `main`)
- `--module-pattern <glob>` — Glob pattern for modules to review (default: auto-detected from branch diff)
- `--dry-run` — Report issues without applying fixes

## Workflow

### Step 1: Diff Analysis

Identify all changed files on the current branch relative to the base branch:

```bash
git diff <base-branch>...HEAD --stat
git diff <base-branch>...HEAD -- <module-pattern>
```

Categorize changes:
- Content type reclassifications (e.g., REFERENCE -> CONCEPT)
- Boilerplate removal (assembly comments, trailing blank lines)
- New content (JIRA links, new sections)
- Cross-reference changes (internal xrefs -> external URLs)
- Product name/attribute changes
- Formatting and structural changes

Present a summary to the user before proceeding.

### Step 2: Attribute Compliance Check

Launch an **Explore subagent** to search all changed modules for hardcoded product names that should be AsciiDoc build-time attributes.

#### Standard attribute mappings

| Hardcoded text | Required attribute |
|---|---|
| "OpenShift Container Platform" (in body text) | `{product-title}` |
| "OpenShift" (standalone, not in URLs/link titles) | `{product-title}` |
| "OpenShift Data Foundation" | `{rh-storage}` |
| "ACM" (referring to Advanced Cluster Management) | `{rh-rhacm}` or `{rh-rhacm-first}` |
| "Red Hat Advanced Cluster Management" | `{rh-rhacm-first}` (first use) or `{rh-rhacm}` |
| "Topology Aware Lifecycle Manager" | `{cgu-operator}` |

#### Exclusions — do NOT replace in these contexts

- Inside URL paths (e.g., `https://docs.openshift.com/...`)
- Blog post or external article titles in link text that must match the source title
- AsciiDoc comments (`// ...`)
- JIRA ticket references
- References to upstream project names (e.g., "Openshift" as a project name in engineering context)

Report all findings grouped by file with line numbers.

### Step 3: Typo and Syntax Check

Search changed modules for common issues:

- **Typos**: Common word substitutions (e.g., "poll" vs "pool", "not longer" vs "no longer")
- **Duplicated words**: e.g., "tuning tuning"
- **Broken AsciiDoc**:
  - Unclosed quotes or stray opening quotes
  - Malformed link syntax (e.g., `[text]link:url[text]`)
  - Missing blank lines before admonitions
  - Broken list continuations
- **Inconsistent versions**: External URLs pointing to older versions than the current release

Report all findings to the user.

### Step 4: Human Confirmation

Present all findings in a consolidated report:

```
## Attribute Fixes (N instances across M files)
<file>:<line> — "OpenShift" -> {product-title}
...

## Typos (N found)
<file>:<line> — "poll" -> "pool"
...

## Syntax Issues (N found)
<file>:<line> — unclosed quote
...

## Informational (no fix needed)
- Content type changes: N modules
- Cross-reference changes: N modules
```

Ask the user to confirm before applying fixes. The user may:
- Approve all fixes
- Approve selectively (e.g., "fix attributes but leave the typos for now")
- Flag false positives (e.g., "that link title should stay hardcoded")

### Step 5: Apply Fixes

Use the **Edit tool** to apply confirmed fixes. Batch independent edits in parallel for speed.

After applying:
1. Show a `git diff --stat` summary
2. Ask the user if they want to commit and push

### Step 6: Commit and Push (optional)

If the user confirms:
1. Stage only the fixed files
2. Commit with a descriptive message following the repo's commit style
3. Push to the feature branch

## Example Session

```
User: /docs-upstream-sync

Claude: Analyzing branch TELCODOCS-2823 against main...

Found 35 changed telco-core modules (-148 lines net).

Key changes:
- 15 content type reclassifications (REFERENCE -> CONCEPT)
- Boilerplate comments removed from all modules
- JIRA links added to 4 modules
- Cross-references changed to external URLs in 6 modules

## Issues Found

### Attribute compliance (17 instances, 8 files)
  telco-core-openshift-data-foundation.adoc:3  — "OpenShift Data Foundation" -> {rh-storage}
  telco-core-zones.adoc:6                      — "OpenShift" -> {product-title}
  ...

### Typos (2 found)
  telco-core-cpu-partitioning.adoc:19  — "poll" -> "pool"
  telco-core-agent-based-installer.adoc:20 — "not longer" -> "no longer"

### Syntax (2 found)
  telco-core-openshift-data-foundation.adoc:20 — stray opening quote
  telco-core-monitoring.adoc:12 — duplicated word "tuning tuning"

Apply all fixes? [Y/n/selective]
```

## Integration with docs-orchestrator

This skill can be added as a step in a workflow YAML:

```yaml
- name: upstream-sync-review
  skill: docs-upstream-sync
  description: Review and fix upstream-synced modules for downstream compliance
```

Or run standalone via: `/docs-upstream-sync`
