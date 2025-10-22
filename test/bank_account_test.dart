import 'package:flutter_test/flutter_test.dart';
import 'package:bonuses/models/bank_account.dart';

void main() {
  group('Bank Account Tests', () {
    test('Bank account creation', () {
      final account = BankAccount(
        id: 'bank_1',
        accountHolderName: 'Super Admin',
        accountNumber: '1234567890',
        routingNumber: '021000021',
        bankName: 'Chase Bank',
        accountType: BankAccountType.business,
        status: BankAccountStatus.active,
        address: '123 Main St',
        city: 'New York',
        state: 'NY',
        zipCode: '10001',
        country: 'USA',
        createdAt: DateTime.now(),
        isDefault: true,
      );

      expect(account.id, 'bank_1');
      expect(account.accountHolderName, 'Super Admin');
      expect(account.bankName, 'Chase Bank');
      expect(account.isDefault, true);
    });

    test('Bank account properties work correctly', () {
      final account = BankAccount(
        id: 'bank_1',
        accountHolderName: 'Super Admin',
        accountNumber: '1234567890',
        routingNumber: '021000021',
        bankName: 'Chase Bank',
        accountType: BankAccountType.business,
        status: BankAccountStatus.active,
        createdAt: DateTime.now(),
        verifiedAt: DateTime.now(),
        isDefault: true,
      );

      expect(account.isActive, true);
      expect(account.isVerified, true);
      expect(account.maskedAccountNumber, '****7890');
      expect(account.accountTypeDisplay, 'Business Account');
      expect(account.statusDisplay, 'Active');
      expect(account.accountIcon, '🏢');
    });

    test('Bank account JSON serialization', () {
      final account = BankAccount(
        id: 'bank_1',
        accountHolderName: 'Super Admin',
        accountNumber: '1234567890',
        routingNumber: '021000021',
        bankName: 'Chase Bank',
        accountType: BankAccountType.business,
        status: BankAccountStatus.active,
        address: '123 Main St',
        city: 'New York',
        state: 'NY',
        zipCode: '10001',
        country: 'USA',
        swiftCode: 'CHASUS33',
        iban: 'US64SVBKUS6S3300958879',
        createdAt: DateTime(2024, 1, 1),
        verifiedAt: DateTime(2024, 1, 2),
        isDefault: true,
        metadata: {'source': 'demo'},
      );

      final json = account.toJson();
      final restoredAccount = BankAccount.fromJson(json);

      expect(restoredAccount.id, account.id);
      expect(restoredAccount.accountHolderName, account.accountHolderName);
      expect(restoredAccount.accountNumber, account.accountNumber);
      expect(restoredAccount.routingNumber, account.routingNumber);
      expect(restoredAccount.bankName, account.bankName);
      expect(restoredAccount.accountType, account.accountType);
      expect(restoredAccount.status, account.status);
      expect(restoredAccount.address, account.address);
      expect(restoredAccount.city, account.city);
      expect(restoredAccount.state, account.state);
      expect(restoredAccount.zipCode, account.zipCode);
      expect(restoredAccount.country, account.country);
      expect(restoredAccount.swiftCode, account.swiftCode);
      expect(restoredAccount.iban, account.iban);
      expect(restoredAccount.isDefault, account.isDefault);
      expect(restoredAccount.metadata, account.metadata);
    });

    test('Bank account copyWith works correctly', () {
      final originalAccount = BankAccount(
        id: 'bank_1',
        accountHolderName: 'Super Admin',
        accountNumber: '1234567890',
        routingNumber: '021000021',
        bankName: 'Chase Bank',
        accountType: BankAccountType.business,
        status: BankAccountStatus.pending,
        createdAt: DateTime.now(),
        isDefault: false,
      );

      final updatedAccount = originalAccount.copyWith(
        status: BankAccountStatus.active,
        isDefault: true,
        verifiedAt: DateTime.now(),
      );

      expect(updatedAccount.id, originalAccount.id);
      expect(
          updatedAccount.accountHolderName, originalAccount.accountHolderName);
      expect(updatedAccount.accountNumber, originalAccount.accountNumber);
      expect(updatedAccount.routingNumber, originalAccount.routingNumber);
      expect(updatedAccount.bankName, originalAccount.bankName);
      expect(updatedAccount.accountType, originalAccount.accountType);
      expect(updatedAccount.status, BankAccountStatus.active);
      expect(updatedAccount.isDefault, true);
      expect(updatedAccount.verifiedAt, isNotNull);
    });
  });
}
