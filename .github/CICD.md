# CI/CD Pipeline Documentation

## Overview

This project uses GitHub Actions for continuous integration and deployment. The workflows are designed to ensure code quality, run comprehensive tests, and deploy the web application to GitHub Pages.

## Workflows

### 1. Main CI/CD Pipeline (`main.yaml`)

**Trigger:** Push to `main` branch, Pull Requests, Manual workflow dispatch, Daily scheduled runs at 2 AM UTC

**Jobs:**

#### `test`
- Runs all tests with detailed coverage reporting
- Uploads coverage to Codecov for tracking
- Caches dependencies for faster builds
- Validates coverage meets 80% threshold
- **Timeout:** 30 minutes

#### `analyze`
- Runs `flutter analyze` with fatal warnings
- Checks code formatting consistency
- **Checks for unsafe testWidgets usage** (files using `pumpAndSettle` must use `testWidgetsSafe`)
- **Validates IdGenerator table registration** (all PowerSync tables must be registered)
- Ensures code quality standards
- **Timeout:** 20 minutes

#### `build-web-smoke`
- Runs a production web build smoke check on Ubuntu
- Validates release web compilation
- **Timeout:** 30 minutes

#### `build-ios-unsigned-ipa`
- Runs iOS build on `macos-latest` with `--no-codesign`
- Packages `build/ios/iphoneos/Runner.app` into `Runner-unsigned.ipa`
- Uploads artifact `ios-unsigned-ipa` (7-day retention)
- Intended for AltStore/manual sideloading flows
- Skips scheduled runs to reduce macOS CI consumption
- **Timeout:** 45 minutes

### 2. GitHub Pages Deployment (`deploy-web.yaml`)

**Trigger:** Push to `main` branch, Manual workflow dispatch

**Process:**
1. **Build Job:**
   - Checks out code
   - Sets up Flutter 3.38.x stable
   - Caches dependencies
   - Generates code with build_runner
   - Builds web with correct base href: `/taskly_bloc/`
   - Adds `.nojekyll` file (prevents Jekyll processing)
   - Copies `index.html` to `404.html` (enables client-side routing)
   - Uploads build artifact

2. **Deploy Job:**
   - Deploys to GitHub Pages environment
   - Requires `build` job completion
   - Sets up proper page URL

**Output:** Web app available at `https://sebastianhobby.github.io/taskly_bloc/`

## Setup Instructions

### 1. Enable GitHub Pages

GitHub Pages needs to be configured to use GitHub Actions as the deployment source. Here's how to set it up:

#### Step-by-Step Instructions

1. **Navigate to Repository Settings**
   - Go to your GitHub repository: `https://github.com/sebastianHobby/taskly_bloc`
   - Click the **Settings** tab (you need admin/write access)
   - If you don't see Settings, you may not have the required permissions

2. **Access GitHub Pages Settings**
   - In the left sidebar, scroll down to the **Code and automation** section
   - Click on **Pages** (should be near the bottom of the list)
   - You'll be taken to the GitHub Pages configuration page

3. **Configure the Source**
   - Under the **Build and deployment** section, locate **Source**
   - Click the dropdown menu (it may say "Deploy from a branch" by default)
   - Select **GitHub Actions** from the options
   - No need to click "Save" - this setting is applied immediately

4. **Verify Configuration**
   - After selecting GitHub Actions, you should see a message confirming the source
   - The page will show: "Your site is ready to be published at `https://sebastianhobby.github.io/taskly_bloc/`"
   - Note: The site won't actually be live until the first deployment completes

#### What Happens Next

Once configured, GitHub Pages will:
- ✅ Wait for the `deploy-web.yaml` workflow to run
- ✅ Create a special `github-pages` environment (visible in your repository)
- ✅ Generate a deployment URL: `https://sebastianhobby.github.io/taskly_bloc/`
- ✅ Provide deployment status in the Actions tab

#### Triggering the First Deployment

You have two options to trigger the initial deployment:

**Option A: Push to Main Branch**
```bash
# Make any commit to main branch
git add .
git commit -m "chore: trigger initial deployment"
git push origin main
```

**Option B: Manual Workflow Dispatch**
1. Go to the **Actions** tab in your repository
2. Click on **Deploy to GitHub Pages** in the left sidebar
3. Click the **Run workflow** button (top right)
4. Select the `main` branch
5. Click **Run workflow**

#### Monitoring the Deployment

1. **Check Workflow Progress**
   - Go to **Actions** tab
   - Click on the running **Deploy to GitHub Pages** workflow
   - You'll see two jobs: `build` and `deploy`
   - Total time: ~3-5 minutes (first run may be longer)

2. **View Deployment Status**
   - Go to **Settings** → **Pages**
   - You'll see "Your site is live at..." with a green checkmark
   - Click **Visit site** to open your deployed app

3. **Check Environments**
   - Go to your repository's main page
   - Click **Environments** on the right sidebar (under About)
   - You'll see `github-pages` environment with deployment history
   - Each deployment shows the commit hash and timestamp

#### Verifying the Deployment

After the first successful deployment:

1. **Visit the URL**
   - Navigate to: `https://sebastianhobby.github.io/taskly_bloc/`
   - You should see your Flutter web app loading
   - Initial load may take a few seconds

2. **Check Browser Console**
   - Open Developer Tools (F12)
   - Look for any errors in the Console tab
   - Common issues: CORS errors, asset loading failures

3. **Test Navigation**
   - Try navigating to different routes
   - Use browser back/forward buttons
   - Refresh the page on a deep link
   - All routes should work (thanks to 404.html trick)

#### Troubleshooting

**Problem: "Settings" tab not visible**
- **Cause:** Insufficient permissions
- **Solution:** You need admin or write access to the repository
- **Action:** Contact the repository owner to grant access or enable Pages

**Problem: "GitHub Actions" not in Source dropdown**
- **Cause:** Repository may not be public, or Actions are disabled
- **Solution:** 
  - For private repos: Ensure you have GitHub Pro or organization plan
  - Go to **Settings** → **Actions** → **General**
  - Enable "Allow all actions and reusable workflows"

**Problem: Deployment fails with permission error**
- **Cause:** Missing workflow permissions
- **Solution:** 
  - Go to **Settings** → **Actions** → **General**
  - Scroll to **Workflow permissions**
  - Select "Read and write permissions"
  - Check "Allow GitHub Actions to create and approve pull requests"
  - Click **Save**

**Problem: Site shows 404 after deployment**
- **Cause:** GitHub Pages propagation delay
- **Solution:** Wait 5-10 minutes and try again
- **Alternative:** Clear browser cache (Ctrl+Shift+Delete)

**Problem: "Your site is being built from" shows wrong source**
- **Cause:** Cached settings or browser issue
- **Solution:** 
  - Hard refresh the Settings page (Ctrl+F5)
  - Disable any browser extensions that might interfere
  - Try a different browser or incognito mode

**Problem: Assets not loading (404 on CSS/JS files)**
- **Cause:** Incorrect base-href configuration
- **Solution:** Verify `deploy-web.yaml` has `--base-href "/taskly_bloc/"`
- **Check:** Repository name must match the base-href path

#### Important Notes

⚠️ **Repository Name Matters**
- Your base-href must match your repository name: `/taskly_bloc/`
- If you rename the repository, you must update the base-href in `deploy-web.yaml`
- Format: `--base-href "/<repository-name>/"`

⚠️ **Public vs Private Repositories**
- GitHub Pages for private repos requires GitHub Pro, Team, or Enterprise
- Public repositories get unlimited GitHub Pages hosting for free
- Private repo deployments count against Actions minutes

⚠️ **HTTPS and Custom Domains**
- GitHub Pages serves all sites over HTTPS automatically
- Custom domains can be configured after initial setup
- Custom domain setup is in **Settings** → **Pages** → **Custom domain**

⚠️ **Build Artifacts**
- Only the `build/web` directory is deployed
- Total size limit: 1 GB per repository
- Individual file limit: 100 MB
- Consider optimizing images and assets

#### Next Steps After Enabling

Once GitHub Pages is enabled and the first deployment succeeds:

1. ✅ **Update README** - Add the live site link
2. ✅ **Configure Supabase** - Add GitHub Pages domain to allowed origins (see Step 2)
3. ✅ **Test thoroughly** - Verify all features work on the deployed site
4. ✅ **Set up monitoring** - Consider adding error tracking (Sentry, etc.)
5. ✅ **Share the link** - Your app is now publicly accessible!

#### Additional Configuration Options

**Custom Domain Setup** (Optional)
1. Go to **Settings** → **Pages**
2. Under **Custom domain**, enter your domain (e.g., `tasks.yourdomain.com`)
3. Click **Save**
4. Add a CNAME record in your DNS settings pointing to `sebastianhobby.github.io`
5. Wait for DNS propagation (up to 24 hours)
6. Enable **Enforce HTTPS** once DNS is configured

**Environment-Specific Deployments** (Advanced)
- Create separate workflows for staging/production
- Use different base-href values
- Configure environment-specific secrets
- Set up deployment protection rules

### 2. Configure Required Repository Secrets

If you use entrypoint-based build-time configuration (for example
`lib/main_prod.dart`), the workflows do **not** require Supabase/PowerSync
values to be passed as GitHub Secrets.

You may still choose to configure secrets if you want CI to inject environment
values (for example, staging vs prod without changing source), but it is
optional.

#### Step-by-Step Secret Configuration

1. **Navigate to Secrets Settings**
   - Go to your repository: `https://github.com/sebastianHobby/taskly_bloc`
   - Click **Settings** → **Secrets and variables** → **Actions**
   - You'll see options for **Repository secrets** and **Environment secrets**

2. **Add Optional Secrets**
   Click **New repository secret** for any of the following (only needed if CI
   injects config or generates config files):

   **`SUPABASE_URL`**
   - Your Supabase project URL
   - Format: `https://xxxxx.supabase.co`
   - Find in Supabase dashboard → Project Settings → API

   **`SUPABASE_PUBLISHABLE_KEY`**
   - Your Supabase anonymous/public key
   - Format: Long alphanumeric string starting with `eyJ...`
   - Find in Supabase dashboard → Project Settings → API → anon/public key

   **`POWERSYNC_URL`**
   - Your PowerSync instance URL
   - Format: `https://xxxxx.powersync.com`
   - Find in PowerSync dashboard

3. **Verify Secrets Configuration**
   - After adding all secrets, you should see 3 secrets listed
   - Secret values are hidden and cannot be viewed after creation
   - You can update secrets by clicking on them and entering new values

#### Optional Secrets

For Codecov integration:
- **`CODECOV_TOKEN`** - Get from https://codecov.io after signing up
- Not required but recommended for detailed coverage reports

#### Security Best Practices

⚠️ **Client-side config is not secret**
- Values like `SUPABASE_URL` and publishable/anon keys are not secrets once
   shipped in an app.
- Protect data via Supabase auth + RLS policies.

⚠️ **Rotate secrets regularly**
- Change passwords every 90 days
- Update API keys when team members leave
- Use different credentials for CI/CD vs local development

⚠️ **Least privilege principle**
- Use read-only credentials where possible
- Dev credentials should have limited permissions
- Production secrets should be environment-specific

### 3. iOS Unsigned IPA (AltStore) Notes

This pipeline does **not** perform Apple code signing. It produces an unsigned
`.ipa` artifact for AltStore to sign with your linked Apple ID.

Required project/repo conditions:

1. `ios/Runner.xcodeproj` must continue to build for device in Release mode.
2. Keep a stable and unique iOS bundle identifier (`PRODUCT_BUNDLE_IDENTIFIER`)
   in the iOS project.
3. No Apple certificates/provisioning profiles are required in GitHub Secrets
   for this workflow because build uses `--no-codesign`.
4. If Flutter or Xcode compatibility changes, pin/update versions in workflow
   first and verify device build output still succeeds.

Artifact usage:

1. Run `taskly_bloc` workflow (push/PR or manually with workflow dispatch).
2. Download artifact `ios-unsigned-ipa`.
3. Install with AltStore (`My Apps` -> `+` -> select `.ipa`).

### 4. Branch Protection Rules (Recommended)

1. Go to **Settings** → **Branches** → **Add rule**
2. Branch name pattern: `main`
3. Enable:
   - ✅ Require a pull request before merging
   - ✅ Require status checks to pass before merging
     - Select: `analyze`, `test`, `build-web-smoke`, `build-ios-unsigned-ipa`
   - ✅ Require branches to be up to date before merging
   - ✅ Require conversation resolution before merging

### 5. Required GitHub Permissions

The workflows automatically request these permissions:
- **Contents:** Read (for checking out code)
- **Pages:** Write (for deploying to GitHub Pages)
- **ID Token:** Write (for GitHub Pages deployment authentication)
- **Security Events:** Write (for uploading security scan results)

## Optimizations Implemented

### Caching Strategy
- **Pub Dependencies:** Cached by pubspec.lock hash
- **Flutter SDK:** Cached by subosito/flutter-action
- Reduces build time by ~2-3 minutes

### Concurrency Control
- Only one workflow run per branch at a time
- Cancels outdated runs automatically
- Prevents resource waste

### Failure Handling
- Each job has appropriate timeout limits
- Scheduled runs skip macOS IPA build to reduce cost
- Web deployment is isolated in `deploy-web.yaml`

### Performance
- Parallel job execution where possible
- Optimized for fastest feedback on PRs
- Artifact retention limited to 7 days

## Web Deployment Details

### Base URL Configuration
The web app is built with `--base-href "/taskly_bloc/"` to work correctly as a subdirectory on GitHub Pages.

### Client-Side Routing
- `.nojekyll` file prevents GitHub Pages from ignoring `_` prefixed files
- `404.html` copy of `index.html` enables deep linking
- All routes are handled by Flutter's router (go_router)

### Important Considerations

⚠️ **Supabase/PowerSync Configuration**
- Web builds may require environment variables for API endpoints
- Consider using GitHub Secrets for sensitive configuration
- Web build may need different Supabase configuration than mobile

⚠️ **CORS Configuration**
- Ensure Supabase API allows requests from GitHub Pages domain
- Add `https://sebastianhobby.github.io` to allowed origins

⚠️ **Local Storage**
- Web uses browser local storage for drift/PowerSync
- Users may need to enable third-party cookies
- Data persistence requires user consent

## Continuous Improvement Recommendations

### Short Term (1-2 weeks)
1. [ ] Add Codecov badge to README
2. [ ] Configure Codecov coverage thresholds
3. [ ] Add integration test job (if applicable)
4. [ ] Set up environment-specific builds (dev/staging/prod)

### Medium Term (1-2 months)
1. [ ] Add automated release workflow
2. [ ] Implement semantic versioning
3. [ ] Add changelog generation
4. [ ] Set up automated dependency updates (already have Dependabot)
5. [ ] Add performance benchmarking

### Long Term (3+ months)
1. [ ] Add E2E tests with Playwright or similar
2. [ ] Implement blue-green deployment strategy
3. [ ] Add deployment previews for PRs
4. [ ] Set up monitoring and error tracking
5. [ ] Add automated rollback on failure

## Troubleshooting

### Build Fails Due to Code Generation
**Solution:** Ensure all models are properly annotated and build_runner completes successfully locally first.

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Dependency Conflict with envied_generator

**Issue:** `envied_generator ^1.3.2` requires `analyzer >=8.0.0` which conflicts with Flutter SDK's test packages.

**Note:** This repo now supports entrypoint-based build-time configuration
(for example `lib/main_prod.dart`), so GitHub Secrets are not required just to
provide Supabase/PowerSync endpoints for builds.

**pubspec.yaml Configuration:**
```yaml
dependency_overrides:
  envied_generator: 1.3.2
```

**Workflow Steps (optional):**
If you choose to generate config files in CI, add steps like the following
before code generation:
```yaml
- name: Get dependencies
  run: flutter pub get

- name: Create .env file
  run: |
    echo "SUPABASE_URL=${{ secrets.SUPABASE_URL }}" >> .env
    echo "SUPABASE_PUBLISHABLE_KEY=${{ secrets.SUPABASE_PUBLISHABLE_KEY }}" >> .env
    echo "POWERSYNC_URL=${{ secrets.POWERSYNC_URL }}" >> .env

- name: Generate code
  run: flutter pub run build_runner build --delete-conflicting-outputs
```

**Local Development:**
If you encounter dependency conflicts locally:
1. Run `flutter pub get`
2. Run code generation: `dart run build_runner build --delete-conflicting-outputs`

### GitHub Pages Shows 404
**Solutions:**
1. Verify GitHub Pages is enabled in repository settings
2. Check that base-href matches repository name
3. Ensure deployment job completed successfully
4. Wait 5-10 minutes for GitHub Pages to propagate

### Coverage Below Threshold
**Solution:** Add tests to increase coverage above 80%:
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # View coverage report
```

### Security Scan Failures
**Solution:** 
1. Review security scan results in Security tab
2. Update vulnerable dependencies
3. Consider adding exceptions for false positives

### Web App Not Loading on GitHub Pages
**Possible Issues:**
1. **CORS errors:** Configure Supabase allowed origins
2. **Service Worker issues:** Clear browser cache
3. **Asset loading:** Verify base-href configuration
4. **Environment variables:** Check web build configuration

## Monitoring and Metrics

### Key Metrics to Track
- **Build Success Rate:** Target > 95%
- **Average Build Time:** Current ~20-30 minutes
- **Test Coverage:** Target ≥ 80%
- **Security Vulnerabilities:** Target = 0 high/critical

### GitHub Actions Usage
- Monitor Actions usage in repository Insights → Actions
- Free tier: 2,000 minutes/month for private repos
- Public repos: Unlimited minutes

## Additional Resources

- [Flutter Web Documentation](https://docs.flutter.dev/platform-integration/web)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Very Good Workflows](https://github.com/VeryGoodOpenSource/very_good_workflows)
- [Andrea Bizzotto's Flutter Web Tutorial](https://codewithandrea.com/articles/flutter-web-github-pages/)
