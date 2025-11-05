JWT-based API keys # Environment Variables Setup Guide

## Overview

This app uses environment variables to securely store API keys and sensitive configuration. **Never commit actual credentials to version control!**

## Quick Start

### For Local Development

1. **Copy the example file:**
   ```bash
   cp env.example .env
   ```

2. **Edit `.env` and add your actual credentials:**
   ```bash
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your_actual_anon_key_here
   ```

3. **Run the app with environment variables:**
   ```bash
   flutter run --dart-define=SUPABASE_URL=$(grep SUPABASE_URL .env | cut -d '=' -f2) \
              --dart-define=SUPABASE_ANON_KEY=$(grep SUPABASE_ANON_KEY .env | cut -d '=' -f2)
   ```

   Or manually:
   ```bash
   flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co \
              --dart-define=SUPABASE_ANON_KEY=your_actual_anon_key_here
   ```

### For Production Builds

Use the same `--dart-define` flags when building:

```bash
# Android
flutter build apk --dart-define=SUPABASE_URL=xxx --dart-define=SUPABASE_ANON_KEY=yyy

# iOS
flutter build ios --dart-define=SUPABASE_URL=xxx --dart-define=SUPABASE_ANON_KEY=yyy
```

### For CI/CD (GitHub Actions, etc.)

Set environment variables in your CI/CD secrets, then use them in your workflow:

```yaml
# .github/workflows/build.yml
- name: Build app
  run: |
    flutter build apk \
      --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
      --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}
```

## Security Best Practices

1. ✅ **`.env` is gitignored** - Your actual credentials will never be committed
2. ✅ **`env.example` is committed** - Template file shows what's needed
3. ✅ **Empty defaults** - App will fail if credentials aren't provided
4. ✅ **No hardcoded values** - All credentials come from environment variables

## Required Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `SUPABASE_URL` | Your Supabase project URL | ✅ Yes |
| `SUPABASE_ANON_KEY` | Your Supabase anonymous key | ✅ Yes |

## Optional Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DEMO_MODE` | Enable demo mode | `true` |
| `DEBUG_MODE` | Enable debug logging | `true` |

## Testing

The environment variable configuration is fully testable. Run tests with:

```bash
# Run environment config tests
flutter test test/environment_config_test.dart

# Run all tests
flutter test

# Run tests with environment variables (if needed for integration tests)
flutter test --dart-define=SUPABASE_URL=test_url --dart-define=SUPABASE_ANON_KEY=test_key
```

The test suite verifies:
- ✅ Empty defaults when env vars not set
- ✅ Validation throws errors for missing credentials
- ✅ No hardcoded credentials in source code
- ✅ Helpful error messages guide configuration

## Troubleshooting

### Error: "Supabase credentials not configured"

**Cause:** Environment variables not set or empty.

**Fix:** Ensure you're passing `--dart-define` flags when running:
```bash
flutter run --dart-define=SUPABASE_URL=xxx --dart-define=SUPABASE_ANON_KEY=yyy
```

### Error: "Using placeholder Supabase credentials"

**Cause:** Using placeholder values from `env.example`.

**Fix:** Replace placeholder values with your actual Supabase credentials.

## Getting Your Supabase Credentials

1. Go to your Supabase project dashboard
2. Navigate to **Settings** → **API**
3. Copy:
   - **Project URL** → Use as `SUPABASE_URL`
   - **anon/public key** → Use as `SUPABASE_ANON_KEY`

⚠️ **Important:** Never share your `service_role` key - it has full database access!

