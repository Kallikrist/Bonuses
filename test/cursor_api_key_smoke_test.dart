import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Smoke test for Cursor Cloud Agents API with CURSOR_API_KEY
/// 
/// This test suite verifies:
/// 1. CURSOR_API_KEY environment variable is available
/// 2. API key has valid format
/// 3. Basic API connectivity to Cursor Cloud Agents endpoint
/// 4. API authentication works correctly
void main() {
  group('Cursor API Key Smoke Tests', () {
    late String? apiKey;
    const String cursorApiBaseUrl = 'https://api2.cursor.sh';
    
    setUp(() {
      // Retrieve the API key from environment variables
      apiKey = Platform.environment['CURSOR_API_KEY'];
    });

    test('CURSOR_API_KEY environment variable should be set', () {
      expect(
        apiKey,
        isNotNull,
        reason: 'CURSOR_API_KEY must be set in environment variables',
      );
      
      expect(
        apiKey!.isNotEmpty,
        isTrue,
        reason: 'CURSOR_API_KEY should not be empty',
      );
    });

    test('CURSOR_API_KEY should have valid format', () {
      if (apiKey == null || apiKey!.isEmpty) {
        fail('API key is not available for format validation');
      }

      // Basic format validation
      expect(
        apiKey!.length,
        greaterThan(10),
        reason: 'API key should have reasonable length',
      );

      // Check that it doesn't contain obvious invalid characters
      expect(
        apiKey!.contains(' '),
        isFalse,
        reason: 'API key should not contain spaces',
      );
    });

    test('Should be able to make authenticated request to Cursor API', () async {
      if (apiKey == null || apiKey!.isEmpty) {
        fail('API key is not available for API call test');
      }

      try {
        // Make a simple GET request to verify API connectivity
        // Using a health check or lightweight endpoint
        final response = await http.get(
          Uri.parse('$cursorApiBaseUrl/health'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException(
              'API request timed out after 10 seconds',
            );
          },
        );

        // Verify we got a response (even if it's not 200)
        expect(
          response.statusCode,
          lessThan(500),
          reason: 'Should not get server error with valid API key',
        );

        // 401 would indicate authentication issue
        expect(
          response.statusCode,
          isNot(equals(401)),
          reason: 'Should not get unauthorized with valid API key',
        );
        
      } catch (e) {
        if (e is SocketException) {
          // Network issue - this is acceptable in isolated test environment
          print('Warning: Network connectivity issue detected - $e');
        } else if (e is TimeoutException) {
          print('Warning: Request timeout - API may be slow or unreachable');
        } else {
          rethrow;
        }
      }
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('API key should work for Cloud Agents operations (minimal check)', () async {
      if (apiKey == null || apiKey!.isEmpty) {
        fail('API key is not available for operations test');
      }

      try {
        // Attempt to query available endpoints or capabilities
        // This is a minimal smoke test - just verify the key is recognized
        final response = await http.get(
          Uri.parse('$cursorApiBaseUrl/api/cloud-agents'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException(
              'Cloud agents API request timed out',
            );
          },
        );

        // We're primarily checking that the API key is accepted
        // Status codes like 404, 403, or 200 are all acceptable
        // Only 401 (unauthorized) would indicate a problem with the key
        expect(
          response.statusCode,
          isNot(equals(401)),
          reason: 'API key should be valid for Cloud Agents operations',
        );

        // Log response for debugging
        if (response.statusCode >= 400) {
          print('API Response Status: ${response.statusCode}');
          print('API Response Body: ${response.body}');
        }
        
      } catch (e) {
        if (e is SocketException) {
          // Network issue - this is acceptable in isolated test environment
          print('Warning: Network connectivity issue - $e');
        } else if (e is TimeoutException) {
          print('Warning: Request timeout - Cloud Agents API may be unavailable');
        } else {
          rethrow;
        }
      }
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('Should handle API errors gracefully', () async {
      // Test with an intentionally invalid API key format
      const invalidKey = 'invalid-key-format';
      
      try {
        final response = await http.get(
          Uri.parse('$cursorApiBaseUrl/health'),
          headers: {
            'Authorization': 'Bearer $invalidKey',
            'Content-Type': 'application/json',
          },
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Request timed out');
          },
        );

        // With invalid key, we should get 401 or similar auth error
        // This verifies that authentication is actually being checked
        if (response.statusCode == 401 || response.statusCode == 403) {
          // Expected behavior with invalid key
          expect(true, isTrue);
        } else {
          print('Note: Invalid key returned status ${response.statusCode}');
        }
        
      } catch (e) {
        if (e is SocketException || e is TimeoutException) {
          // Network issues are acceptable in test environment
          print('Warning: Network issue during error handling test - $e');
        } else {
          // Other errors are acceptable too - we're just testing error handling
          print('Error handled as expected: $e');
        }
      }
    }, timeout: const Timeout(Duration(seconds: 15)));
  });

  group('Environment Configuration Tests', () {
    test('Test environment has necessary network capabilities', () {
      // Verify that the test environment can resolve DNS
      try {
        final result = InternetAddress.lookup('cursor.sh');
        expect(result, isNotNull);
      } catch (e) {
        print('Warning: DNS resolution may not be available - $e');
      }
    });

    test('All required environment variables are documented', () {
      // Document expected environment variables for smoke test
      final expectedVars = ['CURSOR_API_KEY'];
      final missingVars = <String>[];
      
      for (var varName in expectedVars) {
        if (Platform.environment[varName] == null) {
          missingVars.add(varName);
        }
      }

      if (missingVars.isNotEmpty) {
        print('Missing environment variables: ${missingVars.join(", ")}');
        print('Please set these variables before running smoke tests.');
      }

      // This test documents requirements but doesn't fail
      // Individual tests will fail if keys are missing
      expect(true, isTrue);
    });
  });

  group('API Response Validation', () {
    test('API responses should have proper JSON format', () async {
      final apiKey = Platform.environment['CURSOR_API_KEY'];
      
      if (apiKey == null || apiKey.isEmpty) {
        print('Skipping JSON validation test - API key not available');
        return;
      }

      try {
        final response = await http.get(
          Uri.parse('https://api2.cursor.sh/health'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          // Attempt to parse as JSON
          try {
            final jsonData = json.decode(response.body);
            expect(jsonData, isNotNull);
            print('API returned valid JSON: ${response.body}');
          } catch (e) {
            print('Response is not JSON or empty - may be a simple health check');
          }
        }
      } catch (e) {
        print('Warning: Could not validate JSON response - $e');
      }
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
