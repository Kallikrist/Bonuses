import '../models/company.dart';
import '../models/user.dart';

/// Splash branding for the signed-in user only.
///
/// Never uses `users.first` or `companies.first` from the global lists —
/// those can belong to another tenant.
String resolveSplashCompanyName({
  User? currentUser,
  List<Company> companies = const [],
}) {
  if (currentUser == null || currentUser.role == UserRole.superAdmin) {
    return 'Bonuses';
  }

  final primaryId = currentUser.primaryCompanyId;
  if (primaryId != null && primaryId.isNotEmpty) {
    final index = currentUser.companyIds.indexOf(primaryId);
    if (index != -1 && index < currentUser.companyNames.length) {
      final name = currentUser.companyNames[index];
      if (name.isNotEmpty) {
        return name;
      }
    }
    for (final company in companies) {
      if (company.id == primaryId &&
          currentUser.companyIds.contains(company.id) &&
          company.name.isNotEmpty) {
        return company.name;
      }
    }
  }

  for (final name in currentUser.companyNames) {
    if (name.isNotEmpty) {
      return name;
    }
  }

  return 'Bonuses';
}
