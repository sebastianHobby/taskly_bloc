# CI/CD Quick Reference

## 📋 Summary of Improvements

### ✅ What's Been Implemented

1. **Enhanced Main Workflow** (`.github/workflows/main.yaml`)
   - ✨ Matrix builds for Web, iOS, and Windows
   - 📊 Coverage reporting with 80% minimum threshold
   - 🔒 Security scanning with Trivy
   - ⚡ Dependency caching for faster builds
   - 🎯 Code analysis with fatal warnings
   - ⏰ Scheduled daily runs to catch dependency issues

2. **GitHub Pages Deployment** (`.github/workflows/deploy-web.yaml`)
   - 🌐 Automated deployment on push to main
   - 🔀 Client-side routing support (404.html trick)
   - 📦 Proper base-href configuration
   - 🚫 .nojekyll file for Flutter compatibility
   - ⚡ Optimized with caching

3. **Preview Builds** (`.github/workflows/preview.yaml`)
   - 👀 Automatic preview builds on PRs
   - 💬 Comments on PRs with artifact info
   - ⏱️ 3-day artifact retention
   - 🚫 Skips draft PRs

4. **Existing Workflows**
   - ✅ Semantic PR validation (from Very Good Workflows)
   - ✅ Spell checking for documentation
   - ✅ Dependabot for dependency updates

## 🚀 Quick Actions

### Deploy to GitHub Pages
```bash
# Push to main branch
git push origin main

# Or manually trigger
# Go to Actions → Deploy to GitHub Pages → Run workflow
```

### Run Tests Locally
```bash
# All tests
flutter test

# With coverage
flutter test --coverage

# View coverage
genhtml coverage/lcov.info -o coverage/html
start coverage/html/index.html  # Windows
open coverage/html/index.html   # macOS
```

### Build Web Locally
```bash
# Development build
flutter build web --debug

# Production build (like CI)
flutter build web --release --base-href "/taskly_bloc/"

# Serve locally
cd build/web
python -m http.server 8000  # Python
# or
npx serve .                  # Node.js
```

### Check Code Quality
```bash
# Run analyzer
flutter analyze

# Check formatting
dart format --set-exit-if-changed .

# Fix formatting
dart format .
```

### Generate Code
```bash
# Generate all code
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (for development)
flutter pub run build_runner watch --delete-conflicting-outputs
```

## 📦 Workflow Status Badges

Add these to your README.md:

```markdown
[![CI](https://github.com/sebastianHobby/taskly_bloc/actions/workflows/main.yaml/badge.svg)](https://github.com/sebastianHobby/taskly_bloc/actions/workflows/main.yaml)
[![Deploy](https://github.com/sebastianHobby/taskly_bloc/actions/workflows/deploy-web.yaml/badge.svg)](https://github.com/sebastianHobby/taskly_bloc/actions/workflows/deploy-web.yaml)
[![codecov](https://codecov.io/gh/sebastianHobby/taskly_bloc/branch/main/graph/badge.svg)](https://codecov.io/gh/sebastianHobby/taskly_bloc)
```

## 🔧 Configuration Checklist

### GitHub Repository Settings

- [ ] **Enable GitHub Pages**
  - Settings → Pages → Source: GitHub Actions

- [ ] **Add Repository Secrets** (if using Codecov)
  - Settings → Secrets → Actions → New secret
  - Name: `CODECOV_TOKEN`
  - Value: From https://codecov.io

- [ ] **Configure Branch Protection** (Optional but recommended)
  - Settings → Branches → Add rule for `main`
  - Require PR reviews
  - Require status checks: `build`, `analyze`, `test`

### Supabase Configuration for Web

- [ ] **Add GitHub Pages domain to allowed origins**
  - Supabase Dashboard → Authentication → URL Configuration
  - Add: `https://sebastianhobby.github.io`

- [ ] **Configure redirect URLs**
  - Add: `https://sebastianhobby.github.io/taskly_bloc/*`

## 🎯 Key Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Test Coverage | TBD | ≥ 80% |
| Build Time | ~25 min | < 20 min |
| Success Rate | TBD | > 95% |
| Security Issues | TBD | 0 high/critical |

## 🔍 Troubleshooting

### ❌ Build Fails on `build_runner`
```bash
# Clean and regenerate
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### ❌ GitHub Pages Shows 404
1. Wait 5-10 minutes for deployment
2. Check Actions tab for failed deployments
3. Verify repository Settings → Pages is configured
4. Clear browser cache

### ❌ Web App Doesn't Load on GitHub Pages
1. **Check browser console** for errors
2. **CORS issues?** Add GitHub Pages domain to Supabase
3. **Assets not loading?** Verify base-href is `/taskly_bloc/`
4. **Service Worker issues?** Clear browser cache and hard reload

### ❌ Coverage Below 80%
```bash
# Find uncovered code
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
start coverage/html/index.html

# Common areas needing tests:
# - Domain models
# - Business logic
# - Repositories
# - BLoCs
```

### ❌ Security Scan Failures
1. Check Security tab for details
2. Update vulnerable dependencies: `flutter pub upgrade`
3. Review and address legitimate vulnerabilities
4. Create issues for false positives

## 📚 Best Practices

### Before Committing
```bash
# Run checks locally
flutter analyze
dart format .
flutter test
```

### Before Merging PR
```bash
# Rebase on latest main
git checkout main
git pull
git checkout your-feature-branch
git rebase main

# Ensure all tests pass
flutter test

# Squash commits if needed
git rebase -i HEAD~n
```

### Writing Commit Messages
Follow Conventional Commits format:
```
feat: add new feature
fix: resolve bug
docs: update documentation
test: add tests
chore: update dependencies
ci: improve workflows
```

## 🚀 Next Steps

1. **Review workflows** - Check that all jobs pass successfully
2. **Enable GitHub Pages** - Configure in repository settings
3. **Add badges** - Update README with workflow status badges
4. **Test deployment** - Verify web app works on GitHub Pages
5. **Configure branch protection** - Require checks before merging
6. **Set up Codecov** (optional) - For coverage tracking
7. **Monitor Actions usage** - Track minutes usage for cost control

## 📖 Related Documentation

- [Main CI/CD Documentation](.github/CICD.md) - Comprehensive guide
- [Testing Guide](../test/TESTING_GUIDE.md) - Testing best practices
- [README](../README.md) - Project overview

## 🤝 Contributing

When adding new workflows:
1. Test locally with [act](https://github.com/nektos/act) if possible
2. Use caching to reduce build times
3. Set appropriate timeout limits
4. Add clear job descriptions
5. Update this quick reference

---

**Last Updated:** December 31, 2025
