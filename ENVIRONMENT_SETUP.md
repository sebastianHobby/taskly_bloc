# Environment Variables Setup

This project uses a dual-strategy approach for managing environment variables:

- **Local Development (Debug Mode):** Automatically loads from `.env` file for convenience
- **Production/CI (Release Mode):** Uses `--dart-define` compile-time constants for security

## 🔐 Security Principles

✅ **Local `.env` file** is:
- Gitignored (never committed)
- Read from filesystem (NOT bundled in app assets)
- Only loaded in debug mode on non-web platforms
- Convenient for local development without security risk

✅ **Production builds** use:
- `--dart-define` flags at compile time
- No runtime configuration files
- Secrets managed by CI/CD platform (GitHub Secrets)
- Industry-standard approach used by Firebase, Supabase, Sentry

## 📁 Local Development Setup

### 1. Create your `.env` file

Copy the example file:

```bash
cp .env.example .env
```

### 2. Fill in your values

Edit `.env` with your actual credentials:

```env
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=your_publishable_key_here

# PowerSync Configuration
POWERSYNC_URL=https://your-powersync-instance.journeyapps.com

# Development Auto-Login (Optional)
DEV_USERNAME=your_dev_email@example.com
DEV_PASSWORD=your_dev_password
```

### 3. Run the app

```bash
flutter run -d windows
```

The app automatically detects debug mode and loads from `.env` on non-web platforms.

### ⚠️ Web (Chrome) local development

Web builds cannot read `.env` from your filesystem, so you must provide values via
`--dart-define`.

Recommended (uses the repo's `dart_defines.json`):

```bash
flutter run -d chrome --dart-define-from-file=dart_defines.json
```

If you use VS Code, you can also start the existing launch config:
`taskly_bloc (dev - web)`.

## 🚀 Production Builds

### Build for platforms

Use `--dart-define` flags for all builds:

```bash
# Android
flutter build apk \
  --dart-define=SUPABASE_URL="https://your-project.supabase.co" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="your_key" \
  --dart-define=POWERSYNC_URL="https://your-instance.journeyapps.com" \
  --dart-define=DEV_USERNAME="" \
  --dart-define=DEV_PASSWORD=""

# iOS
flutter build ios \
  --dart-define=SUPABASE_URL="https://your-project.supabase.co" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="your_key" \
  --dart-define=POWERSYNC_URL="https://your-instance.journeyapps.com"

# Web
flutter build web --release --base-href "/taskly_bloc/" \
  --dart-define=SUPABASE_URL="https://your-project.supabase.co" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="your_key" \
  --dart-define=POWERSYNC_URL="https://your-instance.journeyapps.com"

# Windows
flutter build windows \
  --dart-define=SUPABASE_URL="https://your-project.supabase.co" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="your_key" \
  --dart-define=POWERSYNC_URL="https://your-instance.journeyapps.com"
```

## 🔧 CI/CD Setup

GitHub Actions workflows automatically use secrets:

### Required Secrets

Configure these in **Settings → Secrets and variables → Actions**:

1. `SUPABASE_URL` - Your Supabase project URL
2. `SUPABASE_PUBLISHABLE_KEY` - Your Supabase publishable/anon key
3. `POWERSYNC_URL` - Your PowerSync instance URL

See [`.github/SECRETS_SETUP.md`](.github/SECRETS_SETUP.md) for detailed setup instructions.

### Workflow Example

```yaml
- name: Build web
  run: |
    flutter build web --release \
      --dart-define=SUPABASE_URL="${{ secrets.SUPABASE_URL }}" \
      --dart-define=SUPABASE_PUBLISHABLE_KEY="${{ secrets.SUPABASE_PUBLISHABLE_KEY }}" \
      --dart-define=POWERSYNC_URL="${{ secrets.POWERSYNC_URL }}"
```

## 🧪 Running Tests

### Locally

Tests will use values from `.env` in debug mode:

```bash
flutter test
```

### With specific values

Override with `--dart-define`:

```bash
flutter test \
  --dart-define=SUPABASE_URL="https://test-project.supabase.co" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="test_key"
```

### In CI/CD

GitHub Actions provides secrets automatically:

```yaml
- name: Run tests
  run: |
    flutter test --coverage \
      --dart-define=SUPABASE_URL="${{ secrets.SUPABASE_URL }}" \
      --dart-define=SUPABASE_PUBLISHABLE_KEY="${{ secrets.SUPABASE_PUBLISHABLE_KEY }}" \
      --dart-define=POWERSYNC_URL="${{ secrets.POWERSYNC_URL }}"
```

## 📝 How It Works

### Code Implementation

```dart
// lib/core/environment/env.dart
class Env {
  static Future<void> load() async {
    // In debug mode, read from .env file if it exists
    if (kDebugMode && !kIsWeb) {
      final file = File('.env');
      if (await file.exists()) {
        dotenv.testLoad(fileInput: await file.readAsString());
      }
    }
  }

  // Getters check dotenv first (debug), then --dart-define (production)
  static String get supabaseUrl {
    if (kDebugMode && !kIsWeb && dotenv.maybeGet('SUPABASE_URL') != null) {
      return dotenv.get('SUPABASE_URL');
    }
    return const String.fromEnvironment('SUPABASE_URL');
  }
}
```

### Initialization

```dart
// lib/bootstrap.dart
Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  // ...
  await Env.load();  // Load environment configuration
  await setupDependencies();  // DI can now access Env values
  // ...
}
```

## ❌ What NOT to Do

🚫 **Never** add `.env` to git:
```bash
git add .env  # DON'T DO THIS!
```

🚫 **Never** add `.env` to Flutter assets:
```yaml
flutter:
  assets:
    - .env  # DON'T DO THIS!
```

🚫 **Never** hardcode secrets in code:
```dart
// DON'T DO THIS!
const apiKey = 'sk_live_abc123';
```

## ✅ Why This Approach?

### Comparison with Other Methods

| Method | Local Dev | Production | Security | Convenience |
|--------|-----------|------------|----------|-------------|
| **flutter_dotenv (our approach)** | ✅ Auto-load | ✅ --dart-define | ✅ Not bundled | ✅ Seamless |
| envied | ❌ Complex | ❌ Build conflicts | ⚠️ Obfuscation theater | ❌ CI/CD issues |
| Assets-bundled .env | ✅ Easy | ❌ Bundled in app | ❌ Extractable | ⚠️ Risky |
| Only --dart-define | ⚠️ Manual flags | ✅ Secure | ✅ Best | ❌ Tedious locally |
| VS Code launch.json | ✅ Works | ❌ IDE-specific | ✅ Secure | ⚠️ Not universal |

### Why Not envied?

The `envied` package was removed due to:
- **Dependency conflicts:** Incompatible analyzer version with Flutter SDK
- **CI/CD complexity:** Required workarounds that didn't work reliably
- **False security:** Obfuscation ≠ security; apps are decompilable
- **Overkill:** Supabase keys are meant to be public (use RLS for security)

## 🛡️ Security Notes

### "Public" Secrets

These values are intentionally public-safe:

- **Supabase URL** - Public endpoint, protected by RLS policies
- **Supabase Publishable Key** - Literally called "publishable", meant for client apps
- **PowerSync URL** - Public endpoint, authenticated via Supabase

**Real security** comes from:
- Supabase Row Level Security (RLS) policies
- Supabase Auth for user identity
- Server-side validation and rate limiting

### Mobile App Reality

**All secrets in mobile apps are extractable:**
- APK/IPA files can be decompiled
- Memory can be inspected at runtime
- Network traffic can be intercepted

**Solution:** Design APIs to be public-safe, use backend security.

## 🆘 Troubleshooting

### "Environment variable not set" error

**Problem:** Value is empty or null

**Solution:** Ensure either:
1. `.env` file exists with the value (local dev), OR
2. `--dart-define` flag is provided (production builds)

### Tests fail with "No credentials"

**Problem:** Tests don't have environment variables

**Solution:**
```bash
# Option 1: Create .env file (auto-loaded in debug)
cp .env.example .env

# Option 2: Pass --dart-define flags
flutter test --dart-define=SUPABASE_URL="https://..."
```

### VS Code can't find variables

**Problem:** IDE doesn't know about `.env` values

**Solution:** Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "taskly_bloc (dev)",
      "request": "launch",
      "type": "dart",
      "toolArgs": [
        "--dart-define=SUPABASE_URL=https://your-project.supabase.co",
        "--dart-define=SUPABASE_PUBLISHABLE_KEY=your_key",
        "--dart-define=POWERSYNC_URL=https://your-instance.journeyapps.com"
      ]
    }
  ]
}
```

## 📚 Further Reading

- [Flutter Environment Variables Guide](https://dart.dev/guides/environment-declarations)
- [Supabase Client-Side Security](https://supabase.com/docs/guides/auth/row-level-security)
- [flutter_dotenv Package](https://pub.dev/packages/flutter_dotenv)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
