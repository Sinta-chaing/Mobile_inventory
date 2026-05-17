/// User model to represent authenticated user with role information
class User {
  final int id;
  final String username;
  final String email;
  final String role; // 'administrator', 'manager', or 'staff'
  final String? firstName;
  final String? lastName;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.firstName,
    this.lastName,
  });

  /// Create User from JSON response
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'staff',
      firstName: json['first_name'],
      lastName: json['last_name'],
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'first_name': firstName,
      'last_name': lastName,
    };
  }

  /// Get user's full name
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username;
  }

  /// Check if user is administrator
  bool get isAdmin => role == 'administrator';

  /// Check if user is manager
  bool get isManager => role == 'manager';

  /// Check if user is staff
  bool get isStaff => role == 'staff';

  /// Check if user has write permissions (admin or manager)
  bool get hasWritePermission => isAdmin || isManager;

  @override
  String toString() => 'User(id: $id, username: $username, role: $role)';
}
