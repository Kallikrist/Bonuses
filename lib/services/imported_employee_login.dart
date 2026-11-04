import 'storage_service.dart';

/// Default password for imported employees.
/// Matches manual add in `admin_dashboard.dart` (`password123`).
const String kImportedEmployeeDefaultPassword = 'password123';

/// Assigns the default email/password login when [userId] has no stored password.
///
/// CSV/Excel import creates users but historically skipped [StorageService.savePassword],
/// so imported staff could not sign in. Call this after creating (or re-importing) an
/// employee. Existing passwords are left unchanged.
Future<void> ensureImportedEmployeePassword(String userId) async {
  final existing = await StorageService.getPassword(userId);
  if (existing != null && existing.isNotEmpty) {
    return;
  }
  await StorageService.savePassword(userId, kImportedEmployeeDefaultPassword);
}
