import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import '../../services/user_service.dart';
import '../../utils/user_role_constants.dart';
import 'dart:ui';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedNavIndex = -1;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late UserService _userService;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _userService = UserService();

    // Initialize controllers with empty values
    _usernameController = TextEditingController();
    _nameController = TextEditingController();
    _emailController = TextEditingController();

    // Load user data from UserService
    _loadUserData();
  }

  void _loadUserData() {
    final user = _userService.getUser();

    if (user != null) {
      _usernameController.text = user.username;
      _emailController.text = user.email;
      _nameController.text = user.fullName;
    } else {
      // No user logged in - should not happen, but handle gracefully
      _usernameController.text = 'Guest User';
      _emailController.text = 'Not available';
      _nameController.text = 'No user data';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isTablet
          ? null
          : SizedBox(
              height: 76,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(220),
                        borderRadius: BorderRadius.circular(20),
                        border: Border(
                          top: BorderSide(
                            color: AppTheme.outlineVariant.withAlpha(100),
                            width: 1,
                          ),
                        ),
                      ),
                      child: AppNavigation(
                        currentIndex: _selectedNavIndex,
                        onDestinationSelected: (_) {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppTheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Profile',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1C1B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final user = _userService.getUser();
    final roleColor = user != null
        ? UserRole.getRoleColor(user.role)
        : '#999999';
    final roleIcon = user != null ? UserRole.getRoleIcon(user.role) : '❓';
    final roleName = user != null
        ? UserRole.getDisplayName(user.role)
        : 'Unknown';
    final roleDescription = user != null
        ? UserRole.getDescription(user.role)
        : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Center(
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 50,
                    color: AppTheme.primary,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // User Info Section
          Center(
            child: Column(
              children: [
                // Username
                Text(
                  user?.username ?? 'Guest User',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1C1B),
                  ),
                ),
                const SizedBox(height: 4),

                // Email
                if (user?.email != null && user!.email.isNotEmpty)
                  Text(
                    user.email,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Role Badge Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(
                  int.parse('0x${roleColor.replaceFirst('#', '')}'),
                ).withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse('0x${roleColor.replaceFirst('#', '')}'),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(roleIcon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        roleName,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Role Description
                Text(
                  'Access Level',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  roleDescription,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Profile Form Section
          Text(
            'Account Information',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1C1B),
            ),
          ),
          const SizedBox(height: 16),

          // Username (read-only)
          _buildFormField(
            'Username',
            _usernameController,
            readOnly: true,
            helperText: 'Your unique username',
          ),
          const SizedBox(height: 16),

          // Email (read-only for now)
          _buildFormField(
            'Email',
            _emailController,
            readOnly: true,
            helperText: 'Your registered email address',
          ),
          const SizedBox(height: 16),

          // Full Name
          _buildFormField(
            'Full Name',
            _nameController,
            readOnly: !_isEditing,
            helperText: 'Your full name',
          ),
          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _isEditing = !_isEditing);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isEditing ? 'Cancel' : 'Edit Profile',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (_isEditing) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Profile update functionality coming soon',
                          ),
                        ),
                      );
                      setState(() => _isEditing = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Save Changes',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1C1B),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? Colors.grey[100] : AppTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: readOnly ? Colors.grey[300]! : AppTheme.outlineVariant,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            helperText: helperText,
            helperStyle: GoogleFonts.dmSans(fontSize: 11, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          style: GoogleFonts.dmSans(
            color: readOnly ? Colors.grey[600] : Colors.black,
          ),
        ),
      ],
    );
  }
}
