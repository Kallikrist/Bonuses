import 'dart:io';

import 'package:bonuses/models/financial_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  late String pubspec;
  late String lock;

  setUpAll(() {
    pubspec = File('pubspec.yaml').readAsStringSync();
    lock = File('pubspec.lock').readAsStringSync();
  });

  group('intl 0.20 bump', () {
    test('pubspec allows 0.20.x and lockfile is 0.20.2 or 0.20.3', () {
      expect(pubspec, contains(RegExp(r'intl:\s*\^0\.20\.[23]')));
      expect(
        lock,
        contains(RegExp(r'intl:\s*\n(?:.+\n){1,8}\s+version: "0\.20\.[23]"')),
      );
    });

    test('DateFormat patterns used in product UI stay stable in en_US', () {
      final morning = DateTime(2024, 1, 15, 9, 5);
      final afternoon = DateTime(2024, 1, 15, 14, 30);

      expect(DateFormat('E', 'en_US').format(morning), 'Mon');
      expect(
        DateFormat('EEEE, MMM dd, yyyy', 'en_US').format(morning),
        'Monday, Jan 15, 2024',
      );
      expect(DateFormat('MMM dd', 'en_US').format(morning), 'Jan 15');
      expect(DateFormat('MMM d, yyyy', 'en_US').format(morning), 'Jan 15, 2024');
      expect(
        DateFormat('MMM dd, yyyy', 'en_US').format(morning),
        'Jan 15, 2024',
      );
      expect(
        DateFormat('MMMM dd, yyyy', 'en_US').format(morning),
        'January 15, 2024',
      );
      expect(DateFormat('MMMM yyyy', 'en_US').format(morning), 'January 2024');
      expect(DateFormat('yyyy-MM-dd', 'en_US').format(morning), '2024-01-15');
      expect(
        DateFormat('MMM dd, yyyy - HH:mm', 'en_US').format(afternoon),
        'Jan 15, 2024 - 14:30',
      );
      expect(
        DateFormat('MMM dd, HH:mm', 'en_US').format(afternoon),
        'Jan 15, 14:30',
      );
      expect(
        DateFormat('MMM dd, yyyy HH:mm', 'en_US').format(afternoon),
        'Jan 15, 2024 14:30',
      );
      expect(
        DateFormat('MMM dd, yyyy • HH:mm', 'en_US').format(afternoon),
        'Jan 15, 2024 • 14:30',
      );
      expect(
        DateFormat('MMM d, yyyy – HH:mm', 'en_US').format(afternoon),
        'Jan 15, 2024 – 14:30',
      );
    });

    test('AM/PM DateFormat skeletons used on target details still print a/p', () {
      final morning = DateTime(2024, 1, 15, 9, 5);
      final afternoon = DateTime(2024, 1, 15, 14, 30);

      expect(
        DateFormat('MMM dd, yyyy • h:mm a', 'en_US').format(morning),
        'Jan 15, 2024 • 9:05 AM',
      );
      expect(
        DateFormat('MMM dd, yyyy • h:mm a', 'en_US').format(afternoon),
        'Jan 15, 2024 • 2:30 PM',
      );
      expect(
        DateFormat('MMM dd, h:mm a', 'en_US').format(afternoon),
        'Jan 15, 2:30 PM',
      );
    });

    test('import targets dd.MM.yyyy parse round-trips', () {
      final parsed = DateFormat('dd.MM.yyyy', 'en_US').parse('15.01.2024');
      expect(parsed.year, 2024);
      expect(parsed.month, 1);
      expect(parsed.day, 15);
      expect(
        DateFormat('dd.MM.yyyy', 'en_US').format(DateTime(2024, 1, 15)),
        '15.01.2024',
      );
    });

    test('NumberFormat.simpleCurrency USD still formats after 0.20 typing', () {
      expect(
        NumberFormat.simpleCurrency(locale: 'en_US', name: 'USD').format(29),
        r'$29.00',
      );
      expect(
        NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 2)
            .format(29),
        r'$29.00',
      );
    });

    test('currency display is hardcoded dollars, not NumberFormat', () {
      final tx = FinancialTransaction(
        id: 'tx_1',
        companyId: 'company_1',
        userId: 'admin',
        type: TransactionType.subscription,
        status: TransactionStatus.completed,
        category: TransactionCategory.subscription,
        amount: 29,
        currency: 'USD',
        description: 'Starter',
        createdAt: DateTime(2024, 1, 15),
      );

      expect(tx.formattedAmount, r'$29.00 USD');

      final dartSources = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      for (final file in dartSources) {
        expect(
          file.readAsStringSync(),
          isNot(contains('NumberFormat')),
          reason: '${file.path} must not use NumberFormat after intl 0.20',
        );
      }
    });
  });
}
