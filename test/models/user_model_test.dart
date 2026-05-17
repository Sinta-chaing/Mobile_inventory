import 'package:flutter_test/flutter_test.dart';
import 'package:inventrack/models/user_model.dart';

void main() {
  group('User Model', () {
    test('User can be created with all properties', () {
      final user = User(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        role: 'staff',
        firstName: 'John',
        lastName: 'Doe',
      );

      expect(user.id, 1);
      expect(user.username, 'testuser');
      expect(user.email, 'test@example.com');
      expect(user.role, 'staff');
      expect(user.firstName, 'John');
      expect(user.lastName, 'Doe');
    });

    test('User can be created without optional properties', () {
      final user = User(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        role: 'staff',
      );

      expect(user.id, 1);
      expect(user.firstName, isNull);
      expect(user.lastName, isNull);
    });

    test('User.fromJson correctly parses JSON response from backend', () {
      final json = {
        'id': 1,
        'username': 'admin',
        'email': 'admin@example.com',
        'role': 'administrator',
        'first_name': 'John',
        'last_name': 'Doe',
      };

      final user = User.fromJson(json);

      expect(user.id, 1);
      expect(user.username, 'admin');
      expect(user.email, 'admin@example.com');
      expect(user.role, 'administrator');
      expect(user.firstName, 'John');
      expect(user.lastName, 'Doe');
    });

    test('User.fromJson handles missing optional fields', () {
      final json = {
        'id': 2,
        'username': 'staff_user',
        'email': 'staff@example.com',
        'role': 'staff',
      };

      final user = User.fromJson(json);

      expect(user.id, 2);
      expect(user.firstName, isNull);
      expect(user.lastName, isNull);
    });

    test('User.fromJson uses default values for missing required fields', () {
      final json = {'id': 3};

      final user = User.fromJson(json);

      expect(user.id, 3);
      expect(user.username, '');
      expect(user.email, '');
      expect(user.role, 'staff');
    });

    test('User.toJson correctly converts to JSON for storage', () {
      final user = User(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        role: 'manager',
        firstName: 'Jane',
        lastName: 'Smith',
      );

      final json = user.toJson();

      expect(json['id'], 1);
      expect(json['username'], 'testuser');
      expect(json['email'], 'test@example.com');
      expect(json['role'], 'manager');
      expect(json['first_name'], 'Jane');
      expect(json['last_name'], 'Smith');
    });

    test('User.fullName returns formatted full name', () {
      final user = User(
        id: 1,
        username: 'john',
        email: 'john@example.com',
        role: 'staff',
        firstName: 'John',
        lastName: 'Doe',
      );

      expect(user.fullName, 'John Doe');
    });

    test('User.fullName returns username when first/last names missing', () {
      final user = User(
        id: 1,
        username: 'john',
        email: 'john@example.com',
        role: 'staff',
      );

      expect(user.fullName, 'john');
    });

    test('User role checks work correctly for administrator', () {
      final user = User(
        id: 1,
        username: 'admin',
        email: 'admin@example.com',
        role: 'administrator',
      );

      expect(user.isAdmin, true);
      expect(user.isManager, false);
      expect(user.isStaff, false);
      expect(user.hasWritePermission, true);
    });

    test('User role checks work correctly for manager', () {
      final user = User(
        id: 2,
        username: 'manager',
        email: 'manager@example.com',
        role: 'manager',
      );

      expect(user.isAdmin, false);
      expect(user.isManager, true);
      expect(user.isStaff, false);
      expect(user.hasWritePermission, true);
    });

    test('User role checks work correctly for staff', () {
      final user = User(
        id: 3,
        username: 'staff',
        email: 'staff@example.com',
        role: 'staff',
      );

      expect(user.isAdmin, false);
      expect(user.isManager, false);
      expect(user.isStaff, true);
      expect(user.hasWritePermission, false);
    });

    test('User.toString returns meaningful string representation', () {
      final user = User(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        role: 'staff',
      );

      final userString = user.toString();

      expect(userString.contains('1'), true);
      expect(userString.contains('testuser'), true);
      expect(userString.contains('staff'), true);
    });

    test('User can roundtrip through JSON serialization', () {
      final originalUser = User(
        id: 5,
        username: 'roundtrip',
        email: 'roundtrip@example.com',
        role: 'manager',
        firstName: 'Test',
        lastName: 'User',
      );

      final json = originalUser.toJson();
      final deserializedUser = User.fromJson(json);

      expect(deserializedUser.id, originalUser.id);
      expect(deserializedUser.username, originalUser.username);
      expect(deserializedUser.email, originalUser.email);
      expect(deserializedUser.role, originalUser.role);
      expect(deserializedUser.firstName, originalUser.firstName);
      expect(deserializedUser.lastName, originalUser.lastName);
    });
  });
}
