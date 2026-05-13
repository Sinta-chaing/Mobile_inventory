import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/profile_menu_widget.dart';

class BIHeaderWidget extends StatelessWidget {
  final String selectedPeriod;
  final List<String> periods;
  final ValueChanged<String> onPeriodChanged;
  final VoidCallback? onRefresh;
  final DateTime? lastUpdated;
  final bool isRefreshing;

  const BIHeaderWidget({
    super.key,
    required this.selectedPeriod,
    required this.periods,
    required this.onPeriodChanged,
    this.onRefresh,
    this.lastUpdated,
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Business Intelligence',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1C1B),
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    'Last updated ${_formatDateTime(lastUpdated ?? DateTime.now())}',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 11,
                      color: AppTheme.outline,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: isRefreshing
                    ? null
                    : (onRefresh != null
                          ? () {
                              onRefresh!();
                            }
                          : null),
                icon: isRefreshing
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primary,
                          ),
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
                color: AppTheme.primary,
                tooltip: isRefreshing ? 'Refreshing...' : 'Refresh',
              ),
              const ProfileMenuWidget(),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: periods.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final period = periods[i];
                final isSelected = period == selectedPeriod;
                return GestureDetector(
                  onTap: () => onPeriodChanged(period),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      period,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.outline,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final displayHour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);

    return '$month $day, $year · ${displayHour.toString().padLeft(2, '0')}:$minute $period';
  }
}
