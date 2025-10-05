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
