/// Role constants and helpers for managing user permissions
class UserRole {
  /// Administrator role - full access
  static const String admin = 'administrator';

  /// Manager role - can manage products, inventory, customers, invoices
  static const String manager = 'manager';

  /// Staff role - read-only access, can process sales
  static const String staff = 'staff';

  /// Get all available roles
  static const List<String> allRoles = [admin, manager, staff];

  /// Check if role is valid
  static bool isValidRole(String role) => allRoles.contains(role);

  /// Get display name for role
  static String getDisplayName(String role) {
    switch (role) {
      case admin:
        return 'Administrator';
      case manager:
        return 'Manager';
      case staff:
        return 'Staff';
      default:
        return 'Unknown Role';
    }
  }

  /// Get role color for UI display
  static String getRoleColor(String role) {
    switch (role) {
      case admin:
        return '#FF6B6B'; // Red
      case manager:
        return '#4ECDC4'; // Teal
      case staff:
        return '#95E1D3'; // Light teal
      default:
        return '#999999'; // Gray
    }
  }

  /// Get role icon
  static String getRoleIcon(String role) {
    switch (role) {
      case admin:
        return '👑'; // Crown
      case manager:
        return '📋'; // Clipboard
      case staff:
        return '👤'; // Person
      default:
        return '❓'; // Question mark
    }
  }

  /// Get role description
  static String getDescription(String role) {
    switch (role) {
      case admin:
        return 'Full access to all features and settings';
      case manager:
        return 'Can manage products, inventory, customers, and invoices';
      case staff:
        return 'Can view products and process sales (read-only for most features)';
      default:
        return 'Unknown role';
    }
  }
}

/// Permission helper class
class Permission {
  /// Check if role can edit products
  static bool canEditProducts(String role) =>
      role == UserRole.admin || role == UserRole.manager;

  /// Check if role can view cost price
  static bool canViewCostPrice(String role) =>
      role == UserRole.admin || role == UserRole.manager;

  /// Check if role can manage users
  static bool canManageUsers(String role) => role == UserRole.admin;

  /// Check if role can delete items
  static bool canDeleteItems(String role) =>
      role == UserRole.admin || role == UserRole.manager;

  /// Check if role can manage inventory
  static bool canManageInventory(String role) =>
      role == UserRole.admin || role == UserRole.manager;

  /// Check if role can process sales
  static bool canProcessSales(String role) => UserRole.allRoles.contains(role);

  /// Get list of roles that can perform action
  static List<String> getRolesWithPermission(String action) {
    switch (action) {
      case 'edit_product':
      case 'delete_product':
      case 'manage_inventory':
      case 'manage_users':
        return [UserRole.admin, UserRole.manager];
      case 'view_cost_price':
        return [UserRole.admin, UserRole.manager];
      case 'process_sales':
      case 'view_products':
        return UserRole.allRoles;
      default:
        return [];
    }
  }
}
