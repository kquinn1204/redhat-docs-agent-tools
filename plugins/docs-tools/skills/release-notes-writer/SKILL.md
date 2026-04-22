---
name: release-notes-writer
description: Generate user-centric release notes for OpenShift telco features from GitHub PR content. Reads PR diffs, applies structured templates, and outputs AsciiDoc release note entries.
allowed-tools: Read, Bash, Grep, Glob, Agent, WebFetch
---

# Release Notes Writer

Write release notes for OpenShift telco features by analyzing GitHub PR content or user-provided descriptions, applying structured templates below.

When given a PR URL, extract content first:

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/skills/git-pr-reader/scripts/git_pr_reader.py read --url "<PR_URL>" --filter "*.adoc"
```

## Release note templates

Release notes in the OCP repo are AsciiDoc bullet entries (`*`) under category sections. Each entry includes a JIRA tracking ID. There are two templates depending on the type of change.

### New feature or enhancement

A single bullet entry with a JIRA comment above it. Structure:

1. **JIRA tracking comment** — AsciiDoc comment with the JIRA ID
2. **What you can now do** — Start with "With this release, you can..." or "You can now..."
3. **Why it matters** — One sentence on the benefit to the user
4. **Documentation link** — "For more information, see xref:..."

Format:

```asciidoc
// <JIRA-ID>
* With this release, you can <what the user can now do>. <Why it matters — the benefit>.
+
For more information, see xref:<assembly-or-module-id>[<section title>].
```

If multiple distinct features are covered in a single PR, produce one entry per feature.

### Bug fix (fixed issue)

A single narrative paragraph using the **Before / Consequence / Fix / Result** flow, with the JIRA ID in parentheses at the end. Do not use subheadings — write it as plain prose.

Format:

```asciidoc
// <JIRA-ID>
* Before this update, <description of the previous behavior or problem when the user did something specific>. <Consequence — the impact on the user>. With this release, <what was changed or fixed>. As a result, <positive outcome for the user>. (<JIRA-ID>)
```

### Deprecated feature

Use when a feature or parameter is being removed or replaced. Do not say "discontinued." Frame the change positively.

Format:

```asciidoc
// <JIRA-ID>
* In this release, <what is deprecated>. <What to use instead or what direction the product is taking>. (<JIRA-ID>)
```

### Technology Preview to GA

Use when a Technology Preview feature moves to fully supported (General Availability).

Format:

```asciidoc
// <JIRA-ID>
* The <feature name> feature is now fully supported. Previously available as a Technology Preview, this feature <brief description of what it does>. For more information, see xref:<assembly-or-module-id>[<section title>].
```

## Style guidelines

- Second person ("you can", "your cluster"), active voice, present tense
- Direct and concise — every word must earn its place. No filler, hedging, or corporate-speak ("cost-effective," "streamlines operations")
- 3-5 sentences per entry, max two paragraphs (excluding link)
- Never use "discontinued" — instead frame as "We are taking our product in the following direction..."
- No unexplained jargon — add a brief parenthetical if a term must be used
- Do not over-explain technical internals unless the user needs them to act

## Workflow

1. **Extract context** — read PR diff/description, identify core functionality and the problem it solves
2. **Classify** — new feature, bug fix, deprecation, or TP-to-GA
3. **Extract JIRA ID** — from PR title, description, or branch name
4. **Draft** — apply the matching template, include xref link for features and TP-to-GA entries
5. **Review** — verify against style guidelines, cut any word that does not add meaning

## Examples

### New feature example

Given a PR that adds ExecCPUAffinity documentation for low-latency workloads (TELCODOCS-2496):

```asciidoc
// TELCODOCS-2496
* With this release, you can protect latency-sensitive workloads from performance degradation caused by `oc exec` and shell processes. When you apply a `PerformanceProfile`, exec processes are automatically pinned to a designated CPU so they do not interrupt your workload CPUs. This feature is enabled by default for Guaranteed QoS pods with whole-integer CPU requests, so your Telco RAN DU and 5G Core applications maintain consistent, predictable performance without additional configuration.
+
For more information, see xref:scalability_and_performance/cnf-tuning-low-latency-nodes-with-perf-profile.adoc#cnf-protecting-low-latency-workloads_cnf-low-latency-perf-profile[Protecting low-latency workloads from exec process interruption].
```

### Bug fix example

Given a PR that fixes a vSphere validation issue (OCPBUGS-63584):

```asciidoc
// OCPBUGS-63584
* Before this update, the vSphere platform configuration lacked a validation check to prevent the simultaneous definition of both a custom virtual machine template and a `clusterOSImage` parameter. This issue allowed users to provide both parameters in the installation configuration, leading to ambiguity and potential deployment failures. With this release, the vSphere validation logic has been updated to ensure that `template` and `clusterOSImage` parameters are treated as mutually exclusive. As a result, a specific error message is returned if both fields are populated, which prevents misconfiguration. (OCPBUGS-63584)
```

## Integration with other skills

- **git-pr-reader**: Use to extract PR metadata, file diffs, and AsciiDoc content before drafting
- **docs-review-style**: Use after drafting to verify style guide compliance
- **rh-ssg-release-notes**: Use after drafting to verify SSG release note conventions
