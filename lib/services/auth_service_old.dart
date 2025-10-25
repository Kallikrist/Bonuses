import '../models/user.dart';
import 'storage_service.dart';
// Firebase auth service removed - using Supabase now

class AuthService {
  static User? _currentUser;

  static User? get currentUser => _currentUser;

  static Future<bool> login(String email, String password) async {
    try {
      // Try Firebase authentication first (for mobile platforms)
      try {
        final firebaseUser =
            await FirebaseAuthService.signInWithEmailAndPassword(
                email: email, password: password);
        if (firebaseUser != null) {
          print(
              'DEBUG: Firebase Login - User: ${firebaseUser.email}, Role: ${firebaseUser.role}');

          // Check if user has any active companies (skip check for super admin)
          if (firebaseUser.role != UserRole.superAdmin &&
              firebaseUser.email != 'superadmin@platform.com') {
            print(
                'DEBUG: Login - Checking active companies for ${firebaseUser.email}');
            final hasActiveCompany =
                await _checkUserHasActiveCompany(firebaseUser);
            print('DEBUG: Login - Has active company: $hasActiveCompany');
            if (!hasActiveCompany) {
              print(
                  'DEBUG: Login blocked - No active companies for user ${firebaseUser.email}');
              return false; // No active companies, block login
            }
          } else {
            print(
                'DEBUG: Login - Bypassing company check for ${firebaseUser.email}');
          }

          _currentUser = firebaseUser;
          await StorageService.setCurrentUser(firebaseUser);
          return true;
        }
      } catch (e) {
        print('DEBUG: Firebase login failed, trying local storage...');
      }

      // Fallback to local storage authentication
      print('DEBUG: Using local storage authentication');
      final users = await StorageService.getUsers();
      final localUser = users.firstWhere((u) => u.email == email);

      // Get stored password for this user
      final storedPassword = await StorageService.getPassword(localUser.id);

      // Check if password matches (either stored password or default 'password123' for demo users)
      if (password == storedPassword ||
          (storedPassword == null && password == 'password123')) {
        print(
            'DEBUG: Local Login - User: ${localUser.email}, Role: ${localUser.role}');

        // Check if user has any active companies (skip check for super admin)
        if (localUser.role != UserRole.superAdmin &&
            localUser.email != 'superadmin@platform.com') {
          print(
              'DEBUG: Login - Checking active companies for ${localUser.email}');
          final hasActiveCompany = await _checkUserHasActiveCompany(localUser);
          print('DEBUG: Login - Has active company: $hasActiveCompany');
          if (!hasActiveCompany) {
            print(
                'DEBUG: Login blocked - No active companies for user ${localUser.email}');
            return false; // No active companies, block login
          }
        } else {
          print(
              'DEBUG: Login - Bypassing company check for ${localUser.email}');
        }

        _currentUser = localUser;
        await StorageService.setCurrentUser(localUser);
        return true;
      }
      return false;
    } catch (e) {
      print('DEBUG: Login failed: $e');
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
    try {
      await FirebaseAuthService.signOut();
    } catch (e) {
      print('DEBUG: Firebase logout failed (continuing with local logout): $e');
    }
    await StorageService.clearCurrentUser();
  }

  static Future<bool> isLoggedIn() async {
    if (_currentUser != null) return true;

    // Try Firebase first (if available)
    try {
      final firebaseUser = await FirebaseAuthService.getCurrentUser();
      if (firebaseUser != null) {
        _currentUser = firebaseUser;
        return true;
      }
    } catch (e) {
      print(
          'DEBUG: Firebase login check failed (continuing with local storage): $e');
    }

    // Fallback to local storage
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
