import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import './widgets/auth_form_widget.dart';
import './widgets/auth_header_widget.dart';
import './widgets/demo_credentials_widget.dart';

class SignUpLoginScreen extends StatefulWidget {
  const SignUpLoginScreen({super.key});

  @override
  State<SignUpLoginScreen> createState() => _SignUpLoginScreenState();
}

class _SignUpLoginScreenState extends State<SignUpLoginScreen>
    with TickerProviderStateMixin {
  // TODO: Replace with Riverpod/Bloc for production
  bool _isLogin = true;
  bool _isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessNameController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
    _slideController.reset();
    _slideController.forward();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    // TODO: Replace with real auth service (Firebase/custom API)
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Check demo credentials
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email == 'manager@inventrack.io' && password == 'Track2024!') {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.biDashboardScreen,
        (route) => false,
      );
    } else {
      Fluttertoast.showToast(
        msg: 'Invalid credentials — use the demo account below to sign in',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppTheme.error,
        textColor: Colors.white,
        fontSize: 13,
      );
    }
  }

  void _fillDemoCredentials() {
    setState(() {
      _emailController.text = 'manager@inventrack.io';
      _passwordController.text = 'Track2024!';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: isTablet
              ? _buildTabletLayout(theme)
              : _buildPhoneLayout(theme),
        ),
      ),
    );
  }

  Widget _buildPhoneLayout(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeaderWidget(isLogin: _isLogin),
          const SizedBox(height: 32),
          SlideTransition(
            position: _slideAnimation,
            child: AuthFormWidget(
              formKey: _formKey,
              emailController: _emailController,
              passwordController: _passwordController,
              businessNameController: _businessNameController,
              isLogin: _isLogin,
              isLoading: _isLoading,
              obscurePassword: _obscurePassword,
              onToggleObscure: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              onSubmit: _handleSubmit,
              onToggleMode: _toggleMode,
            ),
          ),
          const SizedBox(height: 24),
          DemoCredentialsWidget(onFill: _fillDemoCredentials),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(ThemeData theme) {
    return Center(
      child: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeaderWidget(isLogin: _isLogin),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(18),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: AuthFormWidget(
                    formKey: _formKey,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    businessNameController: _businessNameController,
                    isLogin: _isLogin,
                    isLoading: _isLoading,
                    obscurePassword: _obscurePassword,
                    onToggleObscure: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onSubmit: _handleSubmit,
                    onToggleMode: _toggleMode,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              DemoCredentialsWidget(onFill: _fillDemoCredentials),
            ],
          ),
        ),
      ),
    );
  }
}
