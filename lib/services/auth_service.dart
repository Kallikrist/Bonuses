import '../models/user.dart';
import 'storage_service.dart';

class AuthService {
  static User? _currentUser;

  static User? get currentUser => _currentUser;

  static Future<bool> login(String email, String password) async {
    // In a real app, this would validate against a server
    // For demo purposes, we'll use simple email-based authentication
    final users = await StorageService.getUsers();

    try {
      final user = users.firstWhere((u) => u.email == email);

      // Get stored password for this user
      final storedPassword = await StorageService.getPassword(user.id);

      // Check if password matches (either stored password or default 'password123' for demo users)
      if (password == storedPassword ||
          (storedPassword == null && password == 'password123')) {
        print('DEBUG: Login - User: ${user.email}, Role: ${user.role}');
        print(
            'DEBUG: Login - Is super admin? ${user.role == UserRole.superAdmin}');
        print(
            'DEBUG: Login - Email check: ${user.email == 'superadmin@platform.com'}');

        // Check if user has any active companies (skip check for super admin)
        if (user.role != UserRole.superAdmin &&
            user.email != 'superadmin@platform.com') {
          print('DEBUG: Login - Checking active companies for ${user.email}');
          final hasActiveCompany = await _checkUserHasActiveCompany(user);
          print('DEBUG: Login - Has active company: $hasActiveCompany');
          if (!hasActiveCompany) {
            print(
                'DEBUG: Login blocked - No active companies for user ${user.email}');
            return false; // No active companies, block login
          }
        } else {
          print('DEBUG: Login - Bypassing company check for ${user.email}');
        }
        _currentUser = user;
        await StorageService.setCurrentUser(user);
        return true;
      }
      return false;
    } catch (e) {
      // User not found
      return false;
    }
  }

  // Check if user has at least one active company
  static Future<bool> _checkUserHasActiveCompany(User user) async {
    print('DEBUG: _checkUserHasActiveCompany - User: ${user.email}');
    print(
        'DEBUG: _checkUserHasActiveCompany - User companyIds: ${user.companyIds}');

    if (user.companyIds.isEmpty) {
      print('DEBUG: _checkUserHasActiveCompany - User has no companies');
      return false; // User has no companies
    }

    final companies = await StorageService.getCompanies();
    print(
        'DEBUG: _checkUserHasActiveCompany - Total companies in system: ${companies.length}');

    for (final companyId in user.companyIds) {
      try {
        final company = companies.firstWhere((c) => c.id == companyId);
        print(
            'DEBUG: _checkUserHasActiveCompany - Company ${company.name} (${companyId}): isActive=${company.isActive}');
        if (company.isActive) {
          print(
              'DEBUG: _checkUserHasActiveCompany - Found active company: ${company.name}');
          return true; // Found at least one active company
        }
      } catch (e) {
        print(
            'DEBUG: _checkUserHasActiveCompany - Company $companyId not found');
        // Company not found, continue checking others
        continue;
      }
    }
    print('DEBUG: _checkUserHasActiveCompany - No active companies found');
    return false; // No active companies found
  }

  static Future<void> logout() async {
    _currentUser = null;
    await StorageService.clearCurrentUser();
  }

  static Future<bool> isLoggedIn() async {
    if (_currentUser != null) return true;

    final user = await StorageService.getCurrentUser();
    if (user != null) {
      _currentUser = user;
      return true;
    }
    return false;
  }

  static bool get isAdmin => _currentUser?.role == UserRole.admin;
  static bool get isEmployee => _currentUser?.role == UserRole.employee;
}
