import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migrationsDir = Directory('supabase/migrations');

  List<File> migrationFiles() {
    expect(migrationsDir.existsSync(), isTrue);
    final files = migrationsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.sql'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  String allSql() =>
      migrationFiles().map((f) => f.readAsStringSync()).join('\n');

  group('supabase/migrations', () {
    test('tracked SQL migrations exist', () {
      final files = migrationFiles();
      expect(files, isNotEmpty);
      expect(
        files.map((f) => f.uri.pathSegments.last),
        containsAll([
          '20261104180000_app_schema.sql',
          '20261104180100_app_rls.sql',
        ]),
      );
    });

    test('migrations are additive (no table/row destruction)', () {
      final comment = RegExp(r'--.*', multiLine: true);
      for (final file in migrationFiles()) {
        final lower =
            file.readAsStringSync().replaceAll(comment, '').toLowerCase();
        expect(lower, isNot(contains('drop table')), reason: file.path);
        expect(lower, isNot(contains('truncate ')), reason: file.path);
        expect(lower, isNot(contains('delete from')), reason: file.path);
        expect(lower, isNot(contains('drop column')), reason: file.path);
      }
    });

    test('RLS is enabled on users and there is no anon USING true select', () {
      final rls = File('supabase/migrations/20261104180100_app_rls.sql')
          .readAsStringSync();
      expect(rls, contains('ALTER TABLE public.users ENABLE ROW LEVEL SECURITY'));
      expect(rls, contains('bonuses_users_select'));
      expect(rls, contains('TO authenticated'));
      expect(rls, contains('private.auth_phone'));
      expect(rls, contains('"phoneNumber"'));
      expect(rls, isNot(contains('auth.uid()::text = id::text')));
      expect(rls, contains('DROP POLICY IF EXISTS "Allow anon insert users"'));
      expect(rls, contains('REVOKE ALL ON TABLE public.users FROM anon'));
    });

    test('schema covers SupabaseService tables', () {
      final schema = File('supabase/migrations/20261104180000_app_schema.sql')
          .readAsStringSync();
      for (final table in [
        'users',
        'companies',
        'workplaces',
        'sales_targets',
        'points_transactions',
        'bonuses',
        'messages',
        'approval_requests',
      ]) {
        expect(schema, contains('CREATE TABLE IF NOT EXISTS public.$table'));
      }
    });

    test('combined SQL has no live Stripe secrets', () {
      final sql = allSql();
      expect(sql, isNot(contains('sk_live_')));
      expect(sql, isNot(contains('sk_test_')));
      expect(sql, isNot(contains('STRIPE_SECRET_KEY')));
    });

    test('RLS is phone-JWT authenticated-only (anon dual-write would fail)', () {
      final rls = File('supabase/migrations/20261104180100_app_rls.sql')
          .readAsStringSync();
      expect(rls, contains('private.auth_phone'));
      expect(rls, contains("auth.jwt() ->> 'phone'"));
      expect(rls, contains('TO authenticated'));
      expect(rls, contains('REVOKE ALL ON TABLE public.users FROM anon, PUBLIC'));
      expect(
        rls,
        isNot(contains(RegExp(r'CREATE POLICY\b.*\bTO anon\b'))),
        reason: 'no policy should grant the anon role',
      );
      expect(rls, isNot(contains('signInWithPassword')));
    });
  });

  group('current client vs paused phone OTP', () {
    test('AuthService is still local email/password, not phone OTP', () {
      final auth = File('lib/services/auth_service.dart').readAsStringSync();
      expect(auth, contains('Using local storage authentication'));
      expect(auth, contains('StorageService.getPassword'));
      expect(auth, isNot(contains('signInWithOtp')));
      expect(auth, isNot(contains('verifyOTP')));
      expect(auth, isNot(contains('OtpType')));
    });

    test('product getUsers is local SharedPreferences, not PostgREST', () {
      final storage = File('lib/services/storage_service.dart').readAsStringSync();
      final getUsers = storage.substring(
        storage.indexOf('static Future<List<User>> getUsers()'),
        storage.indexOf('static Future<Map<String, List<String>>> getHeaderNavPrefs()'),
      );
      expect(getUsers, contains("prefs.getStringList(_usersKey)"));
      expect(getUsers, isNot(contains('SupabaseService')));
    });
  });
}
