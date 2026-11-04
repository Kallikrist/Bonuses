import 'dart:io';

import 'package:bonuses/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _mustRead(String relative) {
  final candidates = [
    File(relative),
    File('${Directory.current.path}/$relative'),
  ];
  for (final file in candidates) {
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
  }
  fail('Could not read $relative from ${Directory.current.path}');
}

void main() {
  late String pubspec;
  late String lock;
  late String workflow;

  setUpAll(() {
    pubspec = _mustRead('pubspec.yaml');
    lock = _mustRead('pubspec.lock');
    workflow = _mustRead('.github/workflows/flutter-tests.yml');
  });

  group('http 1.6.0 bump (BON-36)', () {
    test('pubspec and lock pin http 1.6.0', () {
      expect(pubspec, contains('http: ^1.6.0'));
      expect(
        RegExp(
          r'^  http:\n(?:    .*\n)+?    version: "1\.6\.0"$',
          multiLine: true,
        ).hasMatch(lock),
        isTrue,
        reason: 'pubspec.lock must resolve http 1.6.0',
      );
    });

    test('no product Dart source imports package:http', () {
      final dartFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();
      expect(dartFiles, isNotEmpty);
      for (final file in dartFiles) {
        final text = file.readAsStringSync();
        expect(
          text.contains("package:http"),
          isFalse,
          reason: '${file.path} must not import package:http',
        );
      }
    });

    test('this file is not a named CI exclusion', () {
      final excludeLine = workflow
          .split('\n')
          .firstWhere((line) => line.contains("EXCLUDE='"));
      expect(excludeLine, isNot(contains('http_package_bump_test.dart')));
    });

    test('JSON Request.body does not gain a charset (1.6.0 RFC-8259)', () {
      final request = http.Request('POST', Uri.parse('https://example.com/v1'))
        ..headers['Content-Type'] = 'application/json'
        ..body = '{"hello":"world"}';
      expect(request.headers['content-type'], 'application/json');
      expect(request.headers['content-type'], isNot(contains('charset')));
    });

    test('text Request.body still gets a charset', () {
      final request = http.Request('POST', Uri.parse('https://example.com/v1'))
        ..headers['Content-Type'] = 'text/plain'
        ..body = 'hello';
      expect(request.headers['content-type'], 'text/plain; charset=utf-8');
    });

    test('MockClient JSON POST never hits the network', () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'example.com');
        expect(request.headers['content-type'], 'application/json');
        expect(request.body, '{"hello":"world"}');
        return http.Response(
          '{"ok":true}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      addTearDown(client.close);

      final response = await client.post(
        Uri.parse('https://example.com/v1'),
        headers: {'content-type': 'application/json'},
        body: '{"hello":"world"}',
      );
      expect(response.statusCode, 200);
      expect(response.body, '{"ok":true}');
    });

    test('payments stay on the mock Stripe path', () {
      expect(AppConfig.demoMode, isTrue);
      expect(AppConfig.useMockStripe, isTrue);
    });
  });
}
