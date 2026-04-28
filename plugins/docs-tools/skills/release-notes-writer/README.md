# Release Notes Writer

Generate user-centric release notes for OpenShift features in AsciiDoc format. The skill reads GitHub PRs or JIRA tickets, classifies the change type, and outputs a copy-paste-ready release note entry that follows OCP repo conventions.

## Prerequisites

- **Claude Code** with the `docs-tools` plugin installed
- **GITHUB_TOKEN** environment variable set (for reading PRs)
- **JIRA access** configured via the `jira-mcp` MCP server (for reading JIRA tickets)

## How to use

There are three ways to invoke this skill. In each case, Claude reads the source material, classifies the change, and drafts the release note using the correct template.

### 1. Point it at a GitHub PR

If you have a PR that describes a new feature or enhancement, pass the PR URL:

```
/release-notes-writer https://github.com/openshift/openshift-docs/pull/12345
```

The skill reads the PR title, description, and diff, then drafts a **New Feature** release note entry.

### 2. Point it at a JIRA ticket by key

Pass a JIRA issue key directly:

```
/release-notes-writer OCPBUGS-12345
```

Or use the full URL:

```
/release-notes-writer https://issues.redhat.com/browse/CNF-5678
```

The skill reads the JIRA summary, description, and the **Release Note Type** field to determine which template to use.

### 3. How the JIRA "Release Note Type" field maps to output

The **Release Note Type** field on the JIRA ticket controls which template the skill applies:

| Release Note Type | What the skill generates |
|---|---|
| **Feature** or **Enhancement** | New feature entry (definition list format) |
| **Bug Fix** | Fixed issue entry (bullet format) |
| **Known Issue** | Known issue entry (bullet format) |

You can also provide additional context or instructions alongside the URL or key:

```
/release-notes-writer OCPBUGS-12345 — this is for the 4.19 z-stream
```

## What you get back

The skill outputs an AsciiDoc block that you can paste directly into the appropriate release notes file. The format depends on the change type.

### New feature example

```asciidoc
// CNF-5678
PTP grandmaster clock support::
+
You can now configure a PTP grandmaster clock on bare-metal nodes.
This enables sub-microsecond time synchronization across your cluster.
+
For more information, see xref:../networking/ptp/ptp-grandmaster.adoc#configuring-grandmaster[Configuring a PTP grandmaster clock].
```

### Bug fix example

```asciidoc
* Before this update, the egress IP address was incorrectly assigned
  to the br-ex bridge. As a consequence, routing conflicts occurred.
  With this release, the egress IP address is correctly assigned to
  the secondary interface. As a result, routing conflicts are resolved.
  (link:https://issues.redhat.com/browse/OCPBUGS-77257[OCPBUGS-77257])
```

### Known issue example

```asciidoc
* Currently, on clusters with SR-IOV virtual functions configured,
  a race condition might occur between system services and the TuneD
  service. As a consequence, the TuneD profile might become degraded
  after a node restart. As a workaround, restart the TuneD pod to
  restore the profile state.
  (link:https://issues.redhat.com/browse/OCPBUGS-41934[OCPBUGS-41934])
```

## Supported change types

The skill handles six types of release note entries:

1. **New feature or enhancement** -- Definition list format with "what you can now do" and "why it matters"
2. **Bug fix (fixed issue)** -- Bullet format using the Before / Consequence / Fix / Result pattern
3. **Known issue** -- Bullet format with problem, consequence, and optional workaround
4. **Deprecated feature** -- Bullet format with deprecation notice and alternative
5. **Technology Preview to GA** -- Definition list format noting the TP-to-GA transition
6. **Z-stream (maintenance release)** -- Separate module format with fixed header and boilerplate

## Style conventions applied

- Second person ("you can", "your cluster"), active voice, present tense
- 3-5 sentences per entry, maximum two paragraphs
- No filler, hedging, or corporate-speak
- JIRA tracking comment above each entry
- Clickable JIRA links using `link:https://issues.redhat.com/browse/...`
- Cross-references using `xref:../` paths (relative from `modules/` directory)

## Tips

- **Multiple features in one PR**: The skill creates a separate entry for each distinct feature it identifies in the diff.
- **Missing JIRA ID**: The skill extracts the JIRA ID from the PR title, description, or branch name. If it can't find one, it will ask you.
- **Review after drafting**: Consider running `/rh-ssg-release-notes` on the output to verify SSG compliance.
- **Z-stream notes**: Mention "z-stream" in your prompt so the skill uses the maintenance release template instead of the GA format.
