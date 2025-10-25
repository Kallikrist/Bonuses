import '../models/user.dart';
import 'storage_service.dart';

class AuthService {
  static User? _currentUser;

  static User? get currentUser => _currentUser;

  static Future<bool> login(String email, String password) async {
    try {
      // Use local storage authentication only
      print('DEBUG: Using local storage authentication for $email');

      final users = await StorageService.getUsers();
      final user = users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('User not found'),
      );

      // Check password
      final storedPassword = await StorageService.getPassword(user.id);
      if (storedPassword != password) {
        print('DEBUG: Invalid password for $email');
        return false;
      }

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
      print('DEBUG: Local storage login successful for ${user.email}');
      return true;
    } catch (e) {
      print('DEBUG: Login failed: $e');
      return false;
    }
  }

  static Future<void> logout() async {
    try {
      print('DEBUG: Logging out user');
    } catch (e) {
      print('DEBUG: Logout error (non-critical): $e');
    }

    await StorageService.clearCurrentUser();
    _currentUser = null;
    print('DEBUG: Local logout completed');
  }

  static Future<bool> isLoggedIn() async {
    try {
      // Check local storage first
      final user = await StorageService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        return true;
      }
    } catch (e) {
      print('DEBUG: Error checking login status: $e');
    }

    return false;
  }

  // Helper method to check if user has active companies
  static Future<bool> _checkUserHasActiveCompany(User user) async {
    try {
      final companies = await StorageService.getCompanies();

      // Check if any of the user's companies are active
      for (final companyId in user.companyIds) {
        final company = companies.firstWhere(
          (c) => c.id == companyId,
          orElse: () => throw Exception('Company not found'),
        );
        if (company.isActive) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('DEBUG: Error checking user companies: $e');
      return false;
    }
  }
}
