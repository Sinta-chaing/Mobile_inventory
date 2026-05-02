import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../theme/app_theme.dart';

class DemoCredentialsWidget extends StatelessWidget {
  final VoidCallback onFill;

  const DemoCredentialsWidget({super.key, required this.onFill});

  void _copyToClipboard(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    Fluttertoast.showToast(
      msg: '$label copied to clipboard',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.primaryDark,
      textColor: Colors.white,
      fontSize: 13,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.infoContainer.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.info.withAlpha(64), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: AppTheme.info,
              ),
              const SizedBox(width: 6),
              Text(
                'Demo Account',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.info,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onFill,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: AppTheme.info.withAlpha(26),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  'Autofill',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.info,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildCredentialRow(
            context,
            label: 'Email',
            value: 'manager@inventrack.io',
          ),
          const SizedBox(height: 6),
          _buildCredentialRow(context, label: 'Password', value: 'Track2024!'),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.outline,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1C1B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: () => _copyToClipboard(context, value, label),
          child: Container(
            padding: const EdgeInsets.all(4),
            child: const Icon(
              Icons.copy_rounded,
              size: 14,
              color: AppTheme.outline,
            ),
          ),
        ),
      ],
    );
  }
}
