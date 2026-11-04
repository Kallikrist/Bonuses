import 'dart:io';

import 'package:bonuses/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _importTestSupabase = RegExp(
  r'''^\s*import\s+['"][^'"\n]*test_supabase_connection[^'"\n]*['"]''',
  multiLine: true,
);

final _importTestSupabaseScreen = RegExp(
  r'''^\s*import\s+['"][^'"\n]*['"][^;]*TestSupabaseScreen''',
  multiLine: true,
);

bool _isGitignoredLibTestFile(String path) {
  final name = path.split(RegExp(r'[/\\]')).last;
  return name.startsWith('test_') ||
      name.startsWith('debug_') ||
      name.endsWith('_test.dart');
}

Iterable<File> _dartFilesUnder(Directory dir) {
  if (!dir.existsSync()) return const [];
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
}

List<String> _trackedDartPaths() {
  final listed = Process.runSync('git', ['ls-files', '*.dart']);
  expect(listed.exitCode, 0, reason: listed.stderr.toString());
  return listed.stdout
      .toString()
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.endsWith('.dart'))
      .toList();
}

void main() {
  test('main.dart does not import gitignored lib/test_*.dart', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(
      source.contains('test_supabase_connection.dart'),
      isFalse,
      reason:
          'lib/test_*.dart is gitignored; a clean clone cannot compile this import',
    );
    expect(source.contains('TestSupabaseScreen'), isFalse);
    expect(source.contains('/supabase-test'), isFalse);
  });

  test('no Dart file imports test_supabase_connection or TestSupabaseScreen',
      () {
    final paths = <String>{
      ..._trackedDartPaths(),
      ..._dartFilesUnder(Directory('lib')).map((file) => file.path),
      ..._dartFilesUnder(Directory('test')).map((file) => file.path),
    };

    expect(paths, isNotEmpty);

    for (final path in paths) {
      if (_isGitignoredLibTestFile(path) && path.startsWith('lib/')) {
        continue;
      }
      final file = File(path);
      if (!file.existsSync()) continue;
      final source = file.readAsStringSync();
      expect(
        _importTestSupabase.hasMatch(source),
        isFalse,
        reason: '$path imports test_supabase_connection',
      );
      expect(
        _importTestSupabaseScreen.hasMatch(source),
        isFalse,
        reason: '$path imports TestSupabaseScreen',
      );
    }
  });

  test('lib/test_*.dart is gitignored and not tracked', () {
    final listed = Process.runSync('git', ['ls-files', 'lib/test_*.dart']);
    expect(listed.exitCode, 0, reason: listed.stderr.toString());
    expect(
      listed.stdout.toString().trim(),
      isEmpty,
      reason: 'gitignored debug screens must not be tracked',
    );

    final ignored = Process.runSync(
      'git',
      ['check-ignore', '-q', 'lib/test_supabase_connection.dart'],
    );
    expect(
      ignored.exitCode,
      0,
      reason: 'lib/test_supabase_connection.dart should match .gitignore',
    );
  });

  testWidgets('BonusesApp keeps AppWrapper home and has no supabase-test route',
      (tester) async {
    await tester.pumpWidget(const BonusesApp());
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.home, isA<AppWrapper>());
    final routes = app.routes ?? const <String, WidgetBuilder>{};
    expect(routes.containsKey('/supabase-test'), isFalse);
  });
}
