# Cursor API Key Smoke Test

## Overview

This smoke test verifies the Cursor Cloud Agents API functionality with the `CURSOR_API_KEY` environment variable.

## Purpose

The test suite validates:
- ✅ `CURSOR_API_KEY` environment variable is properly set
- ✅ API key has a valid format
- ✅ API authentication works correctly
- ✅ Basic API connectivity to Cursor Cloud Agents endpoints
- ✅ Error handling for invalid credentials

## Test File

- **Location**: `test/cursor_api_key_smoke_test.dart`
- **Type**: Integration/Smoke Test
- **Duration**: ~15-30 seconds

## Prerequisites

### Required Environment Variables

```bash
export CURSOR_API_KEY="your-cursor-api-key-here"
```

To obtain a Cursor API key:
1. Log into your Cursor account
2. Navigate to Settings → API Keys
3. Generate a new API key
4. Copy and set it as an environment variable

### Required Dependencies

The test requires the `http` package, which has been added to `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0
```

## Running the Tests

### Run all tests including smoke test

```bash
flutter test
```

### Run only the Cursor API smoke test

```bash
flutter test test/cursor_api_key_smoke_test.dart
```

### Run with verbose output

```bash
flutter test test/cursor_api_key_smoke_test.dart --verbose
```

### Run with environment variable inline

```bash
CURSOR_API_KEY="your-key" flutter test test/cursor_api_key_smoke_test.dart
```

## Test Structure

The test suite is organized into three groups:

### 1. Cursor API Key Smoke Tests
- **Environment Variable Check**: Validates `CURSOR_API_KEY` is set and not empty
- **Format Validation**: Ensures the API key has reasonable format (length, no spaces)
- **Authenticated Request**: Makes a real API call to verify authentication
- **Cloud Agents Operations**: Tests minimal Cloud Agents API functionality
- **Error Handling**: Verifies proper error responses with invalid keys

### 2. Environment Configuration Tests
- **Network Capabilities**: Checks DNS resolution and connectivity
- **Documentation**: Lists all required environment variables

### 3. API Response Validation
- **JSON Format**: Validates API responses are properly formatted
- **Response Structure**: Checks for expected response patterns

## Expected Behavior

### With Valid API Key

✅ All tests should pass
✅ No 401 (Unauthorized) errors
✅ Successful API connectivity

### Without API Key

❌ Tests will fail with clear error messages:
- "CURSOR_API_KEY must be set in environment variables"
- "API key is not available for API call test"

### With Invalid API Key

⚠️ Tests will detect authentication failures:
- 401 or 403 status codes are properly handled
- Error messages are logged for debugging

## Network Requirements

The test makes HTTPS requests to:
- `https://api2.cursor.sh/health`
- `https://api2.cursor.sh/api/cloud-agents`

Ensure your environment allows outbound HTTPS traffic to these endpoints.

## Timeouts

Each API test has a 15-second timeout to prevent hanging:
- Connection timeout: 10 seconds per request
- Total test timeout: 15 seconds

## Troubleshooting

### Test Fails: "CURSOR_API_KEY must be set"

**Solution**: Set the environment variable before running tests

```bash
export CURSOR_API_KEY="your-key"
flutter test test/cursor_api_key_smoke_test.dart
```

### Test Fails: "Network connectivity issue"

**Possible causes**:
- Firewall blocking outbound HTTPS
- No internet connection
- Cursor API endpoints are down

**Solution**: 
- Check internet connectivity
- Verify firewall rules allow HTTPS to `*.cursor.sh`
- Check Cursor API status

### Test Fails: "Should not get unauthorized"

**Possible causes**:
- Invalid API key
- Expired API key
- API key doesn't have required permissions

**Solution**:
- Verify the API key is correct
- Generate a new API key from Cursor settings
- Check API key has Cloud Agents permissions

### Test Times Out

**Possible causes**:
- Slow network connection
- API is experiencing high load
- DNS resolution issues

**Solution**:
- Retry the test
- Check network latency to `cursor.sh`
- Increase timeout if needed

## CI/CD Integration

### GitHub Actions

Add to your workflow file:

```yaml
name: Cursor API Smoke Test

on: [push, pull_request]

jobs:
  smoke-test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.6.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run Cursor API Smoke Test
        env:
          CURSOR_API_KEY: ${{ secrets.CURSOR_API_KEY }}
        run: flutter test test/cursor_api_key_smoke_test.dart
```

**Important**: Store `CURSOR_API_KEY` as a repository secret in GitHub Settings.

## Security Notes

⚠️ **Never commit API keys to version control**
⚠️ **Always use environment variables or secrets management**
⚠️ **Rotate API keys regularly**
⚠️ **Limit API key permissions to minimum required scope**

## Success Criteria

For the smoke test to be considered successful:

1. ✅ All test cases pass
2. ✅ API authentication succeeds
3. ✅ No network timeouts
4. ✅ Proper error handling demonstrated
5. ✅ Response validation passes

## Maintenance

- **Review**: Monthly or when API changes occur
- **Update**: If Cursor API endpoints change
- **Verify**: After any authentication system updates

## Contact

For issues with:
- **Test failures**: Check the troubleshooting section above
- **API access**: Contact Cursor support
- **Test improvements**: Submit a PR with description

## Version History

- **v1.0.0** (Nov 2026): Initial smoke test implementation
  - Basic API key validation
  - Authentication verification
  - Error handling tests
  - Network connectivity checks
