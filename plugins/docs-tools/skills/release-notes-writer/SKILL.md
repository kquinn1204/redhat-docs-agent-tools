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

## Release note template

Every release note entry MUST follow this four-part structure:

### 1. Heading

A short, descriptive summary of the feature or enhancement. Write it as a noun phrase, not a sentence.

- Good: "CPU isolation for exec processes in low-latency pods"
- Bad: "This release adds a new feature that isolates CPUs"

### 2. What and How (the feature)

Describe the feature from the user's perspective. Focus on what the user can now do. Use second person ("you").

- Start with: "With this release, you can..." or "You can now..."
- Describe the user action, not the internal implementation
- Example: "You can use this feature to directly create and manage SR-IOV networks within your application namespaces."

### 3. Why and Result (the benefit)

Explain why the feature was added and how it benefits the user's workflow. One to two sentences.

- Focus on the outcome for the user, not the engineering motivation
- Example: "Namespaced SR-IOV networks provide greater control over your network configurations and help to simplify your workflow."

### 4. Call to action (documentation link)

Provide a link to the detailed product documentation.

- Format: `For more information, see link:<URL>[<Link text>].`
- If the exact URL is not known, use a placeholder: `For more information, see xref:<assembly-id>[<section title>].`

## Output format

Produce the release note as an AsciiDoc snippet:

```asciidoc
== <Heading>

<What and How paragraph>

<Why and Result paragraph>

For more information, see xref:<assembly-or-module-id>[<section title>].
```

If multiple distinct features are covered in a single PR, produce one entry per feature.

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
2. **Identify the audience.** Determine which telco persona benefits (RAN engineer, platform admin, network operator, etc.).
3. **Draft the heading.** Write a concise noun-phrase summary.
4. **Write the What/How.** One to two sentences from the user's perspective.
5. **Write the Why/Result.** One to two sentences on the benefit.
6. **Add the link.** Include an xref or URL placeholder.
7. **Polish.** Check against the style guidelines. Cut any word that does not add meaning.

## Example

Given a PR that adds ExecCPUAffinity documentation for low-latency workloads, the output should look like:

```asciidoc
== CPU isolation for exec processes in low-latency pods

With this release, you can protect latency-sensitive workloads from performance
degradation caused by `oc exec` and shell processes. When you apply a
`PerformanceProfile`, exec processes are automatically pinned to a designated CPU
so they do not interrupt your workload CPUs.

This feature is enabled by default for guaranteed QoS pods with whole-integer CPU
requests. You can disable it per-pod with an annotation if your workloads require
the previous behavior.

For more information, see xref:scalability_and_performance/cnf-tuning-low-latency-nodes-with-perf-profile.adoc#cnf-protecting-low-latency-workloads_cnf-low-latency-perf-profile[Protecting low-latency workloads from exec process interruption].
```

## Integration with other skills

- **git-pr-reader**: Use to extract PR metadata, file diffs, and AsciiDoc content before drafting
- **docs-review-style**: Use after drafting to verify style guide compliance
- **rh-ssg-release-notes**: Use after drafting to verify SSG release note conventions
