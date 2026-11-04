import 'dart:io';

import 'package:bonuses/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('BonusesApp keeps AppWrapper home and has no supabase-test route',
      (tester) async {
    await tester.pumpWidget(const BonusesApp());
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.home, isA<AppWrapper>());
    final routes = app.routes ?? const <String, WidgetBuilder>{};
    expect(routes.containsKey('/supabase-test'), isFalse);
  });
}
