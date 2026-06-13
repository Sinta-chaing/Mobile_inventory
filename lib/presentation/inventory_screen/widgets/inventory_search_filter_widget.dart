import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../../widgets/animated_scale_button.dart';

class InventorySearchFilterWidget extends StatelessWidget {
  final String searchQuery;
  final List<String> categories;
  final List<String> subcategories;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onAddItem;
  final VoidCallback? onImageSearch;
  
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final String selectedSubCategory;
  final ValueChanged<String> onSubCategoryChanged;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;
  final String selectedStockStatus;
  final ValueChanged<String> onStockStatusChanged;

  const InventorySearchFilterWidget({
    super.key,
    required this.searchQuery,
    required this.categories,
    required this.subcategories,
    required this.onSearchChanged,
    this.onAddItem,
    this.onImageSearch,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.selectedSubCategory,
    required this.onSubCategoryChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.selectedStockStatus,
    required this.onStockStatusChanged,
  });

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    final dropdownValue = items.contains(value) ? value : (items.isNotEmpty ? items.first : 'All');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.outlineVariant.withAlpha(150)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: dropdownValue,
          isDense: true,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: const Color(0xFF1A1C1B),
            fontWeight: FontWeight.w500,
          ),
          icon: const Icon(Icons.arrow_drop_down, size: 18, color: AppTheme.outline),
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(
                '$label: $val',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1C1B),
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              onChanged(val);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar with action buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.outlineVariant),
                  ),
                  child: TextField(
                    onChanged: onSearchChanged,
                    style: GoogleFonts.dmSans(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search by name or SKU…',
                      hintStyle: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppTheme.outline,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppTheme.outline,
                      ),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppTheme.outline,
                              ),
                              onPressed: () => onSearchChanged(''),
                              padding: EdgeInsets.zero,
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Image search button
              if (onImageSearch != null)
                AnimatedScaleButton(
                  onTap: onImageSearch!,
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.image_search_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              // Add item button
              if (onAddItem != null)
                AnimatedScaleButton(
                  onTap: onAddItem!,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(30),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
          ),
          const SizedBox(height: 12),
          // Horizontal scrollable filter row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDropdownFilter(
                  label: 'Category',
                  value: selectedCategory,
                  items: categories,
                  onChanged: onCategoryChanged,
                ),
                const SizedBox(width: 8),
                _buildDropdownFilter(
                  label: 'Subcategory',
                  value: selectedSubCategory,
                  items: subcategories,
                  onChanged: onSubCategoryChanged,
                ),
                const SizedBox(width: 8),
                _buildDropdownFilter(
                  label: 'Status',
                  value: selectedStatus,
                  items: const ['All', 'Active', 'Inactive', 'Discount'],
                  onChanged: onStatusChanged,
                ),
                const SizedBox(width: 8),
                _buildDropdownFilter(
                  label: 'Stock',
                  value: selectedStockStatus,
                  items: const ['All', 'In Stock', 'Out of Stock', 'Low Stock'],
                  onChanged: onStockStatusChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
