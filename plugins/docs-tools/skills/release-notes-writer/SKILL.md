---
name: release-notes-writer
description: Generate user-centric release notes for OpenShift telco features from GitHub PR content. Reads PR diffs, applies structured templates, and outputs AsciiDoc release note entries.
allowed-tools: Read, Bash, Grep, Glob, Agent
---

# Release Notes Writer

Write release notes for OpenShift telco features by analyzing GitHub PR content or user-provided descriptions, applying structured templates below.

When given a PR URL, extract content first:

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/skills/git-pr-reader/scripts/git_pr_reader.py read --url "<PR_URL>" --filter "*.adoc"
```

## Release note templates

Release notes in the OCP repo are organized under category sections (e.g., `== Networking`, `== Installation and update`). Each entry uses AsciiDoc **definition list** format with `+` continuation blocks. Each entry includes a JIRA tracking ID as a comment above it. There are several templates depending on the type of change.

### New feature or enhancement

A definition list entry with prose continuation paragraphs. Structure:

1. **JIRA tracking comment** — AsciiDoc comment with the JIRA ID
2. **Definition list title** — A concise title ending with `::`
3. **What you can now do** — Start with "With this release, you can...", "You can now...", or "As of this update, you can..."
4. **Why it matters** — One sentence on the benefit to the user
5. **Documentation link** — "For more information, see xref:../..."

Format:

```asciidoc
// <JIRA-ID>
<Concise feature title>::
+
<What the user can now do>. <Why it matters — the benefit>.
+
<Optional second paragraph with additional detail, configuration, or how to disable.>
+
For more information, see xref:../<path-to-assembly>.adoc#<anchor>[<section title>].
```

**xref format**: All xrefs in release notes modules must start with `../` because the module lives in `modules/` and references assemblies at the repo root. Always use `xref:../path/to/assembly.adoc#anchor[Link text]`.

**Bullet lists inside an entry**: When an entry contains a list, wrap the `*` items in `--` open block delimiters so they nest correctly inside the definition list continuation:

```asciidoc
<Title>::
+
<Intro text>:
+
--
* Item one
* Item two
--
+
For more information, see xref:../<path>.adoc#<anchor>[<title>].
```

**Admonition blocks inside an entry**: You can include `[NOTE]`, `[IMPORTANT]`, or `[WARNING]` blocks inside a continuation. Place them after a `+` continuation marker:

```asciidoc
<Title>::
+
<Main text>.
+
[NOTE]
====
<Note content>.
====
```

If multiple distinct features are covered in a single PR, produce one entry per feature, each as its own definition list item.

### Bug fix (fixed issue)

A single bullet (`*`) paragraph using the **Before / Consequence / Fix / Result** flow, with a JIRA link at the end. Fixed issues are grouped under category subsections (e.g., `== Installer`, `== Networking`) with `[id=...]` anchors. Do not use definition list format for bug fixes.

Format:

```asciidoc
[id="rn-ocp-release-note-<category>-fixed-issues_{context}"]
== <Category name>

* Before this update, <description of the previous behavior or problem>. As a consequence, <impact on the user>. With this release, <what was changed or fixed>. As a result, <positive outcome for the user>. (link:https://issues.redhat.com/browse/<JIRA-ID>[<JIRA-ID>])
```

**JIRA link format**: Always use `link:https://issues.redhat.com/browse/JIRA-ID[JIRA-ID]` — not just the ID in parentheses. This creates a clickable link in the rendered docs.

### Known issue

A bullet (`*`) paragraph describing an ongoing problem the user may encounter, with a workaround if available. Known issues are listed as flat bullets under the main `= Known issues` heading — they are **not** grouped under category subsections like fixed issues. Use "Currently" to open the entry.

Format (with workaround):

```asciidoc
* Currently, <description of the problem and when it occurs>. As a consequence, <impact on the user>. As a workaround, <mitigation steps>. (link:https://issues.redhat.com/browse/<JIRA-ID>[<JIRA-ID>])
```

Format (no workaround available):

```asciidoc
* Currently, <description of the problem and when it occurs>. As a consequence, <impact on the user>. (link:https://issues.redhat.com/browse/<JIRA-ID>[<JIRA-ID>])
```

**Multi-paragraph known issues**: For complex workarounds with code blocks or steps, use `+` continuation after the opening bullet, same as definition list continuations. Wrap bullet lists in `--` open block delimiters.

### Deprecated feature

Use when a feature or parameter is being removed or replaced. Do not say "discontinued." Frame the change positively.

Format:

```asciidoc
// <JIRA-ID>
* In this release, <what is deprecated>. <What to use instead or what direction the product is taking>. (link:https://issues.redhat.com/browse/<JIRA-ID>[<JIRA-ID>])
```

### Technology Preview to GA

Use when a Technology Preview feature moves to fully supported (General Availability).

Format:

```asciidoc
// <JIRA-ID>
<Feature name> (Generally Available)::
+
<Brief description of what the feature does>.
+
This feature was introduced in {product-title} <version> with Technology Preview status. This feature is now supported as generally available in {product-title} {product-version}.
+
For more information, see xref:../<path-to-assembly>.adoc#<anchor>[<section title>].
```

### Z-stream (maintenance release)

Z-stream release notes are separate modules (`zstream-4-YY-N.adoc`) included from the main release notes assembly. They have a fixed structure with boilerplate sections. Entries use the same **Before / Consequence / Fix / Result** bullet format as GA fixed issues — no category subsections.

File structure:

```asciidoc
// Module included in the following assemblies:
//
// * release_notes/ocp-4-YY-release-notes.adoc

:_mod-docs-content-type: REFERENCE
[id="zstream-4-YY-N_{context}"]
= <RHBA|RHSA>-YYYY:NNNN - {product-title} {product-version}.N fixed issues advisory

Issued: DD Month YYYY

[role="_abstract"]
{product-title} release {product-version}.N is now available. The list of fixed issues that are included in the update is documented in the link:https://access.redhat.com/errata/<RHBA|RHSA>-YYYY:NNNN[<RHBA|RHSA>-YYYY:NNNN] advisory. The RPM packages that are included in the update are provided by the link:https://access.redhat.com/errata/RHBA-YYYY:NNNN[RHBA-YYYY:NNNN] advisory.

Space precluded documenting all of the container images for this release in the advisory.

You can view the container images in this release by running the following command:

[source,terminal]
----
$ oc adm release info 4.YY.N --pullspecs
----

[id="zstream-4-YY-N-fixed-issues_{context}"]
== Fixed issues

* Before this update, <problem>. As a consequence, <impact>. With this release, <fix>. As a result, <outcome>. (link:https://issues.redhat.com/browse/<JIRA-ID>[<JIRA-ID>])

[id="zstream-4-YY-N-updating_{context}"]
== Updating

To update an {product-title} 4.YY cluster to this latest release, see xref:../updating/updating_a_cluster/updating-cluster-cli.adoc#updating-cluster-cli[Updating a cluster using the CLI].
```

**Z-stream enhancements**: Some z-stream releases include an optional `== Enhancements` section before `== Fixed issues`. Enhancement entries use `+` continuation blocks (same format as definition list entries but without the `::` — just a plain `*` bullet with continuation paragraphs).

**JIRA link domains**: Z-stream entries may use either `issues.redhat.com/browse/` or `redhat.atlassian.net/browse/` for JIRA links — both are valid. Use whichever domain the JIRA ticket originates from.

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

### New feature — simple (single paragraph with xref)

```asciidoc
// TELCODOCS-2565
Multi-network policy backend uses nftables::
+
With this release, the multi-network policy backend uses `nftables` instead of `iptables`. The `iptables` backend has been removed and there is no option to revert to it. The `MultiNetworkPolicy` API and user-facing configuration are unchanged, so your existing multi-network policies continue to work without modification.
+
The Cluster Network Operator (CNO) now automatically creates and manages the `multi-networkpolicy-custom-rules` ConfigMap for IPv6 NDP support. You no longer need to create this resource manually.
+
For more information, see xref:../networking/multiple_networks/secondary_networks/configuring-multi-network-policy.adoc#configuring-multi-network-policy[Configuring multi-network policy].
```

### New feature — with configuration detail

```asciidoc
// TELCODOCS-2496
CRI-O ExecCPUAffinity protects low-latency workloads from exec process interruption::
+
With this release, you can protect latency-sensitive workloads from performance degradation caused by `oc exec` and shell processes. When you apply a `PerformanceProfile`, the CRI-O `ExecCPUAffinity` feature automatically pins exec processes to a designated CPU within the container's allocated set, preventing them from running on your workload CPUs.
+
This feature is enabled by default for `Guaranteed` QoS pods with whole-integer CPU requests and requires no additional configuration. You can disable it per profile by adding the `performance.openshift.io/exec-cpu-affinity: "disable"` annotation to the `PerformanceProfile`.
+
For more information, see xref:../scalability_and_performance/cnf-tuning-low-latency-nodes-with-perf-profile.adoc#cnf-protecting-low-latency-workloads_cnf-tuning-low-latency-nodes-with-perf-profile[How ExecCPUAffinity prevents latency spikes from exec operations].
```

### New feature — brief (no second paragraph)

```asciidoc
// OSDOCS-12345
Installing a cluster on {azure-full} uses Marketplace images by default::
+
As of this update, the {product-title} installation program uses Marketplace images by default when installing a cluster on {azure-short}. This speeds up the installation by removing the need to upload a virtual hard disk to {azure-short} and create an image during installation. This feature is not supported on Azure Stack Hub, or for {azure-short} installations that use Confidential VMs.
```

### New feature — Technology Preview

```asciidoc
// OSDOCS-12346
Installing a cluster on {aws-short} with a user-provisioned DNS (Technology Preview)::
+
You can enable a user-provisioned domain name server (DNS) instead of the default cluster-provisioned DNS solution. For example, your organization's security policies might not allow the use of public DNS services such as {aws-first} DNS. If you use this feature, you must provide your own DNS solution that includes records for `api.<cluster_name>.<base_domain>.` and `*.apps.<cluster_name>.<base_domain>.`. Enabling a user-provisioned DNS is available as a Technology Preview feature.
+
For more information, see xref:../installing/installing_aws/ipi/installing-aws-customizations.adoc#installation-aws-enabling-user-managed-DNS_installing-aws-customizations[Enabling a user-managed DNS] and xref:../installing/installing_aws/ipi/installing-aws-customizations.adoc#installation-aws-provisioning-own-dns-records_installing-aws-customizations[Provisioning your own DNS records].
```

### New feature — with bullet list

```asciidoc
MetalLB Operator status reporting::
+
You can now use enhanced MetalLB Operator reporting features to view real-time operational data for IP address allocation and Border Gateway Protocol (BGP) connectivity. Previously, viewing this information required manual log inspection across multiple controllers. With this release, you can monitor your network health and resolve connectivity issues directly through the following custom resources:
+
--
* `IPAddressPool`: Monitor cluster-wide IP address allocation through the `status` field to track usage and prevent address exhaustion.
* `ServiceBGPStatus`: Verify which service IP addresses are announced to specific BGP peers to ensure correct route advertisements.
* `BGPSessionStatus`: Check the real-time state of BGP and Bidirectional Forwarding Detection sessions to quickly identify connectivity drops.
--
+
For more information, see xref:../networking/ingress_load_balancing/metallb/monitoring-metallb-status.adoc[Monitoring MetalLB configuration status].
```

### New feature — with admonition block

```asciidoc
Support for {vmw-full} Foundation 9 and VMware Cloud Foundation 9::
+
You can now install {product-title} on {vmw-full} Foundation (VVF) 9 and VMware Cloud Foundation (VCF) 9.
+
[NOTE]
====
The following additional VCF and VVF components are outside the scope of Red Hat support:

* Management: VCF Operations, VCF Automation, VCF Fleet Management, and VCF Identity Broker.
* Networking: VMware NSX Container Plugin (NCP).
* Migration: VMware HCX.
====
```

### Technology Preview to GA example

```asciidoc
Running firmware upgrades for hosts in deployed bare metal clusters (Generally Available)::
+
For hosts in deployed bare metal clusters, you can update firmware attributes and the firmware image. As a result, you can run firmware upgrades and update BIOS settings for hosts that are already provisioned without fully deprovisioning them. Performing a live update to the `HostFirmwareComponents`, `HostFirmwareSettings`, or `HostUpdatePolicy` resource can be a destructive and destabilizing action. Perform these updates only after careful consideration.
+
This feature was introduced in {product-title} 4.18 with Technology Preview status. This feature is now supported as generally available in {product-title} {product-version}.
+
For more information, see xref:../installing/installing_bare_metal/bare-metal-postinstallation-configuration.adoc#bmo-performing-a-live-update-to-the-hostfirmwaresettings-resource_bare-metal-postinstallation-configuration[Performing a live update to the HostFirmwareSettings resource],
xref:../installing/installing_bare_metal/bare-metal-postinstallation-configuration.adoc#bmo-performing-a-live-update-to-the-hostfirmwarecomponents-resource_bare-metal-postinstallation-configuration[Performing a live update to the HostFirmwareComponents resource], and
xref:../installing/installing_bare_metal/bare-metal-postinstallation-configuration.adoc#bmo-setting-the-hostupdatepolicy-resource_bare-metal-postinstallation-configuration[Setting the HostUpdatePolicy resource].
```

### Known issue — simple with workaround

```asciidoc
* Currently, on clusters with SR-IOV network virtual functions configured, a race condition might occur between system services responsible for network device renaming and the TuneD service managed by the Node Tuning Operator. As a consequence, the TuneD profile might become degraded after the node restarts, leading to performance degradation. As a workaround, restart the TuneD pod to restore the profile state. (link:https://issues.redhat.com/browse/OCPBUGS-41934[OCPBUGS-41934])
```

### Known issue — multi-paragraph with code block

```asciidoc
* If you mirrored the {product-title} release images to the registry of a disconnected environment by using the `oc adm release mirror` command, the release image Sigstore signature is not mirrored with the image.
+
This has become an issue in {product-title} {product-version}, because the `openshift` cluster image policy is now deployed to the cluster by default. This policy causes CRI-O to automatically verify the Sigstore signature when pulling images into a cluster. (link:https://issues.redhat.com/browse/OCPBUGS-70297[OCPBUGS-70297])
+
If you cannot use the oc-mirror plugin v2, you can use the `oc image mirror` command to mirror the Sigstore signature into your mirror registry by using a command similar to the following:
+
--
[source,terminal]
----
$ oc image mirror "quay.io/openshift-release-dev/ocp-release:${RELEASE_DIGEST}.sig" "${LOCAL_REGISTRY}/${LOCAL_RELEASE_IMAGES_REPOSITORY}:${RELEASE_DIGEST}.sig"
----
--
```

### Known issue — with recovery steps list

```asciidoc
* While Day 2 firmware updates and BIOS attribute reconfiguration for bare-metal hosts are generally available with this release, the Bare Metal Operator (BMO) does not provide a native mechanism to cancel a firmware update request once initiated. If a firmware update or setting change for `HostFirmwareComponents` or `HostFirmwareSettings` resources fails, returns an error, or becomes indefinitely stuck, you can try to recover by using the following steps:
+
--
* Removing the changes to the `HostFirmwareComponents` and `HostFirmwareSettings` resources.
* Setting the node to `online: false` to trigger a reboot.
* If the issue persists, deleting the Ironic pod.
--
+
A native abort capability for servicing operations might be planned for a future release.
```

### Bug fix examples

Multiple bug fixes under a category subsection:

```asciidoc
[id="rn-ocp-release-note-installer-fixed-issues_{context}"]
== Installer

* Before this update, the vSphere platform configuration lacked a validation check to prevent the simultaneous definition of both a custom virtual machine template and a `clusterOSImage` parameter. As a consequence, users could provide both parameters in the installation configuration, leading to ambiguity and potential deployment failures. With this release, the vSphere validation logic has been updated to ensure that template and `clusterOSImage` parameters are treated as mutually exclusive, returning a specific error message if both fields are populated. (link:https://issues.redhat.com/browse/OCPBUGS-63584[OCPBUGS-63584])

* Before this update, a race condition occurred when multiple reconciliation loops or concurrent processes attempted to add a virtual machine (VM) to a vSphere Host Group simultaneously due to the provider lacking a check to see if the VM was already a member. Consequently, the vSphere API could return errors during the cluster reconfiguration task, leading to reconciliation failures and preventing the VM from being correctly associated with its designated zone or host group. With this release, the zonal logic has been updated to verify the VM's membership within the target host group before initiating a reconfiguration task, ensuring the operation is only performed if the VM is not already present. (link:https://issues.redhat.com/browse/OCPBUGS-60765[OCPBUGS-60765])
```

Single bug fix under a category:

```asciidoc
[id="rn-ocp-release-note-networking-fixed-issues_{context}"]
== Networking

* Before this update, an incorrect private key containing certificate data caused HAProxy reload failure in {product-title} 4.14. As a consequence, incorrect certificate configuration caused HAProxy router pods to fail reloads, which led to a partial outage. With this release, `haproxy` now validates certificates. As a result, router reload failures with invalid certificates are prevented. (link:https://issues.redhat.com/browse/OCPBUGS-49769[OCPBUGS-49769])
```

### Z-stream fixed issue

```asciidoc
* Before this update, the egress IP address was incorrectly assigned to the br-ex bridge when you configured additional interfaces. This issue caused egress IP address assignment conflicts and routing issues with unexpected traffic paths. With this release, the egress IP address is not assigned to the br-ex bridge. As a result, the egress IP address is correctly assigned to the secondary interface, which resolves routing conflicts. (link:https://redhat.atlassian.net/browse/OCPBUGS-77257[OCPBUGS-77257])
```

### Z-stream enhancement (with continuation)

```asciidoc
* With this release, the Insights Operator now collects the `opentelemetrycollectors.opentelemetry.io` custom resource to improve data retrieval efficiency and system performance.
+
To maintain security and prevent the collection of sensitive information, the Insights Operator applies the following constraints:

** Resource Limit: The Insights Operator collects a maximum of five OpenTelemetry Collector custom resources from the cluster.

** Data Masking: The Insights Operator retains only the service subsection of the `spec.config` field. It omits receivers, exporters, and other pipeline configuration details.
+
These improvements allow {product-title} to better analyze the efficiency of the data gathering process and provide more precise environment insights. (link:https://redhat.atlassian.net/browse/OCPBUGS-79534[OCPBUGS-79534])
```

## Integration with other skills

- **git-pr-reader**: Use to extract PR metadata, file diffs, and AsciiDoc content before drafting
- **docs-review-style**: Use after drafting to verify style guide compliance
- **rh-ssg-release-notes**: Use after drafting to verify SSG release note conventions
