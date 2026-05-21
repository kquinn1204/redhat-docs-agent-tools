---
name: docs-playwright-test
description: Run Playwright tests against a live OpenShift cluster to validate documented web console procedures. Currently supports MetalLB Operator installation.
argument-hint: --console-url <url> --password <password> [--headed] [--cleanup]
allowed-tools: Bash, Read
---

# Playwright Procedure Test

Validates OpenShift web console procedures against a live cluster using Playwright. Drives a real browser through the documented steps and reports pass/fail.

## Prerequisites

- Node.js 18+ installed
- `oc` CLI authenticated to the target cluster (for cleanup and verification)
- Network access to the OpenShift console URL

## Usage

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/run_test.sh \
  --console-url <url> --password <password> \
  [--headed] [--cleanup] [--test <test-name>]
```

## Options

| Option | Description |
|--------|-------------|
| `--console-url <url>` | OpenShift console URL (required) |
| `--password <password>` | kubeadmin password (required) |
| `--headed` | Show the browser window (default: headless) |
| `--cleanup` | Uninstall the operator after test |
| `--test <name>` | Test spec to run (default: `metallb-install`) |

## Available tests

| Test | Procedure |
|------|-----------|
| `metallb-install` | Installing MetalLB Operator from the software catalog using the web console |

## Output

The script exits 0 on success, 1 on failure. On failure, a screenshot is saved to `test-results/` in the skill directory. Read stdout for the Playwright test report.

## Example

```bash
# Headless run
bash ${CLAUDE_SKILL_DIR}/scripts/run_test.sh \
  --console-url https://console-openshift-console.apps.sno.example.com \
  --password "my-kubeadmin-password"

# Headed with cleanup
bash ${CLAUDE_SKILL_DIR}/scripts/run_test.sh \
  --console-url https://console-openshift-console.apps.sno.example.com \
  --password "my-kubeadmin-password" \
  --headed --cleanup
```
