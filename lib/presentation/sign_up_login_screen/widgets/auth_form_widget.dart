import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class AuthFormWidget extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController businessNameController;
  final bool isLogin;
  final bool isLoading;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;

  const AuthFormWidget({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.businessNameController,
    required this.isLogin,
    required this.isLoading,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isLogin) ...[
            _buildLabel('Business Name'),
            const SizedBox(height: 6),
            TextFormField(
              controller: businessNameController,
              decoration: InputDecoration(
                hintText: 'e.g. Meridian Hardware Co.',
                prefixIcon: const Icon(Icons.business_rounded, size: 20),
                prefixIconColor: AppTheme.outline,
              ),
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Business name is required' : null,
            ),
            const SizedBox(height: 16),
          ],
          _buildLabel('Work Email'),
          const SizedBox(height: 6),
          TextFormField(
            controller: emailController,
            decoration: InputDecoration(
              hintText: 'you@company.com',
              prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
              prefixIconColor: AppTheme.outline,
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildLabel('Password'),
          const SizedBox(height: 6),
          TextFormField(
            controller: passwordController,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              hintText: isLogin ? 'Enter your password' : 'Min. 8 characters',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              prefixIconColor: AppTheme.outline,
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppTheme.outline,
                ),
                onPressed: onToggleObscure,
              ),
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (!isLogin && v.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
          if (isLogin) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot password?',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _buildSubmitButton(theme),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLogin
                    ? "Don't have an account? "
                    : 'Already have an account? ',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13,
                  color: AppTheme.outline,
                ),
              ),
              GestureDetector(
                onTap: onToggleMode,
                child: Text(
                  isLogin ? 'Sign Up' : 'Sign In',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          if (!isLogin) ...[
            const SizedBox(height: 16),
            Text(
              'By signing up, you agree to our Terms of Service and Privacy Policy.',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 11,
                color: AppTheme.outline,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.ibmPlexSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF3F4946),
        letterSpacing: 0.1,
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.primary.withAlpha(153),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                isLogin ? 'Sign In' : 'Create Account',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}
