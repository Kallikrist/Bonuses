import '../models/user.dart';

/// Whether this user skips the active-company gate (suspension / selection).
///
/// Super-admin is role-only. The demo email `superadmin@platform.com` is not a
/// privilege — a non-super-admin with that address still needs an active company.
bool skipsCompanyStatusCheck(User user) => user.role == UserRole.superAdmin;
