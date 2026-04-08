---
name: release-notes-writer
description: Generate user-centric release notes for OpenShift telco features from GitHub PR content. Reads PR diffs, applies structured templates, and outputs AsciiDoc release note entries.
author: Kevin Quinn (kquinn@redhat.com)
allowed-tools: Read, Bash, Grep, Glob, Agent, WebFetch
---

# Release Notes Writer

Write release notes for OpenShift telco features by analyzing GitHub PR content and applying a structured, user-centric template.

## Capabilities

- Read a GitHub PR to extract the technical context (files changed, descriptions, AsciiDoc content)
- Generate release note entries following the Red Hat OpenShift release note template
- Apply telco-specific tone and style guidelines
- Output AsciiDoc-formatted release note entries ready for inclusion in release note assemblies

## Usage

### From a GitHub PR

When the user provides a PR URL, extract the content first:

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/skills/git-pr-reader/scripts/git_pr_reader.py read --url "<PR_URL>" --filter "*.adoc"
```

Then apply the template and guidelines below to draft a release note.

### From manual input

The user can also provide a plain-text description of the feature. Apply the same template and guidelines to produce the release note.

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

Follow these rules strictly when writing release notes:

### Tone

- **Direct and concise.** Every word must earn its place. Remove filler, hedging, and thesis-style explanations.
- **Encouraging and positive.** Highlight value and new possibilities. Do not be dry or clinical.
- **Transparent.** Be honest about changes, even potentially negative ones, to maintain trust.
- **User-centric.** Write from the user's perspective, using the language they know.

### Do

- Use second person ("you can", "your cluster")
- Use active voice
- Use present tense for the feature description
- State clearly when a Technology Preview feature moves to fully supported
- Keep each release note entry to 3-5 sentences total (excluding the heading and link)

### Do not

- Use "discontinued" -- instead say "We are taking our product in the following direction..."
- Use corporate-speak: "cost-effective," "reducing operational expenses," "enhances efficiency," "streamlines operations"
- Over-explain the technical internals unless the user needs them to act
- Use jargon without context -- if a term must be used, add a brief parenthetical explanation
- Write more than two paragraphs per entry (excluding the link)

## Workflow

1. **Extract context.** Read the PR diff and description to identify the core functionality and the problem it solves.
2. **Identify the type.** Determine whether this is a new feature, bug fix, deprecation, or TP-to-GA change.
3. **Extract the JIRA ID.** Pull the JIRA tracking ID from the PR title, description, or branch name.
4. **Apply the template.** Use the matching template for the change type.
5. **Write from the user's perspective.** Use second person, active voice, present tense.
6. **Add the link.** Include an xref or URL placeholder for new features and TP-to-GA entries.
7. **Polish.** Check against the style guidelines. Cut any word that does not add meaning.

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
