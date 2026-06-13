import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../purchase_screen/purchase_screen.dart';
import '../../inventory_screen/inventory_screen.dart';

class BIProfitBreakdownWidget extends StatefulWidget {
  final List<Order> orders;
  final List<StockItem> stockItems;

  const BIProfitBreakdownWidget({
    super.key,
    required this.orders,
    required this.stockItems,
  });

  @override
  State<BIProfitBreakdownWidget> createState() =>
      _BIProfitBreakdownWidgetState();
}

class _BIProfitBreakdownWidgetState extends State<BIProfitBreakdownWidget> {
  late List<_ProfitItem> _items;
  int _currentPage = 1;
  static const int _itemsPerPage = 10;
  static const int _initialItemsToShow = 3;
  static const int _itemsToLoadMore = 7;
  late Map<int, int> _loadedItemsPerPage;

  @override
  void initState() {
    super.initState();
    _loadedItemsPerPage = {};
    _generateProfitItems();
  }

  void _generateProfitItems() {
    final items = <_ProfitItem>[];

    // Generate profit items from paid orders only
    for (final order in widget.orders) {
      for (final item in order.items) {
        // Find cost price from inventory
        final stockItem = widget.stockItems.firstWhere(
          (s) => s.name.toLowerCase() == item.itemName.toLowerCase(),
          orElse: () => StockItem(
            id: '',
            inventoryId: '',
            name: item.itemName,
            sku: '',
            category: '',
            subCategory: '',
            quantity: 0,
            reorderLevel: 0,
            unitCost: 0.0,
            unitPrice: item.unitPrice,
            supplierName: '',
            imageUrl: '',
            semanticLabel: '',
          ),
        );

        items.add(
          _ProfitItem(
            orderId: order.orderId,
            itemName: item.itemName,
            quantity: item.quantity,
            costPrice: stockItem.unitCost,
            sellingPrice: item.unitPrice,
            discount: item.discount,
          ),
        );
      }
    }

    _items = items;
  }

  int get _totalPages {
    return (_items.length / _itemsPerPage).ceil();
  }

  int get _totalItemsOnCurrentPage {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _items.length);
    return endIndex - startIndex;
  }

  List<_ProfitItem> get _currentItems {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final loadedCount =
        _loadedItemsPerPage[_currentPage] ?? _initialItemsToShow;
    final endIndex = (startIndex + loadedCount).clamp(0, _items.length);
    return _items.sublist(startIndex, endIndex);
  }

  bool get _canLoadMore {
    final loadedCount =
        _loadedItemsPerPage[_currentPage] ?? _initialItemsToShow;
    return loadedCount < _totalItemsOnCurrentPage;
  }

  void _loadMore() {
    setState(() {
      final currentLoaded =
          _loadedItemsPerPage[_currentPage] ?? _initialItemsToShow;
      final newCount = (currentLoaded + _itemsToLoadMore).clamp(
        0,
        _totalItemsOnCurrentPage,
      );
      _loadedItemsPerPage[_currentPage] = newCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profit Calculation Breakdown',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1C1B),
            ),
          ),
          Text(
            'Paid invoices only · Profit = Revenue - Cost',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11,
              color: AppTheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          // Pagination buttons
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Wrap(
                spacing: 8,
                children: List.generate(_totalPages, (index) {
                  final pageNumber = index + 1;
                  final isActive = pageNumber == _currentPage;
                  return GestureDetector(
                    onTap: () => setState(() => _currentPage = pageNumber),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.primary
                            : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isActive
                              ? AppTheme.primary
                              : AppTheme.outlineVariant,
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        pageNumber.toString(),
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF1A1C1B),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          // Page info
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Showing ${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage - 1) * _itemsPerPage + _currentItems.length} of ${_items.length} invoices',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 10,
                color: AppTheme.outline,
              ),
            ),
          ),
          // Show table for larger screens, cards for mobile
          if (isMobile)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _currentItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _currentItems[index];
                return _buildProfitCard(item);
              },
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 64,
                ),
                child: DataTable(
                  headingRowColor: MaterialStatePropertyAll(
                    AppTheme.surfaceVariant,
                  ),
                  columnSpacing: 16,
                  horizontalMargin: 0,
                  columns: [
                    DataColumn(
                      label: Text(
                        'Order ID',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1B),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Item Name',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1B),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Qty',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1B),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Cost/Unit',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1B),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Selling/Unit',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1B),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Discount %',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1B),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Total Cost',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1B),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Total Revenue',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1B),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Profit',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                  rows: _currentItems
                      .map(
                        (item) => DataRow(
                          cells: [
                            DataCell(
                              Text(
                                item.orderId.toString(),
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 10,
                                  color: const Color(0xFF1A1C1B),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 140,
                                child: Text(
                                  item.itemName,
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 10,
                                    color: const Color(0xFF1A1C1B),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                item.quantity.toString(),
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 10,
                                  color: const Color(0xFF1A1C1B),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '\$${item.costPrice.toStringAsFixed(2)}',
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 10,
                                  color: const Color(0xFF1A1C1B),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '\$${item.sellingPrice.toStringAsFixed(2)}',
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 10,
                                  color: const Color(0xFF1A1C1B),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${item.discount.toStringAsFixed(0)}%',
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 10,
                                  color: const Color(0xFF1A1C1B),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '\$${item.totalCost.toStringAsFixed(2)}',
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 10,
                                  color: const Color(0xFF1A1C1B),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '\$${item.totalRevenue.toStringAsFixed(2)}',
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 10,
                                  color: const Color(0xFF1A1C1B),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '\$${item.profit.toStringAsFixed(2)}',
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 10,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          // Load More button
          if (_canLoadMore)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loadMore,
                  icon: const Icon(Icons.expand_more),
                  label: Text(
                    'Load More (${_totalItemsOnCurrentPage - (_loadedItemsPerPage[_currentPage] ?? _initialItemsToShow)} remaining)',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfitCard(_ProfitItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.orderId.toString(),
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.itemName,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1C1B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '\$${item.profit.toStringAsFixed(2)}',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildValueRow('Qty', '${item.quantity}')),
              Expanded(
                child: _buildValueRow(
                  'Cost/Unit',
                  '\$${item.costPrice.toStringAsFixed(2)}',
                ),
              ),
              Expanded(
                child: _buildValueRow(
                  'Selling/Unit',
                  '\$${item.sellingPrice.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildValueRow(
                  'Discount',
                  '${item.discount.toStringAsFixed(0)}%',
                ),
              ),
              Expanded(
                child: _buildValueRow(
                  'Total Cost',
                  '\$${item.totalCost.toStringAsFixed(2)}',
                ),
              ),
              Expanded(
                child: _buildValueRow(
                  'Revenue',
                  '\$${item.totalRevenue.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.ibmPlexSans(fontSize: 9, color: AppTheme.outline),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1C1B),
          ),
        ),
      ],
    );
  }
}

class _ProfitItem {
  final int orderId;
  final String itemName;
  final int quantity;
  final double costPrice;
  final double sellingPrice;
  final double discount;

  _ProfitItem({
    required this.orderId,
    required this.itemName,
    required this.quantity,
    required this.costPrice,
    required this.sellingPrice,
    required this.discount,
  });

  double get totalCost => quantity * costPrice;

  double get subtotal => quantity * sellingPrice;

  double get discountAmount => (subtotal * discount) / 100;

  double get totalRevenue => subtotal - discountAmount;

  double get profit => totalRevenue - totalCost;
}
