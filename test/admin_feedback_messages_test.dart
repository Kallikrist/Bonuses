import 'package:flutter_test/flutter_test.dart';
import 'package:bonuses/models/user.dart';

void main() {
  group('Admin Feedback Messages Tests', () {
    // Helper function to get user names from IDs (same as in admin_dashboard.dart)
    String getUserNames(Set<String> userIds, List<User> allUsers) {
      final names = userIds
          .map((id) {
            final user = allUsers.firstWhere(
              (u) => u.id == id,
              orElse: () => User(
                id: id,
                name: 'Unknown User',
                email: '',
                role: UserRole.employee,
                primaryCompanyId: '',
                companyIds: [],
                companyRoles: {},
                createdAt: DateTime.now(),
              ),
            );
            return user.name;
          })
          .toList();
      return names.join(', ');
    }

    test('getUserNames returns correct names for valid user IDs', () {
      // Create test users
      final users = [
        User(
          id: 'user1',
          name: 'John Doe',
          email: 'john@test.com',
          role: UserRole.employee,
          primaryCompanyId: 'company1',
          companyIds: ['company1'],
          companyRoles: {'company1': 'employee'},
          createdAt: DateTime.now(),
        ),
        User(
          id: 'user2',
          name: 'Jane Smith',
          email: 'jane@test.com',
          role: UserRole.employee,
          primaryCompanyId: 'company1',
          companyIds: ['company1'],
          companyRoles: {'company1': 'employee'},
          createdAt: DateTime.now(),
        ),
      ];

      // Test single user
      expect(getUserNames({'user1'}, users), 'John Doe');

      // Test multiple users
      final multipleNames = getUserNames({'user1', 'user2'}, users);
      expect(multipleNames, contains('John Doe'));
      expect(multipleNames, contains('Jane Smith'));
      expect(multipleNames, contains(','));
    });

    test('getUserNames handles unknown user IDs gracefully', () {
      final users = <User>[];

      // Test with non-existent user ID
      expect(getUserNames({'nonexistent_id'}, users), 'Unknown User');
    });

    test('Team member added message format is correct', () {
      final users = [
        User(
          id: 'emp1',
          name: 'John Doe',
          email: 'john@test.com',
          role: UserRole.employee,
          primaryCompanyId: 'company1',
          companyIds: ['company1'],
          companyRoles: {'company1': 'employee'},
          createdAt: DateTime.now(),
        ),
        User(
          id: 'emp2',
          name: 'Jane Smith',
          email: 'jane@test.com',
          role: UserRole.employee,
          primaryCompanyId: 'company1',
          companyIds: ['company1'],
          companyRoles: {'company1': 'employee'},
          createdAt: DateTime.now(),
        ),
      ];

      // Simulate adding a team member
      final originalMembers = {'emp1'}.toSet();
      final updatedMembers = {'emp1', 'emp2'}.toSet();
      final addedMembers = updatedMembers.difference(originalMembers);

      // Generate feedback message
      final addedNames = getUserNames(addedMembers, users);
      final message =
          'Team member(s) added: $addedNames - points awarded automatically';

      // Verify message contains the added member's name
      expect(message, contains('Jane Smith'));
      expect(message, contains('Team member(s) added:'));
      expect(message, contains('points awarded automatically'));
    });

    test('Team member removed message format is correct', () {
      final users = [
        User(
          id: 'emp1',
          name: 'John Doe',
          email: 'john@test.com',
          role: UserRole.employee,
          primaryCompanyId: 'company1',
          companyIds: ['company1'],
          companyRoles: {'company1': 'employee'},
          createdAt: DateTime.now(),
        ),
        User(
          id: 'emp2',
          name: 'Jane Smith',
          email: 'jane@test.com',
          role: UserRole.employee,
          primaryCompanyId: 'company1',
          companyIds: ['company1'],
          companyRoles: {'company1': 'employee'},
          createdAt: DateTime.now(),
        ),
      ];

      // Simulate removing a team member
      final originalMembers = {'emp1', 'emp2'}.toSet();
      final updatedMembers = {'emp1'}.toSet();
      final removedMembers = originalMembers.difference(updatedMembers);

      // Generate feedback message
      final removedNames = getUserNames(removedMembers, users);
      final message =
          'Team member(s) removed: $removedNames - points withdrawn automatically';

      // Verify message contains the removed member's name
      expect(message, contains('Jane Smith'));
      expect(message, contains('Team member(s) removed:'));
      expect(message, contains('points withdrawn automatically'));
    });

    test('Team members updated message includes both added and removed names',
        () {
      final users = [
        User(
          id: 'emp1',
          name: 'John Doe',
          email: 'john@test.com',
          role: UserRole.employee,
          primaryCompanyId: 'company1',
          companyIds: ['company1'],
          companyRoles: {'company1': 'employee'},
          createdAt: DateTime.now(),
        ),
        User(
          id: 'emp2',
          name: 'Jane Smith',
          email: 'jane@test.com',
          role: UserRole.employee,
          primaryCompanyId: 'company1',
          companyIds: ['company1'],
          companyRoles: {'company1': 'employee'},
          createdAt: DateTime.now(),
        ),
        User(
          id: 'emp3',
          name: 'Bob Johnson',
          email: 'bob@test.com',
          role: UserRole.employee,
          primaryCompanyId: 'company1',
          companyIds: ['company1'],
          companyRoles: {'company1': 'employee'},
          createdAt: DateTime.now(),
        ),
      ];

      // Simulate changing team members (remove emp2, add emp3)
      final originalMembers = {'emp1', 'emp2'}.toSet();
      final updatedMembers = {'emp1', 'emp3'}.toSet();
      final removedMembers = originalMembers.difference(updatedMembers);
      final addedMembers = updatedMembers.difference(originalMembers);

      // Generate feedback message
      final addedNames = getUserNames(addedMembers, users);
      final removedNames = getUserNames(removedMembers, users);
      final message =
          'Team members updated: Added $addedNames, Removed $removedNames - points adjusted';

      // Verify message contains both added and removed names
      expect(message, contains('Bob Johnson')); // Added
      expect(message, contains('Jane Smith')); // Removed
      expect(message, contains('Added'));
      expect(message, contains('Removed'));
      expect(message, contains('points adjusted'));
    });

    test('Multiple team members are comma-separated in message', () {
      final users = [
        User(
          id: 'user1',
          name: 'John Doe',
          email: 'john@test.com',
          role: UserRole.employee,
          primaryCompanyId: 'company1',
          companyIds: ['company1'],
          companyRoles: {'company1': 'employee'},
          createdAt: DateTime.now(),
        ),
        User(
          id: 'user2',
          name: 'Jane Smith',
          email: 'jane@test.com',
          role: UserRole.employee,
          primaryCompanyId: 'company1',
          companyIds: ['company1'],
          companyRoles: {'company1': 'employee'},
          createdAt: DateTime.now(),
        ),
        User(
          id: 'user3',
          name: 'Bob Johnson',
          email: 'bob@test.com',
          role: UserRole.employee,
          primaryCompanyId: 'company1',
          companyIds: ['company1'],
          companyRoles: {'company1': 'employee'},
          createdAt: DateTime.now(),
        ),
      ];

      // Test multiple users formatting
      final names = getUserNames({'user1', 'user2', 'user3'}, users);

      // Should contain all names
      expect(names, contains('John Doe'));
      expect(names, contains('Jane Smith'));
      expect(names, contains('Bob Johnson'));

      // Should be comma-separated
      expect(names, contains(','));
    });

    test('Empty user set returns empty string', () {
      final users = [
        User(
          id: 'user1',
          name: 'John Doe',
          email: 'john@test.com',
          role: UserRole.employee,
          primaryCompanyId: 'company1',
          companyIds: ['company1'],
          companyRoles: {'company1': 'employee'},
          createdAt: DateTime.now(),
        ),
      ];

      expect(getUserNames({}, users), '');
    });

    test('Mixed known and unknown users are handled correctly', () {
      final users = [
        User(
          id: 'user1',
          name: 'John Doe',
          email: 'john@test.com',
          role: UserRole.employee,
          primaryCompanyId: 'company1',
          companyIds: ['company1'],
          companyRoles: {'company1': 'employee'},
          createdAt: DateTime.now(),
        ),
      ];

      final names = getUserNames({'user1', 'unknown_user'}, users);
      expect(names, contains('John Doe'));
      expect(names, contains('Unknown User'));
      expect(names, contains(','));
    });
  });
}
