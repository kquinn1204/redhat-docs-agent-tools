#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
TEST_DIR="${SKILL_DIR}/tests"

CONSOLE_URL=""
KUBEADMIN_PASSWORD=""
HEADED=""
CLEANUP="false"
TEST_NAME="metallb-install"

usage() {
  cat <<EOF
Usage: $(basename "$0") --console-url <url> --password <password> [options]

Run Playwright tests against a live OpenShift cluster.

Required:
  --console-url <url>    OpenShift console URL
  --password <password>  kubeadmin password

Options:
  --headed               Show browser window (default: headless)
  --cleanup              Uninstall operator after test
  --test <name>          Test spec name (default: metallb-install)
  --help                 Show this help
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --console-url) CONSOLE_URL="$2"; shift 2 ;;
    --password)    KUBEADMIN_PASSWORD="$2"; shift 2 ;;
    --headed)      HEADED="--headed"; shift ;;
    --cleanup)     CLEANUP="true"; shift ;;
    --test)        TEST_NAME="$2"; shift 2 ;;
    --help)        usage ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$CONSOLE_URL" || -z "$KUBEADMIN_PASSWORD" ]]; then
  echo "Error: --console-url and --password are required" >&2
  usage
fi

TEST_FILE="${TEST_DIR}/${TEST_NAME}.spec.ts"
if [[ ! -f "$TEST_FILE" ]]; then
  echo "Error: test spec not found: ${TEST_FILE}" >&2
  echo "Available tests:" >&2
  ls "${TEST_DIR}"/*.spec.ts 2>/dev/null | sed 's|.*/||; s|\.spec\.ts||' >&2
  exit 1
fi

# Ensure Playwright is installed
if ! command -v npx &>/dev/null; then
  echo "Error: npx not found. Install Node.js 18+ first." >&2
  exit 1
fi

cd "$SKILL_DIR"

if [[ ! -d node_modules/@playwright ]]; then
  echo "Installing Playwright and dependencies..."
  npm init -y --silent 2>/dev/null || true
  npm install --save-dev @playwright/test 2>&1
  npx playwright install chromium 2>&1
fi

export CONSOLE_URL
export KUBEADMIN_PASSWORD
export CLEANUP

echo "Running test: ${TEST_NAME}"
echo "Console URL: ${CONSOLE_URL}"
echo "Headed: ${HEADED:-headless}"
echo "Cleanup: ${CLEANUP}"
echo "---"

npx playwright test "$TEST_FILE" \
  --project=chromium \
  --reporter=list \
  ${HEADED} \
  || exit_code=$?

if [[ ${exit_code:-0} -ne 0 ]]; then
  echo "---"
  echo "FAILED: Test ${TEST_NAME} failed with exit code ${exit_code:-1}"
  if [[ -d "${SKILL_DIR}/test-results" ]]; then
    echo "Screenshots saved to: ${SKILL_DIR}/test-results/"
  fi
  exit "${exit_code:-1}"
fi

echo "---"
echo "PASSED: ${TEST_NAME}"
