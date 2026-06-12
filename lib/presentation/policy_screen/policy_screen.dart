import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import 'dart:ui';

class PolicyScreen extends StatefulWidget {
  const PolicyScreen({super.key});

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen> {
  int _selectedNavIndex = -1;

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
            'Privacy Policy',
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            'Privacy Policy',
            '''Our Privacy Policy explains how we collect, use, protect, and handle your personal information. We are committed to protecting your privacy and ensuring you have a positive experience on our platform.''',
          ),
          const SizedBox(height: 20),
          _buildSection(
            'Information We Collect',
            '''We collect information you provide directly to us, such as:
• Account registration information (name, email, phone)
• Company and business information
• Payment information
• Communication preferences
• Usage data and analytics''',
          ),
          const SizedBox(height: 20),
          _buildSection(
            'How We Use Your Information',
            '''We use the information we collect to:
• Provide and improve our services
• Process transactions
• Send you updates and communications
• Personalize your experience
• Analyze usage patterns and trends
• Comply with legal obligations''',
          ),
          const SizedBox(height: 20),
          _buildSection(
            'Data Security',
            '''We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.''',
          ),
          const SizedBox(height: 20),
          _buildSection('Your Rights', '''You have the right to:
• Access your personal information
• Correct inaccurate data
• Request deletion of your data
• Opt-out of communications
• Data portability'''),
          const SizedBox(height: 20),
          _buildSection(
            'Contact Us',
            '''If you have any questions about this Privacy Policy, please contact us at privacy@inventrack.com''',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1C1B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: AppTheme.outline,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
