import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import '../../widgets/profile_menu_widget.dart';
import '../../services/supplier_data_service.dart';
import '../../models/all_models.dart' as backend;

// UI-specific Supplier model
class Supplier {
  final int sourceId;
  String name;
  String? sourceUrl;
  String? contactPerson;
  String? email;
  String? phone;
  String? address;
  String? district;
  double totalOrders;
  int orderCount;
  double rating;
  int leadTimeDays;
  String notes;

  Supplier({
    required this.sourceId,
    required this.name,
    this.sourceUrl,
    this.contactPerson,
    this.email,
    this.phone,
    this.address,
    this.district,
    this.totalOrders = 0.0,
    this.orderCount = 0,
    this.rating = 4.0,
    this.leadTimeDays = 7,
    this.notes = '',
  });

  /// Map from backend Source model to UI Supplier
  static Supplier fromBackend(backend.Source source) {
    return Supplier(
      sourceId: source.sourceId,
      name: source.name,
      sourceUrl: source.sourceUrl,
      contactPerson: source.contactPerson,
      email: source.email,
      phone: source.phone,
      address: source.address,
      district: source.district,
    );
  }

  /// Convert UI Supplier back to backend Source
  backend.Source toBackend() {
    return backend.Source(
      sourceId: sourceId,
      name: name,
      sourceUrl: sourceUrl,
      contactPerson: contactPerson,
      email: email,
      phone: phone,
      address: address,
      district: district,
      createdAt: DateTime.now(),
    );
  }
}

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  int _selectedNavIndex = 3;
  String _searchQuery = '';
  List<Supplier> _suppliers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    try {
      final backendSuppliers = await SupplierDataService.fetchSuppliers();
      final suppliers = backendSuppliers
          .map((s) => Supplier.fromBackend(s))
          .toList();
      setState(() {
        _suppliers = suppliers;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading suppliers: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✗ Failed to load suppliers from API.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  List<Supplier> get _filteredSuppliers {
    return _suppliers.where((s) {
      final matchSearch =
          _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (s.contactPerson?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (s.address?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchSearch;
    }).toList();
  }

  void _onNavTap(int index) {
    if (index == _selectedNavIndex) return;
    setState(() => _selectedNavIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.inventoryScreen);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.purchaseScreen);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.customerScreen);
        break;
      case 4:
        Navigator.pushReplacementNamed(context, AppRoutes.biDashboardScreen);
        break;
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  BoxDecoration _outlinedCardDecoration({double radius = 12}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppTheme.outlineVariant, width: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              Expanded(child: _buildSupplierList()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildGlassNavBar(),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildGlassNavBar() {
    return ClipRect(
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
              onDestinationSelected: _onNavTap,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final totalValue = _suppliers.fold<double>(
      0,
      (s, sup) => s + sup.totalOrders,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(14.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(60),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suppliers',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1C2B),
                      ),
                    ),
                    Text(
                      'Manage supplier records',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppTheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              const ProfileMenuWidget(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  '${_suppliers.length}',
                  Icons.business_rounded,
                  AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Purchased',
                  '\$${(totalValue / 1000).toStringAsFixed(0)}k',
                  Icons.attach_money_rounded,
                  AppTheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: _outlinedCardDecoration(radius: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1C2B),
                      ),
                    ),
                    Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: AppTheme.outline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: _outlinedCardDecoration(radius: 14),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: const Color(0xFF1A1C2B),
              ),
              decoration: InputDecoration(
                hintText: 'Search by name, category or contact…',
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppTheme.outline,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.outline,
                  size: 20,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    final suppliers = _filteredSuppliers;
    if (suppliers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 56,
              color: AppTheme.outline.withAlpha(100),
            ),
            const SizedBox(height: 12),
            Text(
              'No suppliers found',
              style: GoogleFonts.dmSans(fontSize: 16, color: AppTheme.outline),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: suppliers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _buildSupplierCard(suppliers[i]),
    );
  }

  Widget _buildSupplierCard(Supplier supplier) {
    return GestureDetector(
      onTap: () => _showSupplierDetail(supplier),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: _outlinedCardDecoration(radius: 16),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withAlpha(180),
                        AppTheme.primaryDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(60),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _initials(supplier.name),
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              supplier.name,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1C2B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (supplier.address != null)
                        Text(
                          supplier.address!,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 11,
                            color: AppTheme.outline,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              supplier.contactPerson ?? 'N/A',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppTheme.outline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildRatingStars(supplier.rating),
                          const SizedBox(width: 8),
                          _InfoChip(
                            label: '${supplier.leadTimeDays}d lead',
                            color: AppTheme.secondary,
                          ),
                          const SizedBox(width: 6),
                          _InfoChip(
                            label: '${supplier.orderCount} orders',
                            color: AppTheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppTheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating.floor()
              ? Icons.star_rounded
              : (i < rating
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded),
          size: 12,
          color: const Color(0xFFFFC107),
        );
      }),
    );
  }

  void _showSupplierDetail(Supplier supplier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SupplierDetailSheet(
        supplier: supplier,
        onEdit: (updated) {
          setState(() {
            final idx = _suppliers.indexWhere(
              (s) => s.sourceId == updated.sourceId,
            );
            if (idx >= 0) _suppliers[idx] = updated;
          });
          Navigator.pop(context);
        },
        onDelete: () {
          setState(
            () =>
                _suppliers.removeWhere((s) => s.sourceId == supplier.sourceId),
          );
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(80),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _showAddSupplierDialog,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: Text(
          'Add Supplier',
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showAddSupplierDialog() {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Add Supplier',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Company Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contactCtrl,
                decoration: const InputDecoration(labelText: 'Contact Person'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;

              final payload = {
                'name': nameCtrl.text.trim(),
                'contactPerson': contactCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'address': addressCtrl.text.trim(),
              };

              // Try to create supplier on backend; do not fallback to local/static data
              Future<void> showFailureDialog() async {
                final retry = await showDialog<bool>(
                  context: context,
                  builder: (dctx) => AlertDialog(
                    title: const Text('Create supplier failed'),
                    content: const Text(
                      'Failed to create supplier on the server. Would you like to retry?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(dctx).pop(true),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );

                if (retry == true) {
                  // Attempt again
                  final retryCreated = await SupplierDataService.createSupplier(
                    payload,
                  );
                  if (retryCreated != null) {
                    setState(() {
                      _suppliers.insert(0, Supplier.fromBackend(retryCreated));
                    });
                    Navigator.pop(ctx); // close add dialog
                    return;
                  }
                  // If still fails, show snack and keep add dialog open for user to try again or cancel
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '✗ Retry failed. Please check your connection or try again later.',
                        ),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              }

              final created = await SupplierDataService.createSupplier(payload);
              if (created != null) {
                setState(() {
                  _suppliers.insert(0, Supplier.fromBackend(created));
                });
                Navigator.pop(ctx);
                return;
              }

              await showFailureDialog();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SupplierDetailSheet extends StatelessWidget {
  final Supplier supplier;
  final ValueChanged<Supplier> onEdit;
  final VoidCallback onDelete;

  const _SupplierDetailSheet({
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.outlineVariant,
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supplier.name,
                            style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (supplier.address != null)
                            Text(
                              supplier.address!,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: AppTheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppTheme.primary,
                      ),
                      onPressed: () => _showEditDialog(context),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppTheme.error,
                      ),
                      onPressed: onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Contact',
                  value: supplier.contactPerson ?? 'N/A',
                ),
                _DetailRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: supplier.email ?? 'N/A',
                ),
                _DetailRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: supplier.phone ?? 'N/A',
                ),
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: supplier.address ?? 'N/A',
                ),
                _DetailRow(
                  icon: Icons.schedule_rounded,
                  label: 'Lead Time',
                  value: '${supplier.leadTimeDays} days',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(10),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: AppTheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${supplier.orderCount}',
                              style: GoogleFonts.dmSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                            Text(
                              'Orders',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppTheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withAlpha(10),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: AppTheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '\$${(supplier.totalOrders / 1000).toStringAsFixed(1)}k',
                              style: GoogleFonts.dmSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.success,
                              ),
                            ),
                            Text(
                              'Total Purchased',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppTheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC107).withAlpha(15),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: AppTheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            Text(
                              supplier.rating.toStringAsFixed(1),
                              style: GoogleFonts.dmSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFFC107),
                              ),
                            ),
                            Text(
                              'Rating',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppTheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (supplier.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: AppTheme.outlineVariant),
                    ),
                    child: Text(
                      supplier.notes,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: const Color(0xFF3F4460),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: supplier.name);
    final contactCtrl = TextEditingController(text: supplier.contactPerson);
    final emailCtrl = TextEditingController(text: supplier.email);
    final phoneCtrl = TextEditingController(text: supplier.phone);
    final notesCtrl = TextEditingController(text: supplier.notes);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Edit Supplier',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Company Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contactCtrl,
                decoration: const InputDecoration(labelText: 'Contact Person'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              supplier.name = nameCtrl.text;
              supplier.contactPerson = contactCtrl.text;
              supplier.email = emailCtrl.text;
              supplier.phone = phoneCtrl.text;
              supplier.notes = notesCtrl.text;
              onEdit(supplier);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.outline),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.outline),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1C2B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
