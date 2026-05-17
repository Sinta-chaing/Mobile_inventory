import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventrack/services/user_service.dart';
import 'package:inventrack/models/user_model.dart';

void main() {
  setUpAll(() {
    // Initialize SharedPreferences mock before any tests
    SharedPreferences.setMockInitialValues({});
  });

  group('UserService', () {
    late UserService userService;

    setUp(() async {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      userService = UserService();
      await userService.init();
    });

    test('UserService is a singleton', () {
      final service1 = UserService();
      final service2 = UserService();
      expect(identical(service1, service2), true);
    });

    test('User is not logged in initially', () async {
      expect(userService.isLoggedIn(), false);
      expect(userService.getUser(), isNull);
    });

    test('Can set and get current user', () async {
      final user = User(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        role: 'staff',
      );

      await userService.setUser(user);

      expect(userService.isLoggedIn(), true);
      expect(userService.getUser()?.username, 'testuser');
      expect(userService.getUser()?.email, 'test@example.com');
    });

    test('Admin user permissions are correctly identified', () async {
      final adminUser = User(
        id: 1,
        username: 'admin',
        email: 'admin@example.com',
        role: 'administrator',
      );

      await userService.setUser(adminUser);

      expect(userService.isAdmin(), true);
      expect(userService.isManager(), false);
      expect(userService.isStaff(), false);
      expect(userService.hasWritePermission(), true);
      expect(userService.canManageUsers(), true);
    });

    test('Manager user permissions are correctly identified', () async {
      final managerUser = User(
        id: 2,
        username: 'manager',
        email: 'manager@example.com',
        role: 'manager',
      );

      await userService.setUser(managerUser);

      expect(userService.isAdmin(), false);
      expect(userService.isManager(), true);
      expect(userService.isStaff(), false);
      expect(userService.hasWritePermission(), true);
      expect(userService.canManageUsers(), false);
    });

    test('Staff user permissions are correctly identified', () async {
      final staffUser = User(
        id: 3,
        username: 'staff',
        email: 'staff@example.com',
        role: 'staff',
      );

      await userService.setUser(staffUser);

      expect(userService.isAdmin(), false);
      expect(userService.isManager(), false);
      expect(userService.isStaff(), true);
      expect(userService.hasWritePermission(), false);
      expect(userService.canManageUsers(), false);
    });

    test('Can clear user on logout', () async {
      final user = User(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        role: 'staff',
      );

      await userService.setUser(user);
      expect(userService.isLoggedIn(), true);

      await userService.clearUser();
      expect(userService.isLoggedIn(), false);
      expect(userService.getUser(), isNull);
    });

    test('Can get user display name', () async {
      final user = User(
        id: 1,
        username: 'john',
        email: 'john@example.com',
        role: 'staff',
        firstName: 'John',
        lastName: 'Doe',
      );

      await userService.setUser(user);

      expect(userService.getUserDisplayName(), 'John Doe');
    });

    test('Returns username when no first/last name', () async {
      final user = User(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        role: 'staff',
      );

      await userService.setUser(user);

      expect(userService.getUserDisplayName(), 'testuser');
    });

    test('Role display name is correctly formatted', () async {
      // Test Administrator
      var adminUser = User(
        id: 1,
        username: 'admin',
        email: 'admin@example.com',
        role: 'administrator',
      );
      await userService.setUser(adminUser);
      expect(userService.getRoleDisplayName(), 'Administrator');

      // Test Manager
      var managerUser = User(
        id: 2,
        username: 'manager',
        email: 'manager@example.com',
        role: 'manager',
      );
      await userService.setUser(managerUser);
      expect(userService.getRoleDisplayName(), 'Manager');

      // Test Staff
      var staffUser = User(
        id: 3,
        username: 'staff',
        email: 'staff@example.com',
        role: 'staff',
      );
      await userService.setUser(staffUser);
      expect(userService.getRoleDisplayName(), 'Staff');
    });

    test('Can edit products if has write permission', () async {
      final adminUser = User(
        id: 1,
        username: 'admin',
        email: 'admin@example.com',
        role: 'administrator',
      );

      await userService.setUser(adminUser);
      expect(userService.canEditProducts(), true);

      final staffUser = User(
        id: 2,
        username: 'staff',
        email: 'staff@example.com',
        role: 'staff',
      );

      await userService.setUser(staffUser);
      expect(userService.canEditProducts(), false);
    });

    test('Can view cost price if has write permission', () async {
      final adminUser = User(
        id: 1,
        username: 'admin',
        email: 'admin@example.com',
        role: 'administrator',
      );

      await userService.setUser(adminUser);
      expect(userService.canViewCostPrice(), true);

      final staffUser = User(
        id: 2,
        username: 'staff',
        email: 'staff@example.com',
        role: 'staff',
      );

      await userService.setUser(staffUser);
      expect(userService.canViewCostPrice(), false);
    });
  });
}
