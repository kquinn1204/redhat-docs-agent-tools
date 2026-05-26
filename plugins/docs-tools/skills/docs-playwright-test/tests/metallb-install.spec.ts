import { test, expect } from '@playwright/test';
import { execSync } from 'child_process';

const CONSOLE_URL = process.env.CONSOLE_URL!;
const KUBEADMIN_PASSWORD = process.env.KUBEADMIN_PASSWORD!;
const CLEANUP = process.env.CLEANUP === 'true';

test.use({
  ignoreHTTPSErrors: true,
});

test.describe('MetalLB Operator install via web console', () => {
  // Procedure: metallb-installing-using-web-console.adoc
  // Source: openshift-docs/networking/networking_operators/metallb-operator/modules/

  test.setTimeout(180_000);

  test.beforeEach(async ({ page }) => {
    // Prerequisite: Log in as a user with cluster-admin privileges
    await page.goto(`${CONSOLE_URL}`);

    // Some clusters show an identity provider selection page, others go
    // directly to the login form, and single-provider clusters may auto-
    // redirect all the way to the console.
    const alreadyLoggedIn = await page
      .waitForURL(/.*\/dashboards|.*\/overview/, { timeout: 5_000 })
      .then(() => true)
      .catch(() => false);

    if (!alreadyLoggedIn) {
      // If the provider selection page is shown, click kubeadmin
      const idpLink = page.getByRole('link', { name: /kube:admin/i });
      const loginField = page.getByLabel('Username');
      const firstVisible = await Promise.race([
        idpLink.waitFor({ timeout: 10_000 }).then(() => 'idp' as const),
        loginField.waitFor({ timeout: 10_000 }).then(() => 'login' as const),
      ]);

      if (firstVisible === 'idp') {
        await idpLink.click();
      }

      await page.getByLabel('Username').fill('kubeadmin');
      await page.getByLabel('Password').fill(KUBEADMIN_PASSWORD);
      await page.getByRole('button', { name: 'Log in' }).click();

      await page.waitForURL(/.*\/dashboards|.*\/overview/, { timeout: 30_000 });
    }
  });

  test('install MetalLB from software catalog', async ({ page }) => {
    // Step 1: Navigate to Ecosystem -> Software Catalog
    await page.getByRole('button', { name: /Ecosystem/i }).click();
    await page.getByRole('link', { name: /Software Catalog/i }).click();
    await expect(page).toHaveURL(/catalog|operatorhub/, { timeout: 15_000 });

    // Step 2: Type "metallb" into the Filter by keyword box
    await page.getByPlaceholder(/filter by keyword/i).fill('metallb');

    // Wait for tile to appear and click MetalLB Operator
    const metallbTile = page.locator(
      '[data-test^="metallb"], .catalog-tile-pf, [class*="catalog"] a, [class*="tile"]'
    )
      .filter({ hasText: /MetalLB Operator/i })
      .first();
    await expect(metallbTile).toBeVisible({ timeout: 10_000 });
    await metallbTile.click();

    // Click Install on the side panel or detail page
    await page.getByRole('button', { name: 'Install' }).click();

    // Step 3: On the Install Operator page, accept defaults and click Install
    await page.waitForURL(/subscribe|install-operator|operatorhub/, { timeout: 10_000 });
    await page.getByRole('button', { name: 'Install' }).click();

    // Wait for the install to be acknowledged — the page shows an
    // "Installing Operator" status or a "View installed Operators" link
    const viewInstalledLink = page.getByRole('link', {
      name: /View installed Operators/i,
    });
    await expect(viewInstalledLink).toBeVisible({ timeout: 60_000 });

    // Verification Step 1: Navigate to Ecosystem -> Installed Operators
    // The operator installs to metallb-system namespace by default
    await page.goto(
      `${CONSOLE_URL}/k8s/ns/metallb-system/operators.coreos.com~v1alpha1~ClusterServiceVersion`
    );

    // Verification Step 2: Check MetalLB status is Succeeded
    const metallbRow = page.locator('tr').filter({ hasText: /MetalLB/i });
    await expect(metallbRow).toBeVisible({ timeout: 30_000 });

    await expect(
      metallbRow.getByText(/Succeeded/i)
    ).toBeVisible({ timeout: 120_000 });
  });

  test.afterEach(async ({}, testInfo) => {
    // Take screenshot on failure
    if (testInfo.status !== 'passed') {
      console.log(`Test failed: ${testInfo.title}`);
    }

    if (CLEANUP) {
      try {
        execSync(
          'oc delete subscription metallb-operator -n metallb-system --ignore-not-found',
          { timeout: 30_000 }
        );
        execSync(
          'oc delete csv -n metallb-system -l operators.coreos.com/metallb-operator.metallb-system= --ignore-not-found',
          { timeout: 30_000 }
        );
        console.log('Cleanup: MetalLB Operator removed');
      } catch (e) {
        console.warn('Cleanup warning:', e);
      }
    }
  });
});
