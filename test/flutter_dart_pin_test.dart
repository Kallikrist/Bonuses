import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String pubspec;
  late String lock;
  late String workflow;

  setUpAll(() {
    pubspec = File('pubspec.yaml').readAsStringSync();
    lock = File('pubspec.lock').readAsStringSync();
    workflow = File('.github/workflows/flutter-tests.yml').readAsStringSync();
  });

  group('Flutter/Dart pin (BON-20)', () {
    test('pubspec pins Dart 3.6.x, not the leftover beta constraint', () {
      expect(pubspec, contains("sdk: '>=3.6.0 <3.7.0'"));
      expect(pubspec, isNot(contains('3.6.0-149.3.beta')));
      expect(pubspec, isNot(contains('sdk: ^3.6.0-149')));
    });

    test('pubspec.lock dart sdk matches the pubspec range', () {
      expect(lock, contains('dart: ">=3.6.0 <3.7.0"'));
      expect(lock, isNot(contains('>=3.6.0-149.3.beta')));
    });

    test('CI pins Flutter 3.27.4 stable on both jobs', () {
      final setups = RegExp(
        r'uses:\s+subosito/flutter-action@v2\s+'
        r'with:\s+'
        r'channel:\s+stable\s+'
        r"flutter-version:\s+'3\.27\.4'",
      );
      expect(
        setups.allMatches(workflow).length,
        2,
        reason: 'analyze and test jobs must both pin stable 3.27.4',
      );
      expect(workflow, isNot(contains(RegExp(r'channel:\s+beta'))));
    });

    test('pubspec Dart range and CI Flutter version agree', () {
      expect(pubspec, contains("sdk: '>=3.6.0 <3.7.0'"));
      expect(workflow, contains("flutter-version: '3.27.4'"));
      expect(workflow, contains('channel: stable'));
      expect(lock, contains('dart: ">=3.6.0 <3.7.0"'));
    });

    test('test runtime is Dart 3.6.2 (Flutter 3.27.4 stable)', () {
      expect(Platform.version, startsWith('3.6.2'));
    });
  });
}
