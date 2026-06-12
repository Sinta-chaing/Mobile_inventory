import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AppNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppNavigation({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // BI icon container with matching style
        GestureDetector(
          onTap: () => onDestinationSelected(4),
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 52,
                  decoration: BoxDecoration(
                    color: currentIndex == 4
                        ? AppTheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    currentIndex == 4
                        ? Icons.bar_chart_rounded
                        : Icons.bar_chart_outlined,
                    color: currentIndex == 4
                        ? AppTheme.primary
                        : AppTheme.outline,
                    size: 24,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'BI',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: currentIndex == 4
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: currentIndex == 4
                          ? AppTheme.primary
                          : AppTheme.outline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Divider to isolate BI
        Container(
          width: 1,
          height: 24,
          color: Colors.black,
          margin: const EdgeInsets.symmetric(horizontal: 8),
        ),
        // Main 4 navigation items - Custom implementation
        Expanded(
          child: Row(
            children: [
              _buildNavItem(
                0,
                Icons.inventory_2_outlined,
                Icons.inventory_2_rounded,
                'Inventory',
              ),
              _buildNavItem(
                1,
                Icons.shopping_cart_outlined,
                Icons.shopping_cart_rounded,
                'Purchase',
              ),
              _buildNavItem(
                2,
                Icons.people_outline_rounded,
                Icons.people_rounded,
                'Customers',
              ),
              _buildNavItem(
                3,
                Icons.local_shipping_outlined,
                Icons.local_shipping_rounded,
                'Suppliers',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(
    int index,
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
  ) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onDestinationSelected(index),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 52,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSelected ? filledIcon : outlinedIcon,
                  color: isSelected ? AppTheme.primary : AppTheme.outline,
                  size: 24,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppTheme.primary : AppTheme.outline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tablet NavigationRail variant
class AppNavigationRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppNavigationRail({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      extended: MediaQuery.of(context).size.width >= 840,
      backgroundColor: Colors.white.withAlpha(200),
      indicatorColor: AppTheme.primaryContainer,
      selectedIconTheme: const IconThemeData(color: AppTheme.primaryDark),
      unselectedIconTheme: const IconThemeData(color: AppTheme.outline),
      selectedLabelTextStyle: GoogleFonts.dmSans(
        color: AppTheme.primary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: GoogleFonts.dmSans(
        color: AppTheme.outline,
        fontWeight: FontWeight.w400,
        fontSize: 12,
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2_rounded),
          label: Text('Inventory'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.shopping_cart_outlined),
          selectedIcon: Icon(Icons.shopping_cart_rounded),
          label: Text('Purchase'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_outline_rounded),
          selectedIcon: Icon(Icons.people_rounded),
          label: Text('Customers'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.local_shipping_outlined),
          selectedIcon: Icon(Icons.local_shipping_rounded),
          label: Text('Suppliers'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart_rounded),
          label: Text('BI'),
        ),
      ],
    );
  }
}
