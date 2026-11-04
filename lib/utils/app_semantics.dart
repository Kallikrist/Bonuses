/// Semantic labels for the logged-out login screen and role dashboards.
///
/// Use with [Semantics] / [Icon.semanticLabel] so tests can find
/// `find.bySemanticsLabel` / `find.bySemanticsIdentifier` without relying on
/// visual copy alone.
abstract final class AppSemantics {
  static const loginScreen = 'Login screen';
  static const loginForm = 'Login form';
  static const emailField = 'Email';
  static const passwordField = 'Password';
  static const loginButton = 'Login';
  static const signingIn = 'Signing in';
  static const createCompany = 'Create Company';
  static const showPassword = 'Show password';
  static const hidePassword = 'Hide password';
  static const darkMode = 'Dark mode';
  static const lightMode = 'Light mode';

  static const employeeDashboard = 'Employee dashboard';
  static const employeeNavigation = 'Employee navigation';
  static const adminDashboard = 'Admin dashboard';
  static const adminNavigation = 'Admin navigation';
  static const superAdminDashboard = 'Platform administration';
  static const superAdminNavigation = 'Platform administration navigation';

  static const profileHeader = 'Profile header';
  static const profile = 'Profile';
  static const companySwitcher = 'Company switcher';
  static const settings = 'Settings';
  static const logout = 'Logout';
  static const approveAll = 'Approve All';
  static const previousDate = 'Previous';
  static const todayDate = 'Today';
  static const nextDate = 'Next';
  static const newSubscription = 'New Subscription';
  static const manageBankAccounts = 'Manage Bank Accounts';
}
