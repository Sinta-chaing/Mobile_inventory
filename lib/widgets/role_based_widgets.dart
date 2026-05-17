import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../utils/user_role_constants.dart';

/// Widget that conditionally renders based on user role
class RoleBasedWidget extends StatelessWidget {
  final Widget? adminWidget;
  final Widget? managerWidget;
  final Widget? staffWidget;
  final Widget? defaultWidget;

  const RoleBasedWidget({
    Key? key,
    this.adminWidget,
    this.managerWidget,
    this.staffWidget,
    this.defaultWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final role = userService.getCurrentRole();

    switch (role) {
      case UserRole.admin:
        return adminWidget ?? defaultWidget ?? const SizedBox.shrink();
      case UserRole.manager:
        return managerWidget ?? defaultWidget ?? const SizedBox.shrink();
      case UserRole.staff:
        return staffWidget ?? defaultWidget ?? const SizedBox.shrink();
      default:
        return defaultWidget ?? const SizedBox.shrink();
    }
  }
}

/// Widget that shows content only if user has write permission (admin/manager)
class AdminManagerOnly extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const AdminManagerOnly({Key? key, required this.child, this.fallback})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    if (userService.hasWritePermission()) {
      return child;
    }
    return fallback ?? const SizedBox.shrink();
  }
}

/// Widget that shows content only if user is admin
class AdminOnly extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const AdminOnly({Key? key, required this.child, this.fallback})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    if (userService.isAdmin()) {
      return child;
    }
    return fallback ?? const SizedBox.shrink();
  }
}

/// Widget that shows content only if user is manager
class ManagerOnly extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const ManagerOnly({Key? key, required this.child, this.fallback})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    if (userService.isManager()) {
      return child;
    }
    return fallback ?? const SizedBox.shrink();
  }
}

/// Widget that shows content only if user is staff
class StaffOnly extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const StaffOnly({Key? key, required this.child, this.fallback})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    if (userService.isStaff()) {
      return child;
    }
    return fallback ?? const SizedBox.shrink();
  }
}

/// Button that is only enabled for users with write permission
class RoleBasedButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool? fullWidth;
  final Color? backgroundColor;
  final Color? disabledBackgroundColor;

  const RoleBasedButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = false,
    this.backgroundColor,
    this.disabledBackgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final hasPermission = userService.hasWritePermission();

    final button = icon != null
        ? ElevatedButton.icon(
            onPressed: hasPermission ? onPressed : null,
            icon: Icon(icon),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              disabledBackgroundColor: disabledBackgroundColor,
            ),
          )
        : ElevatedButton(
            onPressed: hasPermission ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              disabledBackgroundColor: disabledBackgroundColor,
            ),
            child: Text(label),
          );

    if (fullWidth == true) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

/// Show role badge with user's role
class RoleBadge extends StatelessWidget {
  final double? fontSize;
  final EdgeInsets? padding;

  const RoleBadge({Key? key, this.fontSize = 12, this.padding})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final role = userService.getCurrentRole() ?? 'unknown';
    final roleColor = UserRole.getRoleColor(role);
    final roleIcon = UserRole.getRoleIcon(role);
    final roleName = UserRole.getDisplayName(role);

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(int.parse('0x${roleColor.replaceFirst('#', '')}')),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(roleIcon, style: TextStyle(fontSize: fontSize)),
          const SizedBox(width: 4),
          Text(
            roleName,
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
